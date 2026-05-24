@echo off
chcp 65001 >nul
title Online BeamNG.drive - Server

echo ===========================================
echo   Online BeamNG.drive - Server Launcher
echo ===========================================
echo.

cd /d "%~dp0..\server"

echo [1/2] Installing dependencies...
call npm install >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] npm install failed
    pause
    exit /b 1
)

echo [2/2] Starting server...
echo.
echo Admin panel: http://localhost:30815
echo Game port:   30814
echo.
npm start
pause
