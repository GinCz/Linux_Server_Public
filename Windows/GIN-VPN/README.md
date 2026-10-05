# 🛡️ GIN-VPN by VladiMIR+AI — High-Speed Native Windows Xray Client (v025)

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v025%20(Public%20Release)-green.svg)](https://github.com/GinCz/Windows_scripts)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Engine](https://img.shields.io/badge/Engine-Xray%20Core%20VLESS--Reality%20%2B%20Vision-orange.svg)](https://github.com/GinCz/Windows_scripts)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-VPN** is an ultra-fast, lightweight, standalone native Windows GUI client for **Xray Core (VLESS + Reality + Vision)**. Engineered for high-throughput network tunneling, zero background bloat, volumetric 3D beveled button design, full OLED Dark & Day theme switching, dual-gateway telemetry verification (EU-222 / RU-109), right-click server profile management, and seamless system tray integration.

---

## ⚡ Download & Direct Execution

- **Standalone Native Binary:** [`GIN-VPN_v025.exe`](GIN-VPN_v025.exe) / [`GIN-VPN.exe`](GIN-VPN.exe)
- **Embedded Application Icon:** [`Gin-VPN.ico`](Gin-VPN.ico)
- **Clean Uninstaller:** [`Uninstall.cmd`](Uninstall.cmd) / [`Uninstall.ps1`](Uninstall.ps1)

> **Zero installation required.** Simply launch `GIN-VPN_v025.exe` on any Windows workstation or server (Windows 7 SP1, 8.1, 10, 11, Server 2008–2025).

---

## 🌟 Key Features

1. **Native High-Speed Xray Core Engine:**
   - Standalone native Windows x64 binary without Electron, Chromium, or .NET runtime dependencies.
   - Built-in multi-threaded tunnel supervisor with sub-millisecond route switching.
   - Clean Standby mode on startup (opens in idle state without unwanted automatic connection).

2. **Volumetric 3D Beveled Buttons & Custom Theme Engine:**
   - Rich, physical 3D embossed buttons with top-light highlight reflections, smooth drop bevels, and tactile click states.
   - Seamless **Full OLED Dark Theme** (`🌙 Night`) with deep black/slate cards and zero white edge bleeding.
   - Crisp **Clean Day Theme** (`☀️ Day`) with balanced contrast and vibrant accent controls.

3. **Right-Click Server Profile Context Menu:**
   - ⚡ **Connect:** Instant routing through the selected node.
   - ★ **Set as Default:** Designate primary default server (`★ YES`).
   - ✏️ **Rename Profile:** In-app modal dialog to customize server names.
   - 🗑️ **Delete Profile:** Clean removal with confirmation dialog.
   - 📋 **Copy Key:** Quick export of VLESS Reality URI to clipboard.
   - 🔍 **Verify Route:** Targeted ping and latency test.

4. **Dual IP & Gateway Verification (EU & RU):**
   - **EU Master Gateway (DE-222):** Direct verification against `152.53.182.222:8443` (Portal: `eco-seo.cz/ip`).
   - **RU Fast Gateway (RU-109):** Real-time reachability test against `212.109.223.109:8443` (Portal: `prodvig-saita.ru/ip`).
   - Live telemetry status line: `Protected VPN IP: <IP> (EU/RU) [Dual Verified] | DE: XX ms | RU: YY ms`.

5. **Stabilized System Tray & Taskbar Integration:**
   - High-DPI Golden Shield icon embedded directly into Windows PE resources table (`rsrc_windows_amd64.syso`).
   - Glitch-free background tray supervisor with right-click quick menu and clean window minimize/restore behavior.

---

## 📜 Version History & Changelog

| Version | Release Date | Highlights |
|:---:|:---:|:---|
| **v025** | 2026-10-05 | **Current Public Release:** Added 3D volumetric button styling, fixed Dark Mode card background bleeding, resolved tray icon stability, disabled startup auto-connect, and embedded golden shield PE icon resource. |
| **v024** | 2026-10-05 | Implemented right-click profile context menu and dual EU/RU IP verification engine. |
| **v017** | 2026-10-05 | Multi-server profile table and live diagnostic routing panel. |
| **v012** | 2026-10-04 | Initial standalone native Windows client with custom GDI controls. |

---

## 📄 License

MIT License — 100% Free & Open Source. Created by Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz)) & Anti-Gravity AI.
