@echo off
chcp 65001 >nul
cls

:: Auto-Elevate to Administrator (fltmc method - reliable Win7+10+11)
fltmc >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
title XRAY VPN Installer - LOADING...

for /L %%i in (1,1,4) do echo.
powershell -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; Write-Host ' [POWERSHELL STARTING...]' -ForegroundColor DarkGray"
for /L %%i in (1,1,3) do echo.

:: Extract and run the embedded PowerShell section from this file
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; $s=[System.IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::UTF8); Invoke-Expression $s.Substring($s.IndexOf('#'+'#PS_MAIN'))"
exit /b

##PS_MAIN
clear
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "XRAY VPN Installer - EXECUTE"

Write-Host '==========================================================================================' -ForegroundColor Yellow
Write-Host ''
Write-Host '                       X R A Y   V P N   I N S T A L L E R' -ForegroundColor Yellow
Write-Host '                            Windows 10 / 11' -ForegroundColor DarkGray
Write-Host ''
Write-Host '==========================================================================================' -ForegroundColor Yellow
Write-Host ''

Write-Host '[*] Resetting proxy settings...' -ForegroundColor Cyan
& netsh winhttp reset proxy | Out-Null
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f | Out-Null

Write-Host '[*] Downloading installer script from server...' -ForegroundColor Cyan
try {
    (New-Object Net.WebClient).DownloadFile('http://prodvig-saita.ru/vpn/install.ps1', "$env:TEMP\xray_install.ps1")
    # Remove Windows 7 references for Windows 10/11
    $inst = [System.IO.File]::ReadAllText("$env:TEMP\xray_install.ps1", [System.Text.Encoding]::UTF8)
    $inst = $inst.Replace('Windows 7 Xray Core', 'Xray Core')
    $inst = $inst.Replace('WINDOWS 7 / 10 / 11', 'WINDOWS 10 / 11')
    [System.IO.File]::WriteAllText("$env:TEMP\xray_install.ps1", $inst, [System.Text.Encoding]::UTF8)
} catch {
    Write-Host "[ERROR] Download failed: $_" -ForegroundColor Red
    Start-Sleep -Seconds 5
    exit 1
}

Write-Host '[*] Running installer...' -ForegroundColor Cyan
& "$env:TEMP\xray_install.ps1"
Remove-Item "$env:TEMP\xray_install.ps1" -Force -ErrorAction SilentlyContinue

# Save original external IP and Country Code before VPN connects
try {
    $rawOrig = (New-Object Net.WebClient).DownloadString('http://ip-api.com/line/?fields=query,countryCode').Trim()
    $origLines = $rawOrig -split "?
"
    $ipFound = ""
    $codeFound = ""
    foreach ($l in $origLines) {
        $t = $l.Trim()
        if ($t -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') { $ipFound = $t }
        elseif ($t -match '^[A-Za-z]{2}$') { $codeFound = $t.ToUpper() }
    }
    if ($ipFound) {
        [System.IO.File]::WriteAllLines("C:\XRAY_VPN\orig_ip.txt", @($ipFound, $codeFound), [System.Text.Encoding]::UTF8)
    }
} catch {}

# Deploy enhanced TrayVPN
$trayScript = @'
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

$baseDir = "C:\XRAY_VPN"
$linkFile = "$baseDir\link.txt"
$origIpFile = "$baseDir\orig_ip.txt"
$errorFile = "$baseDir\error.txt"
$logFile = "$baseDir\vpn.log"

# Parse Profile Name from link.txt
$profileName = ""
if (Test-Path $linkFile) {
    try {
        $linkContent = [System.IO.File]::ReadAllText($linkFile, [System.Text.Encoding]::UTF8).Trim()
        if ($linkContent -match "#(.*)$") {
            $profileName = [System.Uri]::UnescapeDataString($matches[1].Trim())
        }
    } catch {}
}
if (-not $profileName) { $profileName = $env:USERNAME }

# Extract short user name for tooltip (e.g. 4er-33-VladiMIR -> VladiMIR)
$shortName = if ($profileName -match "[-_]") { ($profileName -split "[-_]")[-1] } else { $profileName }

# Read Original IP and Country Code
$origIp = "Unknown"
$origCode = ""
if (Test-Path $origIpFile) {
    try {
        $origLines = [System.IO.File]::ReadAllLines($origIpFile, [System.Text.Encoding]::UTF8)
        foreach ($l in $origLines) {
            $t = $l.Trim()
            if ($t -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') { $origIp = $t }
            elseif ($t -match '^[A-Za-z]{2}$') { $origCode = $t.ToUpper() }
        }
    } catch {}
}

# Icon generator: Green, Orange, Red shield with thin black outline
function Get-ShieldIcon([string]$colorName) {
    $grid = @(
        "................",
        "..############..",
        ".#HHHHHHHHHHHH#.",
        ".#HGGGGGGGGGGH#.",
        ".#HGGGGGGGGGGH#.",
        ".#HGGGGGGGGGGH#.",
        ".#HGGGGGGGGGGH#.",
        ".#HGGGGGGGGGGH#.",
        "..#HGGGGGGGGH#..",
        "..#HGGGGGGGGH#..",
        "...#HGGGGGGH#...",
        "...#HGGGGGGH#...",
        "....#HGGGGH#....",
        ".....#HGGH#.....",
        "......#HH#......",
        ".......##......."
    )
    $bmp = New-Object System.Drawing.Bitmap 16, 16, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $T = [System.Drawing.Color]::Transparent
    $B = [System.Drawing.Color]::FromArgb(255, 12, 28, 12)
    
    $mainColor = switch ($colorName) {
        "Green"  { [System.Drawing.Color]::FromArgb(255, 0, 205, 50) }
        "Red"    { [System.Drawing.Color]::FromArgb(255, 225, 25, 25) }
        default  { [System.Drawing.Color]::FromArgb(255, 240, 150, 0) } # Orange
    }
    $highColor = switch ($colorName) {
        "Green"  { [System.Drawing.Color]::FromArgb(255, 65, 245, 95) }
        "Red"    { [System.Drawing.Color]::FromArgb(255, 255, 95, 95) }
        default  { [System.Drawing.Color]::FromArgb(255, 255, 205, 60) }
    }
    
    for ($y = 0; $y -lt 16; $y++) {
        $row = $grid[$y]
        for ($x = 0; $x -lt 16; $x++) {
            $c = switch ($row[$x]) {
                '#' { $B }
                'H' { $highColor }
                'G' { $mainColor }
                default { $T }
            }
            if ($c -ne $T) { $bmp.SetPixel($x, $y, $c) }
        }
    }
    return [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
}

$iconGreen  = Get-ShieldIcon "Green"
$iconOrange = Get-ShieldIcon "Orange"
$iconRed    = Get-ShieldIcon "Red"

$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = $iconOrange
$notify.Visible = $true

# Initial Tooltip
$notify.Text = "Xray VPN: Connecting...`n$shortName"

# Context Menu
$menu = New-Object System.Windows.Forms.ContextMenu
$mStatus = New-Object System.Windows.Forms.MenuItem "Xray VPN: Connecting..."
$mStatus.Enabled = $false
$mProfile = New-Object System.Windows.Forms.MenuItem "ID: $profileName"
$mProfile.Enabled = $false
$mSep1 = New-Object System.Windows.Forms.MenuItem "-"
$mEditLink = New-Object System.Windows.Forms.MenuItem "Edit VLESS Key (link.txt)"
$mEditLink.add_Click({ Start-Process "notepad.exe" -ArgumentList "`"$linkFile`"" })
$mViewLog = New-Object System.Windows.Forms.MenuItem "View Log (vpn.log)"
$mViewLog.add_Click({ if (Test-Path $logFile) { Start-Process "notepad.exe" -ArgumentList "`"$logFile`"" } })
$mRestart = New-Object System.Windows.Forms.MenuItem "Restart VPN"
$mRestart.add_Click({ Start-Process "wscript.exe" -ArgumentList "`"$baseDir\Start_VPN.vbs`"" -WindowStyle Hidden })
$mSep2 = New-Object System.Windows.Forms.MenuItem "-"
$mStop = New-Object System.Windows.Forms.MenuItem "Disconnect && Exit"
$mStop.add_Click({
    $notify.Visible = $false
    $notify.Dispose()
    Start-Process "wscript.exe" -ArgumentList "`"$baseDir\Stop_VPN.vbs`"" -WindowStyle Hidden
    [System.Windows.Forms.Application]::Exit()
})

[void]$menu.MenuItems.Add($mStatus)
[void]$menu.MenuItems.Add($mProfile)
[void]$menu.MenuItems.Add($mSep1)
[void]$menu.MenuItems.Add($mEditLink)
[void]$menu.MenuItems.Add($mViewLog)
[void]$menu.MenuItems.Add($mRestart)
[void]$menu.MenuItems.Add($mSep2)
[void]$menu.MenuItems.Add($mStop)
$notify.ContextMenu = $menu

# State tracker
$script:lastState = "Connecting"
$script:vpnIp = ""
$script:vpnCode = ""

function Set-SafeTooltip([string]$line1, [string]$line2, [string]$line3) {
    $t = "$line1`n$line2`n$line3"
    if ($t.Length -gt 63) {
        $t = $t.Substring(0, 60) + "..."
    }
    $notify.Text = $t
}

# Double-click balloon with full details
$notify.add_DoubleClick({
    if ($script:lastState -eq "Connected") {
        $msg = "VPN: $script:vpnIp ($script:vpnCode)`nOrig: $origIp ($origCode)`nProfile: $profileName"
        $notify.ShowBalloonTip(4000, "Xray VPN: Connected", $msg, [System.Windows.Forms.ToolTipIcon]::Info)
    } elseif ($script:lastState -eq "Error") {
        $errMsg = "Connection failed. Please check your VLESS key in link.txt or network."
        if (Test-Path $errorFile) {
            try { $errMsg = [System.IO.File]::ReadAllText($errorFile).Trim() } catch {}
        }
        $notify.ShowBalloonTip(5000, "Xray VPN: Error", $errMsg, [System.Windows.Forms.ToolTipIcon]::Error)
    } else {
        $notify.ShowBalloonTip(3000, "Xray VPN", "Connecting to $profileName...", [System.Windows.Forms.ToolTipIcon]::Warning)
    }
})

# Connection & IP resolution timer
$ipTimer = New-Object System.Windows.Forms.Timer
$ipTimer.Interval = 1500
$script:checkAttempts = 0

$ipTimer.add_Tick({
    # Check if explicit error file exists
    if (Test-Path $errorFile) {
        $errMsg = "Error in link.txt"
        try { $errMsg = [System.IO.File]::ReadAllText($errorFile).Trim() } catch {}
        $notify.Icon = $iconRed
        $mStatus.Text = "Status: Error"
        Set-SafeTooltip "VPN: Error" $errMsg $shortName
        if ($script:lastState -ne "Error") {
            $script:lastState = "Error"
            $notify.ShowBalloonTip(5000, "Xray VPN: Error", $errMsg, [System.Windows.Forms.ToolTipIcon]::Error)
        }
        return
    }

    # Check if xray process is alive
    $proc = Get-Process xray -ErrorAction SilentlyContinue
    if (-not $proc) {
        $script:checkAttempts++
        if ($script:checkAttempts -ge 4) {
            $notify.Icon = $iconRed
            $mStatus.Text = "Status: Disconnected"
            Set-SafeTooltip "VPN: Disconnected" "Xray process not running" $shortName
            if ($script:lastState -ne "Error") {
                $script:lastState = "Error"
                $notify.ShowBalloonTip(5000, "Xray VPN: Stopped", "Xray process stopped. Right-click to view log or restart.", [System.Windows.Forms.ToolTipIcon]::Error)
            }
        }
        return
    }

    # Query IP and Country Code through proxy
    try {
        $wc = New-Object Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $raw = $wc.DownloadString("http://ip-api.com/line/?fields=query,countryCode").Trim()
        $lines = $raw -split "`r?`n"
        $ipFound = ""
        $codeFound = ""
        foreach ($l in $lines) {
            $t = $l.Trim()
            if ($t -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') { $ipFound = $t }
            elseif ($t -match '^[A-Za-z]{2}$') { $codeFound = $t.ToUpper() }
        }
        
        if ($ipFound) {
            $script:vpnIp   = $ipFound
            $script:vpnCode = $codeFound
            
            # Switch to Green Shield
            $notify.Icon = $iconGreen
            $mStatus.Text = "VPN: $script:vpnIp ($script:vpnCode)"
            $ipTimer.Interval = 30000 # Check every 30s once connected
            
            # Format tooltip cleanly:
            # Line 1: VPN: 195.63.138.33 (NL)
            # Line 2: Orig: 185.100.197.0 (CZ)
            # Line 3: VladiMIR
            $line1 = if ($script:vpnCode) { "VPN: $script:vpnIp ($script:vpnCode)" } else { "VPN: $script:vpnIp" }
            $line2 = if ($origCode) { "Orig: $origIp ($origCode)" } else { "Orig: $origIp" }
            
            Set-SafeTooltip $line1 $line2 $shortName
            
            if ($script:lastState -ne "Connected") {
                $script:lastState = "Connected"
                $balloon = "$line1`n$line2`nProfile: $profileName"
                $notify.ShowBalloonTip(4000, "Xray VPN: Connected", $balloon, [System.Windows.Forms.ToolTipIcon]::Info)
            }
        }
    } catch {
        $script:checkAttempts++
        if ($script:checkAttempts -gt 10 -and $script:lastState -ne "Connected") {
            $notify.Icon = $iconRed
            $mStatus.Text = "Status: Cannot connect to server"
            Set-SafeTooltip "VPN: Connection Timeout" "Cannot reach server" $shortName
            if ($script:lastState -ne "Error") {
                $script:lastState = "Error"
                $notify.ShowBalloonTip(5000, "Xray VPN: Timeout", "Could not connect to server $profileName. Check network or key.", [System.Windows.Forms.ToolTipIcon]::Warning)
            }
        }
    }
})
$ipTimer.Start()

[System.Windows.Forms.Application]::Run()

'@
[System.IO.File]::WriteAllText("C:\XRAY_VPN\TrayVPN.ps1", $trayScript, [System.Text.Encoding]::UTF8)

# Clear any previous error file
Remove-Item "C:\XRAY_VPN\error.txt" -Force -ErrorAction SilentlyContinue

Write-Host ''
Write-Host '==========================================================================================' -ForegroundColor Green
Write-Host ' [OK] Done! Next steps:' -ForegroundColor Green
Write-Host '      1. Paste your VLESS key into Notepad (link.txt) and Save (Ctrl+S)' -ForegroundColor Green
Write-Host '      2. Double-click Start_VPN shortcut in C:\XRAY_VPN' -ForegroundColor Green
Write-Host '      3. Click Check_IP to verify your new IP' -ForegroundColor Green
Write-Host '==========================================================================================' -ForegroundColor Green
Write-Host ''

$timeout = 20
while ($timeout -gt 0) {
    try {
        if ([Console]::KeyAvailable) { [void][Console]::ReadKey($true); break }
    } catch {}
    Write-Host -NoNewline "Closing automatically in $timeout s (or press any key to exit now)...  "
    Start-Sleep -Seconds 1
    $timeout--
}
Write-Host ''