import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from pipeline import analyze


EMPTY_CONFIG = {"protocol": "", "base_url": "", "api_key": "", "model": ""}


class AiConfigTests(unittest.TestCase):
    def test_coverage_prompt_v2_enforces_stable_markdown_tables(self):
        rules = analyze._load_rules()
        self.assertEqual(analyze.config.PROMPT_FILE.name, "覆盖分析提示词-v2.md")
        self.assertIn("每个表格行只能占一个物理行", rules)
        self.assertIn("单元格内禁止出现换行", rules)
        self.assertIn("对应测试用例位置", rules)

    def test_coverage_prompt_requires_independent_tests_appended_at_end(self):
        rules = analyze._load_rules()
        self.assertIn("只能整体追加到目标单元测试主文件的物理末尾", rules)
        self.assertIn("不得插入、替换、删除或改写", rules)
        self.assertIn("独立的顶层 `@testset`", rules)
        self.assertIn("不得引用原有测试块内部的局部变量", rules)
        self.assertIn("不得建议插入到任何现有测试块中", rules)

        user = analyze._build_user("sample", "# sample", "@test true")
        self.assertIn("整块可原样追加到单元测试主文件的物理末尾", user)
        self.assertIn("不得插入、改写或复述任何原有代码", user)

    def test_custom_coverage_prompt_overrides_default_and_can_be_reset(self):
        with tempfile.TemporaryDirectory() as tmp:
            custom_path = Path(tmp) / ".coverage-prompt.md"
            with patch.object(analyze.config, "CUSTOM_PROMPT_FILE", custom_path):
                self.assertFalse(analyze.coverage_prompt_is_customized())
                analyze.save_coverage_prompt("自定义覆盖规则")
                self.assertEqual(analyze._load_rules(), "自定义覆盖规则")
                self.assertTrue(analyze.coverage_prompt_is_customized())

                restored = analyze.reset_coverage_prompt()

                self.assertFalse(custom_path.exists())
                self.assertEqual(analyze._load_rules(), restored)
                self.assertIn("每个表格行只能占一个物理行", restored)

    def test_empty_custom_coverage_prompt_is_rejected(self):
        with self.assertRaisesRegex(analyze.AnalyzeError, "不能为空"):
            analyze.save_coverage_prompt("  ")

    def test_api_key_mask_exposes_only_last_four_characters(self):
        masked = analyze.mask_api_key("sk-secret-123456")
        self.assertEqual(masked, "••••••••3456")
        self.assertNotIn("secret", masked)

    def test_timeout_validation_accepts_seconds_in_supported_range(self):
        self.assertEqual(analyze.normalize_timeout_seconds("90"), 90)
        with self.assertRaisesRegex(analyze.AnalyzeError, "10~3600"):
            analyze.normalize_timeout_seconds("5")
        with self.assertRaisesRegex(analyze.AnalyzeError, "整数秒"):
            analyze.normalize_timeout_seconds("slow")

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
        ):
            answer = analyze.test_ai_prompt("hello")

        self.assertEqual(answer, "test answer")
        self.assertEqual(call.call_args.kwargs["eff"], effective)
        self.assertEqual(call.call_args.kwargs["max_tokens"], 512)

    def test_analysis_retries_selected_provider_three_times_without_fallback(self):
        effective = {
            "protocol": "openai",
            "base_url": "https://openai.example",
            "api_key": "test-key",
            "model": "grok-4.5",
        }
        logs = []
        with (
            patch("pipeline.analyze._effective", return_value=effective),
            patch(
                "pipeline.analyze._via_openai",
                side_effect=ConnectionError("remote closed"),
            ) as call,
            patch("pipeline.analyze.time.sleep") as sleep,
        ):
            with self.assertRaisesRegex(analyze.AnalyzeError, "连续 3 次调用失败"):
                analyze._run_analysis("system", "user", log=logs.append)

        self.assertEqual(call.call_count, 3)
        self.assertTrue(all(c.kwargs["eff"] is effective for c in call.call_args_list))
        self.assertEqual([c.args[0] for c in sleep.call_args_list], [2, 4])
        self.assertFalse(any("cli" in line.lower() for line in logs))

    def test_analysis_retry_can_succeed_with_same_configuration(self):
        effective = {
            "protocol": "openai",
            "base_url": "https://openai.example",
            "api_key": "test-key",
            "model": "grok-4.5",
        }
        with (
            patch("pipeline.analyze._effective", return_value=effective),
            patch(
                "pipeline.analyze._via_openai",
                side_effect=[ConnectionError("remote closed"), "完成"],
            ) as call,
            patch("pipeline.analyze.time.sleep"),
        ):
            result = analyze._run_analysis("system", "user", log=lambda _message: None)

        self.assertEqual(result, "完成")
        self.assertEqual(call.call_count, 2)
        self.assertTrue(all(c.kwargs["eff"] is effective for c in call.call_args_list))

    def test_custom_prompt_rejects_empty_question(self):
        with self.assertRaisesRegex(analyze.AnalyzeError, "填写测试问题"):
            analyze.test_ai_prompt("  ")

    def test_pasted_performance_report_only_analyzes_current_function(self):
        report = (
            "函数名\tJulia 首次用时 s\tMATLAB 首次用时 s\tsyslab/matlab首次比例\n"
            "activecontour\t0.2\t0.1\t2.0\n"
            "cameraProjection\t9.0\t0.1\t90.0"
        )
        ai_report = (
            "### 用户粘贴的性能报告分析\n\n"
            "#### 综合结论\n\n"
            "**性能结论：性能首次不通过，二次通过**"
        )
        with patch("pipeline.analyze._run_analysis", return_value=ai_report) as call:
            result = analyze.pasted_performance_analysis("activecontour", report)

        self.assertEqual(result, ai_report)
        system, user, _log = call.call_args.args
        self.assertIn("只分析“函数名”与当前任务函数完全一致", system)
        self.assertIn("其他函数即使数据完整也必须忽略", system)
        self.assertIn("报告给出“Julia / MATLAB”", system)
        self.assertIn("只分析这个精确名称", user)
        self.assertIn("cameraProjection", user)

    def test_performance_verdict_parser_accepts_only_four_fixed_states(self):
        allowed = (
            "性能通过",
            "性能首次不通过，二次通过",
            "性能首次通过，二次不通过",
            "性能不通过",
        )
        for verdict in allowed:
            with self.subTest(verdict=verdict):
                self.assertEqual(
                    analyze.performance_verdict_from_markdown(
                        f"#### 综合结论\n\n**性能结论：{verdict}**"
                    ),
                    verdict,
                )
        self.assertIsNone(
            analyze.performance_verdict_from_markdown(
                "**性能结论：大概通过**"
            )
        )
        self.assertEqual(
            analyze.performance_verdict_from_markdown(
                "**性能结论：性能通过（首次通过、二次通过）**"
            ),
            "性能通过",
        )

    def test_pasted_performance_analysis_returns_unstructured_response(self):
        with patch("pipeline.analyze._run_analysis", return_value="综合来看还可以"):
            result = analyze.pasted_performance_analysis(
                "graycomatrix", "原始性能数据"
            )

        self.assertEqual(result, "综合来看还可以")


class AiProfileStoreTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.config_path = Path(self.temp_dir.name) / ".ai-config.json"
        self.config_patch = patch.object(analyze.config, "AI_CONFIG_FILE", self.config_path)
        self.config_patch.start()

    def tearDown(self):
        self.config_patch.stop()
        self.temp_dir.cleanup()

    def test_legacy_config_migrates_without_losing_key(self):
        self.config_path.write_text(json.dumps({
            "protocol": "openai",
            "base_url": "https://legacy.example/v1",
            "api_key": "legacy-secret-key",
            "model": "legacy-model",
        }), encoding="utf-8")

        store = analyze.load_ai_config_store()

        self.assertEqual(store["version"], 2)
        self.assertEqual(store["active_profile_id"], "legacy")
        self.assertEqual(store["profiles"][0]["name"], "现有配置")
        self.assertEqual(store["profiles"][0]["api_key"], "legacy-secret-key")
        saved = json.loads(self.config_path.read_text(encoding="utf-8"))
        self.assertEqual(saved["profiles"][0]["api_key"], "legacy-secret-key")

    def test_profiles_can_be_saved_switched_and_default_does_not_delete_them(self):
        first = analyze.save_ai_profile(
            "", "公益站 A", "https://a.example/v1", "key-a", "model-a", "openai"
        )
        second = analyze.save_ai_profile(
            "", "公益站 B", "https://b.example", "key-b", "model-b", "anthropic"
        )
        self.assertEqual(analyze.load_ai_config()["api_key"], "key-b")

        analyze.activate_ai_profile(first)
        self.assertEqual(analyze.load_ai_config()["model"], "model-a")
        analyze.activate_ai_profile("")

        store = analyze.load_ai_config_store()
        self.assertEqual(store["active_profile_id"], "")
        self.assertEqual({p["id"] for p in store["profiles"]}, {first, second})

    def test_each_profile_keeps_its_own_request_timeout(self):
        first = analyze.save_ai_profile(
            "", "快站", "https://fast.example", "key-a", "model-a", "openai", 60
        )
        second = analyze.save_ai_profile(
            "", "慢站", "https://slow.example", "key-b", "model-b", "openai", 1800
        )
        self.assertEqual(analyze.load_ai_config()["timeout_seconds"], 1800)

        analyze.activate_ai_profile(first)
        self.assertEqual(analyze.resolve_ai_config()["timeout_seconds"], 60)

        store = analyze.load_ai_config_store()
        timeouts = {p["name"]: p["timeout_seconds"] for p in store["profiles"]}
        self.assertEqual(timeouts, {"快站": 60, "慢站": 1800})

    def test_deleting_active_profile_activates_first_remaining_profile(self):
        first = analyze.save_ai_profile(
            "", "公益站 A", "https://a.example", "key-a", "model-a", "openai"
        )
        second = analyze.save_ai_profile(
            "", "公益站 B", "https://b.example", "key-b", "model-b", "openai"
        )

        analyze.delete_ai_profile(second)

        store = analyze.load_ai_config_store()
        self.assertEqual(store["active_profile_id"], first)
        self.assertEqual(len(store["profiles"]), 1)


if __name__ == "__main__":
    unittest.main()
