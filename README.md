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

### 3. 📋 Documentation language and quality

- **All documentation in this PUBLIC repository must be in English only**
- Every script must have a full header comment block (see Coding Standards below)
- Every `.md` file must be detailed — not just a filename list
- Every problem and its solution must be documented

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

## 🗂️ Repository Structure

```
Linux_Server_Public/
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
├── VPN/          → AmneziaWG VPN infrastructure
│                  Multiple VPN nodes — see VPN node list below
│                  Automated Docker backup system with AWS S3
│                  📖 Full docs: VPN/README.md
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

## 🌐 VPN Node Infrastructure (AmneziaWG)

All nodes run **AmneziaWG** (WireGuard obfuscation) + **Samba** file sharing.

| Node Name | IP (masked) | Extra Services |
|---|---|---|
| ALEX_47 | xxx.xxx.xxx.47 | AmneziaWG + Samba |
| 4TON_237 | xxx.xxx.xxx.237 | AmneziaWG + Samba + Prometheus |
| TATRA_9 | xxx.xxx.xxx.9 | AmneziaWG + Samba + Kuma Monitoring |
| SHAHIN_227 | xxx.xxx.xxx.227 | AmneziaWG + Samba |
| STOLB_24 | xxx.xxx.xxx.24 | AmneziaWG + Samba + AdGuard Home |
| PILIK_178 | xxx.xxx.xxx.178 | AmneziaWG + Samba |
| ILYA_176 | xxx.xxx.xxx.176 | AmneziaWG + Samba |
| SO_38 | xxx.xxx.xxx.38 | AmneziaWG + Samba |

> Full IP addresses, WireGuard keys and configs are stored in the **private `Secret_Privat` repository**.

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

### VPN Docker Backup (automated)
- Script: `VPN/vpn_docker_backup.sh`
- Uploads encrypted archives to **AWS S3**
- Runs daily at **03:30** via cron
- Keeps last **7 backups** (KEEP=7)
- Full docs: `VPN/BACKUP.md`

### Server Backup (222 / 109)
- Script: `222/backup_clean.sh` and `109/backup_clean.sh`
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
| `VPN/` | Scripts/configs for AmneziaWG VPN nodes |
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

### VPN Docker Backup

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
bash /root/Linux_Server_Public/VPN/vpn_docker_backup.sh
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
- 📁 [VPN/ folder (AmneziaWG)](VPN/README.md)
- 📁 [scripts/ folder (shared)](scripts/)
- 📋 [CHANGELOG](CHANGELOG.md)
- 📋 [OPERATIONS](OPERATIONS.md)
- 🌐 [Domain List](domains.md)

---

*= Rooted by VladiMIR | AI =*
