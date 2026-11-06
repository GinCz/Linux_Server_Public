# 🌐 Linux Server Public — Production Infrastructure & Automation Suite

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%2024.04%20LTS%20%7C%20Debian%2012-orange.svg)](https://ubuntu.com/)
[![Bash](https://img.shields.io/badge/Language-Bash%205.0+-green.svg)](https://www.gnu.org/software/bash/)
[![Security](https://img.shields.io/badge/Security-Xray%20%7C%20CrowdSec%20%7C%20WireGuard%20%7C%20IPGuard-red.svg)](https://github.com/GinCz/Linux_Server_Public)

A production-grade collection of automated provisioning scripts, hardening frameworks, live parallel cluster monitoring, and network security tools for enterprise **Ubuntu 24.04 LTS** and **Debian 12** server fleets.

> **Maintained by:** [Vladimir Bulantsev (GinCz)](https://github.com/GinCz) & Anti-Gravity AI  
> **Ecosystem Navigation:** [🪟 Windows Suite (.EXE & Scripts) ↗](https://github.com/GinCz/Windows_scripts) • [📱 Android Suite (.apk) ↗](https://github.com/GinCz/Android)

---

## ⚡ 1-Click Instant Execution & Fast Launch

Deploy tools and diagnostics instantly across fresh VPS or production instances via single terminal commands:

| Tool / Automation | Target OS | 1-Click Terminal Command |
| :--- | :--- | :--- |
| 🚀 **Fresh Server Provisioning** | Ubuntu 24 / Debian 12 | `bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh)` |
| 🧹 **Deep System Cleaner** | All Linux | `bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/server_cleanup.sh)` |
| 🐧 **Ubuntu 24 LTS Slim** | Ubuntu 24.04 LTS | `bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Ubuntu24_Slim/ubuntu24_slim.sh)` |
| 🐧 **Debian 12 Slim** | Debian 12 | `bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Debian12_Slim/debian12_slim.sh)` |
| 📊 **Cluster Live Monitor** | Any Linux (SSH Master) | `bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/monitoring/install.sh)` |
| 🔍 **Interactive SOS Diagnostics**| All Linux | `bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/install_sos_standalone.sh)` |
| 💾 **Fastpanel Auto-Fix** | Fastpanel / Nginx | `bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/fastpanel-fix.sh)` |
| 🛡️ **Secure Disk Wipe** | All Linux | `bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/wipe_disk.sh)` |

---

## 🌐 Enterprise Multi-Datacenter Network Architecture

Designed for distributed hybrid infrastructure spread across European and international datacenters (Oracle Cloud, Netcup, AWS EC2, and private VDS clusters):

- **Private L2/L3 Interconnect:** High-throughput isolated overlay networking without public transit fees.
- **Perimeter Threat Defense:** Multi-stage edge filtering combining **Cloudflare WAF**, **CrowdSec**, **Fail2Ban**, and custom IP-set kernel tables.
- **Zero-Latency Monitoring:** Parallel SSH socket polling reporting real-time CPU, RAM, NVMe I/O, Samba SMB status, and live VPN client connections.

---

## 📁 Repository Modules & Dedicated Documentation

| Module / Directory | Category | Description | Documentation |
| :--- | :--- | :--- | :--- |
| 📊 **[`monitoring/`](monitoring/)** | Observability | Parallel Multi-Node Live Cluster & VPN Monitor (`stat_all` / `stat`) | [`monitoring/README.md`](monitoring/README.md) |
| 🔍 **[`sos/`](sos/)** | Diagnostics | Interactive Deep Server Diagnostics & Security Audit Suite (`sos`) | [`sos/README.md`](sos/README.md) |
| 🛡️ **[`IPGuard/`](IPGuard/)** | Security | Dynamic IP Whitelist & Samba / SSH Protection Daemon | [`IPGuard/README.md`](IPGuard/README.md) |
| 🛡️ **[`crowdsec/`](crowdsec/)** | Intrusion Prevention | CrowdSec automated bouncers, L7 behavioral parsers, and custom scenarios | [`crowdsec/README.md`](crowdsec/README.md) |
| 🛡️ **[`antivir/`](antivir/)** | Malware Defense | ClamAV Antivirus Provisioning, Daily Scanner & Automated Quarantine | [`antivir/README.md`](antivir/README.md) |
| 🧹 **[`cleanup/`](cleanup/)** | Maintenance | Deep SSD Disk Cleanup, Journal Vacuuming & RAM Flushing (`cleanup`) | [`cleanup/README.md`](cleanup/README.md) |
| ⌨️ **[`aliases/`](aliases/)** | Shell UX | Master Terminal Aliases, Colorized Prompts & Modded Midnight Commander | [`aliases/README.md`](aliases/README.md) |
| ℹ️ **[`info/`](info/)** | System Profiler | Detailed Hardware Specs, Network Interfaces & System Info (`infooo`) | [`info/README.md`](info/README.md) |
| 💾 **[`WinSambaBackup/`](WinSambaBackup/)** | Storage & Backup | Windows & Linux Bare-Metal Disk Backup & Restore over SMB/Samba | [`WinSambaBackup/README.md`](WinSambaBackup/README.md) |
| 🚀 **[`Ubuntu24_Slim/`](Ubuntu24_Slim/)** | Hardening | Automated minimal hardening profile for Ubuntu 24.04 LTS servers | [`Ubuntu24_Slim/README.md`](Ubuntu24_Slim/README.md) |
| 🚀 **[`Debian12_Slim/`](Debian12_Slim/)** | Hardening | Automated minimal headless profile for Debian 12 Bookworm | [`Debian12_Slim/README.md`](Debian12_Slim/README.md) |
| 🛡️ **[`AdGuard/`](AdGuard/)** | DNS Shield | DNS Sinkhole, Ad-Blocking & Privacy Security Suite | [`AdGuard/README.md`](AdGuard/README.md) |
| ☁️ **[`Cloudflare/`](Cloudflare/)** | Edge Security | Edge WAF Rules, Security Headers & Real-IP Nginx Configurations | [`Cloudflare/README.md`](Cloudflare/README.md) |
| 🔑 **[`XRAY/`](XRAY/)** | VPN Gateway | High-speed VLESS Reality & WireGuard setup and traffic monitoring | [`XRAY/README.md`](XRAY/README.md) |
| 🌐 **[`domains/`](domains/)** | Web Services | Domain HTTP Response Code, TLS Expiration & Route Monitor | [`domains/README.md`](domains/README.md) |
| ⚡ **[`wpupd/`](wpupd/)** | Web CMS | Batch WordPress Core, Plugin & Theme Auto-Updater (`wpupd`) | [`wpupd/README.md`](wpupd/README.md) |
| 🌍 **[`RU_IP_BLOCK/`](RU_IP_BLOCK/)** | Network Quality | Regional TCP reachability checks, latency metrics, and network failover | [`RU_IP_BLOCK/README.md`](RU_IP_BLOCK/README.md) |

---

## 📊 Live Cluster Monitor Architecture

High-performance, asynchronous parallel cluster monitoring tool with **5-Star visual meters**, live SMB status, and live VPN client tracking:

```text
======================================================================================================================
  SERVER NAME      IP ADDRESS         SMB    Xray   CPU             RAM                      DISK FREE                
======================================================================================================================
  master-node      127.0.0.1          ●      0/1    [★★★☆☆]  67%    3.5G/7.7G [★★☆☆☆]  45%    93.3G (247G) [★★★★☆]  62%
======================================================================================================================
  web-cluster-01   198.51.100.10      ●      0/6    [☆☆☆☆☆]   5%    5.4G/7.7G [★★★★☆]  70%    14.6G (79G)  [★★★★☆]  76%
======================================================================================================================
  db-primary       198.51.100.20      ●      2/23   [☆☆☆☆☆]   0%    582M/961M [★★★☆☆]  60%    1.7G  (10G)  [★★★★☆]  78%
======================================================================================================================
  vpn-frankfurt    198.51.100.30      ●      1/12   [☆☆☆☆☆]   3%    478M/961M [★★☆☆☆]  49%    1.4G  (10G)  [★★★★☆]  80%
======================================================================================================================
  vpn-helsinki     198.51.100.40      ●      2/18   [☆☆☆☆☆]   4%    632M/961M [★★★☆☆]  65%    0.6G  (10G)  [★★★★☆]  88%
======================================================================================================================
  [ 22:49:20 ]  |  [Ctrl+C] Exit  |  Auto-Refresh: 3s
```

### ✨ Key Monitor Features:
- 🚀 **Non-Blocking SSH Concurrency:** All nodes polled simultaneously in under 0.6 seconds via background threads.
- 📺 **ANSI Double-Buffering:** Zero terminal flicker using cursor home repositioning (`\033[H`).
- 🛡️ **VPN Client Detection:** Native SQLite queries (`/etc/x-ui/x-ui.db`), WireGuard (`wg show`), and Docker containers.
- ⚡ **Accurate CPU Telemetry:** Real-time calculation derived from normalized load average and `/proc/stat` deltas.

---

## 🛠️ Tool Suite & System Aliases

Upon installing the master aliases suite (`new_server_install.sh`), the following commands become instantly available system-wide:

| Alias / Command | Purpose |
| :--- | :--- |
| **`servers_stat`** / **`stars`** | Interactive Live Cluster Hardware & VPN Monitor |
| **`sos`** | Comprehensive interactive server diagnostics & security audit |
| **`cleanup`** | Deep disk cleanup (journalctl vacuum, APT caches, old kernel modules) |
| **`antivir`** | ClamAV scanning suite and malware quarantine |
| **`fight`** | Automated bot blocking, DDoS mitigation & firewall security |
| **`domains`** | Web server HTTP/HTTPS & SSL certificate validator |
| **`wpupd`** | Automated batch updater for WordPress core, plugins, and themes |
| **`wpcron`** | CLI-based WordPress background cron runner |

---

## 👤 Author & Architecture

- **Vladimir Bulantsev (GinCz)** — Systems Architect & DevOps Engineer
- **GitHub Profile:** [https://github.com/GinCz](https://github.com/GinCz)
- **Linux Suite:** [https://github.com/GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)
- **Windows Suite:** [https://github.com/GinCz/Windows_scripts](https://github.com/GinCz/Windows_scripts)
- **Android Suite:** [https://github.com/GinCz/Android](https://github.com/GinCz/Android)

---

<div align="center">

<h3>= Rooted by VladiMIR + AI =</h3>

<a href="https://github.com/GinCz" target="_blank" rel="noopener noreferrer"><img src="https://img.shields.io/badge/GitHub-GinCz-181717?style=flat&logo=github&logoColor=white" alt="GitHub" /></a>
&nbsp;&nbsp;<b>|||</b>&nbsp;&nbsp;
<a href="https://www.linkedin.com/in/gincz/" target="_blank" rel="noopener noreferrer"><img src="https://img.shields.io/badge/LinkedIn-Vladimir%20Bulantsev-0A66C2?style=flat&logo=linkedin&logoColor=white" alt="LinkedIn" /></a>

<br/><br/>

<sub>Linux_Server_Public &copy; 2026. VladiMIR + AI</sub>

</div>
