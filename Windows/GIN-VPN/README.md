# 🛡️ GIN-VPN by VladiMIR+AI — High-Speed Native Windows Xray Client (v037)

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v037%20(Production%20Release)-green.svg)](https://github.com/GinCz/Windows_scripts)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Engine](https://img.shields.io/badge/Engine-Xray%20Core%20VLESS--Reality%20%2B%20Vision-orange.svg)](https://github.com/GinCz/Windows_scripts)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-VPN** is an ultra-fast, lightweight, 100% standalone all-in-one native Windows GUI client for **Xray Core (VLESS + Reality + Vision)**. Engineered for high-throughput network tunneling, zero background bloat, **Consolidated Bold Diagnostics Status Indicator**, **One-Click "Copy All" Event Log Buffer**, **Smart Geo-Aware Split Routing Matrix** (`RU => EU` / `EU => RU`) with **Interactive Multi-line Hover Tooltip Explanations**, **Auto-Connect on Startup with Instant Tray Minimization**, **Close-to-Tray Protection (X button minimizes to tray)**, **1080p Screen Height Optimized Layout (<700px)**, **Embedded High-Performance Xray Core Engine** (100% self-contained single executable, zero external dependencies or downloads required), solid connected row highlight (Dark Forest Green + Vivid Yellow bold text), dynamic green system tray indicator, real-time Original ISP & VPN Geo-IP telemetry, volumetric 3D button design, full OLED Dark & Day theme switching, multi-language support (English / Russian), persistent profile management (Registry + local JSON store), and clean 3D wireframe Easter Egg dialog (`VladiMIR+AI`).

---

## ⚡ Download & Direct Execution

- **Standalone Native Binary:** [`GIN-VPN_v037.exe`](GIN-VPN_v037.exe) / [`GIN-VPN.exe`](GIN-VPN.exe)
- **Multi-Resolution Golden Shield Icon:** [`Gin-VPN.ico`](Gin-VPN.ico)
- **Connected Dynamic Tray Icon:** [`Gin-VPN-green.ico`](Gin-VPN-green.ico)

> **Zero installation or external downloads required.** Simply run `GIN-VPN_v037.exe` on any Windows workstation or server (Windows 7 SP1, 8.1, 10, 11, Server 2008–2025). The complete high-speed Xray Core is embedded directly within the application.

---

## 🌟 Key Features in v037

1. **Consolidated Bold Status in Diagnostics Card:**
   - Removed redundant secondary header status line.
   - Status is cleanly integrated directly into the Diagnostics Card (`⚡ Diagnostics & Routing`), displaying bold vibrant green `🟢 Connected: <IP>`, yellow `🟡 Connecting...`, or red `🔴 Disconnected`.

2. **Dedicated One-Click `[ 📋 Copy All ]` / `[ 📋 Копировать всё ]`:**
   - Replaced "View Log" with a direct one-click action that copies the complete event log buffer to the Windows clipboard.
   - Full keyboard `Ctrl+A` (Select All) support inside the VLESS key input and log view.

3. **Interactive Multi-line Hover Tooltips for Smart Split Routing:**
   - Hovering over any server profile row in the list or the diagnostics telemetry card displays an informative multi-line tooltip explaining direct bypass vs proxied traffic:
     - **`[ RU => EU ]`:** Russian sites (`.ru`, Gosuslugi, Mos.ru, VK, Banks) connect directly without wasting VPN quota; YouTube, Instagram, Facebook, Twitter, Spotify, OpenAI proxy via encrypted tunnel.
     - **`[ EU => RU ]`:** European/global sites (YouTube, Netflix, Spotify, EU banks) connect directly at full Gigabit speed; Russian government & geo-blocked portals proxy through the Russian node.

4. **Auto-Connect on App Launch (Right-Click Context Menu Option):**
   - Right-click any server profile in the list and check `✓ Auto-connect on App Startup` (`✓ Подключаться при запуске программы`).
   - Automatically connects on launch and minimizes quietly to the system tray.

5. **Close-to-Tray Protection (Window X Button):**
   - Clicking the title bar "X" close button minimizes GIN-VPN to the system tray rather than killing the process, keeping your active VPN tunnel protected.
   - To completely exit the client, use the Tray context menu option (`Exit GIN-VPN` / `Выход`).

6. **1080p / High-DPI Optimized Compact Layout:**
   - Window dimensions (595x695) comfortably fit 1080p displays with 125%/150% scaling and taskbar visible.
   - Clean, crisp compact Consolas log font.

7. **100% Standalone All-In-One Architecture:**
   - The entire Xray Core engine payload is embedded directly inside `GIN-VPN_v037.exe`.
   - Works immediately out of the box on any fresh machine, completely offline or online, without searching external directories or downloading external binaries.

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
