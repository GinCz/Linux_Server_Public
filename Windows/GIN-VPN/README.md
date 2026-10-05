# 🛡️ GIN-VPN by VladiMIR+AI — High-Speed Native Windows Xray Client (v028)

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v028%20(Public%20Release)-green.svg)](https://github.com/GinCz/Windows_scripts)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Engine](https://img.shields.io/badge/Engine-Xray%20Core%20VLESS--Reality%20%2B%20Vision-orange.svg)](https://github.com/GinCz/Windows_scripts)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-VPN** is an ultra-fast, lightweight, standalone native Windows GUI client for **Xray Core (VLESS + Reality + Vision)**. Engineered for high-throughput network tunneling, zero background bloat, volumetric 3D beveled button design, full OLED Dark & Day theme switching, multi-language support (English / Russian), persistent profile management (Registry + local JSON store), active server connected highlighting, server numbering grid, dual-gateway telemetry verification (EU-222 / RU-109), right-click server profile CRUD operations, 3D rotating wireframe Easter Egg dialog, clean Windows Explorer icon integration, and dynamic green system tray supervisor.

---

## ⚡ Download & Direct Execution

- **Standalone Native Binary:** [`GIN-VPN_v028.exe`](GIN-VPN_v028.exe) / [`GIN-VPN.exe`](GIN-VPN.exe)
- **Multi-Resolution Golden Shield Icon:** [`Gin-VPN.ico`](Gin-VPN.ico)
- **Connected Dynamic Tray Icon:** [`Gin-VPN-green.ico`](Gin-VPN-green.ico)
- **Clean Uninstaller:** [`Uninstall.cmd`](Uninstall.cmd) / [`Uninstall.ps1`](Uninstall.ps1)

> **Zero installation required.** Simply launch `GIN-VPN_v028.exe` on any Windows workstation or server (Windows 7 SP1, 8.1, 10, 11, Server 2008–2025).

---

## 🌟 Key Features

1. **Persistent Profile Management (Registry + JSON):**
   - Profile changes (Add, Rename, Set Default, and Delete) are immediately synced to Windows Registry (`HKCU\Software\VladiMIR\GIN-VPN`) and `%LOCALAPPDATA%\GIN-VPN\profiles.json`.
   - Deleted profiles remain permanently deleted across application restarts.

2. **3D Interactive Easter Egg Graphics Dialog:**
   - Clickable brand signature at the bottom (`VladiMIR+AI`) launches an interactive 3D modal window.
   - Features real-time 3D rotating wireframe geometry with glowing vertices, author credentials, and direct repository links.

3. **Multi-Language Switcher (EN & RU):**
   - Header switcher with instant language toggle (`🇬🇧 EN` and `🇷🇺 RU`).
   - Default language is English (`EN`).
   - Translates all controls, status lines, diagnostics, tooltips, dialogs, and right-click context menus.

4. **Active Server Connected Highlighting & Gridlines:**
   - Saved profiles displayed in a clean structured table grid with vertical and horizontal cell borders.
   - Dedicated index numbering column (`№`): 1, 2, 3, 4, 5, 6, 7...
   - The currently connected server is highlighted with a **dark green row background** (`#1B5E20`) and **bold bright yellow text** (`#00FFFF`).

5. **Dynamic Green System Tray Icon:**
   - Dedicated connected PE resource (`Gin-VPN-green.ico`) with glowing green badge indicator.
   - When connected, system tray icon turns solid green; when disconnected, restores golden shield.

6. **Native High-Speed Xray Core Engine:**
   - Standalone native Windows x64 binary without Electron, Chromium, or .NET runtime dependencies.
   - Built-in multi-threaded tunnel supervisor with sub-millisecond route switching.
   - Standby mode on startup (opens in idle state without unwanted automatic connection).

7. **Volumetric 3D Beveled Buttons & Custom Theme Engine:**
   - Rich, physical 3D embossed buttons with top-light highlight reflections, smooth drop bevels, and tactile click states.
   - Seamless **Full OLED Dark Theme** (`🌙 Night`) with deep black/slate cards and zero white edge bleeding.
   - Crisp **Clean Day Theme** (`☀️ Day`) with balanced contrast and vibrant accent controls.

8. **Right-Click Server Profile Context Menu:**
   - ⚡ **Connect:** Instant routing through the selected node.
   - ★ **Set as Default:** Designate primary default server (`★ YES`).
   - ✏️ **Rename Profile:** In-app modal dialog to customize server names.
   - 🗑️ **Delete Profile:** Permanent removal with confirmation dialog and instant registry sync.
   - 📋 **Copy Key:** Quick export of VLESS Reality URI to clipboard.
   - 🔍 **Verify Route:** Targeted ping and latency test.

9. **Dual IP & Gateway Verification (EU & RU):**
   - **EU Master Gateway (DE-222):** Direct verification against `152.53.182.222:8443` (Portal: `eco-seo.cz/ip`).
   - **RU Fast Gateway (RU-109):** Real-time reachability test against `212.109.223.109:8443` (Portal: `prodvig-saita.ru/ip`).

---

## 📜 Version History & Changelog

| Version | Release Date | Highlights |
|:---:|:---:|:---|
| **v028** | 2026-10-05 | **Current Public Release:** Added persistent profile storage (Windows Registry `HKCU\Software\VladiMIR\GIN-VPN` + Local JSON storage) so deleted/renamed profiles remain persistent across restarts; implemented clickable bottom brand signature `VladiMIR+AI` launching 3D rotating wireframe Easter Egg animation dialog. |
| **v027** | 2026-10-05 | Added EN/RU language switcher, restored table gridlines, added server numbering column (`№`), implemented active connected server highlighting (dark green row + bright yellow bold text), and integrated dynamic green tray icon PE resource. |
| **v026** | 2026-10-05 | Fixed PE ICO multi-resolution headers (resolving Desktop/Explorer icon display). |
| **v025** | 2026-10-05 | Added 3D volumetric button styling, fixed Dark Mode card background bleeding, and disabled startup auto-connect. |
| **v024** | 2026-10-05 | Implemented right-click profile context menu and dual EU/RU IP verification engine. |
| **v017** | 2026-10-05 | Multi-server profile table and live diagnostic routing panel. |
| **v012** | 2026-10-04 | Initial standalone native Windows client with custom GDI controls. |

---

## 📄 License

MIT License — 100% Free & Open Source. Created by Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz)) & Anti-Gravity AI.
