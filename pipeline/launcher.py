"""Woodpecker Windows 图形启动器。

默认由 ``启动.bat`` 使用 pythonw 启动。环境准备在后台执行，完成后拉起隐藏的
Web 服务；首次安装的进度和失败原因由这个窗口承载，不再依赖命令行窗口。
"""

from __future__ import annotations

import os
import queue
import subprocess
import sys
import threading
from pathlib import Path

from .windows_dpi import enable_high_dpi, scaled_tk_window_size


PROJECT_ROOT = Path(__file__).resolve().parent.parent
VENV_PYTHONW = PROJECT_ROOT / ".venv" / "Scripts" / "pythonw.exe"
_HEADER_MIN_HEIGHT = 92


def _launcher_header_height(mark_height: int, title_height: int) -> int:
    """Keep the launcher header tall enough for the display's actual fonts."""
    return max(_HEADER_MIN_HEIGHT, mark_height + 36, title_height + 32)


def _hidden_process_kwargs() -> dict:
    if sys.platform == "win32":
        return {"creationflags": subprocess.CREATE_NO_WINDOW}
    return {}


def _bootstrap_python() -> str:
    """pythonw 没有控制台，但执行 bootstrap 本身仍需使用同环境的 python.exe。"""
    executable = Path(sys.executable)
    if executable.name.lower() == "pythonw.exe":
        console_python = executable.with_name("python.exe")
        if console_python.is_file():
            return str(console_python)
    return str(executable)


def _service_command() -> list[str]:
    python = VENV_PYTHONW if VENV_PYTHONW.is_file() else Path(_bootstrap_python())
    return [str(python), "-m", "pipeline.web"]


def main() -> None:
    # DPI awareness must be set before Tk creates its first native window.
    enable_high_dpi()
    try:
        import tkinter as tk
        from tkinter import messagebox, ttk
    except ImportError:
        raise SystemExit("当前 Python 缺少 tkinter，无法打开 Woodpecker 启动器")

    root = tk.Tk()
    root.title("Woodpecker")
    window_width, window_height = scaled_tk_window_size(root, 560, 480)
    root.geometry(f"{window_width}x{window_height}")
    root.resizable(False, False)
    root.configure(bg="#f4f6f8")

    try:
        root.iconname("Woodpecker")
    except tk.TclError:
        pass

    root.update_idletasks()
    x = max(0, (root.winfo_screenwidth() - root.winfo_width()) // 2)
    y = max(0, (root.winfo_screenheight() - root.winfo_height()) // 2 - 30)
    root.geometry(f"+{x}+{y}")

    colors = {
        "ink": "#17212b",
        "muted": "#66727f",
        "line": "#dce2e8",
        "brand": "#16705a",
        "brand_dark": "#105744",
        "surface": "#ffffff",
        "soft": "#e9f4f0",
        "warning": "#b45309",
        "danger": "#b42318",
    }

    style = ttk.Style(root)
    style.theme_use("clam")
    style.configure(
        "Woodpecker.Horizontal.TProgressbar",
        troughcolor="#e6eaee",
        background=colors["brand"],
        bordercolor="#e6eaee",
        lightcolor=colors["brand"],
        darkcolor=colors["brand"],
        thickness=7,
    )

    shell = tk.Frame(root, bg=colors["surface"], highlightthickness=1,
                     highlightbackground=colors["line"])
    shell.pack(fill="both", expand=True, padx=20, pady=20)

    header = tk.Frame(shell, bg=colors["brand"], height=_HEADER_MIN_HEIGHT)
    header.pack(fill="x")
    header.pack_propagate(False)
    mark = tk.Label(header, text="W", width=3, height=1, bg="#ffffff",
                    fg=colors["brand_dark"], font=("Segoe UI", 18, "bold"))
    mark.pack(side="left", padx=(24, 14), pady=18)
    title_group = tk.Frame(header, bg=colors["brand"])
    title_group.pack(side="left", fill="y", pady=16)
    tk.Label(title_group, text="Woodpecker", bg=colors["brand"], fg="#ffffff",
             font=("Segoe UI", 18, "bold")).pack(anchor="w")
    subtitle = tk.Label(
        title_group, text="数学库提测分析工作台", bg=colors["brand"],
        fg="#d9eee8", font=("Microsoft YaHei UI", 9), pady=1,
    )
    subtitle.pack(anchor="w", pady=(2, 0))
    header.update_idletasks()
    header.configure(height=_launcher_header_height(
        mark.winfo_reqheight(), title_group.winfo_reqheight()
    ))

    body = tk.Frame(shell, bg=colors["surface"])
    body.pack(fill="both", expand=True, padx=28, pady=(22, 20))
    heading = tk.Label(body, text="正在启动分析工作台", bg=colors["surface"],
                       fg=colors["ink"], font=("Microsoft YaHei UI", 14, "bold"))
    heading.pack(anchor="w")
    detail = tk.Label(body, text="正在检查本机环境，请稍候...", bg=colors["surface"],
                      fg=colors["muted"], font=("Microsoft YaHei UI", 9))
    detail.pack(anchor="w", pady=(5, 16))

    progress = ttk.Progressbar(body, mode="indeterminate",
                               style="Woodpecker.Horizontal.TProgressbar")
    progress.pack(fill="x")
    progress.start(12)

    steps_frame = tk.Frame(body, bg=colors["surface"])
    steps_frame.pack(fill="x", pady=(18, 0))
    step_texts = ["检查运行环境", "准备依赖与浏览器", "打开工作台"]
    step_labels: list[tk.Label] = []
    for index, text in enumerate(step_texts):
        row = tk.Frame(steps_frame, bg=colors["surface"])
        row.pack(fill="x", pady=3)
        dot = tk.Label(row, text=str(index + 1), width=2, bg="#edf0f3",
                       fg=colors["muted"], font=("Segoe UI", 9, "bold"))
        dot.pack(side="left")
        label = tk.Label(row, text=text, bg=colors["surface"], fg=colors["muted"],
                         font=("Microsoft YaHei UI", 9))
        label.pack(side="left", padx=(10, 0))
        step_labels.append(dot)

    actions = tk.Frame(body, bg=colors["surface"])
    actions.pack(side="bottom", fill="x", pady=(14, 0))
    close_button = tk.Button(
        actions, text="关闭", command=root.destroy, bg="#ffffff", fg=colors["ink"],
        activebackground="#f2f4f6", activeforeground=colors["ink"], relief="solid",
        bd=1, padx=18, pady=7, font=("Microsoft YaHei UI", 9), cursor="hand2",
    )
    retry_button = tk.Button(
        actions, text="重试", bg=colors["brand"], fg="#ffffff",
        activebackground=colors["brand_dark"], activeforeground="#ffffff", relief="flat",
        bd=0, padx=20, pady=8, font=("Microsoft YaHei UI", 9, "bold"), cursor="hand2",
    )

    events: queue.Queue[tuple[str, object]] = queue.Queue()
    running = {"value": False}
    process_state: dict[str, subprocess.Popen | None] = {"bootstrap": None}

    def set_step(active: int) -> None:
        for index, dot in enumerate(step_labels):
            if index < active:
                dot.configure(text="OK", bg=colors["soft"], fg=colors["brand"],
                              font=("Segoe UI", 7, "bold"))
            elif index == active:
                dot.configure(text=str(index + 1), bg=colors["brand"], fg="#ffffff",
                              font=("Segoe UI", 9, "bold"))
            else:
                dot.configure(text=str(index + 1), bg="#edf0f3", fg=colors["muted"],
                              font=("Segoe UI", 9, "bold"))

    def worker() -> None:
        command = [_bootstrap_python(), "-m", "pipeline.bootstrap"]
        worker_log: list[str] = []
        try:
            proc = subprocess.Popen(
                command,
                cwd=str(PROJECT_ROOT),
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                stdin=subprocess.DEVNULL,
                text=True,
                encoding="utf-8",
                errors="replace",
                env={**os.environ, "PYTHONUTF8": "1"},
                **_hidden_process_kwargs(),
            )
            process_state["bootstrap"] = proc
            assert proc.stdout is not None
            for raw in proc.stdout:
                line = raw.strip()
                if line:
                    worker_log.append(line)
                    events.put(("line", line))
            code = proc.wait()
            process_state["bootstrap"] = None
            if code != 0:
                message = "\n".join(worker_log[-12:]) or f"环境准备失败（退出码 {code}）"
                events.put(("error", message))
                return
            events.put(("launching", None))
            subprocess.Popen(
                _service_command(),
                cwd=str(PROJECT_ROOT),
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                close_fds=True,
                **_hidden_process_kwargs(),
            )
            events.put(("done", None))
        except OSError as exc:
            process_state["bootstrap"] = None
            events.put(("error", f"无法启动程序：{exc}"))

    def start() -> None:
        if running["value"]:
            return
        running["value"] = True
        heading.configure(text="正在启动分析工作台", fg=colors["ink"])
        detail.configure(text="正在检查本机环境，请稍候...", fg=colors["muted"])
        retry_button.pack_forget()
        close_button.pack_forget()
        progress.start(12)
        set_step(0)
        threading.Thread(target=worker, daemon=True).start()

    def poll_events() -> None:
        try:
            while True:
                event, value = events.get_nowait()
                if event == "line":
                    line = str(value)
                    detail.configure(text=line[:88])
                    if line.startswith("[2/3]"):
                        set_step(1)
                    elif line.startswith("[3/3]"):
                        set_step(1)
                elif event == "launching":
                    set_step(2)
                    detail.configure(text="环境已就绪，正在打开浏览器...")
                elif event == "done":
                    set_step(3)
                    progress.stop()
                    progress.configure(mode="determinate", value=100)
                    heading.configure(text="工作台已启动", fg=colors["brand_dark"])
                    detail.configure(text="浏览器即将打开，此窗口会自动关闭。")
                    root.after(700, root.destroy)
                elif event == "error":
                    running["value"] = False
                    progress.stop()
                    progress.configure(mode="determinate", value=0)
                    heading.configure(text="启动失败", fg=colors["danger"])
                    detail.configure(text="请查看错误详情，修复后可以重试。", fg=colors["danger"])
                    close_button.pack(side="right")
                    retry_button.configure(command=start)
                    retry_button.pack(side="right", padx=(0, 10))
                    messagebox.showerror("Woodpecker 启动失败", str(value), parent=root)
        except queue.Empty:
            pass
        if root.winfo_exists():
            root.after(80, poll_events)

    def close() -> None:
        proc = process_state["bootstrap"]
        if proc and proc.poll() is None:
            if sys.platform == "win32":
                subprocess.run(
                    ["taskkill", "/F", "/T", "/PID", str(proc.pid)],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    **_hidden_process_kwargs(),
                )
            else:
                proc.terminate()
        root.destroy()

    close_button.configure(command=close)
    root.protocol("WM_DELETE_WINDOW", close)
    start()
    root.after(80, poll_events)
    root.mainloop()


if __name__ == "__main__":
    main()
