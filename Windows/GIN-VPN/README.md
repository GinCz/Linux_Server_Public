# 🛡️ GIN-VPN by VladiMIR+AI — High-Speed Native Windows Xray Client (v040)

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v040%20(Production%20Release)-green.svg)](https://github.com/GinCz/Windows_scripts)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Engine](https://img.shields.io/badge/Engine-Xray%20Core%20VLESS--Reality%20%2B%20Vision-orange.svg)](https://github.com/GinCz/Windows_scripts)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-VPN** is an ultra-fast, lightweight, 100% standalone all-in-one native Windows GUI client for **Xray Core (VLESS + Reality + Vision)**. Engineered for high-throughput network tunneling, zero background bloat, **2-Column Dedicated Rules Info Modal & Custom Direct Domain Manager**, **Live Xray Routing Table Hot-Reloading**, **Clean Compact 2-Line Diagnostics Card**, **Clean Country Code Displays (no redundant duplicate tags)**, **Auto-Connect on Startup with Instant Tray Minimization**, **Close-to-Tray Protection (X button minimizes to tray)**, **1080p Screen Height Optimized Layout (<700px)**, **One-Click "Copy All" Event Log Buffer**, **Embedded High-Performance Xray Core Engine** (100% self-contained single executable, zero external dependencies or downloads required), solid connected row highlight (Dark Forest Green + Vivid Yellow bold text), dynamic green system tray indicator, real-time Original ISP & VPN Geo-IP telemetry, volumetric 3D button design, full OLED Dark & Day theme switching, multi-language support (English / Russian), persistent profile management (Registry + local JSON store), and clean 3D wireframe Easter Egg dialog (`VladiMIR+AI`).

---

## ⚡ Download & Direct Execution

- **Standalone Native Binary:** [`GIN-VPN_v040.exe`](GIN-VPN_v040.exe) / [`GIN-VPN.exe`](GIN-VPN.exe)
- **Multi-Resolution Golden Shield Icon:** [`Gin-VPN.ico`](Gin-VPN.ico)
- **Connected Dynamic Tray Icon:** [`Gin-VPN-green.ico`](Gin-VPN-green.ico)

> **Zero installation or external downloads required.** Simply run `GIN-VPN_v040.exe` on any Windows workstation or server (Windows 7 SP1, 8.1, 10, 11, Server 2008–2025). The complete high-speed Xray Core is embedded directly within the application.

---

## 🌟 Key Innovations in v040

1. **2-Column Dedicated Rules Modal & Custom Direct Domains Manager:**
   - **Column 1 (Left):** Read-only list of all built-in Russian services (`*.ru`, `*.рф`, `*.su`, Госуслуги, mos.ru, Сбер, Т-Банк, ВТБ, Альфа, VK, Яндекс, Ozon, WB, Авито, Мосэнергосбыт, ЕИРЦ, Кинопоиск, RuTube, 2GIS и др.) that connect directly at local Gigabit speeds without consuming VPN bandwidth.
   - **Column 2 (Right):** Read-only list of all built-in global services (YouTube, Instagram, Facebook, X/Twitter, Spotify, ChatGPT/OpenAI, Claude, Netflix, Telegram, Discord, LinkedIn, Google, GitHub и др.) routed securely via the encrypted VLESS Reality tunnel.
   - **Bottom Custom Editor:** Dedicated multiline input box for user-added custom direct domains (e.g., local municipal portals, Moscow utility payment portals, mother-in-law's housing sites).
   - **Live Hot-Reloading:** When saving new rules, the embedded Xray Core dynamically hot-reloads its routing table in real-time without dropping active connections.
   - **Persistent Storage:** Custom domains are saved in `%LOCALAPPDATA%\GIN-VPN\custom_rules.json`.

2. **Clean Compact 2-Line Diagnostics Card:**
   - Removed unnecessary 4th line from the main screen Diagnostics rectangle.
   - Header with `[ ℹ️ Инфо ]` / `[ ℹ️ Info ]` button.
   - Clean telemetry with no duplicate country codes (e.g. `VPN IP: 🟢 212.109.223.109 (RU)`).

3. **100% Standalone All-In-One Architecture:**
   - The entire Xray Core engine payload is embedded directly inside `GIN-VPN_v040.exe`.

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
