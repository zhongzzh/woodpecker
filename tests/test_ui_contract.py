from html.parser import HTMLParser
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "pipeline" / "static" / "index.html"


class _ElementIndex(HTMLParser):
    def __init__(self):
        super().__init__()
        self.by_id = {}

    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        if values.get("id"):
            self.by_id[values["id"]] = {"tag": tag, **values}


class CodeChatUiContractTests(unittest.TestCase):
    def test_pasted_submission_fills_extracted_function_name(self):
        self.assertIn('$("func").value=data.func||""', self.html)

    @classmethod
    def setUpClass(cls):
        cls.html = INDEX.read_text(encoding="utf-8")
        cls.elements = _ElementIndex()
        cls.elements.feed(cls.html)

    def test_composer_uses_single_line_semantic_input_and_icon_submit(self):
        input_attrs = self.elements.by_id["codeChatInput"]
        send_attrs = self.elements.by_id["sendCodeChat"]

        self.assertEqual(input_attrs["tag"], "textarea")
        self.assertEqual(input_attrs["rows"], "1")
        self.assertEqual(input_attrs["enterkeyhint"], "send")
        self.assertEqual(input_attrs["aria-keyshortcuts"], "Enter")
        self.assertEqual(send_attrs["tag"], "button")
        self.assertEqual(send_attrs["type"], "submit")
        self.assertIn("chat-send", send_attrs["class"].split())
        self.assertIn("disabled", send_attrs)

    def test_composer_keeps_send_button_stable_and_input_self_sizing(self):
        self.assertIn(".chat-send { width:36px; height:36px", self.html)
        self.assertIn("function resizeCodeChatInput()", self.html)
        self.assertIn('input.style.height="auto"', self.html)
        self.assertIn('!$("codeChatInput").value.trim()', self.html)

    def test_enter_send_is_safe_for_shift_newlines_and_chinese_ime(self):
        self.assertIn(
            'e.key==="Enter"&&!e.shiftKey&&!e.isComposing&&e.keyCode!==229',
            self.html,
        )
        self.assertIn('$("codeChatForm").requestSubmit()', self.html)

    def test_gitlab_host_and_ssh_port_share_the_same_grid_alignment(self):
        self.assertIn(
            ".gitlab-grid > .field { display:grid; gap:7px; margin-top:0; }",
            self.html,
        )

    def test_failed_progress_steps_use_a_red_cross(self):
        self.assertIn(".step.failed { color:var(--danger); }", self.html)
        self.assertIn('dot.innerHTML=isFailed?"&times;"', self.html)
        self.assertIn('updateSteps(step||1,false,[step||1])', self.html)

    def test_partial_completion_does_not_show_a_redundant_message(self):
        self.assertNotIn("报告已生成，但标红步骤未完成", self.html)
        self.assertIn("progress.hidden=!message", self.html)

    def test_new_ai_profile_defaults_to_openai_protocol(self):
        self.assertIn('const protocol="openai"', self.html)

    def test_document_only_refresh_is_explicitly_scoped(self):
        checkbox = self.elements.by_id["refresh_doc_only"]

        self.assertEqual(checkbox["tag"], "input")
        self.assertEqual(checkbox["type"], "checkbox")
        self.assertIn(
            "以远端文档为准，放弃本地冲突和已跟踪改动；不读取代码，不执行 AI 分析",
            self.html,
        )
        self.assertIn("refresh_doc_only:docOnly", self.html)
        self.assertIn('s.job_mode==="refresh_doc_only"', self.html)


if __name__ == "__main__":
    unittest.main()
