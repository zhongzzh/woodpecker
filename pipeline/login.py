"""GitLab 浏览器连接测试与人工登录。"""

from __future__ import annotations

import sys
from urllib.parse import urlparse

from playwright.sync_api import Error as PlaywrightError
from playwright.sync_api import TimeoutError as PlaywrightTimeoutError
from playwright.sync_api import sync_playwright

from . import config


class LoginError(RuntimeError):
    pass


def _sign_in_url(host: str) -> str:
    return f"https://{host.strip().rstrip('/')}/users/sign_in"


def _root_url(host: str) -> str:
    return f"https://{host.strip().rstrip('/')}/"


def _is_authenticated_url(url: str, host: str) -> bool:
    """登录成功后必须回到目标 GitLab 主机，且不再位于登录页。"""
    current = urlparse(url)
    expected = urlparse(_root_url(host))
    return (
        current.hostname == expected.hostname
        and current.path.rstrip("/") != "/users/sign_in"
        and current.scheme in ("http", "https")
    )


def _launch_login_browser(playwright, proxy: str | None):
    """人工登录优先使用系统 Chrome，获得正常缩放与原生窗口体验。"""
    options = {
        "headless": False,
        "proxy": {"server": proxy} if proxy else None,
        "args": ["--start-maximized"],
    }
    try:
        return playwright.chromium.launch(channel="chrome", **options)
    except PlaywrightError:
        return playwright.chromium.launch(**options)


def _friendly_error(error: Exception, host: str, proxy: str | None) -> str:
    raw = str(error)
    detail = f"目标：https://{host}；代理：{proxy or '未设置（直连/系统网络）'}。"
    mappings = (
        ("ERR_CONNECTION_CLOSED", "连接被关闭。请确认公司 VPN/代理已启动，并检查代理地址和端口"),
        ("ERR_CONNECTION_REFUSED", "连接被拒绝。请检查 GitLab 地址、代理端口或代理软件是否运行"),
        ("ERR_CONNECTION_TIMED_OUT", "连接超时。请检查公司内网、VPN、防火墙或代理设置"),
        ("ERR_TIMED_OUT", "访问超时。请检查公司内网、VPN、防火墙或代理设置"),
        ("ERR_NAME_NOT_RESOLVED", "域名无法解析。请检查 GitLab 地址和当前 DNS/VPN"),
        ("ERR_PROXY_CONNECTION_FAILED", "无法连接代理。请检查代理地址、端口及代理软件状态"),
        ("ERR_TUNNEL_CONNECTION_FAILED", "代理隧道建立失败。请检查代理规则或公司网络权限"),
        ("ERR_CERT", "HTTPS 证书校验失败。请确认系统已安装公司证书，且 GitLab 地址正确"),
    )
    for marker, message in mappings:
        if marker in raw:
            return f"{message}。{detail}"
    if isinstance(error, PlaywrightTimeoutError):
        return f"打开 GitLab 超时。请检查网络、VPN 或代理。{detail}"
    first = raw.splitlines()[0] if raw else error.__class__.__name__
    return f"无法打开 GitLab：{first}。{detail}"


def check_connection(host: str | None = None, proxy: str | None = None) -> dict:
    """用与正式取数相同的 Chromium 网络路径测试 GitLab。"""
    host = host or config.gitlab_host()
    proxy = config.system_proxy() if proxy is None else (proxy.strip() or None)
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(
                headless=True, proxy={"server": proxy} if proxy else None
            )
            try:
                page = browser.new_page()
                response = page.goto(
                    _sign_in_url(host), wait_until="domcontentloaded", timeout=30_000
                )
                return {
                    "url": page.url,
                    "status": response.status if response else None,
                }
            finally:
                browser.close()
    except PlaywrightError as e:
        raise LoginError(_friendly_error(e, host, proxy)) from e


def login_gitlab(host: str | None = None, proxy: str | None = None) -> None:
    """打开有界面浏览器，等待用户完成 GitLab 登录并保存会话。"""
    host = host or config.gitlab_host()
    proxy = config.system_proxy() if proxy is None else (proxy.strip() or None)
    try:
        with sync_playwright() as p:
            browser = _launch_login_browser(p, proxy)
            try:
                context = browser.new_context(
                    storage_state=(
                        str(config.PW_STATE_FILE)
                        if config.PW_STATE_FILE.exists()
                        else None
                    ),
                    no_viewport=True,
                )
                page = context.new_page()
                # wait_until=commit 让浏览器窗口尽快展示，不必等整页资源加载完成。
                page.goto(_root_url(host), wait_until="commit", timeout=60_000)
                # 等初始重定向完成后再判断，避免把尚未跳到登录页的根 URL 误认为已登录。
                page.wait_for_load_state("domcontentloaded", timeout=60_000)

                if not _is_authenticated_url(page.url, host):
                    page.wait_for_url(
                        lambda url: _is_authenticated_url(str(url), host), timeout=300_000
                    )
                # 不能只凭一次 URL 变化判断成功：重新访问受保护的 GitLab 首页，
                # 若仍跳回登录页则拒绝保存这份无效状态。
                page.goto(_root_url(host), wait_until="domcontentloaded", timeout=60_000)
                if not _is_authenticated_url(page.url, host):
                    raise LoginError("登录尚未完成：GitLab 首页仍然跳转到登录页")
                context.storage_state(path=str(config.PW_STATE_FILE))
            finally:
                browser.close()
    except LoginError:
        raise
    except PlaywrightError as e:
        raise LoginError(_friendly_error(e, host, proxy)) from e


def main() -> None:
    try:
        login_gitlab()
    except LoginError as e:
        print(f"GitLab 登录失败：{e}", file=sys.stderr)
        raise SystemExit(1) from None
    print(f"GitLab 登录成功，登录态已保存：{config.PW_STATE_FILE}")


if __name__ == "__main__":
    main()
