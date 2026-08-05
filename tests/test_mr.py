import unittest

from pipeline import mr


class BranchParsingTests(unittest.TestCase):
    def test_reads_regular_mr_text(self):
        self.assertEqual(
            mr._parse_branches(
                "Open requested to merge feature/area into main"
            ),
            ("feature/area", "main"),
        )

    def test_reads_stacked_mr_from_branch_links(self):
        self.assertEqual(
            mr._parse_branches(
                "Open requested to merge 1 of 2 Stacked merge requests",
                [
                    {"name": "tz/alphaTriangulation", "href": "/-/tree/tz/alphaTriangulation"},
                    {"name": "main", "href": "/-/tree/main"},
                ],
            ),
            ("tz/alphaTriangulation", "main"),
        )

    def test_stacked_text_fallback_allows_merge_position(self):
        self.assertEqual(
            mr._parse_branches(
                "Open requested to merge 1 of 2 feature/area into main"
            ),
            ("feature/area", "main"),
        )

    def test_branch_links_preserve_slashes_in_branch_name(self):
        self.assertEqual(
            mr._parse_branches(
                "ignored",
                [
                    {"name": "user/feature/alpha", "href": "/-/tree/user/feature/alpha"},
                    {"name": "develop", "href": "/-/tree/develop"},
                ],
            ),
            ("user/feature/alpha", "develop"),
        )


class PerformanceNoteSelectionTests(unittest.TestCase):
    @staticmethod
    def _note(heading, func, git_file=None):
        return {
            "heading": heading,
            "summary_text": "",
            "tables": [{
                "title": "分支版本详细数据",
                "headers": ["func_name", "git_file", "name"],
                "rows": [[
                    func,
                    git_file or f"benchmark/BoundaryArea/{func}/PerformanceTest",
                    f"{func} - sample",
                ]],
            }],
        }

    def test_selects_latest_note_for_requested_function(self):
        notes = [
            self._note(
                "julia分支性能对比测试报告 2026-07-16 08:52:53",
                "alphaTriangulation",
            ),
            self._note(
                "julia分支性能对比测试报告 2026-07-16 09:03:49",
                "volume",
            ),
            self._note(
                "julia分支性能对比测试报告 2026-07-16 09:05:00",
                "volume",
            ),
            self._note(
                "julia分支性能对比测试报告 2026-07-16 10:01:01",
                "alphaShape",
            ),
        ]

        selected = mr._select_perf_note(notes, "volume")

        self.assertEqual(
            selected["heading"],
            "julia分支性能对比测试报告 2026-07-16 09:05:00",
        )

    def test_git_file_is_used_when_func_name_is_missing(self):
        note = {
            "heading": "julia分支性能对比测试报告 2026-07-16 09:05:00",
            "tables": [{
                "title": "分支版本详细数据",
                "headers": ["git_file", "name"],
                "rows": [[
                    "benchmark/BoundaryArea/volume/PerformanceTest/PerformanceTest1",
                    "volume - sample",
                ]],
            }],
        }

        self.assertIs(mr._select_perf_note([note], "volume"), note)

    def test_function_match_uses_identifier_boundaries(self):
        notes = [self._note("report 2026-07-16 10:01:01", "surfaceArea")]

        self.assertIsNone(mr._select_perf_note(notes, "area"))

    def test_missing_function_report_does_not_select_another_function(self):
        notes = [self._note("report 2026-07-16 10:01:01", "alphaShape")]

        self.assertIsNone(mr._select_perf_note(notes, "volume"))


if __name__ == "__main__":
    unittest.main()
