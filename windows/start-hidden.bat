@echo off
REM Lance Teams Macro sans fenêtre console (démarrage Windows).
setlocal
cd /d "%~dp0"
if exist ".venv\Scripts\pythonw.exe" (
  ".venv\Scripts\pythonw.exe" -m teamsmacro
) else (
  where pythonw >nul 2>&1
  if errorlevel 1 (
    python -m teamsmacro
  ) else (
    pythonw -m teamsmacro
  )
)
endlocal
