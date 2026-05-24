@echo off
chcp 65001 >nul
title Online BeamNG.drive - Full Launcher

echo ===========================================
echo   Online BeamNG.drive - Launch Everything
echo ===========================================
echo.

:: Check server
if not exist "%~dp0..\server\node_modules" (
    echo [1/3] Installing server dependencies...
    cd /d "%~dp0..\server"
    call npm install
    if %errorlevel% neq 0 (
        echo [ERROR] npm install failed
        pause
        exit /b 1
    )
) else (
    echo [1/3] Dependencies OK
)

:: Build if needed
if not exist "%~dp0..\server\dist" (
    echo [2/3] Building server...
    cd /d "%~dp0..\server"
    call npm run build
) else (
    echo [2/3] Build OK
)

:: Start server
echo [3/3] Starting server...
cd /d "%~dp0..\server"
start "BeamNG Server" cmd /c "npm start & pause"

:: Wait for server to initialize
timeout /t 3 /nobreak >nul

:: Launch game
echo.
echo Launching BeamNG.drive...
start "" "C:\Program Files (x86)\Steam\steamapps\common\BeamNG.drive\BeamNG.drive.exe"

echo.
echo ===========================================
echo  Server started!
echo  Admin Panel: http://localhost:30815
echo  Game: connect to localhost:30814
echo ===========================================
echo.
echo Press any key to stop server...
pause >nul

:: Stop server
taskkill /f /im "node.exe" >nul 2>&1
echo Server stopped.
