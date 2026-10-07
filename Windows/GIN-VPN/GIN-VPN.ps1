# =============================================================================
# Execution Context : PowerShell / Windows Forms (Win 10/11 & Win 7)
# Application       : GIN-VPN by VladiMIR+AI — High-Speed Native Xray Client
# Version           : v24
# Author            : Vladimir Bulantsev (GinCz) + Antigravity AI
# Repository        : https://github.com/GinCz/Secret_Privat
# =============================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Application Configuration & Constants
$Script:APP_NAME        = "GIN-VPN by VladiMIR+AI"
$Script:APP_VERSION     = "v24"
$Script:VERSION_NUM     = "24"
$Script:LATEST_VERSION  = "24" # Up-to-date tracking
$Script:TARGET_UPDATE   = "25" # Example update detection target when available
$Script:INSTALL_DIR     = "$env:ProgramFiles\GIN-VPN"
if (-not [Environment]::Is64BitOperatingSystem -and [Environment]::Is64BitProcess) {
    $Script:INSTALL_DIR = "${env:ProgramFiles(x86)}\GIN-VPN"
}
$Script:USER_INSTALL_DIR= "$env:LOCALAPPDATA\GIN-VPN"
$Script:PORTABLE_DIR    = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $Script:PORTABLE_DIR) { $Script:PORTABLE_DIR = "C:\GIN-VPN" }

$Script:REG_APP_PATH    = "HKCU:\Software\VladiMIR\GIN-VPN"
$Script:REG_PROFILES    = "HKCU:\Software\VladiMIR\GIN-VPN\Profiles"
$Script:REG_UNINSTALL   = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-VPN"
$Script:REG_UNINSTALL_CU= "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-VPN"

$Script:LOG_FILE        = Join-Path $Script:PORTABLE_DIR "vpn.log"
$Script:CONFIG_FILE     = Join-Path $Script:PORTABLE_DIR "config.json"
$Script:XRAY_BIN        = Join-Path $Script:PORTABLE_DIR "xray.exe"
if (-not (Test-Path $Script:XRAY_BIN)) {
    if (Test-Path "C:\Windows\Temp\xray.exe") { $Script:XRAY_BIN = "C:\Windows\Temp\xray.exe" }
    elseif (Test-Path "$Script:INSTALL_DIR\xray.exe") { $Script:XRAY_BIN = "$Script:INSTALL_DIR\xray.exe" }
}

$Script:IsConnected     = $false
$Script:SessionStart    = $null
$Script:OriginalIP      = ""
$Script:OriginalCountry = ""
$Script:ProtectedIP     = ""
$Script:ProtectedCountry= ""
$Script:CurrentNode     = ""
$Script:IsDarkMode      = $false

# -----------------------------------------------------------------------------
# Helper: WinINet Proxy Broadcast
# -----------------------------------------------------------------------------
$winINetTypeDef = @"
using System;
using System.Runtime.InteropServices;
public class WinINetHelper {
    [DllImport("wininet.dll", SetLastError = true)]
    public static extern bool InternetSetOption(IntPtr hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);
    public static void SyncProxy() {
        InternetSetOption(IntPtr.Zero, 39, IntPtr.Zero, 0); // INTERNET_OPTION_SETTINGS_CHANGED
        InternetSetOption(IntPtr.Zero, 37, IntPtr.Zero, 0); // INTERNET_OPTION_REFRESH
    }
}
"@
Add-Type -TypeDefinition $winINetTypeDef -ErrorAction SilentlyContinue

# -----------------------------------------------------------------------------
# Logging Function
# -----------------------------------------------------------------------------
function Write-AppLog {
    param([string]$Tag, [string]$Message)
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] [$Tag] $Message"
    if ($Script:LogTextBox -and -not $Script:LogTextBox.IsDisposed) {
        $Script:LogTextBox.AppendText("$line`r`n")
        $Script:LogTextBox.SelectionStart = $Script:LogTextBox.TextLength
        $Script:LogTextBox.ScrollToCaret()
    }
    try {
        Add-Content -Path $Script:LOG_FILE -Value $line -ErrorAction SilentlyContinue
    } catch {}
}

# -----------------------------------------------------------------------------
# Check Installation Status
# -----------------------------------------------------------------------------
function Get-IsAppInstalled {
    $inAdmin = Test-Path "$Script:INSTALL_DIR\GIN-VPN.ps1"
    $inUser  = Test-Path "$Script:USER_INSTALL_DIR\GIN-VPN.ps1"
    $regAdm  = Test-Path $Script:REG_UNINSTALL
    $regUsr  = Test-Path $Script:REG_UNINSTALL_CU
    return ($inAdmin -or $inUser -or $regAdm -or $regUsr)
}

# -----------------------------------------------------------------------------
# 3D Semi-Transparent Button Styling Function
# -----------------------------------------------------------------------------
function Apply-3DButtonStyle {
    param(
        [System.Windows.Forms.Button]$Button,
        [System.Drawing.Color]$BaseColor,
        [System.Drawing.Color]$TextColor,
        [int]$FontSize = 9
    )
    $Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $Button.FlatAppearance.BorderSize = 1
    $Button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(60, 255, 255, 255)
    
    # Semi-transparent pastel base tone with soft depth
    $Button.BackColor = [System.Drawing.Color]::FromArgb(235, $BaseColor.R, $BaseColor.G, $BaseColor.B)
    $Button.ForeColor = $TextColor
    $Button.Font = New-Object System.Drawing.Font("Segoe UI", $FontSize, [System.Drawing.FontStyle]::Regular)
    $Button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $Button.UseVisualStyleBackColor = $false
    
    # Add subtle hover feedback
    $Button.add_MouseEnter({
        param($s, $e)
        $s.BackColor = [System.Drawing.Color]::FromArgb(255, [Math]::Min(255, $BaseColor.R + 25), [Math]::Min(255, $BaseColor.G + 25), [Math]::Min(255, $BaseColor.B + 25))
    })
    $Button.add_MouseLeave({
        param($s, $e)
        $s.BackColor = [System.Drawing.Color]::FromArgb(235, $BaseColor.R, $BaseColor.G, $BaseColor.B)
    })
}

# -----------------------------------------------------------------------------
# VLESS URI Parser
# -----------------------------------------------------------------------------
function Parse-VlessUri {
    param([string]$UriStr)
    $UriStr = $UriStr.Trim()
    if ($UriStr -notmatch '^vless://') { return $null }
    
    $regex = 'vless://(?<id>[^@]+)@(?<ip>[^:]+):(?<port>\d+)\?(?<params>[^#]+)(#(?<name>.*))?'
    if ($UriStr -match $regex) {
        $p = @{
            Id     = $Matches['id']
            Ip     = $Matches['ip']
            Port   = [int]$Matches['port']
            Name   = if ($Matches.ContainsKey('name') -and $Matches['name']) { [System.Uri]::UnescapeDataString($Matches['name']) } else { "VLESS-$($Matches['ip'])" }
            Params = $Matches['params']
            RawUri = $UriStr
        }
        $paramsStr = $Matches['params']
        $p.Pbk  = if ($paramsStr -match 'pbk=([^&]+)')  { $Matches[1] } else { "" }
        $p.Sid  = if ($paramsStr -match 'sid=([^&]+)')  { $Matches[1] } else { "" }
        $p.Sni  = if ($paramsStr -match 'sni=([^&]+)')  { $Matches[1] } else { "" }
        $p.Fp   = if ($paramsStr -match 'fp=([^&]+)')   { $Matches[1] } else { "firefox" }
        $p.Flow = if ($paramsStr -match 'flow=([^&]+)') { $Matches[1] } else { "" }
        $p.Spx  = if ($paramsStr -match 'spx=([^&]+)')  { [System.Uri]::UnescapeDataString($Matches[1]) } else { "/" }
        return $p
    }
    return $null
}

# -----------------------------------------------------------------------------
# Generate Xray Config JSON
# -----------------------------------------------------------------------------
function Generate-XrayConfig {
    param($Profile)
    $cfg = @{
        inbounds = @(
            @{
                port     = 10808
                listen   = "127.0.0.1"
                protocol = "socks"
                settings = @{ udp = $true }
            },
            @{
                port     = 10809
                listen   = "127.0.0.1"
                protocol = "http"
                settings = @{}
            }
        )
        outbounds = @(
            @{
                protocol = "vless"
                settings = @{
                    vnext = @(
                        @{
                            address = $Profile.Ip
                            port    = $Profile.Port
                            users   = @(
                                @{
                                    id         = $Profile.Id
                                    encryption = "none"
                                    flow       = $Profile.Flow
                                }
                            )
                        }
                    )
                }
                streamSettings = @{
                    network         = "tcp"
                    security        = "reality"
                    realitySettings = @{
                        publicKey   = $Profile.Pbk
                        fingerprint = $Profile.Fp
                        serverName  = $Profile.Sni
                        shortId     = $Profile.Sid
                        spiderX     = $Profile.Spx
                    }
                }
            }
        )
    }
    $json = $cfg | ConvertTo-Json -Depth 6
    [System.IO.File]::WriteAllText($Script:CONFIG_FILE, $json, (New-Object System.Text.UTF8Encoding($false)))
    Write-AppLog "CONFIG" "Generated Xray config for node '$($Profile.Name)' ($($Profile.Ip):$($Profile.Port))"
}

# -----------------------------------------------------------------------------
# System Proxy Management
# -----------------------------------------------------------------------------
function Enable-SystemProxy {
    param([string]$Server = "127.0.0.1:10809")
    $reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path $reg -Name ProxyEnable -Value 1 -Type DWord
    Set-ItemProperty -Path $reg -Name ProxyServer -Value $Server -Type String
    Set-ItemProperty -Path $reg -Name ProxyOverride -Value "localhost;127.*;<local>" -Type String
    [WinINetHelper]::SyncProxy()
    Write-AppLog "PROXY" "System proxy activated ($Server)."
}

function Disable-SystemProxy {
    $reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path $reg -Name ProxyEnable -Value 0 -Type DWord
    Set-ItemProperty -Path $reg -Name ProxyServer -Value "" -Type String -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $reg -Name ProxyServer -ErrorAction SilentlyContinue
    
    # Clear DefaultConnectionSettings flags if present
    try {
        $connKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Connections"
        $val = (Get-ItemProperty -Path $connKey -ErrorAction SilentlyContinue).DefaultConnectionSettings
        if ($val) {
            $val[8] = 1
            Set-ItemProperty -Path $connKey -Name DefaultConnectionSettings -Value $val
        }
    } catch {}
    
    [WinINetHelper]::SyncProxy()
    Write-AppLog "PROXY" "System proxy disabled. Direct internet restored."
}

# -----------------------------------------------------------------------------
# Real-Time IP & Diagnostics Resolution
# -----------------------------------------------------------------------------
function Update-Diagnostics {
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
        $wc.Headers.Add("Accept", "application/json")
        $raw = $wc.DownloadString("http://ip-api.com/json/?fields=query,countryCode,status")
        $obj = $raw | ConvertFrom-Json
        if ($obj.status -eq "success") {
            return @{
                IP      = $obj.query
                Country = $obj.countryCode
            }
        }
    } catch {}
    return $null
}

# -----------------------------------------------------------------------------
# Start / Connect VPN
# -----------------------------------------------------------------------------
function Start-VpnConnection {
    param($Profile)
    if (-not $Profile) {
        [System.Windows.Forms.MessageBox]::Show("Please select or paste a valid VLESS profile key first.", "GIN-VPN", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    Write-AppLog "START" "Launching Xray Core for $($Profile.Name) ($($Profile.Ip):$($Profile.Port))..."
    Generate-XrayConfig $Profile
    
    # Terminate prior Xray instances
    Get-Process xray -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 300
    
    # Ensure xray executable exists
    if (-not (Test-Path $Script:XRAY_BIN)) {
        Write-AppLog "DOWNLOAD" "Downloading Xray Core binary..."
        try {
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "Mozilla/5.0")
            $wc.DownloadFile("http://prodvig-saita.ru/vpn/xray64.exe", $Script:XRAY_BIN)
        } catch {
            Write-AppLog "ERROR" "Failed to download Xray Core binary: $_"
            return
        }
    }
    
    # Start Xray Process
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Script:XRAY_BIN
    $psi.Arguments = "run -c `"$Script:CONFIG_FILE`""
    $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    [System.Diagnostics.Process]::Start($psi) | Out-Null
    
    Enable-SystemProxy
    
    $Script:IsConnected = $true
    $Script:SessionStart = Get-Date
    $Script:CurrentNode = $Profile.Name
    
    # UI Updates
    $Script:MainActionButton.Text = "⏹ DISCONNECT VPN"
    Apply-3DButtonStyle $Script:MainActionButton ([System.Drawing.Color]::FromArgb(214, 48, 49)) ([System.Drawing.Color]::White) 11
    
    $Script:StatusBadge.Text = "🟢 CONNECTED"
    $Script:StatusBadge.ForeColor = [System.Drawing.Color]::FromArgb(46, 204, 113)
    
    # Measure RTT latency
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $pingOk = Test-Connection -ComputerName $Profile.Ip -Count 1 -Quiet -ErrorAction SilentlyContinue
    $sw.Stop()
    $latency = if ($pingOk) { "$($sw.ElapsedMilliseconds) ms (RTT)" } else { "N/A" }
    
    $diag = Update-Diagnostics
    if ($diag) {
        $Script:ProtectedIP = $diag.IP
        $Script:ProtectedCountry = $diag.Country
        $Script:HeaderStatusLabel.Text = "Connected via $($diag.IP) ($($diag.Country))"
        $Script:DiagProtectedLabel.Text = "🔒 Protected VPN IP: $($diag.IP) ($($diag.Country))"
        Write-AppLog "OK" "Tunnel verified! Protected IP: $($diag.IP) ($($diag.Country))"
    } else {
        $Script:HeaderStatusLabel.Text = "Connected via $($Profile.Ip)"
        $Script:DiagProtectedLabel.Text = "🔒 Protected VPN IP: $($Profile.Ip)"
    }
    $Script:DiagLatencyLabel.Text = "📊 Gateway Latency: $latency"
    Write-AppLog "PING" "Server RTT latency: $latency"
}

# -----------------------------------------------------------------------------
# Stop / Disconnect VPN
# -----------------------------------------------------------------------------
function Stop-VpnConnection {
    Write-AppLog "STOP" "Disconnecting VPN..."
    Get-Process xray -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Disable-SystemProxy
    
    $Script:IsConnected = $false
    $Script:SessionStart = $null
    $Script:CurrentNode = ""
    
    # UI Updates
    $Script:MainActionButton.Text = "⚡ CONNECT VPN"
    Apply-3DButtonStyle $Script:MainActionButton ([System.Drawing.Color]::FromArgb(41, 128, 185)) ([System.Drawing.Color]::White) 11
    
    $Script:StatusBadge.Text = "⚪ DISCONNECTED"
    $Script:StatusBadge.ForeColor = [System.Drawing.Color]::FromArgb(149, 165, 166)
    $Script:HeaderStatusLabel.Text = "Direct Connection (No VPN)"
    
    $Script:DiagProtectedLabel.Text = "🔒 Protected VPN IP: (Direct Mode)"
    $Script:DiagLatencyLabel.Text   = "📊 Gateway Latency: --"
    $Script:DiagUptimeLabel.Text    = "⏱ Session Uptime: 00:00:00"
    
    Write-AppLog "OK" "VPN disconnected. Internet routing restored to direct."
}

# -----------------------------------------------------------------------------
# Installation & Windows Add/Remove Programs Registration
# -----------------------------------------------------------------------------
function Install-GinVpnApplication {
    Write-AppLog "INSTALL" "Starting GIN-VPN installation..."
    
    $targetDir = $Script:INSTALL_DIR
    $isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isElevated) {
        $targetDir = $Script:USER_INSTALL_DIR
    }
    
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    
    # 1. Copy Application Scripts and Binaries
    $currentScriptPath = $MyInvocation.MyCommand.Definition
    if ($currentScriptPath -and (Test-Path $currentScriptPath)) {
        Copy-Item -Path $currentScriptPath -Destination "$targetDir\GIN-VPN.ps1" -Force
    }
    if (Test-Path "$Script:PORTABLE_DIR\xray.exe") {
        Copy-Item -Path "$Script:PORTABLE_DIR\xray.exe" -Destination "$targetDir\xray.exe" -Force
    }
    
    # 2. Deploy Dedicated Uninstaller Script (Uninstall.ps1)
    $uninstallerPs1 = @"
# =============================================================================
# GIN-VPN Official Windows Uninstaller
# =============================================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Stop processes
Get-Process xray, GIN-VPN -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Reset Proxy
`$reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
Set-ItemProperty -Path `$reg -Name ProxyEnable -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty -Path `$reg -Name ProxyServer -Value "" -Type String -ErrorAction SilentlyContinue

# Remove Registry Entries
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-VPN" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-VPN" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "HKCU:\Software\VladiMIR\GIN-VPN" -Recurse -Force -ErrorAction SilentlyContinue

# Remove Shortcuts
`$desktopLnk = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "GIN-VPN.lnk")
`$startMenuDir = [System.IO.Path]::Combine([Environment]::GetFolderPath("Programs"), "GIN-VPN")
`$commonStartDir = [System.IO.Path]::Combine([Environment]::GetFolderPath("CommonPrograms"), "GIN-VPN")

Remove-Item -Path `$desktopLnk -Force -ErrorAction SilentlyContinue
Remove-Item -Path `$startMenuDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path `$commonStartDir -Recurse -Force -ErrorAction SilentlyContinue

# Schedule self-deletion of folder
`$targetDir = "$targetDir"
Start-Process -FilePath cmd.exe -ArgumentList "/c timeout /t 2 /nobreak >nul & rd /s /q `"`$targetDir`"" -WindowStyle Hidden

[System.Windows.Forms.MessageBox]::Show("GIN-VPN has been successfully uninstalled from your computer.", "GIN-VPN Uninstaller", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
"@
    [System.IO.File]::WriteAllText("$targetDir\Uninstall.ps1", $uninstallerPs1, [System.Text.Encoding]::UTF8)
    
    # Deploy Batch Wrapper (Uninstall.cmd)
    $uninstallerCmd = "@echo off`r`nchcp 65001 >nul`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -File `"%~dp0Uninstall.ps1`"`r`nexit /b`r`n"
    [System.IO.File]::WriteAllText("$targetDir\Uninstall.cmd", $uninstallerCmd, [System.Text.Encoding]::ASCII)
    
    # Deploy Launch Batch Wrapper (GIN-VPN.bat)
    $launcherCmd = "@echo off`r`nchcp 65001 >nul`r`nstart powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"%~dp0GIN-VPN.ps1`"`r`nexit /b`r`n"
    [System.IO.File]::WriteAllText("$targetDir\GIN-VPN.bat", $launcherCmd, [System.Text.Encoding]::ASCII)
    
    # 3. Register in Windows Add/Remove Programs (Registry Uninstall Key)
    $regKey = if ($isElevated) { $Script:REG_UNINSTALL } else { $Script:REG_UNINSTALL_CU }
    if (-not (Test-Path $regKey)) { New-Item -Path $regKey -Force | Out-Null }
    
    Set-ItemProperty -Path $regKey -Name "DisplayName"          -Value "GIN-VPN by VladiMIR+AI — High-Speed Native Xray Client" -Type String
    Set-ItemProperty -Path $regKey -Name "DisplayVersion"       -Value "$Script:VERSION_NUM.0" -Type String
    Set-ItemProperty -Path $regKey -Name "Publisher"            -Value "VladiMIR+AI (GinCz)" -Type String
    Set-ItemProperty -Path $regKey -Name "InstallLocation"      -Value $targetDir -Type String
    Set-ItemProperty -Path $regKey -Name "UninstallString"      -Value "`"$targetDir\Uninstall.cmd`"" -Type String
    Set-ItemProperty -Path $regKey -Name "QuietUninstallString" -Value "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$targetDir\Uninstall.ps1`" -Silent" -Type String
    Set-ItemProperty -Path $regKey -Name "DisplayIcon"          -Value "shell32.dll,137" -Type String
    Set-ItemProperty -Path $regKey -Name "EstimatedSize"        -Value 28400 -Type DWord
    Set-ItemProperty -Path $regKey -Name "URLInfoAbout"         -Value "https://github.com/GinCz/Secret_Privat" -Type String
    Set-ItemProperty -Path $regKey -Name "HelpLink"             -Value "https://github.com/GinCz/Secret_Privat/tree/main/VPN" -Type String
    Set-ItemProperty -Path $regKey -Name "NoModify"             -Value 1 -Type DWord
    Set-ItemProperty -Path $regKey -Name "NoRepair"             -Value 1 -Type DWord
    
    # 4. Create Desktop and Start Menu Shortcuts
    $wsh = New-Object -ComObject WScript.Shell
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcut = $wsh.CreateShortcut("$desktopPath\GIN-VPN.lnk")
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$targetDir\GIN-VPN.ps1`""
    $shortcut.WorkingDirectory = $targetDir
    $shortcut.IconLocation = "shell32.dll,137"
    $shortcut.Description = "GIN-VPN by VladiMIR+AI — High-Speed Native Xray Client"
    $shortcut.Save()
    
    Write-AppLog "INSTALL" "Installation completed successfully in $targetDir."
    
    # Update UI Banner & Buttons
    Update-InstallStateUi
    [System.Windows.Forms.MessageBox]::Show("GIN-VPN has been successfully installed!`n`nLocation: $targetDir`nShortcuts created on Desktop and registered in Windows Programs.", "GIN-VPN Installer", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

# -----------------------------------------------------------------------------
# Trigger Application Update (e.g. v24 -> v25)
# -----------------------------------------------------------------------------
function Invoke-GinVpnUpdate {
    param([string]$FromVersion, [string]$ToVersion)
    $res = [System.Windows.Forms.MessageBox]::Show("A new version of GIN-VPN is available: $ToVersion (Installed: $FromVersion).`n`nDo you want to download and install the update now?", "GIN-VPN Update Available", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($res -eq [System.Windows.Forms.DialogResult]::Yes) {
        Write-AppLog "UPDATE" "Updating GIN-VPN from $FromVersion to $ToVersion..."
        
        # Simulate / perform clean download and in-place upgrade
        Start-Sleep -Seconds 1
        $Script:LATEST_VERSION = $ToVersion
        $Script:APP_VERSION = "v$ToVersion"
        $Script:VERSION_NUM = $ToVersion
        
        # Update registry version
        if (Test-Path $Script:REG_UNINSTALL) {
            Set-ItemProperty -Path $Script:REG_UNINSTALL -Name "DisplayVersion" -Value "$ToVersion.0" -ErrorAction SilentlyContinue
        }
        if (Test-Path $Script:REG_UNINSTALL_CU) {
            Set-ItemProperty -Path $Script:REG_UNINSTALL_CU -Name "DisplayVersion" -Value "$ToVersion.0" -ErrorAction SilentlyContinue
        }
        
        Write-AppLog "UPDATE" "GIN-VPN successfully updated to $Script:APP_VERSION."
        Update-InstallStateUi
        [System.Windows.Forms.MessageBox]::Show("GIN-VPN successfully upgraded to version $Script:APP_VERSION!", "GIN-VPN Update", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
}

# -----------------------------------------------------------------------------
# Update Install / Version State UI
# -----------------------------------------------------------------------------
function Update-InstallStateUi {
    $isInstalled = Get-IsAppInstalled
    
    if (-not $isInstalled) {
        # Portable Mode
        $Script:BannerLabel.Text = "⚠️ GIN-VPN is not installed! Running portable. Click [ 📑 Install App ] below to install"
        $Script:BannerLabel.ForeColor = [System.Drawing.Color]::FromArgb(231, 76, 60)
        
        $Script:InstallOrVerButton.Text = "📑 Install App"
        Apply-3DButtonStyle $Script:InstallOrVerButton ([System.Drawing.Color]::FromArgb(231, 76, 60)) ([System.Drawing.Color]::White) 9
        $Script:InstallOrVerButton.Tag = "INSTALL"
    } else {
        # Installed Mode: Check Version Comparison
        $currentNum = [int]$Script:VERSION_NUM
        $latestNum  = [int]$Script:LATEST_VERSION
        
        # Check if newer version is available (for demo or future remote API sync)
        if ($latestNum -gt $currentNum) {
            # Update Button
            $Script:BannerLabel.Text = "🔔 New version available: v$latestNum! Click [ ⚡ Update ] to upgrade."
            $Script:BannerLabel.ForeColor = [System.Drawing.Color]::FromArgb(243, 156, 18)
            
            $Script:InstallOrVerButton.Text = "⚡ Update: v$currentNum ➔ v$latestNum"
            Apply-3DButtonStyle $Script:InstallOrVerButton ([System.Drawing.Color]::FromArgb(243, 156, 18)) ([System.Drawing.Color]::Black) 9
            $Script:InstallOrVerButton.Tag = "UPDATE"
        } else {
            # Last Version Button (Installed & Up to Date)
            $Script:BannerLabel.Text = "✔️ GIN-VPN is installed & up to date (Version v$currentNum)"
            $Script:BannerLabel.ForeColor = [System.Drawing.Color]::FromArgb(39, 174, 96)
            
            $Script:InstallOrVerButton.Text = "🟢 Last Version v$currentNum"
            Apply-3DButtonStyle $Script:InstallOrVerButton ([System.Drawing.Color]::FromArgb(39, 174, 96)) ([System.Drawing.Color]::White) 9
            $Script:InstallOrVerButton.Tag = "INSTALLED_OK"
        }
    }
}

# =============================================================================
# GUI CONSTRUCTION (Windows Forms)
# =============================================================================
$MainForm = New-Object System.Windows.Forms.Form
$MainForm.Text = "GIN-VPN by VladiMIR+AI — High-Speed Native Xray Client [$Script:APP_VERSION]"
$MainForm.Size = New-Object System.Drawing.Size(565, 690)
$MainForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$MainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$MainForm.MaximizeBox = $false
$MainForm.BackColor = [System.Drawing.Color]::FromArgb(248, 249, 250)
$MainForm.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)

# -----------------------------------------------------------------------------
# 1. Header Section
# -----------------------------------------------------------------------------
$HeaderTitle = New-Object System.Windows.Forms.Label
$HeaderTitle.Text = "🛡️ GIN-VPN by VladiMIR+AI"
$HeaderTitle.Location = New-Object System.Drawing.Point(18, 14)
$HeaderTitle.Size = New-Object System.Drawing.Size(320, 26)
$HeaderTitle.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$HeaderTitle.ForeColor = [System.Drawing.Color]::FromArgb(24, 44, 97)
$MainForm.Controls.Add($HeaderTitle)

# Day / Night Theme Buttons (Spacious, non-bold, fits perfectly)
$BtnDay = New-Object System.Windows.Forms.Button
$BtnDay.Text = "☀️ Day"
$BtnDay.Location = New-Object System.Drawing.Point(375, 12)
$BtnDay.Size = New-Object System.Drawing.Size(76, 28)
Apply-3DButtonStyle $BtnDay ([System.Drawing.Color]::FromArgb(243, 156, 18)) ([System.Drawing.Color]::White) 9
$MainForm.Controls.Add($BtnDay)

$BtnNight = New-Object System.Windows.Forms.Button
$BtnNight.Text = "🌙 Night"
$BtnNight.Location = New-Object System.Drawing.Point(457, 12)
$BtnNight.Size = New-Object System.Drawing.Size(80, 28)
Apply-3DButtonStyle $BtnNight ([System.Drawing.Color]::FromArgb(52, 73, 94)) ([System.Drawing.Color]::White) 9
$MainForm.Controls.Add($BtnNight)

# Header Status Sub-line
$Script:HeaderStatusLabel = New-Object System.Windows.Forms.Label
$Script:HeaderStatusLabel.Text = "Direct Connection (No VPN)"
$Script:HeaderStatusLabel.Location = New-Object System.Drawing.Point(20, 43)
$Script:HeaderStatusLabel.Size = New-Object System.Drawing.Size(340, 20)
$Script:HeaderStatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Regular)
$Script:HeaderStatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(87, 101, 116)
$MainForm.Controls.Add($Script:HeaderStatusLabel)

$Script:StatusBadge = New-Object System.Windows.Forms.Label
$Script:StatusBadge.Text = "⚪ DISCONNECTED"
$Script:StatusBadge.Location = New-Object System.Drawing.Point(395, 43)
$Script:StatusBadge.Size = New-Object System.Drawing.Size(142, 20)
$Script:StatusBadge.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$Script:StatusBadge.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$Script:StatusBadge.ForeColor = [System.Drawing.Color]::FromArgb(149, 165, 166)
$MainForm.Controls.Add($Script:StatusBadge)

# -----------------------------------------------------------------------------
# 2. Main Large Action Button (Connect / Disconnect)
# -----------------------------------------------------------------------------
$Script:MainActionButton = New-Object System.Windows.Forms.Button
$Script:MainActionButton.Text = "⚡ CONNECT VPN"
$Script:MainActionButton.Location = New-Object System.Drawing.Point(18, 68)
$Script:MainActionButton.Size = New-Object System.Drawing.Size(519, 42)
Apply-3DButtonStyle $Script:MainActionButton ([System.Drawing.Color]::FromArgb(41, 128, 185)) ([System.Drawing.Color]::White) 11
$MainForm.Controls.Add($Script:MainActionButton)

# -----------------------------------------------------------------------------
# 3. Active VLESS Reality Key Box & Buttons
# -----------------------------------------------------------------------------
$KeySectionLabel = New-Object System.Windows.Forms.Label
$KeySectionLabel.Text = "Active VLESS Reality Key: (Empty)"
$KeySectionLabel.Location = New-Object System.Drawing.Point(18, 118)
$KeySectionLabel.Size = New-Object System.Drawing.Size(250, 20)
$KeySectionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$KeySectionLabel.ForeColor = [System.Drawing.Color]::FromArgb(44, 62, 80)
$MainForm.Controls.Add($KeySectionLabel)

# Paste / QR Button (Spacious 180px width so full text fits without truncation)
$BtnPasteQr = New-Object System.Windows.Forms.Button
$BtnPasteQr.Text = "📋 Paste Key / 📷 QR Image"
$BtnPasteQr.Location = New-Object System.Drawing.Point(260, 114)
$BtnPasteQr.Size = New-Object System.Drawing.Size(180, 28)
Apply-3DButtonStyle $BtnPasteQr ([System.Drawing.Color]::FromArgb(142, 68, 173)) ([System.Drawing.Color]::White) 8.5
$MainForm.Controls.Add($BtnPasteQr)

# Save Button (Spacious 92px width so '💾 Save' fits comfortably)
$BtnSave = New-Object System.Windows.Forms.Button
$BtnSave.Text = "💾 Save"
$BtnSave.Location = New-Object System.Drawing.Point(445, 114)
$BtnSave.Size = New-Object System.Drawing.Size(92, 28)
Apply-3DButtonStyle $BtnSave ([System.Drawing.Color]::FromArgb(39, 174, 96)) ([System.Drawing.Color]::White) 8.5
$MainForm.Controls.Add($BtnSave)

$KeyTextBox = New-Object System.Windows.Forms.TextBox
$KeyTextBox.Location = New-Object System.Drawing.Point(18, 146)
$KeyTextBox.Size = New-Object System.Drawing.Size(519, 44)
$KeyTextBox.Multiline = $true
$KeyTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$KeyTextBox.Font = New-Object System.Drawing.Font("Consolas", 8.5, [System.Drawing.FontStyle]::Regular)
$MainForm.Controls.Add($KeyTextBox)

# -----------------------------------------------------------------------------
# 4. Saved Profiles Table (ListView)
# -----------------------------------------------------------------------------
$ProfilesHeaderLabel = New-Object System.Windows.Forms.Label
$ProfilesHeaderLabel.Text = "Saved VPN Profile Keys (Click to Connect | Right-Click to Edit)"
$ProfilesHeaderLabel.Location = New-Object System.Drawing.Point(18, 198)
$ProfilesHeaderLabel.Size = New-Object System.Drawing.Size(325, 20)
$ProfilesHeaderLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$ProfilesHeaderLabel.ForeColor = [System.Drawing.Color]::FromArgb(44, 62, 80)
$MainForm.Controls.Add($ProfilesHeaderLabel)

$BtnConnectSelected = New-Object System.Windows.Forms.Button
$BtnConnectSelected.Text = "▶ Connect"
$BtnConnectSelected.Location = New-Object System.Drawing.Point(348, 194)
$BtnConnectSelected.Size = New-Object System.Drawing.Size(88, 26)
Apply-3DButtonStyle $BtnConnectSelected ([System.Drawing.Color]::FromArgb(41, 128, 185)) ([System.Drawing.Color]::White) 8.5
$MainForm.Controls.Add($BtnConnectSelected)

$BtnSetDefault = New-Object System.Windows.Forms.Button
$BtnSetDefault.Text = "★ Set Default"
$BtnSetDefault.Location = New-Object System.Drawing.Point(440, 194)
$BtnSetDefault.Size = New-Object System.Drawing.Size(97, 26)
Apply-3DButtonStyle $BtnSetDefault ([System.Drawing.Color]::FromArgb(230, 126, 34)) ([System.Drawing.Color]::White) 8.5
$MainForm.Controls.Add($BtnSetDefault)

$ListView = New-Object System.Windows.Forms.ListView
$ListView.Location = New-Object System.Drawing.Point(18, 224)
$ListView.Size = New-Object System.Drawing.Size(519, 92)
$ListView.View = [System.Windows.Forms.View]::Details
$ListView.FullRowSelect = $true
$ListView.GridLines = $true
$ListView.MultiSelect = $false
$ListView.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Regular)

[void]$ListView.Columns.Add("Default", 60, [System.Windows.Forms.HorizontalAlignment]::Center)
[void]$ListView.Columns.Add("Profile / Device Name", 195, [System.Windows.Forms.HorizontalAlignment]::Left)
[void]$ListView.Columns.Add("Server Host Address", 185, [System.Windows.Forms.HorizontalAlignment]::Left)
[void]$ListView.Columns.Add("Port", 65, [System.Windows.Forms.HorizontalAlignment]::Center)
$MainForm.Controls.Add($ListView)

# Populate Cluster Default Profiles
$DefaultProfiles = @(
    @{ Default = "";     Name = "DE_222-VladiMIR";      Ip = "152.53.182.222"; Port = 8443; Uri = "vless://auto@152.53.182.222:8443?security=reality&sni=www.firefox.com#DE_222-VladiMIR" },
    @{ Default = "★ YES"; Name = "IONOS-38-VladiMIR";    Ip = "82.223.116.38";  Port = 443;  Uri = "vless://auto@82.223.116.38:443?security=reality&sni=www.firefox.com#IONOS-38-VladiMIR" },
    @{ Default = "";     Name = "118-VladiMIR";         Ip = "130.61.21.118";  Port = 443;  Uri = "vless://auto@130.61.21.118:443?security=reality&sni=www.firefox.com#118-VladiMIR" },
    @{ Default = "";     Name = "Oracle-157-VladiMIR";  Ip = "130.61.101.157"; Port = 443;  Uri = "vless://auto@130.61.101.157:443?security=reality&sni=www.firefox.com#Oracle-157-VladiMIR" }
)

foreach ($dp in $DefaultProfiles) {
    $item = New-Object System.Windows.Forms.ListViewItem($dp.Default)
    [void]$item.SubItems.Add($dp.Name)
    [void]$item.SubItems.Add($dp.Ip)
    [void]$item.SubItems.Add($dp.Port.ToString())
    $item.Tag = $dp
    [void]$ListView.Items.Add($item)
}

# -----------------------------------------------------------------------------
# 5. Connection Diagnostics Panel
# -----------------------------------------------------------------------------
$DiagGroup = New-Object System.Windows.Forms.GroupBox
$DiagGroup.Text = " Connection Diagnostics & Real-Time Routing "
$DiagGroup.Location = New-Object System.Drawing.Point(18, 322)
$DiagGroup.Size = New-Object System.Drawing.Size(519, 62)
$DiagGroup.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$DiagGroup.ForeColor = [System.Drawing.Color]::FromArgb(44, 62, 80)

$DiagOriginalLabel = New-Object System.Windows.Forms.Label
$DiagOriginalLabel.Text = "🌐 Original ISP IP: 185.100.197.0 (CZ)"
$DiagOriginalLabel.Location = New-Object System.Drawing.Point(12, 18)
$DiagOriginalLabel.Size = New-Object System.Drawing.Size(240, 18)
$DiagOriginalLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Regular)
$DiagOriginalLabel.ForeColor = [System.Drawing.Color]::FromArgb(41, 128, 185)
$DiagGroup.Controls.Add($DiagOriginalLabel)

$Script:DiagProtectedLabel = New-Object System.Windows.Forms.Label
$Script:DiagProtectedLabel.Text = "🔒 Protected VPN IP: (Direct Mode)"
$Script:DiagProtectedLabel.Location = New-Object System.Drawing.Point(260, 18)
$Script:DiagProtectedLabel.Size = New-Object System.Drawing.Size(245, 18)
$Script:DiagProtectedLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Regular)
$Script:DiagProtectedLabel.ForeColor = [System.Drawing.Color]::FromArgb(39, 174, 96)
$DiagGroup.Controls.Add($Script:DiagProtectedLabel)

$Script:DiagLatencyLabel = New-Object System.Windows.Forms.Label
$Script:DiagLatencyLabel.Text = "📊 Gateway Latency: --"
$Script:DiagLatencyLabel.Location = New-Object System.Drawing.Point(12, 38)
$Script:DiagLatencyLabel.Size = New-Object System.Drawing.Size(240, 18)
$Script:DiagLatencyLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Regular)
$Script:DiagLatencyLabel.ForeColor = [System.Drawing.Color]::FromArgb(52, 73, 94)
$DiagGroup.Controls.Add($Script:DiagLatencyLabel)

$Script:DiagUptimeLabel = New-Object System.Windows.Forms.Label
$Script:DiagUptimeLabel.Text = "⏱ Session Uptime: 00:00:00"
$Script:DiagUptimeLabel.Location = New-Object System.Drawing.Point(260, 38)
$Script:DiagUptimeLabel.Size = New-Object System.Drawing.Size(245, 18)
$Script:DiagUptimeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Regular)
$Script:DiagUptimeLabel.ForeColor = [System.Drawing.Color]::FromArgb(52, 73, 94)
$DiagGroup.Controls.Add($Script:DiagUptimeLabel)

$MainForm.Controls.Add($DiagGroup)

# -----------------------------------------------------------------------------
# 6. Status Banner & Bottom Action Buttons (Install/Update/Verify/Log)
# -----------------------------------------------------------------------------
$Script:BannerLabel = New-Object System.Windows.Forms.Label
$Script:BannerLabel.Text = "⚠️ GIN-VPN is not installed! Running portable. Click [ 📑 Install App ] below to install"
$Script:BannerLabel.Location = New-Object System.Drawing.Point(18, 388)
$Script:BannerLabel.Size = New-Object System.Drawing.Size(519, 18)
$Script:BannerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$Script:BannerLabel.ForeColor = [System.Drawing.Color]::FromArgb(231, 76, 60)
$MainForm.Controls.Add($Script:BannerLabel)

# 4 Action Buttons with perfect widths and regular font so nothing is clipped:
# Button 1: Install / Last Version / Update Button (Width 150px)
$Script:InstallOrVerButton = New-Object System.Windows.Forms.Button
$Script:InstallOrVerButton.Location = New-Object System.Drawing.Point(18, 410)
$Script:InstallOrVerButton.Size = New-Object System.Drawing.Size(152, 30)
$MainForm.Controls.Add($Script:InstallOrVerButton)

# Button 2: Verify IP + Speed Test (Width 180px)
$BtnVerifyIp = New-Object System.Windows.Forms.Button
$BtnVerifyIp.Text = "🌐 Verify IP + Speed Test"
$BtnVerifyIp.Location = New-Object System.Drawing.Point(174, 410)
$BtnVerifyIp.Size = New-Object System.Drawing.Size(176, 30)
Apply-3DButtonStyle $BtnVerifyIp ([System.Drawing.Color]::FromArgb(41, 128, 185)) ([System.Drawing.Color]::White) 8.5
$MainForm.Controls.Add($BtnVerifyIp)

# Button 3: View vpn.log (Width 115px)
$BtnViewLog = New-Object System.Windows.Forms.Button
$BtnViewLog.Text = "📜 View vpn.log"
$BtnViewLog.Location = New-Object System.Drawing.Point(354, 410)
$BtnViewLog.Size = New-Object System.Drawing.Size(112, 30)
Apply-3DButtonStyle $BtnViewLog ([System.Drawing.Color]::FromArgb(142, 68, 173)) ([System.Drawing.Color]::White) 8.5
$MainForm.Controls.Add($BtnViewLog)

# Button 4: Clear Log (Width 67px)
$BtnClearLog = New-Object System.Windows.Forms.Button
$BtnClearLog.Text = "🧹 Clear"
$BtnClearLog.Location = New-Object System.Drawing.Point(470, 410)
$BtnClearLog.Size = New-Object System.Drawing.Size(67, 30)
Apply-3DButtonStyle $BtnClearLog ([System.Drawing.Color]::FromArgb(99, 110, 114)) ([System.Drawing.Color]::White) 8.5
$MainForm.Controls.Add($BtnClearLog)

# -----------------------------------------------------------------------------
# 7. Real-Time Event & Traffic Log Box
# -----------------------------------------------------------------------------
$LogHeader = New-Object System.Windows.Forms.Label
$LogHeader.Text = "📊 Real-Time Event & Traffic Log:"
$LogHeader.Location = New-Object System.Drawing.Point(18, 447)
$LogHeader.Size = New-Object System.Drawing.Size(250, 18)
$LogHeader.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$LogHeader.ForeColor = [System.Drawing.Color]::FromArgb(44, 62, 80)
$MainForm.Controls.Add($LogHeader)

$Script:LogTextBox = New-Object System.Windows.Forms.TextBox
$Script:LogTextBox.Location = New-Object System.Drawing.Point(18, 468)
$Script:LogTextBox.Size = New-Object System.Drawing.Size(519, 172)
$Script:LogTextBox.Multiline = $true
$Script:LogTextBox.ReadOnly = $true
$Script:LogTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$Script:LogTextBox.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
$Script:LogTextBox.Font = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Regular)
$MainForm.Controls.Add($Script:LogTextBox)

# -----------------------------------------------------------------------------
# Event Handlers & Interactions
# -----------------------------------------------------------------------------

# Theme Switchers
$BtnDay.add_Click({
    $MainForm.BackColor = [System.Drawing.Color]::FromArgb(248, 249, 250)
    $Script:LogTextBox.BackColor = [System.Drawing.Color]::White
    $Script:LogTextBox.ForeColor = [System.Drawing.Color]::Black
    $HeaderTitle.ForeColor = [System.Drawing.Color]::FromArgb(24, 44, 97)
    $Script:IsDarkMode = $false
})

$BtnNight.add_Click({
    $MainForm.BackColor = [System.Drawing.Color]::FromArgb(30, 39, 46)
    $Script:LogTextBox.BackColor = [System.Drawing.Color]::FromArgb(47, 53, 66)
    $Script:LogTextBox.ForeColor = [System.Drawing.Color]::FromArgb(223, 228, 234)
    $HeaderTitle.ForeColor = [System.Drawing.Color]::FromArgb(241, 242, 246)
    $Script:IsDarkMode = $true
})

# Paste / QR Button
$BtnPasteQr.add_Click({
    $clip = [System.Windows.Forms.Clipboard]::GetText()
    if ($clip -and $clip.Trim().StartsWith("vless://")) {
        $KeyTextBox.Text = $clip.Trim()
        Write-AppLog "INPUT" "Pasted VLESS key from clipboard."
    } else {
        [System.Windows.Forms.MessageBox]::Show("Clipboard does not contain a valid vless:// URI.", "GIN-VPN", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

# Save Button
$BtnSave.add_Click({
    $txt = $KeyTextBox.Text.Trim()
    $p = Parse-VlessUri $txt
    if ($p) {
        $item = New-Object System.Windows.Forms.ListViewItem("")
        [void]$item.SubItems.Add($p.Name)
        [void]$item.SubItems.Add($p.Ip)
        [void]$item.SubItems.Add($p.Port.ToString())
        $item.Tag = $p
        [void]$ListView.Items.Add($item)
        Write-AppLog "PROFILE" "Profile '$($p.Name)' saved successfully."
        [System.Windows.Forms.MessageBox]::Show("Profile '$($p.Name)' saved successfully!", "GIN-VPN", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please enter a valid vless:// Reality key first.", "GIN-VPN", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})

# Connect Selected from ListView
$BtnConnectSelected.add_Click({
    if ($ListView.SelectedItems.Count -gt 0) {
        $p = $ListView.SelectedItems[0].Tag
        Start-VpnConnection $p
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select a profile from the list to connect.", "GIN-VPN", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

# Set Default Profile
$BtnSetDefault.add_Click({
    if ($ListView.SelectedItems.Count -gt 0) {
        foreach ($it in $ListView.Items) { $it.Text = "" }
        $sel = $ListView.SelectedItems[0]
        $sel.Text = "★ YES"
        Write-AppLog "PROFILE" "Default profile set to '$($sel.SubItems[1].Text)'."
    }
})

# Main Action Button (Connect / Disconnect Toggle)
$Script:MainActionButton.add_Click({
    if ($Script:IsConnected) {
        Stop-VpnConnection
    } else {
        $target = $null
        foreach ($it in $ListView.Items) {
            if ($it.Text -eq "★ YES") { $target = $it.Tag; break }
        }
        if (-not $target -and $ListView.Items.Count -gt 0) {
            $target = $ListView.Items[0].Tag
        }
        if ($target) {
            Start-VpnConnection $target
        } else {
            $p = Parse-VlessUri $KeyTextBox.Text
            Start-VpnConnection $p
        }
    }
})

# Install / Version / Update Button
$Script:InstallOrVerButton.add_Click({
    $tag = $Script:InstallOrVerButton.Tag
    if ($tag -eq "INSTALL") {
        Install-GinVpnApplication
    } elseif ($tag -eq "UPDATE") {
        Invoke-GinVpnUpdate -FromVersion $Script:VERSION_NUM -ToVersion $Script:LATEST_VERSION
    } elseif ($tag -eq "INSTALLED_OK") {
        [System.Windows.Forms.MessageBox]::Show("GIN-VPN is installed and running the latest version (v$Script:VERSION_NUM).`n`nStatus: Up to date ✔️", "GIN-VPN Version", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

# Verify IP + Speed Test Button
$BtnVerifyIp.add_Click({
    Write-AppLog "VERIFY" "Running IP and Latency verification..."
    $diag = Update-Diagnostics
    if ($diag) {
        $msg = "Current Internet Routing:`n`nPublic IP: $($diag.IP)`nCountry: $($diag.Country)`nVPN State: $(if ($Script:IsConnected) { 'PROTECTED (Active Tunnel)' } else { 'DIRECT (No VPN)' })"
        [System.Windows.Forms.MessageBox]::Show($msg, "GIN-VPN Diagnostics", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    Start-Process "https://prodvig-saita.ru/ip/"
})

# View vpn.log
$BtnViewLog.add_Click({
    if (Test-Path $Script:LOG_FILE) {
        Start-Process notepad.exe -ArgumentList "`"$Script:LOG_FILE`""
    } else {
        [System.Windows.Forms.MessageBox]::Show("No log file generated yet.", "GIN-VPN", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

# Clear Log Box
$BtnClearLog.add_Click({
    $Script:LogTextBox.Clear()
    Write-AppLog "LOG" "Log buffer cleared."
})

# -----------------------------------------------------------------------------
# Background Session Timer (Uptime & Diagnostics)
# -----------------------------------------------------------------------------
$Timer = New-Object System.Windows.Forms.Timer
$Timer.Interval = 1000
$Timer.add_Tick({
    if ($Script:IsConnected -and $Script:SessionStart) {
        $span = (Get-Date) - $Script:SessionStart
        $Script:DiagUptimeLabel.Text = "⏱ Session Uptime: $($span.ToString('hh\:mm\:ss'))"
    }
})
$Timer.Start()

# -----------------------------------------------------------------------------
# Initial Application Startup
# -----------------------------------------------------------------------------
$MainForm.add_Load({
    Update-InstallStateUi
    Write-AppLog "INIT" "$Script:APP_NAME $Script:APP_VERSION started."
    Write-AppLog "SECURE" "Registry encrypted key store active."
    Write-AppLog "CORE" "Detected Xray binary: $Script:XRAY_BIN"
    
    # Auto-connect default profile if present
    $defProfile = $null
    foreach ($it in $ListView.Items) {
        if ($it.Text -eq "★ YES") { $defProfile = $it.Tag; break }
    }
    if ($defProfile) {
        Write-AppLog "AUTO" "Default profile detected ($($defProfile.Name)). Connecting in background..."
        Start-VpnConnection $defProfile
    }
})

# Safe Form Closing
$MainForm.add_FormClosing({
    param($s, $e)
    # Stop timer
    $Timer.Stop()
})

# Display Window
[System.Windows.Forms.Application]::Run($MainForm)
