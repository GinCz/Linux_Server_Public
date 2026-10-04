# 🌐 GIN-NetScan — High-Speed Native Windows Network Scanner

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server%202008--2025-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v015%20(Public%20Release)-green.svg)](https://github.com/GinCz/Linux_Server_Public)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Type](https://img.shields.io/badge/Type-Standalone%20Win32%20GUI%20(Zero%20Install)-purple.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Speed](https://img.shields.io/badge/Speed-Hardware%20SendARP%20%7C%202s%20Subnet-orange.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-NetScan** is an ultra-fast, lightweight, standalone native Windows GUI application for comprehensive local area network (LAN) discovery, hardware MAC resolution, mDNS Bonjour & NetBIOS identification, latency & line-rate speed estimation, deep port scanning, and automated device classification (including deep Apple iPhone / iPad / Mac model decoding).

Supports all Windows operating systems and architectures (**Windows 7, 8, 8.1, 10, 11** and **Windows Server 2008, 2012, 2016, 2019, 2022, 2025**). Built directly on pure Win32 API without heavy frameworks, runtimes, dependencies, or installers. **100% Free & Open Source for public use.**

---

## ⚡ Quick Download & Run (100% Free)

- **Latest Release (.exe):** [`GIN-NetScan_v015.exe`](https://github.com/GinCz/Linux_Server_Public/raw/main/Windows/Gin-NetScan/GIN-NetScan_v015.exe)
- **Source Code (.go):** [`main.go`](main.go)
- **Application Icon (.ico):** [`Gin-NetScan.ico`](Gin-NetScan.ico)

> **No installation required.** Just download `GIN-NetScan_v015.exe` and double-click to run on any Windows PC or Server.

---

## 🌟 Core Features (v015)

- **🔍 One-Click Network-Wide Port Audit (`Scan Ports`):**
  Dedicated toolbar button to perform a non-blocking 36-port service sweep across all discovered online devices concurrently, updating the grid in real-time.
- **🍎 Deep Apple Device & mDNS / Bonjour Discovery:**
  Integrated Multicast DNS (UDP 5353) and Apple Bonjour service discovery (`_companion-link`, `_airplay`, `_apple-mobdev2`, `_googlecast`). Automatically resolves friendly names (e.g. `Alisa-iPhone`, `Nikol-PC`) and translates internal Apple model IDs (e.g. `iPhone14,5` -> `iPhone 13`, `iPhone15,2` -> `iPhone 14 Pro`, `MacBookPro18,1` -> `MacBook Pro 16-inch M1 Pro`).
- **⚡ Sub-Second Hardware Discovery (`SendARP`):**
  Uses low-level Windows hardware ARP sweeps (`iphlpapi.dll`) with multi-threaded concurrent probe stages to scan an entire `/24` subnet (254 hosts) in under **2 seconds**.
- **🔍 Dedicated Deep Port Scanner Dialog:**
  Right-click any host to open a live multi-threaded port audit window testing 36 standard TCP service ports (Web HTTP/HTTPS, SSH, RDP, SMB, RTSP cameras, Apple Mobile Device Sync `62078`, AirPlay `7000`, SQL databases) with service banners and one-click copy report.
- **🏷️ Strict Classification Hierarchy (Zero Substring Collisions):**
  Intelligent multi-tier classifier with priority sorting distinguishing Apple iPhones, iPads, Macs, Android Smartphones, IP Cameras, Smart TVs, IoT nodes, and Access Points without false-positive keyword overlaps.
- **💤 Persistent Session History & Gray Offline Nodes:**
  Maintains a session cache of previously discovered hosts. If a device sleeps or disconnects on subsequent scans, it remains in the list rendered in distinct **gray text** with its last-seen timestamp and fingerprint preserved.
- **🛡️ Compact Dropdown Presets (1366x768 Optimized):**
  Streamlined dropdown menus for Timeout (`1000ms`, `500ms`, `1500ms`, `2500ms`), Packet size (`1472B MTU`, `32B`, `64B`, `512B`), and Threads (`100`, `50`, `150`), perfectly fitting laptop screens and low-resolution monitors.
- **💡 Rich Hover Tooltips & Dynamic Status Feedback:**
  Interactive balloon tooltips and dynamic status updates with booster tips explaining latency impact and how to discover sleeping IoT/Wi-Fi nodes.
- **🎨 Modern Day Theme (Win32 GUI):**
  Clean, high-contrast white layout designed for Windows with crisp Segoe UI typography.
- **📊 Real-Time Bandwidth & Latency Meter:**
  Customizable payload ping (default 1472B MTU packet) to calculate real-time link latency (RTT) and estimated transfer bandwidth (`≥ 1.0 Gbps`, `~850 Mbps`, `~500 Mbps`, `~100 Mbps`).
- **🔀 Smart Multi-Subnet Auto-Detection & No-Adapter Safety:**
  Automatically detects active network adapters and warns if multiple subnets exist. If no network adapter/driver is installed, displays an informative prompt with disabled scanning controls.
- **📋 Right-Click Instant Actions & Multiline Card Copy:**
  Right-click any discovered row to copy structured multiline host cards, individual IP/MAC/Hostname values, or launch instant browser / ping commands.
- **💾 One-Click Clean UTF-8 Log Export:**
  Click `💾 Save Log` to immediately export a structured, non-delimited UTF-8 BOM report (`Network_Deep_Audit_Report.txt`) to the Desktop and automatically open it.
- **🎮 Retro Demoscene About Box:**
  Click the **`VladiMIR+AI`** brand label in the bottom right corner to open an interactive Winamp-style 3D rotating wireframe cube running at 30 FPS.

---

## 📄 Clean UTF-8 Export Report Preview

```text
=========================================================================================================
                               GIN-NetScan Deep Network Inventory Audit Report                           
Date: 2026-10-04 14:55:00   Total Nodes: 16   Engine & Author: VladiMIR+AI
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
[3] IP Address:  192.168.33.157  (ONLINE)
    Device Type: 💻 🖥️ PC / Workstation
    Host Name:   E14--Home
    MAC Address: 00:24:32:18:7E:7D (Intel Corporation)
    Latency RTT: 0 ms   Speed: ≥ 1.0 Gbps
    Fingerprint: Intel Corporation (PC / Workstation)
---------------------------------------------------------------------------------------------------------

=========================================================================================================
                  GIN-NetScan by VladiMIR+AI (GinCz)  -  100% Free & Open Source                         
                  GitHub Repository: https://github.com/GinCz/Linux_Server_Public                        
=========================================================================================================
```

---

## 🛠️ Build from Source

Requirements: Go 1.19+ and MinGW-w64 (optional, for icon resource embedding).

```bash
# Clone the repository
git clone https://github.com/GinCz/Linux_Server_Public.git
cd Linux_Server_Public/Windows/Gin-NetScan

# Cross-compile for Windows x86_64
GOOS=windows GOARCH=amd64 go build -ldflags="-H windowsgui -s -w" -o GIN-NetScan_v014.exe main.go
```

---

## 📜 License & Credits

- **Developer:** [Vladimir Bulantsev (GinCz) ↗](https://github.com/GinCz)
- **Engine:** VladiMIR+AI Autonomous Development Suite
- **License:** [MIT License](https://opensource.org/licenses/MIT) — 100% Free for personal, commercial, and enterprise use.
