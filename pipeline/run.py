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
  python -m pipeline.run --name "分析 polydiv" --func polydiv \
      --local-code C:\\path\\to\\polydiv.jl --local-doc C:\\path\\to\\polydiv.md \
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

from . import analyze, config, locate, mr, perf, repo
from .taskcard import TaskCard


def _log(msg: str) -> None:
    print(msg, flush=True)


def _performance_email_text(result: dict | None, performed: bool = True) -> str:
    """性能明细转换成总结邮件中的简短结论。"""
    if not performed:
        return "本次未进行性能分析"
    if not result:
        return "性能验证待确认"
    if result.get("mode") == "pasted":
        return "已分析用户粘贴的性能报告信息"
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
    functional_performed: bool = True,
) -> str:
    """生成可直接复制的周提测总结邮件文本；版本号由测试人员手填。"""
    library = card.code_repo_name.removesuffix(".jl")
    functional_text = "功能验证通过" if functional_performed else "功能验证未进行"
    lines = [
        f"{card.name}，{functional_text}，"
        f"{_performance_email_text(perf_result, performance_performed)}，请补充自动化脚本",
    ]
    if card.is_local:
        lines += [
            "分析材料来自用户电脑本地文件：",
            "",
            "代码/单测：",
            card.local_code,
            "",
            "帮助文档：",
            card.local_doc,
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


def run(card: TaskCard, skip_ai: bool = False,
        doc_branch: str = "", code_branch: str = "",
        perf_report_text: str = "", log=_log) -> Path:
    _log = log  # 允许 Web 壳注入日志收集器；缺省打印到控制台
    out_dir = card.make_output_dir()
    materials = out_dir / "materials"
    materials.mkdir(exist_ok=True)
    _log(f"任务: {card.name}（函数 {card.func}）")
    _log(f"产出目录: {out_dir}")

    # ---- 步骤 1/5 文档侧 --------------------------------------------------
    if card.is_local:
        _log("[1/5] 读取用户指定的本地文档")
        doc_md_path = locate.local_file(card.local_doc, "本地文档")
        doc_md = doc_md_path.read_text(encoding="utf-8", errors="replace")
        doc_rel = doc_md_path.name
        shutil.copy2(doc_md_path, materials / doc_md_path.name)
        doc_info = {"source_branch": "本地文件", "perf_note": None}
        doc_source = f"用户本地文件 `{doc_md_path}`"
    elif card.is_new_function:
        _log("[1/5] 文档 MR 取数")
        if doc_branch:
            _log(f"  使用人工指定分支（降级模式，跳过 MR 页面）: {doc_branch}")
            doc_info = {"source_branch": doc_branch, "perf_note": None}
        else:
            doc_info = mr.read_mr(card.doc_mr, log=_log)
        docs_repo = repo.ensure_repo(card.doc_project, log=_log)
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
        docs_repo = repo.ensure_repo(config.DOCS_REPO_PROJECT, log=_log)
        repo.refresh_repo(docs_repo, log=_log)
        doc_material = locate.read_existing_doc_md(
            docs_repo, card.func, config.DOCS_DEFAULT_BASE, log=_log
        )
        doc_info = {"source_branch": doc_material["revision"], "perf_note": None}
        doc_rel = doc_material["relative_path"]
        doc_md = doc_material["text"]
        (materials / f"{card.func}.md").write_text(doc_md, encoding="utf-8")
        doc_source = f"本地 {config.DOCS_REPO_NAME}（{doc_material['revision']}）`{doc_rel}`"

    # ---- 步骤 2/5 代码侧：MR → 分支 → 单测 + 性能报告 --------------------
    if card.is_local:
        _log("[2/5] 读取用户指定的本地代码/单测")
        unit = locate.find_local_unit_test(card.local_code, card.func, log=_log)
        code_repo = unit["root"]
        code_info = {"source_branch": "本地文件", "perf_note": None}
        bench = None
    else:
        _log("[2/5] 代码 MR 取数")
        if code_branch:
            _log(f"  使用人工指定分支（降级模式，跳过 MR 页面，无性能报告）: {code_branch}")
            code_info = {"source_branch": code_branch, "perf_note": None}
        else:
            code_info = mr.read_mr(card.code_mr, log=_log)
        code_repo = repo.ensure_repo(card.code_project, log=_log)
        repo.prepare_branch(code_repo, code_info["source_branch"], log=_log)
        unit = locate.find_unit_test(code_repo, card.func, log=_log)
        bench = locate.find_benchmark_dir(code_repo, card.func, log=_log)
    test_bundle = locate.read_test_bundle(unit)
    for p in [unit["main"], *unit["companions"]]:
        shutil.copy2(p, materials / p.name)

    # ---- 步骤 3/5 AI 覆盖分析 --------------------------------------------
    if skip_ai:
        _log("[3/5] AI 覆盖分析：--no-ai 跳过")
        coverage_md = "> （本次运行使用 --no-ai 跳过了 AI 覆盖分析。）"
    else:
        _log("[3/5] AI 覆盖分析")
        coverage_md = analyze.coverage_analysis(card.func, doc_md, test_bundle, log=_log)

    # ---- 步骤 4/5 性能判定 ------------------------------------------------
    _log("[4/5] 性能判定")
    perf_result = None
    performance_performed = False
    if card.is_local:
        pasted = perf_report_text.strip()
        if pasted:
            (materials / "性能报告-用户粘贴.txt").write_text(pasted, encoding="utf-8")
            if skip_ai:
                perf_md = (
                    "### 用户粘贴的性能报告分析\n\n"
                    "> 本次运行使用 `--no-ai`，已保存用户粘贴的性能报告原文，"
                    "但未执行 AI 分析。"
                )
                _log("  已保存粘贴的性能报告；--no-ai 跳过分析")
            else:
                performance_performed = True
                perf_md = analyze.pasted_performance_analysis(
                    card.func, pasted, card.task_type, log=_log
                )
                _log("  用户粘贴的性能报告分析完成")
                perf_result = {"mode": "pasted", "passed": None}
        else:
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
        if card.is_performance_optimization:
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
        task_type_text = "本地材料分析"
        rule_text = "提示词 v1（本地文档/代码覆盖分析）"
        if performance_performed:
            rule_text += "＋用户粘贴性能报告分析"
    else:
        task_source = (
            f"{card.name}（{card.code_repo_name} {card.code_mr.rsplit('/', 1)[-1]}，"
            f"分支 {code_info['source_branch']}）"
        )
        task_type_text = "性能优化" if card.is_performance_optimization else "新增函数"
        rule_text = (
            "提示词 v1（D20）＋性能标准 "
            f"{'D13/D15/D16/D23~D28' if card.is_performance_optimization else 'D13/D15/D16'}"
        )
    header = "\n".join([
        f"# {card.func} 提测分析报告",
        "",
        f"> 任务：{task_source}",
        f"> 任务类型：{task_type_text}",
        f"> 文档：{doc_source}",
        f"> 单测：`{unit_rel}`"
        + (f"（伴随数据 {len(unit['companions'])} 个）" if unit["companions"] else ""),
        f"> benchmark：`{bench_rel}`" if bench_rel else "> benchmark：未定位到",
        f"> 分析规则：{rule_text} ｜ "
        f"生成：{datetime.now():%Y-%m-%d %H:%M} ｜ 模型：{'—' if skip_ai else analyze.current_model()}",
    ])
    report = "\n\n".join([
        header,
        "## 一、单元测试覆盖分析（AI）",
        coverage_md,
        "## 二、性能测试判定（脚本演算）",
        perf_md,
        "## 三、总结邮件格式（可直接复制）",
        f"```text\n{_summary_email(card, perf_result, performance_performed, not skip_ai)}\n```",
    ]) + "\n"
    report_path = out_dir / "分析报告.md"
    report_path.write_text(report, encoding="utf-8")

    (out_dir / "task.json").write_text(json.dumps({
        "name": card.name, "func": card.func,
        "task_type": card.task_type,
        "input_mode": card.input_mode,
        "code_mr": card.code_mr or None, "doc_mr": card.doc_mr or None,
        "local_code": card.local_code or None, "local_doc": card.local_doc or None,
        "code_branch": code_info["source_branch"], "doc_branch": doc_info["source_branch"],
        "doc_md": doc_rel,
        "unit_test": unit_rel,
        "benchmark": bench_rel,
        "perf_note_heading": code_info["perf_note"]["heading"] if code_info["perf_note"] else None,
        "pasted_performance_report": card.is_local and bool(perf_report_text.strip()),
        "model": None if skip_ai else analyze.current_model(),
        "generated_at": datetime.now().isoformat(timespec="seconds"),
    }, ensure_ascii=False, indent=2), encoding="utf-8")

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
                    help="本地代码/单测文件或目录；填写后启用本地材料模式")
    ap.add_argument("--local-doc", default="", help="本地文档文件（本地材料模式必填）")
    ap.add_argument("--perf-report-file", default="",
                    help="可选：用户复制保存的性能报告文本文件")
    ap.add_argument("--func", default="", help="函数名（缺省从任务名解析）")
    ap.add_argument("--no-ai", action="store_true", help="跳过 AI 覆盖分析（调试取数/性能用）")
    ap.add_argument("--doc-branch", default="",
                    help="人工指定文档源分支（降级模式：MR 页面读不了时用，03-A 预案）")
    ap.add_argument("--code-branch", default="",
                    help="人工指定代码源分支（降级模式，此时无性能报告）")
    args = ap.parse_args()
    try:
        input_mode = "local" if args.local_code or args.local_doc else "remote"
        card = TaskCard(
            name=args.name, code_mr=args.code_mr, doc_mr=args.doc_mr, func=args.func,
            input_mode=input_mode, local_code=args.local_code, local_doc=args.local_doc,
        )
        perf_report_text = ""
        if args.perf_report_file:
            perf_path = locate.local_file(args.perf_report_file, "性能报告文件")
            perf_report_text = perf_path.read_text(encoding="utf-8", errors="replace")
        run(
            card, skip_ai=args.no_ai, doc_branch=args.doc_branch,
            code_branch=args.code_branch, perf_report_text=perf_report_text,
        )
    except (
        repo.GitError, mr.MrError, locate.LocateError, perf.PerfError,
        analyze.AnalyzeError, ValueError,
    ) as e:
        # 已知失败场景给人话提示（docs/07 §3），意外异常仍抛 traceback 便于排查
        print(f"❌ {e}", flush=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
