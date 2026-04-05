# CHANGELOG

```
= Rooted by VladiMIR | AI =
```

All notable changes to server configurations, scripts and infrastructure.

Format: `[YYYY-MM-DD] SERVER — Description`

---

## [2026-04-05 15:17] SERVER 222 — Load report + wowflow.cz webshell scan + CrowdSec low bans

### Load Report (last 1h, 15:17 CEST)

**Total requests: 462 676**

Top sites:
1. **svetaform.eu** — 315 422 total requests (front + back) — **abnormally high**, needs Cloudflare analytics check
2. abl-metal.com — 6 822
3. czechtoday.eu — 12 687 total

Active PHP pools with high CPU:
- `timan-kuchyne.cz` (nata_po) — **18.3% CPU** (2 workers) — elevated
- `doska-cz.ru` (doski) — 11.5%
- `lybawa.com` (gadanie) — 7.4%

Attack traffic:
- `/wp-login.php` — **5 788 hits/hour** — active brute force
- `/wp-cron.php` — **191 hits** — should be 0, some sites may not have DISABLE_WP_CRON set

### wowflow.cz — Webshell Scan

Three attack sessions detected in error log:

1. **07:17 — `2.58.56.31` (NL, BlueVPS)** — 4 webshell probes:
   - `/wp-content/plugins/fix/up.php` — upload webshell
   - `/wp-content/themes/seotheme/db.php` — known "seotheme" malware shell
   - `/wp-content/plugins/apikey/apikey.php` — API key steal
   - `/plugins/content/apismtp/apismtp.php` — SMTP credential steal

2. **11:39–11:41 — `20.104.201.101` (US, Azure)** — 3 probes:
   - `/.well-known/index.php`, `siteindex.php`, `fm.php` — file manager webshell probes

3. **14:58 — `87.121.84.44` (CZ)** — 1 probe:
   - `/admin/assets/plugins/plupload/examples/upload.php` — file upload exploit

**Result:** All probes returned "Primary script unknown" — **files don't exist, attacks failed**.

**Action needed:** Manually ban attacker IPs, investigate why CrowdSec didn't auto-ban.

### CrowdSec — Only 3 Active Bans (Suspected Issue)

Given 5 788 wp-login hits and 3 webshell scan sessions, **3 bans is far too low**.  
Same root cause suspected as on server 109: FastPanel nginx log format not parseable by CrowdSec.  
Action needed: check `cscli metrics` and nginx acquis config on server 222.

---

## [2026-04-05 14:58] SERVER 109 — Load report + mariela.ru AH01630 analysis

### Load Report (last 1h, 14:58 CEST)

**Total requests: 69 755**

Top sites:
1. shapkioptom.ru — 10 912 total (6 450 front + 4 462 back)
2. news-port.ru — 9 404 total (5 100 front + 4 304 back)
3. 4ton-96.ru — 3 277 front

Active PHP pools: foton (4ton-96.ru), palantins (shapkioptom.ru), vobs (stuba-dom.ru)

Attack traffic:
- `/wp-login.php` — **2 986 hits in 1h** — active brute force
- CrowdSec active bans: **56** — working correctly

### mariela.ru — AH01630 Errors

- Chinese Baidu crawler (`116.179.32.x`, `220.181.108.x`) hitting `/katalog`, `/otbor`
- DigitalOcean scanner (`170.64.225.6`) probing `/.env`
- **Status:** Blocks working correctly, no action needed

---

## [2026-04-05] SERVER 109 — CrowdSec fix + clamd disable

### 🔴 Problem
- CrowdSec was running but **NOT banning any HTTP attackers**
- `clamd` consuming **975 MB swap** continuously

### 🔍 Root Cause
FastPanel nginx log format has `[$time_local]` as first field instead of `$remote_addr`.  
CrowdSec parser couldn't extract IP addresses → zero bans.

### ✅ Fix 1 — nginx dual logging
- Added `log_format combined_crowdsec` to `/etc/nginx/nginx.conf`
- Added `access_log /var/log/nginx/crowdsec-access.log combined_crowdsec;`
- FastPanel native log unchanged
- Backup: `/etc/nginx/nginx.conf.bak.20260405`

### ✅ Fix 2 — CrowdSec acquis updated
- `/etc/crowdsec/acquis.d/fastpanel-nginx.yaml` now reads `/var/log/nginx/crowdsec-access.log`
- CrowdSec banning immediately after fix

### ✅ Fix 3 — clamd disabled
- `systemctl stop clamav-daemon && systemctl disable clamav-daemon`
- Freed ~975 MB swap
- Manual scan still works via `clamscan`

| Metric | Before | After |
|--------|--------|-------|
| Swap used | ~1.4 GB | ~439 MB |
| CrowdSec HTTP bans | 0 | ✅ Firing |

### ⚠️ Failed attempt: custom grok parser
Created `/etc/crowdsec/parsers/s01-parse/fastpanel-nginx-logs.yaml` → crashed CrowdSec (invalid `GeoIPCountry()` expression). File deleted.

---

## [2026-04-01] BOTH SERVERS — WordPress updater + cron

- Updated `wp_update_all.sh` to v2026-04-01
- WordPress cron (`wp-cron.php`) disabled on both servers
- `DISABLE_WP_CRON=true` set in all wp-config.php files
- System cron via WP-CLI replacing wp-cron on server 109

---

## [2026-03-25] SERVER 222 — PHP on-demand mode

- Added `fastpanel_php_ondemand_v2026-03-25.sh`
- PHP-FPM pools switched to `pm=ondemand`
- Watchdog script every 15 min
- @reboot cron for persistence

---

## [2026-03-12] SERVER 109 — nginx + CrowdSec initial setup

- Installed CrowdSec v1.7.7
- Configured nginx bouncers
- Added CloudFlare real IP config
- Initial acquis.yaml for nginx + syslog
- Added webshell block in nginx

---

```
= Rooted by VladiMIR | AI =
v2026-04-05
```
