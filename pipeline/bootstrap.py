"""Woodpecker 本地环境自举。

由 ``启动.bat`` 使用系统 Python 调用。首次运行创建项目内 ``.venv``，
安装 requirements.txt，并确保 Playwright Chromium 已下载；后续运行只做快速校验。
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import venv
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent
VENV_DIR = PROJECT_ROOT / ".venv"
REQUIREMENTS_FILE = PROJECT_ROOT / "requirements.txt"
STATE_FILE = VENV_DIR / ".woodpecker-bootstrap.json"
MIN_PYTHON = (3, 10)


class BootstrapError(RuntimeError):
    pass


def _venv_python() -> Path:
    if sys.platform == "win32":
        return VENV_DIR / "Scripts" / "python.exe"
    return VENV_DIR / "bin" / "python"


def _run(cmd: list[str]) -> None:
    result = subprocess.run(cmd, cwd=PROJECT_ROOT)
    if result.returncode != 0:
        raise BootstrapError(f"命令执行失败（退出码 {result.returncode}）：{' '.join(cmd)}")


def _requirements_hash() -> str:
    if not REQUIREMENTS_FILE.is_file():
        raise BootstrapError(f"缺少依赖文件：{REQUIREMENTS_FILE}")
    return hashlib.sha256(REQUIREMENTS_FILE.read_bytes()).hexdigest()


def _load_state() -> dict:
    try:
        return json.loads(STATE_FILE.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return {}


def _packages_available(python: Path) -> bool:
    probe = "import anthropic; from playwright.sync_api import sync_playwright"
    return subprocess.run(
        [str(python), "-c", probe], cwd=PROJECT_ROOT,
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    ).returncode == 0


def _chromium_available(python: Path) -> bool:
    probe = (
        "from pathlib import Path; "
        "from playwright.sync_api import sync_playwright; "
        "p=sync_playwright().start(); "
        "ok=Path(p.chromium.executable_path).is_file(); "
        "p.stop(); raise SystemExit(0 if ok else 1)"
    )
    return subprocess.run(
        [str(python), "-c", probe], cwd=PROJECT_ROOT,
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    ).returncode == 0


def _ensure_supported_python() -> None:
    if sys.version_info < MIN_PYTHON:
        required = ".".join(map(str, MIN_PYTHON))
        actual = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
        raise BootstrapError(f"需要 Python {required} 或更高版本，当前为 {actual}")


def ensure_environment() -> Path:
    """创建或修复虚拟环境，返回虚拟环境中的 Python。"""
    _ensure_supported_python()
    if not shutil.which("git"):
        raise BootstrapError(
            "未找到 Git。请先安装 Git for Windows，并配置可访问公司 GitLab 的 SSH 账号/密钥。"
        )
    digest = _requirements_hash()
    python = _venv_python()

    if not python.is_file():
        print(f"[1/3] 首次运行：创建虚拟环境 {VENV_DIR}", flush=True)
        venv.EnvBuilder(with_pip=True).create(VENV_DIR)
    else:
        print("[1/3] 虚拟环境已存在", flush=True)

    state = _load_state()
    if state.get("requirements_sha256") != digest or not _packages_available(python):
        print("[2/3] 安装/更新 Python 依赖（首次运行可能需要几分钟）……", flush=True)
        _run([
            str(python), "-m", "pip", "install", "--disable-pip-version-check",
            "-r", str(REQUIREMENTS_FILE),
        ])
    else:
        print("[2/3] Python 依赖已就绪", flush=True)

    if not _chromium_available(python):
        print("[3/3] 下载 Playwright Chromium（仅首次需要，文件较大）……", flush=True)
        _run([str(python), "-m", "playwright", "install", "chromium"])
    else:
        print("[3/3] Playwright Chromium 已就绪", flush=True)

    STATE_FILE.write_text(json.dumps({
        "requirements_sha256": digest,
        "python": f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}",
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    print("环境准备完成。", flush=True)
    return python


def check_environment() -> int:
    """只检查、不写入，供 ``启动.bat --check`` 和维护时使用。"""
    try:
        _ensure_supported_python()
        _requirements_hash()
    except BootstrapError as exc:
        print(f"[失败] {exc}")
        return 1

    print(f"[正常] 系统 Python: {sys.version.split()[0]} ({sys.executable})")
    git = shutil.which("git")
    if git:
        print(f"[正常] Git: {git}")
    else:
        print("[失败] 未找到 Git；分析时无法克隆被测仓库。")
        return 1

    python = _venv_python()
    if not python.is_file():
        print("[待初始化] .venv 不存在；正常双击启动时会自动创建。")
        return 0
    print(f"[正常] 虚拟环境: {python}")
    print("[正常] Python 依赖" if _packages_available(python) else "[待修复] Python 依赖缺失")
    print("[正常] Chromium" if _chromium_available(python) else "[待修复] Chromium 缺失")
    return 0


def main() -> None:
    parser = argparse.ArgumentParser(description="Woodpecker 环境自举")
    parser.add_argument("--check", action="store_true", help="只检查，不创建或安装")
    args = parser.parse_args()
    try:
        if args.check:
            code = check_environment()
        else:
            ensure_environment()
            code = 0
    except (BootstrapError, OSError) as exc:
        print(f"\n[环境准备失败] {exc}", file=sys.stderr, flush=True)
        code = 1
    raise SystemExit(code)


if __name__ == "__main__":
    main()
