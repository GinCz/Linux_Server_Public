# 🖥️ Linux Server Public — VladiMIR

> Public configuration files, scripts, and documentation for production servers.  
> **All secrets, passwords, API keys and FULL IP addresses are stored in a separate PRIVATE repository.**

---

## 🤖 HOW TO WORK WITH AI (Mandatory Rules)

> These rules apply to every session. The AI must follow them **without exception**.

### 1. 🔍 AI must ALWAYS read the repository first

Before answering ANY question — the AI must:
1. Read the root `README.md` (this file)
2. Read the relevant server folder `README.md` (e.g. `222/README.md`)
3. Read `CHANGELOG.md` to understand recent changes
4. Only THEN answer, based on actual repo contents — not assumptions

> **If you are not sure what is already set up — check the repo first.**
> **Do NOT ask the server questions that can be answered by reading the repo.**

---

### 2. 📝 EVERYTHING must be recorded in the repository

Every change, no matter how small, must be saved to the repo. This includes:
- New scripts or config files
- Any changes to existing scripts
- New cron jobs or systemd units
- Every problem encountered and how it was solved
- Installation steps for any software
- Backup configurations
- Test results

> **If it was done on a server — it must exist in the repo. No exceptions.**

---

### 3. 💬 Language rules

| Where | Language | Notes |
|---|---|---|
| **AI ↔ VladiMIR (chat)** | 🇷🇺 **Russian only** | Always communicate in Russian in chat |
| **This PUBLIC repo** (`Linux_Server_Public`) | 🇬🇧 **English only** | All `.md` files, all comments inside scripts, all descriptions |
| **Private repo** (`Secret_Privat`) | 🇷🇺 **Russian** | Descriptions, notes and comments in Russian |
| **Crypto bot repo** (`crypto-docker` / private) | 🇷🇺 **Russian** | Descriptions, notes and comments in Russian |

**Summary:**
- Chat with AI → always Russian
- Public GitHub repo → always English (code comments, README, all docs)
- Private / secret repos → Russian

---

### 4. 💻 Code blocks — execution rules

When the AI sends code, it **must always clearly mark** one of these:

```
📋 INFO ONLY — do not run this
```
```
🚀 RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)
```
```
🚀 RUN ON SERVER: xxx.xxx.xxx.109 (109-RU-FastVDS)
```
```
🚀 RUN ON ALL SERVERS
```

- Every executable code block must specify the **exact server IP** where it should run
- If multiple code blocks are needed for the same task → **merge them into one script**
- Every script must start with `clear` to clear the terminal before output
- Do NOT send 10 separate snippets when one combined script will do

---

### 5. 🔐 Security rules for this repo

| ✅ Allowed in PUBLIC repo | ❌ NEVER in PUBLIC repo |
|---|---|
| Template placeholders `<VALUE>` | Real passwords |
| IP format: `xxx.xxx.xxx.222` | Full IP addresses |
| Script logic and structure | API keys / tokens |
| Config templates | SSH private keys |
| Documentation | WireGuard private keys |
| Masked IPs (last octet only visible) | Telegram Bot tokens |

**IP masking format:** only the last octet is shown. Examples:
- `152.53.182.222` → `xxx.xxx.xxx.222`
- `212.109.223.109` → `xxx.xxx.xxx.109`
- `109.234.38.47` → `xxx.xxx.xxx.47`

**Full IPs, passwords and keys → stored ONLY in the private `Secret_Privat` repository.**

---

### 6. ⚙️ Server Configuration Philosophy (CRITICAL)

> **All configuration must be done at the SERVER level — never per-account or per-domain.**

#### The rule:
- PHP settings (`memory_limit`, `max_execution_time`, `opcache`, etc.) → set **globally** in `php.ini` or `www.conf`
- Nginx settings (timeouts, buffers, limits) → set **globally** in `nginx.conf` or `conf.d/`
- MariaDB settings → set **globally** in `my.cnf`
- CrowdSec rules → applied **globally** to all sites automatically
- PHP-FPM pool parameters → use a **global template** applied to all pools equally

#### Why:
- Individual per-site tuning creates inconsistency and technical debt
- If one site needs more resources, the **server** needs upgrading — not that one site's config
- All hosted sites are equal — no site gets special treatment at config level
- Easier maintenance: one change fixes all sites at once

#### What to do when a specific site misbehaves:
If a site shows errors, high CPU, memory issues, or behaves differently from others — **do NOT edit its config files directly**. Instead:

1. **Check if WordPress is up to date** — log into the site's WP Admin and update all plugins, themes, and WordPress core
2. **Check if a CAPTCHA plugin is installed and working** — every WP site must have an active, up-to-date CAPTCHA (e.g. Cloudflare Turnstile, hCaptcha, or similar)
3. **Check for outdated or abandoned plugins** — deactivate anything not updated in 12+ months
4. **If the problem persists** — investigate at the server level (PHP-FPM pool stats, error logs, CrowdSec decisions)

> **The AI must notify VladiMIR** when a specific domain behaves differently from others:  
> _"Domain `example.cz` is generating errors — please log into WP Admin, update all plugins/themes/core, and verify that a CAPTCHA plugin is installed and active."_

---

## 🗂️ Repository Structure

```
LinuxServerPublic/
├── 222/          → Server 222-DE-NetCup   (xxx.xxx.xxx.222)  — NetCup.com, Germany
│                  Ubuntu 24 / FASTPANEL / Cloudflare / CZ+EU sites
│                  4 vCore AMD EPYC-Genoa / 8 GB DDR5 ECC / 256 GB NVMe
│                  Tariff: VPS 1000 G12 (2026) — 8.60 €/mo
│                  📖 Full docs: 222/README.md
│
├── 109/          → Server 109-RU-FastVDS  (xxx.xxx.xxx.109) — FastVDS.ru, Russia
│                  Ubuntu 24 / FASTPANEL / No Cloudflare / RU sites
│                  4 vCore AMD EPYC 7763 / 8 GB RAM / 80 GB NVMe
│                  Tariff: VDS-KVM-NVMe-Otriv-10.0 — 13 €/mo
│                  📖 Full docs: 109/README.md
│
├── VPN/          → VPN infrastructure (AmneziaWG + x-ui/Xray)
│                  8 VPN nodes — see node table below
│                  Automated backup system: Docker (Amnezia) + x-ui archives
│                  📖 Full docs: VPN/README.md
│
├── XRAY/         → x-ui / Xray installer scripts
│                  Safe / Clean / Full-clean installers
│
├── scripts/      → Shared scripts used by ALL servers
│                  shared_aliases.sh — common aliases (save, load, aw, mc...)
│
├── CHANGELOG.md  → Full history of all changes
├── OPERATIONS.md → Operational procedures and runbooks
├── domains.md    → Domain list and DNS configuration
└── README.md     → This file — AI rules, standards, quick reference
```

---

## 🖥️ Server Overview

| Name | IP (masked) | Provider | Location | Panel | Cloudflare | Monthly |
|---|---|---|---|---|---|---|
| 222-DE-NetCup | xxx.xxx.xxx.222 | NetCup.com | Germany | FASTPANEL | ✅ Yes | 8.60 € |
| 109-RU-FastVDS | xxx.xxx.xxx.109 | FastVDS.ru | Russia | FASTPANEL | ❌ No | 13 € |

**Hardware (both servers):** 4 vCore AMD EPYC / 8 GB RAM / 80–256 GB NVMe / Ubuntu 24 LTS

---

## 🌐 VPN Node Infrastructure

Nodes are in migration from **AmneziaWG** (Docker) to **x-ui / Xray** (VLESS + Reality).  
Some nodes still run AmneziaWG in parallel. Both backup systems are active.

| Node Name | IP (masked) | VPN Stack | Extra Services |
|---|---|---|---|
| ALEX_47 | xxx.xxx.xxx.47 | ✅ x-ui / Xray | Samba |
| 4TON_237 | xxx.xxx.xxx.237 | ✅ x-ui / Xray | Samba, Prometheus |
| TATRA_9 | xxx.xxx.xxx.9 | ✅ x-ui / Xray | Samba, Uptime Kuma |
| SHAHIN_227 | xxx.xxx.xxx.227 | 🔄 AmneziaWG (Docker) | Samba |
| STOLB_24 | xxx.xxx.xxx.24 | ✅ x-ui / Xray | Samba, AdGuard Home |
| PILIK_178 | xxx.xxx.xxx.178 | 🔄 AmneziaWG (Docker) | Samba |
| ILYA_176 | xxx.xxx.xxx.176 | 🔄 AmneziaWG (Docker) | Samba |
| SO_38 | xxx.xxx.xxx.38 | ✅ x-ui / Xray | Samba |

> ✅ x-ui / Xray = migrated to VLESS + Reality protocol  
> 🔄 AmneziaWG = still running Docker-based WireGuard obfuscation  
> Full IPs, keys and configs → private `Secret_Privat` repository only.

---

## 🏗️ MOTD + .bashrc Architecture (IMPORTANT — read before editing)

> Understanding this prevents the double MOTD display bug.

### How shell startup works on these servers

When you SSH into a server, Linux runs two separate chains:

```
SSH login
├── 1. LOGIN SHELL chain:  /etc/profile → /etc/profile.d/*.sh
│       └── /etc/profile.d/motd_server.sh  ← MOTD shown here (1st)
│
└── 2. INTERACTIVE BASH:  /root/.bashrc
        └── source /root/Linux_Server_Public/222/.bashrc
                └── source scripts/shared_aliases.sh
```

If `motd_server.sh` has no guard, it fires on **both** chains → MOTD shown **twice**.

### The fix (v2026-04-28)

All `motd_server.sh` files now have a 2-line guard at the top:

```bash
shopt -q login_shell || return 0 2>/dev/null || exit 0
[ -n "$SSH_CONNECTION" ] || return 0 2>/dev/null || exit 0
```

- `shopt -q login_shell` — true only for a login shell (SSH), false for `source .bashrc`
- `$SSH_CONNECTION` — set only for real remote SSH sessions, empty for local/cron

Result: MOTD fires **exactly once** — on SSH login only.

### .bashrc source chain (222)

```
/root/.bashrc
  └── source /root/Linux_Server_Public/222/.bashrc   ← server-specific aliases
          └── source /root/Linux_Server_Public/scripts/shared_aliases.sh  ← shared aliases
```

| File | Purpose | On server | In repo |
|---|---|---|---|
| `/root/.bashrc` | Entry point, loads repo .bashrc | `/root/.bashrc` | `222/.bashrc` |
| `222/.bashrc` | Server-specific aliases + PS1 | sourced by above | `222/.bashrc` |
| `scripts/shared_aliases.sh` | Aliases shared by ALL servers | sourced by 222/.bashrc | `scripts/shared_aliases.sh` |
| `/etc/profile.d/motd_server.sh` | MOTD banner (login only) | auto-run at SSH login | `222/motd_server.sh` |

### Key rule: `alias load` is defined in `222/.bashrc`, NOT in `shared_aliases.sh`

Because `load` must `source /root/Linux_Server_Public/222/.bashrc` — the path is server-specific.  
If `load` were in `shared_aliases.sh`, it would be wrong on every other server.

---

## ✏️ How to Edit MOTD Banner (login screen)

> **MOTD** = the banner you see every time you SSH into the server.

### Where is the file?
| Server | File on server | File in repo |
|---|---|---|
| 222-DE-NetCup | `/etc/profile.d/motd_server.sh` | `222/motd_server.sh` |
| 109-RU-FastVDS | `/etc/profile.d/motd_server.sh` | `109/motd_server.sh` |
| VPN nodes | `/etc/profile.d/motd_server.sh` | `VPN/motd_server.sh` |

### How to add/remove an alias from the MOTD menu:

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
nano /etc/profile.d/motd_server.sh
# Find the block: # Row 1 (SCAN/SERVER/WORDPRESS) or # Row 2 (BOT/GIT/TOOLS)
# Each line format:
# echo -e "  ${G}aliasname${X}(description)   ${G}alias2${X}(desc)"
# Column width: ~26 chars per column (use spaces to align)
# Test immediately:
bash /etc/profile.d/motd_server.sh
# Save to repo:
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

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
nano /root/.bashrc
# Add line: alias myalias='command'
source /root/.bashrc          # apply without re-login
# Also add it to MOTD menu (motd_server.sh) so it shows in the banner!
# Save to repo:
cd /root/Linux_Server_Public
cp /root/.bashrc 222/.bashrc
save
```

---

## 🔄 Standard Update Workflow

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
# Pull latest from repo and install on server:
cd /root/Linux_Server_Public && git pull
cp 222/motd_server.sh /etc/profile.d/motd_server.sh
cp 222/.bashrc /root/.bashrc
source /root/.bashrc
bash /etc/profile.d/motd_server.sh

# After editing files on server — push back to repo:
cd /root/Linux_Server_Public
cp /etc/profile.d/motd_server.sh 222/motd_server.sh
cp /root/.bashrc 222/.bashrc
save
```

---

## 🔐 SSH Key Management

### Generate a new SSH key pair (on your LOCAL machine — do NOT run on server):

📋 **INFO ONLY — run on your LOCAL machine**
```bash
ssh-keygen -t ed25519 -C "yourname@server" -f ~/.ssh/id_ed25519_servername
```

### Add public key to server:

📋 **INFO ONLY — adjust IP before running**
```bash
ssh-copy-id -i ~/.ssh/id_ed25519_servername.pub root@SERVER_IP
# OR manually:
cat ~/.ssh/id_ed25519_servername.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```

### SSH config shortcut (`~/.ssh/config` on local machine):
```
Host 222
    HostName <FULL_IP_FROM_SECRET_REPO>
    User root
    IdentityFile ~/.ssh/id_ed25519_222

Host 109
    HostName <FULL_IP_FROM_SECRET_REPO>
    User root
    IdentityFile ~/.ssh/id_ed25519_109
```
Then simply: `ssh 222` or `ssh 109`

---

## 🔒 CrowdSec — Fix Engine INACTIVE

🚀 **RUN ON SERVER where CrowdSec is broken**
```bash
clear
mkdir -p /etc/crowdsec/hub
cscli hub update
cscli hub upgrade
systemctl restart crowdsec
systemctl status crowdsec --no-pager | head -5
```

---

## 🚨 PHP-FPM Watchdog — Telegram Alert

If you receive a Telegram alert:
```
⚠️ 222-DE-NetCup
PHP-FPM pool kk-med.eu
CPU=103% for 29min → php-fpm restarted automatically
```
This means the **watchdog** (`php_fpm_watchdog.sh`) detected a runaway PHP-FPM pool and restarted it.  
This is **normal auto-recovery** — no manual action needed unless it repeats.

To investigate:

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
watchdog          # check current PHP-FPM state
sos               # check recent nginx/php errors
wphealth          # check WordPress sites health
```

---

## 💾 Backup System

### ALL Servers — Universal Backup (configs + Docker)
- **Script:** `scripts/backup_all_servers_v2026-04-28.sh`
- **Alias:** `f5backup`
- **What:** Backs up ALL 10 servers in one run:
  - Configs: nginx, php, mysql, crowdsec, fail2ban, ufw, cron, systemd, bashrc, ssh keys
  - Docker image archives for: crypto-bot, semaphore (222), amnezia-awg2 (109), amnezia-awg (VPN nodes)
  - x-ui / Xray dirs for: ALEX, 4TON, TATRA, STOLB, SO nodes
- **Schedule:** Wednesday 03:00 + Saturday 03:00 via cron on 222
- **Keeps:** last 10 date-folders per server (~5 weeks)
- **Storage:** `/BACKUP/<SERVER_LABEL>/<YYYY-MM-DD>/`
- **Telegram:** sends summary after completion

### VPN — AmneziaWG Docker Backup
- **Script:** `VPN/vpn_docker_backup.sh`
- **Alias:** `f5vpn`
- **What:** Docker commit + tar.gz of `amnezia-awg` container on each node
- **Nodes backed up:** SHAHIN_227, PILIK_178, ILYA_176 (still on AmneziaWG)
- **Nodes skipped:** ALEX_47, 4TON_237, TATRA_9, STOLB_24, SO_38 (migrated to x-ui)
- **Schedule:** Sunday 03:00 via cron
- **Keeps:** last 5 archives per node
- **Storage:** `/BACKUP/vpn/<NODE>/`

### VPN — x-ui / Xray Backup (all nodes)
- **Script:** `VPN/xray_backup_all_nodes_v2026-04-28.sh`
- **Alias:** `f5xray`
- **What:** Archives `/usr/local/x-ui`, `/etc/x-ui`, `/usr/local/share/xray`, `/root/cert`, `/etc/xray` from each node
- **Nodes backed up:** ALEX_47, 4TON_237, TATRA_9, STOLB_24, SO_38
- **Nodes skipped:** SHAHIN_227, PILIK_178, ILYA_176 (x-ui not installed)
- **Schedule:** Sunday 03:30 via cron (30 min after f5vpn)
- **Keeps:** last 8 archives per node (~2 months history)
- **Storage:** `/BACKUP/vpn/<NODE>/xray/`
- **Archive size:** ~47 MB per node

### Server Backup (222 / 109)
- **Script:** `222/backup_clean.sh` and `109/backup_clean.sh`
- Backs up all WordPress sites, databases, and configs
- Full docs: `222/README.md`

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

### 2. 📍 Version (date-based)
```bash
# Version: v2026-04-12
```

### 3. 📝 Header Block (mandatory for every script)
```bash
#!/bin/bash
# =============================================================
# Script: script_name_vYYYY-MM-DD.sh
# Version: vYYYY-MM-DD
# Server: [server label and masked IP, e.g. 222-DE-NetCup xxx.xxx.xxx.222]
# Description: What this script does (2-4 sentences).
# Usage: bash script_name.sh
# Dependencies: list tools required (e.g. docker, pigz, curl)
# WARNING: [side effects if any — e.g. restarts nginx]
# = Rooted by VladiMIR | AI =
# =============================================================
clear
```

### 4. 🔒 No Secrets — Ever
- ✅ Templates with `<PLACEHOLDER>` — allowed
- ✅ Masked IPs `xxx.xxx.xxx.222` — allowed
- ❌ Passwords, API keys, tokens, private keys — **NEVER** in this repo
- ❌ Full IP addresses — **NEVER** in this repo
- Real credentials and IPs → private `Secret_Privat` repo only

### 5. 📂 File Placement Rules
| Location | Purpose |
|---|---|
| `222/` | Scripts/configs for NetCup Germany server |
| `109/` | Scripts/configs for FastVDS Russia server |
| `VPN/` | Scripts/configs for AmneziaWG / x-ui VPN nodes |
| `XRAY/` | x-ui / Xray installer scripts |
| `scripts/` | Shared across ALL servers |

### 6. 📋 Script Naming Convention
```
NN_servername_description_vYYYY-MM-DD.sh
```
Example: `01_222_clean_vpn_reports_v2026-04-12.sh`

---

## 🚀 Key Scripts Reference

### PHP-FPM Limits (per-site CPU/RAM cap)

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
bash /root/Linux_Server_Public/222/set_php_fpm_limits_v2026-04-07.sh
```

🚀 **RUN ON SERVER: xxx.xxx.xxx.109 (109-RU-FastVDS)**
```bash
clear
bash /root/Linux_Server_Public/109/set_php_fpm_limits_v2026-04-07.sh
```

| Parameter | Value | Effect |
|---|---|---|
| `pm.max_children` | ≤8 (calc from RAM) | Limits concurrent PHP processes |
| `pm.max_requests` | 500 | Prevents memory leaks |
| `CPUQuota` | 320% (4 cores × 80%) | Hard CPU cap via systemd |
| `MemoryMax` | ~6.8 GB (85% of 8 GB) | Hard RAM cap via systemd |
| `OOMScoreAdjust` | 300 | OOM killer priority |

### VPN Backups

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
# AmneziaWG Docker backup (SHAHIN, PILIK, ILYA)
f5vpn

# x-ui / Xray backup (ALEX, 4TON, TATRA, STOLB, SO)
f5xray
```

### AmneziaWG VPN Node Statistics

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
bash /root/Linux_Server_Public/VPN/amnezia_stat.sh
```

---

## 🔗 Quick Links

- 📁 [222/ folder (NetCup DE)](222/README.md)
- 📁 [109/ folder (FastVDS RU)](109/README.md)
- 📁 [VPN/ folder (AmneziaWG + x-ui)](VPN/README.md)
- 📁 [XRAY/ folder (installers)](XRAY/)
- 📁 [scripts/ folder (shared)](scripts/)
- 📋 [CHANGELOG](CHANGELOG.md)
- 📋 [OPERATIONS](OPERATIONS.md)
- 🌐 [Domain List](domains.md)

---

## 🚀 XRAY + x-ui Installers

### 1. Safe Installer (adds to existing services)
```bash
bash <(curl -s https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/XRAY/xray_safe_installer.sh)
```

### 2. Clean Installer (removes old Xray only)
```bash
bash <(curl -s https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/XRAY/xray_clean_installer.sh)
```

### 3. Full Clean Installer (for fresh servers)
```bash
bash <(curl -s https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/XRAY/xray_installer.sh)
```

---

*= Rooted by VladiMIR | AI =*
