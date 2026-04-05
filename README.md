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
├── VPN/                          # AmneziaWG VPN nodes config
├── ansible/                      # Playbooks for Semaphore UI
├── scripts/                      # Shared general utilities
│   └── fastpanel_php_ondemand_v2026-03-25.sh
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
# Updated: 2026-04-01

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
Checks WordPress core version and shows update availability (does not auto-update core).

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
Runs `wp cron event run --due-now` via WP-CLI for each site as the site owner user.

---

### `scan_clamav.sh` — ClamAV Manual Scanner (109)

| Parameter | Value |
|-----------|-------|
| Location | `/root/scan_clamav.sh` |
| Source | `109/scan_clamav.sh` in this repo |
| Version | `v2026-04-05` |

> ⚠️ **Important (2026-04-05):** `clamav-daemon` (clamd) was **disabled** on server 109 to free RAM/swap (~975 MB).  
> ClamAV still works via `clamscan` direct call (no daemon needed).  
> `clamav-freshclam` (database updates) remains **enabled**.  
> Manual scan: `bash /root/scan_clamav.sh`

---

## Quick Aliases (both servers)

All aliases are defined in `/root/.bashrc`:

```bash
# WordPress update — run on current server
alias wpupd='bash /root/wp_update_all.sh'

# Go to private repo and pull latest
alias secret='cd ~/Secret_Privat && git pull && ls -la'
```

---

## WP-Cron Security Setup

WordPress built-in cron (`wp-cron.php`) was **disabled on both servers** for security reasons:  
- It triggers on every page visit (performance hit)
- It can be abused by external HTTP requests (DDoS vector)

**Replacement setup:**
1. Added `define('DISABLE_WP_CRON', true);` to all `wp-config.php` files
2. Removed all `wp-cron.php` lines from crontab
3. System cron calls WP-CLI directly as the site owner user

---

## Style Rules

- Every script starts with `clear`
- Header: `# = Rooted by VladiMIR | AI =`
- Version in filename: `v2026-MM-DD`
- All comments in English
- No sensitive data in this repo
- **Always label which server the code is for** (109 / 222 / VPN 47)
- **Send code as one complete block** — user should paste only once

---

## Basic Usage

```bash
# Pull latest from GitHub
cd ~/Linux_Server_Public && git pull

# Go to private repo
secret

# Run WordPress update manually
wpupd
```

---

Last updated: **2026-04-05**  
Maintained by: **VladiMIR** | gin.vladimir@gmail.com  
GitHub: https://github.com/GinCz/Linux_Server_Public

```
= Rooted by VladiMIR | AI =
v2026-04-05
```
