import unittest

from pipeline.paste import PasteParseError, parse_submission_text


class PasteInputTests(unittest.TestCase):
    def test_generic_submission_title_extracts_name_and_function(self):
        text = (
            "【提测】图像处理工具箱函数 imtophat 中使用Julia替代python依赖提测 "
            "代码 https://git.tongyuan.cc/syslab/packages/image/"
            "TyImageProcessing.jl/-/merge_requests/1 "
            "文档 https://git.tongyuan.cc/syslab/syslab-docs-2.0/"
            "-/merge_requests/2"
        )

        result = parse_submission_text(text)

        self.assertEqual(
            result["name"],
            "【提测】图像处理工具箱函数 imtophat 中使用Julia替代python依赖提测",
        )
        self.assertEqual(result["func"], "imtophat")
        self.assertEqual(result["task_type"], "new_function")

    def test_user_provided_encoded_concatenated_text(self):
        text = (
            "https://git.tongyuan.cc/syslab/packages/math/TyDifferentialEquation.jl/-/merge_requests/250"
            "%E3%80%90%E6%95%B0%E5%AD%A6%E5%BA%932026.7%E6%9C%88%E7%AC%AC%E4%BA%8C%E5%91%A8"
            "%E5%91%A8%E6%8F%90%E6%B5%8B%E3%80%91TyDifferentialEquation%EF%BC%9Aode89%20"
            "%E5%87%BD%E6%95%B0%E6%80%A7%E8%83%BD%E4%BC%98%E5%8C%96ode89%E5%87%BD%E6%95%B0"
            "%E6%8E%A5%E5%8F%A3"
            "https://git.tongyuan.cc/syslab/packages/math/TyDifferentialEquation.jl/-/merge_requests/250"
        )
        result = parse_submission_text(text)
        self.assertEqual(
            result["name"],
            "【数学库2026.7月第二周周提测】TyDifferentialEquation：ode89 函数性能优化",
        )
        self.assertEqual(
            result["code_mr"],
            "https://git.tongyuan.cc/syslab/packages/math/TyDifferentialEquation.jl/-/merge_requests/250",
        )
        self.assertEqual(result["doc_mr"], "")
        self.assertEqual(result["task_type"], "performance_optimization")
        self.assertEqual(len(result["urls"]), 1)  # 重复链接已去重

    def test_new_function_extracts_code_and_doc_mr(self):
        text = (
            "【数学库2026.7月第二周周提测】TyComputationalGeometry：新增convexHull函数 "
            "代码 https://git.tongyuan.cc/syslab/packages/math/TyComputationalGeometry.jl/-/merge_requests/343 "
            "文档 https://git.tongyuan.cc/syslab/syslab-docs-2.0/-/merge_requests/3765"
        )
        result = parse_submission_text(text)
        self.assertEqual(result["task_type"], "new_function")
        self.assertTrue(result["code_mr"].endswith("/343"))
        self.assertTrue(result["doc_mr"].endswith("/3765"))
        self.assertEqual(result["warnings"], [])

    def test_function_optimization_alias_does_not_require_doc_mr(self):
        text = (
            "数学库：函数优化rmnode "
            "代码 https://git.tongyuan.cc/syslab/packages/image/"
            "TyImageProcessing.jl/-/merge_requests/7"
        )
        result = parse_submission_text(text)
        self.assertEqual(result["task_type"], "performance_optimization")
        self.assertEqual(result["func"], "rmnode")
        self.assertEqual(result["doc_mr"], "")
        self.assertEqual(result["warnings"], [])

    def test_missing_task_title_is_rejected(self):
        with self.assertRaisesRegex(PasteParseError, "没有识别到新增函数或函数性能优化"):
            parse_submission_text(
                "https://git.tongyuan.cc/syslab/packages/math/TyMathCore.jl/-/merge_requests/1"
            )


if __name__ == "__main__":
    unittest.main()
