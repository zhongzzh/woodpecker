import unittest
from pathlib import Path

from pipeline.taskcard import TaskCard


class TaskCardTests(unittest.TestCase):
    def test_complete_submission_title_extracts_function_after_function_word(self):
        card = TaskCard(
            name=(
                "【提测】图像处理工具箱函数 imtophat 中使用Julia替代"
                "python依赖提测"
            ),
            code_mr=(
                "https://git.tongyuan.cc/syslab/packages/image/"
                "TyImageProcessing.jl/-/merge_requests/1"
            ),
            doc_mr=(
                "https://git.tongyuan.cc/syslab/syslab-docs-2.0/"
                "-/merge_requests/1"
            ),
        )
        self.assertEqual(card.name, "【提测】图像处理工具箱函数 imtophat 中使用Julia替代python依赖提测")
        self.assertEqual(card.func, "imtophat")
        self.assertEqual(card.task_type, "new_function")

    def test_function_field_also_accepts_complete_submission_title(self):
        card = TaskCard(
            name="检查本地材料",
            func="【提测】图像处理工具箱函数 imtophat 中使用Julia替代python依赖提测",
            input_mode="local",
            local_code="code",
            local_doc="docs",
        )
        self.assertEqual(card.func, "imtophat")

    def test_performance_optimization_needs_no_doc_mr(self):
        card = TaskCard(
            name="【数学库2026.7月第二周周提测】TyDifferentialEquation：ode89 函数性能优化",
            code_mr="https://git.tongyuan.cc/syslab/packages/math/TyDifferentialEquation.jl/-/merge_requests/1",
        )
        self.assertEqual(card.task_type, "performance_optimization")
        self.assertEqual(card.func, "ode89")
        self.assertEqual(card.doc_project, "syslab/syslab-docs-2.0")
        self.assertTrue(card.uses_optimization_summary)

    def test_function_optimization_alias_needs_no_doc_mr(self):
        card = TaskCard(
            name="函数优化rmnode",
            code_mr="https://git.tongyuan.cc/syslab/packages/math/TyImageProcessing.jl/-/merge_requests/1",
        )
        self.assertEqual(card.task_type, "performance_optimization")
        self.assertEqual(card.func, "rmnode")
        self.assertFalse(card.uses_optimization_summary)

    def test_new_function_still_requires_doc_mr(self):
        with self.assertRaisesRegex(ValueError, "必须提供文档 MR"):
            TaskCard(
                name="新增 convexHull 函数",
                code_mr="https://git.tongyuan.cc/syslab/packages/math/TyComputationalGeometry.jl/-/merge_requests/343",
            )

    def test_unknown_task_type_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "无法从任务名识别任务类型"):
            TaskCard(
                name="ode89 调整",
                code_mr="https://git.tongyuan.cc/syslab/packages/math/TyDifferentialEquation.jl/-/merge_requests/1",
            )

    def test_local_mode_accepts_plain_name_and_infers_function_from_doc(self):
        card = TaskCard(
            name="检查本地材料",
            input_mode="local",
            local_code=r"C:\materials\sample.jl",
            local_doc=r"C:\materials\sample.md",
        )
        self.assertEqual(card.task_type, "local_analysis")
        self.assertEqual(card.func, "sample")
        self.assertTrue(card.is_local)
        with self.assertRaisesRegex(ValueError, "没有代码 MR 项目"):
            _ = card.code_project

    def test_local_mode_parses_function_and_accepts_separate_roots(self):
        card = TaskCard(
            name="chromadapt函数", input_mode="local",
            local_code=str(Path("code")), local_doc=str(Path("docs")),
        )
        self.assertEqual(card.func, "chromadapt")
        self.assertEqual(card.local_code, str(Path("code")))
        self.assertEqual(card.local_doc, str(Path("docs")))

    def test_local_repository_mode_accepts_bare_function_name(self):
        card = TaskCard(
            name="graydiffweight",
            input_mode="local",
            local_library="TyImageProcessing",
            local_branch="pyh/add_graydiffweight",
        )
        self.assertEqual(card.func, "graydiffweight")
        self.assertTrue(card.uses_local_repositories)
        self.assertEqual(card.code_repo_name, "TyImageProcessing")

    def test_local_repository_mode_requires_library(self):
        with self.assertRaisesRegex(ValueError, "必须提供函数库名称"):
            TaskCard(
                name="graydiffweight",
                input_mode="local",
                local_branch="pyh/add_graydiffweight",
            )

    def test_local_library_with_paths_uses_manual_materials(self):
        card = TaskCard(
            name="graydiffweight",
            input_mode="local",
            local_library="TyImageProcessing",
            local_code="code",
            local_doc="docs",
        )
        self.assertFalse(card.uses_local_repositories)

    def test_local_mode_requires_both_paths(self):
        with self.assertRaisesRegex(ValueError, "必须提供文档文件或目录"):
            TaskCard(
                name="chromadapt函数", input_mode="local", local_code="code"
            )


if __name__ == "__main__":
    unittest.main()
