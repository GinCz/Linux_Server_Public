# CHANGELOG

## v2026-03-25 — RAM Crisis Fix + PHP-FPM ondemand optimization

### Overview
Server 222-DE-NetCup was critically low on RAM (6.8GB used of 7.7GB, Swap 3.0GB).
Root cause: 45 PHP-FPM pools all running in `dynamic` mode simultaneously.
Fixed by switching 40 idle pools to `ondemand` mode.
Result: RAM dropped from 6.8GB → 2.6GB used, PHP processes 89 → 14.

---

### 🔴 Critical Issues Found & Fixed (222)

#### wowflow.cz — PHP Fatal Error: memory exhausted
- **Problem:** `Allowed memory size of 134217728 bytes (128MB) exhausted`
  in `woocommerce/includes/emails/class-wc-email-customer-pos-completed-order.php`
- **Fix:** Added `php_admin_value[memory_limit] = 256M` to pool config
- **File:** `/etc/php/8.3/fpm/pool.d/wowflow.cz.conf`
- **Command:** `echo "php_admin_value[memory_limit] = 256M" >> /etc/php/8.3/fpm/pool.d/wowflow.cz.conf`

#### High RAM usage — 45 PHP-FPM pools all dynamic
- **Problem:** FASTPANEL runs each site in its own PHP-FPM pool
  Server had 45 pools × 2 processes × ~100MB = ~9GB (exceeds total RAM)
- **Root cause discovered:** FASTPANEL stores pool configs in `/opt/php84/etc/php-fpm.d/`
  (NOT in `/etc/php/8.3/fpm/pool.d/` as expected)
- **FASTPANEL service name:** `fp2-php84-fpm` (not `fpm84`)
- **Fix:** Script `fastpanel_php_ondemand_v2026-03-25.sh` — switches 40 idle pools to `ondemand`

---

### 📊 RAM Results (222-DE-NetCup)

| Metric | Before | After |
|--------|--------|-------|
| RAM used | 6.8 GB | 2.6 GB |
| RAM available | 933 MB | 5.2 GB |
| Swap used | 3.0 GB | 1.9 GB |
| PHP-FPM processes | 89 | 14 |

---

### 🛠️ New Scripts Added

#### `scripts/fastpanel_php_ondemand_v2026-03-25.sh`
- Switches idle PHP-FPM pools from `dynamic` to `ondemand`
- Searches all FASTPANEL pool directories:
  - `/etc/php/8.3/fpm/pool.d`
  - `/opt/php84/etc/php-fpm.d` ← main FASTPANEL location
  - `/opt/fphp/etc/php-fpm.d`
  - `/opt/php74/etc/php-fpm.d`
  - `/opt/php56/etc/php-fpm.d`
- Keeps `dynamic` for high-traffic sites: `svetaform.eu`, `wowflow.cz`, `gadanie-tel.eu`, `czechtoday.eu`, `bio-zahrada.eu`
- Sets `pm.process_idle_timeout = 10s` for ondemand pools
- Auto-reloads correct FASTPANEL service: `fp2-php84-fpm`
- **Run after server reboot** (added to cron `@reboot`)

```bash
bash /root/Linux_Server_Public/scripts/fastpanel_php_ondemand_v2026-03-25.sh
```

---

### 📁 New Files: `222/php-fpm-pools-backup/`

Snapshot of all 44 PHP-FPM pool configs after optimization (2026-03-25).
Useful for reference if FASTPANEL resets pool settings.
Pools saved: all sites from abl-metal.com to www.conf

---

### 🛡️ Security Events (222, 2026-03-25)

- **52 active CrowdSec bans** at time of report
- Main threats: Microsoft Azure IPs (20.63.x, 20.151.x) scanning WordPress
  - Rules triggered: `http-wordpress-scan`, `http-admin-interface-probing`, `http-crawl-non_statics`
- SSH brute-force from RO/Unmanaged Ltd: `2.57.121.x`, `2.57.122.x` — banned
- **2841 wp-login.php** attack attempts in 24h on svetaform.eu
- Top traffic: svetaform.eu (288K req/day), czechtoday.eu (18K req/day)

---

### 📋 Cron Added (222)

```bash
@reboot sleep 60 && bash /root/Linux_Server_Public/scripts/fastpanel_php_ondemand_v2026-03-25.sh >> /var/log/php_ondemand.log 2>&1
```
Ensures ondemand mode survives server reboots.

---

### 🔧 Server 109 — Git SSH Fixed

- **Problem:** 109 had HTTPS remote → auth failed with password
- **Fix:** Switched to SSH remote
  ```bash
  git remote set-url origin git@github.com:GinCz/Linux_Server_Public.git
  ```
- SSH key regenerated: `SHA256:MKND5rIVEcpF+SsbueAIUsdbklNHtVSt0tu2VgVRsjM`
- Git push now works via SSH ✅
- **Found:** 109 also has 17 PHP84 pools — candidate for same ondemand optimization

---

### ✅ Deployment Status (end of session 2026-03-25)

| Server | RAM Before | RAM After | Git Push | Cron @reboot |
|--------|-----------|-----------|----------|---------------|
| 222 DE NetCup | 6.8 GB | 2.6 GB | ✅ | ✅ |
| 109 RU FastVDS | — | — | ✅ SSH fixed | — |

---

### 📦 Commit History (v2026-03-25)

```
ae3ae3e  109: sync bashrc + check PHP pools v2026-03-25
c94fc9f  222: PHP-FPM ondemand optimization + wowflow 256M fix v2026-03-25
81868ad  Fix service names: fp2-php84-fpm for FASTPANEL PHP 8.4 v2026-03-25
6cb006a  Fix pool dirs: add /opt/php84 and /opt/fphp FASTPANEL paths v2026-03-25
cd27114  Add FASTPANEL PHP-FPM ondemand optimizer v2026-03-25
```

---

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

#### `scripts/setup_motd.sh` — Universal SSH Banner + Color Picker
- Installs a beautiful SSH login banner (MOTD) on any server
- Auto-detects all bash aliases from `.bashrc`, `.bash_profile`, `shared_aliases.sh`
- Displays at SSH login: hostname, IP, RAM used/total, CPU%, uptime, load, all aliases
- Writes to `/etc/profile.d/motd_banner.sh`
- **Universal setup command:**
```bash
clear
[ -d /root/Linux_Server_Public ] && cd /root/Linux_Server_Public && git pull \
  || cd /root && git clone https://github.com/GinCz/Linux_Server_Public.git \
  && cd /root/Linux_Server_Public
bash scripts/setup_motd.sh
```

#### `scripts/telegram_alert.sh` — Server Monitoring Alerts
- Monitors: CPU (>80%), RAM (>85%), Disk (>80%), Nginx, PHP-FPM
- Sends formatted HTML alerts to Telegram bot `@My_WWW_bot`
- Runs every 5 minutes via cron

#### `scripts/setup_telegram_alerts.sh` — One-Command Alert Installer
- Tests Telegram bot connection before installing
- Installs cron job: `*/5 * * * *`
- SSH alert fires ONLY for unknown IPs (trusted IPs whitelisted)

---

### ✅ Deployment Status (end of session 2026-03-24)

| Server | IP | Repo | PS1 Color | SSH Banner | Telegram Alerts |
|--------|----|------|-----------|------------|------------------|
| 222 DE NetCup | xxx.xxx.xxx.222 | ✅ | 🟡 Yellow | ✅ | ✅ |
| 109 RU FastVDS | xxx.xxx.xxx.109 | ✅ | 🌸 Pink | ✅ | ✅ |
| VPN EU Alex-47 | xxx.xxx.xxx.47 | ✅ | 🚦 Turquoise | ✅ | ✅ |

---

_Last updated: 2026-03-25 by VladiMIR Bulantsev_
