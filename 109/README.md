# 🖥️ Server 109 — RU-FastVDS (212.109.223.109)

> **Hosting:** FastVDS.ru | **Location:** Russia  
> **Tariff:** VDS-KVM-NVMe-Otriv-10.0  
> **Hardware:** 4 vCore AMD EPYC 7763 | 8 GB RAM | 80 GB NVMe  
> **OS:** Ubuntu 24 LTS + FASTPANEL  
> **Role:** Russian-market web server — WordPress sites, CrowdSec IDS, PHP-FPM watchdog, ClamAV  
> **Cost:** 13 EUR/month

---

## 📋 Server Overview

This is the **Russian production server** for Russian-language websites.
Sites run **without Cloudflare** (direct IP access — all security is server-side).
The server has its own **CrowdSec IDS/IPS**, **PHP-FPM watchdog daemon**,
and **ClamAV antivirus** with databases synced weekly from the donor server `152.53.182.222`.

---

## 📁 Directory Structure

```
109/
├── Scripts (*.sh)          — Automation, maintenance, backup, security, monitoring
├── Nginx configs (*.conf)  — WordPress rate limiting, bot protection
├── PHP config              — PHP-FPM pool settings, php.ini overrides
├── CrowdSec configs        — IDS/IPS: acquis.yaml, scenarios, parsers
├── Dockers/                — Docker Compose definitions
├── systemd/                — Custom systemd service unit files
├── Documentation (*.md)    — READMEs, HOWTOs, notes
└── .bashrc / .bash_profile — Shell environment, aliases
```

---

## 🔧 Scripts Reference

### 🛡️ Security & ClamAV

| Script | Version | Description | Cron / Daemon |
|---|---|---|---|
| `scan_clamav.sh` | — | Full ClamAV scan of `/var/www`. Logs to `/var/log/clamav_scan.log`. Sends Telegram alert if threats found. | **Cron: Sunday 02:00** |
| `banlog.sh` | — | Shows CrowdSec ban log: IPs, country, reason, ban expiry time | Manual |
| `block_bots.sh` | — | Blocks known malicious bots via nginx `deny` rules | Manual |

**ClamAV status on this server:**
- ✅ **INSTALLED** — `/usr/bin/clamscan` present
- ✅ **DB files present:** `main.cvd`, `daily.cvd`, `bytecode.cvd`
- ⚙️ **freshclam:** masked (DB synced from donor `152.53.182.222`)
- 📅 **Last DB sync:** 2026-05-30
- ⏰ **Scan schedule:** Every Sunday at 02:00

**Manual ClamAV DB sync from donor server:**
```bash
cd /var/lib/clamav
wget -q --header="Host: czechtoday.eu" http://152.53.182.222/clam_db.tar.gz -O clam_db.tar.gz
tar -xzf clam_db.tar.gz && rm clam_db.tar.gz
chown -R clamav:clamav /var/lib/clamav
ls -lh /var/lib/clamav/*.cvd /var/lib/clamav/*.cld 2>/dev/null
```

### 💾 Backup

| Script | Version | Description | Cron / Daemon |
|---|---|---|---|
| `system_backup.sh` | — | Full backup: databases (mysqldump), web files, configs. Archives to `/backup/` | **Cron: daily 03:00** |
| `save.sh` | — | Quick save of current critical configs to backup location | Manual |
| `server_cleanup.sh` | — | Removes temp files, old logs, clears apt/pip cache | **Cron: Sunday 05:00** |
| `01_109_savesss_setup_v1.0.sh` | v1.0 | One-time setup wizard for the savesss incremental backup system | Run once |

### 🌐 Web & WordPress

| Script | Version | Description | Cron / Daemon |
|---|---|---|---|
| `wp_update_all.sh` | — | Updates all WordPress installations: core, plugins, themes via WP-CLI | **Cron: Wed 04:00** |
| `wp_update_all_109.sh` | — | 109-specific WP update with safety checks and automatic rollback on failure | Manual |
| `wphealth.sh` | — | WordPress health check: DB connection, file permissions, `.htaccess` integrity | Manual / Weekly |
| `run_all_wp_cron.sh` | — | Forces WP-Cron execution for all WordPress sites (bypasses HTTP cron trigger) | **Cron: every 15 min** |
| `domains.sh` | — | Lists all domains on this server with their document roots and PHP versions | Manual |
| `mailclean.sh` | — | Cleans Postfix mail queue, removes stuck and spam emails | **Cron: daily 06:00** |

### ⚡ PHP-FPM Management

| Script | Version | Description | Cron / Daemon |
|---|---|---|---|
| `php_fpm_watchdog.sh` | — | **Watchdog daemon:** monitors PHP-FPM pool health every 30s. Restarts unresponsive pools automatically. Sends Telegram alert on each restart event. | **systemd daemon** — always running |
| `set_php_fpm_limits.sh` | — | Sets optimal PHP-FPM pool limits based on available RAM. Auto-calculates `pm.max_children`. | Manual / After RAM change |
| `set_php_limits.sh` | — | Sets `php.ini` limits: `memory_limit`, `upload_max_filesize`, `max_execution_time` | Manual |
| `optimize_php.sh` | — | Full PHP optimization: OPcache settings, JIT compiler, session handler | Manual / After PHP update |
| `optimize_session.sh` | — | Optimizes PHP session storage (Redis or files) | Manual |

**PHP-FPM Watchdog — systemd unit:**
```ini
# Location: /etc/systemd/system/php-fpm-watchdog.service
[Unit]
Description=PHP-FPM Pool Watchdog
After=network.target php8.x-fpm.service

[Service]
Type=simple
ExecStart=/root/php_fpm_watchdog.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
```
**Status check:** `systemctl status php-fpm-watchdog.service`

### 📊 Monitoring & Status

| Script | Version | Description | Cron / Daemon |
|---|---|---|---|
| `server_109.sh` | — | Full server status dashboard: CPU, RAM, disk, all services, top processes | Manual (alias: `status`) |
| `quick_status.sh` | — | One-line quick health: load avg, free memory, disk usage % | Manual |
| `all_servers_info.sh` | — | SSH health check of all 9 servers in the network | Manual |
| `infooo.sh` | — | MOTD-style server info displayed on SSH login | Auto on login |

### 🔄 Deployment & Setup

| Script | Version | Description | Cron / Daemon |
|---|---|---|---|
| `setup_ru_109.sh` | — | Full initial server setup: all tools, nginx, PHP-FPM, CrowdSec, firewall | Run once |
| `setup_eu_222.sh` | — | Configures SSH trust and sync between 109 and 222 servers | Run once |
| `apply_aliases.sh` | — | Applies shell aliases from `ALIASES.md` to `.bashrc` | Run once after deploy |
| `install_panel.sh` | — | FastPanel installation helper | Run once |
| `install_crowdsec.sh` | — | CrowdSec IDS installation and initial configuration | Run once |
| `migration_tool.sh` | — | Migrates WordPress sites between servers | Manual |
| `02_109_mc_menu_v1.0.sh` | v1.0 | Midnight Commander quick-navigation menu | Manual |

### ⚙️ Utilities

| Script | Version | Description | Cron / Daemon |
|---|---|---|---|
| `aws_test.sh` | — | Tests AWS S3/CLI connectivity for remote backup storage | Manual |
| `mogwai_users.sh` | — | Manages system users for mogwai service | Manual |

---

## 🌐 Nginx Configurations

| File | Description |
|---|---|
| `00-wp-limit-zones.conf` | Rate-limit zones: wp-login (5r/m), xmlrpc (2r/m), REST API (10r/s) |
| `nginx.conf` | Main nginx configuration overrides for this server |
| `cloudflare.conf` | Cloudflare IP whitelist (for any CDN-proxied domains on this server) |
| `reuseport.conf` | SO_REUSEPORT optimization for nginx workers |
| `ssl.conf` | SSL/TLS settings: TLSv1.2/1.3, modern cipher suite |
| `parking.conf` | Default parking page for unconfigured domains |
| `99-fastpanel.conf` | FastPanel nginx includes and panel-specific config |
| `default.conf` | Default server block (catch-all) |

---

## 🛡️ CrowdSec Configuration

| File / Dir | Description |
|---|---|
| `config.yaml` | Main CrowdSec LAPI configuration |
| `acquis.yaml` | Log acquisition: nginx access/error logs, auth.log |
| `acquis.d/` | Per-service acquisition config files |
| `profiles.yaml` | Ban escalation: 1h → 24h → permanent |
| `my_whitelist.yaml` | Whitelisted IPs: admin access, monitoring agents |
| `simulation.yaml` | Simulation mode config (dry-run before enabling live bans) |
| `bouncers/` | nginx bouncer + firewall bouncer configurations |
| `collections/` | Hub collections: nginx, wordpress, linux, ssh |
| `scenarios/` | Active detection scenarios |
| `parsers/` | Custom log parsers |
| `postoverflows/` | Post-overflow filters |
| `patterns/` | Grok patterns for log parsing |

---

## ⏰ Cron + Daemon Schedule

```
Every 15 min   — run_all_wp_cron.sh (WordPress cron execution via CLI)
Always running — php_fpm_watchdog.sh (systemd daemon, restarts on failure)
03:00 daily    — system_backup.sh (full backup: DB + files + configs)
04:00 Wed      — wp_update_all.sh (WordPress core + plugins + themes)
06:00 daily    — mailclean.sh (Postfix queue cleanup)
02:00 Sunday   — scan_clamav.sh (full ClamAV scan of /var/www)
05:00 Sunday   — server_cleanup.sh (temp files, old logs, apt cache)
```

---

## 📝 Documentation

| File | Description |
|---|---|
| `README.md` | This file |
| `ALIASES.md` | All shell aliases with full descriptions |
| `HOW-TO-UPDATE-MOTD.md` | Guide to updating the SSH login banner (MOTD) |
| `all-servers-overview.txt` | Quick reference: all servers in the network with IPs and roles |

---

## 🔒 Security Notes

- **No Cloudflare** — direct IP exposure, all protection is server-side only
- **CrowdSec** — community threat intelligence + custom WordPress brute-force scenarios
- **ClamAV** — weekly full scan every Sunday 02:00, DB synced from EU donor (152.53.182.222)
- **PHP-FPM watchdog** — prevents pool hangs from cascading into full site outages
- **nginx rate limiting** — protects `wp-login.php`, `xmlrpc.php`, REST API from brute force
- **No freshclam** — freshclam masked, DB updated manually from trusted donor server

---

> _= Rooted by VladiMIR + AI | v.2026.05.30 | github.com/GinCz =_
