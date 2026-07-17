"""AI 覆盖分析（docs/02 D19/D20：管线中唯一需要 AI 的一步）。

双通道（docs/07 §4）：
  sdk — API 直连通道，支持两种协议：
        anthropic：Anthropic SDK /v1/messages；
        openai：OpenAI 兼容 /v1/chat/completions。
        协议/端点/Key/模型优先用网页「AI 设置」保存的 .ai-config.json，
        留空项回落对应环境变量与 WOODPECKER_MODEL。
  cli — headless `claude -p`（复用本机 Claude Code 登录，兜底通道）。
通道选择：环境变量 WOODPECKER_AI_CHANNEL = sdk | cli | auto（默认 auto：
先 sdk，失败自动落 cli）。数据外发范围仅函数文档 md + 单测 jl 文本。

代理坑（2026-07-16 实测）：本机中转代理要求带 anthropic-beta: context-1m 头，
否则 400「请启用 1m 上下文」——处理方式是先按标准请求，遇到该错误再带头重试，
不影响其他厂商端点。
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import urllib.error
import urllib.request

from . import config

_1M_BETA = {"anthropic-beta": "context-1m-2025-08-07"}


class AnalyzeError(RuntimeError):
    pass


# ---- 用户 AI 配置（网页「AI 设置」读写） ---------------------------------

def load_ai_config() -> dict:
    """{protocol, base_url, api_key, model}，空项使用环境变量默认。"""
    empty = {"protocol": "", "base_url": "", "api_key": "", "model": ""}
    try:
        d = json.loads(config.AI_CONFIG_FILE.read_text(encoding="utf-8"))
        return {k: str(d.get(k, "")).strip() for k in empty}
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return empty


def save_ai_config(base_url: str, api_key: str, model: str, protocol: str = "") -> None:
    protocol = protocol.strip().lower()
    if protocol and protocol not in ("openai", "anthropic"):
        raise AnalyzeError(f"不支持的 AI 接口协议: {protocol}")
    config.AI_CONFIG_FILE.write_text(
        json.dumps(
            {
                "protocol": protocol,
                "base_url": base_url.strip(),
                "api_key": api_key.strip(),
                "model": model.strip(),
            },
            ensure_ascii=False, indent=2,
        ),
        encoding="utf-8",
    )


def normalize_base(url: str) -> str:
    """SDK 的 base_url 不含 /v1（SDK 自己拼 /v1/messages）；容忍用户多填。"""
    url = url.strip().rstrip("/")
    if url.endswith("/v1"):
        url = url[: -len("/v1")]
    return url


def _effective() -> dict:
    """合并用户配置与环境变量，得到实际生效的协议/端点/Key/模型。"""
    cfg = load_ai_config()
    protocol = (cfg["protocol"] or os.environ.get("WOODPECKER_AI_PROTOCOL", "anthropic")).lower()
    if protocol not in ("openai", "anthropic"):
        raise AnalyzeError(
            f"WOODPECKER_AI_PROTOCOL 取值非法: {protocol!r}（应为 openai/anthropic）"
        )
    if protocol == "openai":
        env_base = os.environ.get("OPENAI_BASE_URL", "") or os.environ.get("ANTHROPIC_BASE_URL", "")
        env_key = (
            os.environ.get("OPENAI_API_KEY", "")
            or os.environ.get("ANTHROPIC_AUTH_TOKEN", "")
            or os.environ.get("ANTHROPIC_API_KEY", "")
        )
        env_model = os.environ.get("OPENAI_MODEL", "") or config.MODEL
    else:
        env_base = os.environ.get("ANTHROPIC_BASE_URL", "")
        env_key = (
            os.environ.get("ANTHROPIC_AUTH_TOKEN", "")
            or os.environ.get("ANTHROPIC_API_KEY", "")
        )
        env_model = config.MODEL
    return {
        "protocol": protocol,
        "base_url": normalize_base(cfg["base_url"] or env_base),
        "api_key": cfg["api_key"] or env_key,
        "model": cfg["model"] or env_model,
    }


def current_model() -> str:
    return _effective()["model"]


def current_protocol() -> str:
    return _effective()["protocol"]


def list_models(base_url: str = "", api_key: str = "", protocol: str = "") -> list[str]:
    """一键获取端点支持的模型清单（GET <base>/v1/models）。

    入参留空则用当前生效配置。鉴权同时带 Bearer 与 x-api-key 两种头，
    兼容 Anthropic 官方与各类中转代理。
    """
    eff = _effective()
    protocol = protocol.strip().lower() or eff["protocol"]
    if protocol not in ("openai", "anthropic"):
        raise AnalyzeError(f"不支持的 AI 接口协议: {protocol}")
    base = normalize_base(base_url) or eff["base_url"]
    key = api_key.strip() or eff["api_key"]
    if not base:
        raise AnalyzeError("API 地址为空：请填写，或先设置 ANTHROPIC_BASE_URL 环境变量")
    if not key:
        raise AnalyzeError("API Key 为空：请填写，或先设置 ANTHROPIC_AUTH_TOKEN 环境变量")

    headers = {
        "Authorization": f"Bearer {key}",
        "Accept": "application/json",
        # 部分中转端点的 Cloudflare 会拦截 Python-urllib 默认 UA（1010）。
        "User-Agent": "Woodpecker/1.0",
    }
    if protocol == "anthropic":
        headers.update({"x-api-key": key, "anthropic-version": "2023-06-01"})
    req = urllib.request.Request(f"{base}/v1/models", headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.load(resp)
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", errors="replace")[:200]
        raise AnalyzeError(f"获取模型失败（HTTP {e.code}）：{detail}") from e
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as e:
        raise AnalyzeError(f"获取模型失败：{e}") from e

    items = data.get("data", data) if isinstance(data, dict) else data
    if not isinstance(items, list):
        raise AnalyzeError(f"模型接口返回格式不认识：{str(data)[:200]}")
    ids = [it.get("id") if isinstance(it, dict) else str(it) for it in items]
    ids = sorted({i for i in ids if i})
    if not ids:
        raise AnalyzeError("端点返回了空模型清单")
    return ids


# ---- 覆盖分析 ------------------------------------------------------------

def _load_rules() -> str:
    """提示词文件开头是归档说明（标题 + 引用块），正文在第一条 --- 之后。"""
    text = config.PROMPT_FILE.read_text(encoding="utf-8")
    marker = "\n---\n"
    if marker in text:
        return text.split(marker, 1)[1].strip()
    return text.strip()


def _build_user(func: str, doc_md: str, test_bundle: str) -> str:
    return (
        f"以下是 `{func}.md` 与 `{func}.jl`（含伴随数据文件，已标注文件名）的完整内容，"
        "请按既定规则输出分析报告。\n\n"
        f"===== {func}.md =====\n\n{doc_md}\n\n"
        f"===== {func}.jl =====\n\n{test_bundle}"
    )


def _openai_content(message: dict) -> str:
    """兼容标准字符串内容及部分兼容端点返回的内容块。"""
    content = message.get("content", "")
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        chunks = []
        for item in content:
            if isinstance(item, str):
                chunks.append(item)
            elif isinstance(item, dict):
                text = item.get("text", "")
                if isinstance(text, dict):
                    text = text.get("value", "")
                if text:
                    chunks.append(str(text))
        return "".join(chunks).strip()
    return str(content or "").strip()


def _via_openai(system: str, user: str, log) -> str:
    """通过 OpenAI 兼容 Chat Completions API 完成覆盖分析。"""
    eff = _effective()
    if not eff["base_url"]:
        raise AnalyzeError("OpenAI API 地址为空：请在 AI 设置中填写，或设置 OPENAI_BASE_URL")
    if not eff["api_key"]:
        raise AnalyzeError("OpenAI API Key 为空：请在 AI 设置中填写，或设置 OPENAI_API_KEY")

    url = f"{eff['base_url']}/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {eff['api_key']}",
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": "Woodpecker/1.0",
    }
    base_payload = {
        "model": eff["model"],
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
    }

    def _request(token_field: str) -> dict:
        payload = {**base_payload, token_field: config.MAX_TOKENS}
        req = urllib.request.Request(
            url,
            data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
            headers=headers,
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=1200) as resp:
                return json.load(resp)
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", errors="replace")[:1000]
            if (
                e.code == 400
                and token_field == "max_tokens"
                and "max_completion_tokens" in detail
            ):
                log("  [openai] 端点要求 max_completion_tokens，自动重试")
                return _request("max_completion_tokens")
            raise AnalyzeError(f"OpenAI 请求失败（HTTP {e.code}）：{detail}") from e
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as e:
            raise AnalyzeError(f"OpenAI 请求失败：{e}") from e

    log(f"  [openai] 调用 {eff['model']}（输入约 {len(system) + len(user)} 字符）……")
    data = _request("max_tokens")
    choices = data.get("choices", []) if isinstance(data, dict) else []
    if not choices or not isinstance(choices[0], dict):
        raise AnalyzeError(f"OpenAI 接口返回格式不认识：{str(data)[:500]}")
    choice = choices[0]
    message = choice.get("message", {})
    report = _openai_content(message) if isinstance(message, dict) else ""
    if not report:
        # 某些推理模型兼容端点使用 reasoning_content 字段返回正文。
        report = str(message.get("reasoning_content", "")).strip() if isinstance(message, dict) else ""
    if not report:
        raise AnalyzeError(f"OpenAI 接口返回了空内容：{str(data)[:500]}")
    finish_reason = choice.get("finish_reason", "")
    log(f"  [openai] 完成：输出 {len(report)} 字符（finish_reason={finish_reason}）")
    if finish_reason == "length":
        report += "\n\n> ⚠️ 输出因达到 token 上限被截断，建议调大 WOODPECKER_MAX_TOKENS 后重跑。"
    return report


def _via_sdk(system: str, user: str, log) -> str:
    import anthropic

    eff = _effective()
    kwargs: dict = {}
    if eff["base_url"]:
        kwargs["base_url"] = eff["base_url"]
    if eff["api_key"]:
        # 两种鉴权头都带上：官方 API 认 x-api-key，常见中转代理认 Bearer
        kwargs["api_key"] = eff["api_key"]
        kwargs["auth_token"] = eff["api_key"]
    client = anthropic.Anthropic(**kwargs)

    def _stream(extra_headers: dict | None) -> tuple[str, object]:
        chunks: list[str] = []
        with client.messages.stream(
            model=eff["model"],
            max_tokens=config.MAX_TOKENS,
            system=system,
            messages=[{"role": "user", "content": user}],
            extra_headers=extra_headers,
        ) as stream:
            for text in stream.text_stream:
                chunks.append(text)
            return "".join(chunks).strip(), stream.get_final_message()

    log(f"  [sdk] 调用 {eff['model']}（流式，输入约 {len(system) + len(user)} 字符）……")
    try:
        report, final = _stream(None)
    except anthropic.APIStatusError as e:
        if "1m" in str(e):  # 本机中转代理的特殊门槛，带 1m beta 头重试
            log("  [sdk] 端点要求 1m 上下文头，自动重试")
            report, final = _stream(_1M_BETA)
        else:
            raise

    log(f"  [sdk] 完成：输出 {len(report)} 字符（stop_reason={final.stop_reason}）")
    if final.stop_reason == "max_tokens":
        report += "\n\n> ⚠️ 输出因达到 max_tokens 被截断，建议调大 WOODPECKER_MAX_TOKENS 后重跑。"
    return report


def _via_cli(system: str, user: str, log) -> str:
    exe = shutil.which("claude")
    if not exe:
        raise AnalyzeError("找不到 claude 命令，cli 兜底通道不可用")
    log("  [cli] 调用 headless claude -p（会话默认模型）……")
    proc = subprocess.run(
        [exe, "-p", "--output-format", "text"],
        input=f"{system}\n\n---\n\n{user}",
        capture_output=True, text=True, encoding="utf-8", errors="replace",
        timeout=1200,
    )
    if proc.returncode != 0 or not proc.stdout.strip():
        raise AnalyzeError(f"claude -p 失败（exit={proc.returncode}）：{proc.stderr.strip()[:300]}")
    report = proc.stdout.strip()
    log(f"  [cli] 完成：输出 {len(report)} 字符")
    return report


def coverage_analysis(func: str, doc_md: str, test_bundle: str, log=print) -> str:
    """文档 md + 单测文本 → 覆盖分析报告（md 文本，提示词 v1 六段结构）。"""
    system = _load_rules()
    user = _build_user(func, doc_md, test_bundle)
    channel = os.environ.get("WOODPECKER_AI_CHANNEL", "auto")

    if channel not in ("sdk", "cli", "auto"):
        raise AnalyzeError(f"WOODPECKER_AI_CHANNEL 取值非法: {channel!r}（应为 sdk/cli/auto）")
    if channel in ("sdk", "auto"):
        try:
            if current_protocol() == "openai":
                return _via_openai(system, user, log)
            return _via_sdk(system, user, log)
        except Exception as e:  # noqa: BLE001 —— auto 模式下任何 SDK 失败都落 cli
            if channel == "sdk":
                raise
            log(f"  ⚠️ sdk 通道失败：{e}")
            log("  自动切换 cli 兜底通道")
    return _via_cli(system, user, log)
