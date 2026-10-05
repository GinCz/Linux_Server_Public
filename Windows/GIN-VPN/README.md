# 🛡️ GIN-VPN by VladiMIR+AI — High-Speed Native Windows Xray Client (v041)

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v041%20(Production%20Release)-green.svg)](https://github.com/GinCz/Windows_scripts)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Engine](https://img.shields.io/badge/Engine-Xray%20Core%20VLESS--Reality%20%2B%20Vision-orange.svg)](https://github.com/GinCz/Windows_scripts)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-VPN** is an ultra-fast, lightweight, 100% standalone all-in-one native Windows GUI client for **Xray Core (VLESS + Reality + Vision)**. Engineered for high-throughput network tunneling, zero background bloat, **Privacy-First Clean Initial Profiles on New Workstations (Zero Private Servers Bundled)**, **Automatic Profile & Settings Migration into Program Files on Installation**, **Pixel-Perfect Rectangular Solid Button Rendering (Zero White Corner Artifacts in OLED Night Mode)**, **Single Country Code Display**, **2-Column Dedicated Rules Info Modal & Custom Direct Domain Manager**, **Live Xray Routing Table Hot-Reloading**, **Clean Compact 2-Line Diagnostics Card**, **Auto-Connect on Startup with Instant Tray Minimization**, **Close-to-Tray Protection (X button minimizes to tray)**, **1080p Screen Height Optimized Layout (<700px)**, **One-Click "Copy All" Event Log Buffer**, **Embedded High-Performance Xray Core Engine** (100% self-contained single executable, zero external dependencies or downloads required), solid connected row highlight (Dark Forest Green + Vivid Yellow bold text), dynamic green system tray indicator, real-time Original ISP & VPN Geo-IP telemetry, volumetric 3D button design, full OLED Dark & Day theme switching, multi-language support (English / Russian), persistent profile management (Registry + local JSON store), and clean 3D wireframe Easter Egg dialog (`VladiMIR+AI`).

---

## ⚡ Download & Direct Execution

- **Standalone Native Binary:** [`GIN-VPN_v041.exe`](GIN-VPN_v041.exe) / [`GIN-VPN.exe`](GIN-VPN.exe)
- **Multi-Resolution Golden Shield Icon:** [`Gin-VPN.ico`](Gin-VPN.ico)
- **Connected Dynamic Tray Icon:** [`Gin-VPN-green.ico`](Gin-VPN-green.ico)

> **Zero installation or external downloads required.** Simply run `GIN-VPN_v041.exe` on any Windows workstation or server (Windows 7 SP1, 8.1, 10, 11, Server 2008–2025). The complete high-speed Xray Core is embedded directly within the application.

---

## 🌟 Key Innovations in v041

1. **Clean Privacy-First Profiles on New Installations:**
   - When launching on a clean PC without pre-existing registry data, the profile list starts completely **empty (0 servers)**, protecting your private server credentials from leaking to third parties.
   - For existing installations, all profiles are preserved and read safely from Windows Registry (`HKCU\Software\VladiMIR\GIN-VPN`) and `%LOCALAPPDATA%\GIN-VPN\profiles.json`.

2. **Automatic Registry-to-Program-Files Settings Migration on Install:**
   - Clicking `[ 📑 Установить / 📑 Install App ]` installs the application to `C:\Program Files\GIN-VPN\` and automatically migrates all active profiles, default server selection, and custom routing rules into the installed directory and registry.

3. **Solid Monolithic Rectangular Rendering (Zero White Corners in Dark Mode):**
   - Replaced rounded polygon GDI drawing with precise `procRectangle` rendering for all buttons and panels, completely eliminating white corner artifacts in Dark/Night OLED mode.

4. **Dedicated 2-Column Rules Modal & Custom Direct Domain Manager:**
   - Inspect standard Russian domains (Direct) vs. Global services (VPN) in 2 parallel columns, with an editable box for custom local domains (utility portals, housing portals, local municipal services).
   - Real-time live hot-reloading of Xray Core routing tables without session drop.

5. **100% Standalone All-In-One Architecture:**
   - Embedded Xray Core payload directly inside `GIN-VPN_v041.exe`.

---

## 🏛️ System Architecture

```text
┌────────────────────────────────────────────────────────┐
│               GIN-VPN.exe (Single Binary)              │
│  ┌─────────────────────────┐  ┌─────────────────────┐  │
│  │    Win32 GUI Client     │  │ Embedded Xray Core  │  │
│  │ (Dark/Day, Tray, Rules) │  │  (Compressed Gzip)  │  │
│  └────────────┬────────────┘  └──────────┬──────────┘  │
└───────────────┼──────────────────────────┼─────────────┘
                │                          │ (Instant In-Memory Unpack)
                │ IPC Config               ▼
        ┌───────▼───────────────────────────────┐
        │        Local Xray Core Daemon         │
        └───────────────────┬───────────────────┘
                            │ (TLS Reality Tunnel)
        ┌───────────────────▼───────────────────┐
        │  DE-222 / RU-109 / IONOS-38 Gateways  │
        └───────────────────┬───────────────────┘
```

---

## 🔒 Triple-Lock & Repository Mirroring
- **GitHub Repository (Windows Scripts):** [Windows_scripts ↗](https://github.com/GinCz/Windows_scripts)
- **GitHub Repository (Public Linux/Windows):** [Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public)
- **Author:** Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz))
