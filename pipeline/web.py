"""本地 Web 壳（P2，docs/07 §3 MVP 单页三区）。

零第三方依赖：标准库 http.server；管线在**子进程**里跑（python -m pipeline.run），
stdout 逐行收进日志，「中止」= 强杀子进程树（连带 playwright/AI 请求干净终止）。
浏览器打开 http://127.0.0.1:8737 即用（启动.bat 双击启动）。存储即目录：
历史列表就是读 tasks/，无数据库。同一时刻只跑一个任务（03-H：逐个起步）。

接口：
  GET  /                     单页 UI
  POST /api/run              {name, code_mr, doc_mr?, func?, doc_branch?, code_branch?, no_ai?}
  POST /api/parse-input      {text} → 从整段粘贴内容提取任务名与 MR
  POST /api/stop             中止当前任务（杀子进程树）
  GET  /api/status           当前任务进度（前端 1s 轮询）
  GET  /api/tasks            历史任务列表（tasks/ 下有 分析报告.md 的目录）
  GET  /api/report?dir=xxx   某次任务的报告原文（md）
  GET  /api/gitlab-config    GitLab 地址/代理/登录状态（POST 同路径保存）
  POST /api/gitlab-test      使用 Chromium 测试 GitLab 连接
  POST /api/gitlab-login     打开 GitLab 登录窗口并保存登录态
  GET  /api/ai-config        AI 设置（OpenAI/Anthropic 双协议；POST 同路径保存）
  POST /api/ai-models        按所选协议获取端点模型清单
"""

from __future__ import annotations

import atexit
import json
import os
import shutil
import subprocess
import sys
import threading
import time
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

from . import analyze, config, login, paste
from .taskcard import TaskCard

HOST, PORT = "127.0.0.1", 8737
STATIC_DIR = config.PROJECT_ROOT / "pipeline" / "static"
REPORT_NAME = "分析报告.md"


class _Job:
    """一次管线运行（子进程）的状态（同一时刻至多一个）。"""

    def __init__(self) -> None:
        self.lock = threading.Lock()
        self.proc: subprocess.Popen | None = None
        self.running = False
        self.stopped = False          # 是否被用户中止
        self.log_lines: list[str] = []
        self.error: str | None = None
        self.report_dir: str | None = None
        self.out_dir: str | None = None  # 本次运行的产出目录（从日志解析）

    def log(self, msg: str) -> None:
        with self.lock:
            self.log_lines.append(str(msg))

    def snapshot(self) -> dict:
        with self.lock:
            return {
                "running": self.running,
                "stopped": self.stopped,
                "log": list(self.log_lines),
                "error": self.error,
                "report_dir": self.report_dir,
            }


_job = _Job()

# 浏览器页面与隐藏的本地服务绑定：最后一个页面关闭后给刷新/重连留出短暂宽限，
# 随后自动退出服务。这样用户不需要看见或手动关闭终端窗口。
_ui_lock = threading.Lock()
_ui_clients = 0
_ui_generation = 0
_ui_ever_connected = False
_UI_CLOSE_GRACE_SECONDS = 8


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
        "--code-mr", payload["code_mr"].strip(),
    ]
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
    return argv


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
        _job.report_dir = None
        _job.out_dir = None

    env = {**os.environ, "PYTHONUTF8": "1"}  # 子进程 stdout/stderr 统一 utf-8
    try:
        proc = subprocess.Popen(
            _build_argv(payload),
            cwd=str(config.PROJECT_ROOT),
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
            text=True, encoding="utf-8", errors="replace",
            env=env,
        )
    except OSError as e:
        with _job.lock:
            _job.running = False
            _job.error = f"启动分析子进程失败: {e}"
        return False, f"启动分析子进程失败: {e}"

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
        else:
            with _job.lock:
                last = next((ln for ln in reversed(_job.log_lines) if ln.strip()), "")
                _job.error = last or f"分析子进程异常退出（exit={code}）"
            _cleanup_partial_output(out_dir)
        with _job.lock:
            _job.running = False
            _job.proc = None

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
                       capture_output=True)


def _list_tasks() -> list[dict]:
    items = []
    if config.TASKS_DIR.is_dir():
        for d in sorted(config.TASKS_DIR.iterdir(), reverse=True):
            report = d / REPORT_NAME
            legacy = d / "覆盖分析报告.md"  # 手工时期的旧产出（tasks/polydiv）
            f = report if report.exists() else legacy if legacy.exists() else None
            if d.is_dir() and f:
                items.append({"dir": d.name, "file": f.name})
    return items


def _read_report(dirname: str) -> str | None:
    d = (config.TASKS_DIR / dirname).resolve()
    if d.parent != config.TASKS_DIR.resolve() or not d.is_dir():
        return None  # 防路径逃逸
    for name in (REPORT_NAME, "覆盖分析报告.md"):
        f = d / name
        if f.exists():
            return f.read_text(encoding="utf-8", errors="replace")
    return None


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _send(self, code: int, body: bytes, ctype: str) -> None:
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _json(self, obj, code: int = 200) -> None:
        self._send(code, json.dumps(obj, ensure_ascii=False).encode("utf-8"),
                   "application/json; charset=utf-8")

    def do_GET(self) -> None:  # noqa: N802（http.server 约定）
        u = urlparse(self.path)
        if u.path == "/":
            html = (STATIC_DIR / "index.html").read_bytes()
            self._send(200, html, "text/html; charset=utf-8")
        elif u.path == "/favicon.ico":
            self.send_response(204)
            self.end_headers()
        elif u.path == "/api/status":
            self._json(_job.snapshot())
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
        elif u.path == "/api/gitlab-config":
            cfg = config.load_gitlab_config()
            cfg.update({
                "logged_in": config.PW_STATE_FILE.exists(),
                "effective_proxy": config.system_proxy() or "",
                "saved": config.GITLAB_CONFIG_FILE.exists(),
            })
            self._json(cfg)
        elif u.path == "/api/ai-config":
            cfg = analyze.load_ai_config()
            # 页面只需要知道是否已保存，绝不把完整 Key 回传给浏览器。
            cfg["has_saved_key"] = bool(cfg["api_key"])
            cfg["api_key"] = ""
            # 环境变量兜底情况给前端做占位提示（不回传环境变量里的 Key 本身）。
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
                # 兼容旧前端字段。
                "env_base_url": env_base_urls[effective_protocol],
                "has_env_key": has_env_keys[effective_protocol],
                "default_model": default_models[effective_protocol],
            })
            self._json(cfg)
        elif u.path == "/api/report":
            dirname = parse_qs(u.query).get("dir", [""])[0]
            text = _read_report(dirname)
            if text is None:
                self._json({"error": "报告不存在"}, 404)
            else:
                self._json({"dir": dirname, "markdown": text})
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

        if path == "/api/parse-input":
            try:
                result = paste.parse_submission_text(str(payload.get("text", "")))
                self._json({"ok": True, **result})
            except paste.PasteParseError as e:
                self._json({"ok": False, "message": str(e)}, 400)
        elif path == "/api/run":
            if not config.PW_STATE_FILE.exists():
                self._json({
                    "ok": False,
                    "message": "尚未登录 GitLab。请先打开右上角“GitLab 设置”，配置网络并完成登录。",
                }, 400)
                return
            for field in ("name", "code_mr"):
                if not str(payload.get(field, "")).strip():
                    self._json({"ok": False, "message": f"输入有误: 缺少必填项 {field}"}, 400)
                    return
            try:
                card = TaskCard(
                    name=str(payload.get("name", "")).strip(),
                    code_mr=str(payload.get("code_mr", "")).strip(),
                    doc_mr=str(payload.get("doc_mr", "")).strip(),
                    func=str(payload.get("func", "")).strip(),
                )
                # 提前验证 URL 结构，避免启动子进程后才失败。
                _ = card.code_project
                if card.is_new_function:
                    _ = card.doc_project
            except ValueError as e:
                self._json({"ok": False, "message": f"输入有误: {e}"}, 400)
                return
            ok, message = _start_job(payload)
            self._json({"ok": ok, "message": message}, 200 if ok else 409)
        elif path == "/api/stop":
            ok, message = _stop_job()
            self._json({"ok": ok, "message": message}, 200 if ok else 409)
        elif path == "/api/gitlab-config":
            try:
                saved = config.save_gitlab_config(
                    str(payload.get("host", "")),
                    payload.get("ssh_port", ""),
                    str(payload.get("proxy", "")),
                )
                self._json({"ok": True, "message": "GitLab 配置已保存", **saved})
            except config.GitLabConfigError as e:
                self._json({"ok": False, "message": str(e)}, 400)
        elif path == "/api/gitlab-test":
            try:
                candidate = config.save_gitlab_config(
                    str(payload.get("host", "")),
                    payload.get("ssh_port", ""),
                    str(payload.get("proxy", "")),
                )
                result = login.check_connection(
                    candidate["host"], candidate["proxy"] or None
                )
                self._json({
                    "ok": True,
                    "message": f"连接成功（HTTP {result['status'] or '未知'}）",
                    **result,
                })
            except (config.GitLabConfigError, login.LoginError) as e:
                self._json({"ok": False, "message": str(e)}, 400)
        elif path == "/api/gitlab-login":
            try:
                candidate = config.save_gitlab_config(
                    str(payload.get("host", "")),
                    payload.get("ssh_port", ""),
                    str(payload.get("proxy", "")),
                )
                login.login_gitlab(candidate["host"], candidate["proxy"] or None)
                self._json({"ok": True, "message": "GitLab 登录成功，登录态已保存"})
            except (config.GitLabConfigError, login.LoginError) as e:
                self._json({"ok": False, "message": str(e)}, 400)
        elif path == "/api/ai-models":
            try:
                models = analyze.list_models(
                    str(payload.get("base_url", "")),
                    str(payload.get("api_key", "")),
                    str(payload.get("protocol", "")),
                )
                self._json({"ok": True, "models": models})
            except analyze.AnalyzeError as e:
                self._json({"ok": False, "message": str(e)}, 400)
        elif path == "/api/ai-config":
            try:
                api_key = str(payload.get("api_key", ""))
                if not api_key.strip() and payload.get("keep_api_key"):
                    api_key = analyze.load_ai_config()["api_key"]
                analyze.save_ai_config(
                    str(payload.get("base_url", "")),
                    api_key,
                    str(payload.get("model", "")),
                    str(payload.get("protocol", "")),
                )
                self._json({"ok": True, "message": "已保存"})
            except analyze.AnalyzeError as e:
                self._json({"ok": False, "message": str(e)}, 400)
        else:
            self._json({"error": "not found"}, 404)

    def log_message(self, fmt, *args) -> None:  # 静默默认访问日志
        pass


def main() -> None:
    url = f"http://{HOST}:{PORT}"
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
