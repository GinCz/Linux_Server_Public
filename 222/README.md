# 🖥️ Server 222 — EU-DE-NetCup (152.53.182.222)

> **Hosting:** NetCup.com | **Location:** Germany (EU)  
> **Hardware:** 4 vCore AMD EPYC-Genoa | 8 GB DDR5 | 256 GB NVMe  
> **OS:** Ubuntu 24 LTS + FASTPANEL  
> **Role:** Primary EU web server — WordPress sites, Cloudflare proxy, Docker, CrowdSec, ClamAV Donor  
> **Cost:** 8.60 EUR/month

---

## 📋 Server Overview

This is the **main production server** for Czech and European websites.
All sites run behind **Cloudflare** (proxy + WAF + DDoS protection).
The server acts as a **ClamAV donor** — it exports fresh antivirus databases
to all other servers in the network via a web-accessible archive.

---

## 📁 Directory Structure

```
222/
├── Scripts (*.sh)          — Automation, maintenance, backup, monitoring
├── Nginx configs (*.conf)  — WordPress protection, rate limiting, Cloudflare IPs
├── PHP config (*.ini)      — OPcache, PHP limits
├── CrowdSec configs        — IDS/IPS: acquis.yaml, config.yaml, profiles
├── Dockers/                — Docker Compose definitions
├── crypto/                 — Crypto trading bot configs and scripts
├── crowdsec/               — CrowdSec hub: collections, bouncers, scenarios
├── Documentation (*.md)    — READMEs, HOWTOs, postmortems
└── .bashrc / .bash_profile — Shell environment, aliases
```

---

## 🔧 Scripts Reference

### 🛡️ Security & Protection

| Script | Version | Description | Cron / Daemon |
|---|---|---|---|
| `banlog.sh` | — | Displays CrowdSec ban log with banned IPs, country, reason, expiry | Manual |
| `block_bots.sh` | — | Blocks known bad bots via nginx `deny` rules, updates config | Manual |
| `block_bots_root.sh` | — | Root-level bot blocking, regenerates nginx deny lists | Manual |
| `custom-wp-login-hardban.yaml` | — | CrowdSec custom scenario: permanent ban after 5+ wp-login attempts | CrowdSec daemon |

### 💾 Backup

| Script | Version | Description | Cron / Daemon |
|---|---|---|---|
| `backup_all_servers.sh` | — | Full backup of all sites on this server + remote servers via SSH | **Cron: daily 03:00** |
| `backup_clean.sh` | — | Removes backup archives older than 7 days | **Cron: daily 04:00** |
| `docker_backup.sh` | — | Backs up all Docker volumes and container configs to archive | **Cron: daily 02:00** |
| `crypto_restore.sh` | — | Restores crypto bot from latest backup in case of container failure | Manual |

### 🌐 Web & WordPress

| Script | Version | Description | Cron / Daemon |
|---|---|---|---|
| `domains.sh` | — | Lists all domains configured on the server with document roots | Manual |
| `domains_check.sh` | — | Checks SSL certificate expiry and DNS resolution for all domains | Manual / Weekly |
| `global_htaccess.sh` | — | Applies hardened `.htaccess` security rules to all WordPress sites | Manual |
| `mailclean.sh` | — | Cleans Postfix mail queue, removes stuck/spam emails | **Cron: daily 06:00** |
| `wp_update_all.sh` | — | Updates all WordPress: core, plugins, themes via WP-CLI | **Cron: Wed 04:00** |

### 📊 Monitoring & Status

| Script | Version | Description | Cron / Daemon |
|---|---|---|---|
| `infooo.sh` | — | Quick server overview: CPU, RAM, disk, active services | Manual / MOTD |
| `f5servers.sh` | — | Checks status of 5 primary servers via SSH | Manual |
| `f9servers.sh` | — | Extended check of all 9 network servers via SSH | Manual |
| `final_check.sh` | — | Health check after maintenance: nginx, php-fpm, mysql | Manual |
| `load.sh` | — | Monitors server load average in real time | Manual |

### 🛡️ ClamAV — DONOR Role

| Script / Action | Description | Schedule |
|---|---|---|
| Export DB archive | Runs `freshclam` then packs `/var/lib/clamav/` into tar.gz | **Cron: daily 01:00** |

**ClamAV status on this server:**
- ✅ **INSTALLED** — `/usr/bin/clamscan` present
- ✅ **DB files present:** `main.cvd`, `daily.cvd`, `bytecode.cvd`
- ⚙️ **freshclam:** masked (manual update + donor export)
- 📦 **DB export path:** `/var/www/dmitry-vary/data/www/czechtoday.eu/clam_db.tar.gz`
- 🌐 **DB export URL:** `http://152.53.182.222/clam_db.tar.gz` (Host: czechtoday.eu)

All other servers in the network pull ClamAV databases from this server.
See [CHANGELOG.md](../CHANGELOG.md) for last sync date.

### 🔄 Deployment & Sync

| Script | Version | Description | Cron / Daemon |
|---|---|---|---|
| `deploy.sh` | — | Deploys latest scripts from GitHub to server | Manual |
| `deploy_sos_all_vpn.sh` | — | Emergency deploy of SOS scripts to all VPN servers | Manual |
| `01_222_clean_vpn_reports_v1.0.sh` | v1.0 | Cleans old VPN status reports from disk | **Cron: weekly** |
| `02_222_mc_menu_v1.0.sh` | v1.0 | Midnight Commander quick-navigation menu | Manual |

### ⚙️ System Setup

| Script | Version | Description | Cron / Daemon |
|---|---|---|---|
| `apply_aliases.sh` | — | Applies all shell aliases from `ALIASES.md` to `.bashrc` | Run once after deploy |
| `install_panel.sh` | — | FastPanel installation helper script | Run once |
| `aws_test.sh` | — | Tests AWS S3/CLI connectivity for backup storage | Manual |

---

## 🌐 Nginx Configurations

| File | Description |
|---|---|
| `cloudflare.conf` | Cloudflare IP ranges for `set_real_ip_from` directives |
| `cloudflare_real_ip.conf` | Real IP resolution from Cloudflare `CF-Connecting-IP` header |
| `00-wp-login-limit-zone.conf` | Rate-limit zone definition for `wp-login.php` |
| `00-wp-protection-zones.conf` | Full protection: xmlrpc, wp-login, REST API rate limit zones |
| `01-wp-limit-zones.conf` | Per-vhost application of protection zones |
| `99-fastpanel.conf` | FastPanel-specific nginx includes |
| `10-opcache.ini` | PHP OPcache config: 256 MB memory, JIT enabled |
| `default.conf` | Default nginx server block |

---

## 🛡️ CrowdSec Configuration

| File / Dir | Description |
|---|---|
| `config.yaml` | Main CrowdSec LAPI configuration |
| `acquis.yaml` | Log acquisition sources: nginx access/error, syslog, auth.log |
| `acquis.d/` | Additional per-service acquisition config files |
| `profiles.yaml` | Ban decision profiles and escalation rules |
| `custom-wp-login-hardban.yaml` | Custom scenario: 5+ wp-login attempts → permanent ban |
| `bouncers/` | CrowdSec bouncer configs: nginx bouncer, firewall bouncer |
| `collections/` | Installed hub collections (nginx, wordpress, linux) |
| `scenarios/` | Active detection scenarios |
| `parsers/` | Log parsers for nginx and system logs |

---

## ⏰ Cron & Daemon Schedule

```
01:00 daily   — ClamAV DB freshclam update + export archive for network sync
02:00 daily   — Docker volumes backup
03:00 daily   — Full backup all sites + remote servers
04:00 daily   — Clean old backups (keep last 7 days)
04:00 Wed     — WordPress core/plugins/themes update (WP-CLI)
06:00 daily   — Postfix mail queue cleanup
Weekly        — VPN reports cleanup, domain SSL certificate check
```

---

## 🐳 Docker Services

See `Dockers/` directory and `docker-compose.yml` for:
- CrowdSec container (IDS/IPS)
- Monitoring stack (Netdata / Grafana)
- Crypto trading bot containers (see `crypto/`)

---

## 📝 Documentation

| File | Description |
|---|---|
| `README.md` | This file |
| `ALIASES.md` | All shell aliases with full descriptions |
| `CLEANUP_LOG.md` | History of server cleanup operations |
| `HOW-TO-UPDATE-MOTD.md` | Guide to updating the SSH login banner (MOTD) |
| `INSTALL_SCRIPTS.md` | Step-by-step installation guide for all scripts |
| `SERVER_STATUS.md` | Server status snapshots |
| `POSTMORTEM_wp_login_hardening.md` | Post-mortem: WordPress login hardening incident |
| `SSH-Cursor-Setup.md` | SSH + Cursor IDE integration guide |
| `cloudflare_waf_rules.md` | Cloudflare WAF custom rules documentation |

---

## 🔧 FastPanel Notes

**Known issue:** If FastPanel File Manager fails with `filemanagersystemd@<site>.service` error
(e.g., after a panel update), the fix is:
```bash
systemctl daemon-reload
systemctl reset-failed filemanagersystemd@<site>.service
systemctl start filemanagersystemd@<site>.service
```
This happens when systemd unit files are changed on disk without reloading the daemon.
See [CHANGELOG.md](../CHANGELOG.md) for the 2026-05-30 incident details.

---

> _= Rooted by VladiMIR + AI | v.2026.05.30 | github.com/GinCz =_
