# 🌐 GIN NetScan by VladiMIR+AI__v023 — High-Speed Native Windows Network Scanner

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server%202008--2025-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v023%20(Public%20Release)-green.svg)](https://github.com/GinCz/Linux_Server_Public)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Type](https://img.shields.io/badge/Type-Standalone%20Win32%20GUI%20(Zero%20Install)-purple.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Speed](https://img.shields.io/badge/Speed-Hardware%20SendARP%20%7C%201.5s%20Subnet-orange.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-NetScan** is an ultra-fast, lightweight, standalone native Windows GUI application for comprehensive local area network (LAN) discovery, hardware MAC resolution, mDNS Bonjour & NetBIOS identification, latency & line-rate speed estimation, deep port scanning, and automated device classification (including deep Apple iPhone / iPad / Mac model decoding).

Supports all Windows operating systems and architectures (**Windows 7, 8, 8.1, 10, 11** and **Windows Server 2008, 2012, 2016, 2019, 2022, 2025**). Built directly on pure Win32 API without heavy frameworks, runtimes, dependencies, or installers. **100% Free & Open Source for public use.**

---

## ⚡ Quick Download & Run (100% Free)

- **Latest Release (.exe):** [`GIN-NetScan_v023.exe`](https://github.com/GinCz/Linux_Server_Public/raw/main/Windows/Gin-NetScan/GIN-NetScan_v023.exe)
- **Source Code (.go):** [`main.go`](main.go)
- **Application Icon (.ico):** [`Gin-NetScan.ico`](Gin-NetScan.ico)
- **PE Resource Syso (.syso):** [`rsrc_windows_amd64.syso`](rsrc_windows_amd64.syso)

> **No installation required.** Just download `GIN-NetScan_v023.exe` and double-click to run on any Windows PC or Server.  
> *(In accordance with our repository policy, only the latest release binary is kept available for direct download; all previous release notes and technical changelogs are permanently documented below).*

---

## 🌟 Core Features (v023)

- **🛡️ Full-Width Auto-Expanding Dropdown Menus (`CB_SETDROPPEDWIDTH`):**
  All toolbar dropdown selectors (Timeout, Packet payload, Threads concurrency, Subnets) maintain a sleek, space-saving toolbar footprint while dynamically expanding to 195–230 px wide when opened, ensuring all descriptive text is 100% visible with zero label clipping.
- **💾 One-Click Permanent Installer (`Install`):**
  Bright radiant coral-red action button located in the bottom toolbar positioned symmetrically between the status export text and the brand signature. Clicking installs GIN-NetScan permanently to `C:\Program Files\GIN-NetScan` (with elevated UAC or graceful user-profile fallback), generates Desktop and Start Menu shortcuts with the embedded custom icon, and notifies the user before closing the portable launcher.
- **🖥️ Dedicated Multi-Host Port Scanner Window (`🔍 Scan Ports`):**
  Clicking `[🔍 Scan Ports]` opens a dedicated large window auditing all discovered online devices concurrently with separate columns (`№`, `Host Name`, `IP Address`, `MAC Address`, `Open Ports & Detected Services`), live progress tracking, and one-click clipboard report export.
- **⚡ All-in-One Deep Discovery at Primary Scan (`▶ Start Scan`):**
  Full multi-service discovery (mDNS Bonjour, Apple Model ID translation, NetBIOS, SSDP UPnP, and HTTP banners) is executed automatically during the initial scan. 100 parallel workers collect rich metadata instantly with zero UI freezing or hanging.
- **🏷️ Strict 15-Character Hostname Capping & Optimized Column Layout:**
  Strict 15-character limit on the Hostname column across GUI table, context menu copy, and export logs. Auto-fitting applies ~1 mm visual breathing room to all columns while capping Hostname width (95–115 px) so that the **Hardware & Service Fingerprint** column receives maximum horizontal room.
- **🛡️ Zero-Hang Async Architecture & Low Process Priority:**
  All reverse DNS queries and multi-service probes operate under non-blocking goroutines with strict 40ms channel timeouts. Runs with `BELOW_NORMAL_PRIORITY_CLASS` so it never freezes the desktop or exhausts CPU resources even on low-end PCs.
- **🎨 Embedded Multi-Resolution PE Icon:**
  High-resolution Windows icon directly embedded into the executable PE resource section for crisp rendering on Windows Explorer desktop and taskbar.
- **🍎 Deep Apple Device & mDNS / Bonjour Discovery:**
  Translates internal Apple model IDs (e.g. `iPhone14,5` -> `iPhone 13`, `iPhone15,2` -> `iPhone 14 Pro`, `MacBookPro18,1` -> `MacBook Pro 16-inch M1 Pro`) and discovers Bonjour hostnames.
- **💤 Persistent Session History & Gray Offline Nodes:**
  Maintains a session cache of previously discovered hosts. If a device sleeps or disconnects on subsequent scans, it remains in the list rendered in distinct **gray text** with its last-seen timestamp and fingerprint preserved.
- **💡 Rich Hover Tooltips & Dynamic Status Feedback:**
  Interactive balloon tooltips and dynamic status updates with booster tips explaining latency impact and how to discover sleeping IoT/Wi-Fi nodes.
- **📊 Real-Time Bandwidth & Latency Meter:**
  Customizable payload ping (default 1472B MTU packet) to calculate real-time link latency (RTT) and estimated transfer bandwidth (`≥ 1.0 Gbps`, `~850 Mbps`, `~500 Mbps`, `~100 Mbps`).
- **🔀 Smart Multi-Subnet Auto-Detection & No-Adapter Safety:**
  Automatically detects active network adapters and warns if multiple subnets exist. If no network adapter/driver is installed, displays an informative prompt with disabled scanning controls.
- **📋 Right-Click Instant Actions & Multiline Card Copy:**
  Right-click any discovered row to copy structured multiline host cards, individual IP/MAC/Hostname values, or launch instant browser / ping commands or single-device port audits.
- **💾 One-Click Clean UTF-8 Log Export:**
  Click `💾 Save Log` to immediately export a structured, non-delimited UTF-8 BOM report (`Network_Deep_Audit_Report.txt`) to the Desktop and automatically open it.
- **🎮 Retro Demoscene About Box:**
  Click the **`VladiMIR+AI`** brand label in the bottom right corner to open an interactive Winamp-style 3D rotating wireframe cube running at 30 FPS.

---

## 📜 Full Version History & Release Changelog (v001 — v023)

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
| **v018** | 2026-10-04 | All-in-one automatic deep metadata discovery during primary scan (removed Deep Scan button); zero-freeze DNS/mDNS architecture with strict 40ms channel timeouts. |
| **v019** | 2026-10-04 | Enforced strict 15-character limit on Hostname column; auto-fitted all columns with ~1mm breathing room padding; clamped Hostname column width (95–115px) to give maximum space to Hardware & Service Fingerprint; enlarged toolbar label widths (`Timeout:`, `Packet:`, `Threads:`) to eliminate text truncation. |
| **v020** | 2026-10-04 | Dedicated multi-host port scanner window triggered via toolbar `[🔍 Scan Ports]` with live progress, columns for `№`, `Host Name`, `IP Address`, `MAC Address`, and `Open Ports & Detected Services` per device, and one-click clipboard export. |
| **v021** | 2026-10-04 | Added red owner-drawn action button `[💾 Install App]` in the bottom right toolbar (left of author brand signature); installs permanently to `C:\Program Files\GIN-NetScan` with UAC elevation / user-profile fallback. |
| **v022** | 2026-10-04 | Streamlined red Install button text to `Install` with bright radiant candy/coral-red styling; balanced symmetrical spacing between status export text and author brand signature. |
| **v023** | 2026-10-04 | **Current Release:** Implemented full-width auto-expanding dropdown popup lists via `CB_SETDROPPEDWIDTH` (185–230 px) across Timeout, Packet, Threads, and Subnet selectors so all text labels and descriptions are completely visible when opened; window title updated to `GIN NetScan by VladiMIR+AI__v023`. |

---

## 📄 Clean UTF-8 Export Report Preview

```text
=========================================================================================================
                               GIN-NetScan Deep Network Inventory Audit Report                           
Date: 2026-10-04 16:18:00   Total Nodes: 16   Engine & Author: VladiMIR+AI
=========================================================================================================

[1] IP Address:  192.168.33.5  (ONLINE)
    Device Type: 👑 🌐 Gateway / Router
    Host Name:   TP-Link-Archer
    MAC Address: E8:DE:27:FB:8F:32 (TP-Link Technologies)
    Latency RTT: 0 ms   Speed: ≥ 1.0 Gbps
    Fingerprint: TP-Link Technologies (Archer/Router) | Ports: [HTTP:80, SSH:22]
---------------------------------------------------------------------------------------------------------
[2] IP Address:  192.168.33.168  (ONLINE)
    Device Type: 📱 🍎 Apple iPhone
    Host Name:   Alisa-iPhone
    MAC Address: 44:DA:30:C0:68:C3 (Apple, Inc.)
    Latency RTT: 44 ms   Speed: ~20 Mbps
    Fingerprint: Apple, Inc. (iPhone / iOS) | Model: iPhone 13 | Ports: [AirPlay:7000]
---------------------------------------------------------------------------------------------------------
[3] IP Address:  130.61.101.157  (ONLINE)
    Device Type: ☁️ 🐧 Linux Cloud Server
    Host Name:   ORACLE_157
    MAC Address: 00:00:00:00:00:00 (Oracle Cloud Infrastructure)
    Latency RTT: 11 ms   Speed: ~100 Mbps
    Fingerprint: Oracle Linux Server | Ports: [SSH:22, SMB:445, HTTPS:443, RDP:3389, UPnP:5000]
---------------------------------------------------------------------------------------------------------

=========================================================================================================
                  GIN-NetScan by VladiMIR+AI (GinCz)  -  100% Free & Open Source                         
                  GitHub Repository: https://github.com/GinCz/Linux_Server_Public                        
=========================================================================================================
```

---

## 🛠️ Build from Source

Requirements: Go 1.19+ and `rsrc` tool (for Windows PE icon resource embedding).

```bash
# Clone the repository
git clone https://github.com/GinCz/Linux_Server_Public.git
cd Linux_Server_Public/Windows/Gin-NetScan

# Compile resource and build standalone executable
rsrc -ico Gin-NetScan.ico -o rsrc_windows_amd64.syso
GOOS=windows GOARCH=amd64 go build -ldflags="-H windowsgui -s -w" -o GIN-NetScan_v023.exe .
```

---

## 📜 License & Credits

- **Developer:** [Vladimir Bulantsev (GinCz) ↗](https://github.com/GinCz)
- **Engine:** VladiMIR+AI Autonomous Development Suite
- **License:** [MIT License](https://opensource.org/licenses/MIT) — 100% Free for personal, commercial, and enterprise use.
