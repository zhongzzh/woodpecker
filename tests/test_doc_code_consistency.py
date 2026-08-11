import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from pipeline import analyze, config, locate
from pipeline.run import run
from pipeline.taskcard import TaskCard
from pipeline.web import _build_argv, _resolve_local_materials


class DocumentCodeConsistencyTests(unittest.TestCase):
    def test_markdown_code_block_can_match_complete_code_file(self):
        markdown = "# sample\n\n```julia\nvalue = 1\n```\n"

        report = analyze.document_code_consistency(
            markdown, "value = 1\n", "sample.md", "sample.jl"
        )

        self.assertIn("初筛结果：**未发现文本差异", report)
        self.assertIn("完全一致 1 个，有差异 0 个", report)
        self.assertIn("对应代码文件第 1 行", report)

    def test_changed_code_is_reported_with_diff(self):
        markdown = "```julia\nvalue = 1\n```"

        report = analyze.document_code_consistency(
            markdown, "value = 2", "sample.md", "sample.jl"
        )

        self.assertIn("初筛结果：**发现候选差异", report)
        self.assertIn("文本疑似修改", report)
        self.assertIn("待 AI 复审的候选差异", report)
        self.assertIn("代码文件中最接近的语句（第 1 行）", report)
        self.assertIn("-value = 1", report)
        self.assertIn("+value = 2", report)

    def test_report_groups_differences_by_heading_and_ignores_output_blocks(self):
        markdown = (
            "## 步骤 1：读取图像\n\n"
            "```julia\nrgb = imread(\"doc.png\")\n```\n\n"
            "```dataframe\n45\n```\n"
        )

        report = analyze.document_code_consistency(
            markdown, 'rgb = imread("code.png")', "sample.md", "sample.jl"
        )

        self.assertIn("步骤 1：读取图像（文档第 4 行）", report)
        self.assertIn("已忽略非代码输出块：1 个", report)
        self.assertIn('rgb = imread("doc.png")', report)
        self.assertIn('rgb = imread("code.png")', report)

    def test_ai_semantic_review_treats_path_and_display_setup_as_equivalent(self):
        markdown = (
            "```julia\n"
            "using TyImageProcessing\n"
            "using TyPlot\n"
            'rgb = imread("coloredChips.png");\n'
            "imshow(rgb)\n"
            "```\n"
        )
        code = (
            "# 读取并显示彩色圆片图像\n"
            'rgb = imread(joinpath(path, "coloredChips.png"));\n'
            "figure();\n"
            "imshow(rgb)\n"
        )
        ai_response = json.dumps({
            "verdict": "consistent",
            "summary": "两段代码完成相同的图像读取和显示流程，没有功能步骤丢失。",
            "reviewed_candidates": 3,
            "missing_items": [],
            "equivalent_items": [{
                "section": "未命名代码块",
                "document_lines": "2-5",
                "document_code": (
                    'rgb = imread("coloredChips.png");\nimshow(rgb)'
                ),
                "code_lines": "2-4",
                "code_code": (
                    'rgb = imread(joinpath(path, "coloredChips.png"));\n'
                    "figure();\nimshow(rgb)"
                ),
                "reason": "joinpath 只补充资源目录，figure 只是显示准备，核心数据流相同。",
            }],
            "notes": ["using 声明由运行环境统一提供，不属于示例功能丢失。"],
        }, ensure_ascii=False)

        with patch.object(analyze, "_run_analysis", return_value=ai_response) as request:
            result = analyze.document_code_consistency_analysis(
                markdown, code, "example.md", "example.jl", log=lambda _message: None
            )

        self.assertEqual(result["status"], "consistent")
        self.assertEqual(result["review"]["missing_items"], [])
        self.assertIn("未发现明显代码缺失", result["markdown"])
        self.assertIn("已确认的等价写法", result["markdown"])
        self.assertIn("imread(joinpath(path", result["markdown"])
        self.assertIn("using 声明由运行环境统一提供", result["markdown"])
        system_prompt, user_prompt = request.call_args.args[:2]
        self.assertIn('imread(joinpath(path, "coloredChips.png"))', system_prompt)
        self.assertIn(markdown, user_prompt)
        self.assertIn(code, user_prompt)

    def test_ai_review_json_can_be_fenced_and_missing_evidence_is_rendered(self):
        raw = """```json
        {
          "verdict": "missing",
          "reviewed_candidates": 1,
          "missing_items": [{
            "section": "测量半径",
            "document_lines": "20",
            "document_code": "radii = measure_radii(circles)",
            "expected_behavior": "计算每个圆的半径",
            "code_evidence": "完整代码只检测圆心，未调用半径计算或等价逻辑",
            "reason": "后续也没有生成半径结果"
          }],
          "equivalent_items": [],
          "notes": []
        }
        ```"""

        review = analyze._parse_doc_code_review(raw)
        report, status = analyze._render_doc_code_review(
            review, "example.md", "example.jl"
        )

        self.assertEqual(status, "missing")
        self.assertIn("发现 1 处明显代码缺失", report)
        self.assertIn("文档预期功能：** 计算每个圆的半径", report)
        self.assertIn("代码侧证据：** 完整代码只检测圆心", report)

    def test_parent_directories_are_resolved_by_file_name(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            code = root / "repository" / "src" / "sample.jl"
            doc = root / "documentation" / "guide" / "sample.md"
            code.parent.mkdir(parents=True)
            doc.parent.mkdir(parents=True)
            code.write_text("value = 1", encoding="utf-8")
            doc.write_text("```julia\nvalue = 1\n```", encoding="utf-8")
            card = TaskCard(
                name="sample.md",
                input_mode="local",
                local_code=str(root / "repository"),
                local_doc=str(root / "documentation"),
                compare_doc_code=True,
            )

            resolved = _resolve_local_materials(card)

        self.assertEqual(resolved["local_code"], str(code))
        self.assertEqual(resolved["local_doc"], str(doc))
        self.assertFalse(card.uses_local_repositories)
        self.assertEqual(card.local_library, "")

    def test_explicit_code_file_does_not_need_to_share_document_slug(self):
        with tempfile.TemporaryDirectory() as tmp:
            code = Path(tmp) / "03_DetectAndMeasureCircularObjectsInAnImage.jl"
            code.write_text("value = 1", encoding="utf-8")

            resolved = locate.find_local_named_code(
                str(code),
                "detect-and-measure-circular-objects-in-an-image",
                log=lambda _message: None,
            )

        self.assertEqual(resolved, code)

    def test_parent_directory_matches_numbered_camel_case_code_name(self):
        with tempfile.TemporaryDirectory() as tmp:
            code = Path(tmp) / "03_DetectAndMeasureCircularObjectsInAnImage.jl"
            code.write_text("value = 1", encoding="utf-8")

            resolved = locate.find_local_named_code(
                tmp,
                "detect-and-measure-circular-objects-in-an-image",
                log=lambda _message: None,
            )

        self.assertEqual(resolved, code)

    def test_pipeline_generates_ai_consistency_report(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            code = root / "sample.jl"
            doc = root / "sample.md"
            code.write_text("value = 1\n", encoding="utf-8")
            doc.write_text("```julia\nvalue = 1\n```\n", encoding="utf-8")
            card = TaskCard(
                name="sample",
                input_mode="local",
                local_code=str(code),
                local_doc=str(doc),
                compare_doc_code=True,
            )
            with (
                patch.object(config, "TASKS_DIR", root / "tasks"),
                patch(
                    "pipeline.run.analyze.coverage_analysis",
                    side_effect=AssertionError("一致性检查不应调用覆盖分析 AI"),
                ),
                patch(
                    "pipeline.run.analyze.document_code_consistency_analysis",
                    return_value={
                        "markdown": "### AI 复审\n\n- 结论：**未发现明显代码缺失**",
                        "status": "consistent",
                        "raw": '{"verdict":"consistent"}',
                        "review": {"verdict": "consistent"},
                    },
                ) as semantic_review,
            ):
                report_path = run(card, log=lambda _message: None)

            report = report_path.read_text(encoding="utf-8")
            task = json.loads(
                (report_path.parent / "task.json").read_text(encoding="utf-8")
            )
            raw_response = (
                report_path.parent / "materials" / "文档代码一致性-AI原始返回.json"
            ).read_text(encoding="utf-8")

        self.assertIn("任务类型：文档代码一致性检查", report)
        self.assertIn("结论：**未发现明显代码缺失", report)
        self.assertNotIn("单元测试覆盖分析", report)
        self.assertEqual(task["consistency_status"], "consistent")
        self.assertEqual(task["coverage_ai_status"], "completed")
        self.assertEqual(
            task["consistency_ai_response_file"],
            "materials/文档代码一致性-AI原始返回.json",
        )
        self.assertEqual(raw_response, '{"verdict":"consistent"}')
        semantic_review.assert_called_once()

    def test_pipeline_marks_ai_review_failure_as_undetermined(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            code = root / "sample.jl"
            doc = root / "sample.md"
            code.write_text("value = 2\n", encoding="utf-8")
            doc.write_text("```julia\nvalue = 1\n```\n", encoding="utf-8")
            card = TaskCard(
                name="sample", input_mode="local", local_code=str(code),
                local_doc=str(doc), compare_doc_code=True,
            )
            with (
                patch.object(config, "TASKS_DIR", root / "tasks"),
                patch(
                    "pipeline.run.analyze.document_code_consistency_analysis",
                    side_effect=analyze.AnalyzeError("AI endpoint unavailable"),
                ),
            ):
                report_path = run(card, log=lambda _message: None)

            report = report_path.read_text(encoding="utf-8")
            task = json.loads(
                (report_path.parent / "task.json").read_text(encoding="utf-8")
            )

        self.assertIn("AI 语义复审失败", report)
        self.assertIn("只能作为候选，不能据此断言代码明显缺失", report)
        self.assertEqual(task["consistency_status"], "undetermined")
        self.assertEqual(task["coverage_ai_status"], "failed")

    def test_pipeline_no_ai_only_keeps_non_conclusive_candidates(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            code = root / "sample.jl"
            doc = root / "sample.md"
            code.write_text("value = 2\n", encoding="utf-8")
            doc.write_text("```julia\nvalue = 1\n```\n", encoding="utf-8")
            card = TaskCard(
                name="sample", input_mode="local", local_code=str(code),
                local_doc=str(doc), compare_doc_code=True,
            )
            with (
                patch.object(config, "TASKS_DIR", root / "tasks"),
                patch(
                    "pipeline.run.analyze.document_code_consistency_analysis",
                    side_effect=AssertionError("--no-ai 不应调用 AI 语义复审"),
                ),
            ):
                report_path = run(card, skip_ai=True, log=lambda _message: None)

            report = report_path.read_text(encoding="utf-8")
            task = json.loads(
                (report_path.parent / "task.json").read_text(encoding="utf-8")
            )

        self.assertIn("仅为文本候选差异", report)
        self.assertIn("待 AI 复审的候选差异", report)
        self.assertEqual(task["consistency_status"], "not_reviewed")
        self.assertEqual(task["coverage_ai_status"], "skipped")

    def test_web_command_uses_dedicated_mode_argument(self):
        argv = _build_argv({
            "input_mode": "local",
            "name": "sample",
            "local_code": r"C:\code",
            "local_doc": r"C:\docs",
            "compare_doc_code": True,
        })

        self.assertIn("--compare-doc-code", argv)
        self.assertIn("--local-code", argv)
        self.assertNotIn("--local-library", argv)


if __name__ == "__main__":
    unittest.main()
