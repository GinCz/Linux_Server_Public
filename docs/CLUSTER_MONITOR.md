# 🌐 Linux Server Public — Production Infrastructure & Management

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%2024.04%20LTS-orange.svg)](https://ubuntu.com/)
[![Bash](https://img.shields.io/badge/Language-Bash%205.0+-green.svg)](https://www.gnu.org/software/bash/)
[![Security](https://img.shields.io/badge/Security-Xray%20%7C%20CrowdSec%20%7C%20WireGuard-red.svg)](https://github.com/GinCz/Linux_Server_Public)

A production-grade Linux server automation, monitoring, and provisioning suite maintained by [Vladimir Bulantsev (GinCz)](https://github.com/GinCz).

---

## ⚡ Quick One-Line Installation

To provision a fresh server or update aliases, styles, and tools on an existing node:

```bash
clear; apt-get update -qq && apt-get install -y -qq curl ca-certificates && bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh)
```

---

## 📊 Cluster Live Monitor (`st` / `stat_all` / `stat`)

High-performance, asynchronous parallel cluster monitoring tool with **5-Star compact visual meters**, live SMB status, and live VPN client tracking.

```text
═════════════════════════════════════════════════════════════════════════════════════════════════════════════
  SERVER NAME      IP ADDRESS       SMB  Xray   CPU           RAM                    DISK FREE              
═════════════════════════════════════════════════════════════════════════════════════════════════════════════
  222-DE-NetCup    152.53.182.222   ●   0/1    [★★★★★] 100%  4.0G/7.7G [★★★☆☆]  51%  93.3G (247G) [★★★☆☆]  62%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════
  109-RU-FastVDS   212.109.223.109  ●   0/6    [★☆☆☆☆]  26%  5.9G/7.7G [★★★★☆]  76%  14.6G (79G)  [★★★★☆]  76%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════
  alex47           212.34.148.51    ●   2/23   [★☆☆☆☆]  13%  589M/961M [★★★☆☆]  61%  1.7G  (10G)  [★★★★☆]  78%
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
  [ 21:57:01 ]  |  [Ctrl+C] Exit  |  Auto-Refresh: 3s
```

### ✨ Key Monitor Features:
- 🚀 **Asynchronous Querying:** All nodes polled concurrently in under 0.6 seconds.
- 🚦 **5-Star Compact Visual Meter:** Real-time visual usage indicators with dynamic colors (Green <75%, Yellow 75-89%, Red ≥90%).
- 🛡️ **VPN Client Activity:** Live active user connection tracking against total registered client accounts.
- 💾 **Samba Status Indicator (SMB):** Quick service visual indication (`●` active / `✗` inactive).
- 🔄 **Real-Time Live Interface:** Auto-refreshes every 3s with clean `[Ctrl+C]` exit.