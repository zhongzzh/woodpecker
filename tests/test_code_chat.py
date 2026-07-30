import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from pipeline import analyze, code_chat, config


class CodeChatTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        self.tasks_patch = patch.object(config, "TASKS_DIR", self.root)
        self.tasks_patch.start()
        self.task_dir = self.root / "sample-20260730-120000"
        materials = self.task_dir / "materials"
        materials.mkdir(parents=True)
        (self.task_dir / "分析报告.md").write_text(
            "# sample 分析\n\n```julia\n@testset \"sample 补充覆盖\" begin\nend\n```",
            encoding="utf-8",
        )
        (self.task_dir / "task.json").write_text(json.dumps({
            "name": "sample函数", "func": "sample", "task_type": "local_analysis",
            "local_code": r"C:\external\test_sample.jl",
        }), encoding="utf-8")
        (materials / "sample.md").write_text("# sample 文档", encoding="utf-8")
        (materials / "test_sample.jl").write_text("@test sample(1) == 1", encoding="utf-8")
        (materials / "sample.jl").write_text("sample(x) = x", encoding="utf-8")
        (materials / "性能分析-AI原始返回.md").write_text(
            "不应进入补测上下文", encoding="utf-8"
        )

    def tearDown(self):
        self.tasks_patch.stop()
        self.temp_dir.cleanup()

    def test_send_persists_messages_and_uses_task_snapshots(self):
        answer = "```julia\n@testset \"sample 补充覆盖 v2\" begin\nend\n```"
        with patch(
            "pipeline.code_chat.analyze.code_refinement_chat",
            return_value=answer,
        ) as refine:
            result = code_chat.send_message(
                self.task_dir.name, "把用例改成固定输入", log=lambda _message: None
            )

        self.assertEqual([item["role"] for item in result["messages"]], [
            "user", "assistant",
        ])
        context, history, question = refine.call_args.args[:3]
        self.assertEqual(question, "把用例改成固定输入")
        self.assertEqual(history, [])
        self.assertIn("sample 分析", context["analysis_report"])
        self.assertEqual(
            {item["filename"] for item in context["materials"]},
            {"sample.md", "sample.jl", "test_sample.jl"},
        )
        self.assertNotIn(
            "不应进入补测上下文",
            json.dumps(context, ensure_ascii=False),
        )
        self.assertTrue((self.task_dir / code_chat.CHAT_FILE_NAME).is_file())

    def test_second_turn_receives_persisted_history_and_clear_removes_it(self):
        answers = ["第一轮回答", "第二轮回答"]
        with patch(
            "pipeline.code_chat.analyze.code_refinement_chat",
            side_effect=answers,
        ) as refine:
            code_chat.send_message(self.task_dir.name, "第一轮")
            result = code_chat.send_message(self.task_dir.name, "第二轮")

        history = refine.call_args.args[1]
        self.assertEqual([item["content"] for item in history], [
            "第一轮", "第一轮回答",
        ])
        self.assertEqual(len(result["messages"]), 4)
        cleared = code_chat.clear_conversation(self.task_dir.name)
        self.assertEqual(cleared["messages"], [])
        self.assertFalse((self.task_dir / code_chat.CHAT_FILE_NAME).exists())

    def test_rejects_path_escape_and_empty_message(self):
        with self.assertRaisesRegex(code_chat.CodeChatError, "任务不存在"):
            code_chat.conversation("../outside")
        with self.assertRaisesRegex(code_chat.CodeChatError, "请输入"):
            code_chat.send_message(self.task_dir.name, "  ")


class CodeRefinementPromptTests(unittest.TestCase):
    def test_prompt_requires_append_only_static_test_block(self):
        with patch("pipeline.analyze._run_analysis", return_value="回答") as run:
            result = analyze.code_refinement_chat(
                {"analysis_report": "报告", "materials": []},
                [{"role": "user", "content": "上一轮"}],
                "优化随机数据",
            )

        self.assertEqual(result, "回答")
        system, user, _log = run.call_args.args
        self.assertIn("原样追加到测试文件物理末尾", system)
        self.assertIn("只能出现一个完整的 Julia 代码块", system)
        self.assertIn("恰好是一个作用域自足的顶层 `@testset`", system)
        self.assertIn("证据不足时明确指出缺什么", system)
        self.assertIn("不得声称已运行", system)
        self.assertIn("MATLAB baseline", system)
        self.assertIn("优化随机数据", user)
        self.assertIn("上一轮", user)


if __name__ == "__main__":
    unittest.main()
