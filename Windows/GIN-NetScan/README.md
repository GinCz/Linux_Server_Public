# 🌐 GIN NetScan by VladiMIR+AI__v025 — High-Speed Native Windows Network Scanner

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server%202008--2025-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v025%20(Public%20Release)-green.svg)](https://github.com/GinCz/Secret_Privat)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Type](https://img.shields.io/badge/Type-Standalone%20Win32%20GUI%20(Zero%20Install)-purple.svg)](https://github.com/GinCz/Secret_Privat)
[![Speed](https://img.shields.io/badge/Speed-Hardware%20SendARP%20%7C%201.5s%20Subnet-orange.svg)](https://github.com/GinCz/Secret_Privat)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-NetScan** is an ultra-fast, lightweight, standalone native Windows GUI application for comprehensive local area network (LAN) discovery, hardware MAC resolution, mDNS Bonjour & NetBIOS identification, latency & line-rate speed estimation, deep port scanning, and automated device classification (including deep Apple iPhone / iPad / Mac model decoding).

Supports all Windows operating systems and architectures (**Windows 7, 8, 8.1, 10, 11** and **Windows Server 2008, 2012, 2016, 2019, 2022, 2025**). Built directly on pure Win32 API without heavy frameworks, runtimes, dependencies, or installers. **100% Free & Open Source for public use.**

---

## ⚡ Quick Download & Run (100% Free)

- **Latest Release (.exe):** [`GIN-NetScan_v025.exe`](GIN-NetScan_v025.exe)
- **Source Code (.go):** [`main.go`](main.go)
- **Application Icon (.ico):** [`Gin-NetScan.ico`](Gin-NetScan.ico)
- **PE Resource Syso (.syso):** [`rsrc_windows_amd64.syso`](rsrc_windows_amd64.syso)

> **No installation required.** Just download `GIN-NetScan_v025.exe` and double-click to run on any Windows PC or Server.  
> *(In accordance with our repository policy, only the latest release binary is kept available for direct download; all previous release notes and technical changelogs are permanently documented below).*

---

## 🌟 Core Features (v025)

- **🎨 Modern Vibrant Owner-Drawn Toolbar Buttons (`BS_OWNERDRAW`):**
  Full custom GDI rendering for all action buttons with modern, saturated color palettes:
  - **Start Scan (`▶ Start Scan`):** Vibrant Emerald Green (`#28A745`) with white bold text.
  - **Stop Scan (`⏹ Stop`):** Vibrant Crimson Red (`#DC3545`) with white bold text.
  - **Scan Ports (`🔍 Scan Ports`):** Windows Fluent Sapphire Blue (`#0078D4`) with white bold text.
  - **Save Log (`💾 Save Log`):** Vibrant Deep Teal/Cyan (`#17A2B8`) with white bold text.
  - **Install App (`Install`):** Radiant Coral Red (`#FF3B30`) or Emerald Green when installed.
  - **Update (`⚡ New Version`):** Vibrant Amber Gold (`#FF9500`).
  All buttons feature smooth rounded corners (radius 8px), high-contrast white typography, and responsive pressed and disabled states.

- **✨ Clean Single-Icon Design (Zero Double Emojis):**
  Eliminated duplicate monochrome balls/circles from all buttons. Each button features exactly one clean, high-visibility symbol (`▶ Start Scan`, `⏹ Stop`, `🔍 Scan Ports`, `💾 Save Log`, `Install`).

- **🛡️ Embedded PE Icon Resource (`rsrc_windows_amd64.syso`):**
  Crisp multi-resolution Windows PE icon compiled directly into the binary resource table, ensuring proper desktop shortcut, explorer tile, and taskbar icon display across all Windows versions.

- **🛑 Zero Auto-Start on Launch:**
  The scanner starts in an idle, clean "Ready" state without triggering unprompted network ARP/ICMP broadcasts, waiting strictly for explicit user trigger.

- **📦 Official Windows Uninstaller & Programs/Features Integration:**
  Permanent installation registers cleanly in Windows `Apps & Features` / `Add or Remove Programs` (`HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-NetScan`). An interactive/silent `uninstall.bat` script is created inside `C:\Program Files\GIN-NetScan` to cleanly remove shortcuts, registry entries, and program binaries on demand.

- **🛡️ Full-Width Auto-Expanding Dropdown Menus (`CB_SETDROPPEDWIDTH`):**
  All toolbar dropdown selectors (Timeout, Packet payload, Threads concurrency, Subnets) maintain a sleek, space-saving toolbar footprint while dynamically expanding to 185–230 px wide when opened, ensuring all descriptive text is 100% visible.

- **🖥️ Dedicated Multi-Host Port Scanner Window (`🔍 Scan Ports`):**
  Audits 36 common service ports across all discovered online devices concurrently with separate columns (`№`, `Host Name`, `IP Address`, `MAC Address`, `Open Ports & Detected Services`), live progress tracking, and one-click clipboard report export.

- **⚡ All-in-One Deep Discovery at Primary Scan (`▶ Start Scan`):**
  Full multi-service discovery (mDNS Bonjour, Apple Model ID translation, NetBIOS, SSDP UPnP, and HTTP banners) is executed automatically during the initial scan. 100 parallel workers collect rich metadata instantly with zero UI freezing or hanging.

- **🏷️ Strict 15-Character Hostname Capping & Optimized Column Layout:**
  Strict 15-character limit on the Hostname column across GUI table, context menu copy, and export logs. Auto-fitting applies ~1 mm visual breathing room to all columns while capping Hostname width (95–115 px) so that the **Hardware & Service Fingerprint** column receives maximum horizontal room.

- **🛡️ Zero-Hang Async Architecture & Low Process Priority:**
  All reverse DNS queries and multi-service probes operate under non-blocking goroutines with strict 40ms channel timeouts. Runs with `BELOW_NORMAL_PRIORITY_CLASS` so it never freezes the desktop or exhausts CPU resources even on low-end PCs.

- **🍎 Deep Apple Device & mDNS / Bonjour Discovery:**
  Translates internal Apple model IDs (e.g. `iPhone14,5` -> `iPhone 13`, `iPhone15,2` -> `iPhone 14 Pro`, `MacBookPro18,1` -> `MacBook Pro 16-inch M1 Pro`) and discovers Bonjour hostnames.

- **💤 Persistent Session History & Gray Offline Nodes:**
  Maintains a session cache of previously discovered hosts. If a device sleeps or disconnects on subsequent scans, it remains in the list rendered in distinct **gray text** with its last-seen timestamp and fingerprint preserved.

- **💾 One-Click Clean UTF-8 Log Export:**
  Click `💾 Save Log` to immediately export a structured, non-delimited UTF-8 BOM report (`Network_Deep_Audit_Report.txt`) to the Desktop and automatically open it.

- **🎮 Retro Demoscene About Box:**
  Click the **`VladiMIR+AI`** brand label in the bottom right corner to open an interactive Winamp-style 3D rotating wireframe cube running at 30 FPS.

---

## 📜 Full Version History & Release Changelog (v001 — v025)

| Version | Release Date | Summary of Improvements & Architecture Changes |
|:---:|:---:|:---|
| **v001** | 2026-10-04 | Initial prototype: Standalone native Win32 GUI network scanner using `SendARP` and `IcmpSendEcho`. |
| **v002** | 2026-10-04 | Multi-threaded worker pool, progress bar (`msctls_progress32`), and Segoe UI system font integration. |
| **v003** | 2026-10-04 | Integrated built-in OUI database for 300+ hardware MAC vendors (Apple, Intel, TP-Link, Samsung, Xiaomi). |
| **v004** | 2026-10-04 | Multi-adapter & subnet auto-detection with dropdown switcher; dynamic link speed estimation (up to 1.0 Gbps). |
| **v005** | 2026-10-04 | Added full right-click context menu (Copy IP/MAC/Host, Open Web Browser, Continuous Ping in CMD). |
| **v006** | 2026-10-04 | Added retro demoscene About dialog featuring an interactive 3D rotating wireframe cube with double buffering. |
| **v007** | 2026-10-04 | Clean UTF-8 BOM report export to Desktop (`Network_Deep_Audit_Report.txt`) removing disruptive vertical borders. |
| **v008** | 2026-10-04 | Safety logic for systems with no network adapter or uninstalled drivers (informative status and button lockdown). |
| **v009** | 2026-10-04 | Persistent session history cache: keeps track of previous scans, rendering disconnected/sleeping nodes in **gray**. |
| **v010** | 2026-10-04 | Interactive balloon tooltips (`tooltips_class32`) and dynamic booster advice on how to reach sleeping IoT nodes. |
| **v011** | 2026-10-04 | Added dedicated 36-port live security audit dialog with service banner discovery and one-click copy report. |
| **v012** | 2026-10-04 | Context menu enhancement: «Copy All Info» formatted as structured multiline device cards. |
| **v013** | 2026-10-04 | Added mDNS Bonjour & Apple Companion-Link discovery, decoding internal IDs (`iPhone14,5` -> `iPhone 13`). |
| **v014** | 2026-10-04 | Strict classifier hierarchy preventing keyword false-positive overlaps (Smartphones, IoT, Access Points, TVs). |
| **v015** | 2026-10-04 | Added network-wide `[🔍 Scan Ports]` toolbar button; streamlined comboboxes for 1366x768 screens. |
| **v016** | 2026-10-04 | Split scan pipeline experiments; low priority (`BELOW_NORMAL_PRIORITY_CLASS`); embedded Windows PE icon. |
| **v017** | 2026-10-04 | Enforced 23-character maximum length on Hostname column across all views; full changelog table. |
| **v018** | 2026-10-04 | All-in-one automatic deep metadata discovery during primary scan; zero-freeze DNS/mDNS architecture. |
| **v019** | 2026-10-04 | Enforced strict 15-character limit on Hostname column; auto-fitted all columns with ~1mm breathing room padding. |
| **v020** | 2026-10-04 | Dedicated multi-host port scanner window triggered via toolbar `[🔍 Scan Ports]` with live progress tracking. |
| **v021** | 2026-10-04 | Added red owner-drawn action button `[💾 Install App]` in the bottom right toolbar. |
| **v022** | 2026-10-04 | Streamlined red Install button text to `Install` with bright radiant candy/coral-red styling. |
| **v023** | 2026-10-04 | Implemented full-width auto-expanding dropdown popup lists via `CB_SETDROPPEDWIDTH` (185–230 px). |
| **v024** | 2026-10-04 | Official Windows uninstaller registry integration and update engine. |
| **v025** | 2026-10-04 | **Current Release:** Native Win32 Owner-Drawn Toolbar Buttons (`BS_OWNERDRAW`) with vivid saturated color palettes (Emerald Green for `Start Scan`, Crimson Red for `Stop`, Sapphire Blue for `Scan Ports`, Deep Cyan/Teal for `Save Log`, Coral Red for `Install`, Amber Gold for `Update`), clean single icons with zero duplicate monochrome balls, and embedded multi-resolution PE icon resource linked via `rsrc` ensuring crisp Desktop shortcut display. |

---

## 📄 Clean UTF-8 Export Report Preview

```text
=========================================================================================================
                               GIN-NetScan Deep Network Inventory Audit Report                           
Date: 2026-10-04 16:18:00   Total Nodes: 16   Engine & Author: VladiMIR+AI
=========================================================================================================

  №   Status   IP Address        Host Name        MAC Address         Latency      Speed        Device Classification & Fingerprint
---------------------------------------------------------------------------------------------------------
  1   ONLINE   192.168.33.1      router.lan       00:11:32:AA:BB:CC   0.31 ms      ≥ 1.0 Gbps   🌐 Gateway / Router (Synology Inc. | RT2600ac SRM 1.3.1 | HTTP, HTTPS, SSH, DNS)
  2   ONLINE   192.168.33.15     iPhone15-Pro     48:D7:05:11:22:33   1.42 ms      ~850 Mbps    📱 Smartphone (Apple iPhone 15 Pro | iOS 17.5 | mDNS Bonjour, AirPlay)
  3   ONLINE   192.168.33.22     MacBook-M2       F4:D4:88:44:55:66   0.85 ms      ≥ 1.0 Gbps   💻 Computer / Mac (Apple MacBook Air (M2) | macOS Sonoma | SSH, AFP, SMB)
  4   ONLINE   192.168.33.45     LG-webOSTV       00:E0:91:77:88:99   2.10 ms      ~500 Mbps    📺 Smart TV (LG Electronics | webOS TV | DLNA Media Renderer, AirPlay 2)
  5   ONLINE   192.168.33.88     LivingRoom-Cam   18:C0:4F:AA:00:11   3.40 ms      ~100 Mbps    📹 Security Camera (Hangzhou Hikvision | RTSP 554, ONVIF 8000, HTTP)
  6   ONLINE   192.168.33.102    SmartPlug-01     24:62:AB:BB:CC:DD   5.20 ms      ~100 Mbps    💡 Smart Home / IoT (Espressif ESP32 IoT Node | MQTT 1883, HTTP 80)
  7   OFFLINE  192.168.33.120    iPad-Mini        3C:22:FB:EE:FF:00   —            —            [Offline Node] (Apple iPad mini | Disconnected / Sleeping)

=========================================================================================================
```

---

## 📄 License

MIT License — 100% Free & Open Source. Created by Vladimir Bulantsev ([GinCz](https://github.com/GinCz)).
