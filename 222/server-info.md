# Server 222 — 222-DE-NetCup

```
= Rooted by VladiMIR | AI =
v2026-07-11
```

## Hardware & Access

| Parameter | Value |
|-----------|-------|
| Hostname | `222-DE-NetCup` |
| IP | `152.53.182.222` |
| Provider | NetCup.com (Germany) |
| Tariff | VPS 1000 G12 (2026) |
| CPU | 4 vCore AMD EPYC-Genoa |
| RAM | 8 GB DDR5 ECC |
| Disk | 256 GB NVMe |
| OS | Ubuntu 24 LTS |
| Panel | FASTPANEL |
| Cloudflare | ✅ Yes (all sites behind CF) |
| Price | 8.60 €/mo |
| SSH | `ssh root@152.53.182.222` |

---

## Sites Hosted

| Domain | User | Notes |
|--------|------|-------|
| abl-metal.com | abl_metal | |
| britishcarsclub.cz | british | |
| czechtoday.eu | czechtoday | 🔥 Top-3 traffic |
| doska-cz.ru | doski | ⚠️ High CPU php-fpm |
| filatov.cz | filatov | |
| gadanie-online.eu | gadanie | |
| lybawa.com | gadanie | ⚠️ High CPU php-fpm |
| nail-space.cz | ginvpn | |
| shapkioptom.cz | ginvpn | |
| svetaform.eu | ginvpn | 🔥 ABNORMALLY HIGH traffic (315K req/hr) |
| timan-kuchyne.cz | nata_popkova | ⚠️ Missing DISABLE_WP_CRON — see below |
| volkov-style.cz | volkov | |
| wowflow.cz | wowflow | ⚠️ Webshell scan attempts 2026-04-05 |

> Full domains list: see `domains.md` in repo root

---

## Services & Software

| Service | Status | Notes |
|---------|--------|-------|
| nginx | ✅ running | Dual log format (fastpanel + combined_crowdsec) — fixed 2026-04-05 |
| PHP-FPM | ✅ running | pm=ondemand (since 2026-03-25), watchdog every 15min |
| MariaDB | ✅ running | |
| CrowdSec | ✅ running | Banning active after 2026-04-05 nginx log fix |
| Exim4 | ✅ running | |
| Named (BIND) | ✅ running | |
| Docker | ✅ running | Crypto bot containers |
| Netdata | ✅ running | |
| Glances | ✅ running | |
| Samba | ✅ running | Open for all IPs (auth by users vlad/usr) — changed 2026-07-11 |

---

## Samba (SMB) Configuration

### Status — 2026-07-11

Samba network shares are **open for all IP addresses**. Access is protected by Samba user authentication only (users: `vlad`, `usr`).

> See full details: `222/SAMBA_OPEN_ACCESS.md`

### Shares

| Share | Path | vlad | usr | Notes |
|-------|------|------|-----|-------|
| `storage` | `/storage` | RO | RO | Root — shows soft and user folders |
| `soft` | `/storage/soft` | RW | RO | Software storage |
| `user` | `/storage/user` | RW | RW | User storage |

### iptables rules (ports open for all IPs since 2026-07-11)

```
ACCEPT  tcp  0.0.0.0/0  dpt:445
ACCEPT  tcp  0.0.0.0/0  dpt:139
ACCEPT  udp  0.0.0.0/0  dpt:138
ACCEPT  udp  0.0.0.0/0  dpt:137
```

### smb.conf [global] key settings

```ini
[global]
   security = user
   map to guest = never
   ntlm auth = yes
   server min protocol = SMB2
   invalid users = root bin daemon nobody
   # No 'hosts allow' / 'hosts deny' — open for all IPs
```

---

## nginx Configuration

### Log Formats (`/etc/nginx/nginx.conf`)

As of **2026-04-05**, nginx writes **two access logs simultaneously**.

**⚠️ IMPORTANT HISTORY:** Before 2026-04-05, CrowdSec was NOT banning any HTTP attackers on this server.

**Root cause:** FastPanel's default `log_format fastpanel` puts `[$time_local]` as the FIRST field, not `$remote_addr`. The CrowdSec nginx parser expects `$remote_addr` as the first field (standard Combined format). Result: CrowdSec could parse 0% of log lines → 0 automatic bans, even though 1200+ alerts were detected.

**Fix applied 2026-04-05:**

```nginx
# FastPanel native format (unchanged — used by FastPanel UI)
log_format fastpanel '[$time_local] $host $server_addr $remote_addr $status $body_bytes_sent $request_time $request $http_referer $http_user_agent';

# Combined standard format — ADDED for CrowdSec parser compatibility
log_format combined_crowdsec '$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"';

# Both access logs active:
access_log  /var/log/nginx/access.log fastpanel;
access_log  /var/log/nginx/crowdsec-access.log combined_crowdsec;

sendfile        on;
keepalive_timeout  65;
```

---

## CrowdSec Configuration

### Status — 2026-04-05
- **Service:** `active (running)` — started after nginx log fix
- **Active bans (decisions after fix):** 11+ IPs in first 60s

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

### Log Sources (`/etc/crowdsec/acquis.yaml`)

```yaml
filenames:
  - /var/log/nginx/crowdsec-access.log
labels:
  type: nginx
source: file
```

---

## PHP-FPM Configuration

### Mode: `pm=ondemand` (since 2026-03-25)

| Setting | Value |
|---------|-------|
| `pm` | `ondemand` |
| `pm.max_children` | per-pool (set per site) |
| `pm.process_idle_timeout` | 10s |
| Watchdog | `/opt/server_tools/scripts/php_fpm_watchdog.sh` |
| Watchdog schedule | `*/15 * * * *` (cron) |
| @reboot apply | `@reboot sleep 60 && bash /root/Linux_Server_Public/scripts/fastpanel_php_ondemand_v2026-03-25.sh` |

---

## Docker — Crypto Bot Containers

Location: `/root/docker-compose.yml`  
Backup script: `/root/docker_backup.sh`  
Schedule: Daily at 03:00 (`/var/log/docker-backup.log`)

| Container | Status |
|-----------|--------|
| crypto-bot (main) | ✅ running |
| crypto-restore.sh | Available for manual use |

---

## Backup

| Type | Location | Schedule |
|------|----------|----------|
| System | `/root/backup_clean.sh` | Daily 02:00 |
| Docker | `/root/docker_backup.sh` | Daily 03:00 |
| Log | `/var/log/system-backup.log` | |

---

## Crontab (active)

```cron
# === 222-DE-NetCup | 152.53.182.222 ===
# Updated: 2026-07-11

# PHP-FPM watchdog every 15 min
*/15 * * * * bash /opt/server_tools/scripts/php_fpm_watchdog.sh

# FastPanel PHP on-demand mode — run on every reboot
@reboot sleep 60 && bash /root/Linux_Server_Public/scripts/fastpanel_php_ondemand_v2026-03-25.sh >> /var/log/php_ondemand.log 2>&1

# Daily backup cleanup at 02:00
0 2 * * * /root/backup_clean.sh >> /var/log/system-backup.log 2>&1

# Daily Docker backup at 03:00
0 3 * * * /root/docker_backup.sh >> /var/log/docker-backup.log 2>&1

# WordPress updates: Wednesday + Saturday at 02:00
0 2 * * 3,6  bash /root/wp_update_all.sh >> /var/log/wp_update.log 2>&1
```

---

## ⚠️ Known Issues & Open Tasks

### 1. timan-kuchyne.cz — DISABLE_WP_CRON missing

- All 44 sites were checked on 2026-04-05
- **43 sites** have `define('DISABLE_WP_CRON', true);` in `wp-config.php` ✅
- **1 site missing:** `/var/www/nata_popkova/data/www/timan-kuchyne.cz/wp-config.php`
- **Fix needed:** add `define( 'DISABLE_WP_CRON', true );` to that file
- **Status:** ⚠️ NOT YET FIXED

### 2. svetaform.eu — Abnormal traffic

- 315 422 requests in 1h (2026-04-05) — far above all other sites
- **Status:** ⚠️ Needs investigation

---

Last updated: **2026-07-11 22:00 CEST**

```
= Rooted by VladiMIR + AI | v.2026.07.11 | github.com/GinCz =
```
