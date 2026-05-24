param(
    [string]$GamePath = "",
    [switch]$StartLauncher
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Resolve-Path "$scriptDir\.."
$modSource = "$projectDir\client\mods\OnlineBeamNG"

$defaultPaths = @(
    "C:\Program Files (x86)\Steam\steamapps\common\BeamNG.drive",
    "C:\Program Files\BeamNG.drive",
    "$env:ProgramFiles\BeamNG.drive",
    "${env:ProgramFiles(x86)}\Steam\steamapps\common\BeamNG.drive"
)

function Write-Step {
    param([string]$Message, [string]$Status = "INFO")
    $color = @{ INFO = "Cyan"; OK = "Green"; WARN = "Yellow"; ERR = "Red" }
    Write-Host "[$Status] $Message" -ForegroundColor $color[$Status]
}

Write-Host "`n===========================================" -ForegroundColor Cyan
Write-Host "  Online BeamNG.drive - Mod Installer" -ForegroundColor Cyan
Write-Host "===========================================`n" -ForegroundColor Cyan

# Find game
if (-not $GamePath -or -not (Test-Path $GamePath)) {
    $GamePath = $defaultPaths | Where-Object { Test-Path "$_\BeamNG.drive.exe" } | Select-Object -First 1
}

if (-not $GamePath) {
    Write-Step "Game not found automatically." "WARN"
    $GamePath = Read-Host "Enter BeamNG.drive installation path"
    if (-not (Test-Path "$GamePath\BeamNG.drive.exe")) {
        Write-Step "Invalid path: $GamePath" "ERR"
        exit 1
    }
}

Write-Step "Game found: $GamePath" "OK"

$modsDir = "$env:USERPROFILE\Documents\BeamNG.drive\mods"
if (-not (Test-Path $modsDir)) {
    New-Item -ItemType Directory -Path $modsDir -Force | Out-Null
    Write-Step "Created mods directory: $modsDir" "OK"
}

# Copy mod
$modDest = "$modsDir\OnlineBeamNG"
if (Test-Path $modDest) {
    Remove-Item -Recurse -Force $modDest
    Write-Step "Removed old mod version" "INFO"
}

Copy-Item -Recurse -Path $modSource -Destination $modDest
Write-Step "Mod installed to: $modDest" "OK"

# Create launcher script
$launcherPath = "$env:USERPROFILE\Desktop\Online BeamNG Launcher.bat"
$serverDir = Resolve-Path "$projectDir\server"

@"
@echo off
chcp 65001 >nul
title Online BeamNG.drive

echo Starting BeamNG Online Server...
cd /d "$serverDir"
start /min "" cmd /c "npm start & pause"

timeout /t 3 /nobreak >nul

echo Launching BeamNG.drive...
start "" "$GamePath\BeamNG.drive.exe"

echo.
echo Server admin panel: http://localhost:30815
echo Connect in-game to: localhost:30814
echo.
pause
"@ | Set-Content -Path $launcherPath -Encoding ASCII

Write-Step "Launcher created: $launcherPath" "OK"

Write-Host "`n===========================================" -ForegroundColor Cyan
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host "===========================================`n" -ForegroundColor Cyan
Write-Host "  Run 'Online BeamNG Launcher.bat' on desktop" -ForegroundColor White
Write-Host "  or press any key to start now..." -ForegroundColor White
Write-Host "`n===========================================`n" -ForegroundColor Cyan

if ($StartLauncher) {
    Start-Process -FilePath "cmd" -ArgumentList "/c", $launcherPath
}
