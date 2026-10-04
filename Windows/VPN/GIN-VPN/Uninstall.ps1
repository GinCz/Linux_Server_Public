# =============================================================================
# Execution Context : PowerShell (Administrator)
# Application       : GIN-VPN Official Windows Uninstaller
# Author            : Vladimir Bulantsev (GinCz) + Antigravity AI
# =============================================================================

param([switch]$Silent)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$targetDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $targetDir) { $targetDir = "$env:ProgramFiles\GIN-VPN" }

# 1. Terminate running processes
Get-Process xray, GIN-VPN -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

# 2. Reset System Proxy to Direct Connection
$reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
Set-ItemProperty -Path $reg -Name ProxyEnable -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty -Path $reg -Name ProxyServer -Value "" -Type String -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $reg -Name ProxyServer -ErrorAction SilentlyContinue

# WinINet Sync
$winINetTypeDef = @"
using System;
using System.Runtime.InteropServices;
public class WinINetUninstallerSync {
    [DllImport("wininet.dll", SetLastError = true)]
    public static extern bool InternetSetOption(IntPtr hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);
    public static void Sync() {
        InternetSetOption(IntPtr.Zero, 39, IntPtr.Zero, 0);
        InternetSetOption(IntPtr.Zero, 37, IntPtr.Zero, 0);
    }
}
"@
Add-Type -TypeDefinition $winINetTypeDef -ErrorAction SilentlyContinue
[WinINetUninstallerSync]::Sync()

# 3. Remove Windows Add/Remove Programs Registry Entries
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-VPN" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-VPN" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "HKCU:\Software\VladiMIR\GIN-VPN" -Recurse -Force -ErrorAction SilentlyContinue

# 4. Remove Desktop and Start Menu Shortcuts
$desktopLnk = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "GIN-VPN.lnk")
$startMenuDir = [System.IO.Path]::Combine([Environment]::GetFolderPath("Programs"), "GIN-VPN")
$commonStartDir = [System.IO.Path]::Combine([Environment]::GetFolderPath("CommonPrograms"), "GIN-VPN")

Remove-Item -Path $desktopLnk -Force -ErrorAction SilentlyContinue
Remove-Item -Path $startMenuDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $commonStartDir -Recurse -Force -ErrorAction SilentlyContinue

# 5. Self-delete folder asynchronously after exit
Start-Process -FilePath cmd.exe -ArgumentList "/c timeout /t 2 /nobreak >nul & rd /s /q `"$targetDir`"" -WindowStyle Hidden

if (-not $Silent) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("GIN-VPN has been successfully uninstalled from your computer.`nDirect internet connection has been restored.", "GIN-VPN Uninstaller", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}
