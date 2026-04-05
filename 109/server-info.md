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
| 4ton-96.ru | foton | |
| ver7.ru | foton | |
| geodesia-ekb.ru | geodesia | |
| news-port.ru | gincz | |
| prodvig-saita.ru | gincz | |
| ru-tv.eu | gincz | |
| voyage4u.ru | gincz | |
| mtek-expert.ru | kirill_mtek | |
| tri-sure.ru | kirill-tri-sure | |
| natal-karta.ru | natal-karta | |
| novorr-art.ru | novorr | |
| mariela.ru | palantins | |
| palantins.ru | palantins | |
| shapkioptom.ru | palantins | |
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
| CrowdSec | ✅ running | v1.7.7, bouncers: nginx |
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
access_log  /var/log/nginx/crowdsec-access.log combined_crowdsec;  # <-- new, for CrowdSec
```

**Why two logs?**  
FastPanel uses a custom `log_format fastpanel` where `$remote_addr` is NOT the first field — this breaks the CrowdSec nginx parser which expects standard Combined format. Adding a second log in Combined format allows CrowdSec to correctly parse IP addresses and trigger bans.

**Backup created:** `/etc/nginx/nginx.conf.bak.20260405`

---

## CrowdSec Configuration

### Version
`crowdsec v1.7.7-debian-pragmatic-amd64`

### Active Scenarios

| Scenario | Status |
|----------|--------|
| crowdsecurity/ssh-bf | ✅ enabled |
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
# Combined format log — readable by standard CrowdSec nginx parser
filenames:
  - /var/log/nginx/crowdsec-access.log
labels:
  type: nginx
source: file
```

> ⚠️ **Important:** `/var/log/nginx/crowdsec-access.log` is the **new dedicated log** in standard Combined format.  
> The old `fastpanel` format logs (`/var/log/nginx/access.log` and per-site logs) are still present but **NOT used by CrowdSec** because the FastPanel log format has `$remote_addr` at position 4 instead of position 1, which breaks the parser.

### Why CrowdSec Was NOT Blocking Before (Root Cause)

FastPanel uses a non-standard nginx log format:
```
[$time_local] $host $server_addr $remote_addr ...
```
CrowdSec's nginx parser expects standard Combined format:
```
$remote_addr - $remote_user [$time_local] ...
```
Because `$remote_addr` was at position 4 instead of 1, the parser could not extract the IP → no IP → no bucket → **no bans**. All scenarios were correctly installed but silently failing.

### Fix Applied (2026-04-05)
1. Added `log_format combined_crowdsec` to nginx.conf
2. Added second `access_log` writing to `/var/log/nginx/crowdsec-access.log`
3. Updated `/etc/crowdsec/acquis.d/fastpanel-nginx.yaml` to read only the new combined log
4. Restarted CrowdSec → immediately started banning attackers

### Sample Decisions After Fix
```
| Ip:31.57.216.187  | http-bf-wordpress_bf | ban | AE |
| Ip:20.151.229.110 | http-wordpress-scan  | ban | CA |
| Ip:52.243.57.116  | http-probing         | ban | JP |
| Ip:2.57.121.17    | ssh-bf               | ban | RO |
```

---

## ClamAV — Important Change (2026-04-05)

**`clamav-daemon` (clamd) was permanently disabled** on this server.

### Reason
`clamd` running as a permanent daemon was consuming **~975 MB of swap** continuously (loaded virus DB into RAM+swap). With only 8 GB RAM, this severely impacted server performance.

### What changed

| Component | Before | After |
|-----------|--------|-------|
| `clamav-daemon` | ✅ enabled, running 24/7 | ❌ **disabled, stopped** |
| `clamav-freshclam` | ❌ disabled | ✅ **enabled** (DB updates) |
| Manual scan | worked via daemon socket | works via `clamscan` directly |
| Scan speed | fast (DB preloaded) | slightly slower first run |

### How to scan manually
```bash
bash /root/scan_clamav.sh
# or directly:
clamscan -r /var/www --exclude-dir=.git -l /var/log/clamav_manual.log
```

---

## RAM & Swap Status (2026-04-05)

**Before fixes:**
- Swap used: ~1.4 GB
- clamd alone: 975 MB in swap

**After fixes:**
- Swap used: ~439 MB
- RAM free: ~2.3 GB available
- PHP-FPM workers: 49 active

---

## Backup

| Type | Location | Schedule |
|------|----------|----------|
| System | `/root/backup_clean.sh` | Daily 01:00 |
| Log | `/var/log/system-backup.log` | |

---

Last updated: **2026-04-05**
