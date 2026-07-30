"""任务级补测代码优化对话：读取材料快照、调用 AI、持久化多轮记录。"""

from __future__ import annotations

import json
import threading
from datetime import datetime
from pathlib import Path

from . import analyze, config


CHAT_FILE_NAME = "补测代码优化对话.json"
MAX_QUESTION_CHARS = 6000
MAX_STORED_MESSAGES = 100
MAX_PROMPT_MESSAGES = 16
MAX_REPORT_CHARS = 100_000
MAX_MATERIAL_CHARS = 80_000
MAX_CONTEXT_CHARS = 260_000

_chat_locks_guard = threading.Lock()
_chat_locks: dict[Path, threading.Lock] = {}


class CodeChatError(ValueError):
    pass


def _lock_for(directory: Path) -> threading.Lock:
    """同一任务串行更新；不同任务的对话互不阻塞。"""
    with _chat_locks_guard:
        return _chat_locks.setdefault(directory, threading.Lock())


def _task_directory(dirname: str) -> Path:
    name = str(dirname).strip()
    directory = (config.TASKS_DIR / name).resolve()
    if (
        not name
        or directory.parent != config.TASKS_DIR.resolve()
        or not directory.is_dir()
        or not any(
            (directory / report_name).is_file()
            for report_name in ("分析报告.md", "覆盖分析报告.md")
        )
    ):
        raise CodeChatError("任务不存在或尚未生成分析报告")
    return directory


def _read_json_object(path: Path) -> dict:
    if not path.is_file():
        return {}
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise CodeChatError(f"无法读取 {path.name}：{exc}") from exc
    return value if isinstance(value, dict) else {}


def _excerpt(path: Path, limit: int) -> str:
    text = path.read_text(encoding="utf-8", errors="replace")
    if len(text) <= limit:
        return text
    head = limit * 2 // 3
    tail = limit - head
    return (
        text[:head]
        + f"\n\n[内容过长，中间省略 {len(text) - limit} 个字符]\n\n"
        + text[-tail:]
    )


def _report_path(directory: Path) -> Path:
    for name in ("分析报告.md", "覆盖分析报告.md"):
        path = directory / name
        if path.is_file():
            return path
    raise CodeChatError("任务分析报告不存在")


def _task_context(directory: Path) -> dict:
    metadata = _read_json_object(directory / "task.json")
    report = _excerpt(_report_path(directory), MAX_REPORT_CHARS)
    remaining = MAX_CONTEXT_CHARS - len(report)
    materials = []
    material_dir = directory / "materials"
    if material_dir.is_dir() and remaining > 0:
        candidates = sorted(
            path for path in material_dir.iterdir()
            if path.is_file()
            and path.suffix.lower() in (".jl", ".md")
            and path.name != "性能分析-AI原始返回.md"
        )
        for path in candidates:
            if remaining <= 0:
                break
            content = _excerpt(path, min(MAX_MATERIAL_CHARS, remaining))
            materials.append({"filename": path.name, "content": content})
            remaining -= len(content)
    return {
        "task": {
            key: metadata.get(key)
            for key in (
                "name", "func", "task_type", "local_library", "code_branch",
                "doc_branch", "unit_test", "doc_md", "model",
            )
            if metadata.get(key) is not None
        },
        "analysis_report": report,
        "materials": materials,
    }


def _load_messages(directory: Path) -> list[dict]:
    path = directory / CHAT_FILE_NAME
    if not path.is_file():
        return []
    value = _read_json_object(path)
    messages = value.get("messages", [])
    if not isinstance(messages, list):
        raise CodeChatError("补测代码优化对话记录格式不正确")
    clean = []
    for item in messages:
        if not isinstance(item, dict):
            continue
        role = item.get("role")
        content = item.get("content")
        if role not in ("user", "assistant") or not isinstance(content, str):
            continue
        clean.append({
            "role": role,
            "content": content,
            "created_at": str(item.get("created_at", "")),
        })
    return clean[-MAX_STORED_MESSAGES:]


def _save_messages(directory: Path, messages: list[dict]) -> None:
    value = {
        "version": 1,
        "task": directory.name,
        "updated_at": datetime.now().isoformat(timespec="seconds"),
        "messages": messages[-MAX_STORED_MESSAGES:],
    }
    path = directory / CHAT_FILE_NAME
    temporary = path.with_name(path.name + ".tmp")
    try:
        temporary.write_text(
            json.dumps(value, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def _conversation_payload(directory: Path, messages: list[dict]) -> dict:
    metadata = _read_json_object(directory / "task.json")
    return {
        "dir": directory.name,
        "func": str(metadata.get("func") or directory.name.split("-", 1)[0]),
        "messages": messages,
    }


def conversation(dirname: str) -> dict:
    directory = _task_directory(dirname)
    with _lock_for(directory):
        messages = _load_messages(directory)
        return _conversation_payload(directory, messages)


def clear_conversation(dirname: str) -> dict:
    directory = _task_directory(dirname)
    with _lock_for(directory):
        (directory / CHAT_FILE_NAME).unlink(missing_ok=True)
        return _conversation_payload(directory, [])


def send_message(dirname: str, question: str, log=print) -> dict:
    question = str(question).strip()
    if not question:
        raise CodeChatError("请输入要优化或确认的内容")
    if len(question) > MAX_QUESTION_CHARS:
        raise CodeChatError(
            f"单条消息不能超过 {MAX_QUESTION_CHARS} 个字符"
        )
    directory = _task_directory(dirname)
    with _lock_for(directory):
        messages = _load_messages(directory)
        context = _task_context(directory)
        answer = analyze.code_refinement_chat(
            context, messages[-MAX_PROMPT_MESSAGES:], question, log=log
        )
        now = datetime.now().isoformat(timespec="seconds")
        messages.extend([
            {"role": "user", "content": question, "created_at": now},
            {"role": "assistant", "content": answer, "created_at": now},
        ])
        _save_messages(directory, messages)
        return _conversation_payload(directory, messages[-MAX_STORED_MESSAGES:])
