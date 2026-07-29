"""git 只读取数（docs/06 流程；docs/02 D17/D18）。

只读边界在本模块物理强制：仅封装 clone / fetch / checkout / pull / stash。
本模块【不实现】push、commit、reset --hard、clean 等任何改写历史或远端的操作。
"""

from __future__ import annotations

import subprocess
from pathlib import Path

from . import config


class GitError(RuntimeError):
    pass


def _git(repo: Path | None, *args: str, check: bool = True) -> subprocess.CompletedProcess:
    """在 repo 下执行 git 命令，返回 CompletedProcess（utf-8 文本）。"""
    cmd = ["git"]
    if repo is not None:
        cmd += ["-C", str(repo)]
    cmd += list(args)
    proc = subprocess.run(
        cmd, capture_output=True, text=True, encoding="utf-8", errors="replace"
    )
    if check and proc.returncode != 0:
        raise GitError(f"git {' '.join(args)} 失败:\n{proc.stderr.strip()}")
    return proc


def ssh_url(project_path: str) -> str:
    return (
        f"ssh://git@{config.gitlab_host()}:{config.gitlab_ssh_port()}/"
        f"{project_path}.git"
    )


def ensure_repo(
    project_path: str, log=print, local_path: Path | str | None = None
) -> Path:
    """仓库已存在则直接用；不存在才 clone（D17）。返回本地路径。

    ``local_path`` 用于复用约定好的独立工作区，例如所有任务共享的文档仓库；
    未指定时使用共享的 ``CLONE_ROOT/<项目名>`` 代码仓库工作区；会先复用
    Desktop/doc 下已有版本，不存在才在同一位置首次 clone。
    """
    name = project_path.rsplit("/", 1)[-1]
    local = Path(local_path).expanduser() if local_path else config.CLONE_ROOT / name
    if (local / ".git").exists():
        log(f"  仓库已存在: {local}")
        return local
    local.parent.mkdir(parents=True, exist_ok=True)
    log(f"  克隆 {project_path} -> {local} （首次，可能较慢）")
    _git(None, "clone", ssh_url(project_path), str(local))
    return local


def refresh_repo(repo: Path, log=print) -> bool:
    """只执行 fetch，供不切工作分支的只读 revision 读取使用。"""
    fetch = _git(repo, "fetch", "origin", check=False)
    if fetch.returncode != 0:
        log("  ⚠️ git fetch 失败，继续使用本地已有的远端引用")
        return False
    return True


def files_at_revision(repo: Path, revision: str) -> list[str]:
    """列出 revision 中的全部文件，不 checkout、不改工作区。"""
    proc = _git(repo, "ls-tree", "-r", "--name-only", revision, check=False)
    if proc.returncode != 0:
        raise GitError(f"无法读取文档版本 {revision}:\n{proc.stderr.strip()}")
    return [line.strip() for line in proc.stdout.splitlines() if line.strip()]


def read_text_at_revision(repo: Path, revision: str, path: str) -> str:
    """读取 revision:path 的 UTF-8 文本，不 checkout、不改工作区。"""
    proc = _git(repo, "show", f"{revision}:{path}", check=False)
    if proc.returncode != 0:
        raise GitError(f"无法读取 {revision}:{path}:\n{proc.stderr.strip()}")
    return proc.stdout


def prepare_branch(repo: Path, branch: str, log=print) -> dict:
    """fetch → (必要时 stash) → checkout → pull。返回操作记录。

    - 工作区有未提交改动且阻碍切换时，用 stash 暂存（不丢弃，可 stash pop 还原）。
    - 源分支已在远端删除（MR 已合并）时 pull 失败不致命，使用本地已有分支。
    """
    record: dict = {"repo": str(repo), "branch": branch, "stashed": False, "pulled": False}

    fetch = _git(repo, "fetch", "origin", check=False)
    if fetch.returncode != 0:
        # 内网不通等场景：本地已有该分支时仍可继续（数据可能略旧，日志明示）
        log("  ⚠️ git fetch 失败（内网不通？），尝试直接用本地已有分支")

    status = _git(repo, "status", "--porcelain").stdout.strip()
    checkout = _git(repo, "checkout", branch, check=False)
    if checkout.returncode != 0:
        if status:
            log("  工作区有未提交改动，git stash 暂存（不会丢失，可用 git stash pop 还原）")
            _git(repo, "stash", "push", "-m", f"woodpecker暂存: 切换到 {branch} 前")
            record["stashed"] = True
            checkout = _git(repo, "checkout", branch, check=False)
        if checkout.returncode != 0:
            raise GitError(f"切换分支 {branch} 失败:\n{checkout.stderr.strip()}")

    pull = _git(repo, "pull", check=False)
    if pull.returncode == 0:
        record["pulled"] = True
    else:
        # 典型场景：MR 已合并、远端分支已删除 —— 用本地分支即可
        log(f"  pull 未成功（{pull.stderr.strip().splitlines()[-1] if pull.stderr.strip() else '未知原因'}），使用本地分支")

    record["head"] = _git(repo, "log", "-1", "--format=%h %s").stdout.strip()
    log(f"  就位: {branch} @ {record['head']}")
    return record


def diff_added_files(repo: Path, base: str) -> list[str]:
    """列出当前 HEAD 相对 base 新增（状态 A）的文件路径。"""
    out = _git(repo, "diff", "--name-status", f"{base}...HEAD").stdout
    added = []
    for line in out.splitlines():
        parts = line.split("\t")
        if len(parts) >= 2 and parts[0].strip() == "A":
            added.append(parts[-1].strip())
    return added
