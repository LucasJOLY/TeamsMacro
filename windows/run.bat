@echo off
setlocal
cd /d "%~dp0"

where python >nul 2>&1
if errorlevel 1 (
  echo Python introuvable. Installe Python 3.10+ depuis https://www.python.org/downloads/
  echo Coche "Add python.exe to PATH" pendant l'installation.
  pause
  exit /b 1
)

if not exist ".venv\Scripts\python.exe" (
  echo Creation de l'environnement virtuel...
  python -m venv .venv
  if errorlevel 1 (
    echo Echec de creation du venv.
    pause
    exit /b 1
  )
  ".venv\Scripts\python.exe" -m pip install --upgrade pip
  ".venv\Scripts\python.exe" -m pip install -r requirements.txt
  if errorlevel 1 (
    echo Echec de l'installation des dependances.
    pause
    exit /b 1
  )
)

echo Lancement de Teams Macro...
start "" ".venv\Scripts\pythonw.exe" -m teamsmacro
endlocal
