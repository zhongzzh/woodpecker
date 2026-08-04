"""本地 Web 壳（P2，docs/07 §3 MVP 单页三区）。

零第三方依赖：标准库 http.server；管线在**子进程**里跑（python -m pipeline.run），
stdout 逐行收进日志，「中止」= 强杀子进程树（连带 playwright/AI 请求干净终止）。
浏览器打开 http://127.0.0.1:8737 即用（启动.bat 双击启动）。存储即目录：
历史列表就是读 tasks/，无数据库。同一时刻只跑一个任务（03-H：逐个起步）。

接口：
  GET  /                     单页 UI
  POST /api/run              在线 MR 或本地材料任务
  POST /api/select-local     打开本机文件选择器（代码/单测或文档）
  POST /api/parse-input      {text} → 从整段粘贴内容提取任务名与 MR
  POST /api/stop             中止当前任务（杀子进程树）
  GET  /api/status           当前任务进度（前端 1s 轮询）
  GET  /api/runtime          当前服务代码版本、项目路径与任务状态
  POST /api/shutdown         空闲时退出旧服务，供新版启动进程接管端口
  GET  /api/tasks            历史任务列表（tasks/ 下有 分析报告.md 的目录）
  GET  /api/report?dir=xxx   某次任务的报告原文（md）
  GET  /api/code-chat?dir=xx 某次任务的补测代码优化对话
  POST /api/code-chat        发送消息或清空当前任务对话
  GET  /api/ai-config        AI 设置（OpenAI/Anthropic 双协议；POST 同路径保存）
  GET  /api/analysis-prompt  当前覆盖分析提示词（POST 保存或恢复默认）
  POST /api/ai-models        按所选协议获取端点模型清单
  POST /api/ai-test          使用设置面板当前值发送一次自定义问题
"""

from __future__ import annotations

import atexit
import hashlib
import json
import os
import socket
import shutil
import subprocess
import sys
import tempfile
import threading
import time
import webbrowser
from http.client import HTTPConnection
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

from . import analyze, code_chat, config, locate, login, paste
from .taskcard import TaskCard
from .windows_dpi import enable_high_dpi

HOST, PORT = "127.0.0.1", 8737
STATIC_DIR = config.PROJECT_ROOT / "pipeline" / "static"
REPORT_NAME = "分析报告.md"


def _calculate_runtime_version(source_dir: Path | None = None) -> str:
    """计算服务代码与静态资源指纹；缓存文件和编译产物不参与。"""
    root = (source_dir or Path(__file__).resolve().parent).resolve()
    digest = hashlib.sha256()
    candidates = sorted(
        path for path in root.rglob("*")
        if path.is_file()
        and "__pycache__" not in path.parts
        and path.suffix.lower() not in (".pyc", ".pyo")
    )
    for path in candidates:
        relative = path.relative_to(root).as_posix().encode("utf-8")
        content = path.read_bytes()
        digest.update(len(relative).to_bytes(4, "big"))
        digest.update(relative)
        digest.update(len(content).to_bytes(8, "big"))
        digest.update(content)
    return digest.hexdigest()[:20]


RUNTIME_VERSION = _calculate_runtime_version()


def _read_index_html() -> bytes:
    """每次请求读取页面，避免常驻服务继续返回启动时缓存的旧界面。"""
    return (STATIC_DIR / "index.html").read_bytes()


class _Job:
    """一次管线运行（子进程）的状态（同一时刻至多一个）。"""

    def __init__(self) -> None:
        self.lock = threading.Lock()
        self.proc: subprocess.Popen | None = None
        self.running = False
        self.stopped = False          # 是否被用户中止
        self.log_lines: list[str] = []
        self.error: str | None = None
        self.completed = False
        self.job_mode = "analysis"
        self.report_dir: str | None = None
        self.out_dir: str | None = None  # 本次运行的产出目录（从日志解析）
        self.resolved_paths: dict | None = None

    def log(self, msg: str) -> None:
        with self.lock:
            self.log_lines.append(str(msg))

    def snapshot(self) -> dict:
        with self.lock:
            snapshot = {
                "running": self.running,
                "stopped": self.stopped,
                "log": list(self.log_lines),
                "error": self.error,
                "completed": self.completed,
                "job_mode": self.job_mode,
                "report_dir": self.report_dir,
                "resolved_paths": self.resolved_paths,
            }
            out_dir = self.out_dir
        snapshot["failed_steps"] = _read_failed_steps(out_dir)
        if snapshot["resolved_paths"] is None:
            resolved = _read_resolved_paths(out_dir)
            if resolved:
                with self.lock:
                    if self.out_dir == out_dir:
                        self.resolved_paths = resolved
                snapshot["resolved_paths"] = resolved
        return snapshot


def _read_failed_steps(out_dir: str | None) -> list[int]:
    """从最终任务元数据中提取已降级但实际未完成的步骤。"""
    if not out_dir:
        return []
    try:
        task = json.loads((Path(out_dir) / "task.json").read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        return []

    failed_steps = []
    if task.get("coverage_ai_status") == "failed":
        failed_steps.append(3)
    if task.get("performance_ai_status") in {"failed", "unparsed"}:
        failed_steps.append(4)
    return failed_steps


_job = _Job()

# 浏览器页面与隐藏的本地服务绑定：最后一个页面关闭后给刷新/重连留出短暂宽限，
# 随后自动退出服务。这样用户不需要看见或手动关闭终端窗口。
_ui_lock = threading.Lock()
_ui_clients = 0
_ui_generation = 0
_ui_ever_connected = False
_UI_CLOSE_GRACE_SECONDS = 8


def _read_resolved_paths(out_dir: str | None) -> dict | None:
    """读取子进程刚定位出的本地材料；任务完成后回退到 task.json。"""
    if not out_dir:
        return None
    directory = Path(out_dir).resolve()
    if directory.parent != config.TASKS_DIR.resolve():
        return None
    candidates = [
        directory / config.LOCAL_PATHS_STATE_NAME,
        directory / "task.json",
    ]
    for path in candidates:
        if not path.is_file():
            continue
        try:
            value = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if not isinstance(value, dict) or not value.get("local_code") or not value.get("local_doc"):
            continue
        return {
            "local_code": str(value["local_code"]),
            "local_doc": str(value["local_doc"]),
            "local_code_files": [str(item) for item in value.get("local_code_files", [])],
            "local_doc_files": [str(item) for item in value.get("local_doc_files", [])],
        }
    return None


def _ui_connected() -> None:
    global _ui_clients, _ui_generation, _ui_ever_connected
    with _ui_lock:
        _ui_clients += 1
        _ui_generation += 1
        _ui_ever_connected = True


def _ui_disconnected(server: ThreadingHTTPServer) -> None:
    global _ui_clients, _ui_generation
    with _ui_lock:
        _ui_clients = max(0, _ui_clients - 1)
        _ui_generation += 1
        generation = _ui_generation

    def shutdown_if_still_closed() -> None:
        with _ui_lock:
            should_stop = _ui_clients == 0 and _ui_generation == generation
        if should_stop:
            server.shutdown()

    timer = threading.Timer(_UI_CLOSE_GRACE_SECONDS, shutdown_if_still_closed)
    timer.daemon = True
    timer.start()


def _build_argv(payload: dict) -> list[str]:
    python_exe = sys.executable
    # Web 服务由 pythonw.exe 隐藏启动；分析子进程仍使用 python.exe，确保日志管道正常。
    if os.path.basename(python_exe).lower() == "pythonw.exe":
        console_python = os.path.join(os.path.dirname(python_exe), "python.exe")
        if os.path.isfile(console_python):
            python_exe = console_python
    argv = [
        python_exe, "-m", "pipeline.run",
        "--name", payload["name"].strip(),
    ]
    if payload.get("input_mode") == "local":
        if payload.get("local_branch", "").strip():
            argv += [
                "--local-library", payload["local_library"].strip(),
                "--local-branch", payload["local_branch"].strip(),
            ]
        else:
            # 保留旧 API/命令行调用的路径式本地材料输入。
            argv += [
                "--local-code", payload["local_code"].strip(),
                "--local-doc", payload["local_doc"].strip(),
            ]
            if payload.get("local_library", "").strip():
                argv += ["--local-library", payload["local_library"].strip()]
    else:
        argv += ["--code-mr", payload["code_mr"].strip()]
        if payload.get("doc_mr", "").strip():
            argv += ["--doc-mr", payload["doc_mr"].strip()]
    if payload.get("func", "").strip():
        argv += ["--func", payload["func"].strip()]
    if payload.get("code_branch", "").strip():
        argv += ["--code-branch", payload["code_branch"].strip()]
    if payload.get("doc_branch", "").strip():
        argv += ["--doc-branch", payload["doc_branch"].strip()]
    if payload.get("no_ai"):
        argv += ["--no-ai"]
    if payload.get("build_doc_html"):
        argv += ["--build-doc-html"]
    if payload.get("refresh_doc_only"):
        argv += ["--refresh-doc-only"]
    if payload.get("perf_report_file", "").strip():
        argv += ["--perf-report-file", payload["perf_report_file"].strip()]
    return argv


def _hidden_process_kwargs() -> dict:
    """Windows GUI 模式下禁止子进程创建控制台窗口。"""
    if sys.platform == "win32":
        return {"creationflags": subprocess.CREATE_NO_WINDOW}
    return {}


def _service_is_running() -> bool:
    """启动前探测已有实例，避免 Windows 的端口复用留下重复后台进程。"""
    try:
        with socket.create_connection((HOST, PORT), timeout=0.25):
            return True
    except OSError:
        return False


def _service_runtime_info() -> dict | None:
    """读取现有 Woodpecker 服务的启动版本与任务状态。"""
    connection = HTTPConnection(HOST, PORT, timeout=0.6)
    try:
        connection.request("GET", "/api/runtime")
        response = connection.getresponse()
        if response.status != 200:
            response.read()
            return None
        value = json.loads(response.read().decode("utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        return None
    finally:
        connection.close()
    if not isinstance(value, dict) or value.get("service") != "woodpecker":
        return None
    return value


def _legacy_service_status() -> dict | None:
    """识别尚未提供 /api/runtime 的旧版 Woodpecker。"""
    connection = HTTPConnection(HOST, PORT, timeout=0.6)
    try:
        connection.request("GET", "/api/status")
        response = connection.getresponse()
        if response.status != 200:
            response.read()
            return None
        value = json.loads(response.read().decode("utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        return None
    finally:
        connection.close()
    required = {"running", "stopped", "log", "error", "report_dir"}
    if not isinstance(value, dict) or not required.issubset(value):
        return None
    return value


def _legacy_service_process() -> dict | None:
    """在 Windows 上定位默认端口的进程，并验证它属于当前项目。"""
    if sys.platform != "win32":
        return None
    script = (
        f"$c=Get-NetTCPConnection -LocalPort {PORT} -State Listen "
        "-ErrorAction Stop|Select-Object -First 1;"
        "$p=Get-CimInstance Win32_Process -Filter "
        "\"ProcessId = $($c.OwningProcess)\";"
        "[PSCustomObject]@{pid=$p.ProcessId;command_line=$p.CommandLine;"
        "executable_path=$p.ExecutablePath}|ConvertTo-Json -Compress"
    )
    result = subprocess.run(
        ["powershell.exe", "-NoProfile", "-NonInteractive", "-Command", script],
        capture_output=True, text=True, encoding="utf-8", errors="replace",
        **_hidden_process_kwargs(),
    )
    if result.returncode != 0:
        return None
    try:
        value = json.loads(result.stdout.strip())
    except json.JSONDecodeError:
        return None
    command_line = str(value.get("command_line", ""))
    normalized_command = command_line.replace("/", "\\").lower()
    normalized_root = str(config.PROJECT_ROOT.resolve()).replace("/", "\\").lower()
    if normalized_root not in normalized_command or "pipeline.web" not in command_line:
        return None
    try:
        pid = int(value["pid"])
    except (KeyError, TypeError, ValueError):
        return None
    if pid <= 0 or pid == os.getpid():
        return None
    return {**value, "pid": pid}


def _stop_legacy_service() -> bool:
    """只结束已验证为当前项目且处于空闲状态的旧版服务。"""
    process = _legacy_service_process()
    if process is None:
        return False
    result = subprocess.run(
        ["taskkill", "/F", "/T", "/PID", str(process["pid"])],
        capture_output=True, **_hidden_process_kwargs(),
    )
    return result.returncode == 0


def _request_service_shutdown() -> bool:
    """请求空闲旧实例正常退出；运行中的分析由旧实例拒绝。"""
    connection = HTTPConnection(HOST, PORT, timeout=1.0)
    try:
        connection.request(
            "POST", "/api/shutdown", body=b"{}",
            headers={"Content-Type": "application/json"},
        )
        response = connection.getresponse()
        value = json.loads(response.read().decode("utf-8"))
        return response.status == 200 and bool(value.get("ok"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        return False
    finally:
        connection.close()


def _wait_for_service_exit(timeout: float = 5.0) -> bool:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if not _service_is_running():
            return True
        time.sleep(0.05)
    return not _service_is_running()


def _should_reuse_running_service(log=print) -> bool:
    """同版本直接复用；旧版本空闲时退出并由当前进程接管。"""
    info = _service_runtime_info()
    if info is None:
        legacy = _legacy_service_status()
        if legacy is None:
            return _service_is_running()
        if legacy.get("running"):
            log("检测到旧版服务仍在执行分析，本次保留现有任务")
            return True
        if not _stop_legacy_service():
            return True
        return not _wait_for_service_exit()
    same_project = info.get("project_root") == str(config.PROJECT_ROOT.resolve())
    if same_project and info.get("version") == RUNTIME_VERSION:
        return True
    if info.get("running"):
        log("检测到旧版本服务仍在执行分析，本次保留现有任务")
        return True
    if not _request_service_shutdown():
        return _service_is_running()
    stopped = _wait_for_service_exit()
    if not stopped:
        log("旧版本服务未能在限定时间内退出，本次继续复用")
    return not stopped


def _select_local_file(kind: str) -> str:
    """用系统文件对话框选择材料；浏览器本身不会暴露本地文件的真实路径。"""
    choices = {
        "code": ("选择 Julia 代码或单测", [("Julia 文件", "*.jl"), ("所有文件", "*.*")]),
        "doc": ("选择函数文档", [("Markdown 文件", "*.md"), ("所有文件", "*.*")]),
    }
    directories = {
        "root": "选择本地材料母目录",
        "code_dir": "选择代码/单测母目录",
        "doc_dir": "选择函数文档母目录",
    }
    if kind not in directories and kind not in choices:
        raise ValueError(f"不支持的文件类型：{kind!r}")
    enable_high_dpi()
    try:
        import tkinter as tk
        from tkinter import filedialog
    except ImportError as exc:
        raise RuntimeError("当前 Python 环境缺少 tkinter，无法打开系统文件选择器") from exc

    try:
        root = tk.Tk()
    except tk.TclError as exc:
        raise RuntimeError(f"无法打开系统文件选择器：{exc}") from exc
    root.withdraw()
    try:
        root.attributes("-topmost", True)
        root.update()
        if kind in directories:
            try:
                return str(filedialog.askdirectory(parent=root, title=directories[kind]))
            except tk.TclError as exc:
                raise RuntimeError(f"系统目录选择器执行失败：{exc}") from exc
        title, filetypes = choices[kind]
        try:
            return str(filedialog.askopenfilename(
                parent=root, title=title, filetypes=filetypes
            ))
        except tk.TclError as exc:
            raise RuntimeError(f"系统文件选择器执行失败：{exc}") from exc
    finally:
        root.destroy()


def _cleanup_partial_output(out_dir: str | None) -> None:
    """中止/失败后清掉没有报告的残留产出目录（该目录是本次运行自己建的）。"""
    if not out_dir:
        return
    d = config.TASKS_DIR / os.path.basename(out_dir)
    if d.is_dir() and not (d / REPORT_NAME).exists():
        shutil.rmtree(d, ignore_errors=True)


def _start_job(payload: dict) -> tuple[bool, str]:
    with _job.lock:
        if _job.running:
            return False, "已有任务在跑：可点「中止」结束它，或等它完成（当前版本一次只跑一个）"
        _job.running = True
        _job.stopped = False
        _job.log_lines = []
        _job.error = None
        _job.completed = False
        _job.job_mode = (
            "refresh_doc_only" if payload.get("refresh_doc_only") else "analysis"
        )
        _job.report_dir = None
        _job.out_dir = None
        _job.resolved_paths = None

    env = {**os.environ, "PYTHONUTF8": "1"}  # 子进程 stdout/stderr 统一 utf-8
    launch_payload = dict(payload)
    temp_perf_path: Path | None = None
    try:
        perf_report_text = str(payload.get("perf_report_text", "")).strip()
        if perf_report_text:
            with tempfile.NamedTemporaryFile(
                mode="w", encoding="utf-8", prefix="woodpecker-perf-",
                suffix=".txt", delete=False,
            ) as temp_perf:
                temp_perf.write(perf_report_text)
                temp_perf_path = Path(temp_perf.name)
            launch_payload["perf_report_file"] = str(temp_perf_path)
        proc = subprocess.Popen(
            _build_argv(launch_payload),
            cwd=str(config.PROJECT_ROOT),
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
            text=True, encoding="utf-8", errors="replace",
            env=env,
            **_hidden_process_kwargs(),
        )
    except OSError as e:
        if temp_perf_path:
            temp_perf_path.unlink(missing_ok=True)
        with _job.lock:
            _job.running = False
            _job.error = f"启动任务子进程失败: {e}"
        return False, f"启动任务子进程失败: {e}"

    with _job.lock:
        _job.proc = proc

    def reader() -> None:
        assert proc.stdout is not None
        for raw in proc.stdout:
            line = raw.rstrip("\r\n")
            if not line:
                continue
            _job.log(line)
            if line.startswith("产出目录: "):
                with _job.lock:
                    _job.out_dir = line.split(": ", 1)[1].strip()
        code = proc.wait()
        with _job.lock:
            stopped = _job.stopped
            out_dir = _job.out_dir
        if stopped:
            _job.log("⏹ 已被用户中止")
            _cleanup_partial_output(out_dir)
        elif code == 0 and out_dir:
            with _job.lock:
                _job.report_dir = os.path.basename(out_dir)
                _job.completed = True
        elif code == 0:
            with _job.lock:
                _job.completed = True
        else:
            with _job.lock:
                last = next((ln for ln in reversed(_job.log_lines) if ln.strip()), "")
                _job.error = last or f"任务子进程异常退出（exit={code}）"
            _cleanup_partial_output(out_dir)
        with _job.lock:
            _job.running = False
            _job.proc = None
        if temp_perf_path:
            temp_perf_path.unlink(missing_ok=True)

    threading.Thread(target=reader, daemon=True).start()
    return True, "started"


def _stop_job() -> tuple[bool, str]:
    with _job.lock:
        proc = _job.proc
        if not (_job.running and proc):
            return False, "当前没有在跑的任务"
        _job.stopped = True
        pid = proc.pid
    # 杀整棵进程树：管线可能挂着 playwright 浏览器等子进程
    kill = subprocess.run(
        ["taskkill", "/F", "/T", "/PID", str(pid)],
        capture_output=True, text=True,
        **_hidden_process_kwargs(),
    )
    if kill.returncode != 0:
        try:
            proc.kill()
        except OSError:
            pass
    return True, "已发出中止"


@atexit.register
def _kill_on_exit() -> None:
    with _job.lock:
        proc = _job.proc
    if proc and proc.poll() is None:
        subprocess.run(["taskkill", "/F", "/T", "/PID", str(proc.pid)],
                       capture_output=True, **_hidden_process_kwargs())


def _list_tasks() -> list[dict]:
    items = []
    if config.TASKS_DIR.is_dir():
        for d in config.TASKS_DIR.iterdir():
            if not d.is_dir():
                continue
            report = d / REPORT_NAME
            legacy = d / "覆盖分析报告.md"  # 手工时期的旧产出（tasks/polydiv）
            f = report if report.exists() else legacy if legacy.exists() else None
            if f:
                items.append((f.stat().st_mtime_ns, d.name, f.name))
    items.sort(key=lambda item: (item[0], item[1]), reverse=True)
    return [{"dir": dirname, "file": filename} for _, dirname, filename in items]


def _read_report(dirname: str) -> str | None:
    d = (config.TASKS_DIR / dirname).resolve()
    if d.parent != config.TASKS_DIR.resolve() or not d.is_dir():
        return None  # 防路径逃逸
    for name in (REPORT_NAME, "覆盖分析报告.md"):
        f = d / name
        if f.exists():
            return f.read_text(encoding="utf-8", errors="replace")
    return None


def _public_ai_config() -> dict:
    """生成浏览器可见的 AI 配置，任何档案都不包含明文 Key。"""
    store = analyze.load_ai_config_store()
    public_profiles = []
    for profile in store["profiles"]:
        public_profiles.append({
            "id": profile["id"],
            "name": profile["name"],
            "protocol": profile["protocol"],
            "base_url": profile["base_url"],
            "model": profile["model"],
            "timeout_seconds": profile["timeout_seconds"],
            "has_saved_key": bool(profile["api_key"]),
            "api_key_masked": analyze.mask_api_key(profile["api_key"]),
        })
    active_id = store["active_profile_id"]
    active = next((p for p in public_profiles if p["id"] == active_id), None)
    cfg = dict(active) if active else {
        "id": "", "name": "环境变量默认", "protocol": "", "base_url": "",
        "model": "", "timeout_seconds": analyze._default_timeout_seconds(),
        "has_saved_key": False, "api_key_masked": "",
    }
    cfg["api_key"] = ""
    cfg["active_profile_id"] = active_id
    cfg["profiles"] = public_profiles

    default_protocol = os.environ.get("WOODPECKER_AI_PROTOCOL", "anthropic").lower()
    if default_protocol not in ("openai", "anthropic"):
        default_protocol = "anthropic"
    effective_protocol = cfg["protocol"] or default_protocol
    env_base_urls = {
        "openai": os.environ.get("OPENAI_BASE_URL", ""),
        "anthropic": os.environ.get("ANTHROPIC_BASE_URL", ""),
    }
    has_env_keys = {
        "openai": bool(os.environ.get("OPENAI_API_KEY")),
        "anthropic": bool(
            os.environ.get("ANTHROPIC_AUTH_TOKEN")
            or os.environ.get("ANTHROPIC_API_KEY")
        ),
    }
    default_models = {
        "openai": os.environ.get("OPENAI_MODEL", "") or config.MODEL,
        "anthropic": config.MODEL,
    }
    cfg.update({
        "default_protocol": default_protocol,
        "effective_protocol": effective_protocol,
        "env_base_urls": env_base_urls,
        "has_env_keys": has_env_keys,
        "default_models": default_models,
        "env_base_url": env_base_urls[effective_protocol],
        "has_env_key": has_env_keys[effective_protocol],
        "default_model": default_models[effective_protocol],
        "default_timeout_seconds": analyze._default_timeout_seconds(),
    })
    return cfg


def _public_gitlab_config() -> dict:
    """返回浏览器可见的 GitLab 网络配置与登录态状态。"""
    value = config.load_gitlab_config()
    return {
        **value,
        "login_state_exists": config.PW_STATE_FILE.is_file(),
        "login_state_file": str(config.PW_STATE_FILE),
    }


def _apply_gitlab_action(payload: dict) -> dict:
    """保存 GitLab 配置，并按需测试连接或打开人工登录窗口。"""
    action = str(payload.get("action", "save")).strip().lower()
    if action not in ("save", "test", "login"):
        raise config.GitLabConfigError(f"不支持的 GitLab 配置操作: {action}")
    saved = config.save_gitlab_config(
        str(payload.get("host", "")),
        payload.get("ssh_port", ""),
        str(payload.get("proxy", "")),
    )
    # 空值表示沿用 WOODPECKER_PROXY / Windows 系统代理；必须传 None，
    # 不能传空字符串，否则 login 模块会把它理解成强制直连。
    browser_proxy = saved["proxy"] or None
    if action == "test":
        result = login.check_connection(saved["host"], browser_proxy)
        return {
            "message": (
                f"网络连接成功（HTTP {result['status'] or '—'}）；"
                "这只表示登录页可达，仍需完成 GitLab 登录"
            ),
            "connection": result,
            **_public_gitlab_config(),
        }
    if action == "login":
        login.login_gitlab(saved["host"], browser_proxy)
        return {
            "message": "GitLab 登录成功，登录态已更新",
            **_public_gitlab_config(),
        }
    return {"message": "GitLab 设置已保存", **_public_gitlab_config()}


def _profile_api_key(payload: dict) -> str:
    """取表单新 Key；留空时仅可复用请求所指档案的服务端 Key。"""
    api_key = str(payload.get("api_key", "")).strip()
    if api_key:
        return api_key
    profile = analyze.get_ai_profile(str(payload.get("profile_id", "")))
    return profile["api_key"] if profile else ""


def _coverage_prompt_payload() -> dict:
    prompt = analyze.load_coverage_prompt()
    return {
        "prompt": prompt,
        "customized": analyze.coverage_prompt_is_customized(),
        "characters": len(prompt),
    }


def _resolve_local_materials(card: TaskCard) -> dict:
    """预定位本地材料，返回用于回填的首选路径和完整命中列表。"""
    unit = locate.find_local_unit_test(
        card.local_code, card.func, log=lambda _message: None
    )
    docs = locate.find_local_docs(
        card.local_doc, card.func, log=lambda _message: None
    )
    code_files = [unit["main"], *unit["companions"]]
    return {
        "local_code": str(unit["main"]),
        "local_doc": str(docs[0]),
        "local_code_files": [str(path) for path in code_files],
        "local_doc_files": [str(path) for path in docs],
    }


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _send(
        self, code: int, body: bytes, ctype: str, cache_control: str | None = None
    ) -> None:
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        if cache_control:
            self.send_header("Cache-Control", cache_control)
        self.end_headers()
        self.wfile.write(body)

    def _json(self, obj, code: int = 200) -> None:
        self._send(code, json.dumps(obj, ensure_ascii=False).encode("utf-8"),
                   "application/json; charset=utf-8")

    def do_GET(self) -> None:  # noqa: N802（http.server 约定）
        u = urlparse(self.path)
        if u.path == "/":
            try:
                body = _read_index_html()
            except OSError as exc:
                self._json({"error": f"页面读取失败: {exc}"}, 500)
            else:
                self._send(
                    200, body, "text/html; charset=utf-8", cache_control="no-store"
                )
        elif u.path == "/favicon.ico":
            self.send_response(204)
            self.end_headers()
        elif u.path == "/api/status":
            self._json(_job.snapshot())
        elif u.path == "/api/runtime":
            self._json({
                "service": "woodpecker",
                "version": RUNTIME_VERSION,
                "project_root": str(config.PROJECT_ROOT.resolve()),
                "pid": os.getpid(),
                "running": bool(_job.snapshot()["running"]),
            })
        elif u.path == "/api/lifecycle":
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream; charset=utf-8")
            self.send_header("Cache-Control", "no-cache, no-transform")
            self.send_header("Connection", "keep-alive")
            self.end_headers()
            _ui_connected()
            try:
                while True:
                    self.wfile.write(b": woodpecker-alive\n\n")
                    self.wfile.flush()
                    time.sleep(3)
            except (BrokenPipeError, ConnectionResetError, OSError):
                pass
            finally:
                self.close_connection = True
                _ui_disconnected(self.server)
        elif u.path == "/api/tasks":
            self._json(_list_tasks())
        elif u.path == "/api/ai-config":
            self._json(_public_ai_config())
        elif u.path == "/api/gitlab-config":
            self._json(_public_gitlab_config())
        elif u.path == "/api/analysis-prompt":
            try:
                self._json(_coverage_prompt_payload())
            except (analyze.AnalyzeError, OSError) as e:
                self._json({"error": str(e)}, 500)
        elif u.path == "/api/report":
            dirname = parse_qs(u.query).get("dir", [""])[0]
            text = _read_report(dirname)
            if text is None:
                self._json({"error": "报告不存在"}, 404)
            else:
                self._json({"dir": dirname, "markdown": text})
        elif u.path == "/api/code-chat":
            dirname = parse_qs(u.query).get("dir", [""])[0]
            try:
                self._json({"ok": True, **code_chat.conversation(dirname)})
            except code_chat.CodeChatError as e:
                self._json({"ok": False, "message": str(e)}, 404)
        else:
            self._json({"error": "not found"}, 404)

    def do_POST(self) -> None:  # noqa: N802
        path = urlparse(self.path).path
        length = int(self.headers.get("Content-Length", 0))
        try:
            payload = json.loads(self.rfile.read(length).decode("utf-8")) if length else {}
        except (json.JSONDecodeError, UnicodeDecodeError) as e:
            self._json({"ok": False, "message": f"请求体不是合法 UTF-8 JSON: {e}"}, 400)
            return

        if path == "/api/shutdown":
            if _job.snapshot()["running"]:
                self._json({
                    "ok": False,
                    "message": "当前任务仍在运行，不能重启本地服务",
                }, 409)
            else:
                self._json({"ok": True, "message": "本地服务正在重启"})
                threading.Thread(target=self.server.shutdown, daemon=True).start()
        elif path == "/api/parse-input":
            try:
                result = paste.parse_submission_text(str(payload.get("text", "")))
                self._json({"ok": True, **result})
            except paste.PasteParseError as e:
                self._json({"ok": False, "message": str(e)}, 400)
        elif path == "/api/select-local":
            try:
                selected = _select_local_file(str(payload.get("kind", "")))
                self._json({"ok": True, "path": selected, "cancelled": not bool(selected)})
            except (RuntimeError, ValueError) as e:
                self._json({"ok": False, "message": str(e)}, 400)
        elif path == "/api/run":
            input_mode = str(payload.get("input_mode", "remote")).strip().lower() or "remote"
            refresh_doc_only = bool(payload.get("refresh_doc_only"))
            if refresh_doc_only and input_mode != "local":
                self._json({
                    "ok": False,
                    "message": "仅更新文档功能只支持本地材料的仓库模式",
                }, 400)
                return
            if input_mode == "local":
                repository_mode = bool(str(payload.get("local_branch", "")).strip())
                required = (
                    ("name", "local_library", "local_branch")
                    if repository_mode or refresh_doc_only
                    else ("name", "local_library", "local_code", "local_doc")
                )
            else:
                required = ("name", "code_mr")
            for field in required:
                if not str(payload.get(field, "")).strip():
                    self._json({"ok": False, "message": f"输入有误: 缺少必填项 {field}"}, 400)
                    return
            try:
                resolved_paths = None
                card = TaskCard(
                    name=str(payload.get("name", "")).strip(),
                    code_mr=str(payload.get("code_mr", "")).strip(),
                    doc_mr=str(payload.get("doc_mr", "")).strip(),
                    func=str(payload.get("func", "")).strip(),
                    input_mode=input_mode,
                    local_code=str(payload.get("local_code", "")).strip(),
                    local_doc=str(payload.get("local_doc", "")).strip(),
                    local_library=str(payload.get("local_library", "")).strip(),
                    local_branch=str(payload.get("local_branch", "")).strip(),
                )
                if card.is_local:
                    if not card.uses_local_repositories:
                        resolved_paths = _resolve_local_materials(card)
                else:
                    # 提前验证 URL 结构，避免启动子进程后才失败。
                    _ = card.code_project
                    if card.is_new_function:
                        _ = card.doc_project
                    payload["perf_report_text"] = ""
                payload["input_mode"] = input_mode
            except (locate.LocateError, ValueError) as e:
                self._json({"ok": False, "message": f"输入有误: {e}"}, 400)
                return
            ok, message = _start_job(payload)
            self._json(
                {"ok": ok, "message": message, "resolved_paths": resolved_paths},
                200 if ok else 409,
            )
        elif path == "/api/stop":
            ok, message = _stop_job()
            self._json({"ok": ok, "message": message}, 200 if ok else 409)
        elif path == "/api/gitlab-config":
            try:
                action = str(payload.get("action", "save")).strip().lower()
                if action == "login" and _job.snapshot()["running"]:
                    self._json({
                        "ok": False,
                        "message": "请先等待当前分析结束或中止任务，再重新登录 GitLab",
                    }, 409)
                    return
                result = _apply_gitlab_action(payload)
                self._json({"ok": True, **result})
            except (config.GitLabConfigError, login.LoginError, OSError) as e:
                self._json({"ok": False, "message": str(e)}, 400)
        elif path == "/api/ai-models":
            try:
                models = analyze.list_models(
                    str(payload.get("base_url", "")),
                    _profile_api_key(payload),
                    str(payload.get("protocol", "")),
                    payload.get("timeout_seconds"),
                )
                self._json({"ok": True, "models": models})
            except analyze.AnalyzeError as e:
                self._json({"ok": False, "message": str(e)}, 400)
        elif path == "/api/ai-test":
            try:
                answer = analyze.test_ai_prompt(
                    str(payload.get("question", "")),
                    str(payload.get("base_url", "")),
                    _profile_api_key(payload),
                    str(payload.get("model", "")),
                    str(payload.get("protocol", "")),
                    payload.get("timeout_seconds"),
                )
                self._json({"ok": True, "answer": answer})
            except analyze.AnalyzeError as e:
                self._json({"ok": False, "message": str(e)}, 400)
        elif path == "/api/ai-config":
            try:
                action = str(payload.get("action", "save")).strip().lower()
                profile_id = str(payload.get("profile_id", "")).strip()
                if action == "save":
                    saved = analyze.get_ai_profile(profile_id)
                    api_key = str(payload.get("api_key", "")).strip()
                    if not api_key and payload.get("keep_api_key") and saved:
                        api_key = saved["api_key"]
                    profile_id = analyze.save_ai_profile(
                        profile_id,
                        str(payload.get("name", "")),
                        str(payload.get("base_url", "")),
                        api_key,
                        str(payload.get("model", "")),
                        str(payload.get("protocol", "")),
                        payload.get("timeout_seconds"),
                    )
                    message = "公益站配置已保存并启用"
                elif action == "activate":
                    analyze.activate_ai_profile(profile_id)
                    message = "已切换当前公益站"
                elif action == "delete":
                    analyze.delete_ai_profile(profile_id)
                    message = "公益站配置已删除"
                elif action == "use_default":
                    analyze.activate_ai_profile("")
                    message = "已改用环境变量默认配置"
                else:
                    raise analyze.AnalyzeError(f"不支持的 AI 配置操作: {action}")
                self._json({"ok": True, "message": message, "profile_id": profile_id})
            except analyze.AnalyzeError as e:
                self._json({"ok": False, "message": str(e)}, 400)
        elif path == "/api/analysis-prompt":
            try:
                action = str(payload.get("action", "save")).strip().lower()
                if action == "save":
                    analyze.save_coverage_prompt(str(payload.get("prompt", "")))
                    message = "覆盖分析提示词已保存"
                elif action == "reset":
                    analyze.reset_coverage_prompt()
                    message = "已恢复项目默认提示词"
                else:
                    raise analyze.AnalyzeError(f"不支持的提示词操作: {action}")
                self._json({"ok": True, "message": message, **_coverage_prompt_payload()})
            except analyze.AnalyzeError as e:
                self._json({"ok": False, "message": str(e)}, 400)
        elif path == "/api/code-chat":
            try:
                action = str(payload.get("action", "send")).strip().lower()
                dirname = str(payload.get("dir", ""))
                if action == "send":
                    result = code_chat.send_message(
                        dirname, str(payload.get("message", "")),
                        log=lambda _message: None,
                    )
                elif action == "clear":
                    result = code_chat.clear_conversation(dirname)
                else:
                    raise code_chat.CodeChatError(
                        f"不支持的补测代码对话操作：{action}"
                    )
                self._json({"ok": True, **result})
            except (code_chat.CodeChatError, analyze.AnalyzeError, OSError) as e:
                self._json({"ok": False, "message": str(e)}, 400)
        else:
            self._json({"error": "not found"}, 404)

    def log_message(self, fmt, *args) -> None:  # 静默默认访问日志
        pass


def main() -> None:
    # The service later creates native Tk file dialogs from request threads.
    enable_high_dpi()
    url = f"http://{HOST}:{PORT}"
    if _should_reuse_running_service():
        webbrowser.open(url)
        return
    try:
        server = ThreadingHTTPServer((HOST, PORT), Handler)
    except OSError:
        # 重复双击时复用已经运行的实例，不再额外启动第二个服务。
        webbrowser.open(url)
        return
    print(f"woodpecker 提测分析已启动: {url}（Ctrl+C 退出）")
    threading.Timer(0.5, webbrowser.open, args=(url,)).start()

    def stop_if_browser_never_opened() -> None:
        with _ui_lock:
            never_opened = not _ui_ever_connected
        if never_opened:
            server.shutdown()

    startup_timer = threading.Timer(90, stop_if_browser_never_opened)
    startup_timer.daemon = True
    startup_timer.start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n已退出")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
