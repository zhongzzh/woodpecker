import tempfile
import unittest
from pathlib import Path
from unittest.mock import ANY, patch

from pipeline import doc_html


DOC_REL = (
    "syslabHelpSourceCode/projects/TyStatistics/Doc/TyStatistics/"
    "DescripitiveStatisticsandVisualization/DescriptiveStatistics/"
    "TabulationandGroupData/tdfread.md"
)


class DocHtmlTests(unittest.TestCase):
    def test_project_comes_from_actual_document_path(self):
        project, source = doc_html.project_and_source_path(DOC_REL)
        self.assertEqual(project, "TyStatistics")
        self.assertEqual(source.name, "tdfread.md")

    def test_expected_output_keeps_project_relative_structure(self):
        root = Path(r"C:\docs\syslab-docs-2.0")
        project, html = doc_html.expected_html_path(root, DOC_REL)
        self.assertEqual(project, "TyStatistics")
        self.assertEqual(html.name, "tdfread.html")
        self.assertIn(str(Path("dist") / "Help" / "TyStatistics"), str(html))

    def test_build_and_open_uses_compiled_function_html(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _project, html = doc_html.expected_html_path(root, DOC_REL)
            html.parent.mkdir(parents=True)
            html.write_text("<html></html>", encoding="utf-8")
            index = (
                root / "syslabHelpSourceCode" / "dist" / "Help"
                / "TyStatistics" / "index.html"
            )
            index.write_text("<html></html>", encoding="utf-8")

            with (
                patch("pipeline.doc_html._run_build") as build,
                patch("pipeline.doc_html.webbrowser.open", return_value=True) as open_browser,
            ):
                result = doc_html.build_and_open(
                    root, DOC_REL, "tdfread", log=lambda _message: None
                )

            build.assert_called_once_with(
                root / "syslabHelpSourceCode", "TyStatistics",
                log=ANY,
            )
            expected_url = (
                f"{index.resolve().as_uri()}#/Doc/TyStatistics/"
                "DescripitiveStatisticsandVisualization/DescriptiveStatistics/"
                "TabulationandGroupData/tdfread.html#%E8%AF%AD%E6%B3%95"
            )
            open_browser.assert_called_once_with(expected_url, new=2)
            self.assertEqual(result["project"], "TyStatistics")
            self.assertEqual(result["html"], str(html))
            self.assertEqual(result["url"], expected_url)


if __name__ == "__main__":
    unittest.main()
