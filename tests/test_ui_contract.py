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


if __name__ == "__main__":
    unittest.main()
