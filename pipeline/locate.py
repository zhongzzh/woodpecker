"""材料定位（docs/06）：函数文档 md、单元测试 jl（含伴随数据文件）、benchmark 目录。"""

from __future__ import annotations

from pathlib import Path

from . import repo as repo_mod


class LocateError(RuntimeError):
    pass


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
