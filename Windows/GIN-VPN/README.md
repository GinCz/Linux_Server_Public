# 🛡️ GIN-VPN by VladiMIR+AI — High-Speed Native Windows Xray Client (v036)

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v036%20(Production%20Release)-green.svg)](https://github.com/GinCz/Windows_scripts)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Engine](https://img.shields.io/badge/Engine-Xray%20Core%20VLESS--Reality%20%2B%20Vision-orange.svg)](https://github.com/GinCz/Windows_scripts)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-VPN** is an ultra-fast, lightweight, 100% standalone all-in-one native Windows GUI client for **Xray Core (VLESS + Reality + Vision)**. Engineered for high-throughput network tunneling, zero background bloat, **Auto-Connect on App Launch with Instant Tray Minimization**, **Close-to-Tray Protection (X button minimizes to tray)**, **1080p Screen Height Optimized Layout (700px)**, **One-Click Event Log Copy & Native Ctrl+A Support**, **Integrated Live Update Checker**, **Embedded High-Performance Xray Core Engine** (100% self-contained single executable, zero external dependencies or downloads required), **Smart Geo-Aware Split Routing Matrix** (`RU => EU` / `EU => RU`) with zero external dat-file dependencies, interactive hover popup explanations, clean server route switching, bold large green status indicators, solid connected row highlight (Dark Green + Vivid Yellow text), minimalist single-line telemetry diagnostics, dynamic green system tray indicator, real-time Original ISP & VPN Geo-IP (Country/City) tray context display, volumetric 3D beveled button design, full OLED Dark & Day theme switching, multi-language support (English / Russian), persistent profile management (Registry + local JSON store), server numbering grid, dual-gateway telemetry verification (EU-222 / RU-109), right-click server profile CRUD operations, and clean 3D rotating wireframe Easter Egg dialog (`VladiMIR+AI`).

---

## ⚡ Download & Direct Execution

- **Standalone Native Binary:** [`GIN-VPN_v036.exe`](GIN-VPN_v036.exe) / [`GIN-VPN.exe`](GIN-VPN.exe)
- **Multi-Resolution Golden Shield Icon:** [`Gin-VPN.ico`](Gin-VPN.ico)
- **Connected Dynamic Tray Icon:** [`Gin-VPN-green.ico`](Gin-VPN-green.ico)

> **Zero installation or external downloads required.** Simply run `GIN-VPN_v036.exe` on any Windows workstation or server (Windows 7 SP1, 8.1, 10, 11, Server 2008–2025). The complete high-speed Xray Core is embedded directly within the application.

---

## 🌟 Key Features in v036

1. **Auto-Connect on App Launch (Right-Click Context Menu Option):**
   - Right-click any server profile in the list and check `✓ Auto-connect on App Startup` (`✓ Подключаться при запуске программы`).
   - When GIN-VPN starts, it automatically connects to your chosen profile and starts cleanly minimized in the system tray with a green indicator.

2. **Close-to-Tray Protection (Window X Button):**
   - Clicking the title bar "X" close button now minimizes GIN-VPN to the system tray rather than killing the process, keeping your active VPN tunnel protected.
   - To completely exit the client, use the Tray context menu option (`Exit GIN-VPN` / `Выход`).

3. **1080p / High-DPI Optimized Compact Layout:**
   - Window height reduced to 700px, fitting comfortably on 1080p screens (even with 125%/150% Windows display scaling and taskbar visible).
   - Clean, crisp compact Consolas log font.

4. **One-Click Log Copy & Native Ctrl+A Text Selection:**
   - Dedicated `[ 📋 Copy ]` button to instantly copy the entire event log buffer to clipboard.
   - Full keyboard `Ctrl+A` (Select All) support inside the VLESS key input and real-time log box.

5. **Integrated Live Update Checker:**
   - Installed installations feature a `[ 🔄 Check Updates ]` (`[ 🔄 Обновить ]`) button that verifies latest releases against GitHub and offers direct updates.

6. **100% Standalone All-In-One Architecture:**
   - The entire Xray Core engine payload is embedded directly inside `GIN-VPN_v036.exe`.
   - Works immediately out of the box on any fresh machine, completely offline or online, without searching external directories or downloading external binaries.

7. **Smart Geo-Aware Split Routing Matrix (`RU => EU` & `EU => RU`):**
   - **`[ RU => EU ]` (User in Russia connecting to Foreign node):**
     - **Direct ISP Bypass:** Russian domestic services (`.ru`, `.рф`, `.su`, Gosuslugi, Mos.ru, VK, Yandex, Sber, T-Bank, Ozon, Wildberries) bypass the VPN directly, avoiding VPN quota consumption with minimum local latency.
     - **Proxied via VPN:** YouTube, Instagram, Facebook, Twitter/X, Spotify, ChatGPT/OpenAI, Claude/Anthropic, LinkedIn, and global services route seamlessly through the encrypted Reality tunnel.
   - **`[ EU => RU ]` (User in Europe connecting to Russian node):**
     - **Direct ISP Bypass:** European & global services (YouTube, Spotify, Instagram, Netflix, Google, Apple, ChatGPT, local EU banks) run at full Gigabit local ISP speed with zero VPN load.
     - **Proxied via VPN:** Russian-only portals (Gosuslugi, Mos.ru, Kinopoisk, RuTube, Russian banks with geo-fencing, `.ru` sites) route via the Russian VLESS tunnel.

8. **Clean Route Notation (`RU => EU`, `CZ => RU`, `CZ => DE`):**
   - Clean, concise single-token route representation without duplicate country tags.

9. **Large Bold Green Connection Status Header & Dark Green Row Highlight:**
   - When connected, the upper status line dynamically scales to a **2x larger bold font** in **vibrant green**.
   - Active profile is highlighted in the grid with **dark forest green background** (`#1B5E20`) and **bright vivid yellow bold text** (`#FFFF00`).

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
        └───────────────────────────────────────┘
```

---

## 🔒 Triple-Lock & Repository Mirroring
- **GitHub Repository (Windows Scripts):** [Windows_scripts ↗](https://github.com/GinCz/Windows_scripts)
- **GitHub Repository (Public Linux/Windows):** [Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public)
- **Author:** Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz))
