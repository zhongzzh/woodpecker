import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from pipeline import config
from pipeline.run import run
from pipeline.taskcard import TaskCard


ROOT = Path(__file__).resolve().parents[1]


class PerformanceOptimizationPipelineTests(unittest.TestCase):
    def test_pipeline_runs_without_doc_mr(self):
        sample = json.loads(
            (ROOT / "docs" / "samples" / "MR472-性能报告-note385041.json")
            .read_text(encoding="utf-8")
        )
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            tasks_dir = root / "tasks"
            docs_repo = root / config.DOCS_REPO_NAME
            code_repo = root / "TyStatisticsCore.jl"
            docs_repo.mkdir()
            (code_repo / "test").mkdir(parents=True)
            unit_file = code_repo / "test" / "partialcorri.jl"
            unit_file.write_text("@testset \"partialcorri\" begin\nend\n", encoding="utf-8")

            card = TaskCard(
                name="TyStatisticsCore：partialcorri 函数性能优化",
                code_mr="https://git.tongyuan.cc/syslab/packages/math/TyStatisticsCore.jl/-/merge_requests/472",
            )

            def fake_ensure(project, log=print):
                return docs_repo if project == config.DOCS_REPO_PROJECT else code_repo

            with (
                patch.object(config, "TASKS_DIR", tasks_dir),
                patch("pipeline.run.repo.ensure_repo", side_effect=fake_ensure),
                patch("pipeline.run.repo.refresh_repo", return_value=True),
                patch("pipeline.run.repo.prepare_branch", return_value={}),
                patch("pipeline.run.mr.read_mr", return_value={
                    "source_branch": "lius/partialcorri_optim_3",
                    "perf_note": sample,
                }),
                patch("pipeline.run.locate.read_existing_doc_md", return_value={
                    "relative_path": "syslabHelpSourceCode/projects/TyMath/Doc/partialcorri.md",
                    "text": "# partialcorri\n",
                    "revision": "origin/develop",
                }),
                patch("pipeline.run.locate.find_unit_test", return_value={
                    "main": unit_file, "companions": [],
                }),
                patch("pipeline.run.locate.find_benchmark_dir", return_value=None),
            ):
                report_path = run(card, skip_ai=True, log=lambda _msg: None)

            report = report_path.read_text(encoding="utf-8")
            task = json.loads((report_path.parent / "task.json").read_text(encoding="utf-8"))
            self.assertIn("任务类型：性能优化", report)
            self.assertIn("【未衰退（性能提升/持平）】", report)
            self.assertIn("性能验证通过（未衰退）", report)
            self.assertIsNone(task["doc_mr"])
            self.assertEqual(task["task_type"], "performance_optimization")
            self.assertTrue((report_path.parent / "materials" / "partialcorri.md").exists())


class LocalMaterialPipelineTests(unittest.TestCase):
    def test_local_pipeline_skips_git_and_optional_performance(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            tasks_dir = root / "tasks"
            unit_file = root / "sample.jl"
            data_file = root / "sample_data_1.jl"
            doc_file = root / "sample.md"
            unit_file.write_text("include(\"sample_data_1.jl\")\n@test true", encoding="utf-8")
            data_file.write_text("values = [1]", encoding="utf-8")
            doc_file.write_text("# sample\n", encoding="utf-8")
            card = TaskCard(
                name="检查本地材料", input_mode="local",
                local_code=str(unit_file), local_doc=str(doc_file),
            )

            with (
                patch.object(config, "TASKS_DIR", tasks_dir),
                patch("pipeline.run.repo.ensure_repo", side_effect=AssertionError("不应访问 Git")),
                patch("pipeline.run.mr.read_mr", side_effect=AssertionError("不应访问 MR")),
            ):
                report_path = run(card, skip_ai=True, log=lambda _message: None)

            report = report_path.read_text(encoding="utf-8")
            task = json.loads((report_path.parent / "task.json").read_text(encoding="utf-8"))
            materials = report_path.parent / "materials"
            self.assertIn("任务类型：本地材料分析", report)
            self.assertIn("本次不进行性能测试分析", report)
            self.assertIn("功能验证未进行，本次未进行性能分析", report)
            self.assertEqual(task["input_mode"], "local")
            self.assertFalse(task["pasted_performance_report"])
            self.assertTrue((materials / "sample.md").exists())
            self.assertTrue((materials / "sample.jl").exists())
            self.assertTrue((materials / "sample_data_1.jl").exists())

    def test_local_pipeline_analyzes_and_snapshots_pasted_performance(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            tasks_dir = root / "tasks"
            unit_file = root / "sample.jl"
            doc_file = root / "sample.md"
            unit_file.write_text("@test true", encoding="utf-8")
            doc_file.write_text("# sample", encoding="utf-8")
            card = TaskCard(
                name="检查本地材料", input_mode="local",
                local_code=str(unit_file), local_doc=str(doc_file),
            )

            with (
                patch.object(config, "TASKS_DIR", tasks_dir),
                patch("pipeline.run.analyze.coverage_analysis", return_value="覆盖分析完成"),
                patch(
                    "pipeline.run.analyze.pasted_performance_analysis",
                    return_value="### 用户粘贴的性能报告分析\n\n无法完整判定",
                ) as perf_analysis,
            ):
                report_path = run(
                    card, perf_report_text="基准 Julia: 1.0s", log=lambda _message: None
                )

            report = report_path.read_text(encoding="utf-8")
            perf_analysis.assert_called_once()
            self.assertIn("已分析用户粘贴的性能报告信息", report)
            self.assertTrue(
                (report_path.parent / "materials" / "性能报告-用户粘贴.txt").exists()
            )

    def test_no_ai_saves_pasted_performance_without_claiming_analysis(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            unit_file = root / "sample.jl"
            doc_file = root / "sample.md"
            unit_file.write_text("@test true", encoding="utf-8")
            doc_file.write_text("# sample", encoding="utf-8")
            card = TaskCard(
                name="检查本地材料", input_mode="local",
                local_code=str(unit_file), local_doc=str(doc_file),
            )
            with patch.object(config, "TASKS_DIR", root / "tasks"):
                report_path = run(
                    card, skip_ai=True, perf_report_text="性能报告原文",
                    log=lambda _message: None,
                )

            report = report_path.read_text(encoding="utf-8")
            self.assertIn("已保存用户粘贴的性能报告原文", report)
            self.assertIn("本次未进行性能分析", report)
            self.assertNotIn("已分析用户粘贴的性能报告信息", report)


if __name__ == "__main__":
    unittest.main()
