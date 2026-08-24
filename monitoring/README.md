# 📊 Cluster Live Monitor (`stat_all` / `stat`)

[![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian%20%7C%20DietPi-orange.svg)](https://ubuntu.com/)
[![Bash](https://img.shields.io/badge/Language-Bash%205.0+-green.svg)](https://www.gnu.org/software/bash/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A high-performance, asynchronous parallel cluster monitoring tool designed for multi-node Linux environments.  
Provides a live terminal dashboard with **5-Star compact visual meters** for CPU, RAM, and Disk utilization, coupled with live SMB status and VPN client tracking across all nodes.

---

## ⚡ Quick Start / Launch

### 1. From Master Node Terminal (DE-222)
```bash
stat_all
# or shortcut aliases:
stat
servers_stat
stars
```

### 2. Direct One-Line Execution
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/monitoring/stat_all.sh)
```

---

## 📊 Live Dashboard Preview

```text
═════════════════════════════════════════════════════════════════════════════════════════════════════════════
  SERVER NAME      IP ADDRESS       SMB  Xray   CPU           RAM                    DISK FREE              
═════════════════════════════════════════════════════════════════════════════════════════════════════════════
  222-DE-NetCup    152.53.182.222   ●   0/1    [★★★★★] 100%  4.0G/7.7G [★★★☆☆]  51%  93.3G (247G) [★★★☆☆]  62%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════
  109-RU-FastVDS   212.109.223.109  ●   0/6    [★☆☆☆☆]  26%  5.9G/7.7G [★★★★☆]  76%  14.6G (79G)  [★★★★☆]  76%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════
  alex47           109.234.38.47    ●   2/23   [★☆☆☆☆]  13%  589M/961M [★★★☆☆]  61%  1.7G  (10G)  [★★★★☆]  78%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════
  4ton237          144.124.228.237  ●   1/12   [☆☆☆☆☆]   0%  488M/961M [★★★☆☆]  50%  1.4G  (10G)  [★★★★☆]  80%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════
  tatra9           144.124.232.9    ●   3/18   [☆☆☆☆☆]   8%  637M/961M [★★★☆☆]  66%  0.6G  (10G)  [★★★★☆]  88%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════
  shahin227        144.124.228.227  ●   2/8    [☆☆☆☆☆]   4%  438M/960M [★★☆☆☆]  45%  6.4G  (10G)  [★☆☆☆☆]  29%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════
  stolb24          144.124.239.24   ●   0/9    [☆☆☆☆☆]   0%  349M/957M [★★☆☆☆]  36%  1.6G  (10G)  [★★★★☆]  78%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════
  pilik33          195.63.138.33    ●   2/5    [★☆☆☆☆]  14%  459M/960M [★★☆☆☆]  47%  6.4G  (10G)  [★☆☆☆☆]  29%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════
  ilya176          146.103.110.176  ●   0/12   [☆☆☆☆☆]   0%  467M/960M [★★☆☆☆]  48%  6.3G  (10G)  [★★☆☆☆]  30%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════
  so38             144.124.233.38   ●   1/6    [☆☆☆☆☆]   4%  336M/957M [★★☆☆☆]  35%  3.1G  (10G)  [★★★☆☆]  63%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════
  [ 21:57:01 ]  |  [Ctrl+C] Exit  |  [F5 / Enter] Refresh now  |  Auto-Refresh: 5s
```

---

## 🛠️ Key Features
- **Parallel Asynchronous Polling:** Queries all 10 nodes concurrently via non-blocking SSH subprocesses in < 1 second.
- **Dynamic 5-Star Visual Indicators:** Compact `[★★★☆☆]` gauges with automatic color transitions (Green <75%, Yellow 75-89%, Red ≥90%).
- **Samba Service Indicator (SMB):** Live green dot (`●`) for running Samba services and red cross (`✗`) if stopped.
- **Xray VPN Metrics:** Live active client connections against total configured clients in green (`X/Y`).
- **Disk Free Space:** Real-time free disk space and total volume capacity (`1.7G (10G)`).
- **Interactive Controls:** Instant manual refresh via `[F5]` or `[Enter]`, live automatic refresh every 5 seconds, and instant exit via `[Ctrl+C]` or `[Q]`.