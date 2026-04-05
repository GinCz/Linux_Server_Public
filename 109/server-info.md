# Server 109 — 109-RU-FastVDS

```
= Rooted by VladiMIR | AI =
v2026-04-05
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

---

## Services & Software

| Service | Status | Notes |
|---------|--------|-------|
| nginx | ✅ running | Dual log format (fastpanel + combined_crowdsec) |
| PHP-FPM | ✅ running | pm=dynamic/ondemand, max_children=73 |
| MariaDB | ✅ running | |
| CrowdSec | ✅ running | v1.7.7, 56 active bans as of 2026-04-05 14:58 |
| ClamAV daemon (clamd) | ❌ **DISABLED** | Disabled 2026-04-05 — was using 975 MB swap |
| clamav-freshclam | ✅ running | DB updates only, no daemon |
| Exim4 | ✅ running | |
| Named (BIND) | ✅ running | |
| Netdata | ✅ running | |
| Glances | ✅ running | |

---

## Load Report — 2026-04-05 14:58 CEST

### Top-5 Sites by Traffic (last 1h, total: 69 755 requests)

| # | Log / Site | Requests |
|---|-----------|----------|
| 1 | shapkioptom.ru (frontend) | 6 450 |
| 2 | news-port.ru (frontend) | 5 100 |
| 3 | shapkioptom.ru (backend) | 4 462 |
| 4 | news-port.ru (backend) | 4 304 |
| 5 | 4ton-96.ru (frontend) | 3 277 |

### Active PHP-FPM Pools (CPU %)

| Pool | CPU% | Notes |
|------|------|-------|
| foton / 4ton-96.ru | 1.5 / 1.4 | |
| palantins / shapkioptom.ru | 1.3 / 1.2 | |
| vobs / stuba-dom.ru | 1.1 | |

### Top URLs (Bot / Attack traffic)

| URL | Count |
|-----|-------|
| (raw HTTP/1.1) | 14 521 |
| / | 9 648 |
| /wp-login.php | **2 986** ⚠️ |
| /robots.txt | 352 |
| /wp-admin/admin-ajax.php | 147 |

> ⚠️ **2 986 hits to /wp-login.php in 1 hour** — active WordPress brute force ongoing.
> CrowdSec is banning attackers automatically (56 active bans).

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
access_log  /var/log/nginx/crowdsec-access.log combined_crowdsec;  # <-- new, for CrowdSec
```

**Why two logs?**  
FastPanel uses a custom `log_format fastpanel` where `$remote_addr` is NOT the first field — this breaks the CrowdSec nginx parser which expects standard Combined format. Adding a second log in Combined format allows CrowdSec to correctly parse IP addresses and trigger bans.

**Backup created:** `/etc/nginx/nginx.conf.bak.20260405`

---

## mariela.ru — AH01630 Errors (2026-04-05)

### What is happening
Nginx/Apache is returning `AH01630: client denied by server configuration` for:
- `/katalog` — multiple hits from `116.179.32.x` and `220.181.108.x` subnets (Baidu crawler, CN)
- `/otbor` — same subnets
- `/.env` — `170.64.225.6` (DigitalOcean, AU) — credential steal attempt

### Error Details
```
[authz_core:error] AH01630: client denied by server configuration
/var/www/palantins/data/www/mariela.ru/katalog
/var/www/palantins/data/www/mariela.ru/otbor
/var/www/palantins/data/www/mariela.ru/.env
```

### Analysis
- `AH01630` means the directory exists but is blocked by `.htaccess` or `<Directory>` config with `Require all denied` or similar — **this is CORRECT behaviour** (the block is working)
- Hitting `/katalog` and `/otbor` from Chinese IP ranges (Baidu bot `116.179.32.x`, `220.181.108.x`) — likely directory content scraping
- Hitting `/.env` — classic automated vulnerability scan for leaked credentials
- **No action needed on the server side** — the blocks are already in place and working
- **Optional:** Add these IP ranges to CrowdSec blocklist or nginx geo block

### IPs involved
| IP | Country | AS | Type |
|----|---------|----|------|
| 116.179.32.155/221/38/146/42 | CN | Baidu | Crawler |
| 220.181.108.169/82 | CN | Baidu | Crawler |
| 170.64.225.6 | AU | DigitalOcean | Scanner |

---

## CrowdSec Configuration

### Status — 2026-04-05 14:58
- **Active bans: 56**
- Service: `active (running)`

### Recent Decisions (sample)

| Alert | IP | Reason | Country | AS |
|-------|----|--------|---------|----|
| 30805 | 20.205.1.146 | http-crawl-non_statics | HK | Microsoft |
| 30804/30803 | 20.199.99.25 | http-crawl + http-probing | FR | Microsoft |
| 30802 | 2.57.121.17 | ssh-bf | RO | Unmanaged Ltd |
| 30799/30798 | 4.193.168.228 | http-crawl + http-probing | SG | Microsoft |
| 30796 | 129.211.218.15 | ssh-slow-bf | CN | Tencent |
| 30792/30791 | 31.57.216.187 | http-bf-wordpress_bf + http-probing | AE | Pentech |

> 📈 Notable: multiple Microsoft Azure IPs being banned (HK, FR, SG) — Azure VMs used as attack proxies is common.

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

| Component | Before | After |
|-----------|--------|-------|
| `clamav-daemon` | ✅ enabled, running 24/7 | ❌ **disabled, stopped** |
| `clamav-freshclam` | ❌ disabled | ✅ **enabled** (DB updates) |
| Manual scan | daemon socket | `clamscan` directly |

```bash
# Manual scan:
bash /root/scan_clamav.sh
```

---

## RAM & Swap Status (2026-04-05)

| Metric | Before | After |
|--------|--------|-------|
| Swap used | ~1.4 GB | ~439 MB |
| RAM available | ~259 MB | ~2.3 GB |
| PHP-FPM workers | 49 | 49 |

---

## Backup

| Type | Location | Schedule |
|------|----------|----------|
| System | `/root/backup_clean.sh` | Daily 01:00 |
| Log | `/var/log/system-backup.log` | |

---

Last updated: **2026-04-05 14:58 CEST**
