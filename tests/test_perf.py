import copy
import json
import unittest
from pathlib import Path

from pipeline import perf


ROOT = Path(__file__).resolve().parents[1]


def make_note(rows, summaries):
    headers = ["usage_name", "name", "j_execute_time_first", "j_execute_time_average"]
    baseline_rows = []
    branch_rows = []
    for usage, name, base_first, base_average, branch_first, branch_average in rows:
        baseline_rows.append([usage, name, str(base_first), str(base_average)])
        branch_rows.append([usage, name, str(branch_first), str(branch_average)])
    return {
        "heading": "julia分支性能对比测试报告 2026-07-17 12:00:00",
        "intro": f"本次对比测试共执行了 {len(rows)}个用法：",
        "summary": summaries,
        "tables": [
            {"title": "基准版本详细数据", "headers": headers, "rows": baseline_rows},
            {"title": "分支版本详细数据", "headers": headers, "rows": branch_rows},
        ],
    }


class OptimizationPerfTests(unittest.TestCase):
    def test_existing_new_function_julia_matlab_strategy_still_works(self):
        path = ROOT / "docs" / "samples" / "MR472-性能报告-note385041.json"
        note = json.loads(path.read_text(encoding="utf-8"))
        branch = next(t for t in note["tables"] if "分支版本" in t["title"])
        result = perf.judge_branch_table(branch)
        self.assertFalse(result["passed"])
        self.assertFalse(result["verdicts"][0].checks[0].passed)
        self.assertTrue(result["verdicts"][0].checks[1].passed)

    def test_new_function_markdown_groups_first_and_repeated_runs(self):
        result = {
            "verdicts": [
                perf.UsageVerdict(
                    usage="PT1", name="one",
                    checks=[
                        perf.Check("首次", 2.0, 1.0, 1.2, True),
                        perf.Check("二次", 2.0, 1.0, 1.2, True),
                    ],
                    bot_perf_status="pass", passed=True,
                ),
                perf.UsageVerdict(
                    usage="PT2", name="two",
                    checks=[
                        perf.Check("首次", 2.0, 1.0, 1.2, True),
                        perf.Check("二次", 2.0, 1.0, 1.2, True),
                    ],
                    bot_perf_status="pass", passed=True,
                ),
            ],
            "passed": True,
            "bot_mismatch": False,
        }

        markdown = perf.render_markdown(result, "report")

        positions = [
            markdown.index("| PT1 | 首次"),
            markdown.index("| PT2 | 首次"),
            markdown.index("| PT1 | 二次"),
            markdown.index("| PT2 | 二次"),
        ]
        self.assertEqual(positions, sorted(positions))

    def test_threshold_boundaries_follow_syslab_standard(self):
        self.assertEqual(perf.threshold_for(1.000001), 1.2)
        self.assertEqual(perf.threshold_for(1.0), 1.25)
        self.assertEqual(perf.threshold_for(0.1), 1.25)
        self.assertEqual(perf.threshold_for(0.099999), 1.5)

    def test_real_mr472_sample_is_all_non_regression(self):
        path = ROOT / "docs" / "samples" / "MR472-性能报告-note385041.json"
        note = json.loads(path.read_text(encoding="utf-8"))
        result = perf.judge_optimization_note(note)
        self.assertTrue(result["passed"])
        self.assertEqual(len(result["verdicts"]), 4)
        self.assertTrue(all(v.passed for v in result["verdicts"]))
        pt1_second = result["verdicts"][0].checks[1]
        self.assertAlmostEqual(pt1_second.x, 0.016)
        self.assertEqual(pt1_second.source, "摘要换算")

    def test_optimization_markdown_groups_first_and_repeated_runs(self):
        note = make_note(
            [
                ("PT1", "one", 2.0, 2.0, 1.0, 1.0),
                ("PT2", "two", 2.0, 2.0, 1.0, 1.0),
            ],
            [],
        )
        result = perf.judge_optimization_note(note)

        markdown = perf.render_optimization_markdown(result, note["heading"])

        positions = [
            markdown.index("| PT1 | 首次"),
            markdown.index("| PT2 | 首次"),
            markdown.index("| PT1 | 二次"),
            markdown.index("| PT2 | 二次"),
        ]
        self.assertEqual(positions, sorted(positions))

    def test_three_threshold_bands_and_equal_boundary(self):
        note = make_note(
            [
                ("PT1", "T > 1", 2.0, 2.0, 2.4, 2.4),
                ("PT2", "0.1 <= T <= 1", 0.5, 0.5, 0.63, 0.63),
                ("PT3", "T < 0.1", 0.05, 0.05, 0.075, 0.075),
            ],
            [
                "用法：PT1\n首次执行时间：相比于基准版本，分支版本性能变慢了20%\n二次执行时间：相比于基准版本，分支版本性能变慢了20%",
                "用法：PT2\n首次执行时间：相比于基准版本，分支版本性能变慢了26%\n二次执行时间：相比于基准版本，分支版本性能变慢了26%",
                "用法：PT3\n首次执行时间：相比于基准版本，分支版本性能变慢了50%\n二次执行时间：相比于基准版本，分支版本性能变慢了50%",
            ],
        )
        result = perf.judge_optimization_note(note)
        by_usage = {v.usage: v for v in result["verdicts"]}
        self.assertTrue(by_usage["PT1"].passed)   # x == 1.2
        self.assertFalse(by_usage["PT2"].passed)  # x == 1.26 > 1.25
        self.assertTrue(by_usage["PT3"].passed)   # x == 1.5
        self.assertFalse(result["passed"])

    def test_missing_summary_item_is_calculated_from_detail_tables(self):
        path = ROOT / "docs" / "samples" / "MR472-性能报告-note385041.json"
        note = json.loads(path.read_text(encoding="utf-8"))
        note = copy.deepcopy(note)
        note["summary"] = note["summary"][:1]
        result = perf.judge_optimization_note(note)
        pt2_first = result["verdicts"][1].checks[0]
        self.assertEqual(pt2_first.change_text, "摘要缺项")
        self.assertEqual(pt2_first.source, "详细表补算")
        self.assertAlmostEqual(pt2_first.x, 0.655429 / 6.80948)
        self.assertTrue(result["passed"])

    def test_zero_baseline_is_unknown_not_pass(self):
        note = make_note(
            [("PT1", "bad baseline", 0, 0, 1, 1)],
            ["用法：PT1\n首次执行时间：相比于基准版本，分支版本性能变慢了10%"],
        )
        result = perf.judge_optimization_note(note)
        self.assertIsNone(result["passed"])
        self.assertTrue(all(c.passed is None for c in result["verdicts"][0].checks))


if __name__ == "__main__":
    unittest.main()
