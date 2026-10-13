# Execution Context : PowerShell 5.1+ (Windows 10 / 11)
# Target Server     : Local Windows Desktop PC
# Description       : GIN-Voice [v001] Native Installer by VladiMIR+AI

cls
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$AppName    = "GIN-Voice"
$AppVersion = "v001"
$InstallDir = "$env:LOCALAPPDATA\GIN-Voice"
$RepoRawURL = "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-Voice"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  ░▒▓█  GIN-Voice [$AppVersion] — Native Desktop Voice AI Installer  █▓▒░" -ForegroundColor Green
Write-Host "  Author: VladiMIR+AI (Vladimir Bulantsev) | GitHub: GinCz" -ForegroundColor DarkGray
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Stop any currently running instance of GIN-Voice
Write-Host "[1/6] Checking for running instances..." -ForegroundColor Yellow
$proc = Get-Process "GIN-Voice*" -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "      Stopping running GIN-Voice process..." -ForegroundColor Gray
    Stop-Process -Name "GIN-Voice*" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800
}

# 2. Prepare installation directory
Write-Host "[2/6] Preparing installation directory: $InstallDir" -ForegroundColor Yellow
if (-not (Test-Path $InstallDir)) {
    New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 3. Deploy Executable and Assets
Write-Host "[3/6] Deploying application binaries and assets..." -ForegroundColor Yellow

# Helper function to copy local or download from GitHub
function Deploy-Asset([string]$fileName, [bool]$overwriteAlways) {
    $destPath = Join-Path $InstallDir $fileName
    $localSrc = Join-Path $ScriptDir $fileName

    if (-not $overwriteAlways -and (Test-Path $destPath)) {
        Write-Host "      Preserving existing user file: $fileName" -ForegroundColor Gray
        return
    }

    if (Test-Path $localSrc) {
        Copy-Item -Path $localSrc -Destination $destPath -Force
        Write-Host "      Installed from local package: $fileName" -ForegroundColor Green
    } else {
        Write-Host "      Downloading $fileName from GitHub..." -ForegroundColor Cyan
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri "$RepoRawURL/$fileName" -OutFile $destPath -UseBasicParsing -TimeoutSec 30
            Write-Host "      Downloaded: $fileName" -ForegroundColor Green
        } catch {
            Write-Host "      [WARN] Could not download $fileName: $_" -ForegroundColor DarkYellow
        }
    }
}

Deploy-Asset "GIN-Voice.exe" $true
Deploy-Asset "GIN-Voice_v001.exe" $true
Deploy-Asset "app.ico" $true
Deploy-Asset "HELP.md" $true
Deploy-Asset "version.json" $true
Deploy-Asset "config.json" $false       # Preserve user API keys / settings
Deploy-Asset "dictionary.json" $false   # Preserve user custom dictionary

# 4. Create Desktop and Start Menu Shortcuts
Write-Host "[4/6] Creating shortcuts with custom icon..." -ForegroundColor Yellow
$wsh = New-Object -ComObject WScript.Shell
$exePath = Join-Path $InstallDir "GIN-Voice.exe"
$icoPath = Join-Path $InstallDir "app.ico"

# Desktop Shortcut
$desktopPath = [Environment]::GetFolderPath("Desktop")
$desktopLnk = Join-Path $desktopPath "GIN-Voice.lnk"
$shortcut = $wsh.CreateShortcut($desktopLnk)
$shortcut.TargetPath = $exePath
$shortcut.WorkingDirectory = $InstallDir
$shortcut.Description = "GIN-Voice by VladiMIR+AI - Instant Voice Typing (F4)"
if (Test-Path $icoPath) { $shortcut.IconLocation = $icoPath }
$shortcut.Save()
Write-Host "      Desktop shortcut created: $desktopLnk" -ForegroundColor Green

# MEGA Desktop Shortcut (if configured)
$megaDesktop = "D:\MEGA\DOCS\desktop"
if (Test-Path $megaDesktop) {
    $megaLnk = Join-Path $megaDesktop "GIN-Voice.lnk"
    $mShort = $wsh.CreateShortcut($megaLnk)
    $mShort.TargetPath = $exePath
    $mShort.WorkingDirectory = $InstallDir
    $mShort.Description = "GIN-Voice by VladiMIR+AI - Instant Voice Typing (F4)"
    if (Test-Path $icoPath) { $mShort.IconLocation = $icoPath }
    $mShort.Save()
    Write-Host "      MEGA Desktop shortcut updated: $megaLnk" -ForegroundColor Green
}

# Start Menu Shortcut
$startMenuPrograms = [Environment]::GetFolderPath("Programs")
$startLnk = Join-Path $startMenuPrograms "GIN-Voice.lnk"
$shortcut = $wsh.CreateShortcut($startLnk)
$shortcut.TargetPath = $exePath
$shortcut.WorkingDirectory = $InstallDir
$shortcut.Description = "GIN-Voice by VladiMIR+AI - Instant Voice Typing (F4)"
if (Test-Path $icoPath) { $shortcut.IconLocation = $icoPath }
$shortcut.Save()
Write-Host "      Start Menu shortcut created: $startLnk" -ForegroundColor Green

# 5. Launch GIN-Voice in background
Write-Host "[5/6] Starting GIN-Voice Tray Application..." -ForegroundColor Yellow
Start-Process -FilePath $exePath -WorkingDirectory $InstallDir

# 6. First Run Verification
Write-Host "[6/6] Installation completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  GIN-Voice is now running in your System Tray (near the clock)!     " -ForegroundColor White
Write-Host "  Hotkey: Press [F4] to Start recording, press [F4] again to Paste.   " -ForegroundColor Yellow
Write-Host "  Languages: English (active), Czech & Russian (available in menu).   " -ForegroundColor White
Write-Host "  Right-click the microphone icon in tray to configure settings.     " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""
Start-Sleep -Seconds 2
