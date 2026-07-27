import os
import unittest
from unittest.mock import patch

from pipeline import analyze


EMPTY_CONFIG = {"protocol": "", "base_url": "", "api_key": "", "model": ""}


class AiConfigTests(unittest.TestCase):
    def test_api_key_mask_exposes_only_last_four_characters(self):
        masked = analyze.mask_api_key("sk-secret-123456")
        self.assertEqual(masked, "••••••••3456")
        self.assertNotIn("secret", masked)

    def test_switching_protocol_does_not_reuse_saved_other_protocol_key(self):
        saved = {
            "protocol": "openai",
            "base_url": "https://saved-openai.example/v1",
            "api_key": "saved-openai-key",
            "model": "saved-openai-model",
        }
        env = {
            "ANTHROPIC_BASE_URL": "https://anthropic.example/v1",
            "ANTHROPIC_API_KEY": "anthropic-env-key",
        }
        with (
            patch("pipeline.analyze.load_ai_config", return_value=saved),
            patch.dict(os.environ, env, clear=True),
        ):
            resolved = analyze.resolve_ai_config(protocol="anthropic")

        self.assertEqual(resolved["protocol"], "anthropic")
        self.assertEqual(resolved["base_url"], "https://anthropic.example")
        self.assertEqual(resolved["api_key"], "anthropic-env-key")
        self.assertNotEqual(resolved["model"], "saved-openai-model")

    def test_custom_prompt_uses_selected_provider_without_cli_fallback(self):
        effective = {
            "protocol": "openai",
            "base_url": "https://openai.example",
            "api_key": "test-key",
            "model": "test-model",
        }
        with (
            patch("pipeline.analyze.resolve_ai_config", return_value=effective),
            patch("pipeline.analyze._via_openai", return_value="test answer") as call,
            patch("pipeline.analyze._via_cli") as cli,
        ):
            answer = analyze.test_ai_prompt("hello")

        self.assertEqual(answer, "test answer")
        self.assertEqual(call.call_args.kwargs["eff"], effective)
        self.assertEqual(call.call_args.kwargs["max_tokens"], 512)
        cli.assert_not_called()

    def test_custom_prompt_rejects_empty_question(self):
        with self.assertRaisesRegex(analyze.AnalyzeError, "填写测试问题"):
            analyze.test_ai_prompt("  ")

    def test_pasted_performance_report_is_not_filtered_by_task_function(self):
        report = (
            "函数名\tJulia 首次用时 s\tMATLAB 首次用时 s\tsyslab/matlab首次比例\n"
            "cameraProjection\t0.2\t0.1\t2.0"
        )
        with patch("pipeline.analyze._run_analysis", return_value="分析完成") as call:
            result = analyze.pasted_performance_analysis("activecontour", report)

        self.assertEqual(result, "分析完成")
        system, user, _log = call.call_args.args
        self.assertIn("不得用当前任务函数名筛选", system)
        self.assertIn("所有具有可用性能数据", system)
        self.assertIn("报告给出“Julia / MATLAB”", system)
        self.assertIn("仅作背景，不用于筛选报告", user)
        self.assertIn("cameraProjection", user)


if __name__ == "__main__":
    unittest.main()
