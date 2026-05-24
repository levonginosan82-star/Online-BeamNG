@echo off
setlocal enabledelayedexpansion
echo ============================================
echo Installing Online BeamNG Mod
echo ============================================
echo.

set GAME_DIR=C:\Program Files (x86)\Steam\steamapps\common\BeamNG.drive
set SRC_DIR=%~dp0..\client\mods\OnlineBeamNG

echo Killing game processes...
taskkill /f /im BeamNG.drive.x64.exe 2>nul
taskkill /f /im BeamNG.drive.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo 1. Copying extension files to subdirectories...
if not exist "%GAME_DIR%\lua\ge\extensions\core" mkdir "%GAME_DIR%\lua\ge\extensions\core"
if not exist "%GAME_DIR%\lua\ge\extensions\mp" mkdir "%GAME_DIR%\lua\ge\extensions\mp"
if not exist "%GAME_DIR%\lua\ge\extensions\onlineBeamNG" mkdir "%GAME_DIR%\lua\ge\extensions\onlineBeamNG"

copy /y "%SRC_DIR%\lua\ge\extensions\core_network.lua" "%GAME_DIR%\lua\ge\extensions\core\network.lua" >nul
copy /y "%SRC_DIR%\lua\ge\extensions\mp_network.lua" "%GAME_DIR%\lua\ge\extensions\mp\network.lua" >nul
copy /y "%SRC_DIR%\lua\ge\extensions\mp_ui.lua" "%GAME_DIR%\lua\ge\extensions\mp\ui.lua" >nul
copy /y "%SRC_DIR%\lua\ge\extensions\mp_config.lua" "%GAME_DIR%\lua\ge\extensions\mp\config.lua" >nul
copy /y "%SRC_DIR%\lua\ge\extensions\mp_position_ge.lua" "%GAME_DIR%\lua\ge\extensions\mp\position_ge.lua" >nul
copy /y "%SRC_DIR%\lua\ge\extensions\mp_updates_ge.lua" "%GAME_DIR%\lua\ge\extensions\mp\updates_ge.lua" >nul
copy /y "%SRC_DIR%\lua\ge\extensions\mp_vehicle_ge.lua" "%GAME_DIR%\lua\ge\extensions\mp\vehicle_ge.lua" >nul
copy /y "%~dp0onlineBeamNG_boot.lua" "%GAME_DIR%\lua\ge\extensions\onlineBeamNG\boot.lua" >nul

echo 2. Copying vehicle extensions...
if not exist "%GAME_DIR%\lua\vehicle\extensions\OnlineBeamNG" mkdir "%GAME_DIR%\lua\vehicle\extensions\OnlineBeamNG"
copy /y "%SRC_DIR%\lua\vehicle\extensions\OnlineBeamNG\*.lua" "%GAME_DIR%\lua\vehicle\extensions\OnlineBeamNG\" >nul

echo 3. Copying UI modules...
if not exist "%GAME_DIR%\ui\modules\onlineBeamNG" mkdir "%GAME_DIR%\ui\modules\onlineBeamNG"
copy /y "%SRC_DIR%\ui\modules\onlineBeamNG\*" "%GAME_DIR%\ui\modules\onlineBeamNG\" >nul

echo 4. Removing old flat files (if any)...
del /f /q "%GAME_DIR%\lua\ge\extensions\core_network.lua" 2>nul
del /f /q "%GAME_DIR%\lua\ge\extensions\mp_network.lua" 2>nul
del /f /q "%GAME_DIR%\lua\ge\extensions\mp_ui.lua" 2>nul
del /f /q "%GAME_DIR%\lua\ge\extensions\mp_config.lua" 2>nul
del /f /q "%GAME_DIR%\lua\ge\extensions\mp_position_ge.lua" 2>nul
del /f /q "%GAME_DIR%\lua\ge\extensions\mp_updates_ge.lua" 2>nul
del /f /q "%GAME_DIR%\lua\ge\extensions\mp_vehicle_ge.lua" 2>nul
del /f /q "%GAME_DIR%\lua\ge\extensions\onlineBeamNG_boot.lua" 2>nul

echo 5. Patching main.lua...
powershell -NoProfile -Command "(Get-Content '%GAME_DIR%\lua\ge\main.lua') -replace '''local startupExtensions = {''', '''local startupExtensions = {\n  ''onlineBeamNG_boot'',''' | Set-Content '%GAME_DIR%\lua\ge\main.lua'"

echo.
echo ============================================
echo Installation complete!
echo Launch BeamNG.drive through Steam.
echo The connect window should appear automatically.
echo ============================================
pause
