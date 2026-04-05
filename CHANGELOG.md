# CHANGELOG

```
= Rooted by VladiMIR | AI =
```

All notable changes to server configurations, scripts and infrastructure.

Format: `[YYYY-MM-DD] SERVER — Description`

---

## [2026-04-05] SERVER 109 — CrowdSec fix + clamd disable

### 🔴 Problem
- CrowdSec was running but **NOT banning any HTTP attackers** (wp-login brute force, webshell probing, path traversal)
- `clamd` daemon consuming **975 MB swap** continuously
- Server swap usage: ~1.4 GB total

### 🔍 Root Cause
FastPanel uses a **non-standard nginx log format**:
```nginx
log_format fastpanel '[$time_local] $host $server_addr $remote_addr ...';
```
CrowdSec nginx parser expects standard **Combined format** where `$remote_addr` is the **first field**.  
Because FastPanel puts `[$time_local]` first, the parser could not extract IP addresses → buckets never filled → **zero bans despite active scenarios**.

### ✅ Fix 1 — nginx dual logging
- Added `log_format combined_crowdsec` to `/etc/nginx/nginx.conf`
- Added second `access_log /var/log/nginx/crowdsec-access.log combined_crowdsec;`
- FastPanel native log **unchanged** — panel still works normally
- Backup: `/etc/nginx/nginx.conf.bak.20260405`

### ✅ Fix 2 — CrowdSec acquis updated
- Updated `/etc/crowdsec/acquis.d/fastpanel-nginx.yaml` to read only `/var/log/nginx/crowdsec-access.log`
- CrowdSec now correctly parses Combined format → IPs extracted → bans firing

### ✅ Fix 3 — CrowdSec scenarios (were already installed, confirmed active)
- `crowdsecurity/http-bad-user-agent` ✅
- `crowdsecurity/http-path-traversal-probing` ✅
- `crowdsecurity/http-sensitive-files` ✅
- `crowdsecurity/http-wordpress-scan` ✅
- `crowdsecurity/http-bf-wordpress_bf` ✅
- `crowdsecurity/http-probing` ✅
- `crowdsecurity/http-crawl-non_statics` ✅

### ✅ Fix 4 — clamd daemon disabled
- `systemctl stop clamav-daemon && systemctl disable clamav-daemon`
- `clamav-freshclam` enabled (DB updates still work)
- Manual scan still works via `clamscan` (no daemon needed)
- Freed: ~975 MB swap immediately

### 📊 Result
| Metric | Before | After |
|--------|--------|-------|
| Swap used | ~1.4 GB | ~439 MB |
| RAM available | ~259 MB | ~2.3 GB |
| CrowdSec HTTP bans | 0 | ✅ Firing |
| clamd swap usage | 975 MB | 0 (stopped) |

### ⚠️ Note about failed parser attempt
First attempt created `/etc/crowdsec/parsers/s01-parse/fastpanel-nginx-logs.yaml` with a custom grok parser.  
This **crashed CrowdSec** due to invalid expression `GeoIPCountry(...)` (function does not exist in CrowdSec expressions).  
The file was deleted and CrowdSec restarted. Correct solution was the dual nginx log approach (no custom parser needed).

---

## [2026-04-01] BOTH SERVERS — WordPress updater + cron

- Updated `wp_update_all.sh` to v2026-04-01
- WordPress cron (`wp-cron.php`) disabled on both servers
- System cron via WP-CLI replacing wp-cron on server 109
- `DISABLE_WP_CRON=true` set in all wp-config.php files

---

## [2026-03-25] SERVER 222 — PHP on-demand mode

- Added `fastpanel_php_ondemand_v2026-03-25.sh` to scripts/
- PHP-FPM pools switched to `pm=ondemand` on 222
- Added watchdog script running every 15 min via cron
- @reboot cron ensures on-demand mode survives reboots

---

## [2026-03-12] SERVER 109 — nginx + CrowdSec initial setup

- Installed CrowdSec v1.7.7
- Configured nginx bouncers
- Added CloudFlare real IP config
- Initial acquis.yaml setup for nginx + syslog logs
- Added webshell block in nginx (`✅ webshell block applied`)

---

```
= Rooted by VladiMIR | AI =
v2026-04-05
```
