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


def _run_analysis(system: str, user: str, log=print) -> str:
    """按当前 AI 配置执行一次文本分析，复用 sdk/cli 自动降级逻辑。"""
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


def coverage_analysis(func: str, doc_md: str, test_bundle: str, log=print) -> str:
    """文档 md + 单测文本 → 覆盖分析报告（md 文本，提示词 v1 六段结构）。"""
    return _run_analysis(_load_rules(), _build_user(func, doc_md, test_bundle), log)


def pasted_performance_analysis(
    func: str, report_text: str, task_type: str = "local_analysis", log=print
) -> str:
    """将用户粘贴的内容作为独立性能报告分析，不按任务函数名过滤。"""
    system = """你是一名严谨的软件性能测试专家。用户会提供一段复制粘贴的性能报告，
请只根据原文分析，不补造缺失字段、用法、耗时或结论。

这份粘贴内容本身就是用户指定要分析的性能数据，必须遵守以下规则：
- 不得用当前任务函数名筛选、拒绝或忽略报告内容；即使报告中的函数名与当前任务不同，
  也要分析报告里所有具有可用性能数据的函数或用法。
- 表格开头的“函数名”“示例”“示例代码”等列只用于标识结果和提供上下文，
  不作为是否允许分析的前置条件。判定时直接提取 Julia/MATLAB 用时、
  分支/基准用时、比例等性能字段。
- 按报告中的每个函数或用法逐项分析。有足够数值的项目必须给出判定；
  缺少数值时只把对应项目列入“无法判定项”，不能据此声称整份报告不存在或无效。
- 当前任务函数名和任务类型仅供背景参考，不能覆盖报告自身明确给出的对比口径。

若报告提供了足够的参考耗时 T 和耗时比值 x，可按以下标准逐项判断：
- T > 1 秒：x > 1.2 才算不通过；
- 0.1 秒 <= T <= 1 秒：x > 1.25 才算不通过；
- T < 0.1 秒：x > 1.5 才算不通过；
- x 恰好等于阈值仍算通过。

对比口径以粘贴报告的明确字段为准：报告给出“分支 Julia / 基准 Julia”时使用该口径；
报告给出“Julia / MATLAB”或“syslab / matlab”时使用 Julia/MATLAB 口径。不得混用参照系。

请输出 Markdown，严格包含：
### 用户粘贴的性能报告分析
#### 数据完整性
#### 可判定项
#### 无法判定项
#### 综合结论

数据不足时，综合结论必须明确写“无法完整判定”，并列出还需要哪些字段。"""
    user = (
        f"当前材料函数（仅作背景，不用于筛选报告）：{func}\n"
        f"任务类型（仅作背景）：{task_type}\n\n"
        "以下是用户粘贴的性能报告原文：\n\n"
        f"{report_text.strip()}"
    )
    return _run_analysis(system, user, log)
