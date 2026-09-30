# 🛡️ Windows Advanced Security & Cryptominer Deep Audit

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20%7C%20Server-blue.svg)](https://microsoft.com/windows)
[![Engine](https://img.shields.io/badge/Engine-PowerShell%205.1%2B%20%7C%20Polyglot%20CMD-green.svg)](https://learn.microsoft.com/en-us/powershell/)
[![Security](https://img.shields.io/badge/Security-Deep%20Cryptominer%20%26%20Rootkit%20Audit-red.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A lightweight, zero-dependency, self-elevating security audit script for Windows workstations and servers. Engineered to detect hidden background cryptocurrency miners, masquerading system processes, unauthorized remote desktop agents, reverse tunnels, malicious persistence hooks, and compromised Windows Defender configurations.

---

## ⚡ Quick Start

### Option 1: Direct Run (One-Click)
1. Download [`System_Security_Miner_Audit.cmd`](System_Security_Miner_Audit.cmd).
2. Double-click the file. It will automatically trigger standard Windows UAC elevation and execute the audit with zero manual configuration.

### Option 2: Run via PowerShell / CMD (Administrator)
```cmd
cmd.exe /c "System_Security_Miner_Audit.cmd"
```

---

## 🔍 Core Security Vectors (16 Inspection Modules)

| # | Check Vector | Description | Threat Level |
| :---: | :--- | :--- | :---: |
| **`[01]`** | **CPU Load Sampling** | Samples all active processes over 5 seconds across all logical CPU cores to detect stealthy CPU-throttling miners. | `WARN` |
| **`[02]`** | **Cryptominer Signatures** | Inspects running process names, binary paths, and CLI parameters for 30+ known mining engines (`xmrig`, `phoenixminer`, `nbminer`, `t-rex`, `lolminer`, `srbminer`, `cpuminer`, `randomx`, `cryptonight`, etc.). | `CRIT` |
| **`[03]`** | **Process Integrity & Spoofing** | Validates Authenticode signatures and checks for fake system processes (`svchost.exe`, `lsass.exe`, `csrss.exe`) executing outside the `System32` directory. | `CRIT` / `WARN` |
| **`[04]`** | **Mining Pool Sockets** | Inspects active TCP connections for standard Stratum mining ports (`3333`, `4444`, `5555`, `14444`, `45560`, etc.) connecting to non-private IPs. | `WARN` |
| **`[05]`** | **Mining Pool DNS Cache** | Audits the local Windows DNS Client Cache for queries to known mining pool endpoints (`nanopool`, `minexmr`, `supportxmr`, `2miners`, `f2pool`, `unmineable`, `kryptex`, etc.). | `WARN` |
| **`[06]`** | **Reverse Tunnels & Proxies** | Identifies active stealth reverse tunneling clients (`ngrok`, `cloudflared`, `frpc`, `chisel`, `ligolo`, `bore`, `localxpose`, `pagekite`). | `WARN` |
| **`[07]`** | **Remote Access Software** | Detects remote administration and screen-sharing agents (`RustDesk`, `TeamViewer`, `AnyDesk`, `Radmin`, `Splashtop`, `ScreenConnect`, `VNC`, etc.) with process instance counts. | `INFO` / `OK` |
| **`[08]`** | **Task Scheduler Triggers** | Audits Windows Task Scheduler for suspicious download stagers (`-enc`, `certutil -urlcache`, `downloadstring`, `IEX`, `mshta`, `bitsadmin`) and untrusted tasks in user folders. | `CRIT` / `WARN` |
| **`[09]`** | **Registry Autorun & Shell** | Scans `Run` / `RunOnce` registry keys and verifies that `Winlogon\Shell` (`explorer.exe`) and `Userinit` have not been hijacked. | `CRIT` / `WARN` |
| **`[10]`** | **Startup Folders** | Inspects user and global `Startup` directories (`shell:startup` and `shell:common startup`) for unauthorized `.bat`, `.cmd`, `.vbs`, `.ps1`, or `.hta` scripts. | `WARN` |
| **`[11]`** | **IFEO Process Hijacking** | Scans `Image File Execution Options` for debugger redirections used by malware to intercept task managers or security tools. | `CRIT` |
| **`[12]`** | **Local Administrators** | Audits members of the local `Administrators` group (`SID S-1-5-32-544`) to detect unauthorized backdoor accounts. | `WARN` |
| **`[13]`** | **WMI Event Persistence** | Queries `root\subscription:__EventConsumer` for hidden WMI event bindings used for stealth persistence across reboots. | `CRIT` |
| **`[14]`** | **Windows Defender Health** | Verifies Real-Time Protection state, antivirus signature age, and detects dangerous path exclusions (e.g. `C:\`, `G:\`, `Temp`, `Downloads`). | `CRIT` / `WARN` |
| **`[15]`** | **Low-Level Hardware Drivers** | Scans loaded kernel drivers for hardware-access exploits commonly bundled with miners (`WinRing0`, `InpOut`, `ProcessHacker`). | `WARN` |
| **`[16]`** | **Hosts & Proxy Hijacking** | Detects blocked security vendor updates (`microsoft`, `windowsupdate`, `defender`, `virustotal`) in the `hosts` file. | `CRIT` |
| **`[17]`** | **Dropped Miner Configs** | Recursively scans `AppData`, `ProgramData`, and `Temp` directories for orphaned miner configuration files (`config.json` containing pool or wallet signatures). | `CRIT` |

---

## 🎨 Minimalist Terminal User Interface

The audit interface employs a clean, high-contrast palette:
- **Green (`[ OK ]`)**: Check passed, normal operating state.
- **Yellow (`[ NO ]` / `Warning`)**: Suspicious artifact detected (unsigned binary, custom startup script, high CPU consumer).
- **Red (`[ NO ]` / `Critical`)**: Severe security violation (disabled antivirus, root folder exclusions, active cryptominer).

### Multi-Language Support
Upon launch, select your preferred language:
- `[1] English` *(Default)*
- `[2] Česky`
- `[3] Русский`

---

## 📄 Automated Report Generation

At the conclusion of each audit, a structured, UTF-8 encoded report is automatically exported directly to the user's **actual Desktop** (automatically resolving custom/redirected paths such as OneDrive or external drive mappings):

```text
%USERPROFILE%\Desktop\Security_Audit_Report.txt
```

---

## 🔒 Polyglot Architecture

The script combines a Windows batch wrapper and an advanced PowerShell engine in a single file:

```bat
<# :
@echo off
setlocal
chcp 65001 >nul
title System Security & Cryptominer Audit - VladiMIR+AI
fltmc >nul 2>&1 || (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -LiteralPath '%~f0' -Encoding UTF8) -join [Environment]::NewLine)"
if %errorlevel% neq 0 pause
exit /b %errorlevel%
#>
# PowerShell Implementation starts here...
```

---

## 📜 License & Credits

- **Author & Project**: VladiMIR+AI ([GinCz ↗](https://github.com/GinCz))
- **Part of**: [Linux Server Public ↗](https://github.com/GinCz/Linux_Server_Public) & [Secret Privat ↗](https://github.com/GinCz/Secret_Privat)
- **License**: MIT License
