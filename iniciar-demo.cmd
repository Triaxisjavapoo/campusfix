@echo off
setlocal
cd /d "%~dp0"
where node >nul 2>nul
if errorlevel 1 (
  echo Necesitas Node.js 24.12 o superior y Java JDK 21 o superior.
  pause
  exit /b 1
)
if not exist "node_modules\firebase-tools\lib\bin\firebase.js" (
  call npm ci
  if errorlevel 1 (
    pause
    exit /b 1
  )
)
echo Iniciando la demostracion gratuita local de CampusFix...
echo Cuando termine de cargar, abre http://127.0.0.1:5000
call npm run demo
pause
