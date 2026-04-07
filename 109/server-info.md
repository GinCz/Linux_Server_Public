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
| novorr-art.ru | novorr | |
| mariela.ru | palantins | ⚠️ AH01630 errors (see below) |
| palantins.ru | palantins | |
| shapkioptom.ru | palantins | 🔥 Top-1 traffic |
| reklama-white.eu | reklama-white | |
| stanok-ural.ru | stanok-ural | |
| stomatolog-belchikov.ru | stomatolog | |
| tatra-ural.ru | tatra-ural | |
| ugfp.ru | ugfp | |
| lvo-endo.ru | lvo-endo | |
| stuba-dom.ru | stuba-dom | |
| nail-space-ekb.ru | valeriia | ✅ wp-admin fixed 2026-04-07 |

---

## Services & Software

| Service | Status | Notes |
|---------|--------|-------|
| nginx | ✅ running | v1.28.3 — Dual log format (fastpanel + combined_crowdsec) |
| PHP-FPM | ✅ running | pm=dynamic/ondemand, max_children=73 |
| MariaDB | ✅ running | |
| CrowdSec | ✅ running | v1.7.7, 61 active bans as of 2026-04-07 |
| ClamAV daemon (clamd) | ❌ **DISABLED** | Disabled 2026-04-05 — was using 975 MB swap |
| clamav-freshclam | ✅ running | DB updates only, no daemon |
| Exim4 | ✅ running | |
| Named (BIND) | ✅ running | |
| Netdata | ✅ running | |
| Glances | ✅ running | |

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
**Important:** `wp-admin` was removed from this file on 2026-04-07 — see CHANGELOG.

```nginx
# Block Meta crawler from WooCommerce heavy endpoints | v2026-04-05
# = Rooted by VladiMIR | AI =
# Server: 109-RU-FastVDS

# Hard block Meta from cart/checkout (IP-level)
location ~* ^/(basket|cart|checkout|wp-cron\.php) {
    if ($is_meta_ip) { return 403; }
    if ($meta_limit_key = "meta") { return 403; }
    try_files $uri $uri/ /index.php?$args;
}

# Block Meta from WooCommerce AJAX
location ~* \?wc-ajax= {
    if ($is_meta_ip) { return 403; }
    if ($meta_limit_key = "meta") { return 403; }
    try_files $uri $uri/ /index.php?$args;
}

# Rate limit Meta on PHP requests
location ~ \.php$ {
    limit_req zone=meta_global burst=5 nodelay;
    include /etc/nginx/fastcgi_params;
    fastcgi_pass unix:/var/run/$server_name.sock;
    fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
    fastcgi_param DOCUMENT_ROOT $realpath_root;
}
```

> ⚠️ **Note:** Variables `$is_meta_ip` and `$meta_limit_key` are defined in per-site WooCommerce configs (e.g. shapkioptom.ru). Sites without WooCommerce do NOT have these variables — but since the `if()` conditions only return 403 when the variable matches, they are harmless on non-WooCommerce sites.

> ⚠️ **Why `wp-admin` was removed:** Originally `wp-admin` was included in the regex `^/(basket|cart|checkout|wp-admin|wp-cron\.php)` to block Meta bots from the admin area. However this caused a global 403 on `/wp-admin/` for **all sites** because nginx treats a regex `location ~*` as higher priority than a prefix `location /wp-admin/`. Since CrowdSec handles WordPress protection, `wp-admin` in this regex is unnecessary.

### `security-wordpress.conf` — v2026-03-25

```nginx
# Block WP REST API user enumeration
location ~* ^/wp-json/wp/v2/users { deny all; return 403; }

# Block author enumeration
if ($query_string ~* "author=[0-9]") { return 403; }

# Block sensitive WP files
location ~* ^/(wp-config\.php|wp-config-sample\.php|readme\.html|license\.txt) {
    deny all; return 403;
}

# Block webshell probing
location ~* \.(php)$ {
    if ($request_uri ~* "(mini|mjq|new|RIP|shell|c99|r57|wso|b374k|indoxploit|filemanager|wp_filemanager|adminer|config\.bak)\.php") {
        return 444;
    }
}
```

---

## nail-space-ekb.ru — nginx vhost

Path: `/etc/nginx/fastpanel2-sites/valeriia/nail-space-ekb.ru.conf`  
Includes: `/etc/nginx/fastpanel2-sites/valeriia/nail-space-ekb.ru.includes` (empty — no extra rules)

Key points:
- PHP socket: `unix:/var/run/nail-space-ekb.ru.sock`
- SSL: `/var/www/httpd-cert/nail-space-ekb.ru_2026-02-28-19-40_15.crt`
- wp-cron blocked via `location = /wp-cron.php { deny all; }`
- `/wp-admin/` works correctly after 2026-04-07 fix (302 redirect to login)
- www → non-www redirect (301)

---

## mariela.ru — AH01630 Errors (2026-04-05)

### What is happening
Nginx/Apache is returning `AH01630: client denied by server configuration` for:
- `/katalog` — multiple hits from `116.179.32.x` and `220.181.108.x` subnets (Baidu crawler, CN)
- `/otbor` — same subnets
- `/.env` — `170.64.225.6` (DigitalOcean, AU) — credential steal attempt

### Analysis
- **This is CORRECT behaviour** — the blocks are already working
- No action needed

### IPs involved
| IP | Country | AS | Type |
|----|---------|----|------|
| 116.179.32.x | CN | Baidu | Crawler |
| 220.181.108.x | CN | Baidu | Crawler |
| 170.64.225.6 | AU | DigitalOcean | Scanner |

---

## CrowdSec Configuration

### Status — 2026-04-07 11:51
- **Active bans: 61**
- Service: `active (running)`

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

## Backup

| Type | Location | Schedule |
|------|----------|----------|
| System | `/root/backup_clean.sh` | Daily 01:00 |
| Log | `/var/log/system-backup.log` | |

---

Last updated: **2026-04-07 11:51 CEST**
