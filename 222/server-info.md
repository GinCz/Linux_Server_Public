# Server 222 — 222-DE-NetCup

```
= Rooted by VladiMIR | AI =
v2026-04-07
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

### Verification after fix

```
nginx -t          → syntax is ok
nginx -t          → configuration file /etc/nginx/nginx.conf test is successful
✅ nginx reloaded — dual logging active
● crowdsec.service Active: active (running)
```

---

## CrowdSec Configuration

### Status — 2026-04-05
- **Service:** `active (running)` — started after nginx log fix
- **Active bans (decisions after fix):** 11+ IPs in first 60s

### Decisions sample after fix (2026-04-05)

| ID | Source | Scope:Value | Reason | Action | Country | Events |
|-------|--------|-------------|--------|--------|---------|--------|
| 6117736 | crowdsec | Ip:2.57.121.17 | crowdsecurity/ssh-bf | ban | RO | 7 |
| 6117735 | crowdsec | Ip:4.193.168.228 | crowdsecurity/http-crawl-non_statics | ban | SG (Microsoft) | 8 |
| 6117733 | crowdsec | Ip:129.211.218.15 | crowdsecurity/ssh-slow-bf | ban | CN (Tencent) | 21 |
| 6117732 | crowdsec | Ip:31.57.216.187 | crowdsecurity/http-bf-wordpress_bf | ban | AE | 6 |
| 6117730 | crowdsec | Ip:43.153.34.199 | crowdsecurity/ssh-bf | ban | US (Tencent) | 6 |
| 6117729 | crowdsec | Ip:20.151.229.110 | crowdsecurity/http-wordpress-scan | ban | CA (Microsoft) | 6 |
| 6117726 | crowdsec | Ip:52.243.57.116 | crowdsecurity/http-probing | ban | JP (Microsoft) | 6 |
| 6117725 | crowdsec | Ip:20.194.110.188 | crowdsecurity/http-probing | ban | KR (Microsoft) | 6 |
| 6117724 | crowdsec | Ip:104.243.43.7 | crowdsecurity/http-crawl-non_statics | ban | US (ReliableSite) | 6 |
| 6102723 | crowdsec | Ip:20.89.241.241 | crowdsecurity/http-crawl-non_statics | ban | JP (Microsoft) | 10 |
| 6102721 | crowdsec | Ip:2.57.121.86 | crowdsecurity/ssh-bf | ban | RO | 7 |

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
# CrowdSec log sources — updated 2026-04-05
filenames:
  - /var/log/nginx/crowdsec-access.log
labels:
  type: nginx
source: file
```

### Script used for fix

File in repo: `222/fix_nginx_crowdsec_222_v2026-04-05.sh`

The script performs in order:
1. Backup `/etc/nginx/nginx.conf` → `/etc/nginx/nginx.conf.bak.20260405`
2. Add `log_format combined_crowdsec` block to `nginx.conf`
3. Add second `access_log` line for `/var/log/nginx/crowdsec-access.log`
4. Reload nginx: `nginx -t && systemctl reload nginx`
5. Update `/etc/crowdsec/acquis.yaml` to read the new log file
6. Restart CrowdSec: `systemctl restart crowdsec`
7. Wait 60s, show `cscli decisions list` for verification

---

## PHP-FPM Configuration

### Mode: `pm=ondemand` (since 2026-03-25)

All PHP-FPM pools were switched from `pm=dynamic` to `pm=ondemand` to reduce idle RAM usage.

| Setting | Value |
|---------|-------|
| `pm` | `ondemand` |
| `pm.max_children` | per-pool (set per site) |
| `pm.process_idle_timeout` | 10s |
| Watchdog | `/opt/server_tools/scripts/php_fpm_watchdog.sh` |
| Watchdog schedule | `*/15 * * * *` (cron) |
| @reboot apply | `@reboot sleep 60 && bash /root/Linux_Server_Public/scripts/fastpanel_php_ondemand_v2026-03-25.sh` |

---

## Load Report — 2026-04-05 15:17 CEST

**Total requests last 1h: 462 676**

| Site | Requests | Notes |
|------|----------|-------|
| svetaform.eu | **315 422** | 🔴 ABNORMALLY HIGH — needs investigation |
| czechtoday.eu | 12 687 | Normal |
| abl-metal.com | 6 822 | Normal |

Top CPU consumers (PHP-FPM):

| Site | User | CPU% | Workers |
|------|------|------|--------|
| timan-kuchyne.cz | nata_popkova | 18.3% | 2 |
| doska-cz.ru | doski | 11.5% | — |
| lybawa.com | gadanie | 7.4% | — |

Attack traffic:
- `/wp-login.php` — **5 788 hits/hour**
- `/wp-cron.php` — **191 hits** (timan-kuchyne.cz has DISABLE_WP_CRON missing — see below)

---

## ⚠️ Known Issues & Open Tasks

### 1. timan-kuchyne.cz — DISABLE_WP_CRON missing

- All 44 sites were checked on 2026-04-05
- **43 sites** have `define('DISABLE_WP_CRON', true);` in `wp-config.php` ✅
- **1 site missing:** `/var/www/nata_popkova/data/www/timan-kuchyne.cz/wp-config.php`
- **Fix needed:** add `define( 'DISABLE_WP_CRON', true );` to that file
- **Status:** ⚠️ NOT YET FIXED as of 2026-04-07

### 2. svetaform.eu — Abnormal traffic

- 315 422 requests in 1h (04-05) — far above all other sites
- Root cause not yet investigated
- **Status:** ⚠️ Needs investigation

---

## wowflow.cz — Webshell Scan Attempts (2026-04-05)

Three attack sessions detected in nginx logs. All failed — files don't exist.

| Time | IP | Country/Provider | Type | Probed paths |
|------|----|-----------------|------|-------------|
| 07:17 | 2.58.56.31 | NL (BlueVPS) | Webshell | seotheme, php shells |
| 11:39–11:41 | 20.104.201.101 | US (Azure) | .well-known PHP probe | .well-known/*.php |
| 14:58 | 87.121.84.44 | CZ | plupload upload exploit | wp-includes/js/plupload/upload.php |

**Verdict:** All blocked — no files exist on the server. No action required. CrowdSec should catch future attempts.

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
# Updated: 2026-04-07

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

Last updated: **2026-04-07 15:00 CEST**

```
= Rooted by VladiMIR | AI =
v2026-04-07
```
