import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import ANY, patch

from pipeline import analyze, config
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

            def fake_ensure(project, log=print, local_path=None):
                if project == config.DOCS_REPO_PROJECT:
                    self.assertEqual(local_path, config.DOCS_REPO_DIR)
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
    def test_manual_local_paths_can_build_document_html(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            docs_repo = root / config.DOCS_REPO_NAME
            doc_relative = (
                "syslabHelpSourceCode/projects/TyImageProcessing/Doc/"
                "TyImageProcessing/sample.md"
            )
            doc_file = docs_repo / Path(*doc_relative.split("/"))
            unit_file = root / "code" / "test_sample.jl"
            (docs_repo / ".git").mkdir(parents=True)
            for path, content in ((doc_file, "# sample"), (unit_file, "@test true")):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content, encoding="utf-8")
            card = TaskCard(
                name="sample", input_mode="local",
                local_library="TyImageProcessing",
                local_code=str(unit_file), local_doc=str(doc_file),
            )
            preview = {
                "project": "TyImageProcessing",
                "html": str(root / "sample.html"),
                "url": "file:///sample.html",
                "browser_opened": True,
            }

            with (
                patch.object(config, "TASKS_DIR", root / "tasks"),
                patch.object(config, "DOCS_REPO_DIR", docs_repo),
                patch(
                    "pipeline.run.doc_html.build_and_open", return_value=preview
                ) as build,
            ):
                report_path = run(
                    card, skip_ai=True, build_doc_html=True,
                    log=lambda _message: None,
                )

            build.assert_called_once_with(
                docs_repo.resolve(), doc_relative, "sample", log=ANY,
            )
            task = json.loads(
                (report_path.parent / "task.json").read_text(encoding="utf-8")
            )
            self.assertEqual(task["doc_md"], doc_relative)
            self.assertTrue(task["doc_html_requested"])

    def test_local_repository_pipeline_can_build_document_html(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            tasks_dir = root / "tasks"
            docs_repo = root / config.DOCS_REPO_NAME
            code_repo = root / "TyImageProcessing.jl"
            doc_relative = (
                "syslabHelpSourceCode/projects/TyImageProcessing/Doc/"
                "TyImageProcessing/graydiffweight.md"
            )
            doc_file = docs_repo / Path(*doc_relative.split("/"))
            test_file = code_repo / "test" / "test_graydiffweight.jl"
            source_file = code_repo / "src" / "graydiffweight.jl"
            for repository in (docs_repo, code_repo):
                (repository / ".git").mkdir(parents=True)
            for path, content in (
                (doc_file, "# graydiffweight"),
                (test_file, "@test true"),
                (source_file, "graydiffweight() = true"),
            ):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content, encoding="utf-8")
            card = TaskCard(
                name="graydiffweight",
                input_mode="local",
                local_library="TyImageProcessing",
                local_branch="pyh/add_graydiffweight",
            )
            preview = {
                "project": "TyImageProcessing",
                "html": str(root / "graydiffweight.html"),
                "url": "file:///graydiffweight.html",
                "browser_opened": True,
            }

            with (
                patch.object(config, "TASKS_DIR", tasks_dir),
                patch.object(config, "DOCS_REPO_DIR", docs_repo),
                patch.object(config, "CLONE_ROOT", root),
                patch("pipeline.run.repo.prepare_branch") as prepare,
                patch(
                    "pipeline.run.doc_html.build_and_open", return_value=preview
                ) as build,
            ):
                report_path = run(
                    card, skip_ai=True, build_doc_html=True,
                    log=lambda _message: None,
                )

            build.assert_called_once_with(
                docs_repo.resolve(), doc_relative, "graydiffweight",
                log=ANY,
            )
            prepare.assert_called_once_with(
                code_repo.resolve(), "pyh/add_graydiffweight", log=ANY,
            )
            task = json.loads(
                (report_path.parent / "task.json").read_text(encoding="utf-8")
            )
            self.assertTrue(task["doc_html_requested"])
            self.assertEqual(task["doc_html_project"], "TyImageProcessing")
            self.assertEqual(task["doc_md"], doc_relative)

    def test_local_repository_syncs_document_branch_only_after_local_miss(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            docs_repo = root / config.DOCS_REPO_NAME
            code_repo = root / "TyImageProcessing.jl"
            doc_file = (
                docs_repo / "syslabHelpSourceCode" / "projects"
                / "TyImageProcessing" / "Doc" / "sample.md"
            )
            test_file = code_repo / "test" / "test_sample.jl"
            for repository in (docs_repo, code_repo):
                (repository / ".git").mkdir(parents=True)
            test_file.parent.mkdir(parents=True)
            test_file.write_text("@test true", encoding="utf-8")
            prepared_repositories = []

            def fake_prepare(repository, branch, log=print):
                prepared_repositories.append(repository)
                if repository == docs_repo.resolve():
                    doc_file.parent.mkdir(parents=True)
                    doc_file.write_text("# sample", encoding="utf-8")
                return {}

            card = TaskCard(
                name="sample", input_mode="local",
                local_library="TyImageProcessing",
                local_branch="dev/add_sample",
            )
            messages = []
            with (
                patch.object(config, "TASKS_DIR", root / "tasks"),
                patch.object(config, "DOCS_REPO_DIR", docs_repo),
                patch.object(config, "CLONE_ROOT", root),
                patch("pipeline.run.repo.prepare_branch", side_effect=fake_prepare),
            ):
                run(card, skip_ai=True, log=messages.append)

            self.assertEqual(
                prepared_repositories, [docs_repo.resolve(), code_repo.resolve()]
            )
            self.assertTrue(any("未找到 sample.md" in msg for msg in messages))

    def test_local_pipeline_resolves_separate_parent_directories(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            tasks_dir = root / "tasks"
            test_file = root / "code" / "test" / "test_chromadapt.jl"
            source_file = root / "code" / "src" / "chromadapt_impl.jl"
            doc_file = root / "docs" / "chromadapt.md"
            for path, content in (
                (test_file, "@test true"),
                (source_file, "chromadapt() = true"),
                (doc_file, "# chromadapt"),
            ):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content, encoding="utf-8")
            card = TaskCard(
                name="chromadapt函数", input_mode="local",
                local_code=str(root / "code"), local_doc=str(root / "docs"),
            )

            with patch.object(config, "TASKS_DIR", tasks_dir):
                report_path = run(card, skip_ai=True, log=lambda _message: None)

            task = json.loads((report_path.parent / "task.json").read_text(encoding="utf-8"))
            self.assertEqual(task["local_code_input"], str(root / "code"))
            self.assertEqual(task["local_doc_input"], str(root / "docs"))
            self.assertEqual(task["local_code"], str(test_file))
            self.assertEqual(task["local_doc"], str(doc_file))
            self.assertEqual(task["local_code_files"], [str(test_file), str(source_file)])
            self.assertEqual(task["local_doc_files"], [str(doc_file)])
            self.assertTrue((report_path.parent / "materials" / test_file.name).exists())
            self.assertTrue((report_path.parent / "materials" / source_file.name).exists())
            self.assertFalse(
                (report_path.parent / config.LOCAL_PATHS_STATE_NAME).exists()
            )

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
                    return_value=(
                        "### 用户粘贴的性能报告分析\n\n"
                        "**性能结论：性能首次不通过，二次通过**"
                    ),
                ) as perf_analysis,
            ):
                report_path = run(
                    card, perf_report_text="基准 Julia: 1.0s", log=lambda _message: None
                )

            report = report_path.read_text(encoding="utf-8")
            perf_analysis.assert_called_once()
            self.assertIn(
                "功能验证通过，性能首次不通过，二次通过，请补充自动化脚本",
                report,
            )
            self.assertIn("## 二、性能测试判定（AI，仅当前函数）", report)
            task = json.loads(
                (report_path.parent / "task.json").read_text(encoding="utf-8")
            )
            self.assertEqual(
                task["performance_verdict"], "性能首次不通过，二次通过"
            )
            self.assertTrue(
                (report_path.parent / "materials" / "性能报告-用户粘贴.txt").exists()
            )
            self.assertTrue(
                (report_path.parent / "materials" / "性能分析-AI原始返回.md").exists()
            )

    def test_unparsed_performance_ai_response_is_preserved_for_diagnostics(self):
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
            ai_response = "#### 综合结论\n\n整体性能看起来可以"

            with (
                patch.object(config, "TASKS_DIR", root / "tasks"),
                patch(
                    "pipeline.run.analyze.coverage_analysis",
                    return_value="覆盖分析完成",
                ),
                patch(
                    "pipeline.run.analyze.pasted_performance_analysis",
                    return_value=ai_response,
                ),
            ):
                report_path = run(
                    card, perf_report_text="性能报告原文",
                    log=lambda _message: None,
                )

            report = report_path.read_text(encoding="utf-8")
            task = json.loads(
                (report_path.parent / "task.json").read_text(encoding="utf-8")
            )
            response_file = report_path.parent / task["performance_ai_response_file"]
            self.assertIn("AI 原始返回（未改写）", report)
            self.assertIn(ai_response, report)
            self.assertIn("性能测试结论无法判定", report)
            self.assertEqual(task["performance_ai_status"], "unparsed")
            self.assertEqual(response_file.read_text(encoding="utf-8"), ai_response)

    def test_performance_ai_failure_keeps_completed_coverage_and_writes_report(self):
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

            with (
                patch.object(config, "TASKS_DIR", root / "tasks"),
                patch(
                    "pipeline.run.analyze.coverage_analysis",
                    return_value="覆盖分析已经完成",
                ),
                patch(
                    "pipeline.run.analyze.pasted_performance_analysis",
                    side_effect=analyze.AnalyzeError(
                        "openai 当前配置连续 3 次调用失败：remote closed"
                    ),
                ),
            ):
                report_path = run(
                    card, perf_report_text="性能报告原文", log=lambda _message: None
                )

            report = report_path.read_text(encoding="utf-8")
            task = json.loads((report_path.parent / "task.json").read_text(encoding="utf-8"))
            self.assertIn("覆盖分析已经完成", report)
            self.assertIn("性能测试 AI 分析失败", report)
            self.assertIn("原始报告已保留", report)
            self.assertEqual(task["coverage_ai_status"], "completed")
            self.assertEqual(task["performance_ai_status"], "failed")
            self.assertTrue(
                (report_path.parent / "materials" / "性能报告-用户粘贴.txt").exists()
            )

    def test_coverage_ai_failure_is_marked_and_report_is_still_written(self):
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

            with (
                patch.object(config, "TASKS_DIR", root / "tasks"),
                patch(
                    "pipeline.run.analyze.coverage_analysis",
                    side_effect=analyze.AnalyzeError(
                        "openai 当前配置连续 3 次调用失败：remote closed"
                    ),
                ),
                patch("pipeline.run.analyze.current_model", return_value="grok-4.5"),
            ):
                report_path = run(card, log=lambda _message: None)

            report = report_path.read_text(encoding="utf-8")
            task = json.loads((report_path.parent / "task.json").read_text(encoding="utf-8"))
            self.assertIn("AI 覆盖分析失败", report)
            self.assertIn("功能验证未进行", report)
            self.assertEqual(task["coverage_ai_status"], "failed")
            self.assertEqual(task["performance_ai_status"], "not_requested")

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
