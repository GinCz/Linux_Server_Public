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

## 📁 Repository Modules & Dedicated Documentation

Each core tool in this repository is maintained in its own dedicated module folder with documentation and standalone scripts:

| Module / Directory | Description | Documentation |
| :--- | :--- | :--- |
| 📊 **[`monitoring/`](monitoring/)** | Parallel Multi-Node Live Cluster & VPN Monitor (`stat_all` / `stat`) | [`monitoring/README.md`](monitoring/README.md) |
| 🔍 **[`sos/`](sos/)** | Interactive Deep Server Diagnostics & Security Audit Suite (`sos`) | [`sos/README.md`](sos/README.md) |
| ℹ️ **[`info/`](info/)** | Detailed Hardware Specs, Network Interfaces & System Info (`infooo`) | [`info/README.md`](info/README.md) |
| ⌨️ **[`aliases/`](aliases/)** | Master Terminal Aliases, Colorized Prompts & Modded Midnight Commander | [`aliases/README.md`](aliases/README.md) |
| 💾 **[`WinSambaBackup/`](WinSambaBackup/)** | Windows & Linux Bare-Metal Disk Backup & Restore over SMB/Samba | [`WinSambaBackup/README.md`](WinSambaBackup/README.md) |
| 🚀 **[`DietPi/`](DietPi/)** | Automated Ultra-Light Linux Live Installer & Migration Script | [`DietPi/README.md`](DietPi/README.md) |
| 🛡️ **[`IPGuard/`](IPGuard/)** | Dynamic IP Whitelist & Samba / SSH Protection Daemon | [`IPGuard/README.md`](IPGuard/README.md) |
| 🛡️ **[`antivir/`](antivir/)** | ClamAV Antivirus Provisioning, Scanner & Quarantine Suite (`antivir`) | [`antivir/README.md`](antivir/README.md) |
| 🌐 **[`domains/`](domains/)** | Domain Status, HTTP Response Code & SSL Certificate Monitor (`domains`) | [`domains/README.md`](domains/README.md) |
| ⚡ **[`wpupd/`](wpupd/)** | Batch WordPress Core, Plugin & Theme Auto-Updater (`wpupd`) | [`wpupd/README.md`](wpupd/README.md) |
| 🧹 **[`cleanup/`](cleanup/)** | Deep SSD Disk Cleanup, Journal Vacuuming & RAM Flushing (`cleanup`) | [`cleanup/README.md`](cleanup/README.md) |
| 🛡️ **[`fight/`](fight/)** | Automated Bot Blocking, Iptables Rate-Limiting & Security (`fight`) | [`fight/README.md`](fight/README.md) |
| 🤖 **[`AI_Tokens/`](AI_Tokens/)** | AI Context Economy, Worklog Architecture & Engineering Guide | [`AI_Tokens/README.md`](AI_Tokens/README.md) |
| ☁️ **[`Oracle_Cloud/`](Oracle_Cloud/)** | Automated Free-Tier ARM Always-Free Instance Provisioner | [`Oracle_Cloud/README.md`](Oracle_Cloud/README.md) |
| 🛡️ **[`AdGuard/`](AdGuard/)** | DNS Sinkhole, Ad-Blocking & Privacy Security Suite | [`AdGuard/README.md`](AdGuard/README.md) |
| ☁️ **[`Cloudflare/`](Cloudflare/)** | Edge WAF Rules, Security Headers & Real-IP Nginx Configurations | [`Cloudflare/README.md`](Cloudflare/README.md) |
| 🔑 **[`XRAY/`](XRAY/)** | VLESS / Reality VPN Provisioning, Backups & Client Traffic | [`XRAY/README.md`](XRAY/README.md) |

---

## 📊 Cluster Live Monitor (`stat_all` / `stat`)

High-performance, asynchronous parallel cluster monitoring tool with **5-Star compact visual meters**, live SMB status, and live VPN client tracking.

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
  [ 22:49:20 ]  |  [Ctrl+C] Exit  |  Auto-Refresh: 3s
```

```bash
# Universal Installer & Launcher (1. Portable Run / 2. Permanent Install)
clear; apt-get update -qq && apt-get install -y -qq curl ca-certificates && bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/monitoring/install.sh)
```

### ✨ Key Monitor Features:
- 🚀 **Asynchronous Querying:** All nodes polled concurrently in under 0.6 seconds via non-blocking SSH.
- 📺 **Flicker-Free Live Updates:** Double-buffering with ANSI cursor positioning `\033[H`.
- 🛡️ **VPN Client Detection:** Live 3x-ui SQLite query (`/etc/x-ui/x-ui.db`), WireGuard (`wg show`), and Docker.
- ⚡ **Precision Combined CPU:** `max(instant /proc/stat delta, normalized loadavg per core)`.
- ⏱️ **Automatic 3-Second Interval:** Smooth live auto-refresh with `Ctrl+C` clean exit.

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