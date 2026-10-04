# 🛡️ GIN-VPN by VladiMIR+AI — High-Speed Native Windows Xray Client (v013)

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v013%20(Public%20Release)-green.svg)](https://github.com/GinCz/Windows_scripts)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Core](https://img.shields.io/badge/Engine-Xray%20Core%20VLESS--Reality-orange.svg)](https://github.com/GinCz/Windows_scripts)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-VPN** is an ultra-fast, lightweight, standalone native Windows GUI client for **Xray Core (VLESS + Reality + Vision)**. Designed for maximum network performance, zero background bloatware, elegant 3D Glassmorphism UI, real-time diagnostic telemetry, and seamless one-click Windows integration.

---

## ⚡ Quick Download & Deployment

- **Latest Executable (.exe):** [`GIN-VPN_v013.exe`](GIN-VPN_v013.exe)
- **Golden Shield Application Icon (.ico):** [`Gin-VPN.ico`](Gin-VPN.ico)
- **PowerShell GUI Client:** [`GIN-VPN.ps1`](GIN-VPN.ps1)
- **Self-Elevating Launcher:** [`GIN-VPN.bat`](GIN-VPN.bat)
- **Official Uninstaller:** [`Uninstall.cmd`](Uninstall.cmd) / [`Uninstall.ps1`](Uninstall.ps1)

> **No installation required to test.** Run `GIN-VPN_v013.exe` or launch `GIN-VPN.bat` on any Windows machine (Windows 7 SP1, 8.1, 10, 11, Server 2008–2025).

---

## 🌟 Core Features

1. **Native High-Speed Xray Core Engine:**
   - Pure VLESS-Reality & Vision protocol support without bulky frameworks, Electron runtimes, or excessive memory overhead.
   - Built-in multi-threaded tunnel supervisor with sub-millisecond route switching.

2. **3D Glassmorphism & High-DPI UI:**
   - Modern semi-transparent glass aesthetic with deep embossed controls and responsive padding.
   - 100% immune to text truncation across any Windows display scaling (100%, 125%, 150%, 200%).

3. **Golden Shield Brand Icon & Embedded PE Resource:**
   - Authentic high-resolution golden shield icon embedded directly into the PE header table (`rsrc_windows_amd64.syso`), ensuring crisp rendering in the Windows taskbar, system tray, and desktop shortcuts.

4. **Real-Time Live Diagnostics & Telemetry:**
   - **Original ISP IP:** Displays your true upstream ISP IP and country.
   - **Protected VPN IP:** Live validation of your encrypted exit IP.
   - **Real-Time Ping & Latency:** Measures live round-trip time (RTT).
   - **Session Timer:** Uptime tracker for the active tunnel session.

5. **Official Windows Apps & Features Integration:**
   - Clean registration in Windows `Add or Remove Programs` / `Programs & Features` (`HKLM`/`HKCU` `Uninstall`).
   - One-click silent or interactive removal via `Uninstall.cmd` that resets proxy settings, restores system DNS, and wipes binaries cleanly.

---

## 📜 Version History & Changelog

| Version | Release Date | Summary of Changes |
|:---:|:---:|:---|
| **v013** | 2026-10-05 | **Current Release:** Rebuilt with authentic golden shield multi-density icon resource, single latest desktop delivery via MEGA, enhanced DPI scaling, and stabilized live IP detection. |
| **v012** | 2026-10-04 | Added automated background update detector and 3D glassmorphism button states. |
| **v011** | 2026-10-04 | Implemented Windows `Programs & Features` uninstaller registry hooks. |
| **v010** | 2026-10-04 | Multi-server profile switcher and auto-fallback routing. |

---

## 📄 License

MIT License — 100% Free & Open Source. Created by Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz)) & Anti-Gravity AI.
