# CHANGELOG

```
= Rooted by VladiMIR | AI =
```

All notable changes to server configurations, scripts and infrastructure.

Format: `[YYYY-MM-DD HH:MM] SERVER — Description`

---

## [2026-04-07 18:11] SERVER 109 — .bashrc fixed: aliases wpupd + reload permanently anchored

### Problem

```
root@109-ru-vds:~$ wpupd
wpupd: command not found
```

`wpupd` (and other aliases) disappeared after a session change / server event. The alias existed only in `.bashrc` but was never pinned to the repository as the source of truth.

### Root Cause

The `.bashrc` on server 109 was a **local-only file** with no connection to the repository. Whenever FastPanel updated, a new SSH session started without sourcing it, or `.bashrc` was accidentally overwritten, all aliases were lost.

Additionally, `wpupd`, `wpcron`, `wphealth`, `nginx-reload`, `fpm-reload`, and `reload-all` were **never added to `.bashrc`** in the first place.

### Fix Applied (2026-04-07 18:07)

**Repository:** `109/.bashrc` updated to `v2026-04-07`.

The following aliases were added:

| Alias | Command | Purpose |
|-------|---------|----------|
| `wpupd` | `bash wp_update_all.sh` | Update all WP plugins + themes |
| `wpcron` | `bash run_all_wp_cron.sh` | Run WP cron manually |
| `wphealth` | `bash wphealth.sh` | WP health check all sites |
| `nginx-reload` | `nginx -t && systemctl reload nginx` | Zero-downtime nginx reload |
| `fpm-reload` | `php-fpm8.3 -t && systemctl reload php8.3-fpm` | Zero-downtime php-fpm reload |
| `reload-all` | both reloads in sequence | Reload both at once |
| `repo` | `cd /root/Linux_Server_Public && git pull` | Update repo from GitHub |

### Self-Recovery Line Added to .bashrc

The `.bashrc` header now contains a one-liner to restore itself from the repo at any time:

```bash
# To restore:
curl -sS https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/109/.bashrc > ~/.bashrc && source ~/.bashrc
```

### How to Apply on Server (copy-paste once)

```bash
cd /root/Linux_Server_Public && git pull && \
cp /root/Linux_Server_Public/109/.bashrc ~/.bashrc && \
source ~/.bashrc && \
echo "=== Alias check ==" && \
type wpupd wpcron wphealth nginx-reload fpm-reload reload-all repo
```

### Why It Will Not Be Lost Again

- `109/.bashrc` in the repo is the **single source of truth**
- `repo` alias runs `git pull` — after every pull, `.bashrc` can be re-applied with `cp + source`
- The restore one-liner is printed in the `.bashrc` header — visible even if aliases are gone
- `nginx-reload` and `fpm-reload` aliases make it **impossible to accidentally run restart** from muscle memory

### Files Changed

| File | Change |
|------|--------|
| `109/.bashrc` | Added 7 new aliases, added self-recovery comment, bumped to v2026-04-07 |
| `109/server-info.md` | Added full Aliases section with table + restore procedure |
| `CHANGELOG.md` | This entry |

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

---

## [2026-04-07 15:34] SERVER 109 — novorr-art.ru + ugfp.ru fixes

### Problem 1: novorr-art.ru — WordPress updates blocked

**Symptom:** WordPress admin dashboard showed "WordPress 6.9.4 available" but the Update button was missing / greyed out.

**Root cause:** `DISALLOW_FILE_MODS = true` in `wp-config.php` completely disables WordPress file system operations — plugin installs, theme updates, **and WordPress core updates**.

**Fix applied:**
```php
// define('DISALLOW_FILE_EDIT', true); // disabled by VladiMIR 2026-04-07
// define('DISALLOW_FILE_MODS', true); // disabled by VladiMIR 2026-04-07
```
Backup: `wp-config.php.bak-2026-04-07-153421`

---

### Problem 2: ugfp.ru — 502 Bad Gateway on HTTPS

**Root cause:** `/etc/php/8.3/fpm/pool.d/ugfp.ru.conf` was **completely absent**.

**Fix applied:** Created `ugfp.ru.conf` with `pm=ondemand`, user=ugfp.

> ⚠️ **Note:** Script used `systemctl restart php8.3-fpm` which caused 1–3 sec downtime
> on ALL sites. Should have used `systemctl reload php8.3-fpm`. See `OPERATIONS.md`.

**Verification:** ugfp.ru HTTPS 200 ✅, wp-login 200 ✅

---

## [2026-04-07 15:00] REPO — 222/server-info.md created, session 04-05 / 04-07 documented

---

## [2026-04-07 11:51] SERVER 109 — nail-space-ekb.ru /wp-admin/ 403 fix

**Root Cause:** `meta_crawler_block.conf` had `wp-admin` in a global regex location (`~*`) which overrides prefix locations — blocked ALL wp-admin server-wide.

**Fix:** Removed `wp-admin` from the regex. Backup created.

---

## [2026-04-05 15:27] SERVER 222 — CrowdSec nginx fix

**Cause:** nginx `log_format fastpanel` starts with `[$time_local]`, not `$remote_addr`. CrowdSec couldn't parse IPs → 0 bans.

**Fix:** Added `log_format combined_crowdsec` + second `access_log`. CrowdSec immediately started banning.

---

## [2026-04-05] SERVER 109 — CrowdSec fix + clamd disable

- Added dual nginx log format for CrowdSec
- Disabled `clamav-daemon` (freed ~975 MB swap)
- CrowdSec bans: 0 → ✅ 56 active

---

## [2026-04-01] BOTH SERVERS — WordPress updater + cron

- Updated `wp_update_all.sh` to v2026-04-01
- `DISABLE_WP_CRON=true` set in all wp-config.php

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
