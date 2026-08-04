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
                patch("pipeline.doc_html._open_preview_url", return_value=True) as open_browser,
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
            open_browser.assert_called_once_with(expected_url)
            self.assertEqual(result["project"], "TyStatistics")
            self.assertEqual(result["html"], str(html))
            self.assertEqual(result["url"], expected_url)

    def test_windows_browser_command_receives_complete_hash_route(self):
        url = (
            "file:///C:/docs/TyMath/index.html#/Doc/TyMath/"
            "ElementaryPolygons/nsidedpoly.html#%E8%AF%AD%E6%B3%95"
        )
        command = (
            r'"C:\Program Files\Google\Chrome\Application\chrome.exe" '
            r'--single-argument %1'
        )
        with (
            patch(
                "pipeline.doc_html._registered_default_browser_command",
                return_value=command,
            ),
            patch("pipeline.doc_html.subprocess.Popen") as popen,
        ):
            opened = doc_html._open_with_registered_windows_browser(url)

        self.assertTrue(opened)
        launch_command = popen.call_args.args[0]
        self.assertIn(url, launch_command)
        self.assertNotIn("%1", launch_command)

    def test_preview_open_falls_back_when_registered_browser_fails(self):
        with (
            patch(
                "pipeline.doc_html._open_with_registered_windows_browser",
                return_value=False,
            ),
            patch("pipeline.doc_html.webbrowser.open", return_value=True) as fallback,
        ):
            opened = doc_html._open_preview_url("file:///C:/docs/index.html#/Doc/test.html")

        self.assertTrue(opened)
        fallback.assert_called_once_with(
            "file:///C:/docs/index.html#/Doc/test.html", new=2
        )


if __name__ == "__main__":
    unittest.main()
