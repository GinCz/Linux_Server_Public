# CHANGELOG

## v2026-03-24 — Major Refactor + Telegram Alerts + SSH Banner

### Overview
Full repository restructure, terminal color system, universal SSH banner,
Telegram monitoring alerts with SSH login protection.

---

### 📁 Repository Structure Refactor

- **Renamed** `server_audit.sh` → `sos.sh` on servers **222** and **109**
- **Removed** `disk_monitor.sh` from all server folders (222, 109, VPN, scripts)
- **Reorganized** scripts by server: each server folder (`222/`, `109/`, `VPN/`) is now
  fully self-contained with its own copies of all relevant scripts
- **Moved** `AWS/server_audit.sh` → `VPN/vpn_server_audit.sh`
- **Deleted** entire `AWS/` folder (server decommissioned):
  - `AWS/.bashrc`
  - `AWS/README.md`
  - `AWS/aws_ping.sh`
  - `AWS/infooo.sh`
  - `AWS/quick_status.sh`
  - `AWS/save.sh`
  - `AWS/system_backup.sh`
- **Fixed** server **222** git remote: was pointing to private repo
  `Linux_Server_Privat_X` → corrected to public `Linux_Server_Public`

---

### 🎨 Terminal Color Scheme

Permanent PS1 color system established for all servers.
Colors are saved to both `/root/.bashrc` and `/root/.bash_profile`
and persist after SSH reconnect.

| Server | Color | ANSI Code |
|--------|-------|-----------|
| 222 DE NetCup | 🟡 Yellow | `\033[01;33m` |
| 109 RU FastVDS | 🌸 Light Pink | `\e[38;5;217m` |
| VPN EU | 🚦 Turquoise `#55FFFF` | `\e[38;5;87m` |

---

### 🛠️ New Scripts Added

#### `scripts/set_color.sh` — Universal PS1 Color Picker
- Interactive menu to select terminal color from 5 options
- Choices: Yellow / Light Pink / Turquoise / Bright Green / Orange
- Writes selected color permanently to `/root/.bashrc` and `/root/.bash_profile`
- Works on **any server** without repository access
- One-liner version embedded in file comments for direct copy-paste

```
# One-liner (copy from top of scripts/set_color.sh):
clear;echo -e "\n1) YELLOW  2) LIGHT PINK  3) TURQUOISE  4) GREEN  5) ORANGE\n";
read -p "Choose [1-5]: " C; ... (sets PS1 permanently)
```

#### `scripts/setup_motd.sh` — Universal SSH Banner + Color Picker
- Installs a beautiful SSH login banner (MOTD) on any server
- Auto-detects all bash aliases from `.bashrc`, `.bash_profile`, `shared_aliases.sh`
- Displays at SSH login: hostname, IP, RAM used/total, CPU%, uptime, load, all aliases
- Combined with color picker — one script does everything
- Writes to `/etc/profile.d/motd_banner.sh` (runs on every SSH login)
- Disables default Ubuntu MOTD (`chmod -x /etc/update-motd.d/*`)
- **Universal setup command (any server):**

```bash
clear
[ -d /root/Linux_Server_Public ] && cd /root/Linux_Server_Public && git pull \
  || cd /root && git clone https://github.com/GinCz/Linux_Server_Public.git \
  && cd /root/Linux_Server_Public
bash scripts/setup_motd.sh
```

#### `scripts/telegram_alert.sh` — Server Monitoring Alerts
- Monitors: **CPU** (>80%), **RAM** (>85%), **Disk** (>80%), **Nginx**, **PHP-FPM**
- Sends formatted HTML alerts to Telegram bot `@My_WWW_bot`
- Designed to run every 5 minutes via cron
- Works on all servers: 222, 109, VPN

#### `scripts/setup_telegram_alerts.sh` — One-Command Alert Installer
- Tests Telegram bot connection before installing
- Installs cron job: `*/5 * * * *` for continuous monitoring
- Installs SSH login alert in `/etc/profile.d/motd_banner.sh`
- **SSH alert fires ONLY for unknown IPs** — trusted IPs are whitelisted:

| IP | Location |
|----|----------|
| `185.100.197.16` | Home |
| `90.181.133.10` | Work |
| `185.14.233.235` | Home alt |
| `185.14.232.0` | Home alt |

---

### 📄 Files Updated

#### `222/.bashrc`
- PS1 color: clean yellow `\033[01;33m` (no blue path)
- All aliases updated to new script paths (`sos.sh` instead of `server_audit.sh`)
- Added: `sos15`, `sos3`, `sos6`, `sos24`, `sos120` shortcuts
- Source path updated to `scripts/shared_aliases.sh`

#### `109/.bashrc`
- PS1 color: light pink `\e[38;5;217m`
- All aliases updated to new paths under `/root/Linux_Server_Public/109/`
- Preserved: `c303()` clipboard function, `_303_start_log()` session logger
- Source path updated to `scripts/shared_aliases.sh`

#### `VPN/.bashrc` _(new file)_
- PS1 color: turquoise `#55FFFF` = `\e[38;5;87m`
- VPN-specific aliases: `vpnstat`, `vpnaudit`, `sos`, `sos15`, `sos3`, `sos24`
- Repository cloned to VPN server during this session

#### `README.md`
- Full rewrite: added all scripts with full paths, run commands, descriptions
- Added color scheme table
- Added repository structure diagram
- Removed AWS references
- Added scripts/ universal base scripts section

---

### ✅ Deployment Status (end of session)

| Server | IP | Repo | PS1 Color | SSH Banner | Telegram Alerts |
|--------|----|------|-----------|------------|------------------|
| 222 DE NetCup | xxx.xxx.xxx.222 | ✅ pulled | 🟡 Yellow | ✅ installed | ✅ active |
| 109 RU FastVDS | xxx.xxx.xxx.109 | ✅ pulled | 🌸 Pink | ✅ installed | ✅ active |
| VPN EU Alex-47 | xxx.xxx.xxx.47 | ✅ cloned | 🚦 Turquoise | ✅ installed | ✅ active |

---

### 📦 Commit History (v2026-03-24)

```
508dee2  Add: setup_telegram_alerts.sh — install cron + SSH alert
000d3a6  Add: Telegram alerts script
9088380  Remove: AWS folder fully removed
d28ea51  Fix: set_color.sh working one-liner version
e5e70b5  Add: universal SSH banner + color picker setup script
d58d20f  Fix: VPN PS1 turquoise #55FFFF (38;5;87m)
4ddb183  Add: universal PS1 color picker script
76c3918  Add: VPN .bashrc green PS1 + aliases
cea68dd  Fix: 109 PS1 light pink 217 + update aliases
4f1e818  Fix: 222 PS1 yellow only + update aliases
7a04588  Docs: full README with all scripts paths + descriptions
6253cbf  Refactor: rename server_audit->sos, remove disk_monitor, reorganize scripts
d677a23  Refactor: distribute scripts by server + fix 222/109 PS1 colors
```

---

_Last updated: 2026-03-24 by VladiMIR Bulantsev_
