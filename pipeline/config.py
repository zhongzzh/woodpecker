"""全局配置：路径约定、模型选择。环境变量可覆盖。"""

from __future__ import annotations

import os
import sys
from pathlib import Path

# ---- 路径约定 ----------------------------------------------------------
# 仓库克隆根目录（docs/06 取数流程：固定位置，已存在则不重复克隆）
CLONE_ROOT = Path(os.environ.get("WOODPECKER_CLONE_ROOT", r"C:\Users\TR\Desktop\doc"))

# woodpecker 项目根（本文件的上上级）
PROJECT_ROOT = Path(__file__).resolve().parent.parent

# 任务产出目录：tasks/<函数名>-<日期>/
TASKS_DIR = PROJECT_ROOT / "tasks"

# playwright 登录态文件（git.tongyuan.cc 会话 cookie；已 gitignore）
# 首次生成：python -m pipeline.login（headed 浏览器人工登录一次）
PW_STATE_FILE = PROJECT_ROOT / ".pw-state.json"

# 覆盖分析提示词（v1 基线，docs/prompts）
PROMPT_FILE = PROJECT_ROOT / "docs" / "prompts" / "覆盖分析提示词-v1.md"

# ---- GitLab ------------------------------------------------------------
GITLAB_HOST = "git.tongyuan.cc"
GIT_SSH_PORT = 222  # remote 形如 ssh://git@git.tongyuan.cc:222/<project>.git


def system_proxy() -> str | None:
    """浏览器访问 GitLab 需走系统代理（实测 headless chromium 不会自动继承）。

    优先级：WOODPECKER_PROXY 环境变量 > Windows 系统代理设置 > 无代理。
    """
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
