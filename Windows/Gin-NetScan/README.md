# 🌐 GIN-NetScan — High-Speed Native Windows Network Scanner

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server%202008--2025-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v013%20(Public%20Release)-green.svg)](https://github.com/GinCz/Linux_Server_Public)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Type](https://img.shields.io/badge/Type-Standalone%20Win32%20GUI%20(Zero%20Install)-purple.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Speed](https://img.shields.io/badge/Speed-Hardware%20SendARP%20%7C%202s%20Subnet-orange.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-NetScan** is an ultra-fast, lightweight, standalone native Windows GUI application for comprehensive local area network (LAN) discovery, hardware MAC resolution, NetBIOS computer name identification, latency & line-rate speed estimation, deep port scanning, and device classification.

Supports all Windows operating systems and architectures (**Windows 7, 8, 8.1, 10, 11** and **Windows Server 2008, 2012, 2016, 2019, 2022, 2025**). Built directly on pure Win32 API without heavy frameworks, runtimes, dependencies, or installers. **100% Free & Open Source for public use.**

---

## ⚡ Quick Download & Run (100% Free)

- **Latest Release (.exe):** [`GIN-NetScan_v013.exe`](https://github.com/GinCz/Linux_Server_Public/raw/main/Windows/Gin-NetScan/GIN-NetScan_v013.exe)
- **Source Code (.go):** [`main.go`](main.go)
- **Application Icon (.ico):** [`Gin-NetScan.ico`](Gin-NetScan.ico)

> **No installation required.** Just download `GIN-NetScan_v013.exe` and double-click to run on any Windows PC or Server.

---

## 🌟 Core Features (v013)

- **⚡ Sub-Second Hardware Discovery (`SendARP`):**
  Uses low-level Windows hardware ARP sweeps (`iphlpapi.dll`) with automated wake-up retries to scan an entire `/24` subnet (254 hosts) in under **2–3 seconds**.
- **🔍 Dedicated Deep Port Scanner Dialog:**
  Right-click any host to open a live multi-threaded port audit window testing 34 standard TCP service ports (Web HTTP/HTTPS, SSH, RDP, SMB, RTSP cameras, SQL databases) with service banners and one-click copy report.
- **💤 Persistent Session History & Gray Offline Nodes:**
  Maintains a session cache of previously discovered hosts. If a device sleeps or disconnects on subsequent scans, it remains in the list rendered in distinct **gray text** with its last-seen timestamp and fingerprint preserved.
- **🛡️ Foolproof Dropdown Presets & Parameter Guidance:**
  Pre-configured dropdown menus for Timeout (`1000ms`, `500ms`, `1500ms`, `2500ms`), Packet size (`1472B Max MTU`, `32B`, `64B`, `512B`), and Threads (`100`, `50`, `150`), preventing invalid configurations and providing instant explanations.
- **💡 Rich Hover Tooltips & Dynamic Status Feedback:**
  Interactive balloon tooltips and dynamic status updates with booster tips explaining latency impact and how to discover sleeping IoT/Wi-Fi nodes.
- **🎨 Modern Day Theme (Win32 GUI):**
  Clean, high-contrast white layout designed for Windows with crisp Segoe UI typography.
- **🏷️ Deep Host Name Resolution:**
  Triple-layer identification: NetBIOS Name Service (UDP 137) + Reverse DNS + HTTP Web Title extraction.
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
Date: 2026-10-04 14:35:00   Total Nodes: 16   Engine & Author: VladiMIR+AI
=========================================================================================================

[1] IP Address:  192.168.1.1  (ONLINE)
    Device Type: 👑 🌐 Router (Gateway)
    Host Name:   Keenetic-Ultra
    MAC Address: 50:FF:20:11:22:33 (Keenetic Limited)
    Latency RTT: 0 ms   Speed: ≥ 1.0 Gbps
    Fingerprint: HTTP Web Admin, Open Ports: 80, 443, 53
---------------------------------------------------------------------------------------------------------
[2] IP Address:  192.168.1.100  (ONLINE)
    Device Type: 📱 📶 Smartphone
    Host Name:   iPhone-Vladimir
    MAC Address: 44:DA:30:C0:68:C3 (Apple, Inc.)
    Latency RTT: 2 ms   Speed: ~500 Mbps
    Fingerprint: Apple iOS Device (DHCP Client)
---------------------------------------------------------------------------------------------------------
[3] IP Address:  192.168.1.157  (OFFLINE)
    Device Type: 💤 📴 Disconnected Node
    Host Name:   E14-Workstation
    MAC Address: 00:24:32:18:7E:7D (Dell, Inc.)
    Latency RTT: Offline   Speed: 0 Mbps
    Fingerprint: 💤 [Offline / Last seen 14:15:30] Windows 11 PC (RDP/SMB)
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
GOOS=windows GOARCH=amd64 go build -ldflags="-H windowsgui -s -w" -o GIN-NetScan_v013.exe main.go
```

---

## 📜 License & Credits

- **Developer:** [Vladimir Bulantsev (GinCz) ↗](https://github.com/GinCz)
- **Engine:** VladiMIR+AI Autonomous Development Suite
- **License:** [MIT License](https://opensource.org/licenses/MIT) — 100% Free for personal, commercial, and enterprise use.
