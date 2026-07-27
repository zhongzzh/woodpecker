import unittest
import tempfile
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


class LocalMaterialLocateTests(unittest.TestCase):
    def test_file_mode_collects_companion_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            main = root / "sample.jl"
            companion = root / "sample_data_1.jl"
            main.write_text("include(\"sample_data_1.jl\")", encoding="utf-8")
            companion.write_text("values = [1]", encoding="utf-8")

            result = locate.find_local_unit_test(
                str(main), "sample", log=lambda _message: None
            )

        self.assertEqual(result["main"], main)
        self.assertEqual(result["companions"], [companion])
        self.assertEqual(result["root"], root)

    def test_directory_mode_prefers_test_tree(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            test_file = root / "test" / "unit" / "sample.jl"
            source_file = root / "src" / "sample.jl"
            test_file.parent.mkdir(parents=True)
            source_file.parent.mkdir(parents=True)
            test_file.write_text("@test true", encoding="utf-8")
            source_file.write_text("sample() = 1", encoding="utf-8")

            result = locate.find_local_unit_test(
                str(root), "sample", log=lambda _message: None
            )

        self.assertEqual(result["main"], test_file)


if __name__ == "__main__":
    unittest.main()
