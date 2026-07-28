@echo off
setlocal
rem Woodpecker local web UI launcher (double-click me).
rem First run bootstraps .venv/dependencies/Chromium automatically.
chcp 65001 >nul
cd /d "%~dp0"

if /i "%~1"=="--check" goto :check_only
if /i "%~1"=="--login-only" goto :login_only

:launch
rem Hand off immediately; use 启动.vbs directly to avoid even the brief cmd flash.
start "" wscript.exe "%~dp0启动.vbs"
exit /b 0

:find_python
py -3 -c "import sys" >nul 2>&1
if not errorlevel 1 (
  set "PYTHON_CMD=py -3"
  exit /b 0
)
python -c "import sys" >nul 2>&1
if not errorlevel 1 (
  set "PYTHON_CMD=python"
  exit /b 0
)
python3 -c "import sys" >nul 2>&1
if not errorlevel 1 (
  set "PYTHON_CMD=python3"
  exit /b 0
)
exit /b 1

:check_only
call :find_python
if errorlevel 1 goto :no_python
%PYTHON_CMD% -m pipeline.bootstrap --check
exit /b %errorlevel%

:login_only
call :find_python
if errorlevel 1 goto :no_python
%PYTHON_CMD% -m pipeline.bootstrap
if errorlevel 1 goto :bootstrap_failed
".venv\Scripts\python.exe" -m pipeline.login
if errorlevel 1 goto :login_failed
echo.
echo GitLab sign-in completed.
pause
exit /b 0

:no_python
echo.
echo [Missing Python] Install Python 3.10 or newer and enable "Add Python to PATH".
echo Download: https://www.python.org/downloads/windows/
pause
exit /b 1

:bootstrap_failed
echo.
echo [Setup failed] Check the error and network above, then launch again.
pause
exit /b 1

:login_failed
echo.
echo [Sign-in failed] Open the web UI GitLab settings to configure the host/proxy and retry.
pause
exit /b 1
