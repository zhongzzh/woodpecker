"""首次登录：python -m pipeline.login

打开有界面浏览器到 GitLab 登录页，人工登录一次；登录成功后自动把会话
保存到 .pw-state.json（gitignore），之后 mr.py 无人值守复用。
"""

from __future__ import annotations

from playwright.sync_api import sync_playwright

from . import config


def main() -> None:
    with sync_playwright() as p:
        proxy = config.system_proxy()
        browser = p.chromium.launch(
            headless=False, proxy={"server": proxy} if proxy else None
        )
        context = browser.new_context(
            storage_state=str(config.PW_STATE_FILE) if config.PW_STATE_FILE.exists() else None
        )
        page = context.new_page()
        page.goto(f"https://{config.GITLAB_HOST}/users/sign_in", timeout=60_000)

        if "/users/sign_in" not in page.url:
            print("已有有效登录态，无需重新登录。")
        else:
            print("请在打开的浏览器窗口中登录 GitLab（最多等 5 分钟）……")
            page.wait_for_url(lambda url: "/users/sign_in" not in url, timeout=300_000)
            print("登录成功。")

        context.storage_state(path=str(config.PW_STATE_FILE))
        print(f"登录态已保存: {config.PW_STATE_FILE}")
        browser.close()


if __name__ == "__main__":
    main()
