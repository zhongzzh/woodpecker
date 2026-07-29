"""材料定位（docs/06）：函数文档 md、单元测试 jl（含伴随数据文件）、benchmark 目录。"""

from __future__ import annotations

import os
from pathlib import Path

from . import config
from . import repo as repo_mod


class LocateError(RuntimeError):
    pass


def local_git_repo(path: Path | str, label: str) -> Path:
    """校验约定位置确实是可供切分支的本地 Git 仓库。"""
    repo = Path(path).expanduser().resolve()
    if not repo.is_dir():
        raise LocateError(f"{label}不存在：{repo}")
    if not (repo / ".git").exists():
        raise LocateError(f"{label}不是 Git 仓库：{repo}")
    return repo


def find_local_library_repo(library: str, root: Path | str | None = None) -> Path:
    """在 Desktop/doc 约定根目录中按函数库名找到代码仓库。

    页面允许填写 ``TyImageProcessing``，实际目录可为 ``TyImageProcessing.jl``。
    这里只接受目录名，不接受任意路径，避免输入越出共享仓库根目录。
    """
    name = library.strip()
    if not name or Path(name).name != name or name in (".", "..") or "/" in name or "\\" in name:
        raise LocateError(f"函数库名称格式不正确：{library!r}")
    repo_root = Path(root) if root is not None else config.CLONE_ROOT
    candidates = [repo_root / name]
    if not name.lower().endswith(".jl"):
        candidates.append(repo_root / f"{name}.jl")
    for candidate in candidates:
        if candidate.is_dir():
            return local_git_repo(candidate, f"函数库 {name}")
    expected = " 或 ".join(str(path.resolve()) for path in candidates)
    raise LocateError(f"未找到函数库 {name!r}，已检查：{expected}")


def local_path(path_text: str, label: str, allow_directory: bool = False) -> Path:
    """校验并解析用户指定的本地路径。"""
    path = Path(path_text).expanduser().resolve()
    if not path.exists():
        raise LocateError(f"{label}不存在：{path}")
    if path.is_dir() and allow_directory:
        return path
    if not path.is_file():
        raise LocateError(f"{label}不是文件：{path}")
    return path


def local_file(path_text: str, label: str) -> Path:
    """校验并解析用户指定的本地文件路径。"""
    return local_path(path_text, label)


def _local_matches(source: Path, func: str, suffix: str, label: str) -> tuple[list[Path], Path]:
    """查找文件名严格包含函数名的本地材料。"""
    if source.is_file():
        if source.suffix.lower() != suffix or func not in source.stem:
            raise LocateError(
                f"{label}文件名必须包含完整函数名 {func!r}，且扩展名为 {suffix}：{source}"
            )
        return [source], source.parent

    hits = []
    ignored_dirs = {".git", ".venv", "__pycache__", "node_modules"}
    for directory, dirnames, filenames in os.walk(source):
        dirnames[:] = [name for name in dirnames if name not in ignored_dirs]
        hits.extend(
            Path(directory) / name for name in filenames
            if Path(name).suffix.lower() == suffix and func in Path(name).stem
        )
    hits.sort()
    if not hits:
        raise LocateError(
            f"{source} 下未找到文件名包含完整函数名 {func!r} 的 {suffix} 文件"
        )
    return hits, source


def _local_code_rank(path: Path, root: Path, func: str) -> tuple:
    """优先选测试文件作为本地代码材料的主文件，其余命中项仍全部保留。"""
    try:
        relative_parts = path.relative_to(root).parts[:-1]
    except ValueError:
        relative_parts = path.parts[:-1]
    test_file = path.stem.startswith("test_")
    in_test_tree = any(part.lower() in ("test", "tests") for part in relative_parts)
    if path.stem == func:
        name_rank = 0
    elif path.stem == f"test_{func}":
        name_rank = 1
    elif path.stem.startswith(func):
        name_rank = 2
    else:
        name_rank = 3
    return (0 if test_file or in_test_tree else 1, name_rank, str(path))


def find_local_unit_test(path_text: str, func: str, log=print) -> dict:
    """从用户指定的文件或目录中读取本地代码/单测。

    文件名必须严格包含函数名。目录模式递归收集所有命中的 ``.jl`` 文件，
    并优先选测试目录或 ``test_<func>.jl`` 作为主文件，其余作为伴随材料。
    """
    source = local_path(path_text, "本地代码/单测路径", allow_directory=True)
    matches, root = _local_matches(source, func, ".jl", "本地代码/单测")
    if source.is_file():
        matches = sorted(
            path for path in source.parent.iterdir()
            if path.is_file() and path.suffix.lower() == ".jl" and func in path.stem
        )
    matches.sort(key=lambda path: _local_code_rank(path, root, func))
    main, companions = matches[0], matches[1:]
    log(
        f"  本地代码/单测: {main}"
        + (f"（另找到相关文件 {len(companions)} 个）" if companions else "")
    )
    return {"main": main, "companions": companions, "root": root}


def find_local_docs(path_text: str, func: str, log=print) -> list[Path]:
    """从用户指定的文件或母目录中查找函数文档，允许命中多个。"""
    source = local_path(path_text, "本地文档路径", allow_directory=True)
    matches, _root = _local_matches(source, func, ".md", "本地文档")
    matches.sort(key=lambda path: (0 if path.stem == func else 1, str(path)))
    log(
        f"  本地文档: {matches[0]}"
        + (f"（另找到同函数文档 {len(matches) - 1} 个）" if len(matches) > 1 else "")
    )
    return matches


def find_doc_md(docs_repo: Path, func: str, base: str, log=print) -> Path:
    """定位函数文档 md。

    首选：MR diff 中新增（A）的 md，且文件名 == <func>.md —— 最稳（docs/06 §5）。
    兜底：syslabHelpSourceCode/projects/**/Doc/**/<func>.md 按名查找。
    """
    added = repo_mod.diff_added_files(docs_repo, base)
    added_md = [p for p in added if p.lower().endswith(".md")]
    exact = [p for p in added_md if Path(p).stem.lower() == func.lower()]
    if len(exact) == 1:
        log(f"  文档(md, 来自 MR diff): {exact[0]}")
        return docs_repo / exact[0]
    if len(exact) > 1:
        raise LocateError(f"MR diff 中有多个同名新增 md，无法确定: {exact}")

    # 兜底：全 projects 目录按名找
    hits = sorted((docs_repo / "syslabHelpSourceCode" / "projects").rglob(f"{func}.md"))
    hits = [h for h in hits if "Doc" in h.parts]
    if len(hits) == 1:
        log(f"  文档(md, 按名兜底): {hits[0].relative_to(docs_repo)}")
        return hits[0]
    if not hits:
        raise LocateError(
            f"未找到 {func}.md：MR 新增 md={added_md or '无'}；projects 下也无同名文件。"
            "请确认文档 MR 分支正确。"
        )
    raise LocateError(f"projects 下有多个 {func}.md，无法确定: {[str(h) for h in hits]}")


def read_existing_doc_md(
    docs_repo: Path, func: str, revision: str, log=print
) -> dict:
    """从既有文档基线读取函数 md，不 checkout 文档仓库工作区（性能优化任务）。"""
    try:
        paths = repo_mod.files_at_revision(docs_repo, revision)
    except repo_mod.GitError as exc:
        raise LocateError(str(exc)) from exc

    hits = [
        p for p in paths
        if Path(p).stem.lower() == func.lower()
        and p.lower().endswith(".md")
        and "Doc" in Path(p).parts
        and "syslabHelpSourceCode" in Path(p).parts
    ]
    if not hits:
        raise LocateError(f"{revision} 中未找到既有函数文档 {func}.md")
    # syslab-docs 同时包含 MultiLanguage 等项目，函数名可能重复。当前代码 MR 来自
    # syslab/packages/math，优先使用数学库帮助文档 projects/TyMath/Doc。
    tymath_hits = [
        p for p in hits
        if "projects/TyMath/Doc/" in p.replace("\\", "/")
    ]
    if len(tymath_hits) == 1:
        if len(hits) > 1:
            log(f"  同名文档共 {len(hits)} 个，数学库任务选用 projects/TyMath/Doc 下版本")
        hits = tymath_hits
    if len(hits) > 1:
        raise LocateError(f"{revision} 中有多个 {func}.md，无法确定: {hits}")
    try:
        text = repo_mod.read_text_at_revision(docs_repo, revision, hits[0])
    except repo_mod.GitError as exc:
        raise LocateError(str(exc)) from exc
    log(f"  文档(md, {revision}): {hits[0]}")
    return {"relative_path": hits[0], "text": text, "revision": revision}


def find_unit_test(code_repo: Path, func: str, log=print) -> dict:
    """定位单元测试主文件与伴随数据文件（test/<大类>/<小类>/<func>.jl + <func>_*.jl）。"""
    test_root = code_repo / "test"
    if not test_root.is_dir():
        raise LocateError(f"{code_repo} 下没有 test/ 目录")

    mains = sorted(p for p in test_root.rglob(f"{func}.jl"))
    if not mains:
        raise LocateError(
            f"test/ 下未找到 {func}.jl。请确认代码 MR 分支正确、函数名无误。"
        )
    if len(mains) > 1:
        raise LocateError(f"test/ 下有多个 {func}.jl: {[str(m) for m in mains]}")
    main = mains[0]

    companions = sorted(
        p for p in main.parent.glob(f"{func}_*.jl") if p != main
    )
    log(f"  单测: {main.relative_to(code_repo)}"
        + (f"（伴随数据 {len(companions)} 个）" if companions else ""))
    return {"main": main, "companions": companions}


def find_benchmark_dir(code_repo: Path, func: str, log=print) -> Path | None:
    """定位 benchmark/<...>/<func>/ 目录（性能基准脚本，供报告引用，非必需）。"""
    bench_root = code_repo / "benchmark"
    if not bench_root.is_dir():
        return None
    hits = sorted(p for p in bench_root.rglob(func) if p.is_dir())
    if len(hits) == 1:
        log(f"  benchmark: {hits[0].relative_to(code_repo)}")
        return hits[0]
    return hits[0] if hits else None


def read_test_bundle(unit: dict) -> str:
    """把单测主文件 + 伴随数据文件拼成给 AI 的文本（标注文件名）。"""
    parts = []
    for p in [unit["main"], *unit["companions"]]:
        parts.append(f"// ===== 文件: {p.name} =====\n{p.read_text(encoding='utf-8', errors='replace')}")
    return "\n\n".join(parts)
