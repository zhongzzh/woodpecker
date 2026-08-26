"""材料定位（docs/06）：函数文档 md、单元测试 jl（含伴随数据文件）、benchmark 目录。"""

from __future__ import annotations

import os
import re
import unicodedata
from pathlib import Path, PurePosixPath

from . import config
from . import repo as repo_mod


_IGNORED_MATERIAL_DIRS = {
    ".git", ".venv", "__pycache__", "node_modules", ".cache",
}


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


def _requested_material_stem(file_name: str) -> str:
    """把用户填写的文件名归一为跨 md/代码文件共用的主体名。"""
    value = file_name.strip()
    if not value:
        raise LocateError("文件名称不能为空")
    if Path(value).name != value or value in (".", "..") or "/" in value or "\\" in value:
        raise LocateError(f"文件名称只能填写名称，不能包含目录：{file_name!r}")
    path = Path(value)
    return path.stem if path.suffix else value


def _material_name_key(file_name: str) -> str:
    """归一示例文件名：忽略数字序号、分隔符和大小写。"""
    stem = Path(file_name).stem
    stem = re.sub(r"^\d+[\s_.-]*", "", stem)
    return "".join(character for character in stem.casefold() if character.isalnum())


def find_local_named_file(
    path_text: str,
    file_name: str,
    suffix: str,
    label: str,
    log=print,
    relaxed_name: bool = False,
) -> Path:
    """按文件名从具体文件或母目录中唯一定位材料。

    ``file_name`` 可带代码或 Markdown 扩展名；定位时统一取主体名，再分别
    拼接目标扩展名，使同一个输入可同时查找 ``sample.md`` 和 ``sample.jl``。
    """
    source = local_path(path_text, f"{label}路径", allow_directory=True)
    stem = _requested_material_stem(file_name)
    expected_name = f"{stem}{suffix}"
    if source.is_file():
        # 用户已经明确选择具体文件时，以路径为准；名称只服务于母目录搜索。
        if source.suffix.casefold() != suffix.casefold():
            raise LocateError(f"{label}扩展名必须为 {suffix}：{source}")
        matches = [source]
    else:
        exact_matches = []
        normalized_matches = []
        requested_key = _material_name_key(expected_name)
        for directory, dirnames, filenames in os.walk(source):
            dirnames[:] = [
                name for name in dirnames
                if name.casefold() not in _IGNORED_MATERIAL_DIRS
            ]
            for name in filenames:
                if name.casefold() == expected_name.casefold():
                    exact_matches.append(Path(directory) / name)
                elif (
                    relaxed_name
                    and Path(name).suffix.casefold() == suffix.casefold()
                    and _material_name_key(name) == requested_key
                ):
                    normalized_matches.append(Path(directory) / name)
        matches = exact_matches or normalized_matches
        matches.sort()
        if not matches:
            match_rule = "等价于" if relaxed_name else "等于"
            raise LocateError(f"{source} 下未找到文件名{match_rule} {expected_name!r} 的{label}")
        if len(matches) > 1:
            raise LocateError(
                f"{source} 下找到多个同名{label} {expected_name!r}，请直接选择具体文件："
                f"{[str(path) for path in matches]}"
            )
    log(f"  {label}: {matches[0]}")
    return matches[0]


def find_local_named_code(path_text: str, file_name: str, log=print) -> Path:
    """按用户填写的文件名定位代码文件；缺省代码扩展名为 ``.jl``。"""
    supplied_suffix = Path(file_name.strip()).suffix.lower()
    suffix = supplied_suffix if supplied_suffix and supplied_suffix != ".md" else ".jl"
    return find_local_named_file(
        path_text, file_name, suffix, "代码文件", relaxed_name=True, log=log
    )


def find_local_named_doc(path_text: str, file_name: str, log=print) -> Path:
    """按用户填写的文件名定位对应的 Markdown 文件。"""
    return find_local_named_file(path_text, file_name, ".md", "Markdown 文档", log=log)


def _local_matches(
    source: Path,
    func: str,
    suffix: str,
    label: str,
    exact_name: bool = False,
) -> tuple[list[Path], Path]:
    """查找本地材料；文档可要求文件主体与函数名严格相等。"""
    if source.is_file():
        name_matches = (
            source.stem.casefold() == func.casefold()
            if exact_name
            else func in source.stem
        )
        if source.suffix.lower() != suffix or not name_matches:
            raise LocateError(
                f"{label}文件名必须"
                + (f"严格等于完整函数名 {func!r}" if exact_name else f"包含完整函数名 {func!r}")
                + f"，且扩展名为 {suffix}：{source}"
            )
        return [source], source.parent

    hits = []
    for directory, dirnames, filenames in os.walk(source):
        dirnames[:] = [
            name for name in dirnames
            if name.casefold() not in _IGNORED_MATERIAL_DIRS
        ]
        for name in filenames:
            path = Path(directory) / name
            if path.suffix.lower() != suffix:
                continue
            if exact_name and path.stem.casefold() != func.casefold():
                continue
            if not exact_name and func not in path.stem:
                continue
            hits.append(path)
    hits.sort()
    if not hits:
        raise LocateError(
            f"{source} 下未找到文件名"
            + (f"严格等于完整函数名 {func!r}" if exact_name else f"包含完整函数名 {func!r}")
            + f" 的 {suffix} 文件"
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


def find_local_docs(
    path_text: str, func: str, log=print, preferred_project: str = ""
) -> list[Path]:
    """从用户指定的文件或母目录中查找函数文档。

    文档文件名必须严格等于 ``<func>.md``，避免 ``dice`` 误命中
    ``nrPBCHDMRSIndices.md`` 这类仅包含子串的文件。文档仓库中可能有多个
    项目保存同名函数文档；自动定位模式可传入 ``preferred_project``，优先
    保留 ``projects/<项目名>`` 下的命中。
    """
    source = local_path(path_text, "本地文档路径", allow_directory=True)
    matches, _root = _local_matches(
        source, func, ".md", "本地文档", exact_name=True
    )
    project = preferred_project.strip().removesuffix(".jl")
    if project and len(matches) > 1:
        project_matches = []
        for path in matches:
            parts = path.parts
            if any(
                part.lower() == "projects"
                and index + 1 < len(parts)
                and parts[index + 1].lower() == project.lower()
                for index, part in enumerate(parts)
            ):
                project_matches.append(path)
        if project_matches:
            log(
                f"  同名文档共 {len(matches)} 个，按函数库选择 "
                f"projects/{project} 下的 {len(project_matches)} 个"
            )
            matches = project_matches
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


def existing_doc_paths(docs_repo: Path, func: str, revision: str) -> list[str]:
    """列出既有文档基线中的同名函数文档，并应用可靠的项目优先规则。"""
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
        hits = tymath_hits
    return sorted(hits)


def _normalized_doc_content(text: str) -> str:
    """忽略 Markdown 标记、空白、大小写和全半角差异后比较正文内容。"""
    normalized = unicodedata.normalize("NFKC", text).casefold()
    return "".join(character for character in normalized if character.isalnum())


def _doc_content_similarity(reference: str, candidate: str) -> float:
    """用字符片段 Dice/包含度计算线性复杂度的正文相似度。"""
    if not reference or not candidate:
        return 0.0
    if reference == candidate:
        return 1.0
    width = 7
    reference_fragments = {
        reference[index:index + width]
        for index in range(max(1, len(reference) - width + 1))
    }
    candidate_fragments = {
        candidate[index:index + width]
        for index in range(max(1, len(candidate) - width + 1))
    }
    overlap = len(reference_fragments & candidate_fragments)
    if not overlap:
        return 0.0
    dice = 2 * overlap / (len(reference_fragments) + len(candidate_fragments))
    containment = overlap / min(len(reference_fragments), len(candidate_fragments))
    return max(dice, containment)


def match_existing_doc_content(
    docs_repo: Path, func: str, revision: str, reference_text: str
) -> dict:
    """用用户提供的文档正文从同名候选中选出唯一且可信的一份。"""
    reference = _normalized_doc_content(reference_text)
    if len(reference) < 24:
        raise LocateError("粘贴的文档有效内容过短，请粘贴更完整的函数文档")

    candidates = existing_doc_paths(docs_repo, func, revision)
    scored = []
    for relative_path in candidates:
        try:
            candidate_text = repo_mod.read_text_at_revision(
                docs_repo, revision, relative_path
            )
        except repo_mod.GitError as exc:
            raise LocateError(str(exc)) from exc
        candidate = _normalized_doc_content(candidate_text)
        score = _doc_content_similarity(reference, candidate)
        scored.append({"relative_path": relative_path, "score": score})

    scored.sort(key=lambda item: (-item["score"], item["relative_path"]))
    best = scored[0]
    runner_up = scored[1]["score"] if len(scored) > 1 else 0.0
    if best["score"] < 0.55 or (
        len(scored) > 1 and best["score"] - runner_up < 0.06
    ):
        summary = "；".join(
            f"{item['relative_path']}={item['score']:.0%}" for item in scored
        )
        raise LocateError(
            "粘贴内容无法唯一匹配候选文档，请粘贴更完整的内容。"
            f"当前相似度：{summary}"
        )
    return {**best, "scores": scored}


def read_existing_doc_md(
    docs_repo: Path, func: str, revision: str, log=print,
    preferred_path: str = "",
) -> dict:
    """从既有文档基线读取函数 md，不 checkout 文档仓库工作区（性能优化任务）。"""
    hits = existing_doc_paths(docs_repo, func, revision)
    selected = preferred_path.strip().replace("\\", "/")
    if selected:
        if selected not in hits:
            raise LocateError(
                f"指定的既有文档不属于 {revision} 中 {func}.md 的候选：{selected}"
            )
        hits = [selected]
    elif len(hits) == 1 and "projects/TyMath/Doc/" in hits[0].replace("\\", "/"):
        # 保留原有自动选择规则的可见日志。
        log("  数学库任务选用 projects/TyMath/Doc 下版本")
    if len(hits) > 1:
        raise LocateError(f"{revision} 中有多个 {func}.md，无法确定: {hits}")
    try:
        text = repo_mod.read_text_at_revision(docs_repo, revision, hits[0])
    except repo_mod.GitError as exc:
        raise LocateError(str(exc)) from exc
    log(f"  文档(md, {revision}): {hits[0]}")
    return {"relative_path": hits[0], "text": text, "revision": revision}


def _performance_path_contexts(perf_note: dict | None, func: str) -> list[tuple[str, ...]]:
    """Extract benchmark directory context before ``func`` from report rows."""
    if not perf_note:
        return []
    target = func.casefold()
    contexts: list[tuple[str, ...]] = []
    for table in perf_note.get("tables", []):
        headers = table.get("headers", [])
        indices = {name: index for index, name in enumerate(headers)}
        path_indices = [
            indices[name] for name in ("git_file", "benchmark_path")
            if name in indices
        ]
        func_index = indices.get("func_name")
        for row in table.get("rows", []):
            if (
                func_index is not None
                and func_index < len(row)
                and str(row[func_index]).strip().casefold() != target
            ):
                continue
            for path_index in path_indices:
                if path_index >= len(row):
                    continue
                raw_path = str(row[path_index]).strip()
                if not raw_path or raw_path.casefold() == "nan":
                    continue
                parts = PurePosixPath(raw_path.replace("\\", "/")).parts
                lowered = [part.casefold() for part in parts]
                try:
                    func_position = lowered.index(target)
                except ValueError:
                    continue
                try:
                    benchmark_position = lowered.index("benchmark", 0, func_position)
                except ValueError:
                    continue
                context = tuple(lowered[benchmark_position + 1:func_position])
                if context and context not in contexts:
                    contexts.append(context)
    return contexts


def _common_prefix_length(left: tuple[str, ...], right: tuple[str, ...]) -> int:
    count = 0
    for left_part, right_part in zip(left, right):
        if left_part != right_part:
            break
        count += 1
    return count


def _common_suffix_length(left: tuple[str, ...], right: tuple[str, ...]) -> int:
    return _common_prefix_length(tuple(reversed(left)), tuple(reversed(right)))


def _unit_test_context(code_repo: Path, path: Path) -> tuple[str, ...]:
    relative = path.relative_to(code_repo)
    parts = tuple(part.casefold() for part in relative.parts)
    if parts and parts[0] == "test":
        return parts[1:-1]
    return parts[:-1]


def _select_unit_test_from_performance(
    code_repo: Path, mains: list[Path], func: str, perf_note: dict | None
) -> Path | None:
    contexts = _performance_path_contexts(perf_note, func)
    if not contexts:
        return None

    scored: list[tuple[tuple[int, int, int, int], Path]] = []
    for candidate in mains:
        candidate_context = _unit_test_context(code_repo, candidate)
        scores = []
        for context in contexts:
            exact = int(candidate_context == context)
            suffix = _common_suffix_length(candidate_context, context)
            prefix = _common_prefix_length(candidate_context, context)
            overlap = len(set(candidate_context) & set(context))
            scores.append((exact, suffix, prefix, overlap))
        scored.append((max(scores), candidate))

    best_score = max(score for score, _candidate in scored)
    if best_score == (0, 0, 0, 0):
        return None
    winners = [candidate for score, candidate in scored if score == best_score]
    return winners[0] if len(winners) == 1 else None


def find_unit_test(
    code_repo: Path, func: str, log=print, perf_note: dict | None = None
) -> dict:
    """定位单测；同名文件用性能报告 benchmark 路径消歧。"""
    test_root = code_repo / "test"
    if not test_root.is_dir():
        raise LocateError(f"{code_repo} 下没有 test/ 目录")

    mains = sorted(p for p in test_root.rglob(f"{func}.jl"))
    if not mains:
        raise LocateError(
            f"test/ 下未找到 {func}.jl。请确认代码 MR 分支正确、函数名无误。"
        )
    if len(mains) > 1:
        selected = _select_unit_test_from_performance(
            code_repo, mains, func, perf_note
        )
        if selected is None:
            raise LocateError(
                f"test/ 下有多个 {func}.jl，性能报告路径也无法唯一确定: "
                f"{[str(m) for m in mains]}"
            )
        main = selected
        log(
            f"  同名 {func}.jl 共 {len(mains)} 个，"
            f"根据性能报告 benchmark 路径选择: {main.relative_to(code_repo)}"
        )
    else:
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
