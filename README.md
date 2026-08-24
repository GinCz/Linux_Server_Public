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

## 📊 Cluster Live Monitor (`servers_stat` / `stars`)

High-performance, asynchronous parallel cluster monitoring tool with **10-Star colored visual meters** and live VPN client tracking.

```text
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
  SERVER NAME      IP ADDRESS         Xray       CPU                 RAM                             DISK                                
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
  222-DE-NetCup    152.53.182.222     ✗  OFF     [★★★★★★★☆☆☆]  74%   3.3G/7.7G   [★★★★☆☆☆☆☆☆]  42%   93.9G free (247G)  [★★★★★★☆☆☆☆]  61%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
  109-RU-FastVDS   212.109.223.109    ●  0/6     [★★★☆☆☆☆☆☆☆]  26%   5.7G/7.7G   [★★★★★★★☆☆☆]  74%   14.6G free (79G)   [★★★★★★★★☆☆]  76%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
  alex47           109.234.38.47      ●  2/23    [☆☆☆☆☆☆☆☆☆☆]   4%   582M/961M   [★★★★★★☆☆☆☆]  60%   1.7G free (10G)    [★★★★★★★★☆☆]  78%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
  4ton237          144.124.228.237    ●  1/12    [☆☆☆☆☆☆☆☆☆☆]   1%   476M/961M   [★★★★★☆☆☆☆☆]  49%   1.4G free (10G)    [★★★★★★★★☆☆]  80%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
  tatra9           144.124.232.9      ●  1/18    [☆☆☆☆☆☆☆☆☆☆]   4%   618M/961M   [★★★★★★☆☆☆☆]  64%   0.6G free (10G)    [★★★★★★★★★☆]  88%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
  shahin227        144.124.228.227    ●  3/8     [☆☆☆☆☆☆☆☆☆☆]   0%   569M/961M   [★★★★★★☆☆☆☆]  59%   0.7G free (10G)    [★★★★★★★★★☆]  87%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
  stolb24          144.124.239.24     ●  1/9     [★★☆☆☆☆☆☆☆☆]  22%   306M/957M   [★★★☆☆☆☆☆☆☆]  31%   1.7G free (10G)    [★★★★★★★★☆☆]  78%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
  pilik33          195.63.138.33      ●  3/5     [★☆☆☆☆☆☆☆☆☆]   9%   568M/961M   [★★★★★★☆☆☆☆]  59%   0.9G free (10G)    [★★★★★★★★★☆]  86%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
  ilya176          146.103.110.176    ●  0/12    [★★☆☆☆☆☆☆☆☆]  19%   403M/960M   [★★★★☆☆☆☆☆☆]  41%   6.4G free (10G)    [★★★☆☆☆☆☆☆☆]  29%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
  so38             144.124.233.38     ●  1/6     [☆☆☆☆☆☆☆☆☆☆]   4%   335M/957M   [★★★★☆☆☆☆☆☆]  35%   3.1G free (10G)    [★★★★★★☆☆☆☆]  63%
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
  [ 17:18:20 ]  |  [Ctrl+C] Exit  |  [F5 / Enter] Refresh now  |  Auto-Refresh: 5s
```

### ✨ Key Monitor Features:
- 🚀 **Asynchronous Querying:** All 10 nodes polled concurrently in under 0.6 seconds.
- 📺 **Flicker-Free Live Updates:** Background double-buffering with ANSI cursor positioning `\033[H`.
- 🛡️ **VPN Client Detection:** Queries 3x-ui SQLite database (`/etc/x-ui/x-ui.db`), WireGuard (`wg show`), and Docker AmneziaWG.
- ⚡ **Precision Combined CPU:** `max(instant /proc/stat delta, normalized loadavg per core)`.
- ⌨️ **Interactive Controls:** Press `F5`, `Enter`, or Space to trigger an immediate update; `Ctrl+C` or `q` for a clean exit.

---

## 🔑 Prerequisites & Master Node Architecture

The monitor operates on a **Master Node architecture** (e.g. `222-DE-NetCup`) to poll all cluster servers simultaneously without manual password prompts:

1. **Passwordless SSH Master Key**:
   The Master Node must have direct, passwordless SSH key access (`/root/.ssh/id_ed25519` or `id_rsa`) to all target nodes:
   ```bash
   # From Master Node to each target server:
   ssh-copy-id -i /root/.ssh/id_ed25519.pub root@<TARGET_SERVER_IP>
   ```
2. **Authorized Keys Verification**:
   Ensure each remote server in the `SERVERS` array has the Master Node's public key present in `/root/.ssh/authorized_keys`.
3. **Local Tools**:
   Standard utilities on nodes (`sqlite3`, `ss`, `free`, `df`, `awk`, `date`) are used automatically without installing heavy agents.

---

## 🛠️ Tool Suite & System Aliases

| Alias / Command | Description |
| :--- | :--- |
| **`servers_stat`** / **`stars`** | Interactive Live Cluster Hardware & VPN Monitor |
| **`sos`** | Comprehensive interactive server diagnostics & security audit |
| **`cleanup`** | Deep disk cleanup (journalctl vacuum, APT caches, old kernel modules) |
| **`antivir`** | ClamAV scanning suite |
| **`fight`** | Automated bot blocking & firewall security |
| **`domains`** | Web server HTTP/HTTPS & SSL certificate validator |
| **`wpupd`** | Automated batch updater for WordPress core, plugins, and themes |
| **`wpcron`** | CLI-based WordPress background cron runner |
| **`save`** / **`load`** | Fast Git synchronization scripts |

---

## 🏷️ Tags & Topics

`#linux` `#devops` `#sysadmin` `#bash` `#server-management` `#wireguard` `#xray` `#vless` `#reality` `#amnezia` `#crowdsec` `#fastpanel` `#monitoring` `#ubuntu24`

---

## 👤 Author

- **Vladimir Bulantsev (GinCz)**
- **GitHub:** [https://github.com/GinCz](https://github.com/GinCz)
- **Repository:** [https://github.com/GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)