@echo off
echo Installing Online BeamNG mod directly into game directory...
set GAME_DIR=C:\Program Files (x86)\Steam\steamapps\common\BeamNG.drive
set SRC_DIR=%~dp0..\client\mods\OnlineBeamNG

echo Copying extensions...
copy /y "%SRC_DIR%\lua\ge\extensions\*.lua" "%GAME_DIR%\lua\ge\extensions\" >nul

echo Copying vehicle extensions...
if not exist "%GAME_DIR%\lua\vehicle\extensions\OnlineBeamNG" mkdir "%GAME_DIR%\lua\vehicle\extensions\OnlineBeamNG"
copy /y "%SRC_DIR%\lua\vehicle\extensions\OnlineBeamNG\*.lua" "%GAME_DIR%\lua\vehicle\extensions\OnlineBeamNG\" >nul

echo Copying UI modules...
if not exist "%GAME_DIR%\ui\modules\onlineBeamNG" mkdir "%GAME_DIR%\ui\modules\onlineBeamNG"
copy /y "%SRC_DIR%\ui\modules\onlineBeamNG\*" "%GAME_DIR%\ui\modules\onlineBeamNG\" >nul

echo Creating boot loader...
copy /y "%~dp0..\client\mods\OnlineBeamNG\lua\ge\extensions\onlineBeamNG_boot.lua" "%GAME_DIR%\lua\ge\extensions\" >nul

echo Patching main.lua...
powershell -Command "(Get-Content '%GAME_DIR%\lua\ge\main.lua') -replace '''core_audio''', '''onlineBeamNG_boot'', ''core_audio''' | Set-Content '%GAME_DIR%\lua\ge\main.lua'"

echo Done. Mod installed directly into game.
pause
