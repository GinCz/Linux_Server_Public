# 🛡️ GIN-VPN by VladiMIR+AI__v003 — High-Speed Native Windows Xray VPN Client

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server%202008--2025-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v003%20(Public%20Release)-green.svg)](https://github.com/GinCz/Linux_Server_Public)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Type](https://img.shields.io/badge/Type-Standalone%20Win32%20GUI%20%2B%201--Click%20Install-purple.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Speed](https://img.shields.io/badge/Tunnel-VLESS%20Reality%20%2B%20Vision-orange.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-VPN** is an ultra-fast, lightweight, standalone native Windows GUI client for high-speed, censorship-resistant VPN connections based on **Xray Core (VLESS + Reality + Vision)**.

Supports all Windows operating systems and architectures (**Windows 7, 8, 8.1, 10, 11** and **Windows Server 2008, 2012, 2016, 2019, 2022, 2025**). Built directly on pure Win32 API without heavy frameworks (Electron/WPF/.NET), without command-line windows, and with zero external runtime dependencies. **100% Free & Open Source for public use.**

---

## ⚡ Quick Download & Run (100% Free)

- **Latest Release (.exe):** [`GIN-VPN_v003.exe`](https://github.com/GinCz/Linux_Server_Public/raw/main/Windows/GIN-VPN/GIN-VPN_v003.exe)
- **Source Code (.go):** [`main.go`](main.go)
- **Application Icon (.ico):** [`GIN-VPN.ico`](GIN-VPN.ico)
- **Resource File (.syso):** [`rsrc_windows_amd64.syso`](rsrc_windows_amd64.syso)

> **Portable + 1-Click Install:** Run anywhere as a portable executable or click **`[ 💾 Install App ]`** inside the app to install permanently to `C:\Program Files\GIN-VPN\` with Desktop & Start Menu shortcuts.

---

## 🌟 Core Features (v003)

- **🛡️ 100% Windows 7 (SP1) & Windows 10/11 Universal Architecture:**
  Compiled with Go 1.19 and pure native Win32 core APIs (`user32`, `kernel32`, `gdi32`, `comctl32`, `advapi32`, `wininet`). Fully supports Windows 7 without TLS handshake crashes or missing API errors, including automatic byte synchronization for legacy connection settings (`DefaultConnectionSettings` and `SavedLegacySettings`).
- **💾 One-Click Automated Installer (`[ 💾 Install App ]`):**
  Installs `GIN-VPN.exe` to `C:\Program Files\GIN-VPN\`, configures full read/write permissions via `icacls` (preventing UAC permission errors for keys/logs), migrates all existing profiles, keys, and cores, and automatically generates **Desktop and Start Menu shortcuts**.
- **🎨 High-Definition 3D Vector Shield Icon:**
  Crisp multi-resolution Windows icon (256x256 to 16x16) directly embedded into the executable PE resource section for sharp rendering in Explorer and taskbars.
- **☀️ Clean Day / Light Aesthetic Theme:**
  Designed with a pure white workspace (`#FFFFFF`), light slate panels, and crisp thin dark borders (`#2B303A`) for high readability.
- **🛡️ Dynamic System Tray Shield Agent & Auto-Minimize:**
  Runs smoothly in the notification area with live status icons:
  - 🟢 **Green Shield**: Protected & Connected (tunnel verified, proxy active)
  - 🟠 **Orange Shield**: Connecting / Handshaking / Verifying routing
  - 🔴 **Red Shield**: Connection failed / Server unreachable / Key syntax error
  - ⚪ **Gray Shield**: Idle / Disconnected
  - **Auto-Minimize**: When `[▶ CONNECT VPN]` connects, the window automatically minimizes down to the system tray.
  - **Close-to-Tray Safety**: Clicking `[X]` minimizes to tray without interrupting the VPN tunnel.
  - **Auto-Connect on Launch**: If a default profile exists, launches directly to tray and connects in the background.
- **📋 Multi-Line Wrapped Key Box with One-Click Buffer Actions:**
  Full multi-line word wrap (`ES_MULTILINE | WS_VSCROLL`) displaying the entire VLESS key without horizontal clipping. Includes `[📋 Clear & Paste from Buffer]` and `[💾 Save]` buttons, auto-detecting the node name from `#...`.
- **📑 Multi-Profile Key Manager:**
  Dedicated table for managing multiple VPN profiles (`profiles.json`) with `[▶ Connect]`, `[★ Set Default]`, and `[🗑️ Delete]` controls.
- **🌐 Instant System Proxy Activation via WinINet:**
  Applies system proxy (`127.0.0.1:10809`) via Win32 API (`InternetSetOptionW`) without rebooting.
- **🌍 Real-Time IP & Country Verification:**
  Resolves and displays **Original ISP IP** vs **Protected VPN IP** with international 2-letter country flags/codes.
- **⏱️ Live Uptime & RTT Latency Meter:**
  Measures live round-trip time (RTT ping) to the server node and tracks active session duration.

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
GOOS=windows GOARCH=amd64 go build -ldflags="-H windowsgui -s -w" -o GIN-VPN_v003.exe main.go
```

---

## 📜 License & Credits

- **Developer:** [Vladimir Bulantsev (GinCz) ↗](https://github.com/GinCz)
- **Engine:** VladiMIR+AI Autonomous Development Suite
- **License:** [MIT License](https://opensource.org/licenses/MIT) — 100% Free for personal, commercial, and enterprise use.
