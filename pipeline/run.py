"""管线串联入口（P1：命令行跑通全流程）。

新增函数用法：
  python -m pipeline.run --name "新增 polydiv 函数" \
      --code-mr https://git.tongyuan.cc/.../merge_requests/856 \
      --doc-mr  https://git.tongyuan.cc/syslab/syslab-docs-2.0/-/merge_requests/3761 \
      [--func polydiv] [--no-ai]

性能优化用法：
  python -m pipeline.run --name "ode89 函数性能优化" \
      --code-mr https://git.tongyuan.cc/.../merge_requests/NNN

本地材料用法：
  python -m pipeline.run --name "graydiffweight" \
      --local-library TyImageProcessing --local-branch pyh/add_graydiffweight \
      [--perf-report-file C:\\path\\to\\performance.txt]

步骤（docs/07 §1 管线）：
  1 任务卡 → 2 文档 MR 取分支+定位 md → 3 代码 MR 取分支+性能报告+定位单测
  → 4 AI 覆盖分析 → 5 性能判定 → 6 拼总报告 + 材料快照，落 tasks/<函数>-<时间>/
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from datetime import datetime
from pathlib import Path

from . import analyze, config, doc_html, locate, mr, perf, repo
from .taskcard import TaskCard


def _log(msg: str) -> None:
    print(msg, flush=True)


def _snapshot_material(source: Path, materials: Path) -> Path:
    """复制材料快照；不同目录的同名文件使用序号保留，避免相互覆盖。"""
    target = materials / source.name
    index = 2
    while target.exists():
        target = materials / f"{source.stem}-{index}{source.suffix}"
        index += 1
    shutil.copy2(source, target)
    return target


def _performance_email_text(result: dict | None, performed: bool = True) -> str:
    """性能明细转换成总结邮件中的简短结论。"""
    if not performed:
        return "本次未进行性能分析"
    if not result:
        return "性能验证待确认"
    if result.get("mode") == "ai_failed":
        return "性能测试 AI 分析失败（原始报告已保留）"
    if result.get("mode") == "pasted":
        return result.get("verdict") or "性能测试结论无法判定"
    if result.get("mode") == "performance_optimization":
        if result["passed"] is True:
            return "性能验证通过（未衰退）"
        if result["passed"] is False:
            return "性能验证不通过（发生衰退）"
        return "性能验证无法完整判定"
    first = [c.passed for v in result["verdicts"] for c in v.checks if c.label == "首次"]
    second = [c.passed for v in result["verdicts"] for c in v.checks if c.label == "二次"]
    first_text = "通过" if first and all(first) else "不通过"
    second_text = "通过" if second and all(second) else "不通过"
    if first_text == "通过" and second_text == "通过":
        return "性能验证通过"
    return f"性能验证首次{first_text}，二次{second_text}"


def _summary_email(
    card: TaskCard, perf_result: dict | None, performance_performed: bool = True,
    functional_performed: bool = True, local_code_files: list[Path] | None = None,
    local_doc_files: list[Path] | None = None,
) -> str:
    """生成可直接复制的周提测总结邮件文本；版本号由测试人员手填。"""
    library = (
        card.local_library.removesuffix(".jl")
        if card.is_local and card.local_library.strip()
        else card.func if card.is_local else card.code_repo_name.removesuffix(".jl")
    )
    functional_text = "功能验证通过" if functional_performed else "功能验证未进行"
    if card.is_doc_code_consistency:
        lines = [f"{card.name}，文档代码一致性检查已完成"]
    else:
        lines = [
            f"{card.name}，{functional_text}，"
            f"{_performance_email_text(perf_result, performance_performed)}，请补充自动化脚本",
        ]
    if card.is_local:
        source_label = (
            f"本地仓库分支 {card.local_branch} 自动定位"
            if card.uses_local_repositories else "用户电脑本地文件"
        )
        code_label = "代码文件：" if card.is_doc_code_consistency else "代码/单测："
        doc_label = "Markdown 文档：" if card.is_doc_code_consistency else "帮助文档："
        lines += [
            f"分析材料来自{source_label}：",
            "",
            code_label,
            *(str(path) for path in (local_code_files or [Path(card.local_code)])),
            "",
            doc_label,
            *(str(path) for path in (local_doc_files or [Path(card.local_doc)])),
        ]
    else:
        lines += [
            "函数代码未合并，请dev对应分支后验证，地址如下：",
            "",
            "提测函数库分支：",
            card.code_mr,
        ]
    if not card.is_local and card.is_new_function:
        lines += ["", "提测函数帮助文档分支：", card.doc_mr]
    elif not card.is_local:
        lines += ["", f"帮助文档：本地既有文档（{config.DOCS_REPO_NAME} / {config.DOCS_DEFAULT_BASE}）"]
    lines += ["", f"{library}："]
    return "\n".join(lines)


def _leadership_summary(
    card: TaskCard, perf_result: dict | None,
    performance_performed: bool = True,
    functional_performed: bool = True,
) -> str:
    """生成报告末尾可直接复制给上级的固定格式结论。"""
    functional_text = (
        "功能单点验证通过" if functional_performed else "功能单点验证未进行"
    )
    performance_text = _performance_email_text(
        perf_result, performance_performed
    )
    if performance_text in ("性能通过", "性能不通过") or performance_text.startswith(
        "性能首次"
    ):
        performance_text = f"性能验证{performance_text.removeprefix('性能')}"
    if card.is_new_function:
        test_item = f"新增{card.func}函数"
    elif card.is_performance_optimization:
        test_item = f"{card.func}函数性能优化"
    else:
        test_item = card.name.strip()
    return "\n".join([
        f"{card.name}，{functional_text}，"
        f"{performance_text}",
        "测试环境：windows",
        f"测试项：{test_item}",
        "遗留缺陷：无",
    ])


def refresh_and_build_document(card: TaskCard, log=_log) -> dict:
    """强制更新文档分支并编译函数 HTML，不进入代码与分析流程。"""
    if not card.is_local or not card.uses_local_repositories:
        raise ValueError("仅更新文档模式需要函数名、函数库名称和源分支")

    log(f"文档更新任务: {card.func}（函数库 {card.local_library}）")
    docs_repo = repo.ensure_repo(
        config.DOCS_REPO_PROJECT, log=log, local_path=config.DOCS_REPO_DIR
    )
    log(f"[文档更新] 以远端为准强制同步文档分支 {card.local_branch}")
    branch_info = repo.force_sync_branch(
        docs_repo, card.local_branch, log=log
    )
    doc_files = locate.find_local_docs(
        str(docs_repo), card.func, log=log,
        preferred_project=card.local_library,
    )
    doc_relative = doc_files[0].relative_to(docs_repo).as_posix()
    log("[文档编译] 编译并打开函数 HTML")
    preview = doc_html.build_and_open(
        docs_repo, doc_relative, card.func, log=log
    )
    log(f"文档更新完成: {doc_files[0]}")
    return {
        "repository": str(docs_repo),
        "branch": branch_info,
        "documents": [str(path) for path in doc_files],
        "preview": preview,
    }


def run(card: TaskCard, skip_ai: bool = False, build_doc_html: bool = False,
        doc_branch: str = "", code_branch: str = "",
        perf_report_text: str = "", log=_log) -> Path:
    _log = log  # 允许 Web 壳注入日志收集器；缺省打印到控制台
    out_dir = card.make_output_dir()
    materials = out_dir / "materials"
    materials.mkdir(exist_ok=True)
    _log(f"任务: {card.name}（函数 {card.func}）")
    _log(f"产出目录: {out_dir}")
    local_doc_compile_error = None

    # ---- 步骤 1/5 文档侧 --------------------------------------------------
    if card.is_local:
        if card.is_doc_code_consistency:
            _log("[1/5] 根据文件名定位 Markdown 文档")
            local_doc_files = [
                locate.find_local_named_doc(card.local_doc, card.name, log=_log)
            ]
            doc_info = {"source_branch": "本地文件", "perf_note": None}
        elif card.uses_local_repositories:
            _log(f"[1/5] 优先定位本地 {card.func}.md，未找到时再同步文档分支")
            docs_repo = locate.local_git_repo(config.DOCS_REPO_DIR, "文档仓库")
            doc_search_root = str(docs_repo)
            try:
                local_doc_files = locate.find_local_docs(
                    doc_search_root, card.func, log=_log,
                    preferred_project=card.local_library,
                )
            except locate.LocateError:
                _log(
                    f"  当前文档工作区未找到 {card.func}.md，"
                    f"同步分支 {card.local_branch} 后重试"
                )
                repo.prepare_branch(docs_repo, card.local_branch, log=_log)
                local_doc_files = locate.find_local_docs(
                    doc_search_root, card.func, log=_log,
                    preferred_project=card.local_library,
                )
                doc_branch = card.local_branch
            else:
                _log("  已命中本地文档，跳过文档仓库 fetch/checkout/pull")
                doc_branch = "当前工作区（未切换）"
            doc_info = {"source_branch": doc_branch, "perf_note": None}
        elif not card.is_doc_code_consistency:
            _log("[1/5] 根据函数名定位本地文档")
            doc_search_root = card.local_doc
            doc_info = {"source_branch": "本地文件", "perf_note": None}
            local_doc_files = locate.find_local_docs(
                doc_search_root, card.func, log=_log,
                preferred_project=card.local_library,
            )
        doc_md = "\n\n".join(
            f"<!-- 本地文档：{path} -->\n"
            + path.read_text(encoding="utf-8", errors="replace")
            for path in local_doc_files
        )
        if card.uses_local_repositories:
            doc_rel = local_doc_files[0].relative_to(docs_repo).as_posix()
        else:
            doc_rel = local_doc_files[0].name
            if build_doc_html:
                try:
                    docs_repo = locate.local_git_repo(config.DOCS_REPO_DIR, "文档仓库")
                    doc_rel = local_doc_files[0].relative_to(docs_repo).as_posix()
                except (locate.LocateError, ValueError) as exc:
                    local_doc_compile_error = (
                        "手动选择的文档不在可编译文档仓库中："
                        f"{local_doc_files[0]}（{exc}）"
                    )
        for doc_path in local_doc_files:
            _snapshot_material(doc_path, materials)
        if card.uses_local_repositories:
            doc_source = (
                f"本地 {config.DOCS_REPO_NAME}（{doc_branch}）"
                + "、".join(f"`{path.relative_to(docs_repo).as_posix()}`" for path in local_doc_files)
            )
        else:
            doc_source = "用户本地文件 " + "、".join(f"`{path}`" for path in local_doc_files)
    elif card.is_new_function:
        _log("[1/5] 文档 MR 取数")
        if doc_branch:
            _log(f"  使用人工指定分支（降级模式，跳过 MR 页面）: {doc_branch}")
            doc_info = {"source_branch": doc_branch, "perf_note": None}
        else:
            doc_info = mr.read_mr(card.doc_mr, log=_log)
        docs_repo = repo.ensure_repo(
            card.doc_project, log=_log, local_path=config.DOCS_REPO_DIR
        )
        repo.prepare_branch(docs_repo, doc_info["source_branch"], log=_log)
        doc_md_path = locate.find_doc_md(
            docs_repo, card.func, config.DOCS_DEFAULT_BASE, log=_log
        )
        doc_md = doc_md_path.read_text(encoding="utf-8", errors="replace")
        doc_rel = doc_md_path.relative_to(docs_repo).as_posix()
        shutil.copy2(doc_md_path, materials / doc_md_path.name)
        doc_source = (
            f"{card.doc_repo_name} MR（分支 {doc_info['source_branch']}）`{doc_rel}`"
        )
    else:
        _log("[1/5] 本地既有文档取数（性能优化，无需文档 MR）")
        docs_repo = repo.ensure_repo(
            config.DOCS_REPO_PROJECT, log=_log, local_path=config.DOCS_REPO_DIR
        )
        repo.refresh_repo(docs_repo, log=_log)
        doc_material = locate.read_existing_doc_md(
            docs_repo, card.func, config.DOCS_DEFAULT_BASE, log=_log
        )
        doc_info = {"source_branch": doc_material["revision"], "perf_note": None}
        doc_rel = doc_material["relative_path"]
        doc_md = doc_material["text"]
        (materials / f"{card.func}.md").write_text(doc_md, encoding="utf-8")
        doc_source = f"本地 {config.DOCS_REPO_NAME}（{doc_material['revision']}）`{doc_rel}`"

    # 文档分支已经就位后，编译真实 md 所属的帮助项目并打开函数 HTML。
    # 项目名来自 projects/<项目名>/...，不能直接照搬代码仓库名（例如
    # TyStatisticsCore.jl 的帮助项目实际是 TyStatistics）。
    doc_html_info = None
    doc_html_error = local_doc_compile_error
    if build_doc_html and (card.is_new_function or card.is_local) and not doc_html_error:
        _log("  [文档预览] 编译 HTML")
        try:
            doc_html_info = doc_html.build_and_open(
                docs_repo, doc_rel, card.func, log=_log
            )
        except doc_html.DocHtmlError as exc:
            doc_html_error = str(exc).replace("\r", " ").replace("\n", " ").strip()
            _log(f"  ⚠️ 文档 HTML 编译/打开失败，继续分析：{doc_html_error}")

    # ---- 步骤 2/5 代码侧：MR → 分支 → 单测 + 性能报告 --------------------
    if card.is_local:
        if card.is_doc_code_consistency:
            _log("[2/5] 根据文件名定位代码文件")
            code_file = locate.find_local_named_code(
                card.local_code, card.name, log=lambda _msg: None
            )
            unit = {"main": code_file, "companions": [], "root": code_file.parent}
            code_repo = code_file.parent
            code_info = {"source_branch": "本地文件", "perf_note": None}
        elif card.uses_local_repositories:
            _log(f"[2/5] 同步函数库 {card.local_library} 并定位代码/单测")
            code_repo = locate.find_local_library_repo(card.local_library)
            repo.prepare_branch(code_repo, card.local_branch, log=_log)
            unit = locate.find_local_unit_test(str(code_repo), card.func, log=lambda _msg: None)
            code_info = {"source_branch": card.local_branch, "perf_note": None}
        else:
            _log("[2/5] 根据函数名定位本地代码/单测")
            unit = locate.find_local_unit_test(card.local_code, card.func, log=lambda _msg: None)
            code_repo = unit["root"]
            code_info = {"source_branch": "本地文件", "perf_note": None}
        _log(f"  {'代码文件' if card.is_doc_code_consistency else '本地代码/单测'}: {unit['main']}"
             + (f"（另找到相关文件 {len(unit['companions'])} 个）" if unit["companions"] else ""))
        (out_dir / config.LOCAL_PATHS_STATE_NAME).write_text(
            json.dumps({
                "local_code": str(unit["main"]),
                "local_doc": str(local_doc_files[0]),
                "local_code_files": [
                    str(path) for path in [unit["main"], *unit["companions"]]
                ],
                "local_doc_files": [str(path) for path in local_doc_files],
            }, ensure_ascii=False),
            encoding="utf-8",
        )
        bench = None
    else:
        _log("[2/5] 代码 MR 取数")
        if code_branch:
            _log(f"  使用人工指定分支（降级模式，跳过 MR 页面，无性能报告）: {code_branch}")
            code_info = {"source_branch": code_branch, "perf_note": None}
        else:
            code_info = mr.read_mr(card.code_mr, log=_log, func=card.func)
        code_repo = repo.ensure_repo(card.code_project, log=_log)
        repo.prepare_branch(code_repo, code_info["source_branch"], log=_log)
        unit = locate.find_unit_test(
            code_repo, card.func, log=_log,
            perf_note=code_info.get("perf_note"),
        )
        bench = locate.find_benchmark_dir(code_repo, card.func, log=_log)
    test_bundle = locate.read_test_bundle(unit)
    for p in [unit["main"], *unit["companions"]]:
        _snapshot_material(p, materials)

    # ---- 步骤 3/5 AI 覆盖分析 --------------------------------------------
    coverage_ai_error = None
    consistency_status = None
    consistency_ai_response_file = None
    functional_performed = False
    if card.is_doc_code_consistency:
        code_text = unit["main"].read_text(encoding="utf-8", errors="replace")
        if skip_ai:
            _log("[3/5] 文档与代码一致性检查：--no-ai，仅保留文本初筛")
            consistency_status = "not_reviewed"
            coverage_ai_status = "skipped"
            coverage_md = (
                "> ⚠️ 本次使用 `--no-ai`，下方仅为文本候选差异，不能据此判断代码是否语义缺失。\n\n"
                + analyze.document_code_consistency(
                    doc_md, code_text,
                    doc_name=local_doc_files[0].name,
                    code_name=unit["main"].name,
                )
            )
        else:
            _log("[3/5] 文档与代码一致性检查（文本初筛 + AI 语义复审）")
            try:
                consistency = analyze.document_code_consistency_analysis(
                    doc_md, code_text,
                    doc_name=local_doc_files[0].name,
                    code_name=unit["main"].name,
                    log=_log,
                )
                coverage_md = consistency["markdown"]
                consistency_status = consistency["status"]
                raw_path = materials / "文档代码一致性-AI原始返回.json"
                raw_path.write_text(consistency["raw"], encoding="utf-8")
                consistency_ai_response_file = raw_path.relative_to(out_dir).as_posix()
                coverage_ai_status = "completed"
                functional_performed = True
            except analyze.AnalyzeError as exc:
                coverage_ai_status = "failed"
                consistency_status = "undetermined"
                coverage_ai_error = str(exc).replace("\r", " ").replace("\n", " ").strip()
                coverage_md = (
                    "> ⚠️ **AI 语义复审失败**\n>\n"
                    "> 下方文本初筛只能作为候选，不能据此断言代码明显缺失。\n>\n"
                    f"> 失败原因：{coverage_ai_error}\n\n"
                    + analyze.document_code_consistency(
                        doc_md, code_text,
                        doc_name=local_doc_files[0].name,
                        code_name=unit["main"].name,
                    )
                )
                _log(f"  ⚠️ AI 语义复审失败，保留文本候选：{coverage_ai_error}")
    elif skip_ai:
        _log("[3/5] AI 覆盖分析：--no-ai 跳过")
        coverage_md = "> （本次运行使用 --no-ai 跳过了 AI 覆盖分析。）"
        coverage_ai_status = "skipped"
    else:
        _log("[3/5] AI 覆盖分析")
        try:
            coverage_md = analyze.coverage_analysis(card.func, doc_md, test_bundle, log=_log)
            coverage_ai_status = "completed"
            functional_performed = True
        except analyze.AnalyzeError as exc:
            coverage_ai_status = "failed"
            coverage_ai_error = str(exc).replace("\r", " ").replace("\n", " ").strip()
            coverage_md = (
                "> ⚠️ **AI 覆盖分析失败**\n>\n"
                "> 已固定使用当前 AI 配置，调用失败时最多尝试三次，未切换其他通道或模型。"
                "本节无法生成，但任务会继续输出其余材料与报告。\n>\n"
                f"> 失败原因：{coverage_ai_error}"
            )
            _log(f"  ⚠️ AI 覆盖分析失败，继续生成报告：{coverage_ai_error}")

    # ---- 步骤 4/5 性能判定 ------------------------------------------------
    _log("[4/5] 性能判定")
    perf_result = None
    performance_performed = False
    performance_ai_status = "not_used"
    performance_ai_error = None
    performance_ai_response_file = None
    if card.is_doc_code_consistency:
        performance_ai_status = "not_used"
        perf_md = (
            "### 性能分析\n\n"
            "> 文档代码一致性检查不进行性能分析。"
        )
        _log("  文档代码一致性检查模式不进行性能分析")
    elif card.is_local:
        pasted = perf_report_text.strip()
        if pasted:
            (materials / "性能报告-用户粘贴.txt").write_text(pasted, encoding="utf-8")
            if skip_ai:
                performance_ai_status = "skipped"
                perf_md = (
                    "### 用户粘贴的性能报告分析\n\n"
                    "> 本次运行使用 `--no-ai`，已保存用户粘贴的性能报告原文，"
                    "但未执行 AI 分析。"
                )
                _log("  已保存粘贴的性能报告；--no-ai 跳过分析")
            else:
                performance_performed = True
                try:
                    ai_perf_md = analyze.pasted_performance_analysis(
                        card.func, pasted, card.task_type, log=_log
                    )
                    ai_response_path = materials / "性能分析-AI原始返回.md"
                    ai_response_path.write_text(ai_perf_md, encoding="utf-8")
                    performance_ai_response_file = (
                        ai_response_path.relative_to(out_dir).as_posix()
                    )
                    verdict = analyze.performance_verdict_from_markdown(ai_perf_md)
                    perf_result = {
                        "mode": "pasted",
                        "verdict": verdict,
                    }
                    if verdict:
                        perf_md = ai_perf_md
                        performance_ai_status = "completed"
                        _log("  用户粘贴的性能报告分析完成")
                    else:
                        performance_ai_status = "unparsed"
                        performance_ai_error = (
                            "AI 已返回性能分析，但未包含可识别的四态结论"
                        )
                        perf_md = (
                            "### 用户粘贴的性能报告分析\n\n"
                            "> ⚠️ **AI 已返回分析，但结论格式无法识别**\n>\n"
                            "> 下方完整保留 AI 原始返回，便于调整性能提示词。"
                            "本次不据此生成性能通过/不通过结论。\n\n"
                            "#### AI 原始返回（未改写）\n\n"
                            f"{ai_perf_md}"
                        )
                        _log(
                            "  ⚠️ AI 已返回性能分析，但四态结论无法解析；"
                            "原始返回已写入报告和材料快照"
                        )
                except analyze.AnalyzeError as exc:
                    performance_ai_status = "failed"
                    performance_ai_error = str(exc).replace("\r", " ").replace("\n", " ").strip()
                    perf_result = {"mode": "ai_failed", "passed": None}
                    perf_md = (
                        "### 用户粘贴的性能报告分析\n\n"
                        "> ⚠️ **性能测试 AI 分析失败**\n>\n"
                        "> 已固定使用当前 AI 配置，调用失败时最多尝试三次，未切换其他通道或模型。"
                        "性能报告原文已保存在材料快照中，覆盖分析结果不受影响。\n>\n"
                        f"> 失败原因：{performance_ai_error}"
                    )
                    _log(f"  ⚠️ 性能测试 AI 分析失败，继续生成报告：{performance_ai_error}")
        else:
            performance_ai_status = "not_requested"
            perf_md = (
                "### 性能分析\n\n"
                "> 本次使用本地材料，用户未提供性能报告；按本地模式约定，"
                "本次不进行性能测试分析。"
            )
            _log("  本地模式未提供性能报告，跳过性能分析")
    elif code_info["perf_note"]:
        performance_performed = True
        note = code_info["perf_note"]
        mr.save_note_snapshot(note, materials / "性能报告-最新note.json")
        # 只有标题明确包含“性能优化”时，才使用摘要中的基准/分支变快变慢结论。
        # 其他优化别名沿用新增函数的分支详细表（MATLAB）判定。
        if card.uses_optimization_summary:
            perf_result = perf.judge_optimization_note(note)
            perf_md = perf.render_optimization_markdown(perf_result, note["heading"])
            if perf_result["passed"] is True:
                perf_log = "通过（全部用法未衰退）"
            elif perf_result["passed"] is False:
                perf_log = "不通过（发生衰退）"
            else:
                perf_log = "无法完整判定"
            _log(f"  整体结论: {perf_log}")
        else:
            perf_result = perf.judge_branch_table(mr.branch_table(note))
            perf_result["mode"] = "new_function"
            perf_md = perf.render_markdown(perf_result, note["heading"])
            _log(f"  整体结论: {'通过' if perf_result['passed'] else '不通过'}"
                 + ("（与 bot perf_status 有不一致，报告中已标注）" if perf_result["bot_mismatch"] else ""))
    else:
        perf_md = ("### 性能判定\n\n> ⚠️ 本次运行没有拿到性能报告"
                   "（降级模式跳过了 MR 页面，或该 MR 无 mtest2 报告 note），"
                   "无法进行性能判定，请人工确认。")
        _log("  未找到性能报告 note，报告中标注")

    # ---- 步骤 5/5 拼总报告 ------------------------------------------------
    _log("[5/5] 拼装总报告")
    try:
        unit_rel = unit["main"].relative_to(code_repo).as_posix()
    except ValueError:
        unit_rel = unit["main"].name
    bench_rel = bench.relative_to(code_repo).as_posix() if bench else None
    if card.is_local:
        task_source = f"{card.name}（本地材料：{unit['main']}）"
        if card.is_doc_code_consistency:
            task_type_text = "文档代码一致性检查"
            rule_text = (
                "本地文本候选初筛＋AI 语义等价复审"
                if not skip_ai else "本地文本候选初筛（未执行 AI 复审）"
            )
        else:
            task_type_text = "本地材料分析"
            rule_text = "提示词 v2（本地文档/代码覆盖分析）"
            if performance_performed:
                rule_text += "＋用户粘贴性能报告分析"
    else:
        task_source = (
            f"{card.name}（{card.code_repo_name} {card.code_mr.rsplit('/', 1)[-1]}，"
            f"分支 {code_info['source_branch']}）"
        )
        task_type_text = "性能优化" if card.is_performance_optimization else "新增函数"
        rule_text = (
            "提示词 v2（D20）＋性能标准 "
            f"{'D13/D15/D16/D23~D28' if card.uses_optimization_summary else 'D13/D15/D16'}"
        )
    try:
        report_model = None if skip_ai else analyze.current_model()
    except analyze.AnalyzeError:
        report_model = "配置不可用"
    report_title = (
        f"# {card.name} 文档代码一致性报告"
        if card.is_doc_code_consistency else f"# {card.func} 提测分析报告"
    )
    header = "\n".join([
        report_title,
        "",
        f"> 任务：{task_source}",
        f"> 任务类型：{task_type_text}",
        f"> 文档：{doc_source}",
        f"> {'代码文件' if card.is_doc_code_consistency else '单测'}：`{unit_rel}`"
        + (f"（伴随数据 {len(unit['companions'])} 个）" if unit["companions"] else ""),
        f"> benchmark：`{bench_rel}`" if bench_rel else (
            "> benchmark：不适用" if card.is_doc_code_consistency else "> benchmark：未定位到"
        ),
        f"> HTML 预览：`{doc_html_info['html']}`"
        if doc_html_info else
        (f"> HTML 预览：编译失败（{doc_html_error}）" if doc_html_error else "> HTML 预览：未执行"),
        f"> 分析规则：{rule_text} ｜ "
        f"生成：{datetime.now():%Y-%m-%d %H:%M} ｜ 模型：{report_model or '—'}",
    ])
    summary_email = _summary_email(
        card, perf_result, performance_performed, functional_performed,
        [unit["main"], *unit["companions"]] if card.is_local else None,
        local_doc_files if card.is_local else None,
    )
    leadership_summary = _leadership_summary(
        card, perf_result, performance_performed, functional_performed
    )
    if card.is_doc_code_consistency:
        analysis_heading = "## 一、文档与代码一致性检查"
    else:
        analysis_heading = "## 一、单元测试覆盖分析（AI）"
    if card.is_local and performance_ai_status in ("completed", "unparsed"):
        performance_heading = "## 二、性能测试判定（AI，仅当前函数）"
    elif card.is_local:
        performance_heading = "## 二、性能测试判定"
    else:
        performance_heading = "## 二、性能测试判定（脚本演算）"
    if card.is_doc_code_consistency:
        report_parts = [header, analysis_heading, coverage_md]
    else:
        report_parts = [
            header,
            analysis_heading,
            coverage_md,
            performance_heading,
            perf_md,
            "## 三、总结邮件格式（可直接复制）",
            f"```text\n{summary_email}\n```",
            "## 四、上级汇报格式（可直接复制）",
            f"```text\n{leadership_summary}\n```",
        ]
    report = "\n\n".join(report_parts) + "\n"
    report_path = out_dir / "分析报告.md"
    report_path.write_text(report, encoding="utf-8")

    (out_dir / "task.json").write_text(json.dumps({
        "name": card.name, "func": card.func,
        "file_name": card.name if card.is_doc_code_consistency else None,
        "task_type": card.task_type,
        "input_mode": card.input_mode,
        "code_mr": card.code_mr or None, "doc_mr": card.doc_mr or None,
        "local_code": str(unit["main"]) if card.is_local else None,
        "local_doc": str(local_doc_files[0]) if card.is_local else None,
        "local_code_input": card.local_code if card.is_local else None,
        "local_doc_input": card.local_doc if card.is_local else None,
        "local_library": card.local_library if card.is_local else None,
        "local_branch": card.local_branch if card.is_local else None,
        "compare_doc_code": card.is_doc_code_consistency,
        "consistency_status": consistency_status,
        "consistency_ai_response_file": consistency_ai_response_file,
        "local_code_files": [str(path) for path in [unit["main"], *unit["companions"]]]
        if card.is_local else [],
        "local_doc_files": [str(path) for path in local_doc_files] if card.is_local else [],
        "code_branch": code_info["source_branch"], "doc_branch": doc_info["source_branch"],
        "doc_md": doc_rel,
        "unit_test": unit_rel,
        "benchmark": bench_rel,
        "doc_html_project": doc_html_info["project"] if doc_html_info else None,
        "doc_html": doc_html_info["html"] if doc_html_info else None,
        "doc_html_url": doc_html_info["url"] if doc_html_info else None,
        "doc_html_requested": bool(build_doc_html),
        "doc_html_browser_opened": doc_html_info["browser_opened"] if doc_html_info else False,
        "doc_html_error": doc_html_error,
        "perf_note_heading": code_info["perf_note"]["heading"] if code_info["perf_note"] else None,
        "pasted_performance_report": card.is_local and bool(perf_report_text.strip()),
        "coverage_ai_status": coverage_ai_status,
        "coverage_ai_error": coverage_ai_error,
        "performance_ai_status": performance_ai_status,
        "performance_ai_error": performance_ai_error,
        "performance_ai_response_file": performance_ai_response_file,
        "performance_verdict": _performance_email_text(
            perf_result, performance_performed
        ),
        "model": report_model,
        "generated_at": datetime.now().isoformat(timespec="seconds"),
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    (out_dir / config.LOCAL_PATHS_STATE_NAME).unlink(missing_ok=True)

    _log(f"完成 ✅ 报告: {report_path}")
    return report_path


def main() -> None:
    if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
        sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser(
        description="woodpecker 提测分析（在线 MR / 本地材料）"
    )
    ap.add_argument(
        "--name", required=True,
        help='任务名，如 "新增 polydiv 函数" 或 "ode89 函数性能优化"',
    )
    ap.add_argument("--code-mr", default="", help="代码 MR 链接（在线模式必填）")
    ap.add_argument("--doc-mr", default="", help="文档 MR 链接（仅新增函数任务必填）")
    ap.add_argument("--local-code", default="",
                    help="代码/单测文件或母目录；填写后启用本地材料模式")
    ap.add_argument("--local-doc", default="",
                    help="兼容参数：文档文件或母目录")
    ap.add_argument("--local-library", default="",
                    help="本地材料的函数库名，如 TyImageProcessing")
    ap.add_argument("--local-branch", default="",
                    help="文档仓库和代码仓库共同使用的源分支")
    ap.add_argument("--perf-report-file", default="",
                    help="可选：用户复制保存的性能报告文本文件")
    ap.add_argument("--func", default="", help="函数名（缺省从任务名解析）")
    ap.add_argument(
        "--compare-doc-code", action="store_true",
        help="本地模式：按文件名比较 Markdown 代码块与代码文件",
    )
    ap.add_argument("--no-ai", action="store_true", help="跳过 AI 分析（仅保留非结论性的文本初筛）")
    ap.add_argument(
        "--build-doc-html", action="store_true",
        help="编译新增函数的帮助文档并在浏览器中打开",
    )
    ap.add_argument(
        "--refresh-doc-only", action="store_true",
        help="强制拉取文档分支并编译 HTML；不读取代码、不执行 AI 分析",
    )
    ap.add_argument("--doc-branch", default="",
                    help="人工指定文档源分支（降级模式：MR 页面读不了时用，03-A 预案）")
    ap.add_argument("--code-branch", default="",
                    help="人工指定代码源分支（降级模式，此时无性能报告）")
    args = ap.parse_args()
    try:
        input_mode = "local" if (
            args.local_library or args.local_branch or args.local_code or args.local_doc
        ) else "remote"
        card = TaskCard(
            name=args.name, code_mr=args.code_mr, doc_mr=args.doc_mr, func=args.func,
            input_mode=input_mode, local_code=args.local_code, local_doc=args.local_doc,
            local_library=args.local_library, local_branch=args.local_branch,
            compare_doc_code=args.compare_doc_code,
        )
        if args.refresh_doc_only:
            refresh_and_build_document(card)
        else:
            perf_report_text = ""
            if args.perf_report_file:
                perf_path = locate.local_file(args.perf_report_file, "性能报告文件")
                perf_report_text = perf_path.read_text(
                    encoding="utf-8", errors="replace"
                )
            run(
                card, skip_ai=args.no_ai, build_doc_html=args.build_doc_html,
                doc_branch=args.doc_branch,
                code_branch=args.code_branch, perf_report_text=perf_report_text,
            )
    except (
        repo.GitError, mr.MrError, locate.LocateError, perf.PerfError,
        analyze.AnalyzeError, doc_html.DocHtmlError, ValueError,
    ) as e:
        # 已知失败场景给人话提示（docs/07 §3），意外异常仍抛 traceback 便于排查
        print(f"❌ {e}", flush=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
