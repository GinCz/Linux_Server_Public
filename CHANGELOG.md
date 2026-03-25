# CHANGELOG

## v2026-03-25/26 — Crypto-Bot Docker Migration + Alias Fixes (222-DE-NetCup)

### 🎯 Overview
Full migration of crypto-bot from bare-metal (`/root/aws-setup/`) to Docker (`/root/crypto-docker/`).
New server 222-DE-NetCup (IP: xxx.xxx.xxx.222, NetCup Germany) replacing old AWS setup.
All scripts, aliases, and paths updated. Binance removed from UI. Exchange switching bug found.

---

### 🔄 Migration: aws-setup → crypto-docker

**Old paths (broken, removed):**
- `/root/aws-setup/scripts/` — old bare-metal location
- `/home/ubuntu/aws-setup/` — old Ubuntu user location
- `systemd` services `crypto-bot` / `crypto-bot-web` — replaced by Docker

**New paths (current):**
- `/root/crypto-docker/` — root of Docker project
- `/root/crypto-docker/scripts/` — all Python/bash scripts
- `/root/crypto-docker/templates/` — Flask HTML templates
- `/root/crypto-docker/config.json` — main config (mounted into container)
- `/root/crypto-docker/logs/` — logs (mounted into container)
- Inside container: `/app/scripts/` — same scripts via Docker volume

**Docker setup:**
```yaml
# docker-compose.yml
container_name: crypto-bot
ports: 127.0.0.1:5000:5000
volumes:
  - ./config.json:/app/config.json
  - ./stats.json:/app/stats.json
  - ./logs:/app/logs
mem_limit: 2g
cpus: 1.0
```

---

### ⚠️ Critical Bug: alias `tr` → renamed to `bot`

- **Problem:** `tr` is a standard Linux system utility (`translate characters`)
  Bash always runs `/usr/bin/tr` instead of the alias — alias has no effect
- **Symptom:** `tr: missing operand` on every call
- **Fix:** Alias renamed from `tr` to `bot`
- **Command:** `alias bot='bash /root/crypto-docker/scripts/tr_docker.sh'`
- **Documented** in `.bashrc` with explanation comment

---

### ⚠️ Critical Bug: `[ -z "$PS1" ] && return` blocked all aliases

- **Problem:** Line 7 of `.bashrc` caused early exit in non-interactive sessions
  After `source ~/.bashrc` in scripts or after `reset` — all aliases below line 7 were ignored
- **Symptom:** `torg: command not found`, `deploy: command not found` after source
- **Fix:** Line commented out:
  ```bash
  # [ -z "$PS1" ] && return  # commented out — was blocking aliases in new sessions
  ```

---

### 🛠️ Scripts Fixed (old paths → Docker)

#### `scripts/torg.sh` (v2026-03-25)
- **Was:** `cd /home/ubuntu/aws-setup && python3 scripts/trades_report.py`
- **Now:** `docker exec crypto-bot python3 /app/scripts/trades_report.py --hours $HOURS --mode paper`
- Supports symlink-based hour detection: `torg1` / `torg3` / `torg24` / `torg120`
- Default hours = 1 (via alias `torg`)

#### `scripts/tr.sh` (v2026-03-25)
- **Was:** `cd /root/aws-setup && inline python3 code`
- **Now:** `docker exec crypto-bot python3 /app/scripts/tr_report.py`

#### `scripts/tr_docker.sh` (existing, correct)
- Already correct: `docker exec crypto-bot python3 /app/scripts/tr_report.py`
- This is the main `bot` alias target

#### `scripts/reset.sh` (v2026-03-25)
- **Was:** Used `/root/aws-setup/` paths, `pkill paper_trade.py`, `nohup python3`
- **Now:** Uses `docker-compose down/up`, cleans files in `/root/crypto-docker/scripts/`
- **Note:** Server uses old Docker syntax `docker-compose` (not `docker compose`)
- Fixed with: `sed -i 's/docker compose/docker-compose/g' reset.sh`

#### `scripts/deploy.sh` (v2026-03-25)
- **Was:** Systemd-based, Ubuntu user paths, AWS domain
- **Now:** Docker-based, root paths, domain `crypto.gincz.com`, IP `xxx.xxx.xxx.222`
- ⚠️ **NO ALIAS** — dangerous script, only for fresh install!
  Run manually: `bash /root/crypto-docker/scripts/deploy.sh`

---

### 🔧 UI Fix: Binance button removed from web interface

**File:** `/root/crypto-docker/templates/index.html`

- **Removed** line 197: `<button onclick="setExchange('binance')"...>Binance</button>`
- **Fixed** JS array line 476: `['okx','mexc','binance']` → `['okx','mexc']`
- **Reason:** Binance not supported in current bot config, no API keys
- **Commands used:**
  ```bash
  sed -i '197d' /root/crypto-docker/templates/index.html
  sed -i "s/\['okx','mexc','binance'\]/['okx','mexc']/g" /root/crypto-docker/templates/index.html
  ```

---

### 🔍 Bug Found (NOT fixed yet): Exchange switching broken

**File:** `/root/crypto-docker/scripts/scanner.py` line 29

```python
# BUG: variable named 'mexc' but hardcoded to OKX!
mexc = ccxt.okx({   # ← always OKX, ignores config.json['exchange']
    'apiKey': _cfg_s.get('okx_api_key', ''),
    ...
})
```

- `app.py` correctly writes selected exchange to `config.json` via `/api/set_exchange`
- But `scanner.py` always uses hardcoded OKX regardless of `config.json['exchange']`
- `run_scan()` reads config for filters but NOT for exchange selection
- **Fix needed:** Make scanner dynamically init exchange based on `config.json['exchange']`
- **Current state:** Exchange buttons OKX/MEXC in UI do nothing — always scans OKX

---

### 📦 New/Updated Aliases (222/.bashrc)

| Alias | Command | Notes |
|-------|---------|-------|
| `bot` | `bash .../tr_docker.sh` | Quick report (replaces broken `tr`) |
| `reset` | `bash .../reset.sh` | Full bot reset + restart via Docker |
| `torg` | `bash .../torg.sh 1` | Trades report 1h (default) |
| `torg1` | `bash .../torg.sh 1` | Trades report 1h |
| `torg3` | `bash .../torg.sh 3` | Trades report 3h |
| `torg24` | `bash .../torg.sh 24` | Trades report 24h |
| `torg120` | `bash .../torg.sh 120` | Trades report 5 days |
| `clog` | `docker logs crypto-bot --tail 40` | Container logs 40 lines |
| `clog100` | `docker logs crypto-bot --tail 100` | Container logs 100 lines |
| ~~`deploy`~~ | ~~alias removed~~ | Dangerous! Run manually only |

---

### 📊 Bot Status at End of Session

- Container: `crypto-bot` running, Up ~1h, port `127.0.0.1:5000`
- Mode: **PAPER** (virtual $1000, OKX prices)
- Cycles: ~700+ completed
- Trades: 1 closed (PROVEUSDT, loss, PEAK-DROP reason, 0.1 min)
- Issue: `list_05 пуст — нет кандидатов` on every cycle — filters too strict for current market
- `tr_report.py` file updated (3.58kB copied into container via SCP)

---

### 📝 Files Changed in Repo (this session)

```
222/.bashrc          — added all crypto-bot aliases, fixed PS1 return bug
222/server-info.md   — added full Crypto-Bot Docker section
222/reset.sh         — rewritten for Docker (new file in repo)
222/deploy.sh        — rewritten for Docker (new file in repo)
```

---

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

_Last updated: 2026-03-26 00:12 by VladiMIR Bulantsev_
