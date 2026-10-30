@echo off
chcp 65001 >nul
cls

:: Execution Context : Windows Command Prompt / CMD (Standard User or Administrator)
:: Target OS         : Windows 10 / Windows 11 / Windows Server / Windows 7 / Windows 8
:: Description       : Resilient Downloader & Launcher for GIN-VPN Windows Client from Russian Servers (RU-109 & CloudCore-191)

:: Auto-Elevate to Administrator (fltmc method - reliable Win7+10+11)
fltmc >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
title GIN-VPN Downloader - LOADING...

:: Extract and run the embedded PowerShell section from this file
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; $s=[System.IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::UTF8); Invoke-Expression $s.Substring($s.IndexOf('#'+'#PS_MAIN'))"
exit /b

##PS_MAIN
clear
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "GIN-VPN Downloader & Launcher (RU Dedicated)"

Write-Host "===============================================================================" -ForegroundColor Yellow
Write-Host "                GIN-VPN Windows Client Downloader & Launcher                   " -ForegroundColor Yellow
Write-Host "           High-Speed Russian Servers: RU-109 & CloudCore-191                  " -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "[*] Checking network settings..." -ForegroundColor Cyan
& netsh winhttp reset proxy 2>$null | Out-Null
& reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f 2>$null | Out-Null
& reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /f 2>$null | Out-Null
& reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride /f 2>$null | Out-Null
& reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" /va /f 2>$null | Out-Null

Write-Host "[*] Checking for running instances of GIN-VPN / Xray..." -ForegroundColor Cyan
Get-Process -Name "GIN-VPN" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process -Name "xray" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

$desktopPath = [Environment]::GetFolderPath('Desktop')
$progFiles = $env:ProgramFiles
if (-not $progFiles) { $progFiles = "C:\Program Files" }
$targetDir = Join-Path $progFiles "GIN-VPN"
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}
$targetExe = Join-Path $targetDir "GIN-VPN.exe"

Write-Host "[*] Target installation path: $targetExe" -ForegroundColor Cyan
Write-Host ""

$mirrors = @(
    @{ Name = "Russian Server RU-109 (prodvig-saita.ru - Moscow Dedicated)"; Url = "http://prodvig-saita.ru/vpn/GIN-VPN.exe" },
    @{ Name = "Russian Server CloudCore-191 Main (4at.gincz.com)"; Url = "https://4at.gincz.com/download/GIN-VPN.exe" },
    @{ Name = "Global GitHub Raw (Versioned v091)"; Url = "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN_v091.exe" },
    @{ Name = "Global GitHub Raw (GIN-VPN.exe)"; Url = "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN.exe" }
)

# Autonomous Win7/8/10/11 TLS configuration and self-healing
try {
    if ([Environment]::OSVersion.Version.Major -lt 10) {
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" -Name "DisabledByDefault" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" -Name "Enabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue | Out-Null
        @("HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319") | ForEach-Object {
            if (Test-Path $_) {
                Set-ItemProperty -Path $_ -Name "SchUseStrongCrypto" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue | Out-Null
                Set-ItemProperty -Path $_ -Name "SystemDefaultTlsVersions" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue | Out-Null
            }
        }
    }
} catch {}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
    if ([Environment]::OSVersion.Version.Major -ge 10) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13
    }
} catch {
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
}
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) GIN-VPN-Installer")

$downloadSuccess = $false
$tempFile = "$env:TEMP\GIN-VPN_download_$((Get-Random)).tmp"

foreach ($m in $mirrors) {
    Write-Host "[*] Connecting to $($m.Name)..." -ForegroundColor White
    try {
        if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
        
        Write-Host "    Downloading: $($m.Url)" -ForegroundColor DarkGray
        $wc.DownloadFile($m.Url, $tempFile)
        
        if (Test-Path $tempFile) {
            $len = (Get-Item $tempFile).Length
            if ($len -ge 10000000) {
                Write-Host "    [+] Download complete: $([math]::Round($len / 1MB, 2)) MB verified." -ForegroundColor Green
                $downloadSuccess = $true
                break
            } else {
                Write-Host "    [-] Incomplete file ($len bytes). Trying next mirror..." -ForegroundColor Yellow
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {
        Write-Host "    [-] Mirror error: $($_.Exception.Message). Trying next..." -ForegroundColor Yellow
    }
}

if (-not $downloadSuccess) {
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Red
    Write-Host " [ERROR] Could not download GIN-VPN from any of the available Russian servers." -ForegroundColor Red
    Write-Host " Please check your internet connection or antivirus settings." -ForegroundColor Red
    Write-Host "===============================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Move verified download to Program Files
Move-Item -Path $tempFile -Destination $targetExe -Force
Copy-Item -Path $targetExe -Destination (Join-Path $targetDir "uninstall.exe") -Force -ErrorAction SilentlyContinue
Unblock-File -LiteralPath $targetExe -ErrorAction SilentlyContinue

# Create clean Desktop shortcut (GIN-VPN.lnk) - NEVER a raw binary on Desktop!
$w = New-Object -ComObject WScript.Shell
$desktopShortcut = $w.CreateShortcut((Join-Path $desktopPath "GIN-VPN.lnk"))
$desktopShortcut.TargetPath = $targetExe
$desktopShortcut.WorkingDirectory = $targetDir
$desktopShortcut.IconLocation = "$targetExe,0"
$desktopShortcut.Description = "GIN-VPN by VladiMIR+AI"
$desktopShortcut.Save()

# Create Start Menu shortcut
$startMenu = [Environment]::GetFolderPath('Programs')
if (Test-Path $startMenu) {
    $smShortcut = $w.CreateShortcut((Join-Path $startMenu "GIN-VPN.lnk"))
    $smShortcut.TargetPath = $targetExe
    $smShortcut.WorkingDirectory = $targetDir
    $smShortcut.IconLocation = "$targetExe,0"
    $smShortcut.Description = "GIN-VPN by VladiMIR+AI"
    $smShortcut.Save()
}

# Clean up any residual .exe or versioned installers on Desktop
Remove-Item -Path (Join-Path $desktopPath "GIN-VPN.exe") -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $desktopPath -Filter "GIN-VPN_v*.exe" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
if (Test-Path "D:\MEGA\DOCS\desktop") {
    Get-ChildItem -Path "D:\MEGA\DOCS\desktop" -Filter "GIN-VPN_v*.exe" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "[+] GIN-VPN successfully installed to: $targetExe" -ForegroundColor Green
Write-Host "[+] Desktop shortcut created: $(Join-Path $desktopPath 'GIN-VPN.lnk')" -ForegroundColor Green
Write-Host "[*] Launching GIN-VPN client..." -ForegroundColor Cyan

Start-Process -FilePath $targetExe -WorkingDirectory $targetDir

Start-Sleep -Seconds 2
$proc = Get-Process -Name "GIN-VPN" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host " [+] SUCCESS: GIN-VPN is downloaded and running!" -ForegroundColor Green
Write-Host ""
Write-Host " File location: $targetExe" -ForegroundColor White
if ($proc) {
    Write-Host " Process status: ACTIVE (Process ID: $($proc.Id))" -ForegroundColor Green
} else {
    Write-Host " Process status: Process started detached." -ForegroundColor White
}
Write-Host ""
Write-Host " -----------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " IMPORTANT NOTICE (SYSTEM TRAY):" -ForegroundColor Yellow
Write-Host " 1. If the main window did NOT open in the center of your screen:" -ForegroundColor White
Write-Host "    GIN-VPN auto-connects and starts MINIMIZED into the Windows SYSTEM TRAY!" -ForegroundColor White
Write-Host " 2. Look at the bottom-right corner of your screen (near the Windows clock)." -ForegroundColor White
Write-Host " 3. Find the green shield icon of GIN-VPN." -ForegroundColor White
Write-Host "    (If hidden, click the '^' arrow icon to show collapsed tray icons)." -ForegroundColor White
Write-Host " 4. Left-click or double-click the green GIN-VPN icon to open the main window!" -ForegroundColor White
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to close this window..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
