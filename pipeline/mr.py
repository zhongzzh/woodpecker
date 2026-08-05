"""MR 页面读取（docs/02 D12/D21④：playwright，不申请 GitLab token）。

从 MR 页面读两样东西：
  1. 源分支名（"requested to merge <源分支> into <目标分支>"）；
  2. 当前函数最新一条 mtest2 性能报告 note（D14/D37：先按函数筛选），含摘要文本 +
     「基准/分支版本详细数据」两张表（headers + rows，结构兼容 perf.judge_branch_table）。

登录态存 .pw-state.json（gitignore），在网页「GitLab 设置」中人工登录生成。
本模块只读页面，不做任何页面操作（不点赞、不评论、不合并）。
"""

from __future__ import annotations

import json
import re
import time

from playwright.sync_api import sync_playwright

from . import config

PERF_HEADING = "julia分支性能对比测试报告"


class MrError(RuntimeError):
    pass


# 一次 evaluate 拿全：源分支文本 + 全部性能报告 note，随后按函数和时间筛选。
_EXTRACT_JS = r"""
() => {
  const out = {};
  const detail = document.querySelector('.detail-page-description');
  out.detail_text = detail ? detail.textContent.replace(/\s+/g, ' ').trim() : '';
  // GitLab's stacked MR view inserts "1 of 2" and other cards into the
  // description text. The ref links remain the authoritative branch values.
  out.branch_links = detail ? [...detail.querySelectorAll('a[href*="/-/tree/"]')]
    .map(a => ({
      name: (a.getAttribute('title') || a.textContent || '').trim(),
      href: a.getAttribute('href') || '',
    }))
    .filter(item => item.name) : [];

  const heads = [...document.querySelectorAll('h2')].filter(
    h => (h.textContent || '').includes('julia分支性能对比测试报告'));
  out.perf_note_count = heads.length;
  out.perf_headings = heads.map(h => h.textContent.trim());

  function extractNote(h) {
    const body = h.closest('.note-body') || h.closest('.md') || h.parentElement;
    const note = { heading: h.textContent.trim(), tables: [] };
    const clone = body.cloneNode(true);
    clone.querySelectorAll('details').forEach(d => d.remove());
    note.summary_text = clone.textContent.replace(/\n{3,}/g, '\n\n').trim();
    note.summary_blocks = [...clone.querySelectorAll('pre')]
      .map(pre => pre.textContent.trim())
      .filter(text => text.includes('用法：') || text.includes('用法:'));

    for (const d of body.querySelectorAll('details')) {
      const table = d.querySelector('table');
      if (!table) continue;
      let headers = [...table.querySelectorAll('thead th')].map(th => th.textContent.trim());
      if (!headers.length) {
        const first = table.querySelector('tr');
        headers = first ? [...first.querySelectorAll('th,td')].map(c => c.textContent.trim()) : [];
      }
      const rows = [...table.querySelectorAll('tbody tr')].map(
        tr => [...tr.querySelectorAll('td')].map(td => td.textContent.trim()));
      const summary = d.querySelector('summary');
      note.tables.push({
        title: summary ? summary.textContent.trim() : '',
        headers, rows,
      });
    }
    return note;
  }

  // Keep every note so the caller can select the latest note for one
  // function instead of selecting the latest note for the whole MR.
  out.perf_notes = heads.map(extractNote);
  out.note = out.perf_notes.length
    ? out.perf_notes.reduce((latest, note) =>
        note.heading > latest.heading ? note : latest)
    : null;
  return out;
}
"""


def _parse_branches(
    detail_text: str, branch_links: list[dict] | None = None
) -> tuple[str, str]:
    """Read source/target refs from GitLab branch links or page text.

    GitLab's stacked MR page renders text such as ``requested to merge 1 of 2
    feature/foo into main``. The links are stable across both regular and
    stacked layouts, so they take precedence over the human-readable text.
    """
    refs = [
        str(item.get("name", "")).strip()
        for item in (branch_links or [])
        if isinstance(item, dict) and str(item.get("name", "")).strip()
    ]
    if len(refs) >= 2:
        return refs[0], refs[1]

    # Keep compatibility with older GitLab markup and captured page fixtures.
    m = re.search(
        r"requested to merge\s+(?:(?:\d+\s+of\s+\d+)\s+)?(\S+)\s+into\s+(\S+)",
        detail_text,
    )
    if not m:
        raise MrError(
            "MR 页面上没读到 'requested to merge <源分支> into <目标分支>'，"
            f"页面文本片段：{detail_text[:200]!r}。请确认链接是 MR 页面且账号有权限查看。"
        )
    return m.group(1), m.group(2)


def _function_pattern(func: str) -> re.Pattern[str]:
    return re.compile(
        rf"(?<![A-Za-z0-9_!]){re.escape(func)}(?![A-Za-z0-9_!])",
        re.IGNORECASE,
    )


def _note_matches_function(note: dict, func: str) -> bool:
    """Return whether a report's detailed rows belong to ``func``."""
    target = func.strip()
    if not target:
        return True
    pattern = _function_pattern(target)
    for table in note.get("tables", []):
        headers = table.get("headers", [])
        indices = {
            name: index for index, name in enumerate(headers)
            if name in {"func_name", "git_file", "benchmark_path", "name"}
        }
        for row in table.get("rows", []):
            for name, index in indices.items():
                if index < len(row) and pattern.search(str(row[index])):
                    # func_name is an exact semantic field. Other fields are
                    # path/name fallbacks, where a token-boundary match avoids
                    # treating `area` as a match for `alphaArea`.
                    if name == "func_name":
                        if str(row[index]).strip().casefold() == target.casefold():
                            return True
                    else:
                        return True
    return False


def _select_perf_note(notes: list[dict], func: str = "") -> dict | None:
    """Select the latest report, optionally restricted to one function."""
    if not notes:
        return None
    target = func.strip()
    candidates = [
        note for note in notes
        if _note_matches_function(note, target)
    ] if target else list(notes)
    if not candidates:
        return None
    return max(candidates, key=lambda note: str(note.get("heading", "")))


def read_mr(mr_url: str, log=print, func: str = "") -> dict:
    """读一个 MR 页面。返回：
    {source_branch, target_branch, perf_note_count, perf_note}
    perf_note 为 None（无性能报告）或 {heading, summary_text, tables:[{title,headers,rows}]}。

    ``func`` 由任务表单中的人工函数名提供。提供时，只从该函数对应的
    报告中选择 heading 时间最新的一条；留空则保持对文档 MR 的旧行为。
    """
    if not config.PW_STATE_FILE.exists():
        raise MrError(
            "还没有 GitLab 登录态（.pw-state.json 不存在）。"
            "请打开网页右上角的“GitLab 设置”，完成登录。"
        )

    with sync_playwright() as p:
        proxy = config.system_proxy()
        browser = p.chromium.launch(
            headless=True, proxy={"server": proxy} if proxy else None
        )
        context = browser.new_context(storage_state=str(config.PW_STATE_FILE))
        page = context.new_page()
        log(f"  打开 MR 页面: {mr_url}")
        page.goto(mr_url, wait_until="domcontentloaded", timeout=60_000)

        if "/users/sign_in" in page.url:
            raise MrError(
                "GitLab 登录态已失效（被跳转到登录页）。"
                "请打开网页右上角的“GitLab 设置”重新登录。"
            )
        page.wait_for_selector(".detail-page-description", timeout=30_000)

        # Branch refs are hydrated asynchronously, especially for stacked MRs.
        # Do not evaluate the description while it only contains the stacked
        # MR list, otherwise the source/target links are missed.
        for _ in range(60):
            branch_count = page.locator(
                '.detail-page-description a[href*="/-/tree/"]'
            ).count()
            if branch_count >= 2:
                break
            time.sleep(0.5)

        # 讨论区 note 异步加载：轮询到性能报告条数连续两次稳定为止
        stable, last_count = 0, -1
        for _ in range(20):
            count = page.evaluate(
                "() => [...document.querySelectorAll('h2')]"
                f".filter(h => (h.textContent||'').includes('{PERF_HEADING}')).length"
            )
            stable = stable + 1 if count == last_count else 0
            last_count = count
            if stable >= 2:
                break
            time.sleep(1.5)

        data = page.evaluate(_EXTRACT_JS)
        # 会话可能被 GitLab 续期，回写登录态
        context.storage_state(path=str(config.PW_STATE_FILE))
        browser.close()

    source, target = _parse_branches(
        data["detail_text"], data.get("branch_links")
    )
    notes = data.get("perf_notes")
    if notes is None:
        legacy_note = data.get("note")
        notes = [] if legacy_note is None else [legacy_note]
    selected_note = _select_perf_note(notes, func)
    if selected_note and func.strip():
        note_message = f"，函数 {func} 取最新: {selected_note['heading']}"
    elif selected_note:
        note_message = f"，取最新: {selected_note['heading']}"
    elif notes and func.strip():
        note_message = (
            f"，未找到函数 {func} 对应报告，已忽略其他函数的报告；"
            "请核对详细表 func_name/git_file"
        )
    else:
        note_message = ""
    log(
        f"  源分支: {source} -> {target}；性能报告 {data['perf_note_count']} 条"
        + note_message
    )
    return {
        "source_branch": source,
        "target_branch": target,
        "perf_note_count": data["perf_note_count"],
        "perf_headings": data.get("perf_headings", []),
        "perf_note": selected_note,
    }


def branch_table(perf_note: dict) -> dict:
    """从性能报告 note 中取「分支版本详细数据」表（perf.judge_branch_table 的输入）。"""
    for t in perf_note["tables"]:
        if "分支版本" in t["title"]:
            return t
    raise MrError(
        f"性能报告里没找到「分支版本详细数据」表，实际表：{[t['title'] for t in perf_note['tables']]}"
    )


def baseline_table(perf_note: dict) -> dict:
    """从性能报告 note 中取「基准版本详细数据」表。"""
    for t in perf_note["tables"]:
        if "基准版本" in t["title"]:
            return t
    raise MrError(
        f"性能报告里没找到「基准版本详细数据」表，实际表：{[t['title'] for t in perf_note['tables']]}"
    )


def save_note_snapshot(perf_note: dict, path) -> None:
    """把抓到的性能报告原样存档（可复现、可离线重跑性能判定）。"""
    path.write_text(json.dumps(perf_note, ensure_ascii=False, indent=2), encoding="utf-8")
