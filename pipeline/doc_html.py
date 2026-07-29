"""帮助文档项目编译与函数 HTML 预览。"""

from __future__ import annotations

import os
import subprocess
import sys
import webbrowser
from pathlib import Path, PurePosixPath
from urllib.parse import quote


class DocHtmlError(RuntimeError):
    pass


def project_and_source_path(doc_relative: str) -> tuple[str, PurePosixPath]:
    """从仓库相对 md 路径提取真实帮助项目和项目内路径。"""
    path = PurePosixPath(doc_relative.replace("\\", "/"))
    parts = path.parts
    try:
        index = parts.index("projects")
        project = parts[index + 1]
    except (ValueError, IndexError) as exc:
        raise DocHtmlError(f"无法从文档路径识别帮助项目：{doc_relative}") from exc
    if not project or len(parts) <= index + 2:
        raise DocHtmlError(f"文档路径缺少项目内文件：{doc_relative}")
    return project, PurePosixPath(*parts[index + 2:])


def expected_html_path(
    docs_repo: Path, doc_relative: str
) -> tuple[str, Path]:
    """Markdown 在 dist/Help 中保持目录结构，仅扩展名变为 .html。"""
    project, source_path = project_and_source_path(doc_relative)
    html = (
        docs_repo
        / "syslabHelpSourceCode"
        / "dist"
        / "Help"
        / project
        / Path(*source_path.parts)
    ).with_suffix(".html")
    return project, html


def _hidden_process_kwargs() -> dict:
    return {"creationflags": subprocess.CREATE_NO_WINDOW} if sys.platform == "win32" else {}


def _run_build(help_root: Path, project: str, log=print) -> None:
    script = help_root / "extension-build.bat"
    project_dir = help_root / "projects" / project
    if not script.is_file():
        raise DocHtmlError(f"未找到文档构建脚本：{script}")
    if not project_dir.is_dir():
        raise DocHtmlError(
            f"文档项目不存在：{project_dir}；请以 md 所在的 projects 子目录为准"
        )

    argument = f".\\projects\\{project}"
    log(f"  编译帮助项目: .\\extension-build.bat {argument}")
    command = [str(script), argument]
    try:
        proc = subprocess.Popen(
            command,
            cwd=str(help_root),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            stdin=subprocess.DEVNULL,
            text=True,
            encoding="utf-8",
            errors="replace",
            env={**os.environ, "PYTHONUTF8": "1"},
            **_hidden_process_kwargs(),
        )
    except OSError as exc:
        raise DocHtmlError(f"无法启动文档编译：{exc}") from exc

    assert proc.stdout is not None
    tail: list[str] = []
    for raw in proc.stdout:
        line = raw.rstrip("\r\n")
        if not line:
            continue
        tail.append(line)
        tail = tail[-8:]
        log(f"    {line}")
    code = proc.wait()
    if code != 0:
        detail = " ｜ ".join(tail) or f"exit={code}"
        raise DocHtmlError(f"文档编译失败（exit={code}）：{detail}")


def _find_built_html(
    docs_repo: Path, doc_relative: str, func: str
) -> tuple[str, Path]:
    project, expected = expected_html_path(docs_repo, doc_relative)
    if expected.is_file():
        return project, expected

    output_root = docs_repo / "syslabHelpSourceCode" / "dist" / "Help" / project
    hits = sorted(
        path for path in output_root.rglob("*.html")
        if path.stem.lower() == func.lower()
    ) if output_root.is_dir() else []
    if len(hits) == 1:
        return project, hits[0]
    if not hits:
        raise DocHtmlError(
            f"编译完成但未找到 {func}.html；预期位置：{expected}"
        )
    raise DocHtmlError(f"编译产物中有多个 {func}.html，无法确定：{hits}")


def preview_url_for_html(docs_repo: Path, project: str, html: Path) -> str:
    """通过帮助项目的 SPA 入口构造函数预览地址。"""
    output_root = (
        docs_repo / "syslabHelpSourceCode" / "dist" / "Help" / project
    ).resolve()
    index = output_root / "index.html"
    if not index.is_file():
        raise DocHtmlError(f"编译完成但未找到帮助项目入口：{index}")
    try:
        relative_html = html.resolve().relative_to(output_root).as_posix()
    except ValueError as exc:
        raise DocHtmlError(f"函数 HTML 不在帮助项目产物中：{html}") from exc
    return (
        f"{index.as_uri()}#/"
        f"{quote(relative_html, safe='/')}#{quote('语法')}"
    )


def build_and_open(
    docs_repo: Path, doc_relative: str, func: str, log=print
) -> dict:
    """编译 md 所属帮助项目，定位函数 HTML，并用系统默认浏览器打开。"""
    project, _expected = expected_html_path(docs_repo, doc_relative)
    help_root = docs_repo / "syslabHelpSourceCode"
    _run_build(help_root, project, log=log)
    project, html = _find_built_html(docs_repo, doc_relative, func)
    preview_url = preview_url_for_html(docs_repo, project, html)
    opened = webbrowser.open(preview_url, new=2)
    log(f"  函数 HTML: {html}")
    log(f"  预览地址: {preview_url}")
    log("  已请求默认浏览器打开文档" if opened else "  ⚠️ 浏览器未确认打开，请手动打开上述 HTML")
    return {
        "project": project,
        "html": str(html),
        "url": preview_url,
        "browser_opened": bool(opened),
    }
