# 🌐 Gin-NetScan — High-Speed Native Windows Network Scanner

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20%7C%20Server-blue.svg)](https://microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Type](https://img.shields.io/badge/Type-Standalone%20Win32%20GUI%20(Zero%20Install)-purple.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Speed](https://img.shields.io/badge/Speed-Hardware%20SendARP%20%7C%202s%20Subnet-orange.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**Gin-NetScan** is an ultra-fast, lightweight, standalone native Windows GUI application for comprehensive local area network (LAN) discovery, hardware MAC resolution, NetBIOS computer name identification, latency & line-rate speed estimation, and device classification.

Built directly on pure Win32 API without heavy frameworks, dependencies, or installers. **100% Free & Open Source for public use.**

---

## ⚡ Quick Download & Run (100% Free)

- **Direct Download (.exe):** [`Gin-NetScan.exe`](https://github.com/GinCz/Linux_Server_Public/raw/main/Windows/Gin-NetScan/Gin-NetScan.exe)
- **Source Code (.go):** [`main.go`](main.go)
- **Application Icon (.ico):** [`Gin-NetScan.ico`](Gin-NetScan.ico)

> **No installation required.** Just download `Gin-NetScan.exe` and double-click to run.

---

## 🌟 Core Features

- **⚡ Sub-Second Hardware Discovery (`SendARP`):**
  Uses low-level Windows hardware ARP sweeps (`iphlpapi.dll`) to scan an entire `/24` subnet (254 hosts) in under **2–3 seconds**.
- **🎨 Modern Day Theme (Win32 GUI):**
  Clean, high-contrast white layout designed for Windows 10 and Windows 11 with crisp Segoe UI typography.
- **🏷️ Deep Host Name Resolution:**
  Triple-layer identification: NetBIOS Name Service (UDP 137) + Reverse DNS + HTTP Web Title extraction.
- **📊 Real-Time Bandwidth & Latency Meter:**
  Customizable payload ping (default 1472B MTU packet) to calculate real-time link latency (RTT) and estimated transfer bandwidth (`≥ 1.0 Gbps`, `~850 Mbps`, `~500 Mbps`, `~100 Mbps`).
- **🔀 Smart Multi-Subnet Auto-Detection:**
  Automatically detects all active network adapters (Ethernet, Wi-Fi, VPN) and provides an interactive dropdown selector with visual warning (`⚠️ Subnet:`) when multiple networks are present.
- **📋 Right-Click Instant Actions (Context Menu):**
  Right-click any discovered row to copy IP Address, Host Name, MAC Address, Vendor Info, or Entire Row directly to the Windows Clipboard, or launch instant browser / ping commands.
- **💾 One-Click UTF-8 Log Export:**
  Click `💾 Save Log` to immediately export a structured, UTF-8 BOM report (`Network_Deep_Audit_Report.txt`) to the Desktop and automatically open it.
- **🎮 Retro Demoscene About Box:**
  Click the **`VladiMIR+AI`** brand label in the bottom right corner to open an interactive Winamp-style 3D rotating wireframe cube running at 30 FPS.

---

## 🖥️ User Interface Overview

```text
+------------------------------------------------------------------------------------------------------------------+
|  NetScan by VladiMIR+AI v006                                                                           -  □  ✕  |
+------------------------------------------------------------------------------------------------------------------+
| IP Range: [ 192.168.33.0 ] - [ 192.168.33.255 ]  Timeout: [ 500 ]  Packet: [ 1472 ]  Threads: [ 100 ]            |
| [ ▶ Start Scan ]  [ ⏹ Stop ]  [ 💾 Save Log ]                                                                   |
| [==================================== Progress Bar (100%) ====================================================] |
+-----+----------------------+-----------------+--------------------+-------------------+----------+---------+-----+
| №   | Device Type          | IP Address      | Host Name          | MAC Address       | Ping RTT | Speed   | ... |
+-----+----------------------+-----------------+--------------------+-------------------+----------+---------+-----+
| 1   | 👑 🌐 Router         | 192.168.33.5    | Archer_C80         | E8:DE:27:FB:BF:32 | 0 ms     | ≥ 1 Gbps| ... |
| 2   | 📡 📶 Access Point   | 192.168.33.8    | Mercusys_AP        | 00:EB:D8:FC:F5:71 | 1 ms     | ~850Mbps| ... |
| 3   | 💻 🖥️ PC/Workstation | 192.168.33.157  | E14--Home          | 00:24:32:18:7E:7D | 0 ms     | ≥ 1 Gbps| ... |
| 4   | 📱 📶 Smartphone     | 192.168.33.168  | iPhone-Nikol       | 44:DA:30:C0:68:C3 | 2 ms     | ~500Mbps| ... |
+-----+----------------------+-----------------+--------------------+-------------------+----------+---------+-----+
| Ready. Found: 12 devices in 2.15 seconds.                                                        VladiMIR+AI     |
+------------------------------------------------------------------------------------------------------------------+
```

---

## 🛠️ Build from Source

Requirements: Go 1.19+ and MinGW-w64 (optional, for resource compilation).

```bash
# Clone the repository
git clone https://github.com/GinCz/Linux_Server_Public.git
cd Linux_Server_Public/Windows/Gin-NetScan

# Cross-compile for Windows x86_64
GOOS=windows GOARCH=amd64 go build -ldflags="-H windowsgui -s -w" -o Gin-NetScan.exe main.go
```

---

## 📜 License & Credits

- **Developer:** [Vladimir Bulantsev (GinCz) ↗](https://github.com/GinCz)
- **Engine:** VladiMIR+AI Autonomous Development Suite
- **License:** [MIT License](https://opensource.org/licenses/MIT) — 100% Free for personal, commercial, and enterprise use.
