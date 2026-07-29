import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from pipeline import config, login, repo


class GitLabConfigTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.config_file = Path(self.tempdir.name) / ".gitlab-config.json"
        self.file_patch = patch.object(config, "GITLAB_CONFIG_FILE", self.config_file)
        self.file_patch.start()

    def tearDown(self):
        self.file_patch.stop()
        self.tempdir.cleanup()

    def test_save_and_load_local_gitlab_config(self):
        saved = config.save_gitlab_config(
            "https://git.example.com/", "2222", "127.0.0.1:7890"
        )
        self.assertEqual("git.example.com", saved["host"])
        self.assertEqual(2222, saved["ssh_port"])
        self.assertEqual("http://127.0.0.1:7890", saved["proxy"])
        self.assertEqual(saved, config.load_gitlab_config())

    def test_invalid_proxy_is_rejected(self):
        with self.assertRaisesRegex(config.GitLabConfigError, "代理格式"):
            config.save_gitlab_config("git.example.com", 222, "not a proxy")

    def test_repo_url_uses_saved_host_and_port(self):
        config.save_gitlab_config("git.example.com", 2200, "")
        self.assertEqual(
            "ssh://git@git.example.com:2200/group/project.git",
            repo.ssh_url("group/project"),
        )

    def test_connection_closed_error_is_friendly(self):
        message = login._friendly_error(
            Exception("Page.goto: net::ERR_CONNECTION_CLOSED"),
            "git.example.com",
            None,
        )
        self.assertIn("连接被关闭", message)
        self.assertIn("VPN/代理", message)

    def test_authenticated_url_requires_return_to_gitlab_host(self):
        self.assertTrue(login._is_authenticated_url(
            "https://git.example.com/dashboard/projects", "git.example.com"
        ))
        self.assertFalse(login._is_authenticated_url(
            "https://git.example.com/users/sign_in", "git.example.com"
        ))
        self.assertFalse(login._is_authenticated_url(
            "https://sso.example.com/login", "git.example.com"
        ))


if __name__ == "__main__":
    unittest.main()
