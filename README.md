# Linux Server Public — Scripts & Configs
GitHub: https://github.com/GinCz/Linux_Server_Public
Author: Ing. VladiMIR Bulantsev
Last updated: v2026-03-24

---

## Git Clone — always use SSH, never HTTPS

```bash
# CORRECT (no password prompt):
git clone git@github.com:GinCz/Linux_Server_Public.git

# WRONG (asks password every time):
# git clone https://github.com/GinCz/Linux_Server_Public.git
```

---

## MAIN RULE
Every script used on a specific server MUST be present in that server's own folder.
Each server folder is self-contained and fully independent.
Scripts MAY be duplicated across folders — this is intentional.

---

## COLOR SCHEME (SSH terminal)
- 222 EU Germany  : YELLOW  `PS1 033[01;33m`
- 109 RU Russia   : LIGHT PINK  `PS1 e[38;5;217m`
- VPN             : GREEN (planned)
- AWS             : CYAN (planned)

Permanent color setup via `/root/.bash_profile` on each server.

---

## REPOSITORY STRUCTURE

```
Linux_Server_Public/
|-- 222/         <- EU Server Germany NetCup  xxx.xxx.xxx.222
|-- 109/         <- RU Server Russia FastVDS  xxx.xxx.xxx.109
|-- VPN/         <- VPN Server AmneziaWG + WireGuard
|-- AWS/         <- AWS Server Amazon
|-- scripts/     <- Universal scripts base (copy to server folder before use)
|-- README.md
```

---

## 222/ — EU Server Germany (NetCup) xxx.xxx.xxx.222
**Specs:** 4 vCore AMD EPYC-Genoa / 8GB DDR5 ECC / 256GB NVMe / Ubuntu 24 / FastPanel / 8.60 EUR/mo
**Sites:** European WordPress sites WITH Cloudflare protection

### 222/ — Shell Scripts

| Script | Run Command | Description |
|--------|-------------|-------------|
| `sos.sh` | `bash sos.sh 1h` | Full server audit for a given time period (15m / 1h / 3h / 6h / 24h). Shows top processes, memory, nginx errors, PHP-FPM status, CrowdSec bans, disk usage. Sends report to Telegram. |
| `infooo.sh` | `bash infooo.sh` | Detailed server status: CPU load, RAM usage, disk, nginx workers, PHP-FPM pool stats, uptime, top 5 processes by CPU and RAM. |
| `quick_status.sh` | `bash quick_status.sh` | One-line health check. Shows CPU/RAM/disk percent + nginx and PHP status in a single compact output. |
| `save.sh` | `bash save.sh` | Git add all + commit with timestamp + push to GitHub. Used to save current state of configs and scripts. |
| `system_backup.sh` | `bash system_backup.sh` | Full system backup: nginx configs, PHP configs, CrowdSec configs, cron, .bashrc. Archives to `/root/backups/` with date stamp. |
| `run_all_wp_cron.sh` | `bash run_all_wp_cron.sh` | Runs `wp cron event run --due-now` for every WordPress site on the server. Bypasses broken WP-Cron HTTP triggers. |
| `domains.sh` | `bash domains.sh` | Reads all nginx vhosts, extracts domain names, checks HTTP status code for each (200 = OK, anything else = problem). Outputs color-coded results. |
| `domains_check.sh` | `bash domains_check.sh` | Extended domain check: HTTP status + SSL certificate expiry in days for every domain. Sends Telegram alert if SSL expires in less than 7 days. |
| `php_fpm_watchdog.sh` | `bash php_fpm_watchdog.sh` | Monitors all PHP-FPM pools. If a pool is hung or not responding, it restarts it automatically. Logs all restarts. Designed for cron every 5 min. |
| `optimize_php.sh` | `bash optimize_php.sh` | Cleans PHP session files, clears OPcache, adjusts PHP-FPM limits based on current RAM, restarts nginx and PHP-FPM. |
| `optimize_session.sh` | `bash optimize_session.sh` | Cleans old PHP session files from `/var/lib/php/sessions/`. Prevents session directory from filling up disk. |
| `set_php_limits.sh` | `bash set_php_limits.sh domain min max` | Sets PHP-FPM `pm.min_spare_servers` and `pm.max_children` for a specific domain pool. Restarts the pool after change. |
| `block_bots.sh` | `bash block_bots.sh` | Analyzes nginx access logs for bad bots and scanners. Adds their IPs to iptables DROP rules and nginx deny list. |
| `block_bots_root.sh` | `bash block_bots_root.sh` | Same as block_bots.sh but reads logs from `/var/log/nginx/` root level. Used when site logs are in non-standard paths. |
| `scan_clamav.sh` | `bash scan_clamav.sh` | Runs ClamAV antivirus scan on all site directories under `/var/www/`. Reports infected files, optionally quarantines them. Sends result to Telegram. |
| `install_crowdsec.sh` | `bash install_crowdsec.sh` | Installs CrowdSec + nginx bouncer. Configures WordPress scenarios (brute-force, xmlrpc, login flood). Adds whitelist for own IPs (222, 109). |
| `cloudflare_proxy.sh` | `bash cloudflare_proxy.sh` | Toggles Cloudflare proxy (orange cloud) on/off for a domain via Cloudflare API. Useful when direct IP access is needed. |
| `global_htaccess.sh` | `bash global_htaccess.sh` | Deploys a standard `.htaccess` file to all WordPress sites. Includes security headers, wp-login protection, xmlrpc block. |
| `apply_aliases.sh` | `bash apply_aliases.sh` | Applies bash aliases from the shared config to the current shell session without needing to re-login. |
| `shared_aliases.sh` | `source shared_aliases.sh` | Contains all custom bash aliases for the server (shortcuts for audit, domains, bots, backup, etc.). Sourced by `.bashrc`. |
| `mogwai_users.sh` | `bash mogwai_users.sh` | Creates/checks FastPanel system users for all WordPress sites. Ensures each site has its own isolated PHP-FPM user. |
| `migration_tool.sh` | `bash migration_tool.sh` | Tool for migrating a WordPress site: copies files, exports/imports database, updates wp-config.php, updates URLs in DB. |
| `setup_eu_222.sh` | `bash setup_eu_222.sh` | Initial full setup script for the 222 EU server: installs packages, configures nginx, PHP, sets up CrowdSec, clones repo. |
| `setup_ru_109.sh` | `bash setup_ru_109.sh` | Initial full setup script for the 109 RU server (can be run from 222 as reference). |
| `server_cleanup.sh` | `bash server_cleanup.sh` | Removes old logs, temp files, orphaned PHP sessions, clears apt cache, frees up disk space. |
| `01_222_clean_vpn_reports_v1.0.sh` | `bash 01_222_clean_vpn_reports_v1.0.sh` | **INSTALLER.** Sets up cron job to auto-delete VPN report folders older than 7 days from `/var/www/.../server-set/VPN_servers/`. Runs daily at 03:00. |
| `02_222_mc_menu_v1.0.sh` | `bash 02_222_mc_menu_v1.0.sh` | **INSTALLER.** Deploys the Midnight Commander F2 user menu (`mc.menu`) for server 222. After running, press F2 in MC to access all server commands. |
| `savesss_wrapper.sh` | `bash savesss_wrapper.sh [args]` | Simple wrapper that calls `server_audit.sh` with any passed arguments. Provides backwards compatibility for old aliases that used the `savesss` name. |

### 222/ — Config Files

| File | Description |
|------|-------------|
| `mc.menu` | Midnight Commander F2 user menu for server 222. Contains: audit, bots, domains, backup, CrowdSec bans/alerts, system info. |
| `.bashrc` | Custom bash config for server 222: colors (yellow PS1), aliases, PATH settings. |
| `nginx.conf` | Main nginx config optimized for server 222: worker processes, gzip, timeouts, buffer sizes. |
| `cloudflare.conf` | Nginx include: sets `real_ip_from` for all Cloudflare IP ranges so real visitor IPs appear in logs. |
| `cloudflare_real_ip.conf` | Alternative Cloudflare real IP config variant (uses `set_real_ip_from` block). |
| `cloudflare_waf_rules.md` | Documentation: Cloudflare WAF custom rules for WordPress protection (xmlrpc block, login flood, etc.). |
| `00-wp-login-limit-zone.conf` | Nginx rate-limit zone definition for `wp-login.php`. Included in main nginx.conf. |
| `01-wp-limit-zones.conf` | Extended nginx rate-limit zones for WordPress (xmlrpc, wp-admin, REST API). |
| `99-fastpanel.conf` | FastPanel nginx addon config. Must not be removed — required by FastPanel panel. |
| `reuseport.conf` | Nginx listen directive with `reuseport` for multi-worker performance on multi-core CPU. |
| `ssl.conf` | Global SSL settings for nginx: TLS 1.2/1.3, cipher list, HSTS, OCSP stapling. |
| `default.conf` | Nginx default server block (catch-all for unknown domains → returns 444). |
| `parking.conf` | Nginx config for parked domains: returns a simple placeholder page instead of 404. |
| `server.gincz.com.conf` | Nginx vhost config for `server.gincz.com` — the internal server monitoring/status page. |
| `acquis.yaml` | CrowdSec acquisition config: defines which log files CrowdSec reads (nginx, sshd, etc.). |
| `config.yaml` | Main CrowdSec configuration file. |
| `profiles.yaml` | CrowdSec profiles: defines what actions to take for each alert type (ban, captcha, etc.). |
| `simulation.yaml` | CrowdSec simulation mode config. When enabled, bans are logged but not applied. |
| `local_api_credentials.yaml` | CrowdSec local API credentials (machine ID + password). Auto-generated, keep as backup. |
| `online_api_credentials.yaml` | CrowdSec cloud API credentials for threat intelligence sharing. |
| `console.yaml` | CrowdSec console enrollment config. |
| `whitelist.txt` | IP whitelist for CrowdSec and iptables: xxx.xxx.xxx.222, xxx.xxx.xxx.109, admin IPs. |
| `global_blacklist.txt` | Global IP blacklist. Loaded by block_bots.sh and CrowdSec. |
| `rules.txt` | Custom iptables rules applied at startup (persistent block list). |
| `server-info.md` | Complete server documentation: hardware specs, list of all 44 WordPress sites with users, cron jobs, all aliases. |
| `php_fpm_limits_info.md` | Reference doc: PHP-FPM pool sizing recommendations based on RAM. |

---

## 109/ — RU Server Russia (FastVDS) xxx.xxx.xxx.109
**Specs:** 4 vCore AMD EPYC 7763 / 8GB RAM / 80GB NVMe / Ubuntu 24 LTS / FastPanel / 13 EUR/mo
**Sites:** Russian WordPress sites WITHOUT Cloudflare (direct IP)

### 109/ — Shell Scripts

| Script | Run Command | Description |
|--------|-------------|-------------|
| `sos.sh` | `bash sos.sh 1h` | Full server audit for a given time period (15m / 1h / 3h / 6h / 24h). Показывает top процессы, память, ошибки nginx, статус PHP-FPM, баны CrowdSec, диск. Отправляет отчёт в Telegram. |
| `infooo.sh` | `bash infooo.sh` | Detailed server status: CPU, RAM, disk, nginx workers, PHP-FPM pools, uptime, top processes. |
| `quick_status.sh` | `bash quick_status.sh` | One-line health check: CPU/RAM/disk + nginx/PHP status. |
| `save.sh` | `bash save.sh` | Git add all + commit with timestamp + push to GitHub. |
| `system_backup.sh` | `bash system_backup.sh` | Backup nginx, PHP, CrowdSec configs, cron, .bashrc to `/root/backups/`. |
| `run_all_wp_cron.sh` | `bash run_all_wp_cron.sh` | Runs WP-Cron for all WordPress sites on the server via WP-CLI. |
| `domains.sh` | `bash domains.sh` | Checks HTTP status of all domains from nginx vhosts. Color output: green=200, red=other. |
| `php_fpm_watchdog.sh` | `bash php_fpm_watchdog.sh` | Monitors PHP-FPM pools, auto-restarts hung pools. For cron every 5 min. |
| `optimize_php.sh` | `bash optimize_php.sh` | Cleans PHP sessions, adjusts FPM limits by RAM, restarts services. |
| `optimize_session.sh` | `bash optimize_session.sh` | Deletes old PHP session files to prevent disk fill-up. |
| `set_php_limits.sh` | `bash set_php_limits.sh domain min max` | Sets PHP-FPM pool min/max for specific domain, restarts pool. |
| `block_bots.sh` | `bash block_bots.sh` | Blocks bad bots/scanners via iptables + nginx deny. Reads nginx access logs. |
| `scan_clamav.sh` | `bash scan_clamav.sh` | ClamAV antivirus scan of all site dirs. Reports + optional quarantine + Telegram alert. |
| `install_crowdsec.sh` | `bash install_crowdsec.sh` | Installs CrowdSec + nginx bouncer + WordPress protection scenarios + whitelist own IPs. |
| `apply_aliases.sh` | `bash apply_aliases.sh` | Applies bash aliases to current session without re-login. |
| `mogwai_users.sh` | `bash mogwai_users.sh` | Creates/checks FastPanel system users for isolated PHP-FPM per site. |
| `migration_tool.sh` | `bash migration_tool.sh` | WordPress site migration: files + DB export/import + wp-config update. |
| `setup_ru_109.sh` | `bash setup_ru_109.sh` | Full initial setup for server 109: packages, nginx, PHP, CrowdSec, repo clone. |
| `setup_eu_222.sh` | `bash setup_eu_222.sh` | Reference setup script for 222 (kept here for cross-server comparison). |
| `server_cleanup.sh` | `bash server_cleanup.sh` | Cleans old logs, sessions, temp files, frees disk space. |
| `01_109_savesss_setup_v1.0.sh` | `bash 01_109_savesss_setup_v1.0.sh` | **INSTALLER.** Sets up the `savesss` sync script: collects server-set files from 109 and sends them via SSH to server 222 into `gincz.com/server-set/`. |
| `02_109_mc_menu_v1.0.sh` | `bash 02_109_mc_menu_v1.0.sh` | **INSTALLER.** Deploys Midnight Commander F2 user menu for server 109. After running, press F2 in MC to get full command menu. |

### 109/ — Config Files

| File | Description |
|------|-------------|
| `mc.menu` | Midnight Commander F2 user menu for server 109. Contains: audit, bots, domains check, CrowdSec, send report to 222, system info. Differs from 222 menu — no Cloudflare controls, has savesss sync. |
| `.bashrc` | Custom bash config for server 109: colors (light pink PS1), aliases, PATH. |
| `nginx.conf` | Main nginx config for server 109. |
| `cloudflare.conf` | Cloudflare real IP config (kept for reference; 109 sites are direct, not through CF). |
| `00-wp-limit-zones.conf` | Nginx rate-limit zone for `wp-login.php` on server 109. |
| `99-fastpanel.conf` | FastPanel nginx addon (required, do not remove). |
| `reuseport.conf` | Nginx `reuseport` multi-worker config. |
| `ssl.conf` | Global SSL/TLS settings for nginx. |
| `default.conf` | Catch-all nginx block → returns 444 for unknown domains. |
| `parking.conf` | Parked domains placeholder page config. |
| `acquis.yaml` | CrowdSec log acquisition config. |
| `config.yaml` | Main CrowdSec config. |
| `profiles.yaml` | CrowdSec alert → action mapping. |
| `simulation.yaml` | CrowdSec simulation mode (log-only, no actual bans). |
| `local_api_credentials.yaml` | CrowdSec local API machine credentials. |
| `online_api_credentials.yaml` | CrowdSec cloud API credentials. |
| `console.yaml` | CrowdSec console config. |
| `whitelist.txt` | IP whitelist: own servers + admin IPs. |
| `global_blacklist.txt` | Global IP blacklist for bots/attackers. |
| `caught_by_109-ru-vds.txt` | Log of IPs caught and blocked specifically on the 109 RU server. |
| `caught_by_xxx.xxx.xxx.109.txt` | Same catch log with full server IP in filename. |
| `all-servers-overview.txt` | Quick reference overview of all servers: IPs, specs, roles. |
| `server-info.md` | Server 109 documentation: hardware, list of 23 WordPress sites, cron jobs, aliases. |
| `php_fpm_limits_info.md` | PHP-FPM pool sizing reference for 8GB RAM server. |

---

## VPN/ — VPN Servers (AmneziaWG + WireGuard)
**Purpose:** Personal VPN, bypass censorship, secure tunnels
**Protocol:** AmneziaWG (obfuscated WireGuard)

| File | Description |
|------|-------------|
| `vpn-info.md` | Full VPN documentation: protocol details, node list, commands (`aw`, `sos`), how to add a new VPN node via `setup.sh`. |

---

## scripts/ — Universal Base Scripts
These are **BASE versions**. Copy to server folder before use.
**Do NOT run directly from `scripts/` on production servers.**

| Script | Description | Use on |
|--------|-------------|--------|
| `crowdsec_xmlrpc_shield` | Installs CrowdSec + firewall bouncer. Configures WordPress brute-force protection (max 5 attempts before ban). Creates whitelist for IPs 222, 109, 114. Globally blocks `/xmlrpc.php` via nginx for all FastPanel sites. Restarts CrowdSec and nginx. | 222 109 |

---

## Aliases Quick Reference (both servers)

| Alias | Command | Description |
|-------|---------|-------------|
| `s` | `bash ~/Linux_Server_Public/222(or 109)/sos.sh 15m` | Quick 15-min audit |
| `ss` | `bash ~/Linux_Server_Public/222(or 109)/sos.sh 1h` | 1-hour audit |
| `i` | `bash ~/Linux_Server_Public/222(or 109)/infooo.sh` | Server info |
| `d` | `bash ~/Linux_Server_Public/222(or 109)/domains.sh` | Domain status |
| `b` | `bash ~/Linux_Server_Public/222(or 109)/block_bots.sh` | Block bots |
| `save` | `bash ~/Linux_Server_Public/222(or 109)/save.sh` | Git push |

---

Last updated: v2026-03-24
