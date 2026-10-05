# 🛡️ GIN-VPN by VladiMIR+AI — High-Speed Native Windows Xray Client (v031)

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v031%20(Public%20Release)-green.svg)](https://github.com/GinCz/Windows_scripts)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Engine](https://img.shields.io/badge/Engine-Xray%20Core%20VLESS--Reality%20%2B%20Vision-orange.svg)](https://github.com/GinCz/Windows_scripts)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-VPN** is an ultra-fast, lightweight, standalone native Windows GUI client for **Xray Core (VLESS + Reality + Vision)**. Engineered for high-throughput network tunneling, zero background bloat, clean server route switching, bold large green status indicators, solid connected row highlight (Dark Green + Vivid Yellow text), minimalist single-line telemetry diagnostics, instant minimization on connect, dynamic green system tray indicator, real-time Original ISP & VPN Geo-IP (Country/City) tray context display, volumetric 3D beveled button design, full OLED Dark & Day theme switching, multi-language support (English / Russian), persistent profile management (Registry + local JSON store), server numbering grid, dual-gateway telemetry verification (EU-222 / RU-109), right-click server profile CRUD operations, and clean 3D rotating wireframe Easter Egg dialog (`VladiMIR+AI`).

---

## ⚡ Download & Direct Execution

- **Standalone Native Binary:** [`GIN-VPN_v031.exe`](GIN-VPN_v031.exe) / [`GIN-VPN.exe`](GIN-VPN.exe)
- **Multi-Resolution Golden Shield Icon:** [`Gin-VPN.ico`](Gin-VPN.ico)
- **Connected Dynamic Tray Icon:** [`Gin-VPN-green.ico`](Gin-VPN-green.ico)

> **Zero installation required.** Simply launch `GIN-VPN_v031.exe` on any Windows workstation or server (Windows 7 SP1, 8.1, 10, 11, Server 2008–2025).

---

## 🌟 Key Features

1. **Large Bold Green Connection Status Header:**
   - When connected, the upper status line dynamically scales to a **2x larger bold font** in **vibrant green**, clearly displaying active server IP and profile name (`Connected: 152.53.182.222 (DE-222-Master)`).

2. **Full Dark Green & Bright Yellow Active Server Row Highlight:**
   - Connected server is prominently highlighted in the profile grid with a rich **dark forest green background** (`#1B5E20`) and **bright vivid yellow bold text** (`#FFFF00`), independent of mouse selection state or focus.

3. **Minimalist Diagnostics Panel (No Text Clipping / Wrapping):**
   - Clean, compact single-line metrics with zero clutter:
     - `ISP IP: <Original IP>` | `VPN IP: <Protected IP>`
     - `Ping: <RTT>ms (EU: <DE>ms | RU: <RU>ms)` | `Uptime: HH:MM:SS`

4. **Clean Route Switching (Disconnect Before Reconnect):**
   - Switching profiles cleanly halts previous tunnel instances, resets system proxy, and starts the new route without stale socket collision.

5. **Double-Click Quick Connect with Instant Tray Minimization & Green Icon:**
   - Double-clicking any server connects instantly and minimizes the window into the tray with solid green indicator (`Gin-VPN-green.ico`).

6. **Full Geo-IP & ISP Address Display in Tray Context Menu:**
   - Right-click tray menu displays Original ISP IP (RU) and VPN Protected IP with Country and City details.

7. **Multi-Language Switcher (EN & RU) & Spaced Layout:**
   - Instant language toggle with clean `EN` and `RU` labels and distinct button group spacing.

8. **Minimalist Centered Brand Signature (`VladiMIR+AI`):**
   - Interactive bottom brand label launching the real-time 3D wireframe Easter Egg modal.

---

## 📜 Version History & Changelog

| Version | Release Date | Highlights |
|:---:|:---:|:---|
| **v031** | 2026-10-05 | **Current Public Release:** Implemented 2x larger bold green connection status header; added full dark green background + bright yellow text highlighting for the connected server in the list view; streamlined diagnostics panel to clean minimalist single-line metrics without text clipping; simplified bottom brand signature to pure `VladiMIR+AI`. |
| **v030** | 2026-10-05 | Added clear visual spacing between Day/Night and EN/RU header controls; fixed button label text rendering for clean `EN` and `RU`; implemented clean route switching with automated prior tunnel teardown before switching servers; optimized Russian profile list header text to prevent UI clipping. |
| **v029** | 2026-10-05 | Implemented instant minimization to system tray on double-click connection with solid green tray icon switch; added dual IP telemetry to right-click tray context menu displaying original ISP IP (RU) and connected VPN IP with Country and City location details; added dynamic Geo-IP background resolver. |
| **v028** | 2026-10-05 | Added persistent profile storage (Windows Registry + Local JSON storage); implemented bottom brand signature launching 3D rotating wireframe Easter Egg animation dialog. |
| **v027** | 2026-10-05 | Added EN/RU language switcher, restored table gridlines, added server numbering column (`№`), implemented active connected server highlighting, and integrated dynamic green tray icon PE resource. |
| **v026** | 2026-10-05 | Fixed PE ICO multi-resolution headers (resolving Desktop/Explorer icon display). |
| **v025** | 2026-10-05 | Added 3D volumetric button styling and fixed Dark Mode card background bleeding. |
| **v024** | 2026-10-05 | Implemented right-click profile context menu and dual EU/RU IP verification engine. |
| **v017** | 2026-10-05 | Multi-server profile table and live diagnostic routing panel. |
| **v012** | 2026-10-04 | Initial standalone native Windows client with custom GDI controls. |

---

## 📄 License

MIT License — 100% Free & Open Source. Created by Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz)) & Anti-Gravity AI.
