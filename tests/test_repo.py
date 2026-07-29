import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from pipeline import config, repo


class EnsureRepoTests(unittest.TestCase):
    def test_default_reuses_repository_from_shared_clone_root(self):
        with tempfile.TemporaryDirectory() as tmp:
            shared_root = Path(tmp) / "Desktop" / "doc"
            existing = shared_root / "TyStatisticsCore.jl"
            (existing / ".git").mkdir(parents=True)

            with (
                patch.object(config, "CLONE_ROOT", shared_root),
                patch("pipeline.repo._git") as git,
            ):
                actual = repo.ensure_repo(
                    "syslab/packages/math/TyStatisticsCore.jl",
                    log=lambda _message: None,
                )

            self.assertEqual(actual, existing)
            git.assert_not_called()

    def test_reuses_explicit_existing_repository(self):
        with tempfile.TemporaryDirectory() as tmp:
            existing = Path(tmp) / "Desktop" / "doc" / "syslab-docs-2.0"
            (existing / ".git").mkdir(parents=True)
            messages = []

            with patch("pipeline.repo._git") as git:
                actual = repo.ensure_repo(
                    "syslab/syslab-docs-2.0",
                    log=messages.append,
                    local_path=existing,
                )

            self.assertEqual(actual, existing)
            git.assert_not_called()
            self.assertEqual(messages, [f"  仓库已存在: {existing}"])

    def test_clones_missing_repository_into_explicit_path(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "Desktop" / "doc" / "syslab-docs-2.0"

            with patch("pipeline.repo._git") as git:
                actual = repo.ensure_repo(
                    "syslab/syslab-docs-2.0",
                    log=lambda _message: None,
                    local_path=target,
                )

            self.assertEqual(actual, target)
            self.assertTrue(target.parent.is_dir())
            git.assert_called_once_with(
                None,
                "clone",
                repo.ssh_url("syslab/syslab-docs-2.0"),
                str(target),
            )


if __name__ == "__main__":
    unittest.main()
