"""手工/本地浏览器烟测：一键粘贴结果能回填表单并触发任务类型 UI。"""

from pathlib import Path

from playwright.sync_api import sync_playwright


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    html = (ROOT / "pipeline" / "static" / "index.html").read_text(encoding="utf-8")
    parsed = {
        "name": "【数学库2026.7月第二周周提测】TyDifferentialEquation：ode89 函数性能优化",
        "code_mr": "https://git.tongyuan.cc/syslab/packages/math/TyDifferentialEquation.jl/-/merge_requests/250",
        "doc_mr": "",
        "task_type": "performance_optimization",
        "warnings": [],
    }
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        page = browser.new_page()
        page.set_content(html)
        page.evaluate(
            """parsed => {
                window.fetch = async (url, options = {}) => {
                    if (url === '/api/parse-input') {
                        return {status: 200, json: async () => ({ok: true, ...parsed})};
                    }
                    return {status: 200, json: async () => ({})};
                };
            }""",
            parsed,
        )
        page.fill("#raw_input", "encoded mixed content")
        page.evaluate("parsePastedInput(false)")
        assert page.input_value("#name") == parsed["name"]
        assert page.input_value("#code_mr") == parsed["code_mr"]
        assert page.locator("#docMrField").get_attribute("hidden") is not None
        assert page.locator("#requiredCount").inner_text() == "性能优化只需任务名和代码 MR"
        assert "已提取" in page.locator("#pasteMsg").inner_text()
        browser.close()
    print("ui paste smoke passed")


if __name__ == "__main__":
    main()
