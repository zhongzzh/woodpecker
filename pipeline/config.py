"""全局配置：路径约定、模型选择。环境变量可覆盖。"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from urllib.parse import urlparse

# ---- 路径约定 ----------------------------------------------------------
# woodpecker 项目根（本文件的上上级）
PROJECT_ROOT = Path(__file__).resolve().parent.parent

# 被测代码仓库的共享工作区。优先复用测试人员长期维护的 Desktop/doc 下现有仓库；
# 某个库不存在时也只在这里首次 clone。可用 WOODPECKER_CLONE_ROOT 覆盖。
CLONE_ROOT = Path(
    os.environ.get("WOODPECKER_CLONE_ROOT", str(Path.home() / "Desktop" / "doc"))
).expanduser()

# 文档仓库与代码仓库共享同一工作区；需要单独放置时仍可独立覆盖。
DOCS_REPO_DIR = Path(
    os.environ.get(
        "WOODPECKER_DOCS_REPO",
        str(CLONE_ROOT / "syslab-docs-2.0"),
    )
).expanduser()

# 任务产出目录：tasks/<函数名>-<日期>/
TASKS_DIR = PROJECT_ROOT / "tasks"
LOCAL_PATHS_STATE_NAME = ".local-material-paths.json"

# Playwright GitLab 登录态（网页「GitLab 设置」中人工登录生成；已 gitignore）
PW_STATE_FILE = PROJECT_ROOT / ".pw-state.json"
GITLAB_CONFIG_FILE = PROJECT_ROOT / ".gitlab-config.json"

# 覆盖分析提示词（v1 保留归档，运行使用格式更稳定的 v2）
PROMPT_FILE = PROJECT_ROOT / "docs" / "prompts" / "覆盖分析提示词-v2.md"
# 网页中保存的自定义版本。缺失时继续使用上面的项目默认提示词。
CUSTOM_PROMPT_FILE = PROJECT_ROOT / ".coverage-prompt.md"

# ---- GitLab ------------------------------------------------------------
GITLAB_HOST = "git.tongyuan.cc"  # 默认值；网页配置可覆盖
GIT_SSH_PORT = 222  # 默认值；remote 形如 ssh://git@host:port/<project>.git


class GitLabConfigError(ValueError):
    pass


def load_gitlab_config() -> dict:
    """读取当前电脑用户的 GitLab 配置；文件不存在时返回项目默认值。"""
    saved: dict = {}
    if GITLAB_CONFIG_FILE.exists():
        try:
            value = json.loads(GITLAB_CONFIG_FILE.read_text(encoding="utf-8"))
            if isinstance(value, dict):
                saved = value
        except (OSError, json.JSONDecodeError):
            saved = {}
    try:
        ssh_port = int(saved.get("ssh_port") or GIT_SSH_PORT)
    except (TypeError, ValueError):
        ssh_port = GIT_SSH_PORT
    return {
        "host": str(saved.get("host") or GITLAB_HOST).strip(),
        "ssh_port": ssh_port,
        "proxy": str(saved.get("proxy") or "").strip(),
    }


def save_gitlab_config(host: str, ssh_port: int | str, proxy: str = "") -> dict:
    """校验并保存本机 GitLab 配置。账号密码仍只在 GitLab 页面中输入。"""
    host = host.strip().rstrip("/")
    if "://" in host:
        parsed = urlparse(host)
        if parsed.scheme != "https" or not parsed.hostname or parsed.path not in ("", "/"):
            raise GitLabConfigError("GitLab 地址请填写主机名，或仅含主机名的 https:// 地址")
        host = parsed.hostname
        if parsed.port:
            host += f":{parsed.port}"
    if not host or any(c.isspace() for c in host) or "/" in host:
        raise GitLabConfigError("GitLab 地址格式不正确，例如 git.example.com")
    try:
        port = int(ssh_port)
    except (TypeError, ValueError) as e:
        raise GitLabConfigError("SSH 端口必须是数字") from e
    if not 1 <= port <= 65535:
        raise GitLabConfigError("SSH 端口必须在 1 到 65535 之间")
    proxy = proxy.strip().rstrip("/")
    if proxy:
        parsed_proxy = urlparse(proxy if "://" in proxy else f"http://{proxy}")
        try:
            _ = parsed_proxy.port
        except ValueError as e:
            raise GitLabConfigError("代理格式不正确，例如 http://127.0.0.1:7890") from e
        if (
            parsed_proxy.scheme not in ("http", "https", "socks5")
            or not parsed_proxy.hostname
            or any(c.isspace() for c in proxy)
        ):
            raise GitLabConfigError("代理格式不正确，例如 http://127.0.0.1:7890")
        if "://" not in proxy:
            proxy = f"http://{proxy}"
    value = {"host": host, "ssh_port": port, "proxy": proxy}
    GITLAB_CONFIG_FILE.write_text(
        json.dumps(value, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    return value


def gitlab_host() -> str:
    return load_gitlab_config()["host"]


def gitlab_ssh_port() -> int:
    return load_gitlab_config()["ssh_port"]


def system_proxy() -> str | None:
    """浏览器访问 GitLab 需走系统代理（实测 headless chromium 不会自动继承）。

    优先级：网页 GitLab 设置 > WOODPECKER_PROXY > Windows 系统代理 > 无代理。
    """
    saved = load_gitlab_config()["proxy"]
    if saved:
        return saved
    env = os.environ.get("WOODPECKER_PROXY")
    if env:
        return env
    if sys.platform == "win32":
        try:
            import winreg

            key = winreg.OpenKey(
                winreg.HKEY_CURRENT_USER,
                r"Software\Microsoft\Windows\CurrentVersion\Internet Settings",
            )
            enable, _ = winreg.QueryValueEx(key, "ProxyEnable")
            server, _ = winreg.QueryValueEx(key, "ProxyServer")
            if enable and server and "=" not in server:
                return f"http://{server}"
        except OSError:
            pass
    return None

# 文档仓库（新增函数的帮助文档所在，目标分支 develop）
DOCS_REPO_NAME = "syslab-docs-2.0"
DOCS_REPO_PROJECT = "syslab/syslab-docs-2.0"
DOCS_DEFAULT_BASE = "origin/develop"

# ---- AI ----------------------------------------------------------------
# 用户可在网页「AI 设置」里自选 API 地址/Key/模型，存本文件（gitignore）；
# 留空的项回落到环境变量：ANTHROPIC_AUTH_TOKEN / ANTHROPIC_BASE_URL / WOODPECKER_MODEL。
AI_CONFIG_FILE = PROJECT_ROOT / ".ai-config.json"

# 模型经 2026-07-15 实测代理支持清单后选定（docs/07 §6），可用环境变量覆盖。
MODEL = os.environ.get("WOODPECKER_MODEL", "claude-opus-4-8")
MAX_TOKENS = int(os.environ.get("WOODPECKER_MAX_TOKENS", "16000"))

# ---- 性能判定（docs/02 D13/D15/D16） ------------------------------------
# (T 下界, T 上界, x 阈值)：T 为参考耗时（秒），x 为耗时比值；x > 阈值 → 不通过
PERF_THRESHOLDS = (
    (1.0, float("inf"), 1.2),   # T > 1s
    (0.1, 1.0, 1.25),           # 0.1s <= T <= 1s
    (0.0, 0.1, 1.5),            # T < 0.1s
)
