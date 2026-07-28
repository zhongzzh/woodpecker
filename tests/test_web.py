import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import MagicMock, patch

from pipeline import analyze
from pipeline.taskcard import TaskCard
from pipeline.web import (
    _build_argv,
    _coverage_prompt_payload,
    _hidden_process_kwargs,
    _profile_api_key,
    _public_ai_config,
    _resolve_local_materials,
    _select_local_file,
    _service_is_running,
)


class WebArgvTests(unittest.TestCase):
    def test_analysis_process_is_hidden_on_windows(self):
        with patch("pipeline.web.sys.platform", "win32"):
            kwargs = _hidden_process_kwargs()
        self.assertIn("creationflags", kwargs)

    def test_coverage_prompt_payload_exposes_content_and_source(self):
        with (
            patch("pipeline.web.analyze.load_coverage_prompt", return_value="规则正文"),
            patch("pipeline.web.analyze.coverage_prompt_is_customized", return_value=True),
        ):
            payload = _coverage_prompt_payload()
        self.assertEqual(payload, {
            "prompt": "规则正文", "customized": True, "characters": 4,
        })

    @patch("pipeline.web.socket.create_connection")
    def test_existing_service_is_detected_before_binding(self, connect):
        connection = MagicMock()
        connect.return_value.__enter__.return_value = connection
        self.assertTrue(_service_is_running())
        connect.assert_called_once()

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

    def test_local_task_emits_only_local_material_arguments(self):
        argv = _build_argv({
            "input_mode": "local",
            "name": "检查本地材料",
            "local_code": r"C:\materials\sample.jl",
            "local_doc": r"C:\materials\sample.md",
            "perf_report_file": r"C:\Temp\performance.txt",
        })
        self.assertIn("--local-code", argv)
        self.assertIn("--local-doc", argv)
        self.assertIn("--perf-report-file", argv)
        self.assertNotIn("--code-mr", argv)
        self.assertNotIn("--doc-mr", argv)

    def test_local_task_accepts_separate_material_roots(self):
        argv = _build_argv({
            "input_mode": "local",
            "name": "chromadapt函数",
            "local_code": r"C:\code",
            "local_doc": r"C:\docs",
        })
        self.assertIn("--local-code", argv)
        self.assertIn("--local-doc", argv)
        self.assertEqual(argv[argv.index("--local-code") + 1], r"C:\code")
        self.assertEqual(argv[argv.index("--local-doc") + 1], r"C:\docs")


class LocalPickerTests(unittest.TestCase):
    def test_code_and_doc_directory_kinds_open_directory_picker(self):
        root = MagicMock()
        with (
            patch("tkinter.Tk", return_value=root),
            patch(
                "tkinter.filedialog.askdirectory",
                side_effect=[r"C:\code", r"C:\docs"],
            ) as choose,
        ):
            code = _select_local_file("code_dir")
            doc = _select_local_file("doc_dir")

        self.assertEqual(code, r"C:\code")
        self.assertEqual(doc, r"C:\docs")
        self.assertIn("代码/单测母目录", choose.call_args_list[0].kwargs["title"])
        self.assertIn("函数文档母目录", choose.call_args_list[1].kwargs["title"])


class LocalMaterialResolutionTests(unittest.TestCase):
    def test_parent_directories_return_preferred_paths_and_all_matches(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            code = root / "code"
            docs = root / "docs"
            (code / "test").mkdir(parents=True)
            (code / "src").mkdir()
            docs.mkdir()
            main = code / "test" / "test_chromadapt.jl"
            source = code / "src" / "chromadapt.jl"
            primary_doc = docs / "chromadapt.md"
            extra_doc = docs / "chromadapt_notes.md"
            for path in (main, source, primary_doc, extra_doc):
                path.write_text("content", encoding="utf-8")
            card = TaskCard(
                name="chromadapt函数",
                input_mode="local",
                local_code=str(code),
                local_doc=str(docs),
            )

            resolved = _resolve_local_materials(card)

        self.assertEqual(resolved["local_code"], str(main))
        self.assertEqual(resolved["local_doc"], str(primary_doc))
        self.assertEqual(
            set(resolved["local_code_files"]), {str(main), str(source)}
        )
        self.assertEqual(
            set(resolved["local_doc_files"]), {str(primary_doc), str(extra_doc)}
        )


class AiConfigWebTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.config_path = Path(self.temp_dir.name) / ".ai-config.json"
        self.config_patch = patch.object(analyze.config, "AI_CONFIG_FILE", self.config_path)
        self.config_patch.start()

    def tearDown(self):
        self.config_patch.stop()
        self.temp_dir.cleanup()

    def test_public_config_masks_keys_in_every_profile(self):
        profile_id = analyze.save_ai_profile(
            "", "公益站 A", "https://a.example", "super-secret-key", "model-a", "openai"
        )

        public = _public_ai_config()
        encoded = json.dumps(public, ensure_ascii=False)

        self.assertEqual(public["active_profile_id"], profile_id)
        self.assertTrue(public["profiles"][0]["has_saved_key"])
        self.assertEqual(public["profiles"][0]["api_key_masked"], "••••••••-key")
        self.assertNotIn("super-secret-key", encoded)
        self.assertNotIn("api_key\"", json.dumps(public["profiles"][0]))

    def test_model_and_prompt_requests_can_reuse_selected_profile_key(self):
        profile_id = analyze.save_ai_profile(
            "", "公益站 A", "https://a.example", "saved-key", "model-a", "openai"
        )
        self.assertEqual(_profile_api_key({"profile_id": profile_id}), "saved-key")
        self.assertEqual(
            _profile_api_key({"profile_id": profile_id, "api_key": "replacement"}),
            "replacement",
        )


if __name__ == "__main__":
    unittest.main()
