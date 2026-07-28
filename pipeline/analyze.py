"""AI 覆盖分析（docs/02 D19/D20：管线中唯一需要 AI 的一步）。

只使用网页「AI 设置」当前选择的 API 通道，支持两种协议：
        anthropic：Anthropic SDK /v1/messages；
        openai：OpenAI 兼容 /v1/chat/completions。
协议/端点/Key/模型优先用网页保存的 .ai-config.json，留空项回落对应环境变量与
WOODPECKER_MODEL。调用失败时使用同一份配置最多尝试三次，不切换 CLI 或其他模型。
数据外发范围仅函数文档 md + 单测 jl 文本。

代理坑（2026-07-16 实测）：本机中转代理要求带 anthropic-beta: context-1m 头，
否则 400「请启用 1m 上下文」——处理方式是先按标准请求，遇到该错误再带头重试，
不影响其他厂商端点。
"""

from __future__ import annotations

import json
import os
import time
import urllib.error
import urllib.request
import uuid

from . import config

_1M_BETA = {"anthropic-beta": "context-1m-2025-08-07"}


class AnalyzeError(RuntimeError):
    pass


# ---- 用户 AI 配置（网页「AI 设置」读写） ---------------------------------

_AI_FIELDS = ("protocol", "base_url", "api_key", "model")


def _empty_ai_config() -> dict:
    return {key: "" for key in _AI_FIELDS}


def _write_ai_config_store(store: dict) -> None:
    config.AI_CONFIG_FILE.write_text(
        json.dumps(store, ensure_ascii=False, indent=2), encoding="utf-8"
    )


def load_ai_config_store() -> dict:
    """读取多公益站配置；旧版单配置会原样保留 Key 并自动迁移。"""
    try:
        raw = json.loads(config.AI_CONFIG_FILE.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return {"version": 2, "active_profile_id": "", "profiles": []}

    if isinstance(raw, dict) and raw.get("version") == 2:
        profiles = []
        seen = set()
        for item in raw.get("profiles", []):
            if not isinstance(item, dict):
                continue
            profile_id = str(item.get("id", "")).strip()
            if not profile_id or profile_id in seen:
                continue
            protocol = str(item.get("protocol", "")).strip().lower()
            if protocol not in ("", "openai", "anthropic"):
                continue
            seen.add(profile_id)
            profiles.append({
                "id": profile_id,
                "name": str(item.get("name", "")).strip() or "未命名公益站",
                "protocol": protocol,
                "base_url": str(item.get("base_url", "")).strip(),
                "api_key": str(item.get("api_key", "")).strip(),
                "model": str(item.get("model", "")).strip(),
            })
        active = str(raw.get("active_profile_id", "")).strip()
        if active not in seen:
            active = ""
        return {"version": 2, "active_profile_id": active, "profiles": profiles}

    # 旧版只有一组 protocol/base_url/api_key/model。只要存在任一值就迁移，
    # 尤其不能因为浏览器不可见 API Key 而在升级时丢掉它。
    legacy = {key: str(raw.get(key, "")).strip() for key in _AI_FIELDS} if isinstance(raw, dict) else _empty_ai_config()
    profiles = []
    active = ""
    if any(legacy.values()):
        active = "legacy"
        profiles.append({"id": active, "name": "现有配置", **legacy})
    store = {"version": 2, "active_profile_id": active, "profiles": profiles}
    try:
        _write_ai_config_store(store)
    except OSError:
        pass
    return store


def get_ai_profile(profile_id: str) -> dict | None:
    profile_id = profile_id.strip()
    return next(
        (dict(item) for item in load_ai_config_store()["profiles"] if item["id"] == profile_id),
        None,
    )


def load_ai_config() -> dict:
    """返回当前启用档案，保持原有调用方所需的四字段格式。"""
    store = load_ai_config_store()
    active = store["active_profile_id"]
    profile = next((p for p in store["profiles"] if p["id"] == active), None)
    return {key: profile[key] for key in _AI_FIELDS} if profile else _empty_ai_config()


def save_ai_profile(
    profile_id: str, name: str, base_url: str, api_key: str, model: str,
    protocol: str = "",
) -> str:
    """新增或更新一个公益站档案，并将其设为当前档案。"""
    protocol = protocol.strip().lower()
    if protocol not in ("openai", "anthropic"):
        raise AnalyzeError(f"不支持的 AI 接口协议: {protocol or '空'}")
    name = name.strip()
    if not name:
        raise AnalyzeError("请填写公益站配置名称")
    store = load_ai_config_store()
    profile_id = profile_id.strip()
    existing = next((p for p in store["profiles"] if p["id"] == profile_id), None)
    if profile_id and existing is None:
        raise AnalyzeError("要保存的公益站配置不存在，请重新选择")
    if not profile_id:
        profile_id = uuid.uuid4().hex
        existing = {"id": profile_id}
        store["profiles"].append(existing)
    existing.update({
        "name": name, "protocol": protocol, "base_url": base_url.strip(),
        "api_key": api_key.strip(), "model": model.strip(),
    })
    store["active_profile_id"] = profile_id
    _write_ai_config_store(store)
    return profile_id


def activate_ai_profile(profile_id: str) -> None:
    store = load_ai_config_store()
    profile_id = profile_id.strip()
    if profile_id and not any(p["id"] == profile_id for p in store["profiles"]):
        raise AnalyzeError("选择的公益站配置不存在")
    store["active_profile_id"] = profile_id
    _write_ai_config_store(store)


def delete_ai_profile(profile_id: str) -> None:
    store = load_ai_config_store()
    profile_id = profile_id.strip()
    remaining = [p for p in store["profiles"] if p["id"] != profile_id]
    if len(remaining) == len(store["profiles"]):
        raise AnalyzeError("要删除的公益站配置不存在")
    store["profiles"] = remaining
    if store["active_profile_id"] == profile_id:
        store["active_profile_id"] = remaining[0]["id"] if remaining else ""
    _write_ai_config_store(store)


def save_ai_config(base_url: str, api_key: str, model: str, protocol: str = "") -> None:
    """兼容旧调用：更新当前档案；没有档案时创建“现有配置”。"""
    store = load_ai_config_store()
    active = store["active_profile_id"]
    if not any((protocol, base_url, api_key, model)):
        activate_ai_profile("")
        return
    save_ai_profile(active, "现有配置" if not active else next(
        p["name"] for p in store["profiles"] if p["id"] == active
    ), base_url, api_key, model, protocol)


def normalize_base(url: str) -> str:
    """SDK 的 base_url 不含 /v1（SDK 自己拼 /v1/messages）；容忍用户多填。"""
    url = url.strip().rstrip("/")
    if url.endswith("/v1"):
        url = url[: -len("/v1")]
    return url


def mask_api_key(api_key: str) -> str:
    """返回可识别但不可还原的 Key 掩码，仅暴露末四位。"""
    api_key = api_key.strip()
    return f"••••••••{api_key[-4:]}" if api_key else ""


def _environment_defaults(protocol: str) -> dict:
    """读取指定协议自己的环境变量，避免切换协议时串用另一协议的配置。"""
    if protocol == "openai":
        return {
            "base_url": os.environ.get("OPENAI_BASE_URL", ""),
            "api_key": os.environ.get("OPENAI_API_KEY", ""),
            "model": os.environ.get("OPENAI_MODEL", "") or config.MODEL,
        }
    return {
        "base_url": os.environ.get("ANTHROPIC_BASE_URL", ""),
        "api_key": (
            os.environ.get("ANTHROPIC_AUTH_TOKEN", "")
            or os.environ.get("ANTHROPIC_API_KEY", "")
        ),
        "model": config.MODEL,
    }


def resolve_ai_config(
    protocol: str = "", base_url: str = "", api_key: str = "", model: str = ""
) -> dict:
    """把表单临时值、已保存配置和环境变量合并为一次调用的实际配置。"""
    cfg = load_ai_config()
    selected_protocol = (
        protocol.strip()
        or cfg["protocol"]
        or os.environ.get("WOODPECKER_AI_PROTOCOL", "anthropic")
    ).lower()
    if selected_protocol not in ("openai", "anthropic"):
        raise AnalyzeError(
            f"AI 接口协议非法: {selected_protocol!r}（应为 openai/anthropic）"
        )
    env = _environment_defaults(selected_protocol)
    saved_applies = not cfg["protocol"] or cfg["protocol"] == selected_protocol
    return {
        "protocol": selected_protocol,
        "base_url": normalize_base(
            base_url or (cfg["base_url"] if saved_applies else "") or env["base_url"]
        ),
        "api_key": api_key.strip() or (cfg["api_key"] if saved_applies else "") or env["api_key"],
        "model": model.strip() or (cfg["model"] if saved_applies else "") or env["model"],
    }


def _effective() -> dict:
    """合并用户配置与环境变量，得到当前任务实际生效的配置。"""
    return resolve_ai_config()


def current_model() -> str:
    return _effective()["model"]


def current_protocol() -> str:
    return _effective()["protocol"]


def list_models(base_url: str = "", api_key: str = "", protocol: str = "") -> list[str]:
    """一键获取端点支持的模型清单（GET <base>/v1/models）。

    入参留空则用当前生效配置。鉴权同时带 Bearer 与 x-api-key 两种头，
    兼容 Anthropic 官方与各类中转代理。
    """
    eff = resolve_ai_config(protocol, base_url, api_key)
    protocol = eff["protocol"]
    base = eff["base_url"]
    key = eff["api_key"]
    if not base:
        env_name = "OPENAI_BASE_URL" if protocol == "openai" else "ANTHROPIC_BASE_URL"
        raise AnalyzeError(f"API 地址为空：请填写，或先设置 {env_name} 环境变量")
    if not key:
        env_name = "OPENAI_API_KEY" if protocol == "openai" else "ANTHROPIC_API_KEY"
        raise AnalyzeError(f"API Key 为空：请填写，或先设置 {env_name} 环境变量")

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

def _default_coverage_prompt() -> str:
    """提示词文件开头是归档说明（标题 + 引用块），正文在第一条 --- 之后。"""
    text = config.PROMPT_FILE.read_text(encoding="utf-8")
    marker = "\n---\n"
    if marker in text:
        return text.split(marker, 1)[1].strip()
    return text.strip()


def load_coverage_prompt() -> str:
    """返回分析实际使用的提示词；用户未自定义时读取项目默认版本。"""
    try:
        custom = config.CUSTOM_PROMPT_FILE.read_text(encoding="utf-8").strip()
    except (FileNotFoundError, OSError, UnicodeError):
        custom = ""
    return custom or _default_coverage_prompt()


def coverage_prompt_is_customized() -> bool:
    try:
        return bool(config.CUSTOM_PROMPT_FILE.read_text(encoding="utf-8").strip())
    except (FileNotFoundError, OSError, UnicodeError):
        return False


def save_coverage_prompt(prompt: str) -> str:
    prompt = prompt.strip()
    if not prompt:
        raise AnalyzeError("覆盖分析提示词不能为空")
    if len(prompt) > 100_000:
        raise AnalyzeError("覆盖分析提示词不能超过 100000 个字符")
    try:
        config.CUSTOM_PROMPT_FILE.write_text(prompt + "\n", encoding="utf-8")
    except OSError as exc:
        raise AnalyzeError(f"保存覆盖分析提示词失败：{exc}") from exc
    return prompt


def reset_coverage_prompt() -> str:
    try:
        config.CUSTOM_PROMPT_FILE.unlink(missing_ok=True)
    except OSError as exc:
        raise AnalyzeError(f"恢复默认提示词失败：{exc}") from exc
    return _default_coverage_prompt()


def _load_rules() -> str:
    """兼容原调用名，返回当前实际使用的覆盖分析提示词。"""
    return load_coverage_prompt()


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


def _via_openai(
    system: str, user: str, log, eff: dict | None = None,
    max_tokens: int = config.MAX_TOKENS,
) -> str:
    """通过 OpenAI 兼容 Chat Completions API 完成覆盖分析。"""
    eff = eff or _effective()
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
        payload = {**base_payload, token_field: max_tokens}
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


def _via_sdk(
    system: str, user: str, log, eff: dict | None = None,
    max_tokens: int = config.MAX_TOKENS,
) -> str:
    import anthropic

    eff = eff or _effective()
    if not eff["api_key"]:
        raise AnalyzeError(
            "Anthropic API Key 为空：请在 AI 设置中填写，或设置 ANTHROPIC_API_KEY"
        )
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
            max_tokens=max_tokens,
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


def test_ai_prompt(
    question: str, base_url: str = "", api_key: str = "", model: str = "",
    protocol: str = "", log=lambda _message: None,
) -> str:
    """用设置面板当前值发起一次真实试问，不允许降级到 CLI。"""
    question = question.strip()
    if not question:
        raise AnalyzeError("请先填写测试问题")
    if len(question) > 4000:
        raise AnalyzeError("测试问题不能超过 4000 个字符")
    eff = resolve_ai_config(protocol, base_url, api_key, model)
    if not eff["model"]:
        raise AnalyzeError("模型为空：请先获取并选择模型")
    system = "你正在执行 AI 接口连通性测试。请直接、简洁地回答用户问题。"
    try:
        if eff["protocol"] == "openai":
            return _via_openai(system, question, log, eff=eff, max_tokens=512)
        return _via_sdk(system, question, log, eff=eff, max_tokens=512)
    except AnalyzeError:
        raise
    except Exception as exc:  # SDK 的连接/状态异常统一转换为页面可展示错误
        raise AnalyzeError(f"AI 测试失败：{exc}") from exc


def _run_analysis(system: str, user: str, log=print) -> str:
    """固定使用当前 AI 配置，失败时同通道最多尝试三次。"""
    eff = _effective()
    protocol = eff["protocol"]
    call = _via_openai if protocol == "openai" else _via_sdk
    last_error: Exception | None = None
    for attempt in range(1, 4):
        try:
            return call(system, user, log, eff=eff)
        except Exception as exc:  # SDK/urllib 的连接异常类型不统一，在此集中重试
            last_error = exc
            detail = str(exc).replace("\r", " ").replace("\n", " ").strip()
            log(f"  ⚠️ [{protocol}] 第 {attempt}/3 次调用失败：{detail}")
            if attempt < 3:
                delay = attempt * 2
                log(f"  [{protocol}] {delay} 秒后使用当前配置重试（{attempt + 1}/3）……")
                time.sleep(delay)
    raise AnalyzeError(
        f"{protocol} 当前配置连续 3 次调用失败：{last_error}"
    ) from last_error


def coverage_analysis(func: str, doc_md: str, test_bundle: str, log=print) -> str:
    """文档 md + 单测文本 → 覆盖分析报告（md 文本，提示词 v1 六段结构）。"""
    return _run_analysis(_load_rules(), _build_user(func, doc_md, test_bundle), log)


def pasted_performance_analysis(
    func: str, report_text: str, task_type: str = "local_analysis", log=print
) -> str:
    """只分析粘贴报告中当前函数，并要求返回可机读的四态性能结论。"""
    system = """你是一名严谨的软件性能测试专家。用户会提供一段复制粘贴的性能报告，
请只根据原文分析，不补造缺失字段、用法、耗时或结论。

筛选规则是硬约束：
- 只分析“函数名”与当前任务函数完全一致的数据行或区块。
- 其他函数即使数据完整也必须忽略，不得出现在数据完整性、计算过程、表格或综合结论中。
- 当前函数可以有多个用法；只要这些用法仍属于当前函数，就逐项合并判定。
- 找不到当前函数时必须明确写“未找到当前函数性能数据”，不得拿其他函数代替。

若报告提供了足够的参考耗时 T 和耗时比值 x，可按以下标准逐项判断：
- T > 1 秒：x > 1.2 才算不通过；
- 0.1 秒 <= T <= 1 秒：x > 1.25 才算不通过；
- T < 0.1 秒：x > 1.5 才算不通过；
- x 恰好等于阈值仍算通过。

对比口径以粘贴报告的明确字段为准：报告给出“分支 Julia / 基准 Julia”时使用该口径；
报告给出“Julia / MATLAB”或“syslab / matlab”时使用 Julia/MATLAB 口径。不得混用参照系。

首次和二次分别汇总：当前函数任一用法在该阶段不通过，则该阶段不通过。
最终性能结论只能是以下四种之一：
- 性能通过（首次通过、二次通过）；
- 性能首次不通过，二次通过；
- 性能首次通过，二次不通过；
- 性能不通过（首次不通过、二次不通过）。

请输出简洁 Markdown，严格包含：
### 用户粘贴的性能报告分析
#### 数据完整性
#### 可判定项
#### 综合结论

表格每行只能占一个物理行；单元格内不得换行、不得使用反斜杠续行，多个值用顿号分隔。
“综合结论”最后一行必须严格写成 `**性能结论：四种允许结论之一**`，不得添加括号、
句号或其他文字。如果当前函数缺少首次或二次所需数值，不得编造数值；在“数据完整性”
中列出缺失字段，并把缺失的阶段按不通过归类，最终仍只能输出上述四态之一。"""
    user = (
        f"当前任务函数（只分析这个精确名称）：{func}\n"
        f"任务类型：{task_type}\n\n"
        "以下是用户粘贴的性能报告原文：\n\n"
        f"{report_text.strip()}"
    )
    report = _run_analysis(system, user, log)
    if performance_verdict_from_markdown(report) is None:
        raise AnalyzeError("性能分析未返回规定的四态结论，无法写入总结邮件")
    return report


_PERFORMANCE_VERDICTS = (
    "性能首次不通过，二次通过",
    "性能首次通过，二次不通过",
    "性能通过",
    "性能不通过",
)


def performance_verdict_from_markdown(report: str) -> str | None:
    """从 AI Markdown 的固定结论行提取四态结论，拒绝自由文本猜测。"""
    for line in report.splitlines():
        clean = line.strip().strip("*").strip()
        if not clean.startswith("性能结论："):
            continue
        verdict = clean.removeprefix("性能结论：").strip()
        return verdict if verdict in _PERFORMANCE_VERDICTS else None
    return None
