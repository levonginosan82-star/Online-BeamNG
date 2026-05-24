param([switch]$Uninstall)

$gameDir = "C:\Program Files (x86)\Steam\steamapps\common\BeamNG.drive"
$srcDir = Join-Path (Split-Path $PSScriptRoot) "client\mods\OnlineBeamNG"
$bootFile = Join-Path $PSScriptRoot "onlineBeamNG_boot.lua"

function Kill-Game {
  Get-Process -Name "BeamNG*" -ErrorAction SilentlyContinue | Stop-Process -Force
  Start-Sleep -Seconds 2
}

function Remove-ModFiles {
  $paths = @(
    "$gameDir\lua\ge\extensions\core_network.lua",
    "$gameDir\lua\ge\extensions\mp_network.lua",
    "$gameDir\lua\ge\extensions\mp_ui.lua",
    "$gameDir\lua\ge\extensions\mp_config.lua",
    "$gameDir\lua\ge\extensions\mp_position_ge.lua",
    "$gameDir\lua\ge\extensions\mp_updates_ge.lua",
    "$gameDir\lua\ge\extensions\mp_vehicle_ge.lua",
    "$gameDir\lua\ge\extensions\onlineBeamNG_boot.lua",
    "$gameDir\lua\ge\extensions\core\network.lua",
    "$gameDir\lua\ge\extensions\mp",
    "$gameDir\lua\ge\extensions\onlineBeamNG",
    "$gameDir\lua\vehicle\extensions\OnlineBeamNG",
    "$gameDir\ui\modules\onlineBeamNG"
  )
  foreach ($p in $paths) { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }
}

function Patch-MainLua {
  $path = "$gameDir\lua\ge\main.lua"
  $content = Get-Content -LiteralPath $path -Raw
  if ($content -notmatch "onlineBeamNG_boot") {
    $content = $content -replace "(local startupExtensions = {)", "`$1`n  'onlineBeamNG_boot',"
    $content | Set-Content -LiteralPath $path -NoNewline
    Write-Output "  main.lua patched"
  } else {
    Write-Output "  main.lua already patched"
  }
}

function Unpatch-MainLua {
  $path = "$gameDir\lua\ge\main.lua"
  $content = Get-Content -LiteralPath $path -Raw
  if ($content -match "'onlineBeamNG_boot',\s*") {
    $content = $content -replace "'onlineBeamNG_boot',\s*", ""
    $content | Set-Content -LiteralPath $path -NoNewline
    Write-Output "  main.lua unpatched"
  }
}

if ($Uninstall) {
  Write-Output "=== Uninstalling Online BeamNG ==="
  Kill-Game
  Unpatch-MainLua
  Remove-ModFiles
  Write-Output "=== DONE ==="
  return
}

Write-Output "=== Installing Online BeamNG ==="
Kill-Game

# 1. Remove old files first
Write-Output "1. Cleaning old files..."
Remove-ModFiles

# 2. Copy extensions to subdirectories
Write-Output "2. Copying extensions..."
New-Item -ItemType Directory -Path "$gameDir\lua\ge\extensions\core" -Force | Out-Null
New-Item -ItemType Directory -Path "$gameDir\lua\ge\extensions\mp" -Force | Out-Null
New-Item -ItemType Directory -Path "$gameDir\lua\ge\extensions\onlineBeamNG" -Force | Out-Null

Copy-Item -LiteralPath "$srcDir\lua\ge\extensions\core_network.lua" -Destination "$gameDir\lua\ge\extensions\core\network.lua" -Force
Copy-Item -LiteralPath "$srcDir\lua\ge\extensions\mp_network.lua" -Destination "$gameDir\lua\ge\extensions\mp\network.lua" -Force
Copy-Item -LiteralPath "$srcDir\lua\ge\extensions\mp_ui.lua" -Destination "$gameDir\lua\ge\extensions\mp\ui.lua" -Force
Copy-Item -LiteralPath "$srcDir\lua\ge\extensions\mp_config.lua" -Destination "$gameDir\lua\ge\extensions\mp\config.lua" -Force
Copy-Item -LiteralPath "$srcDir\lua\ge\extensions\mp_position_ge.lua" -Destination "$gameDir\lua\ge\extensions\mp\position_ge.lua" -Force
Copy-Item -LiteralPath "$srcDir\lua\ge\extensions\mp_updates_ge.lua" -Destination "$gameDir\lua\ge\extensions\mp\updates_ge.lua" -Force
Copy-Item -LiteralPath "$srcDir\lua\ge\extensions\mp_vehicle_ge.lua" -Destination "$gameDir\lua\ge\extensions\mp\vehicle_ge.lua" -Force
Copy-Item -LiteralPath $bootFile -Destination "$gameDir\lua\ge\extensions\onlineBeamNG\boot.lua" -Force
Write-Output "  Done"

# 3. Copy vehicle extensions
Write-Output "3. Copying vehicle extensions..."
Copy-Item -LiteralPath "$srcDir\lua\vehicle\extensions\OnlineBeamNG" -Destination "$gameDir\lua\vehicle\extensions\" -Recurse -Force

# 4. Copy UI modules
Write-Output "4. Copying UI modules..."
Copy-Item -LiteralPath "$srcDir\ui\modules\onlineBeamNG" -Destination "$gameDir\ui\modules\" -Recurse -Force

# 5. Patch main.lua
Write-Output "5. Patching main.lua..."
Patch-MainLua

Write-Output "=== INSTALLATION COMPLETE ==="
Write-Output "Launch BeamNG.drive through Steam."
Write-Output "The Online BeamNG connect window should appear."
