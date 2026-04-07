# CHANGELOG

```
= Rooted by VladiMIR | AI =
```

All notable changes to server configurations, scripts and infrastructure.

Format: `[YYYY-MM-DD HH:MM] SERVER — Description`

---

## [2026-04-07 15:34] SERVER 109 — novorr-art.ru + ugfp.ru fixes

### Problem 1: novorr-art.ru — WordPress updates blocked

**Symptom:** WordPress admin dashboard showed "WordPress 6.9.4 available" but the Update button was missing / greyed out. The logged-in user (gincz, ID=1) appeared to have no admin permissions despite being the only user on the site.

**Investigation steps:**
1. Checked DB — role `a:1:{s:13:"administrator";b:1;}` was correct for user ID=1
2. WP-CLI confirmed `roles: administrator` and `update_core` capability present
3. Not multisite — `sitemeta` table empty
4. Found the actual cause in `wp-config.php`:

```php
// Lines 117-118 in wp-config.php BEFORE fix:
define('DISALLOW_FILE_EDIT', true);
define('DISALLOW_FILE_MODS', true);  // <-- THIS blocks ALL updates
```

**Root cause:** `DISALLOW_FILE_MODS = true` completely disables WordPress file system operations — plugin installs, theme updates, **and WordPress core updates**. This is a security hardening constant that was set at some point and forgotten. The user role and capabilities were 100% correct all along.

**Fix applied (2026-04-07 15:34):**
- Backup created: `wp-config.php.bak-2026-04-07-153421`
- Both constants commented out (not deleted — can be re-enabled if needed):

```php
// Line 117 AFTER fix:
// define('DISALLOW_FILE_EDIT', true); // disabled by VladiMIR 2026-04-07
// Line 118 AFTER fix:
// define('DISALLOW_FILE_MODS', true); // disabled by VladiMIR 2026-04-07
```

**Verification:**
```
wp core check-update:
+---------+-------------+--------------------------------------------------------------+
| version | update_type | package_url                                                  |
+---------+-------------+--------------------------------------------------------------+
| 6.9.4   | minor       | https://downloads.wordpress.org/release/ru_RU/wordpress-6.9.4.zip |
+---------+-------------+--------------------------------------------------------------+
✅ Update button now visible in wp-admin dashboard
```

**wp-config.php path:** `/var/www/novorr/data/www/novorr-art.ru/wp-config.php`  
**WP version before fix:** 6.9.1  
**WP version available:** 6.9.4 (minor, ru_RU)

**Active plugins on this site (as of 2026-04-07):**
- 404-to-301, classic-editor, cyr2lat, head-meta-data, imsanity
- instagram-feed, manage-notification-emails, nextgen-gallery
- tinymce-advanced, wpforms-lite, wp-seopress, youtube-embed-plus

> ⚠️ **Note:** `FS_METHOD = 'direct'` was already correctly set (line 106) — this was not the problem.

---

### Problem 2: ugfp.ru — 502 Bad Gateway on HTTPS

**Symptom:** `https://ugfp.ru/wp-login.php` returned 502 Bad Gateway. HTTP (port 80) returned 301 (redirect), HTTPS returned 502 for all PHP pages.

**Investigation steps:**
1. `/var/run/ugfp.ru.sock` — **missing** (not in `ls /var/run/*.sock`)
2. `find /etc/php -name "*.conf" -path "*/fpm/pool.d/*"` — **no ugfp.ru.conf found** in any PHP version
3. nginx config `/etc/nginx/fastpanel2-sites/ugfp/ugfp.ru.conf` exists and references `unix:/var/run/ugfp.ru.sock`
4. PHP version on server: only **php8.3-fpm** is active
5. User `ugfp` exists: `uid=1048(ugfp) gid=1051(ugfp)`
6. Site files exist: `/var/www/ugfp/data/www/ugfp.ru/wp-config.php` — present

**Root cause:** PHP-FPM pool configuration file for `ugfp.ru` was **completely absent** from `/etc/php/8.3/fpm/pool.d/`. FastPanel either never created it or it was accidentally deleted. Without the pool config, php8.3-fpm never creates the socket → nginx gets "No such file or directory" → 502.

**Fix applied (2026-04-07 15:34):**
Created `/etc/php/8.3/fpm/pool.d/ugfp.ru.conf` with the following content:

```ini
; PHP-FPM pool for ugfp.ru
; = Rooted by VladiMIR | AI =
; v2026-04-07 | Server: 109-RU-FastVDS

[ugfp.ru]
user = ugfp
group = ugfp
listen = /var/run/ugfp.ru.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = ondemand
pm.max_children = 5
pm.process_idle_timeout = 10s
pm.max_requests = 200

slowlog = /var/log/php8.3-fpm-ugfp.ru.log.slow
request_slowlog_timeout = 10s

php_admin_value[upload_max_filesize] = 64M
php_admin_value[post_max_size] = 64M
php_admin_value[memory_limit] = 256M
php_admin_value[max_execution_time] = 120
php_admin_value[error_log] = /var/log/php8.3-fpm-ugfp.ru.log
php_admin_flag[log_errors] = on
```

**Commands executed:**
```bash
php-fpm8.3 -t                    # → configuration file test is successful
systemctl restart php8.3-fpm    # socket created
nginx -t && systemctl reload nginx
```

**Verification:**
```
Socket created: /var/run/ugfp.ru.sock  srw-rw---- 1 www-data www-data
ugfp.ru HTTPS:       200  ✅
ugfp.ru wp-login:    200  ✅ (was 502)
```

---

## [2026-04-07 15:00] REPO — 222/server-info.md created, full session 04-05 / 04-07 documented

**What was done in this session (07.04.2026 ~15:00 CEST):**
- Created `222/server-info.md` — it was completely missing before (only individual config files existed in `/222/`)
- Updated `CHANGELOG.md` — added full documentation of the 05-07 April sessions
- Updated `README.md` — added rules, structure, known issues

---

## [2026-04-07 11:51] SERVER 109 — nail-space-ekb.ru /wp-admin/ 403 fix

### Problem
`https://nail-space-ekb.ru/wp-admin/` returned **403 Forbidden** (nginx/1.28.3).  
Main site `/` was working fine. Other sites on the same server were NOT affected.

### Root Cause
File `/etc/nginx/fastpanel2-includes/meta_crawler_block.conf` contained a **global regex location** applied to ALL sites:
```nginx
location ~* ^/(basket|cart|checkout|wp-admin|wp-cron\.php) {
```
`wp-admin` was included in this regex to block Meta bots from the admin area.  
However, nginx regex locations (`~*`) have **higher priority** than prefix locations (`/wp-admin/`), so the global block was catching ALL `/wp-admin/` requests server-wide — before the per-site PHP handler could process them.  
Since this block used `try_files $uri $uri/ /index.php?$args` without a PHP fastcgi pass, nginx tried to serve `/wp-admin/` as a static directory — found no `autoindex on` — and returned 403.  
The reason only `nail-space-ekb.ru` was visibly affected: other WooCommerce sites (shapkioptom.ru etc.) have their own `location ~* /wp-admin` blocks in their per-site configs that overrode the global one. `nail-space-ekb.ru` had no such override.

### Fix Applied
Removed `|wp-admin` from the regex in `/etc/nginx/fastpanel2-includes/meta_crawler_block.conf`:

```nginx
# Before:
location ~* ^/(basket|cart|checkout|wp-admin|wp-cron\.php) {

# After:
location ~* ^/(basket|cart|checkout|wp-cron\.php) {
```

Backup created: `/etc/nginx/fastpanel2-includes/meta_crawler_block.conf.bak.2026-04-07-114818`

### Why this is safe
- `/wp-admin/` protection is handled by **CrowdSec** (scenario `http-wordpress-scan`, `http-bf-wordpress_bf`)
- Meta bots do not target `/wp-admin/` — they target WooCommerce endpoints (cart/checkout/ajax)
- All WooCommerce-specific blocks remain intact

### Verification
```
nginx -t          → syntax is ok
HTTP /wp-admin/   → 302  ✅ (redirect to login — correct)
HTTP /            → 301  ✅ (www → non-www redirect)
CrowdSec bans     → 61 active
```

---

## [2026-04-05 15:27] SERVER 222 — CrowdSec root cause confirmed + nginx fix script ready

### Root Cause Confirmed

`cscli metrics` clearly shows:
- `crowdsec (security engine)` active_decisions = **0** — local engine makes ZERO bans
- `cscli (manual decisions)` = only 3 — all manual
- `CAPI community blocklist` = 25,940 — working (cloud-based), but no local analysis

**Cause:** Same as server 109.  
nginx `log_format fastpanel` starts with `[$time_local]`, not `$remote_addr`.  
CrowdSec nginx parser can't extract IPs → 1200+ alerts detected but 0 automatic bans.

### Fix Applied

Script created and executed: `222/fix_nginx_crowdsec_222_v2026-04-05.sh`

Fix steps performed:
1. Backed up `/etc/nginx/nginx.conf` → `/etc/nginx/nginx.conf.bak.20260405`
2. Added `log_format combined_crowdsec` to nginx.conf
3. Added second `access_log /var/log/nginx/crowdsec-access.log combined_crowdsec`
4. Reloaded nginx — `nginx -t` → OK, `systemctl reload nginx` → ✅
5. Added `crowdsec-access.log` to `/etc/crowdsec/acquis.yaml`
6. Restarted CrowdSec: `systemctl restart crowdsec`

### Result — nginx.conf log section after fix

```nginx
log_format fastpanel '[$time_local] $host $server_addr $remote_addr $status $body_bytes_sent $request_time $request $http_referer $http_user_agent';
log_format combined_crowdsec '$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"';
access_log  /var/log/nginx/access.log fastpanel;
access_log  /var/log/nginx/crowdsec-access.log combined_crowdsec;
sendfile        on;
keepalive_timeout  65;
```

```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
✅ nginx reloaded — dual logging active
● crowdsec.service Active: active (running) since Sun 2026-04-05 14:47:57 CEST
```

### CrowdSec decisions after 60s wait

| ID | Source | IP | Reason | Action | Country |
|----|--------|----|--------|--------|---------|
| 6117736 | crowdsec | 2.57.121.17 | ssh-bf | ban | RO |
| 6117735 | crowdsec | 4.193.168.228 | http-crawl-non_statics | ban | SG (MS) |
| 6117733 | crowdsec | 129.211.218.15 | ssh-slow-bf | ban | CN (Tencent) |
| 6117732 | crowdsec | 31.57.216.187 | http-bf-wordpress_bf | ban | AE |
| 6117730 | crowdsec | 43.153.34.199 | ssh-bf | ban | US (Tencent) |
| 6117729 | crowdsec | 20.151.229.110 | http-wordpress-scan | ban | CA (MS) |
| 6117726 | crowdsec | 52.243.57.116 | http-probing | ban | JP (MS) |
| 6117725 | crowdsec | 20.194.110.188 | http-probing | ban | KR (MS) |
| 6117724 | crowdsec | 104.243.43.7 | http-crawl-non_statics | ban | US |
| 6102723 | crowdsec | 20.89.241.241 | http-crawl-non_statics | ban | JP (MS) |
| 6102721 | crowdsec | 2.57.121.86 | ssh-bf | ban | RO |

**Status: ✅ CrowdSec banning — WORKING on server 222**

### DISABLE_WP_CRON — timan-kuchyne.cz missing

- 44 sites checked, 43 have `DISABLE_WP_CRON=true`
- **MISSING:** `/var/www/nata_popkova/data/www/timan-kuchyne.cz/wp-config.php`
- Fix needed: add `define( 'DISABLE_WP_CRON', true );` to that file
- **Status: ⚠️ NOT YET FIXED as of 2026-04-07**

---

## [2026-04-05 15:17] SERVER 222 — Load report + wowflow.cz webshell scan

### Load Report (last 1h, 15:17 CEST)

**Total requests: 462 676**

Top sites:
1. **svetaform.eu** — 315 422 total requests (front + back) — abnormally high
2. abl-metal.com — 6 822
3. czechtoday.eu — 12 687 total

Active PHP pools with high CPU:
- `timan-kuchyne.cz` (nata_popkova) — **18.3% CPU** (2 workers)
- `doska-cz.ru` (doski) — 11.5%
- `lybawa.com` (gadanie) — 7.4%

Attack traffic:
- `/wp-login.php` — **5 788 hits/hour**
- `/wp-cron.php` — **191 hits** — DISABLE_WP_CRON missing on timan-kuchyne.cz

### wowflow.cz — Webshell Scan

Three attack sessions — all failed (files don't exist):
1. 07:17 — `2.58.56.31` (NL, BlueVPS) — 4 webshell probes incl. seotheme
2. 11:39–11:41 — `20.104.201.101` (US, Azure) — 3 .well-known PHP probes
3. 14:58 — `87.121.84.44` (CZ) — plupload upload.php exploit probe

All blocked. No files exist. No action required.

---

## [2026-04-05 14:58] SERVER 109 — Load report + mariela.ru AH01630 analysis

### Load Report (last 1h, 14:58 CEST)

**Total requests: 69 755**

Top sites:
1. shapkioptom.ru — 10 912 total (6 450 front + 4 462 back)
2. news-port.ru — 9 404 total (5 100 front + 4 304 back)
3. 4ton-96.ru — 3 277 front

Attack traffic:
- `/wp-login.php` — **2 986 hits in 1h**
- CrowdSec active bans: **56** — working correctly

### mariela.ru — AH01630 Errors

- Chinese Baidu crawler (`116.179.32.x`, `220.181.108.x`) — blocks working correctly
- DigitalOcean scanner (`170.64.225.6`) probing `/.env` — blocked
- **Verdict:** This is CORRECT behaviour. Blocks are working. No action needed.

---

## [2026-04-05] SERVER 109 — CrowdSec fix + clamd disable

### Problem
- CrowdSec NOT banning HTTP attackers
- `clamd` consuming 975 MB swap

### Root Cause
FastPanel nginx log_format has `[$time_local]` as first field instead of `$remote_addr`.  
CrowdSec parser couldn't extract IP addresses → zero bans.

### Fixes Applied
1. Added `log_format combined_crowdsec` to `/etc/nginx/nginx.conf`
2. Added `access_log /var/log/nginx/crowdsec-access.log combined_crowdsec`
3. Updated `/etc/crowdsec/acquis.d/fastpanel-nginx.yaml` to read new log
4. Disabled `clamav-daemon` (freed ~975 MB swap)

| Metric | Before | After |
|--------|--------|-------|
| Swap used | ~1.4 GB | ~439 MB |
| RAM available | ~259 MB | ~2.3 GB |
| CrowdSec HTTP bans | 0 | ✅ Firing |
| CrowdSec active bans | 0 local | 56 local |

---

## [2026-04-01] BOTH SERVERS — WordPress updater + cron

- Updated `wp_update_all.sh` to v2026-04-01
- `DISABLE_WP_CRON=true` set in all wp-config.php files
- System cron via WP-CLI replacing wp-cron on server 109

---

## [2026-03-25] SERVER 222 — PHP on-demand mode

- PHP-FPM pools switched to `pm=ondemand`
- Watchdog script every 15 min
- @reboot cron for persistence

---

## [2026-03-12] SERVER 109 — nginx + CrowdSec initial setup

- Installed CrowdSec v1.7.7
- Configured nginx bouncers
- Added CloudFlare real IP config
- Initial acquis.yaml for nginx + syslog

---

```
= Rooted by VladiMIR | AI =
v2026-04-07
```
