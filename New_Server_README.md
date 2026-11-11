# 🚀 New Server Setup & Quick Commands Cheat Sheet

> Repository: [GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)  
> Author: [Vladimir Bulantsev (GinCz)](https://github.com/GinCz)

Production cheat sheet of 1-line commands for provisioning, optimization, disk vacuuming, and health diagnostics (**Ubuntu 24.04**, **Debian 12**, **DietPi**).

---

## ⚡ 1. New Server Setup & Baseline Provisioning

Deploys base administration toolchain, colorized PS1 prompt, custom Midnight Commander skin, informative MOTD banner, and core aliases:

```bash
clear; apt-get update -qq && apt-get install -y -qq curl ca-certificates && bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh)
```

---

## 🧹 2. Deep Disk Vacuum (Universal Server Cleaner)

Safely frees 2–4 GB of disk space, compresses systemd journals to 30 MB, optimizes swapfile, and purges obsolete packages (safely preserves **Xray VPN, Samba, FastPanel, Nginx, AdGuard Home, Uptime Kuma, SSH**):

```bash
clear; apt-get update -qq && apt-get install -y -qq curl ca-certificates && bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/server_cleanup.sh)
```
*(Or in terminal via alias: `cleanup`)*

---

## 🚀 3. Hardcore Slim & Performance Optimizer (Ubuntu 24)

Reduces idle RAM consumption to 60–80 MB, enables TCP BBR congestion control, strips unnecessary daemons:

```bash
clear; apt-get update -qq && apt-get install -y -qq curl ca-certificates && bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Ubuntu24_Slim/ubuntu24_slim.sh)
```

---

## 🔍 4. SOS Health & Security Diagnostic Monitor

Deep system inspection: active listening ports, active VPN sessions, OOM-killer incidents, NVMe/SSD wear, and network interfaces:

```bash
sos
```
*(Or 1-click execution: `bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh) 1h`)*

---

## 📊 5. Multi-Node Cluster Live Monitor

Interactive parallel SSH cluster dashboard with live 5-star metric gauges, Samba status, and VPN client monitoring:

```bash
servers_stat
```
*(Or via alias: `stars` or `st`)*

---

## 🛡️ 6. ClamAV Antivirus Suite

Interactive ClamAV antivirus manager:

```bash
antivir
```

---

## 🔄 7. Repository Synchronization on Servers

- **load** — Instantly pulls latest production scripts from GitHub to server.
- **save** — Stages local server changes and pushes back to GitHub.

---

*= Rooted by VladiMIR + AI | v.2026.08.25 | github.com/GinCz/Linux_Server_Public =*
