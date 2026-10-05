# 🛡️ GIN-VPN by VladiMIR+AI — High-Speed Native Windows Xray Client (v035)

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v035%20(Standalone%20All--In--One)-green.svg)](https://github.com/GinCz/Windows_scripts)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Engine](https://img.shields.io/badge/Engine-Xray%20Core%20VLESS--Reality%20%2B%20Vision-orange.svg)](https://github.com/GinCz/Windows_scripts)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-VPN** is an ultra-fast, lightweight, 100% standalone all-in-one native Windows GUI client for **Xray Core (VLESS + Reality + Vision)**. Engineered for high-throughput network tunneling, zero background bloat, **Embedded High-Performance Xray Core Engine** (100% self-contained single executable, zero external dependencies or downloads required), **Smart Geo-Aware Split Routing Matrix** (`RU => EU` / `EU => RU`) with zero external dat-file dependencies, interactive hover popup explanations, clean server route switching, bold large green status indicators, solid connected row highlight (Dark Green + Vivid Yellow text), minimalist single-line telemetry diagnostics, instant minimization on connect, dynamic green system tray indicator, real-time Original ISP & VPN Geo-IP (Country/City) tray context display, volumetric 3D beveled button design, full OLED Dark & Day theme switching, multi-language support (English / Russian), persistent profile management (Registry + local JSON store), server numbering grid, dual-gateway telemetry verification (EU-222 / RU-109), right-click server profile CRUD operations, and clean 3D rotating wireframe Easter Egg dialog (`VladiMIR+AI`).

---

## ⚡ Download & Direct Execution

- **Standalone Native Binary:** [`GIN-VPN_v035.exe`](GIN-VPN_v035.exe) / [`GIN-VPN.exe`](GIN-VPN.exe)
- **Multi-Resolution Golden Shield Icon:** [`Gin-VPN.ico`](Gin-VPN.ico)
- **Connected Dynamic Tray Icon:** [`Gin-VPN-green.ico`](Gin-VPN-green.ico)

> **Zero installation or external downloads required.** Simply run `GIN-VPN_v035.exe` on any Windows workstation or server (Windows 7 SP1, 8.1, 10, 11, Server 2008–2025). The complete high-speed Xray Core is embedded directly within the application.

---

## 🌟 Key Features

1. **100% Standalone All-In-One Architecture (v035 New):**
   - The entire Xray Core engine payload is embedded directly inside `GIN-VPN_v035.exe`.
   - Works immediately out of the box on any fresh machine, completely offline or online, without searching external directories or downloading external binaries.

2. **Smart Geo-Aware Split Routing Matrix (`RU => EU` & `EU => RU`):**
   - **`[ RU => EU ]` (User in Russia connecting to Foreign node):**
     - **Direct ISP Bypass:** Russian domestic services (`.ru`, `.рф`, `.su`, Gosuslugi, Mos.ru, VK, Yandex, Sber, T-Bank, Ozon, Wildberries) bypass the VPN directly, avoiding VPN quota consumption with minimum local latency.
     - **Proxied via VPN:** YouTube, Instagram, Facebook, Twitter/X, Spotify, ChatGPT/OpenAI, Claude/Anthropic, LinkedIn, and global services route seamlessly through the encrypted Reality tunnel.
   - **`[ EU => RU ]` (User in Europe connecting to Russian node):**
     - **Direct ISP Bypass:** European & global services (YouTube, Spotify, Instagram, Netflix, Google, Apple, ChatGPT, local EU banks) run at full Gigabit local ISP speed with zero VPN load.
     - **Proxied via VPN:** Russian-only portals (Gosuslugi, Mos.ru, Kinopoisk, RuTube, Russian banks with geo-fencing, `.ru` sites) route via the Russian VLESS tunnel.

3. **Standalone In-Memory Domain Matching (Zero External File Dependencies):**
   - Routing rules use self-contained in-memory domain registries, eliminating runtime crashes related to missing `geosite.dat` / `geoip.dat` binaries in temporary directories.

4. **Interactive Hover Popups & Tooltips:**
   - Hovering over the connected server, status line, or diagnostic badges displays a clear multi-line explanatory tooltip detailing which sites route directly vs via the VPN tunnel.

5. **Clean Route Notation (`RU => EU`, `CZ => RU`, `CZ => DE`):**
   - Clean, concise single-token route representation without duplicate country tags.

6. **Large Bold Green Connection Status Header:**
   - When connected, the upper status line dynamically scales to a **2x larger bold font** in **vibrant green**, clearly displaying active server IP, profile name, and route scheme (`Connected: 152.53.182.222 (DE-222-Master) [CZ => DE]`).

7. **Full Dark Green & Bright Yellow Active Server Row Highlight:**
   - Connected server is prominently highlighted in the profile grid with a rich **dark forest green background** (`#1B5E20`) and **bright vivid yellow bold text** (`#FFFF00`), independent of mouse selection state or focus.

8. **Minimalist Diagnostics Panel (No Text Clipping / Wrapping):**
   - Clean, compact single-line metrics with zero clutter:
     - `ISP IP: <Original IP>` | `VPN IP: <Protected IP>`
     - `Ping: <RTT>ms (EU: <DE>ms | RU: <RU>ms)` | `Uptime: HH:MM:SS`

9. **Clean Route Switching (Disconnect Before Reconnect):**
   - Switching profiles cleanly halts previous tunnel instances, resets system proxy, and starts the new route without stale socket collision.

10. **Double-Click Quick Connect with Instant Tray Minimization & Green Icon:**
    - Double-clicking any server connects instantly and minimizes the window into the tray with solid green indicator (`Gin-VPN-green.ico`).

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
