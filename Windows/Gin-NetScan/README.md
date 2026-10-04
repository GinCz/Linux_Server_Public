# 🌐 GIN NetScan by VladiMIR+AI__v024 — High-Speed Native Windows Network Scanner

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server%202008--2025-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v024%20(Public%20Release)-green.svg)](https://github.com/GinCz/Linux_Server_Public)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Type](https://img.shields.io/badge/Type-Standalone%20Win32%20GUI%20(Zero%20Install)-purple.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Speed](https://img.shields.io/badge/Speed-Hardware%20SendARP%20%7C%201.5s%20Subnet-orange.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-NetScan** is an ultra-fast, lightweight, standalone native Windows GUI application for comprehensive local area network (LAN) discovery, hardware MAC resolution, mDNS Bonjour & NetBIOS identification, latency & line-rate speed estimation, deep port scanning, and automated device classification (including deep Apple iPhone / iPad / Mac model decoding).

Supports all Windows operating systems and architectures (**Windows 7, 8, 8.1, 10, 11** and **Windows Server 2008, 2012, 2016, 2019, 2022, 2025**). Built directly on pure Win32 API without heavy frameworks, runtimes, dependencies, or installers. **100% Free & Open Source for public use.**

---

## ⚡ Quick Download & Run (100% Free)

- **Latest Release (.exe):** [`GIN-NetScan_v024.exe`](https://github.com/GinCz/Linux_Server_Public/raw/main/Windows/Gin-NetScan/GIN-NetScan_v024.exe)
- **Source Code (.go):** [`main.go`](main.go)
- **Application Icon (.ico):** [`Gin-NetScan.ico`](Gin-NetScan.ico)
- **PE Resource Syso (.syso):** [`rsrc_windows_amd64.syso`](rsrc_windows_amd64.syso)
- **Version Manifest (.json):** [`version.json`](version.json)

> **No installation required.** Just download `GIN-NetScan_v024.exe` and double-click to run on any Windows PC or Server.  
> *(In accordance with our repository policy, only the latest release binary is kept available for direct download; all previous release notes and technical changelogs are permanently documented below).*

---

## 🌟 Core Features (v024)

- **🎨 Multi-Color Action Buttons & Vibrant UI Palette:**
  - **Start Scan (▶):** Vibrant Apple / Emerald Green (`#28CD41`) with interactive press and disabled styling.
  - **Stop Scan (⏹):** Radiant Candy Coral Red (`#FF3B30`).
  - **Scan Ports (🔍):** Royal Indigo / Violet (`#5856D6`).
  - **Save Log (💾):** Vibrant Azure / Sapphire Blue (`#007AFF`).
  - **Data Grid Subitem Coloring:** Device Type, IP, Latency RTT, and Link Speed are rendered with custom Win32 subitem color hierarchies for maximum visual clarity and instant node recognition.
- **🛑 Zero Auto-Start on Launch:**
  The scanner starts in an idle, clean "Ready" state without triggering unprompted network ARP/ICMP broadcasts, ensuring total control over scan execution.
- **📦 Official Windows Uninstaller & Programs/Features Integration:**
  Permanent installation registers cleanly in Windows `Apps & Features` / `Add or Remove Programs` (`HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-NetScan`). An interactive/silent `uninstall.bat` script is created inside `C:\Program Files\GIN-NetScan` to cleanly remove shortcuts, registry entries, and program binaries on demand.
- **⚡ Dynamic Background Update Engine:**
  In installed mode, a permanent green `[ Installed ]` badge is shown alongside a dynamic `[ ⚡ New version v... ]` button that appears seamlessly whenever a newer release is published on GitHub.
- **🛡️ Full-Width Auto-Expanding Dropdown Menus (`CB_SETDROPPEDWIDTH`):**
  All toolbar dropdown selectors maintain a compact footprint while dynamically expanding to 195–230 px wide when opened for 100% visible text.
- **🖥️ Dedicated Multi-Host Port Scanner Window (`🔍 Scan Ports`):**
  Audits 36 common service ports across all discovered online devices concurrently with live progress tracking and one-click clipboard report export.
- **⚡ All-in-One Deep Discovery at Primary Scan (`▶ Start Scan`):**
  Full multi-service discovery (mDNS Bonjour, Apple Model ID translation, NetBIOS, SSDP UPnP, and HTTP banners) is executed automatically during the initial scan.

---

## 📋 Full Release History & Changelog

### **v024 (2026-10-04)**
- **UI & Theme:** Replaced monochrome UI with vibrant multi-colored action buttons (Start = Green, Stop = Red, Scan Ports = Violet, Save Log = Blue).
- **Grid CustomDraw:** Added Win32 `NMLVCUSTOMDRAW` subitem colorization for Device Types, IP, Ping, and Link Speed columns.
- **Safety:** Disabled auto-scan on startup to prevent accidental scans.
- **Installer & Uninstaller:** Added official Windows Uninstaller registration in Windows Registry (`Uninstall\GIN-NetScan`) and generated `uninstall.bat`.
- **Update Engine:** Added background update checker with dynamic `[ ⚡ New version v... ]` toolbar action button.

### **v023 (2026-10-04)**
- **Dropdown Fix:** Added `CB_SETDROPPEDWIDTH` (185–230 px) to all ComboBoxes for zero text clipping.

### **v022 (2026-10-04)**
- **Layout:** Streamlined Install button text, vibrant candy red styling, balanced symmetrical layout.

### **v021 (2026-10-04)**
- **Installer Engine:** Added red permanent installer button (Install App) matching GIN-VPN installation engine.

---

## 📄 License

MIT License — 100% Free & Open Source. Created by Vladimir Bulantsev ([GinCz](https://github.com/GinCz)).
