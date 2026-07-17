import unittest

from pipeline.web import _build_argv


class WebArgvTests(unittest.TestCase):
    def test_performance_task_does_not_emit_doc_mr_argument(self):
        argv = _build_argv({
            "name": "ode89 函数性能优化",
            "code_mr": "https://git.tongyuan.cc/a/b/-/merge_requests/1",
            "doc_mr": "",
        })
        self.assertNotIn("--doc-mr", argv)

    def test_new_function_keeps_doc_mr_argument(self):
        argv = _build_argv({
            "name": "新增 ode89 函数",
            "code_mr": "https://git.tongyuan.cc/a/b/-/merge_requests/1",
            "doc_mr": "https://git.tongyuan.cc/a/docs/-/merge_requests/2",
        })
        self.assertIn("--doc-mr", argv)


if __name__ == "__main__":
    unittest.main()
