# Server 109 — 109-RU-FastVDS

```
= Rooted by VladiMIR | AI =
v2026-04-07
```

## Hardware & Access

| Parameter | Value |
|-----------|-------|
| Hostname | `109-ru-vds` |
| IP | `212.109.223.109` |
| Provider | FastVDS.ru (Russia) |
| Tariff | VDS-KVM-NVMe-Otriv-10.0 |
| CPU | 4 vCore AMD EPYC 7763 |
| RAM | 8 GB |
| Disk | 80 GB NVMe |
| OS | Ubuntu 24 LTS |
| Panel | FASTPANEL |
| Cloudflare | ❌ No (direct IP) |
| Price | 13 €/mo |
| SSH | `ssh root@212.109.223.109` |

---

## Aliases & .bashrc — Source of Truth

> ⚠️ **IMPORTANT:** The file `109/.bashrc` in this repository is the **single source of truth** for all aliases on server 109.  
> The local `~/.bashrc` on the server must always match this file.  
> Any new alias must be added here first, then applied on the server.

### How to restore all aliases (if lost)

```bash
# Option 1: from repo (recommended)
cd /root/Linux_Server_Public && git pull && \
cp /root/Linux_Server_Public/109/.bashrc ~/.bashrc && \
source ~/.bashrc

# Option 2: directly from GitHub (if repo not yet pulled)
curl -sS https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/109/.bashrc > ~/.bashrc && source ~/.bashrc
```

### Why aliases disappear

Aliases live in `~/.bashrc`. They are lost when:
- FastPanel overwrites or resets `~/.bashrc` during an update
- A new root session starts without sourcing `.bashrc` (e.g. `su -` or certain cron contexts)
- Server is rebuilt / reinstalled
- Someone manually edits `.bashrc` and removes lines

**Solution:** `109/.bashrc` in the repo is always the master copy. After any loss, restore with the one-liner above.

### Complete Alias Reference (v2026-04-07)

| Alias | Full Command | Purpose |
|-------|--------------|---------|
| `00` | `clear` | Clear terminal |
| `infooo` | `bash .../infooo.sh` | Server info dashboard |
| `domains` | `bash .../domains.sh` | List all domains |
| `sos` | `bash .../sos.sh 1h` | SOS report last 1h |
| `sos3` | `bash .../sos.sh 3h` | SOS report last 3h |
| `sos24` | `bash .../sos.sh 24h` | SOS report last 24h |
| `sos120` | `bash .../sos.sh 120h` | SOS report last 120h |
| `fight` | `bash .../block_bots.sh` | Block bots manually |
| `watchdog` | `bash .../php_fpm_watchdog.sh` | PHP-FPM watchdog |
| `backup` | `bash .../system_backup.sh` | Run system backup |
| `antivir` | `bash .../scan_clamav.sh` | ClamAV manual scan |
| `mailclean` | `bash .../mailclean.sh` | Clean mail queue |
| `cleanup` | `bash .../server_cleanup.sh` | Server cleanup |
| `aws-test` | `bash .../aws_test.sh` | AWS connectivity test |
| `banlog` | `cscli alerts list -l 20` | Last 20 CrowdSec bans |
| `allinfo` | `bash .../all_servers_info.sh` | RAM+disk all servers |
| **`wpupd`** | `bash .../wp_update_all.sh` | ✅ **Update all WP plugins+themes** |
| **`wpcron`** | `bash .../run_all_wp_cron.sh` | ✅ **Run WP cron manually** |
| **`wphealth`** | `bash .../wphealth.sh` | ✅ **WP health check all sites** |
| **`nginx-reload`** | `nginx -t && systemctl reload nginx` | ✅ **Zero-downtime nginx reload** |
| **`fpm-reload`** | `php-fpm8.3 -t && systemctl reload php8.3-fpm` | ✅ **Zero-downtime php-fpm reload** |
| **`reload-all`** | fpm-reload + nginx-reload | ✅ **Both reloads at once** |
| **`repo`** | `cd /root/Linux_Server_Public && git pull` | ✅ **Pull latest from GitHub** |

> **Bold aliases** were added on 2026-04-07. `wpupd` was previously missing entirely — that caused `command not found` errors.

### Alias incident — 2026-04-07 18:11

User typed `wpupd` and got `command not found`. Investigation showed:
1. `wpupd` was documented in README but **never actually written to `.bashrc`**
2. `.bashrc` existed only locally on the server with no GitHub backup
3. There was no self-recovery mechanism if `.bashrc` was lost

**Fix:** Added all missing aliases to `109/.bashrc`, added self-recovery line, added `reload-all` / `nginx-reload` / `fpm-reload` aliases to prevent future accidental `restart` usage.

---

## Sites Hosted

| Domain | User | Notes |
|--------|------|-------|
| comfort-eng.ru | alex_zas | |
| ne-son.ru | alex_zas | |
| septik4dom.ru | alex_zas | |
| stassinhouse.ru | anastasia_bul | |
| study-italy.eu | anatoly_solodilin | |
| andrey-maiorov.ru | andrey-maiorov | |
| 4ton-96.ru | foton | 🔥 Top-5 traffic |
| ver7.ru | foton | |
| geodesia-ekb.ru | geodesia | |
| news-port.ru | gincz | 🔥 Top-5 traffic |
| prodvig-saita.ru | gincz | |
| ru-tv.eu | gincz | |
| voyage4u.ru | gincz | |
| mtek-expert.ru | kirill_mtek | |
| tri-sure.ru | kirill-tri-sure | |
| natal-karta.ru | natal-karta | |
| novorr-art.ru | novorr | ✅ DISALLOW_FILE_MODS removed 2026-04-07 |
| mariela.ru | palantins | ⚠️ AH01630 errors — expected, no action |
| palantins.ru | palantins | |
| shapkioptom.ru | palantins | 🔥 Top-1 traffic |
| reklama-white.eu | reklama-white | |
| stanok-ural.ru | stanok-ural | |
| stomatolog-belchikov.ru | stomatolog | |
| tatra-ural.ru | tatra-ural | |
| ugfp.ru | ugfp | ✅ PHP-FPM pool created 2026-04-07 (was missing) |
| lvo-endo.ru | lvo-endo | |
| stuba-dom.ru | stuba-dom | |
| nail-space-ekb.ru | valeriia | ✅ wp-admin 403 fixed 2026-04-07 |

---

## Services & Software

| Service | Status | Notes |
|---------|--------|-------|
| nginx | ✅ running | v1.28.3 — Dual log format |
| PHP-FPM | ✅ running | php8.3-fpm, pm=ondemand for most pools |
| MariaDB | ✅ running | |
| CrowdSec | ✅ running | v1.7.7, ~61+ active bans |
| clamav-daemon | ❌ **DISABLED** | Freed 975 MB swap (2026-04-05) |
| clamav-freshclam | ✅ running | DB updates only |
| Exim4 | ✅ running | |
| Named (BIND) | ✅ running | |
| Netdata | ✅ running | |
| Glances | ✅ running | |

---

## PHP-FPM Pools

All sites run under **php8.3-fpm**. Each site has its own pool config and socket.

| Pool config | Socket | User |
|-------------|--------|------|
| ne-son.ru.conf | /var/run/ne-son.ru.sock | alex_zas |
| shapkioptom.ru.conf | /var/run/shapkioptom.ru.sock | palantins |
| stanok-ural.ru.conf | /var/run/stanok-ural.ru.sock | stanok-ural |
| study-italy.eu.conf | /var/run/study-italy.eu.sock | anatoly_solodilin |
| tatra-ural.ru.conf | /var/run/tatra-ural.ru.sock | tatra-ural |
| ugfp.ru.conf | /var/run/ugfp.ru.sock | ugfp | ← **Created 2026-04-07** |
| www.conf | /run/php/php8.3-fpm.sock | www-data (default) |

### ⚠️ CRITICAL RULE: Adding a new pool

When a site returns 502 and the pool is missing:
1. Create `/etc/php/8.3/fpm/pool.d/SITE.conf`
2. Run `php-fpm8.3 -t` — test syntax
3. Run `systemctl reload php8.3-fpm` — **RELOAD, not restart**
4. Check socket exists: `ls -la /var/run/SITE.sock`
5. Verify: `curl -s -o /dev/null -w "%{http_code}" https://SITE/`

```bash
# CORRECT:
php-fpm8.3 -t && systemctl reload php8.3-fpm

# WRONG (causes 1-3 sec downtime on ALL 28 sites):
systemctl restart php8.3-fpm
```

See full explanation: [`/root/Linux_Server_Public/OPERATIONS.md`](../OPERATIONS.md)

### ugfp.ru pool config (created 2026-04-07)

```ini
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
php_admin_value[memory_limit] = 256M
php_admin_value[upload_max_filesize] = 64M
php_admin_value[post_max_size] = 64M
php_admin_value[max_execution_time] = 120
php_admin_value[error_log] = /var/log/php8.3-fpm-ugfp.ru.log
php_admin_flag[log_errors] = on
```

---

## novorr-art.ru — wp-config.php (2026-04-07)

| Constant | Before | After |
|----------|--------|-------|
| `FS_METHOD` | `'direct'` | `'direct'` ✅ unchanged |
| `DISALLOW_FILE_EDIT` | `true` | commented out |
| `DISALLOW_FILE_MODS` | `true` | commented out |

> Backup: `wp-config.php.bak-2026-04-07-153421`

---

## nginx Configuration

### Dual Log Formats (since 2026-04-05)

```nginx
log_format fastpanel '[$time_local] $host $server_addr $remote_addr ...';
log_format combined_crowdsec '$remote_addr - $remote_user [$time_local] ...';

access_log /var/log/nginx/access.log fastpanel;
access_log /var/log/nginx/crowdsec-access.log combined_crowdsec;
```

### meta_crawler_block.conf (v2026-04-07)

Blocks Meta/Facebook crawler. `wp-admin` was removed on 2026-04-07 — it was blocking all `/wp-admin/` server-wide due to regex priority.

---

## CrowdSec

- Version: v1.7.7
- Active bans: ~61+ (2026-04-07)
- Log source: `/var/log/nginx/crowdsec-access.log` (combined format)

---

## ClamAV

| Component | Status |
|-----------|--------|
| `clamav-daemon` | ❌ disabled (freed 975 MB swap) |
| `clamav-freshclam` | ✅ running |
| Manual scan | `antivir` or `bash /root/scan_clamav.sh` |

---

## Crontab

```cron
# Updated: 2026-04-05
0 1 * * *      /root/backup_clean.sh >> /var/log/system-backup.log 2>&1
0 3 * * 0      /opt/server_tools/scripts/disk_cleanup.sh
0 2 * * 3,6    bash /root/wp_update_all.sh >> /var/log/wp_update.log 2>&1
*/15 * * * *   bash /root/run_all_wp_cron.sh >> /var/log/wp_cron.log 2>&1
30 3 * * 0     /usr/local/bin/auto_upgrade.sh
```

---

## mariela.ru — AH01630 Errors

`AH01630: client denied by server configuration` from Baidu crawler (CN) and DigitalOcean. **This is correct behaviour** — blocks are working. No action needed.

---

## RAM & Swap (after 2026-04-05)

| Metric | Before | After |
|--------|--------|-------|
| Swap used | ~1.4 GB | ~439 MB |
| RAM available | ~259 MB | ~2.3 GB |

---

Last updated: **2026-04-07 18:11 CEST**

```
= Rooted by VladiMIR | AI =
v2026-04-07
```
