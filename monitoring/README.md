# 📊 Cluster Resource & VPN Live Monitor (`stat_all`)

[![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian%20%7C%20DietPi-orange.svg)](https://ubuntu.com/)
[![Bash](https://img.shields.io/badge/Language-Bash%205.0+-green.svg)](https://www.gnu.org/software/bash/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

High-performance, asynchronous parallel cluster monitoring tool for multi-node Linux environments.  
Provides a live terminal dashboard with **5-Star visual meters** for CPU, RAM, and Disk utilization, combined with live Samba status and VPN client metrics across all cluster nodes.

---

## ⚡ Quick Start & Installation

### 🚀 Universal One-Line Installer & Launcher
Run the single command below to launch the interactive wizard (select between **Portable Run** or **Permanent Installation**):

```bash
clear; apt-get update -qq && apt-get install -y -qq curl ca-certificates && bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/monitoring/install.sh)
```

The installer will ask:
```text
╔══════════════════════════════════════════════════════════════════════════════╗
║     ░▒▓█  CLUSTER RESOURCE & VPN LIVE MONITOR (stat_all v10.0)  █▓▒░         ║
║     Author: Vladimir Bulantsev (GinCz) | Open-Source Public Edition          ║
╚══════════════════════════════════════════════════════════════════════════════╝

  1) Запустить как portable версию  (разовый запуск без установки в систему)
  2) Установить на сервер           (в /usr/local/bin/stat_all + авто-алиасы)
  3) Выход
```

---

## ⚙️ Server Configuration (`servers.conf`)

`stat_all` automatically checks for server lists in the following priority:
1. `/etc/stat_all/servers.conf` (System-wide configuration)
2. `~/.config/stat_all/servers.conf` (User-specific configuration)
3. `./servers.conf` (Local directory configuration)

### Example `/etc/stat_all/servers.conf`:
```conf
# Format: ServerName:IP_or_Host (one per line)
master-node:127.0.0.1
web-cluster-01:192.168.1.10
db-primary:192.168.1.20
vpn-frankfurt:198.51.100.10
vpn-helsinki:203.0.113.15
```

> **SSH Key Authentication:** Remote nodes are queried asynchronously via OpenSSH using your default master key (`~/.ssh/id_ed25519` or `~/.ssh/id_rsa`). Ensure key-based passwordless access is configured between the master node and cluster nodes.

---

## 📊 Live Dashboard Preview

```text
======================================================================================================================
  SERVER NAME      IP ADDRESS         SMB    Xray   CPU             RAM                      DISK FREE                
======================================================================================================================
  master-node      127.0.0.1          ●      0/1    [★★★☆☆]  67%    3.5G/7.7G [★★☆☆☆]  45%    93.3G (247G) [★★★★☆]  62%
======================================================================================================================
  web-cluster-01   192.168.1.10       ●      0/6    [☆☆☆☆☆]   5%    5.4G/7.7G [★★★★☆]  70%    14.6G (79G)  [★★★★☆]  76%
======================================================================================================================
  db-primary       192.168.1.20       ●      2/23   [☆☆☆☆☆]   0%    582M/961M [★★★☆☆]  60%    1.7G  (10G)  [★★★★☆]  78%
======================================================================================================================
  vpn-frankfurt    198.51.100.10      ●      1/12   [☆☆☆☆☆]   3%    478M/961M [★★☆☆☆]  49%    1.4G  (10G)  [★★★★☆]  80%
======================================================================================================================
  vpn-helsinki     203.0.113.15       ●      2/18   [☆☆☆☆☆]   4%    632M/961M [★★★☆☆]  65%    0.6G  (10G)  [★★★★☆]  88%
======================================================================================================================
  [ 22:49:20 ]  |  [Ctrl+C] Exit  |  [F5 / Enter] Refresh now  |  Auto-Refresh: 5s
```

---

## 🛠️ Key Features

- **Parallel Asynchronous Polling:** Queries all cluster nodes concurrently via non-blocking SSH subshells in < 1 second.
- **Dynamic 5-Star Visual Indicators:** Compact `[★★★☆☆]` gauges with automatic color transitions (Green <75%, Yellow 75-89%, Red ≥90%).
- **Samba Service Indicator (SMB):** Live green dot (`●`) for running Samba services and red cross (`✗`) if stopped.
- **Xray VPN Metrics:** Live active client connections against total configured clients in green (`X/Y`).
- **Disk Free Space:** Real-time free disk space and total volume capacity (`1.7G (10G)`).
- **Interactive Controls:** Instant manual refresh via `[F5]` or `[Enter]`, live automatic refresh every 5 seconds, and instant exit via `[Ctrl+C]` or `[Q]`.
