# Server 222 — 222-DE-NetCup

```
= Rooted by VladiMIR | AI =
v2026-04-05
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

## Sites Hosted (full list from acquis metrics)

| Domain | User/Dir | Notes |
|--------|----------|-------|
| svetaform.eu | spa | 🔥 Top-1 traffic (315K req/hr, 2026-04-05) |
| czechtoday.eu | dmitry-vary | Top-4/5 traffic |
| abl-metal.com | igor_kap | |
| megan-consult.cz | igor_kap | |
| timan-kuchyne.cz | nata_popkova | ⚠️ High PHP CPU 18%, DISABLE_WP_CRON was MISSING |
| doska-cz.ru | doski | |
| doska-de.ru | doski | |
| doska-esp.ru | doski | |
| doska-fr.ru | doski | |
| doska-gr.ru | doski | |
| doska-hun.ru | doski | |
| doska-isl.ru | doski | |
| doska-it.ru | doski | |
| doska-mld.ru | doski | |
| doska-pl.ru | doski | |
| doska-ua.ru | doski | |
| gadanie-tel.eu | gadanie-tel | |
| lybawa.com | gadanie-tel | |
| eco-seo.cz | gincz | |
| eco-seo.eu | gincz | |
| ekaterinburg-sro.eu | gincz | |
| gincz.com | gincz | |
| ru-tv.eu | gincz | |
| crypto.gincz.com | gincz | |
| dns.gincz.com | gincz | |
| sem.gincz.com | gincz | |
| hulk-jobs.cz | hulk | |
| kk-med.cz | karina | |
| kk-med.eu | karina | |
| neonella.eu | neonella | |
| kadernik-olga.eu | olga_pisareva | |
| east-vector.cz | serg_et | |
| eurasia-translog.cz | serg_et | |
| rail-east.uk | serg_et | |
| car-chip.eu | serg_pimonov | |
| vymena-motoroveho-oleje.cz | serg_pimonov | |
| stopservis-vestec.cz | serg_reno | |
| sveta-drobot.cz | sveta_drobot | |
| balance-b2b.eu | sveta_tuk | |
| bio-zahrada.eu | tan-adrian | |
| stm-services-group.cz | tatiana_podzolkova | |
| tstwist.cz | tstwist | |
| kadernictvi-salon.eu | viktoria | |
| wowflow.cz | wowflow | ⚠️ Webshell scan target (see below) |
| alejandrofashion.cz | alejandrofashion | |
| detailing-alex.eu | alex_detailing | |
| autoservis-rychlik.cz | andrey-autoservis | |
| car-bus-autoservice.cz | andrey-autoservis | |
| car-bus-service.cz | andrey-autoservis | |
| autoservis-praha.eu | arslan | |
| praha-autoservis.eu | bayerhoff | |
| diamond-odtah.cz | diamond-drivers | |
| autoservis-rychlik.cz | andrey-autoservis | |

---

## Services & Software

| Service | Status | Notes |
|---------|--------|-------|
| nginx | ✅ running | Cloudflare real IP configured |
| PHP-FPM | ✅ running | pm=ondemand (since 2026-03-25) |
| MariaDB | ✅ running | No slow queries |
| CrowdSec | ✅ running | ⚠️ NGINX LOG FORMAT ISSUE — see below |
| Docker | ✅ running | Semaphore CI, crypto bots |
| Exim4 | ✅ running | |
| Named (BIND) | ✅ running | |
| Netdata | ✅ running | |

---

## Load Report — 2026-04-05 15:17 CEST

### Top-5 Sites by Traffic (last 1h, total: 462 676 requests)

| # | Site | Requests |
|---|------|---------|
| 1 | svetaform.eu (frontend) | 160 101 |
| 2 | svetaform.eu (backend) | 155 321 |
| 3 | abl-metal.com (frontend) | 6 822 |
| 4 | czechtoday.eu (frontend) | 6 648 |
| 5 | czechtoday.eu (backend) | 6 039 |

> ⚠️ **svetaform.eu: 315 422 total requests in 1 hour** — abnormally high. Check Cloudflare analytics.

### Active PHP-FPM Pools (CPU %)

| Pool | User | CPU% |
|------|------|------|
| timan-kuchyne.cz | nata_popkova | **18.3% / 17.9%** ⚠️ |
| doska-cz.ru | doski | 11.5% |
| lybawa.com | gadanie | 7.4% |
| doska-pl.ru | doski | 6.6% |

### Top URLs (Bot / Attack traffic)

| URL | Count | Note |
|-----|-------|------|
| (raw HTTP/1.1) | 30 733 | |
| / | 15 783 | |
| /wp-login.php | **5 788** | ⚠️ Active brute force |
| /wp-admin/index.php | 952 | |
| /basket/ | 654 | Woocommerce / bot |
| /api/status | 583 | |
| /wp-cron.php | **191** | ⚠️ See fix below |
| /index.php | 128 | |
| /dashboard/ | 94 | |

---

## 🔴 CrowdSec — Root Cause Analysis (2026-04-05 15:27)

### Diagnosis

From `cscli metrics` output:

**nginx log format in `/etc/nginx/nginx.conf`:**
```
log_format fastpanel '[$time_local] $host $server_addr $remote_addr ...';
access_log /var/log/nginx/access.log fastpanel;
```

**→ SAME PROBLEM AS SERVER 109.**

The `fastpanel` log format starts with `[$time_local]`, not `$remote_addr`.
CrowdSec standard nginx parser expects `$remote_addr` as the FIRST field.
Result: CrowdSec reads all lines (26k parsed) but **generates ZERO automatic local bans**.

### Evidence

- `crowdsec (security engine)` active_decisions = **0** ← the smoking gun
- `cscli (manual decisions)` = only 3 — all manual
- `CAPI (community blocklist)` = 25,940 IPs blocked — these come from cloud, not local analysis
- Local API Alerts show 1200+ events detected, but bouncer has 0 local engine bans

### Fix Required — Same as Server 109

Add `combined_crowdsec` log format and second access_log line to `/etc/nginx/nginx.conf`:

```bash
# BACKUP FIRST
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak.20260405
```

In `nginx.conf` http block, ADD after existing `log_format fastpanel`:
```nginx
log_format combined_crowdsec '$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"';
access_log  /var/log/nginx/crowdsec-access.log combined_crowdsec;
```

Then update `/etc/crowdsec/acquis.yaml` — change nginx filenames to include the new log:
```yaml
filenames:
  - /var/log/nginx/crowdsec-access.log
labels:
  type: nginx
```

Reload:
```bash
nginx -t && systemctl reload nginx
systemctl restart crowdsec
```

**See `fix_nginx_crowdsec_222_v2026-04-05.sh` for full automated fix script.**

---

## ✅ DISABLE_WP_CRON Status (2026-04-05)

- **44 sites checked** — 43 have `DISABLE_WP_CRON=true`
- **1 site MISSING:** `timan-kuchyne.cz` (`/var/www/nata_popkova/data/www/timan-kuchyne.cz/wp-config.php`)
- Fix: `sed -i "/<?php/a define( 'DISABLE_WP_CRON', true );" /var/www/nata_popkova/data/www/timan-kuchyne.cz/wp-config.php`

---

## 🚨 wowflow.cz — Webshell Scan (2026-04-05)

Three attack sessions — all failed ("Primary script unknown" = files don't exist):

| Time | Source IP | Country | Probes |
|------|-----------|---------|--------|
| 07:17 | `2.58.56.31` | NL, BlueVPS | 4 — seotheme shell, upload.php, apismtp, apikey |
| 11:39–11:41 | `20.104.201.101` | US, Azure | 3 — .well-known/fm.php, siteindex.php |
| 14:58 | `87.121.84.44` | CZ | 1 — plupload/upload.php exploit |

CrowdSec custom rules already added manually:
- `wp-backdoor-scanner wowflow.cz 2026-04-05` → 1 ban
- `wp-scanner wowflow.cz 2026-04-05` → 1 ban
- `wp-scanner kadernictvi-salon.eu 2026-04-05` → 1 ban

Once nginx log format is fixed, these will be caught **automatically** by `crowdsecurity/http-wordpress-scan`.

---

## CrowdSec Alert Stats (from metrics, since boot)

| Scenario | Count |
|----------|-------|
| crowdsecurity/http-probing | 323 |
| crowdsecurity/http-crawl-non_statics | 310 |
| crowdsecurity/http-bad-user-agent | 150 |
| crowdsecurity/http-wordpress-scan | 135 |
| crowdsecurity/http-admin-interface-probing | 104 |
| crowdsecurity/http-bf-wordpress_bf | 15 |
| custom/wellknown-php-scan | 48 |
| crowdsecurity/http-sensitive-files | 22 |
| crowdsecurity/ssh-bf | 23 |
| crowdsecurity/ssh-time-based-bf | 3 |
| crowdsecurity/CVE-2017-9841 | 5 |
| crowdsecurity/CVE-2019-18935 | 2 |

**Firewall bouncer stats (since 2026-03-29):**
- CAPI blocklist: 25,940 active IPs, dropped 1.49M packets
- Local engine: 0 active IPs (due to log format issue)
- Manual (cscli): 3 active IPs

---

## nginx Configuration

- Cloudflare real IP module: `/etc/nginx/conf.d/cloudflare_real_ip.conf` ✅
- WP login rate limiting: `00-wp-login-limit-zone.conf`, `01-wp-limit-zones.conf`
- Log format: `fastpanel` only (⚠️ needs `combined_crowdsec` added — see above)

---

## PHP-FPM

- Mode: `pm=ondemand` (set 2026-03-25)
- Watchdog: runs every 15 min via cron
- @reboot: `fastpanel_php_ondemand_v2026-03-25.sh`

---

## Crontab

```cron
# PHP-FPM watchdog every 15 min
*/15 * * * * bash /opt/server_tools/scripts/php_fpm_watchdog.sh

# FastPanel PHP on-demand mode on every reboot
@reboot sleep 60 && bash /root/Linux_Server_Public/scripts/fastpanel_php_ondemand_v2026-03-25.sh >> /var/log/php_ondemand.log 2>&1

# Daily backup cleanup at 02:00
0 2 * * * /root/backup_clean.sh >> /var/log/system-backup.log 2>&1

# Daily Docker backup at 03:00
0 3 * * * /root/docker_backup.sh >> /var/log/docker-backup.log 2>&1

# WordPress updates: Wednesday + Saturday at 02:00
0 2 * * 3,6  bash /root/wp_update_all.sh >> /var/log/wp_update.log 2>&1
```

---

Last updated: **2026-04-05 15:27 CEST**
