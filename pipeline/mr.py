"""MR 页面读取（docs/02 D12/D21④：playwright，不申请 GitLab token）。

从 MR 页面读两样东西：
  1. 源分支名（"requested to merge <源分支> into <目标分支>"）；
  2. 最新一条 mtest2 性能报告 note（D14：同 MR 取最新），含摘要文本 +
     「基准/分支版本详细数据」两张表（headers + rows，结构兼容 perf.judge_branch_table）。

登录态存 .pw-state.json（gitignore），首次用 `python -m pipeline.login` 人工登录一次生成。
本模块只读页面，不做任何页面操作（不点赞、不评论、不合并）。
"""

from __future__ import annotations

import json
import time

from playwright.sync_api import sync_playwright

from . import config

PERF_HEADING = "julia分支性能对比测试报告"


class MrError(RuntimeError):
    pass


# 一次 evaluate 拿全：源分支文本 + 最新性能报告 note（按 heading 时间戳取最大）
_EXTRACT_JS = r"""
() => {
  const out = {};
  const detail = document.querySelector('.detail-page-description');
  out.detail_text = detail ? detail.textContent.replace(/\s+/g, ' ').trim() : '';

  const heads = [...document.querySelectorAll('h2')].filter(
    h => (h.textContent || '').includes('julia分支性能对比测试报告'));
  out.perf_note_count = heads.length;
  out.perf_headings = heads.map(h => h.textContent.trim());
  out.note = null;
  if (!heads.length) return out;

  // heading 含时间戳（YYYY-MM-DD HH:MM:SS，零填充），字典序最大即最新（D14）
  let latest = heads[0];
  for (const h of heads) {
    if (h.textContent.trim() > latest.textContent.trim()) latest = h;
  }
  const body = latest.closest('.note-body') || latest.closest('.md') || latest.parentElement;

  const note = { heading: latest.textContent.trim(), tables: [] };
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
  out.note = note;
  return out;
}
"""


def _parse_branches(detail_text: str) -> tuple[str, str]:
    import re

    m = re.search(r"requested to merge\s+(\S+)\s+into\s+(\S+)", detail_text)
    if not m:
        raise MrError(
            "MR 页面上没读到 'requested to merge <源分支> into <目标分支>'，"
            f"页面文本片段：{detail_text[:200]!r}。请确认链接是 MR 页面且账号有权限查看。"
        )
    return m.group(1), m.group(2)


def read_mr(mr_url: str, log=print) -> dict:
    """读一个 MR 页面。返回：
    {source_branch, target_branch, perf_note_count, perf_note}
    perf_note 为 None（无性能报告）或 {heading, summary_text, tables:[{title,headers,rows}]}。
    """
    if not config.PW_STATE_FILE.exists():
        raise MrError(
            "还没有 GitLab 登录态（.pw-state.json 不存在）。"
            "请先运行一次：python -m pipeline.login"
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
                "请重新运行：python -m pipeline.login"
            )
        page.wait_for_selector(".detail-page-description", timeout=30_000)

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

    source, target = _parse_branches(data["detail_text"])
    log(f"  源分支: {source} -> {target}；性能报告 {data['perf_note_count']} 条"
        + (f"，取最新: {data['note']['heading']}" if data["note"] else ""))
    return {
        "source_branch": source,
        "target_branch": target,
        "perf_note_count": data["perf_note_count"],
        "perf_headings": data.get("perf_headings", []),
        "perf_note": data["note"],
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
