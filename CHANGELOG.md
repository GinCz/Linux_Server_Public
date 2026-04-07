# CHANGELOG

```
= Rooted by VladiMIR | AI =
```

All notable changes to server configurations, scripts and infrastructure.

Format: `[YYYY-MM-DD HH:MM] SERVER — Description`

---

## [2026-04-07 18:00] REPO — OPERATIONS.md created (zero-downtime rules)

### What was added

Created `OPERATIONS.md` — a permanent operations guide covering the correct use of
`reload` vs `restart` for nginx and php-fpm on production servers.

**Triggered by incident:** On 2026-04-07 at ~15:34 CEST, `systemctl restart php8.3-fpm`
caused 1–3 seconds of downtime across all 28 sites on server 109 while creating
the missing PHP-FPM pool for `ugfp.ru`. The correct command was `systemctl reload php8.3-fpm`.

### Document covers
- Full comparison table: `reload` vs `restart` for nginx and php-fpm
- Exact internal behavior of each command (what happens to workers, sockets, connections)
- Decision table: when to use `restart` (acceptable cases only)
- Complete postmortem of the 2026-04-07 incident with root cause
- Safe config change sequence — copy-paste template for all future changes
- Quick reference card (ASCII) for terminal use

### Key rule documented

```bash
# ✅ ALWAYS — zero downtime
php-fpm8.3 -t && systemctl reload php8.3-fpm
nginx -t    && systemctl reload nginx

# ❌ NEVER during working hours (unless binary updated or process frozen)
systemctl restart php8.3-fpm
systemctl restart nginx
```

### README.md updated
- Added Rule #6: Always use reload, never restart
- Added link to OPERATIONS.md in Rules section
- Updated `Last updated` date

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
// define('DISALLOW_FILE_EDIT', true); // disabled by VladiMIR 2026-04-07
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

---

### Problem 2: ugfp.ru — 502 Bad Gateway on HTTPS

**Symptom:** `https://ugfp.ru/wp-login.php` returned 502 Bad Gateway.

**Root cause:** `/etc/php/8.3/fpm/pool.d/ugfp.ru.conf` was **completely absent**.
FastPanel either never created it or it was accidentally deleted.
Without the pool config, php8.3-fpm never creates the socket → nginx gets
"No such file or directory" → 502.

**Fix applied (2026-04-07 15:34):**
Created `/etc/php/8.3/fpm/pool.d/ugfp.ru.conf` with `pm=ondemand`, user=ugfp.

> ⚠️ **Note:** Script used `systemctl restart php8.3-fpm` which caused 1–3 sec downtime
> on ALL sites. Should have used `systemctl reload php8.3-fpm`. See `OPERATIONS.md`.

**Verification:**
```
Socket: /var/run/ugfp.ru.sock  srw-rw---- 1 www-data www-data
ugfp.ru HTTPS:    200 ✅
ugfp.ru wp-login: 200 ✅ (was 502)
```

---

## [2026-04-07 15:00] REPO — 222/server-info.md created, full session 04-05 / 04-07 documented

- Created `222/server-info.md`
- Updated `CHANGELOG.md` — added full documentation of the 05-07 April sessions
- Updated `README.md` — added rules, structure, known issues

---

## [2026-04-07 11:51] SERVER 109 — nail-space-ekb.ru /wp-admin/ 403 fix

### Problem
`https://nail-space-ekb.ru/wp-admin/` returned **403 Forbidden** (nginx/1.28.3).

### Root Cause
File `/etc/nginx/fastpanel2-includes/meta_crawler_block.conf` contained a **global regex location**:
```nginx
location ~* ^/(basket|cart|checkout|wp-admin|wp-cron\.php) {
```
nginx regex locations (`~*`) have higher priority than prefix locations (`/wp-admin/`),
so the global block was catching ALL `/wp-admin/` requests server-wide.

### Fix Applied
```nginx
# Before:
location ~* ^/(basket|cart|checkout|wp-admin|wp-cron\.php) {
# After:
location ~* ^/(basket|cart|checkout|wp-cron\.php) {
```
Backup: `/etc/nginx/fastpanel2-includes/meta_crawler_block.conf.bak.2026-04-07-114818`

### Verification
```
nginx -t        → syntax is ok
/wp-admin/      → 302 ✅
CrowdSec bans   → 61 active
```

---

## [2026-04-05 15:27] SERVER 222 — CrowdSec root cause confirmed + nginx fix script ready

**Cause:** nginx `log_format fastpanel` starts with `[$time_local]`, not `$remote_addr`.
CrowdSec nginx parser can't extract IPs → 1200+ alerts detected but 0 automatic bans.

**Fix:** Added `log_format combined_crowdsec` + second `access_log` to nginx.conf.
CrowdSec immediately started banning after fix.

**Status: ✅ CrowdSec banning — WORKING on server 222**

**DISABLE_WP_CRON:** `timan-kuchyne.cz` still missing — **⚠️ NOT YET FIXED**

---

## [2026-04-05] SERVER 109 — CrowdSec fix + clamd disable

- Added dual nginx log format for CrowdSec compatibility
- Disabled `clamav-daemon` (freed ~975 MB swap)
- CrowdSec HTTP bans: 0 → ✅ 56 active

---

## [2026-04-01] BOTH SERVERS — WordPress updater + cron

- Updated `wp_update_all.sh` to v2026-04-01
- `DISABLE_WP_CRON=true` set in all wp-config.php files

---

## [2026-03-25] SERVER 222 — PHP on-demand mode

- PHP-FPM pools switched to `pm=ondemand`

---

## [2026-03-12] SERVER 109 — nginx + CrowdSec initial setup

- Installed CrowdSec v1.7.7
- Configured nginx bouncers

---

```
= Rooted by VladiMIR | AI =
v2026-04-07
```
