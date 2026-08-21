@echo off
setlocal
cd /d "%~dp0"

where python >nul 2>&1
if errorlevel 1 (
  echo Python introuvable. Installe Python 3.10+ et coche "Add to PATH".
  pause
  exit /b 1
)

echo === Installation Teams Macro (Windows) ===
if not exist ".venv\Scripts\python.exe" (
  python -m venv .venv
)
".venv\Scripts\python.exe" -m pip install --upgrade pip
".venv\Scripts\python.exe" -m pip install -r requirements.txt
if errorlevel 1 (
  echo Echec pip install.
  pause
  exit /b 1
)

echo.
echo OK. Prochaines etapes :
echo   1. Double-clique run.bat
echo   2. Une icone apparait dans la barre des taches (pres de l'horloge)
echo   3. Le demarrage auto Windows est gere dans Reglages de l'app
echo.
pause
endlocal
