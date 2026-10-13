# ==========================================================================================
# Execution Context : PowerShell 5.1+ (Windows Desktop)
# Target Application: GIN-Voice
# Description       : Clean Uninstaller for GIN-Voice by VladiMIR+AI
# ==========================================================================================

$Host.UI.RawUI.WindowTitle = "GIN-Voice Clean Uninstaller by VladiMIR+AI"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

$Line90 = "=" * 90

Write-Host $Line90 -ForegroundColor Cyan
Write-Host "   GIN-Voice by VladiMIR+AI — Clean Uninstaller" -ForegroundColor Cyan
Write-Host "   Fast Multilingual Voice Typing Tool for Windows 10/11" -ForegroundColor Gray
Write-Host $Line90 -ForegroundColor Cyan
Write-Host ""

# 1. Stopping processes
Write-Host "[1/4] Stopping all active GIN-Voice background processes..." -ForegroundColor Green
Get-Process -Name "GIN-Voice*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Stop-Process -Name "GIN-Voice" -Force -ErrorAction SilentlyContinue
Start-Process "taskkill.exe" -ArgumentList "/F /IM GIN-Voice.exe /T" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
Start-Process "taskkill.exe" -ArgumentList "/F /FI `"IMAGENAME eq GIN-Voice*`"" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 800
Write-Host "      Done. Processes terminated." -ForegroundColor Gray
Write-Host ""

# 2. Removing shortcuts (preserving installer binaries on Desktop/MEGA)
Write-Host "[2/4] Removing desktop, start menu, and cloud shortcuts..." -ForegroundColor Green
$shortcuts = @(
    "$([Environment]::GetFolderPath('Desktop'))\GIN-Voice.lnk",
    "$([Environment]::GetFolderPath('Programs'))\GIN-Voice.lnk",
    "$([Environment]::GetFolderPath('Programs'))\Uninstall GIN-Voice.lnk",
    "$([Environment]::GetFolderPath('Programs'))\GIN-Voice",
    "D:\MEGA\DOCS\desktop\GIN-Voice.lnk"
)
foreach ($sc in $shortcuts) {
    if (Test-Path $sc) {
        Remove-Item -Path $sc -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "      Removed: $sc" -ForegroundColor Gray
    }
}
Write-Host ""

# 3. Cleaning Windows Registry
Write-Host "[3/4] Cleaning Windows Autostart and Registry entries..." -ForegroundColor Green
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "GIN-Voice" -ErrorAction SilentlyContinue
Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Voice" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "HKCU:\Software\GIN-Voice" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "      Done. Registry cleaned." -ForegroundColor Gray
Write-Host ""

# 4. Removing installation folder
Write-Host "[4/4] Removing application directory and local data..." -ForegroundColor Green
$localApp = [Environment]::GetFolderPath('LocalApplicationData')
$appDir = Join-Path $localApp "GIN-Voice"
$tempDir = [System.IO.Path]::GetTempPath()

if (Test-Path $appDir) {
    Get-ChildItem -Path $appDir -Exclude "uninstall.ps1" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "      Done. Application folder cleared." -ForegroundColor Gray
Write-Host ""

Write-Host $Line90 -ForegroundColor Green
Write-Host "   GIN-Voice was successfully and completely uninstalled from your system!" -ForegroundColor Green
Write-Host $Line90 -ForegroundColor Green
Write-Host ""
Write-Host "This window will close automatically in 3 seconds..." -ForegroundColor Gray

# Write detached self-cleanup batch in %TEMP%
$cleanBat = Join-Path $tempDir "gin_ps1_cleanup.bat"
$cleanContent = "@echo off`r`ncd /d `"$tempDir`"`r`nping -n 3 127.0.0.1 >nul`r`nrd /s /q `"$appDir`" 2>nul`r`ndel `"%~f0`" 2>nul`r`n"
[System.IO.File]::WriteAllText($cleanBat, $cleanContent)

Start-Process -FilePath "cmd.exe" -ArgumentList "/c start /b `"$cleanBat`"" -WorkingDirectory $tempDir -WindowStyle Hidden
Start-Sleep -Seconds 3
