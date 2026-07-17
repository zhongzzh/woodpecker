"""性能判定（docs/02 D13/D15/D16/D23~D28；样例结构见 docs/05、08）。

输入：mr.py 抓取的最新性能报告中「分支版本详细数据」表（headers + rows）。
规则（新增函数，参照系 = MATLAB）：
  对每个用法检查两项，均须达标（D15，首次无 JIT 豁免）：
    首次: T = m_execute_time_first,   x = execute_time_first_diff
    二次: T = m_execute_time_average, x = execute_time_average_diff
  阈值按 T 分档（D13）：T>1s → 1.2；0.1s≤T≤1s → 1.25；T<0.1s → 1.5
  x 恰好等于阈值算通过（x > 阈值才不通过）。
  任一用法任一项超标 → 整体不通过（D16）。机器人 perf_status 仅作旁证。
"""

from __future__ import annotations

from dataclasses import dataclass
import re

from . import config


class PerfError(RuntimeError):
    pass


def threshold_for(t: float) -> float:
    """按参考时间 T 分档取阈值（D13）。"""
    # 明确写出开闭边界，避免配置区间把 T == 1 错归入 “T > 1” 档。
    long_threshold, medium_threshold, short_threshold = (
        item[2] for item in config.PERF_THRESHOLDS
    )
    if t > 1.0:
        return long_threshold
    if t >= 0.1:
        return medium_threshold
    return short_threshold


@dataclass
class Check:
    label: str          # 首次 / 二次
    t: float            # 参考时间（MATLAB 耗时，秒）
    x: float            # 耗时比值 j/m
    threshold: float
    passed: bool


@dataclass
class UsageVerdict:
    usage: str
    name: str           # 用法中文描述
    checks: list[Check]
    bot_perf_status: str
    passed: bool

    @property
    def bot_mismatch(self) -> bool:
        bot_pass = self.bot_perf_status.strip().lower() == "pass"
        return bot_pass != self.passed


def _col(headers: list[str], name: str) -> int:
    try:
        return headers.index(name)
    except ValueError:
        raise PerfError(f"性能报告表缺少列 {name!r}；实际列: {headers}")


def judge_branch_table(table: dict) -> dict:
    """对分支版本详细数据表逐用法判定。table = {headers: [...], rows: [[...], ...]}"""
    h = table["headers"]
    i_usage = _col(h, "usage_name")
    i_name = _col(h, "name")
    i_mf, i_xf = _col(h, "m_execute_time_first"), _col(h, "execute_time_first_diff")
    i_ma, i_xa = _col(h, "m_execute_time_average"), _col(h, "execute_time_average_diff")
    i_bot = _col(h, "perf_status")

    verdicts: list[UsageVerdict] = []
    for row in table["rows"]:
        checks = []
        for label, i_t, i_x in (("首次", i_mf, i_xf), ("二次", i_ma, i_xa)):
            t, x = float(row[i_t]), float(row[i_x])
            thr = threshold_for(t)
            checks.append(Check(label, t, x, thr, passed=not (x > thr)))
        verdicts.append(
            UsageVerdict(
                usage=row[i_usage],
                name=row[i_name],
                checks=checks,
                bot_perf_status=row[i_bot],
                passed=all(c.passed for c in checks),
            )
        )

    return {
        "verdicts": verdicts,
        "passed": all(v.passed for v in verdicts),
        "bot_mismatch": any(v.bot_mismatch for v in verdicts),
    }


def render_markdown(result: dict, report_heading: str) -> str:
    """判定结果 → 报告 md 片段（逐用法明细，D16）。"""
    lines = [
        "### 性能判定（标准 D13/D15/D16，参照系 MATLAB）",
        "",
        f"依据报告：{report_heading}（同 MR 最新一条）",
        "",
        "| 用法 | 检查项 | T=MATLAB耗时(s) | 档位阈值 | x(j/m) | 结论 |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for v in result["verdicts"]:
        for c in v.checks:
            verdict = "通过" if c.passed else "**不通过**"
            lines.append(
                f"| {v.usage} | {c.label} | {c.t:g} | {c.threshold} | {c.x:.4g} | {verdict} |"
            )
    overall = "✅ 通过" if result["passed"] else "❌ 不通过"
    lines += ["", f"**整体结论：{overall}**（任一用法任一项超标即不通过）"]

    mismatches = [v for v in result["verdicts"] if v.bot_mismatch]
    if mismatches:
        lines += [
            "",
            "> ⚠️ 与机器人 perf_status 不一致（以 D13 标准为准，perf_status 仅旁证）："
            + "；".join(
                f"{v.usage}: 本判定={'通过' if v.passed else '不通过'}, bot={v.bot_perf_status}"
                for v in mismatches
            ),
        ]
    return "\n".join(lines)


# ---- 性能优化：分支 Julia / 基准 Julia（D23~D28） ----------------------

@dataclass
class OptimizationCheck:
    label: str
    t: float | None
    branch_time: float | None
    x: float | None
    raw_x: float | None
    threshold: float | None
    passed: bool | None
    change_text: str
    source: str
    warning: str = ""


@dataclass
class OptimizationUsageVerdict:
    usage: str
    name: str
    checks: list[OptimizationCheck]
    passed: bool | None


def _table(perf_note: dict, keyword: str) -> dict:
    for table in perf_note.get("tables", []):
        if keyword in table.get("title", ""):
            return table
    raise PerfError(
        f"性能报告里没找到“{keyword}”表，实际表："
        f"{[t.get('title', '') for t in perf_note.get('tables', [])]}"
    )


def _rows_by_usage(table: dict) -> tuple[dict[str, list[str]], dict[str, int]]:
    headers = table["headers"]
    indices = {name: _col(headers, name) for name in (
        "usage_name", "name", "j_execute_time_first", "j_execute_time_average"
    )}
    rows: dict[str, list[str]] = {}
    for row in table["rows"]:
        usage = row[indices["usage_name"]]
        if usage in rows:
            raise PerfError(f"性能报告详细表中 usage_name 重复: {usage}")
        rows[usage] = row
    return rows, indices


def _summary_source(perf_note: dict) -> str:
    blocks = perf_note.get("summary") or perf_note.get("summary_blocks") or []
    if isinstance(blocks, str):
        blocks = [blocks]
    pieces = [str(x) for x in blocks if str(x).strip()]
    summary_text = str(perf_note.get("summary_text", "")).strip()
    if summary_text:
        pieces.append(summary_text)
    intro = str(perf_note.get("intro", "")).strip()
    if intro:
        pieces.append(intro)
    return "\n".join(pieces)


def parse_optimization_summary(perf_note: dict) -> dict[tuple[str, str], dict]:
    """解析“用法 + 首次/二次 + 变快/变慢百分比”摘要。"""
    text = _summary_source(perf_note)
    changes: dict[tuple[str, str], dict] = {}
    usage_pattern = re.compile(
        r"用法\s*[：:]\s*(\S+)(.*?)(?=\n\s*用法\s*[：:]|\Z)", re.S
    )
    metric_pattern = re.compile(
        r"(首次|二次)执行时间\s*[：:]\s*"
        r"相比于基准版本，?分支版本性能(变快|变慢)了\s*"
        r"([0-9]+(?:\.[0-9]+)?)\s*%"
    )
    for usage_match in usage_pattern.finditer(text):
        usage, body = usage_match.group(1).strip(), usage_match.group(2)
        for metric in metric_pattern.finditer(body):
            label, direction, percent_text = metric.groups()
            percent = float(percent_text)
            x = 1.0 - percent / 100.0 if direction == "变快" else 1.0 + percent / 100.0
            changes[(usage, label)] = {
                "direction": direction,
                "percent": percent,
                "x": x,
                "text": f"{direction} {percent:g}%",
            }
    return changes


def _float_or_none(value) -> float | None:
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None
    if number != number or number in (float("inf"), float("-inf")):
        return None
    return number


def _aggregate(checks: list[OptimizationCheck]) -> bool | None:
    if any(c.passed is False for c in checks):
        return False
    if any(c.passed is None for c in checks):
        return None
    return True


def judge_optimization_note(perf_note: dict) -> dict:
    """按分支/基准 Julia 耗时判断性能优化是否发生衰退。"""
    baseline = _table(perf_note, "基准版本")
    branch = _table(perf_note, "分支版本")
    base_rows, base_i = _rows_by_usage(baseline)
    branch_rows, branch_i = _rows_by_usage(branch)
    changes = parse_optimization_summary(perf_note)

    warnings: list[str] = []
    base_set, branch_set = set(base_rows), set(branch_rows)
    if base_set != branch_set:
        warnings.append(
            "基准/分支详细表的用法集合不一致："
            f"仅基准={sorted(base_set - branch_set) or '无'}；"
            f"仅分支={sorted(branch_set - base_set) or '无'}"
        )

    source_text = _summary_source(perf_note)
    count_match = re.search(r"共执行了\s*(\d+)\s*个用法", source_text)
    declared_count = int(count_match.group(1)) if count_match else None
    all_usages = list(base_rows) + sorted(branch_set - base_set)
    if declared_count is not None and declared_count != len(set(all_usages)):
        warnings.append(
            f"报告声明 {declared_count} 个用法，但详细表合计识别到 {len(set(all_usages))} 个"
        )

    verdicts: list[OptimizationUsageVerdict] = []
    for usage in all_usages:
        base_row, branch_row = base_rows.get(usage), branch_rows.get(usage)
        name = ""
        if branch_row is not None:
            name = branch_row[branch_i["name"]]
        elif base_row is not None:
            name = base_row[base_i["name"]]

        checks: list[OptimizationCheck] = []
        for label, field in (("首次", "j_execute_time_first"), ("二次", "j_execute_time_average")):
            t = _float_or_none(base_row[base_i[field]]) if base_row is not None else None
            branch_time = (
                _float_or_none(branch_row[branch_i[field]]) if branch_row is not None else None
            )
            raw_x = branch_time / t if t is not None and t > 0 and branch_time is not None else None
            change = changes.get((usage, label))
            summary_x = change["x"] if change else None
            change_text = change["text"] if change else "摘要缺项"
            source = "摘要换算" if change else "详细表补算"
            warning = ""

            if t is None or t <= 0:
                x, threshold, passed = None, None, None
                warning = "基准时间缺失、非数值或不大于 0"
                source = "无法判定"
            elif raw_x is None:
                x, threshold, passed = None, threshold_for(t), None
                warning = "分支时间缺失或非数值"
                source = "无法判定"
            else:
                threshold = threshold_for(t)
                x = summary_x if summary_x is not None else raw_x
                # 摘要通常只保留一位小数。若舍入值和原始时间比值恰好落在阈值两侧，
                # 使用详细表原始时间，避免临界点误判。
                if summary_x is not None:
                    summary_pass = not (summary_x > threshold)
                    raw_pass = not (raw_x > threshold)
                    if summary_pass != raw_pass:
                        x = raw_x
                        source = "详细表原始时间（摘要舍入临界校正）"
                    if abs(summary_x - raw_x) > 0.002:
                        warning = f"摘要换算 x={summary_x:.6g}，原始时间比值 x={raw_x:.6g}"
                passed = not (x > threshold)

            checks.append(OptimizationCheck(
                label=label, t=t, branch_time=branch_time, x=x, raw_x=raw_x,
                threshold=threshold, passed=passed, change_text=change_text,
                source=source, warning=warning,
            ))

        verdicts.append(OptimizationUsageVerdict(
            usage=usage, name=name, checks=checks, passed=_aggregate(checks)
        ))

    overall = _aggregate([c for v in verdicts for c in v.checks])
    return {
        "mode": "performance_optimization",
        "verdicts": verdicts,
        "passed": overall,
        "warnings": warnings,
        "summary_items": len(changes),
        "declared_count": declared_count,
    }


def render_optimization_markdown(result: dict, report_heading: str) -> str:
    lines = [
        "### 性能优化衰退判定（标准 D13/D15/D16/D23~D28，参照系：分支/基准 Julia）",
        "",
        f"依据报告：{report_heading}（同 MR 报告时间最新的一条）",
        "",
        "| 用法 | 检查项 | 基准 T(s) | 分支耗时(s) | 报告变化 | x(分支/基准) | 阈值 | 数据来源 | 结论 |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for verdict in result["verdicts"]:
        for check in verdict.checks:
            t = "—" if check.t is None else f"{check.t:g}"
            branch_time = "—" if check.branch_time is None else f"{check.branch_time:g}"
            x = "—" if check.x is None else f"{check.x:.6g}"
            threshold = "—" if check.threshold is None else f"{check.threshold:g}"
            if check.passed is True:
                conclusion = "未衰退"
            elif check.passed is False:
                conclusion = "**发生衰退**"
            else:
                conclusion = "**无法判定**"
            lines.append(
                f"| {verdict.usage} | {check.label} | {t} | {branch_time} | "
                f"{check.change_text} | {x} | {threshold} | {check.source} | {conclusion} |"
            )
            if check.warning:
                lines.append(
                    f"|  |  |  |  |  |  |  | ⚠️ {check.warning} |  |"
                )

    lines += ["", "**逐用法结论：**", ""]
    for verdict in result["verdicts"]:
        if verdict.passed is True:
            label = "【未衰退（性能提升/持平）】"
        elif verdict.passed is False:
            label = "【发生衰退】"
        else:
            label = "【无法判定】"
        desc = f"（{verdict.name}）" if verdict.name else ""
        lines.append(f"- `{verdict.usage}`{desc}：{label}")

    if result["passed"] is True:
        overall = "✅ 通过：全部用法未衰退"
    elif result["passed"] is False:
        overall = "❌ 不通过：至少一个用法发生衰退"
    else:
        overall = "⚠️ 无法完整判定：存在缺失或异常数据"
    lines += ["", f"**整体结论：{overall}**"]

    if result.get("warnings"):
        lines += ["", "> ⚠️ 报告结构告警：" + "；".join(result["warnings"])]
    if any(c.change_text == "摘要缺项" for v in result["verdicts"] for c in v.checks):
        lines += [
            "",
            "> 摘要未列出的检查项已使用同一份最新报告的基准/分支 Julia 原始时间补算，"
            "没有把“摘要缺项”当作持平或通过。",
        ]
    return "\n".join(lines)
