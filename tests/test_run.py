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


if __name__ == "__main__":
    unittest.main()
