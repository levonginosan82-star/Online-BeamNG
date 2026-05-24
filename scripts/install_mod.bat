@echo off
chcp 65001 >nul
title Online BeamNG.drive - Install Mod

echo ===========================================
echo  Online BeamNG.drive - Mod Installer
echo ===========================================
echo.

:: Detect paths
set "GAME_DIR=C:\Program Files (x86)\Steam\steamapps\common\BeamNG.drive"
set "MODS_DIR=%USERPROFILE%\Documents\BeamNG.drive\mods"
set "MOD_SOURCE=%~dp0..\client\mods\OnlineBeamNG"
set "MOD_DEST=%MODS_DIR%\OnlineBeamNG"

:: Check game exists
if not exist "%GAME_DIR%\BeamNG.drive.exe" (
    echo [WARNING] Game not found at: %GAME_DIR%
    echo Enter your BeamNG.drive installation path:
    set /p GAME_DIR="Path: "
    if "!GAME_DIR!"=="" set "GAME_DIR=C:\Program Files (x86)\Steam\steamapps\common\BeamNG.drive"
)

:: Create mods dir if not exists
if not exist "%MODS_DIR%" mkdir "%MODS_DIR%"

:: Copy mod
echo Copying mod to "%MOD_DEST%"...
if exist "%MOD_DEST%" (
    echo Removing old version...
    rmdir /s /q "%MOD_DEST%"
)
xcopy /e /i /q "%MOD_SOURCE%" "%MOD_DEST%" >nul
echo [OK] Mod installed!

:: Create launcher shortcut
set "SHORTCUT=%USERPROFILE%\Desktop\Online BeamNG Launcher.bat"
echo Creating launcher: %SHORTCUT%
(
echo @echo off
echo chcp 65001 ^>nul
echo title Online BeamNG.drive
echo.
echo echo Starting BeamNG Online Server...
echo start /min "" "%~dp0..\server\dist\index.js" ^|^| ^(
echo   cd /d "%~dp0..\server"
echo   start /min "" cmd /c "npm start ^& pause"
echo ^)
echo.
echo timeout /t 2 /nobreak ^>nul
echo.
echo echo Launching BeamNG.drive...
echo start "" "%GAME_DIR%\BeamNG.drive.exe"
echo.
echo echo.
echo echo Server started! Open http://localhost:30815 in your browser.
echo pause
) > "%SHORTCUT%"

echo.
echo ===========================================
echo  Installation complete!
echo ===========================================
echo.
echo  Launcher: Desktop\Online BeamNG Launcher.bat
echo  Admin UI: http://localhost:30815
echo.
echo  To start manually:
echo    1. cd server ^&^& npm start
echo    2. Launch BeamNG.drive
echo    3. Connect to 127.0.0.1:30814
echo.
pause
