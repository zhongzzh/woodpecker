import unittest
from pathlib import Path
from unittest.mock import patch

from pipeline import locate


class ExistingDocLocateTests(unittest.TestCase):
    def test_math_doc_wins_over_multilanguage_duplicate(self):
        paths = [
            "syslabHelpSourceCode/projects/MultiLanguage/Doc/MultiLanguage/ode89.md",
            "syslabHelpSourceCode/projects/TyMath/Doc/TyMath/DifferentialEquations/ode89.md",
        ]
        with (
            patch("pipeline.locate.repo_mod.files_at_revision", return_value=paths),
            patch("pipeline.locate.repo_mod.read_text_at_revision", return_value="# ode89") as read,
        ):
            result = locate.read_existing_doc_md(
                Path("unused"), "ode89", "origin/develop", log=lambda _msg: None
            )
        self.assertIn("projects/TyMath/Doc/", result["relative_path"])
        read.assert_called_once_with(
            Path("unused"), "origin/develop",
            "syslabHelpSourceCode/projects/TyMath/Doc/TyMath/DifferentialEquations/ode89.md",
        )


if __name__ == "__main__":
    unittest.main()
