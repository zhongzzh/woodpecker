import tempfile
import unittest
from subprocess import CompletedProcess
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


class PrepareBranchTests(unittest.TestCase):
    def test_missing_branch_does_not_stash_dirty_worktree(self):
        calls = []

        def fake_git(_repo, *args, check=True):
            calls.append(args)
            returncode = 1 if args[0] == "show-ref" else 0
            return CompletedProcess(["git", *args], returncode, "", "")

        with patch("pipeline.repo._git", side_effect=fake_git):
            with self.assertRaisesRegex(
                repo.GitError, "本地和 origin 均不存在该分支"
            ):
                repo.prepare_branch(
                    Path("example"), "lzq/add_cmunique",
                    log=lambda _message: None,
                )

        self.assertFalse(any(args[0] == "stash" for args in calls))
        self.assertFalse(any(args[0] == "checkout" for args in calls))

    def test_checkout_blocked_by_changes_stashes_and_retries(self):
        calls = []
        checkout_count = 0

        def fake_git(_repo, *args, check=True):
            nonlocal checkout_count
            calls.append(args)
            if args[0] == "show-ref":
                returncode = 0 if args[-1].startswith("refs/heads/") else 1
                return CompletedProcess(["git", *args], returncode, "", "")
            if args[:2] == ("status", "--porcelain"):
                return CompletedProcess(["git", *args], 0, " M local.md\n", "")
            if args[0] == "checkout":
                checkout_count += 1
                if checkout_count == 1:
                    return CompletedProcess(
                        ["git", *args], 1, "",
                        "Your local changes would be overwritten by checkout. "
                        "Please commit your changes or stash them before you "
                        "switch branches.",
                    )
            if args[0] == "log":
                return CompletedProcess(["git", *args], 0, "abc123 test\n", "")
            return CompletedProcess(["git", *args], 0, "", "")

        with patch("pipeline.repo._git", side_effect=fake_git):
            result = repo.prepare_branch(
                Path("example"), "existing", log=lambda _message: None
            )

        self.assertTrue(result["stashed"])
        self.assertEqual(checkout_count, 2)
        self.assertTrue(any(args[0] == "stash" for args in calls))


if __name__ == "__main__":
    unittest.main()
