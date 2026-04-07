# 🖥️ Linux Server Public — VladiMIR

> Public configuration files, scripts, and documentation for two production servers.
> **All secrets, passwords, and API keys are stored in a separate PRIVATE repository.**

---

## 🗂️ Repository Structure

```
Linux_Server_Public/
├── 222/          → Server 222-DE-NetCup   (152.53.182.222)  — NetCup.com, Germany
│                   Ubuntu 24 / FASTPANEL / Cloudflare / CZ+EU sites
│                   4 vCore AMD EPYC-Genoa / 8GB DDR5 ECC / 256GB NVMe
│
├── 109/          → Server 109-RU-FastVDS  (212.109.223.109) — FastVDS.ru, Russia
│                   Ubuntu 24 / FASTPANEL / No Cloudflare / RU sites
│                   4 vCore AMD EPYC 7763 / 8GB RAM / 80GB NVMe
│
└── README.md     → This file
```

---

## 📁 Folder: `222/` — NetCup Germany (Cloudflare)

| File / Folder | Description |
|---|---|
| `server-info.md` | Full server specification, installed software, domain list |
| `set_php_fpm_limits_v2026-04-07.sh` | **[KEY]** Universal PHP-FPM limiter — sets CPU quota, RAM max, OOM score via systemd cgroup for ALL pools |
| `set_php_limits.sh` | Legacy PHP-FPM limits script (v1, RAM-only, replaced by above) |
| `php_fpm_limits_info.md` | Documentation: how PHP-FPM limits work on this server |
| `php_fpm_watchdog.sh` | Watchdog — monitors PHP-FPM processes, kills runaway workers |
| `php-fpm-pools-backup/` | Backup copies of all PHP-FPM pool `.conf` files |
| `backup_clean.sh` | Cleans old local backups, keeps last N copies |
| `banlog.sh` | Analyses Nginx access logs, shows top attacking IPs |
| `block_bots.sh` | Blocks bad bots via Nginx `deny` rules |
| `block_bots_root.sh` | Same as above but runs in root context |
| `cloudflare.conf` | Nginx: list of Cloudflare IP ranges for `set_real_ip_from` |
| `cloudflare_real_ip.conf` | Nginx: restores real visitor IP from `CF-Connecting-IP` header |
| `cloudflare_waf_rules.md` | Cloudflare WAF custom rules reference |
| `cloudflare_proxy.sh` | Helper to toggle Cloudflare proxy on/off via API |
| `domains.sh` | Lists all domains on this server with their status |
| `domains_check.sh` | Checks SSL certificates and DNS for all domains |
| `docker-compose.yml` | Docker Compose for auxiliary containers |
| `docker_backup.sh` | Backs up Docker volumes and configs |
| `fix_nginx_crowdsec_222_v2026-04-05.sh` | One-time fix for Nginx + CrowdSec bouncer config |
| `wp_update_all.sh` | Updates all WordPress sites (core, plugins, themes) |
| `wphealth.sh` | WordPress health check — detects broken sites |
| `run_all_wp_cron.sh` | Triggers WP-Cron for all sites manually |
| `scan_clamav.sh` | ClamAV antivirus scan for all web directories |
| `mailclean.sh` | Cleans mail queue (Postfix) |
| `motd_server.sh` | Custom MOTD (login message) with server stats |
| `infooo.sh` | Quick server info summary |
| `all_servers_info.sh` | SSH into both servers and shows combined status |
| `quick_status.sh` | One-liner: CPU, RAM, Nginx, PHP-FPM status |
| `banlog.sh` | CrowdSec/Nginx ban log analyser |
| `aws_test.sh` | AWS S3 backup connectivity test |
| `save.sh` | Pushes current configs to this GitHub repo |
| `server_cleanup.sh` | Removes old logs, temp files, apt cache |
| `mc.menu` | Midnight Commander user menu |
| `.bashrc` / `.bash_profile` | Custom shell aliases and prompt |
| `nginx.conf` | Main Nginx config |
| `00-wp-login-limit-zone.conf` | Nginx: rate-limit zone for wp-login.php |
| `01-wp-limit-zones.conf` | Nginx: extended rate-limit zones for WordPress |
| `cloudflare_waf_rules.md` | Cloudflare WAF rules documentation |
| `acquis.yaml` / `acquis.d/` | CrowdSec acquisition config |
| `config.yaml` | CrowdSec main config |
| `local_api_credentials.yaml` | **TEMPLATE ONLY** — real credentials in private repo |
| `online_api_credentials.yaml` | **TEMPLATE ONLY** — real credentials in private repo |

---

## 📁 Folder: `109/` — FastVDS Russia (No Cloudflare)

| File / Folder | Description |
|---|---|
| `server-info.md` | Full server specification, installed software, domain list |
| `set_php_fpm_limits_v2026-04-07.sh` | **[KEY]** Universal PHP-FPM limiter — same as 222, auto-detects server resources |
| `set_php_limits.sh` | Legacy PHP-FPM limits script (v1, replaced by above) |
| `php_fpm_limits_info.md` | Documentation: PHP-FPM limits on this server |
| `php_fpm_watchdog.sh` | Watchdog for runaway PHP-FPM workers |
| `banlog.sh` | Nginx log analyser for bans |
| `block_bots.sh` | Blocks bad bots in Nginx |
| `cloudflare.conf` | Nginx: Cloudflare IP list (kept for reference, CF not active here) |
| `domains.sh` | Lists all domains with status |
| `run_all_wp_cron.sh` | Manual WP-Cron trigger |
| `scan_clamav.sh` | ClamAV scan |
| `mailclean.sh` | Mail queue cleanup |
| `motd_server.sh` | Custom MOTD |
| `infooo.sh` | Quick server info |
| `all_servers_info.sh` | Combined both-server status |
| `quick_status.sh` | One-liner status |
| `aws_test.sh` | AWS S3 test |
| `save.sh` | Push configs to GitHub |
| `server_cleanup.sh` | Cleanup old files |
| `mc.menu` | Midnight Commander menu |
| `nginx.conf` | Main Nginx config |
| `install_crowdsec.sh` | CrowdSec installation script |
| `acquis.yaml` / `acquis.d/` | CrowdSec acquisition config |
| `config.yaml` | CrowdSec main config |
| `local_api_credentials.yaml` | **TEMPLATE ONLY** — real credentials in private repo |
| `online_api_credentials.yaml` | **TEMPLATE ONLY** — real credentials in private repo |

---

## 🔒 Security Policy

**This is a PUBLIC repository.** The following rules apply:

- ✅ Scripts, config templates, documentation — OK to be public
- ❌ **Passwords, API keys, tokens** — NEVER in this repo
- ❌ **CrowdSec credentials** (`local_api_credentials.yaml`, `online_api_credentials.yaml`) — templates only here, real values in private repo
- ❌ **AWS keys, Telegram tokens, Cloudflare API keys** — private repo only

If you ever accidentally commit a secret:
```bash
# Immediately rotate/revoke the exposed credential
# Then clean git history:
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch PATH/TO/FILE' HEAD
git push --force
```

---

## 🚀 Key Script: `set_php_fpm_limits_v2026-04-07.sh`

The most important script added on 2026-04-07. Solves the problem of **a single WordPress site consuming 90%+ CPU** by:

1. **PHP-FPM pool level** — sets `pm.max_children=8` and `pm.max_requests=500` for every domain pool
2. **systemd cgroup level** — sets hard `CPUQuota` and `MemoryMax` so the OS enforces limits even if PHP-FPM config is bypassed

### How to run
```bash
# Download and run on 222-DE-NetCup
wget -O /root/set_php_fpm_limits_v2026-04-07.sh \
  https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/222/set_php_fpm_limits_v2026-04-07.sh
bash /root/set_php_fpm_limits_v2026-04-07.sh

# Download and run on 109-RU-FastVDS
wget -O /root/set_php_fpm_limits_v2026-04-07.sh \
  https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/109/set_php_fpm_limits_v2026-04-07.sh
bash /root/set_php_fpm_limits_v2026-04-07.sh
```

### Limits applied (per server, auto-calculated)
| Parameter | Value | Where |
|---|---|---|
| `pm.max_children` | ≤8 (calc from RAM) | PHP-FPM pool .conf |
| `pm.max_requests` | 500 | PHP-FPM pool .conf |
| `CPUQuota` | 320% (4 cores × 80%) | systemd cgroup |
| `MemoryMax` | ~6.8 GB (85% of 8 GB) | systemd cgroup |
| `MemoryHigh` | ~6.0 GB (75% of 8 GB) | systemd cgroup |
| `OOMScoreAdjust` | 300 | systemd cgroup |

---

*= Rooted by VladiMIR | AI =*
