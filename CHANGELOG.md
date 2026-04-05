# CHANGELOG

```
= Rooted by VladiMIR | AI =
```

All notable changes to server configurations, scripts and infrastructure.

Format: `[YYYY-MM-DD] SERVER — Description`

---

## [2026-04-05 14:58] SERVER 109 — Load report + mariela.ru AH01630 analysis

### Load Report (last 1h, 14:58 CEST)

**Total requests: 69 755**

Top sites:
1. shapkioptom.ru — 10 912 total (6 450 front + 4 462 back)
2. news-port.ru — 9 404 total (5 100 front + 4 304 back)
3. 4ton-96.ru — 3 277 front

Active PHP pools with CPU load: foton (4ton-96.ru), palantins (shapkioptom.ru), vobs (stuba-dom.ru)

**Attack traffic:**
- `/wp-login.php` — **2 986 hits in 1h** — active brute force
- CrowdSec active bans: **56**
- CrowdSec correctly banning WordPress BF, probing, SSH BF attackers

### mariela.ru — AH01630 Errors

- Errors in `/var/www/palantins/data/logs/mariela.ru-backend.error.log`
- Error: `AH01630: client denied by server configuration` on `/katalog`, `/otbor`, `/.env`
- **Cause:** Chinese Baidu crawler (`116.179.32.x`, `220.181.108.x`) hitting protected directories; DigitalOcean scanner (`170.64.225.6`) probing `/.env`
- **Status:** NOT a problem — blocks are working correctly (`.htaccess` / `<Directory>` deny rules in place)
- **No server action needed.** Optional: add these CIDRs to CrowdSec or nginx geo block

### CrowdSec — Confirmed Working

Sample new decisions since fix:
- `20.205.1.146` (HK, Microsoft) — http-crawl-non_statics → banned
- `20.199.99.25` (FR, Microsoft) — http-probing + http-crawl → banned
- `4.193.168.228` (SG, Microsoft) — http-probing + http-crawl → banned
- `129.211.218.15` (CN, Tencent) — ssh-slow-bf → banned
- `31.57.216.187` (AE, Pentech) — wordpress-bf + probing → banned

> Note: Multiple **Azure (Microsoft) IPs** being used as attack proxies — normal pattern, CrowdSec handles it.

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

### ✅ Fix 3 — CrowdSec scenarios (confirmed active)
- All 8 HTTP + SSH scenarios confirmed enabled and firing

### ✅ Fix 4 — clamd daemon disabled
- `systemctl stop clamav-daemon && systemctl disable clamav-daemon`
- `clamav-freshclam` enabled (DB updates still work)
- Manual scan still works via `clamscan`
- Freed: ~975 MB swap immediately

### 📊 Result
| Metric | Before | After |
|--------|--------|-------|
| Swap used | ~1.4 GB | ~439 MB |
| RAM available | ~259 MB | ~2.3 GB |
| CrowdSec HTTP bans | 0 | ✅ Firing |
| clamd swap usage | 975 MB | 0 |

### ⚠️ Note about failed parser attempt
First attempt: created custom grok parser `/etc/crowdsec/parsers/s01-parse/fastpanel-nginx-logs.yaml`.  
This **crashed CrowdSec** due to invalid `GeoIPCountry(...)` expression (function not available).  
File was deleted, CrowdSec restarted. Correct solution: dual nginx log (no custom parser needed).

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
- Added webshell block in nginx

---

```
= Rooted by VladiMIR | AI =
v2026-04-05
```
