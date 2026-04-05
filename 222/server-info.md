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

## Sites Hosted (known)

| Domain | User | Notes |
|--------|------|-------|
| svetaform.eu | spa | 🔥 Top-1 traffic (315K req/hr seen 2026-04-05) |
| abl-metal.com | igor_kap | |
| czechtoday.eu | dmitry-vary | Top-4/5 traffic |
| timan-kuchyne.cz | nata_po | ⚠️ High PHP CPU (18%) |
| doska-cz.ru | doski | Active PHP pool |
| doska-pl.ru | doski | Active PHP pool |
| lybawa.com | gadanie | Active PHP pool |
| wowflow.cz | wowflow | ⚠️ Webshell scan target (see below) |

---

## Services & Software

| Service | Status | Notes |
|---------|--------|-------|
| nginx | ✅ running | Cloudflare real IP configured |
| PHP-FPM | ✅ running | pm=ondemand (since 2026-03-25) |
| MariaDB | ✅ running | No slow queries |
| CrowdSec | ✅ running | Only 3 bans — see note below |
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

> ⚠️ **svetaform.eu: 315 422 total requests in 1 hour** — abnormally high. Could be bot traffic, DDoS, or viral content. Check Cloudflare analytics for this domain.

### Active PHP-FPM Pools (CPU %)

| Pool | User | CPU% |
|------|------|------|
| timan-kuchyne.cz | nata_po | **18.3% / 17.9%** ⚠️ |
| doska-cz.ru | doski | 11.5% |
| lybawa.com | gadanie | 7.4% |
| doska-pl.ru | doski | 6.6% |

> ⚠️ **timan-kuchyne.cz PHP at 18%** — elevated but not critical. Monitor if it stays above 15% for extended periods.

### Top URLs (Bot / Attack traffic)

| URL | Count | Note |
|-----|-------|------|
| (raw HTTP/1.1) | 30 733 | |
| / | 15 783 | |
| /wp-login.php | **5 788** | ⚠️ Active brute force |
| /wp-admin/index.php | 952 | |
| /basket/ | 654 | Woocommerce / bot |
| /api/status | 583 | |
| /wp-cron.php | **191** | ⚠️ Should be 0 — see below |
| /index.php | 128 | |
| /dashboard/ | 94 | |

---

## ⚠️ wp-cron.php — 191 external hits (issue!)

**Problem:** `/wp-cron.php` is receiving **191 external HTTP requests** per hour from bots.

`wp-cron.php` was supposed to be disabled on all sites (`DISABLE_WP_CRON=true` in wp-config.php).  
However, 191 hits means either:
1. Some sites still have `DISABLE_WP_CRON` not set, or
2. Bots are hitting the URL regardless (WordPress still responds if the file exists)

**Recommended fix:** Block `/wp-cron.php` at nginx level globally:
```nginx
# Add to nginx global config or per-site vhost:
location = /wp-cron.php {
    deny all;
    return 403;
}
```
This stops bots from triggering it even if `wp-config.php` is misconfigured.

---

## 🚨 wowflow.cz — Webshell Scan Attempts (2026-04-05)

### Errors in `/var/www/wowflow/data/logs/wowflow.cz-frontend.error.log`

All errors are `FastCGI sent in stderr: "Primary script unknown"` — meaning the files **do not exist** on disk. The attacks failed. But the scan was persistent.

### Attack Sessions

**Session 1 — 07:17:55 from `2.58.56.31` (Netherlands, AS 62005 BlueVPS)**
```
GET /wp-content/plugins/fix/up.php           → webshell upload probe
GET /wp-content/themes/seotheme/db.php?u     → known webshell ("seotheme" malware)
GET /wp-content/plugins/apikey/apikey.php    → API key extraction probe
GET /plugins/content/apismtp/apismtp.php     → SMTP credentials steal probe
```

**Session 2 — 11:39–11:41 from `20.104.201.101` (Azure, US)**
```
GET /.well-known/index.php                   → generic PHP probe
GET /.well-known/pki-validation/siteindex.php
GET /.well-known/pki-validation/fm.php       → file manager webshell probe
```

**Session 3 — 14:58 from `87.121.84.44` (Czech Republic)**
```
GET /admin/assets/plugins/plupload/examples/upload.php  → file upload exploit probe
```

### Assessment
- **All probes returned "Primary script unknown"** — files don’t exist, attacks failed
- **wowflow.cz is a scan target** — domain is indexed and being actively probed
- `2.58.56.31` (BlueVPS) should be banned — multiple known malware scan patterns
- `20.104.201.101` (Azure) — known attack proxy pattern (same as server 109)
- **CrowdSec should have caught these** but only has 3 bans total — see CrowdSec section below

### Recommended immediate actions
1. Manually ban attacker IPs via CrowdSec:
```bash
cscli decisions add --ip 2.58.56.31 --duration 48h --reason "webshell-scan-wowflow"
cscli decisions add --ip 20.104.201.101 --duration 48h --reason "webshell-scan-wowflow"
cscli decisions add --ip 87.121.84.44 --duration 24h --reason "upload-exploit-probe"
```
2. Check if CrowdSec on 222 is correctly parsing nginx logs (same issue as 109 may apply)

---

## ⚠️ CrowdSec — Only 3 Bans (Possible Issue)

**Active bans: 3** — this is suspiciously low given:
- 5 788 `/wp-login.php` hits/hour
- Multiple webshell scan sessions
- Known attack IPs active

**Likely cause:** Same issue as was fixed on server 109 — CrowdSec may not be correctly parsing FastPanel nginx logs.

**Check immediately:**
```bash
# On server 222:
cscli metrics
# Look at: Lines parsed vs Lines unparsed for nginx source
# If Lines parsed = 0 or very low → same log format problem as on 109

# Check which log file CrowdSec reads:
cat /etc/crowdsec/acquis.d/*.yaml

# Verify log format in nginx.conf:
grep -A5 'log_format' /etc/nginx/nginx.conf
```

**If same problem confirmed** — apply the same dual logging fix as on server 109:
- Add `log_format combined_crowdsec` to nginx.conf
- Add second `access_log /var/log/nginx/crowdsec-access.log combined_crowdsec;`
- Update acquis.d to point to the new combined log

---

## nginx Configuration

- Cloudflare real IP module: `/etc/nginx/conf.d/cloudflare_real_ip.conf` ✅
- WP login rate limiting: `00-wp-login-limit-zone.conf`, `01-wp-limit-zones.conf`

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

Last updated: **2026-04-05 15:17 CEST**
