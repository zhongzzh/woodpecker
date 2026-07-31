import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import MagicMock, patch

from pipeline import analyze, config
from pipeline.taskcard import TaskCard
from pipeline.web import (
    _Job,
    _build_argv,
    _calculate_runtime_version,
    _coverage_prompt_payload,
    _apply_gitlab_action,
    _hidden_process_kwargs,
    _list_tasks,
    _profile_api_key,
    _public_ai_config,
    _public_gitlab_config,
    _read_index_html,
    _read_failed_steps,
    _resolve_local_materials,
    _read_resolved_paths,
    _select_local_file,
    _service_is_running,
    _should_reuse_running_service,
)


class WebArgvTests(unittest.TestCase):
    def test_failed_steps_are_read_from_completed_task_metadata(self):
        with tempfile.TemporaryDirectory() as tmp:
            task = Path(tmp) / "task.json"
            task.write_text(json.dumps({
                "coverage_ai_status": "failed",
                "performance_ai_status": "unparsed",
            }), encoding="utf-8")

            self.assertEqual(_read_failed_steps(tmp), [3, 4])

    def test_skipped_ai_steps_are_not_reported_as_failures(self):
        with tempfile.TemporaryDirectory() as tmp:
            task = Path(tmp) / "task.json"
            task.write_text(json.dumps({
                "coverage_ai_status": "skipped",
                "performance_ai_status": "not_requested",
            }), encoding="utf-8")

            self.assertEqual(_read_failed_steps(tmp), [])

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

    def test_index_html_is_reloaded_instead_of_cached_at_process_start(self):
        with tempfile.TemporaryDirectory() as tmp:
            static_dir = Path(tmp)
            index = static_dir / "index.html"
            with patch("pipeline.web.STATIC_DIR", static_dir):
                index.write_bytes(b"first")
                self.assertEqual(_read_index_html(), b"first")
                index.write_bytes(b"second")
                self.assertEqual(_read_index_html(), b"second")

    def test_runtime_version_changes_with_source_content(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "web.py"
            source.write_text("first", encoding="utf-8")
            first = _calculate_runtime_version(root)
            source.write_text("second", encoding="utf-8")
            second = _calculate_runtime_version(root)

        self.assertNotEqual(first, second)

    @patch("pipeline.web._service_runtime_info")
    def test_same_runtime_version_reuses_existing_service(self, runtime_info):
        from pipeline import web

        runtime_info.return_value = {
            "service": "woodpecker",
            "version": web.RUNTIME_VERSION,
            "project_root": str(config.PROJECT_ROOT.resolve()),
            "running": False,
        }
        with patch("pipeline.web._request_service_shutdown") as shutdown:
            self.assertTrue(_should_reuse_running_service())
        shutdown.assert_not_called()

    @patch("pipeline.web._wait_for_service_exit", return_value=True)
    @patch("pipeline.web._request_service_shutdown", return_value=True)
    @patch("pipeline.web._service_runtime_info")
    def test_idle_stale_service_is_replaced(self, runtime_info, shutdown, wait):
        runtime_info.return_value = {
            "service": "woodpecker",
            "version": "stale-version",
            "project_root": str(config.PROJECT_ROOT.resolve()),
            "running": False,
        }

        self.assertFalse(_should_reuse_running_service())

        shutdown.assert_called_once_with()
        wait.assert_called_once_with()

    @patch("pipeline.web._service_runtime_info")
    def test_running_stale_service_is_preserved(self, runtime_info):
        runtime_info.return_value = {
            "service": "woodpecker",
            "version": "stale-version",
            "project_root": str(config.PROJECT_ROOT.resolve()),
            "running": True,
        }
        with patch("pipeline.web._request_service_shutdown") as shutdown:
            self.assertTrue(
                _should_reuse_running_service(log=lambda _message: None)
            )
        shutdown.assert_not_called()

    @patch("pipeline.web._wait_for_service_exit", return_value=True)
    @patch("pipeline.web._stop_legacy_service", return_value=True)
    @patch("pipeline.web._legacy_service_status")
    @patch("pipeline.web._service_runtime_info", return_value=None)
    def test_idle_legacy_service_without_version_api_is_replaced(
        self, _runtime_info, legacy_status, stop_legacy, wait
    ):
        legacy_status.return_value = {
            "running": False, "stopped": False, "log": [], "error": None,
            "report_dir": None,
        }

        self.assertFalse(_should_reuse_running_service())

        stop_legacy.assert_called_once_with()
        wait.assert_called_once_with()

    @patch("pipeline.web._legacy_service_status")
    @patch("pipeline.web._service_runtime_info", return_value=None)
    def test_running_legacy_service_without_version_api_is_preserved(
        self, _runtime_info, legacy_status
    ):
        legacy_status.return_value = {
            "running": True, "stopped": False, "log": ["分析中"],
            "error": None, "report_dir": None,
        }
        with patch("pipeline.web._stop_legacy_service") as stop_legacy:
            self.assertTrue(
                _should_reuse_running_service(log=lambda _message: None)
            )
        stop_legacy.assert_not_called()

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

    def test_document_html_build_is_opt_in(self):
        payload = {
            "name": "新增 ode89 函数",
            "code_mr": "https://git.tongyuan.cc/a/b/-/merge_requests/1",
            "doc_mr": "https://git.tongyuan.cc/a/docs/-/merge_requests/2",
        }
        self.assertNotIn("--build-doc-html", _build_argv(payload))
        self.assertIn(
            "--build-doc-html",
            _build_argv({**payload, "build_doc_html": True}),
        )

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
            "local_library": "TyImageProcessing",
            "local_code": r"C:\code",
            "local_doc": r"C:\docs",
        })
        self.assertIn("--local-code", argv)
        self.assertIn("--local-doc", argv)
        self.assertEqual(argv[argv.index("--local-code") + 1], r"C:\code")
        self.assertEqual(argv[argv.index("--local-doc") + 1], r"C:\docs")
        self.assertEqual(
            argv[argv.index("--local-library") + 1], "TyImageProcessing"
        )

    def test_local_repository_task_emits_library_and_shared_branch(self):
        argv = _build_argv({
            "input_mode": "local",
            "name": "graydiffweight",
            "local_library": "TyImageProcessing",
            "local_branch": "pyh/add_graydiffweight",
        })
        self.assertIn("--local-library", argv)
        self.assertIn("--local-branch", argv)
        self.assertNotIn("--local-code", argv)
        self.assertEqual(
            argv[argv.index("--local-branch") + 1], "pyh/add_graydiffweight"
        )

    def test_local_repository_task_can_request_document_html_build(self):
        argv = _build_argv({
            "input_mode": "local",
            "name": "graydiffweight",
            "local_library": "TyImageProcessing",
            "local_branch": "pyh/add_graydiffweight",
            "build_doc_html": True,
        })
        self.assertIn("--build-doc-html", argv)


class TaskHistoryTests(unittest.TestCase):
    def test_reports_are_sorted_by_generation_time_instead_of_function_name(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            older = root / "zeta-20260730-090000"
            newer = root / "alpha-20260730-100000"
            older.mkdir()
            newer.mkdir()
            older_report = older / "分析报告.md"
            newer_report = newer / "分析报告.md"
            older_report.write_text("older", encoding="utf-8")
            newer_report.write_text("newer", encoding="utf-8")
            os.utime(older_report, (1_700_000_000, 1_700_000_000))
            os.utime(newer_report, (1_700_000_100, 1_700_000_100))

            with patch.object(config, "TASKS_DIR", root):
                items = _list_tasks()

        self.assertEqual(
            [item["dir"] for item in items],
            ["alpha-20260730-100000", "zeta-20260730-090000"],
        )


class GitLabConfigWebTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        root = Path(self.temp_dir.name)
        self.config_patch = patch.object(config, "GITLAB_CONFIG_FILE", root / "gitlab.json")
        self.state_patch = patch.object(config, "PW_STATE_FILE", root / "state.json")
        self.config_patch.start()
        self.state_patch.start()

    def tearDown(self):
        self.state_patch.stop()
        self.config_patch.stop()
        self.temp_dir.cleanup()

    def test_public_config_reports_login_state_without_exposing_state_content(self):
        config.PW_STATE_FILE.write_text('{"cookies": []}', encoding="utf-8")
        result = _public_gitlab_config()
        self.assertTrue(result["login_state_exists"])
        self.assertNotIn("cookies", result)

    def test_test_action_saves_settings_and_checks_browser_connection(self):
        with patch("pipeline.web.login.check_connection", return_value={
            "url": "https://git.example.com/users/sign_in", "status": 200,
        }) as check:
            result = _apply_gitlab_action({
                "action": "test", "host": "git.example.com",
                "ssh_port": "222", "proxy": "127.0.0.1:7890",
            })
        self.assertIn("连接成功", result["message"])
        check.assert_called_once_with("git.example.com", "http://127.0.0.1:7890")

    def test_login_action_opens_login_and_refreshes_state_status(self):
        def fake_login(_host, _proxy):
            config.PW_STATE_FILE.write_text("{}", encoding="utf-8")

        with patch("pipeline.web.login.login_gitlab", side_effect=fake_login) as log_in:
            result = _apply_gitlab_action({
                "action": "login", "host": "git.example.com",
                "ssh_port": 222, "proxy": "",
            })
        self.assertTrue(result["login_state_exists"])
        log_in.assert_called_once_with("git.example.com", None)

class LocalPickerTests(unittest.TestCase):
    def test_code_and_doc_directory_kinds_open_directory_picker(self):
        root = MagicMock()
        with (
            patch("pipeline.web.enable_high_dpi") as enable_dpi,
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
        self.assertEqual(enable_dpi.call_count, 2)
        self.assertIn("代码/单测母目录", choose.call_args_list[0].kwargs["title"])
        self.assertIn("函数文档母目录", choose.call_args_list[1].kwargs["title"])


class LocalMaterialResolutionTests(unittest.TestCase):
    def test_job_status_reads_early_repository_material_paths(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            task_dir = root / "graydiffweight-task"
            task_dir.mkdir()
            value = {
                "local_code": r"C:\code\test_graydiffweight.jl",
                "local_doc": r"C:\docs\graydiffweight.md",
                "local_code_files": [r"C:\code\test_graydiffweight.jl"],
                "local_doc_files": [r"C:\docs\graydiffweight.md"],
            }
            (task_dir / config.LOCAL_PATHS_STATE_NAME).write_text(
                json.dumps(value), encoding="utf-8"
            )
            job = _Job()
            job.out_dir = str(task_dir)
            with patch.object(config, "TASKS_DIR", root):
                snapshot = job.snapshot()

        self.assertEqual(snapshot["resolved_paths"], value)

    def test_resolved_paths_fall_back_to_finished_task_metadata(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            task_dir = root / "graydiffweight-task"
            task_dir.mkdir()
            (task_dir / "task.json").write_text(json.dumps({
                "local_code": r"C:\code\test_graydiffweight.jl",
                "local_doc": r"C:\docs\graydiffweight.md",
                "local_code_files": [],
                "local_doc_files": [],
            }), encoding="utf-8")
            with patch.object(config, "TASKS_DIR", root):
                resolved = _read_resolved_paths(str(task_dir))

        self.assertEqual(resolved["local_doc"], r"C:\docs\graydiffweight.md")

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
        self.assertEqual(public["profiles"][0]["timeout_seconds"], 1200)
        self.assertNotIn("super-secret-key", encoded)
        self.assertNotIn("api_key\"", json.dumps(public["profiles"][0]))

    def test_public_config_exposes_each_profile_timeout(self):
        analyze.save_ai_profile(
            "", "慢速公益站", "https://slow.example", "saved-key", "model-a",
            "openai", 1800,
        )
        public = _public_ai_config()
        self.assertEqual(public["timeout_seconds"], 1800)
        self.assertEqual(public["profiles"][0]["timeout_seconds"], 1800)

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
