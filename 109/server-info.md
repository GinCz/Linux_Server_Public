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
| nginx | ✅ running | v1.28.3 — Dual log format (fastpanel + combined_crowdsec) |
| PHP-FPM | ✅ running | php8.3-fpm, pm=ondemand for most pools |
| MariaDB | ✅ running | |
| CrowdSec | ✅ running | v1.7.7, ~61+ active bans as of 2026-04-07 |
| ClamAV daemon (clamd) | ❌ **DISABLED** | Disabled 2026-04-05 — was using 975 MB swap |
| clamav-freshclam | ✅ running | DB updates only, no daemon |
| Exim4 | ✅ running | |
| Named (BIND) | ✅ running | |
| Netdata | ✅ running | |
| Glances | ✅ running | |

---

## PHP-FPM Pools (`/etc/php/8.3/fpm/pool.d/`)

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

> ⚠️ **Note:** Most sites use the FastPanel-managed default pool via `www.conf`. Only a few have explicit pool configs. The `ugfp.ru.conf` was **missing** and was created manually on 2026-04-07.

### ugfp.ru pool — created 2026-04-07

File: `/etc/php/8.3/fpm/pool.d/ugfp.ru.conf`

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

## novorr-art.ru — wp-config.php constants (2026-04-07)

**Site path:** `/var/www/novorr/data/www/novorr-art.ru/`  
**WP version:** 6.9.1 → update to 6.9.4 now unblocked  
**DB prefix:** `wp_`  
**DB name:** `novorr_art_r`  
**Admin user:** `gincz` (ID=1), email: gin@volny.cz

### Constants state after fix

| Constant | Before | After | Line |
|----------|--------|-------|------|
| `FS_METHOD` | `'direct'` | `'direct'` ✅ unchanged | 106 |
| `DISALLOW_FILE_EDIT` | `true` | **commented out** | 117 |
| `DISALLOW_FILE_MODS` | `true` | **commented out** | 118 |

```php
// Current state of lines 106-118 in wp-config.php:
define('FS_METHOD', 'direct');                                        // line 106 — OK
// define('DISALLOW_FILE_EDIT', true); // disabled by VladiMIR 2026-04-07  // line 117
// define('DISALLOW_FILE_MODS', true); // disabled by VladiMIR 2026-04-07  // line 118
```

> Backup: `wp-config.php.bak-2026-04-07-153421`

---

## nginx Configuration

### Log Formats (`/etc/nginx/nginx.conf`)

As of **2026-04-05**, nginx writes **two access logs simultaneously**:

```nginx
# FastPanel native format (unchanged — used by FastPanel UI)
log_format fastpanel '[$time_local] $host $server_addr $remote_addr $status $body_bytes_sent $request_time $request $http_referer $http_user_agent';

# Combined standard format — added for CrowdSec parser compatibility
log_format combined_crowdsec '$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"';

# Both access logs active:
access_log  /var/log/nginx/access.log fastpanel;
access_log  /var/log/nginx/crowdsec-access.log combined_crowdsec;  # <-- for CrowdSec
```

**Why two logs?**  
FastPanel uses a custom `log_format fastpanel` where `$remote_addr` is NOT the first field — this breaks the CrowdSec nginx parser which expects standard Combined format. Adding a second log in Combined format allows CrowdSec to correctly parse IP addresses and trigger bans.

---

## Global nginx Include Files (`/etc/nginx/fastpanel2-includes/`)

These files are loaded for **ALL sites** on the server. Changes here affect every domain.

### `meta_crawler_block.conf` — v2026-04-07

Blocks Meta/Facebook crawler from heavy WooCommerce endpoints.  
**Important:** `wp-admin` was removed from this file on 2026-04-07.

```nginx
# Block Meta crawler from WooCommerce heavy endpoints | v2026-04-05
# = Rooted by VladiMIR | AI =
# Server: 109-RU-FastVDS

location ~* ^/(basket|cart|checkout|wp-cron\.php) {
    if ($is_meta_ip) { return 403; }
    if ($meta_limit_key = "meta") { return 403; }
    try_files $uri $uri/ /index.php?$args;
}

location ~* \?wc-ajax= {
    if ($is_meta_ip) { return 403; }
    if ($meta_limit_key = "meta") { return 403; }
    try_files $uri $uri/ /index.php?$args;
}

location ~ \.php$ {
    limit_req zone=meta_global burst=5 nodelay;
    include /etc/nginx/fastcgi_params;
    fastcgi_pass unix:/var/run/$server_name.sock;
    fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
    fastcgi_param DOCUMENT_ROOT $realpath_root;
}
```

> ⚠️ **Why `wp-admin` was removed (2026-04-07):** The regex `~* ^/(basket|cart|checkout|wp-admin|...)` was blocking ALL `/wp-admin/` access server-wide because nginx regex locations override prefix locations. Removing `wp-admin` from this regex fixed the 403 on nail-space-ekb.ru. CrowdSec handles WordPress admin protection.

### `security-wordpress.conf` — v2026-03-25

```nginx
location ~* ^/wp-json/wp/v2/users { deny all; return 403; }
if ($query_string ~* "author=[0-9]") { return 403; }
location ~* ^/(wp-config\.php|wp-config-sample\.php|readme\.html|license\.txt) {
    deny all; return 403;
}
location ~* \.(php)$ {
    if ($request_uri ~* "(mini|mjq|new|RIP|shell|c99|r57|wso|b374k|indoxploit|filemanager|wp_filemanager|adminer|config\.bak)\.php") {
        return 444;
    }
}
```

---

## CrowdSec Configuration

### Status — 2026-04-07
- **Active bans: ~61+**
- Service: `active (running)`
- Version: v1.7.7

### Active Scenarios

| Scenario | Status |
|----------|--------|
| crowdsecurity/ssh-bf | ✅ enabled |
| crowdsecurity/ssh-slow-bf | ✅ enabled |
| crowdsecurity/http-wordpress-scan | ✅ enabled |
| crowdsecurity/http-bad-user-agent | ✅ enabled |
| crowdsecurity/http-path-traversal-probing | ✅ enabled |
| crowdsecurity/http-sensitive-files | ✅ enabled |
| crowdsecurity/http-probing | ✅ enabled |
| crowdsecurity/http-crawl-non_statics | ✅ enabled |
| crowdsecurity/http-bf-wordpress_bf | ✅ enabled |

### Log Sources (`/etc/crowdsec/acquis.d/fastpanel-nginx.yaml`)

```yaml
# FastPanel nginx logs for CrowdSec | v2026-04-05
# = Rooted by VladiMIR | AI =
filenames:
  - /var/log/nginx/crowdsec-access.log
labels:
  type: nginx
source: file
```

---

## ClamAV — Important Change (2026-04-05)

**`clamav-daemon` (clamd) was permanently disabled** on this server.

| Component | Status |
|-----------|--------|
| `clamav-daemon` | ❌ disabled, stopped (was using 975 MB swap) |
| `clamav-freshclam` | ✅ enabled (DB updates only) |
| Manual scan | `bash /root/scan_clamav.sh` |

---

## RAM & Swap Status (2026-04-05)

| Metric | Before | After |
|--------|--------|-------|
| Swap used | ~1.4 GB | ~439 MB |
| RAM available | ~259 MB | ~2.3 GB |

---

## mariela.ru — AH01630 Errors

### What is happening
Nginx returns `AH01630: client denied by server configuration` for:
- `/katalog` — `116.179.32.x` and `220.181.108.x` (Baidu crawler, CN)
- `/otbor` — same subnets
- `/.env` — `170.64.225.6` (DigitalOcean, AU) — credential steal attempt

**This is CORRECT behaviour** — the blocks are already working. No action needed.

---

## Backup

| Type | Location | Schedule |
|------|----------|----------|
| System | `/root/backup_clean.sh` | Daily 01:00 |
| Log | `/var/log/system-backup.log` | |

---

Last updated: **2026-04-07 15:34 CEST**
