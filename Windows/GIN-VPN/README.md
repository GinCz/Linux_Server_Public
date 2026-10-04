# 🛡️ GIN-VPN by VladiMIR+AI__v002 — High-Speed Native Windows Xray VPN Client

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server%202008--2025-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v002%20(Public%20Release)-green.svg)](https://github.com/GinCz/Linux_Server_Public)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Type](https://img.shields.io/badge/Type-Standalone%20Win32%20GUI%20(Zero%20Install)-purple.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Speed](https://img.shields.io/badge/Tunnel-VLESS%20Reality%20%2B%20Vision-orange.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-VPN** is an ultra-fast, lightweight, standalone native Windows GUI client for high-speed, censorship-resistant VPN connections based on **Xray Core (VLESS + Reality + Vision)**.

Supports all Windows operating systems and architectures (**Windows 7, 8, 8.1, 10, 11** and **Windows Server 2008, 2012, 2016, 2019, 2022, 2025**). Built directly on pure Win32 API without heavy frameworks (Electron/WPF/.NET), without command-line windows, and with zero external runtime dependencies. **100% Free & Open Source for public use.**

---

## ⚡ Quick Download & Run (100% Free)

- **Latest Release (.exe):** [`GIN-VPN_v002.exe`](https://github.com/GinCz/Linux_Server_Public/raw/main/Windows/GIN-VPN/GIN-VPN_v002.exe)
- **Source Code (.go):** [`main.go`](main.go)
- **Application Icon (.ico):** [`GIN-VPN.ico`](GIN-VPN.ico)
- **Resource File (.syso):** [`rsrc_windows_amd64.syso`](rsrc_windows_amd64.syso)

> **No installation required.** Just download `GIN-VPN_v002.exe` and double-click to run on any Windows PC or Server.
> *(In accordance with our repository policy, only the latest release binary is kept available for direct download).*

---

## 🌟 Core Features (v002)

- **☀️ Clean Day / Light Aesthetic Theme:**
  Designed with a pure white workspace (`#FFFFFF`), light slate panels, and crisp thin dark borders (`#2B303A`) for high readability.
- **⚡ Zero-Console Standalone Win32 GUI (`-H windowsgui`):**
  Pure native Win32 window with smooth performance and 0% idle CPU usage.
- **🛡️ Dynamic System Tray Shield Agent & Auto-Minimize:**
  Runs in the notification area with live status icons:
  - 🟢 **Green Shield**: Protected & Connected (tunnel verified, proxy active)
  - 🟠 **Orange Shield**: Connecting / Handshaking / Verifying routing
  - 🔴 **Red Shield**: Connection failed / Server unreachable / Key syntax error
  - ⚪ **Gray Shield**: Idle / Disconnected
  - **Auto-Minimize**: When `[▶ CONNECT VPN]` is clicked and tunnel connects, the window automatically minimizes down to the system tray.
  - **Close-to-Tray Safety**: Clicking the window close button `[X]` minimizes the client to the tray without terminating the VPN connection.
  - **Auto-Connect on Launch**: If a saved default profile exists, the app launches minimized directly in the tray and connects automatically in the background.
- **📋 Multi-Line Wrapped Key Box with One-Click Buffer Actions:**
  Full multi-line word wrap (`ES_MULTILINE | WS_VSCROLL`) displaying the entire VLESS key without horizontal clipping. Includes `[📋 Clear & Paste from Buffer]` and `[💾 Save]` buttons, auto-detecting the node name from `#...`.
- **📑 Multi-Profile Key Manager:**
  Dedicated table for managing multiple VPN profiles (`profiles.json`) with `[▶ Connect]`, `[★ Set Default]`, and `[🗑️ Delete]` controls.
- **🌐 Instant System Proxy Activation via WinINet:**
  Applies system proxy (`127.0.0.1:10809`) via Win32 API (`InternetSetOptionW`) without rebooting or UAC prompts.
- **🌍 Real-Time IP & Country Verification:**
  Resolves and displays **Original ISP IP** vs **Protected VPN IP** with international 2-letter country flags/codes before and after connecting.
- **⏱️ Live Uptime & RTT Latency Meter:**
  Measures live round-trip time (RTT ping) to the server node and tracks active session duration.
- **🔒 Anti-Leak & Clean Exit Guarantee:**
  Automatically reverts all proxy settings and cleanly terminates child processes upon choosing `Disconnect & Exit`.
- **📥 One-Click Core Downloader:**
  If `xray.exe` is missing from the local folder, clicking `[📥 Download Core]` automatically fetches the verified binary from the dedicated Russian master server RU-109 (`prodvig-saita.ru`).

---

## 🖱️ System Tray Context Menu

Right-click the shield icon in the notification area for instant controls:

```text
┌──────────────────────────────────────┐
│  VPN: 195.63.138.33 (NL)             │  (Live Status Badge)
├──────────────────────────────────────┤
│  📂 Open GIN-VPN Dashboard           │  (Restore Main Window)
│  ⏹ Disconnect VPN                   │  (Instant Proxy Toggle)
│  🌐 Verify IP + Speed Test           │  (Opens IP Verification & Speedtest)
│  📝 Edit Key (link.txt)              │  (Quick Key Editor)
│  📋 View vpn.log                     │  (Diagnostic Log Viewer)
├──────────────────────────────────────┤
│  ❌ Disconnect && Exit               │  (Clean Shutdown & Proxy Reset)
└──────────────────────────────────────┘
```

---

## 🛠️ Build from Source

Requirements: Go 1.19+ and MinGW-w64 windres.

```bash
# Clone the repository
git clone https://github.com/GinCz/Linux_Server_Public.git
cd Linux_Server_Public/Windows/GIN-VPN

# Compile resources with embedded icon
x86_64-w64-mingw32-windres --preprocessor="cpp" -i app.rc -O coff -o rsrc_windows_amd64.syso

# Cross-compile for Windows x86_64 (GUI mode, stripped)
GOOS=windows GOARCH=amd64 go build -ldflags="-H windowsgui -s -w" -o GIN-VPN_v002.exe main.go
```

---

## 📜 License & Credits

- **Developer:** [Vladimir Bulantsev (GinCz) ↗](https://github.com/GinCz)
- **Engine:** VladiMIR+AI Autonomous Development Suite
- **License:** [MIT License](https://opensource.org/licenses/MIT) — 100% Free for personal, commercial, and enterprise use.
