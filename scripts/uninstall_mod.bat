@echo off
echo Uninstalling Online BeamNG mod from game directory...
set GAME_DIR=C:\Program Files (x86)\Steam\steamapps\common\BeamNG.drive

echo Removing extensions...
del /f /q "%GAME_DIR%\lua\ge\extensions\core_network.lua" 2>nul
del /f /q "%GAME_DIR%\lua\ge\extensions\mp_network.lua" 2>nul
del /f /q "%GAME_DIR%\lua\ge\extensions\mp_ui.lua" 2>nul
del /f /q "%GAME_DIR%\lua\ge\extensions\mp_config.lua" 2>nul
del /f /q "%GAME_DIR%\lua\ge\extensions\mp_position_ge.lua" 2>nul
del /f /q "%GAME_DIR%\lua\ge\extensions\mp_updates_ge.lua" 2>nul
del /f /q "%GAME_DIR%\lua\ge\extensions\mp_vehicle_ge.lua" 2>nul
del /f /q "%GAME_DIR%\lua\ge\extensions\onlineBeamNG_boot.lua" 2>nul

echo Removing vehicle extensions...
rmdir /s /q "%GAME_DIR%\lua\vehicle\extensions\OnlineBeamNG" 2>nul

echo Removing UI modules...
rmdir /s /q "%GAME_DIR%\ui\modules\onlineBeamNG" 2>nul

echo Unpatching main.lua...
powershell -Command "(Get-Content '%GAME_DIR%\lua\ge\main.lua') -replace '''onlineBeamNG_boot'',\s*''', ''''' | Set-Content '%GAME_DIR%\lua\ge\main.lua'"

echo Removing mod files from Documents...
del /f /q "%USERPROFILE%\Documents\BeamNG.drive\mods\OnlineBeamNG.zip" 2>nul
rmdir /s /q "%USERPROFILE%\Documents\BeamNG.drive\mods\unpacked\OnlineBeamNG" 2>nul

echo Done. Mod uninstalled.
pause
