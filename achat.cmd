@echo off
where py >nul 2>nul
if %errorlevel%==0 (
  py -3 "%~dp0agentchat.py" %*
) else (
  python "%~dp0agentchat.py" %*
)
exit /b %errorlevel%
