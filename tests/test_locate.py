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


class RepositoryUnitTestLocateTests(unittest.TestCase):
    @staticmethod
    def _performance_note(func, path):
        return {
            "tables": [{
                "title": "分支版本详细数据",
                "headers": ["func_name", "git_file"],
                "rows": [[func, path]],
            }],
        }

    def test_performance_path_selects_matching_duplicate_function(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            expected = repo / "test" / "BoundaryArea" / "area.jl"
            other = (
                repo / "test" / "ElementaryPolygons" / "polyshape" / "area.jl"
            )
            for path in (expected, other):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("@test true", encoding="utf-8")
            note = self._performance_note(
                "area",
                "benchmark/BoundaryArea/area/PerformanceTest/PerformanceTest1",
            )

            result = locate.find_unit_test(
                repo, "area", log=lambda _message: None, perf_note=note
            )

        self.assertEqual(result["main"], expected)

    def test_unrelated_performance_path_keeps_duplicate_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            for relative in (
                "test/BoundaryArea/area.jl",
                "test/ElementaryPolygons/polyshape/area.jl",
            ):
                path = repo / Path(relative)
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("@test true", encoding="utf-8")
            note = self._performance_note(
                "area", "benchmark/UnknownCategory/area/PerformanceTest/Test1"
            )

            with self.assertRaisesRegex(
                locate.LocateError, "性能报告路径也无法唯一确定"
            ):
                locate.find_unit_test(
                    repo, "area", log=lambda _message: None, perf_note=note
                )


class LocalMaterialLocateTests(unittest.TestCase):
    def test_library_name_resolves_dot_jl_repository(self):
        with tempfile.TemporaryDirectory() as tmp:
            repository = Path(tmp) / "TyImageProcessing.jl"
            (repository / ".git").mkdir(parents=True)

            result = locate.find_local_library_repo("TyImageProcessing", Path(tmp))

        self.assertEqual(result, repository)

    def test_library_name_uses_configured_repository_root(self):
        with tempfile.TemporaryDirectory() as tmp:
            repository = Path(tmp) / "TyImageProcessing.jl"
            (repository / ".git").mkdir(parents=True)
            with patch.object(locate.config, "CLONE_ROOT", Path(tmp)):
                result = locate.find_local_library_repo("TyImageProcessing")

        self.assertEqual(result, repository)

    def test_library_name_cannot_escape_repository_root(self):
        with self.assertRaisesRegex(locate.LocateError, "格式不正确"):
            locate.find_local_library_repo("../elsewhere", Path("unused"))

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

    def test_directory_mode_collects_all_names_containing_function(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            test_file = root / "code" / "test" / "test_chromadapt.jl"
            source_file = root / "code" / "src" / "chromadapt_impl.jl"
            unrelated = root / "code" / "test" / "test_adapt.jl"
            for path in (test_file, source_file, unrelated):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("# material", encoding="utf-8")

            result = locate.find_local_unit_test(
                str(root), "chromadapt", log=lambda _message: None
            )

        self.assertEqual(result["main"], test_file)
        self.assertEqual(result["companions"], [source_file])

    def test_directory_mode_finds_only_exactly_named_doc(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            exact = root / "docs" / "chromadapt.md"
            extra = root / "notes" / "chromadapt_examples.md"
            unrelated = root / "docs" / "adapt.md"
            for path in (exact, extra, unrelated):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("# doc", encoding="utf-8")

            result = locate.find_local_docs(
                str(root), "chromadapt", log=lambda _message: None
            )

        self.assertEqual(result, [exact])

    def test_directory_mode_does_not_match_function_as_filename_substring(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            false_match = root / "nrPBCHDMRSIndices.md"
            false_match.write_text("# unrelated", encoding="utf-8")

            with self.assertRaisesRegex(
                locate.LocateError, "严格等于完整函数名 'dice'.*\\.md"
            ):
                locate.find_local_docs(
                    str(root), "dice", log=lambda _message: None
                )

    def test_directory_mode_accepts_case_variant_of_exact_doc_name(self):
        with tempfile.TemporaryDirectory() as tmp:
            doc = Path(tmp) / "Dice.md"
            doc.write_text("# dice", encoding="utf-8")

            result = locate.find_local_docs(
                tmp, "dice", log=lambda _message: None
            )

        self.assertEqual(result, [doc])

    def test_repository_docs_prefer_matching_help_project(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            preferred = (
                root / "syslabHelpSourceCode" / "projects" / "TyImageProcessing"
                / "Doc" / "cmunique.md"
            )
            other = (
                root / "syslabHelpSourceCode" / "projects" / "TyImages"
                / "Doc" / "cmunique.md"
            )
            for path in (preferred, other):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("# cmunique", encoding="utf-8")

            result = locate.find_local_docs(
                str(root), "cmunique", log=lambda _message: None,
                preferred_project="TyImageProcessing.jl",
            )

        self.assertEqual(result, [preferred])

    def test_document_search_ignores_generated_cache_copies(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = (
                root / "syslabHelpSourceCode" / "projects" / "TyImageProcessing"
                / "Doc" / "writeVideo.md"
            )
            cached = (
                root / "syslabHelpSourceCode" / ".cache" / "docs-build" / "staging"
                / "TyImageProcessing-build" / "Doc" / "writeVideo.md"
            )
            for path in (source, cached):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("# writeVideo", encoding="utf-8")

            docs = locate.find_local_docs(
                str(root), "writeVideo", log=lambda _message: None
            )
            named_doc = locate.find_local_named_doc(
                str(root), "writeVideo", log=lambda _message: None
            )

        self.assertEqual(docs, [source])
        self.assertEqual(named_doc, source)

    def test_directory_mode_reports_missing_function_material(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaisesRegex(locate.LocateError, "完整函数名 'chromadapt'"):
                locate.find_local_unit_test(
                    tmp, "chromadapt", log=lambda _message: None
                )

    def test_directory_mode_reports_missing_function_doc(self):
        with tempfile.TemporaryDirectory() as tmp:
            code = Path(tmp) / "test_chromadapt.jl"
            code.write_text("@test true", encoding="utf-8")
            with self.assertRaisesRegex(
                locate.LocateError, "完整函数名 'chromadapt'.*\\.md"
            ):
                locate.find_local_docs(tmp, "chromadapt", log=lambda _message: None)


if __name__ == "__main__":
    unittest.main()
