@echo off
rem woodpecker local web UI launcher (double-click me)
chcp 65001 >nul
cd /d "%~dp0"
if not exist ".venv\Scripts\pythonw.exe" (
  echo [!] .venv not found. Please finish the one-time setup in README.md first.
  pause
  exit /b 1
)
rem pythonw runs the local service without leaving a terminal window visible.
start "" ".venv\Scripts\pythonw.exe" -m pipeline.web
exit /b 0
