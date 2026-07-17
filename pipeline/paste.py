"""整段提测文本拆分：任务名、代码 MR、文档 MR。

用户可直接粘贴邮件/聊天中的连续文本，即使标题被百分号编码并与 URL 粘连，
也先解码再按稳定结构提取。这里只做确定性文本处理，不访问网络。
"""

from __future__ import annotations

import re
from urllib.parse import unquote


class PasteParseError(ValueError):
    pass


MR_URL_RE = re.compile(
    r"https?://[^/\s]+/[A-Za-z0-9._~!$&'()*+,;=:@/-]+?/-/merge_requests/\d+",
    re.I,
)

FUNC = r"[A-Za-z_][A-Za-z0-9_!]*"
TASK_TAIL = rf"(?:新增\s*{FUNC}\s*函数|{FUNC}\s*函数\s*性能优化)"
FULL_TITLE_RE = re.compile(
    rf"【\s*数学库[^】]*周提测[^】]*】\s*"
    rf"[A-Za-z_][A-Za-z0-9_.]*\s*[：:]\s*{TASK_TAIL}",
    re.I,
)
LIBRARY_TASK_RE = re.compile(
    rf"[A-Za-z_][A-Za-z0-9_.]*\s*[：:]\s*{TASK_TAIL}", re.I
)
BARE_TASK_RE = re.compile(TASK_TAIL, re.I)


def _decode(text: str) -> str:
    decoded = text.replace("\u200b", "").replace("\ufeff", "")
    # 兼容从某些系统复制出的二次编码文本；最多两轮，避免无意义循环。
    for _ in range(2):
        next_text = unquote(decoded)
        if next_text == decoded:
            break
        decoded = next_text
    return decoded


def _unique(items: list[str]) -> list[str]:
    seen: set[str] = set()
    result = []
    for item in items:
        normalized = item.rstrip("/.,，。；;)")
        if normalized not in seen:
            seen.add(normalized)
            result.append(normalized)
    return result


def _task_name(text: str) -> str:
    for pattern in (FULL_TITLE_RE, LIBRARY_TASK_RE, BARE_TASK_RE):
        match = pattern.search(text)
        if match:
            return re.sub(r"\s+", " ", match.group(0)).strip()
    return ""


def parse_submission_text(text: str) -> dict:
    """解析一段混合文本，返回可直接回填任务表单的字段。"""
    if not text or not text.strip():
        raise PasteParseError("请先粘贴提测内容")

    decoded = _decode(text)
    urls = _unique(MR_URL_RE.findall(decoded))
    if not urls:
        raise PasteParseError("没有识别到 GitLab Merge Request 链接")

    name = _task_name(decoded)
    if not name:
        raise PasteParseError("识别到了 MR 链接，但没有识别到新增函数或函数性能优化任务标题")

    doc_urls = [url for url in urls if "/syslab/syslab-docs-2.0/-/merge_requests/" in url]
    code_urls = [url for url in urls if url not in doc_urls]
    if not code_urls:
        raise PasteParseError("只识别到文档 MR，没有识别到数学库代码 MR")

    task_type = "performance_optimization" if "性能优化" in name else "new_function"
    warnings: list[str] = []
    if len(code_urls) > 1:
        warnings.append(f"识别到 {len(code_urls)} 个不同代码 MR，已选用第一个")
    if len(doc_urls) > 1:
        warnings.append(f"识别到 {len(doc_urls)} 个不同文档 MR，已选用第一个")
    if task_type == "new_function" and not doc_urls:
        warnings.append("这是新增函数任务，但粘贴内容中没有识别到文档 MR")

    return {
        "name": name,
        "code_mr": code_urls[0],
        "doc_mr": doc_urls[0] if doc_urls else "",
        "task_type": task_type,
        "urls": urls,
        "warnings": warnings,
        "decoded_text": decoded,
    }
