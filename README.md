# Linux_Server_Public

**Main public repository** for all my server scripts, Ansible playbooks, aliases, VPN tools and documentation.

Contains **only non-sensitive code**.  
All passwords, SSH keys, API secrets and full server details are stored in the strictly private repo:  
https://github.com/GinCz/Secret_Privat (never make it public)

---

## 📋 Rules — MUST READ BEFORE ANYTHING

> These rules apply to all scripts, all code, all interactions. No exceptions.

### 1. Always check the repository first
Before answering any question about the state of the servers — **read the repository**. The README, `server-info.md`, and `CHANGELOG.md` are the source of truth. Never guess the current configuration.

### 2. Record every change, no matter how small
Every change made to any server — even a one-liner — **must be recorded** in:
- `CHANGELOG.md` — with date, server, description
- `109/server-info.md` or `222/server-info.md` — current state of that server
- `README.md` — if it affects global structure, services, or rules

This is the only way to know the exact state of all servers at any time.

### 3. Every script must follow the code style
- **First line:** `clear` — to clean the terminal before output
- **Header:** `# = Rooted by VladiMIR | AI =`
- **Version:** today's date in format `v2026-MM-DD` (in filename and/or header)
- **All comments in English**
- **No sensitive data** (passwords, keys, tokens) in this repo

### 4. Always label which server code is for
When sending any command or script, **always specify the target server** clearly:
- 🖥️ **Server 109** — `109-RU-FastVDS` | IP: `212.109.223.109` | Russian sites, no Cloudflare
- 🖥️ **Server 222** — `222-DE-NetCup` | IP: `152.53.182.222` | EU/CZ sites, with Cloudflare
- 🔒 **VPN 47** — AmneziaWG VPN node

### 5. Send code as one complete block
Always send code as **one large block** — not multiple small pieces. The user should need to copy and paste only once.

### 6. ⚠️ NEVER restart nginx or php-fpm — always RELOAD

> **Full details: [`OPERATIONS.md`](OPERATIONS.md)**

This server hosts **28+ sites simultaneously**. A `restart` kills all sockets and causes
1–3 seconds of 502 downtime across ALL sites at once. This is never acceptable.

```bash
# ✅ CORRECT — zero downtime, always use these:
php-fpm8.3 -t && systemctl reload php8.3-fpm
nginx -t    && systemctl reload nginx

# ❌ FORBIDDEN during working hours:
systemctl restart php8.3-fpm   # kills ALL sockets → 502 on ALL sites
systemctl restart nginx         # drops ALL connections
```

`restart` is only acceptable after a **package update** (`apt upgrade nginx` / `apt upgrade php8.3-fpm`)
or if the process is completely frozen and does not respond to `reload`.

---

## Servers Overview

| # | Hostname | IP | Provider | OS | Panel | Cloudflare |
|---|----------|----|----------|----|-------|------------|
| 109 | `109-ru-vds` | `212.109.223.109` | FastVDS.ru (RU) | Ubuntu 24 LTS | FASTPANEL | ❌ No |
| 222 | `222-DE-NetCup` | `152.53.182.222` | NetCup.com (DE) | Ubuntu 24 LTS | FASTPANEL | ✅ Yes |

- **109** — Russian sites, no Cloudflare, 4 vCore AMD EPYC 7763 / 8GB RAM / 80GB NVMe / 13€/mo (FastVDS.ru)
- **222** — European/CZ sites, with Cloudflare, 4 vCore AMD EPYC-Genoa / 8GB DDR5 / 256GB NVMe / 8.60€/mo (NetCup.com)

---

## Repository Structure

```
Linux_Server_Public/
├── 109/                          # Scripts & configs specific to 109-RU-FastVDS
│   ├── server-info.md            # Full current state of server 109
│   ├── wp_update_all.sh          # WordPress plugins + themes updater
│   ├── run_all_wp_cron.sh        # System WP-Cron runner (replaces wp-cron.php)
│   ├── scan_clamav.sh            # ClamAV manual scan script
│   ├── acquis.yaml               # CrowdSec log sources config
│   ├── acquis.d/                 # CrowdSec acquis.d configs
│   ├── nginx.conf                # nginx config with dual log format
│   └── ...                       # Other scripts
├── 222/                          # Scripts specific to 222-DE-NetCup
│   ├── server-info.md            # Full current state of server 222
│   ├── fix_nginx_crowdsec_222_v2026-04-05.sh  # CrowdSec nginx log fix script
│   ├── acquis.yaml               # CrowdSec log sources config
│   ├── nginx.conf                # nginx config with dual log format
│   ├── docker-compose.yml        # Docker crypto bot
│   ├── docker_backup.sh          # Docker container backup
│   └── ...                       # Other scripts
├── VPN/                          # AmneziaWG VPN nodes config
├── ansible/                      # Playbooks for Semaphore UI
├── scripts/                      # Shared general utilities
│   └── fastpanel_php_ondemand_v2026-03-25.sh
├── OPERATIONS.md                 # ⚠️ Zero-downtime rules: reload vs restart
├── CHANGELOG.md                  # Full version/change history
├── domains.md                    # All domains list with servers
└── README.md                     # This file
```

---

## Crontab — Server 109 (109-RU-FastVDS)

```cron
# === 109-RU-FastVDS | 212.109.223.109 ===
# Updated: 2026-04-05

# Daily backup cleanup at 01:00
0 1 * * * /root/backup_clean.sh >> /var/log/system-backup.log 2>&1

# Weekly disk cleanup every Sunday at 03:00
0 3 * * 0 /opt/server_tools/scripts/disk_cleanup.sh

# WordPress updates: Wednesday + Saturday at 02:00
0 2 * * 3,6  bash /root/wp_update_all.sh >> /var/log/wp_update.log 2>&1

# WordPress system cron every 15 min (replaces wp-cron.php)
*/15 * * * *  bash /root/run_all_wp_cron.sh >> /var/log/wp_cron.log 2>&1

# Auto system upgrade every Sunday at 03:30
30 3 * * 0 /usr/local/bin/auto_upgrade.sh
```

---

## Crontab — Server 222 (222-DE-NetCup)

```cron
# === 222-DE-NetCup | 152.53.182.222 ===
# Updated: 2026-04-07

# PHP-FPM watchdog every 15 min
*/15 * * * * bash /opt/server_tools/scripts/php_fpm_watchdog.sh

# FastPanel PHP on-demand mode — run on every reboot
@reboot sleep 60 && bash /root/Linux_Server_Public/scripts/fastpanel_php_ondemand_v2026-03-25.sh >> /var/log/php_ondemand.log 2>&1

# Daily backup cleanup at 02:00
0 2 * * * /root/backup_clean.sh >> /var/log/system-backup.log 2>&1

# Daily Docker backup at 03:00
0 3 * * * /root/docker_backup.sh >> /var/log/docker-backup.log 2>&1

# WordPress updates: Wednesday + Saturday at 02:00
0 2 * * 3,6  bash /root/wp_update_all.sh >> /var/log/wp_update.log 2>&1
```

> **Note:** `wp-cron.php` via curl/php is **disabled** on both servers.  
> `DISABLE_WP_CRON=true` is set in all `wp-config.php` files.  
> WordPress cron is handled by system cron via WP-CLI (`run_all_wp_cron.sh`).

---

## Scripts

### `wp_update_all.sh` — WordPress Updater

| Parameter | Value |
|-----------|-------|
| Location | `/root/wp_update_all.sh` (both servers) |
| Source | `109/wp_update_all.sh` in this repo |
| Version | `v2026-04-01` |
| Schedule | Wednesday + Saturday at 02:00 |
| Alias | `wpupd` |
| Log | `/var/log/wp_update.log` |

Updates plugins and themes for **all WordPress sites** on FastPanel.  
Runs WP-CLI as the correct site owner (not root) to avoid file permission issues.

**Manual run:**
```bash
wpupd
# or
bash /root/wp_update_all.sh
```

---

### `run_all_wp_cron.sh` — WP-Cron Runner (109 only)

| Parameter | Value |
|-----------|-------|
| Location | `/root/run_all_wp_cron.sh` |
| Schedule | Every 15 minutes |
| Log | `/var/log/wp_cron.log` |

Replaces the built-in WordPress `wp-cron.php` web trigger.

---

### `scan_clamav.sh` — ClamAV Manual Scanner (109)

> ⚠️ **Important (2026-04-05):** `clamav-daemon` (clamd) was **disabled** on server 109 to free RAM/swap (~975 MB).  
> Manual scan: `bash /root/scan_clamav.sh`

---

### `fix_nginx_crowdsec_222_v2026-04-05.sh` — CrowdSec nginx fix (222)

Fixed CrowdSec log format mismatch on server 222. Added dual nginx logging.  
Applied: 2026-04-05 ~14:47 CEST. Result: CrowdSec started banning immediately.

---

## WordPress Site Fixes Log — Server 109

| Date | Site | Problem | Root Cause | Fix |
|------|------|---------|------------|-----|
| 2026-04-07 | nail-space-ekb.ru | 403 on /wp-admin/ | `wp-admin` in global nginx regex (higher priority) | Removed `wp-admin` from `meta_crawler_block.conf` |
| 2026-04-07 | novorr-art.ru | WP updates blocked | `DISALLOW_FILE_MODS=true` in wp-config.php | Commented out both DISALLOW constants |
| 2026-04-07 | ugfp.ru | 502 Bad Gateway | PHP-FPM pool config file missing entirely | Created `ugfp.ru.conf`, reloaded php-fpm |

---

## Quick Aliases (both servers)

```bash
alias wpupd='bash /root/wp_update_all.sh'
alias secret='cd ~/Secret_Privat && git pull && ls -la'
```

---

## WP-Cron Security Setup

`DISABLE_WP_CRON=true` is set in all `wp-config.php` files on both servers.  
System cron calls WP-CLI every 15 min as the site owner user.

> ⚠️ **Exception:** `timan-kuchyne.cz` on server 222 still missing — see `222/server-info.md`

---

## ⚠️ Known Issues (Open)

| Server | Site | Issue | Status |
|--------|------|-------|--------|
| 222 | timan-kuchyne.cz | Missing `DISABLE_WP_CRON=true` in wp-config.php | ⚠️ Not fixed |
| 222 | svetaform.eu | Abnormally high traffic (315K req/hr) — root cause unknown | ⚠️ Not investigated |
| 109 | novorr-art.ru | WP core 6.9.4 available — update not yet performed | 🕐 Pending |

---

## Style Rules

- Every script starts with `clear`
- Header: `# = Rooted by VladiMIR | AI =`
- Version in filename: `v2026-MM-DD`
- All comments in English
- No sensitive data in this repo
- **Always label which server the code is for** (109 / 222 / VPN 47)
- **Send code as one complete block**
- **Always `reload`, never `restart`** — see `OPERATIONS.md`

---

## Basic Usage

```bash
cd ~/Linux_Server_Public && git pull
wpupd
secret
```

---

Last updated: **2026-04-07 18:00 CEST**  
Maintained by: **VladiMIR** | gin.vladimir@gmail.com  
GitHub: https://github.com/GinCz/Linux_Server_Public

```
= Rooted by VladiMIR | AI =
v2026-04-07
```
