import unittest

from pipeline.taskcard import TaskCard


class TaskCardTests(unittest.TestCase):
    def test_performance_optimization_needs_no_doc_mr(self):
        card = TaskCard(
            name="【数学库2026.7月第二周周提测】TyDifferentialEquation：ode89 函数性能优化",
            code_mr="https://git.tongyuan.cc/syslab/packages/math/TyDifferentialEquation.jl/-/merge_requests/1",
        )
        self.assertEqual(card.task_type, "performance_optimization")
        self.assertEqual(card.func, "ode89")
        self.assertEqual(card.doc_project, "syslab/syslab-docs-2.0")

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


if __name__ == "__main__":
    unittest.main()
