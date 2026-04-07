# CHANGELOG

```
= Rooted by VladiMIR | AI =
```

All notable changes to server configurations, scripts and infrastructure.

Format: `[YYYY-MM-DD HH:MM] SERVER — Description`

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

### Cleanup
- `/etc/nginx/fastpanel2-sites/valeriia/nail-space-ekb.ru.includes` — empty (no extra rules needed)
- `/etc/nginx/fastpanel2-sites/valeriia/nail-space-ekb.ru.conf` — unchanged from FastPanel default
- Backup files kept: `nail-space-ekb.ru.conf.bak.2026-04-07-114413`, `meta_crawler_block.conf.bak.2026-04-07-114818`

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

### Fix

Script created: `222/fix_nginx_crowdsec_222_v2026-04-05.sh`

Fix steps:
1. Backup `/etc/nginx/nginx.conf` → `nginx.conf.bak.20260405`
2. Add `log_format combined_crowdsec` to nginx.conf
3. Add second `access_log /var/log/nginx/crowdsec-access.log combined_crowdsec`
4. Reload nginx
5. Add crowdsec-access.log to `/etc/crowdsec/acquis.yaml`
6. Restart CrowdSec

Owner's decision: **do not run manually — apply the fix script** `fix_nginx_crowdsec_222_v2026-04-05.sh`.

### DISABLE_WP_CRON — timan-kuchyne.cz missing

- 44 sites checked, 43 have `DISABLE_WP_CRON=true`
- **MISSING:** `/var/www/nata_popkova/data/www/timan-kuchyne.cz/wp-config.php`
- Fix: add `define( 'DISABLE_WP_CRON', true );` to that file

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
| CrowdSec HTTP bans | 0 | ✅ Firing |

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
