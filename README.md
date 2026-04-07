# 🖥️ Linux Server Public — VladiMIR

> Public configuration files, scripts, and documentation for two production servers.  
> **All secrets, passwords, and API keys are stored in a separate PRIVATE repository.**

---

## 🗂️ Repository Structure

```
Linux_Server_Public/
├── 222/          → Server 222-DE-NetCup   (152.53.182.222)  — NetCup.com, Germany
│                  Ubuntu 24 / FASTPANEL / Cloudflare / CZ+EU sites
│                  4 vCore AMD EPYC-Genoa / 8GB DDR5 ECC / 256GB NVMe
│                  📖 Full docs: 222/README.md
│
├── 109/          → Server 109-RU-FastVDS  (212.109.223.109) — FastVDS.ru, Russia
│                  Ubuntu 24 / FASTPANEL / No Cloudflare / RU sites
│                  4 vCore AMD EPYC 7763 / 8GB RAM / 80GB NVMe
│                  📖 Full docs: 109/README.md
│
├── VPN/          → AmneziaWG VPN nodes (server 47, etc.)
│                  📖 Full docs: VPN/MOTD_HOWTO.md
│
├── scripts/      → Shared scripts used by ALL servers
│                  shared_aliases.sh — common aliases (save, load, aw, mc...)
│
└── README.md     → This file — quick reference & coding standards
```

---

## ✏️ How to Edit MOTD Banner (login screen)

> **MOTD** = the banner you see every time you SSH into the server.

### Where is the file?
| Server | File on server | File in repo |
|---|---|---|
| 222-DE-NetCup | `/etc/profile.d/motd_server.sh` | `222/motd_server.sh` |
| 109-RU-FastVDS | `/etc/profile.d/motd_server.sh` | `109/motd_server.sh` |
| VPN nodes (47, etc.) | `/etc/profile.d/motd_server.sh` | `VPN/motd_server.sh` |

### How to add/remove an alias from the MOTD menu:
```bash
nano /etc/profile.d/motd_server.sh
# Find the block: # Row 1 (SCAN/SERVER/WORDPRESS) or # Row 2 (BOT/GIT/TOOLS)
# Each line format:
echo -e "  ${G}aliasname${X}(description)      ${G}alias2${X}(desc)      ${G}alias3${X}(desc)"
# Column width: ~26 chars per column (use spaces to align)
# Test immediately:
bash /etc/profile.d/motd_server.sh
# Save to repo (example for 222):
cd /root/Linux_Server_Public
cp /etc/profile.d/motd_server.sh 222/motd_server.sh
save
```

---

## ✏️ How to Edit Aliases (.bashrc)

### Where is the file?
| Server | File on server | File in repo |
|---|---|---|
| 222-DE-NetCup | `/root/.bashrc` | `222/.bashrc` |
| 109-RU-FastVDS | `/root/.bashrc` | `109/.bashrc` |
| VPN nodes | `/root/.bashrc` | `VPN/.bashrc` |
| ALL servers (shared) | sourced from `.bashrc` | `scripts/shared_aliases.sh` |

### How to add an alias:
```bash
nano /root/.bashrc
# Add line: alias myalias='command'
source /root/.bashrc          # apply without re-login
# ⚠️ Also add it to MOTD menu (motd_server.sh) so it shows in banner!
# Save to repo (example for 222):
cd /root/Linux_Server_Public
cp /root/.bashrc 222/.bashrc
save
```

---

## 🔄 Standard Update Workflow

```bash
# Pull latest from repo and install on server:
cd /root/Linux_Server_Public && git pull
cp 222/motd_server.sh /etc/profile.d/motd_server.sh   # update MOTD
cp 222/.bashrc /root/.bashrc                           # update aliases
source /root/.bashrc
bash /etc/profile.d/motd_server.sh                    # test banner

# After editing files on server — push back to repo:
cd /root/Linux_Server_Public
cp /etc/profile.d/motd_server.sh 222/motd_server.sh
cp /root/.bashrc 222/.bashrc
save
```

---

## 🔒 CrowdSec — Fix Engine INACTIVE

```bash
mkdir -p /etc/crowdsec/hub
cscli hub update
cscli hub upgrade
systemctl restart crowdsec
systemctl status crowdsec --no-pager | head -5
```

---

## 🚨 PHP-FPM Watchdog — Telegram Alert

If you receive Telegram alert:
```
⚠️ 222-DE-NetCup
PHP-FPM pool kk-med.eu
CPU=103% for 29min → php-fpm restarted automatically
```
This means **watchdog** (`php_fpm_watchdog.sh`) detected a runaway PHP-FPM pool and restarted it.  
This is **normal auto-recovery** — no manual action needed unless it repeats.

To investigate:
```bash
watchdog          # run manually to check current state
sos               # check recent nginx/php errors
wphealth          # check WordPress sites health
```

---

## 📜 Coding Standards (Mandatory for ALL scripts)

Every script committed to this repository **must** follow these rules:

### 1. 🌈 Colour Output
```bash
RED='\033[0;31m'     # Errors, critical warnings
YEL='\033[1;33m'     # Warnings, detected values
GRN='\033[0;32m'     # Success, OK messages
CYN='\033[0;36m'     # Section headers, info blocks
NC='\033[0m'         # Reset colour
```

### 2. 📍 Version
```bash
# Version: v2026-04-08
```

### 3. 📝 Header Block
```bash
#!/bin/bash
# =============================================================
# Script: script_name_v2026-04-08.sh
# Version: v2026-04-08
# Server: [server name and IP]
# Description: What this script does.
# Usage: bash script_name.sh
# WARNING: [side effects]
# = Rooted by VladiMIR | AI =
# =============================================================
clear
```

### 4. 🔒 No Secrets
- ✅ Templates with `<PLACEHOLDER>` — OK
- ❌ Passwords, API keys, tokens — **NEVER** in this repo
- Real credentials → private `Secret_Privat` repo only

### 5. 📂 File Placement
| Location | Purpose |
|---|---|
| `222/` | Scripts/configs for NetCup Germany server |
| `109/` | Scripts/configs for FastVDS Russia server |
| `VPN/` | Scripts/configs for AmneziaWG VPN nodes |
| `scripts/` | Shared across ALL servers |

---

## 🚀 Key Script: `set_php_fpm_limits_v2026-04-07.sh`

Solves the problem of **a single WordPress site consuming 90%+ CPU**:

| Parameter | Value | Where |
|---|---|---|
| `pm.max_children` | ≤8 (calc from RAM) | PHP-FPM pool .conf |
| `pm.max_requests` | 500 | PHP-FPM pool .conf |
| `CPUQuota` | 320% (4 cores × 80%) | systemd cgroup |
| `MemoryMax` | ~6.8 GB (85% of 8 GB) | systemd cgroup |
| `OOMScoreAdjust` | 300 | systemd cgroup |

```bash
# Run on 222:
bash /root/Linux_Server_Public/222/set_php_fpm_limits_v2026-04-07.sh
# Run on 109:
bash /root/Linux_Server_Public/109/set_php_fpm_limits_v2026-04-07.sh
```

---

*= Rooted by VladiMIR | AI =*
