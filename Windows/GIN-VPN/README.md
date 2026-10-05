# 🛡️ GIN-VPN by VladiMIR+AI — High-Speed Native Windows Xray Client (v030)

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v030%20(Public%20Release)-green.svg)](https://github.com/GinCz/Windows_scripts)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Engine](https://img.shields.io/badge/Engine-Xray%20Core%20VLESS--Reality%20%2B%20Vision-orange.svg)](https://github.com/GinCz/Windows_scripts)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-VPN** is an ultra-fast, lightweight, standalone native Windows GUI client for **Xray Core (VLESS + Reality + Vision)**. Engineered for high-throughput network tunneling, zero background bloat, clean server route switching, instant minimization on connect, dynamic green system tray indicator, real-time Original ISP & VPN Geo-IP (Country/City) tray context display, volumetric 3D beveled button design, full OLED Dark & Day theme switching, multi-language support (English / Russian), persistent profile management (Registry + local JSON store), active server connected highlighting, server numbering grid, dual-gateway telemetry verification (EU-222 / RU-109), right-click server profile CRUD operations, 3D rotating wireframe Easter Egg dialog, clean Windows Explorer icon integration, and dynamic green system tray supervisor.

---

## ⚡ Download & Direct Execution

- **Standalone Native Binary:** [`GIN-VPN_v030.exe`](GIN-VPN_v030.exe) / [`GIN-VPN.exe`](GIN-VPN.exe)
- **Multi-Resolution Golden Shield Icon:** [`Gin-VPN.ico`](Gin-VPN.ico)
- **Connected Dynamic Tray Icon:** [`Gin-VPN-green.ico`](Gin-VPN-green.ico)

> **Zero installation required.** Simply launch `GIN-VPN_v030.exe` on any Windows workstation or server (Windows 7 SP1, 8.1, 10, 11, Server 2008–2025).

---

## 🌟 Key Features

1. **Clean Route Switching (Disconnect Before Reconnect):**
   - Seamlessly transitions when switching between servers: cleanly stops previous tunnel instances, releases local proxy ports, and establishes the new route from scratch without collisions.

2. **Double-Click Quick Connect with Instant Tray Minimization & Green Icon:**
   - Double-clicking any server profile in the list connects instantly and smoothly minimizes the application into the system tray.
   - The tray notification icon immediately turns vibrant green (`Gin-VPN-green.ico`) confirming active tunnel protection.

3. **Full Geo-IP & ISP Address Display in Tray Context Menu:**
   - Right-clicking the tray icon reveals:
     - **VPN Exit IP & Location:** `🔒 VPN IP: 130.61.101.157 (Germany, Frankfurt)`
     - **Original ISP IP & Location:** `🌐 Original ISP IP: 217.118.x.x (Russia, Moscow)`
   - Live tooltip (`SzTip`) updates with active node and location telemetry.

4. **Multi-Language Switcher (EN & RU) & Clear Spacing:**
   - Header switcher with instant language toggle (`EN` and `RU`) separated with distinct spacing from theme buttons.
   - Default language is English (`EN`).
   - Translates all controls, status lines, diagnostics, tooltips, dialogs, and right-click context menus.
   - Compact and clean label header: `"Double-Click: Connect | Right-Click: Options"` / `"Двойной клик — Пуск | Правый клик — Функции"`.

5. **Persistent Profile Management (Registry + JSON):**
   - Profile changes (Add, Rename, Set Default, and Delete) are immediately synced to Windows Registry (`HKCU\Software\VladiMIR\GIN-VPN`) and `%LOCALAPPDATA%\GIN-VPN\profiles.json`.
   - Deleted profiles remain permanently deleted across application restarts.

6. **3D Interactive Easter Egg Graphics Dialog:**
   - Clickable brand signature at the bottom (`VladiMIR+AI`) launches an interactive 3D modal window.
   - Features real-time 3D rotating wireframe geometry with glowing vertices, author credentials, and direct repository links.

7. **Active Server Connected Highlighting & Gridlines:**
   - Saved profiles displayed in a clean structured table grid with vertical and horizontal cell borders.
   - Dedicated index numbering column (`№`): 1, 2, 3, 4, 5, 6, 7...
   - The currently connected server is highlighted with a **dark green row background** (`#1B5E20`) and **bold bright yellow text** (`#00FFFF`).

8. **Volumetric 3D Beveled Buttons & Custom Theme Engine:**
   - Rich, physical 3D embossed buttons with top-light highlight reflections, smooth drop bevels, and tactile click states.
   - Seamless **Full OLED Dark Theme** (`🌙 Night`) with deep black/slate cards and zero white edge bleeding.
   - Crisp **Clean Day Theme** (`☀️ Day`) with balanced contrast and vibrant accent controls.

9. **Right-Click Server Profile Context Menu:**
   - ⚡ **Connect:** Instant routing through the selected node.
   - ★ **Set as Default:** Designate primary default server (`★ YES`).
   - ✏️ **Rename Profile:** In-app modal dialog to customize server names.
   - 🗑️ **Delete Profile:** Permanent removal with confirmation dialog and instant registry sync.
   - 📋 **Copy Key:** Quick export of VLESS Reality URI to clipboard.
   - 🔍 **Verify Route:** Targeted ping and latency test.

---

## 📜 Version History & Changelog

| Version | Release Date | Highlights |
|:---:|:---:|:---|
| **v030** | 2026-10-05 | **Current Public Release:** Added clear visual spacing between Day/Night and EN/RU header controls; fixed button label text rendering for clean `EN` and `RU`; implemented clean route switching with automated prior tunnel teardown before switching servers; optimized Russian profile list header text to prevent UI clipping. |
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
