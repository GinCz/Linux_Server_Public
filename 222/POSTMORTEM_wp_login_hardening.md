# Postmortem: WP Login Hardening — 12.04.2026
_= Rooted by VladiMIR | AI =_

---

## 1. What happened (trigger)

**Date:** 12.04.2026, ~15:00 CEST
**Server:** 222-DE-NetCup (152.53.182.222, NetCup, Ubuntu 24, FASTPANEL, Nginx 1.28.3)

A mass brute-force attack on `/wp-login.php` was detected in the logs of site `timan-kuchyne.cz`:

```
1113 requests in the last hour from IP 103.186.31.44 (Indonesia)
```

Top URLs per hour:
```
1113 /wp-login.php
  11 /
   8 /index.php/wp-json/wp/v2/users/me
```

All requests returned HTTP 200 — no blocking was in place.

---

## 2. Why the attack was not blocked (root cause analysis)

### Cause A — timan-kuchyne.cz was not proxied through Cloudflare

Verification:
```bash
curl -s -I https://timan-kuchyne.cz/wp-login.php | grep -i "cf-ray"
```
Result: `cf-ray` **absent** from the response. Instead:
```
Server: nginx/1.28.3
X-Powered-By: PHP/8.4.12
```
This means the domain was set in Cloudflare DNS as **"DNS only" (grey cloud)** — requests went directly to the server, completely bypassing Cloudflare WAF. Rules 20 and 30 from `cloudflare_waf_rules.md` **did not apply** to this domain.

### Cause B — timan-kuchyne.cz had no `location = /wp-login.php` in Nginx config

In the config `/etc/nginx/fastpanel2-available/nata_popkova/timan-kuchyne.cz.conf` the `location = /wp-login.php` block was completely absent. The rate limit zone `wp_login_222` was declared but not applied to this domain — nothing was calling `limit_req`.

### Cause C — burst=10 on all other sites was too high

All site configs had:
```nginx
limit_req zone=wp_login_222 burst=10 nodelay;
```
With `rate=6r/m` (1 request every 10 seconds) and `burst=10` — Nginx was letting the first **10 requests through instantly** without delay, and only then started throttling. This meant a bot could make 10 fast login attempts before the first 429. That is too many.

---

## 3. What was tried and what did not work

### Attempt 1 — create a new 00-wp-login-limit-zone.conf

Created file `/etc/nginx/conf.d/00-wp-login-limit-zone.conf` with zone `wp_login_222:30m`.
**Error:**
```
nginx: [emerg] the size 20971520 of shared memory zone "wp_login_222" conflicts
with already declared size 31457280 in /etc/nginx/conf.d/01-wp-limit-zones.conf:7
```
Reason: zone `wp_login_222` was already declared in `01-wp-limit-zones.conf` with size 20m, and we declared it with 30m. Nginx does not allow declaring the same zone twice with different parameters.

**Solution:** delete both old files and create one master file.

### Attempt 2 — add limit_req_status 429 to the new file

Added `limit_req_status 429;` to the new zones file.
**Error:**
```
nginx: [emerg] "limit_req_status" directive is duplicate
in /etc/nginx/conf.d/meta_crawler_limit.conf:20
```
Reason: `limit_req_status 429` was already declared in `/etc/nginx/conf.d/meta_crawler_limit.conf` (Meta/Facebook crawler protection file). This is a global directive — declared only once.
**Solution:** remove `limit_req_status` from our zones file.

### Attempt 3 — create security-wordpress.conf with location blocks

Created `/etc/nginx/fastpanel2-includes/security-wordpress.conf` with a `location = /wp-login.php` block.
**Error:**
```
nginx: [emerg] duplicate location "/wp-login.php"
in /etc/nginx/fastpanel2-includes/security-wordpress.conf:6
```
Reason: `fastpanel2-includes/*.conf` is included inside every `server {}` block via:
```nginx
include /etc/nginx/fastpanel2-includes/*.conf;
```
And each site config already had its own `location = /wp-login.php`. Nginx does not allow two identical `location =` in the same server block.

**Solution:** security-wordpress.conf must NOT contain `location = /wp-login.php`. Instead:
- Change `burst=10` → `burst=3` in each site config directly
- Add `location = /wp-login.php` to `timan-kuchyne.cz` manually
- In security-wordpress.conf keep only blocks not present in site configs (user enumeration, author enumeration, sensitive files)

### Attempt 4 — sed on fastpanel2-sites/

Attempted to modify files via `fastpanel2-sites/`, but this directory contains **symlinks** to `fastpanel2-available/`. sed on symlinks does not behave as expected.
**Solution:** run sed directly on `fastpanel2-available/`.

---

## 4. What was changed (final changes)

### 4.1 Files deleted

| File | Reason for deletion |
|------|---------------------|
| `/etc/nginx/conf.d/00-wp-login-limit-zone.conf` | Duplicated wp_login_222 zone |
| `/etc/nginx/conf.d/01-wp-limit-zones.conf` | Duplicated wp_login_222 zone |
| `/etc/nginx/fastpanel2-includes/security-wordpress.conf` | Caused duplicate location in every site |

### 4.2 File created

**`/etc/nginx/conf.d/00-wp-protection-zones.conf`** — the only zone declaration file:
```nginx
limit_req_zone $binary_remote_addr zone=wp_login_222:30m rate=6r/m;
limit_req_zone $binary_remote_addr zone=wp_admin_222:20m rate=2r/s;
limit_req_zone $binary_remote_addr zone=wp_xmlrpc_222:10m rate=1r/m;
```
Zone size increased from 20m to 30m (with many sites, 20m might not be enough).

### 4.3 burst changed in all active site configs

**41 files** in `/etc/nginx/fastpanel2-available/` changed:
```
before: limit_req zone=wp_login_222 burst=10 nodelay;
after:  limit_req zone=wp_login_222 burst=3 nodelay;
```

Full list of changed files:
```
detailing-alex.eu.conf, ekaterinburg-sro.eu.conf, eco-seo.cz.conf,
rail-east.uk.conf, east-vector.cz.conf, eurasia-translog.cz.conf,
vymena-motoroveho-oleje.cz.conf, car-chip.eu.conf, diamond-odtah.cz.conf,
sveta-drobot.cz.conf, bio-zahrada.eu.conf, alejandrofashion.cz.conf,
czechtoday.eu.conf, stm-services-group.cz.conf, autoservis-praha.eu.conf,
praha-autoservis.eu.conf, neonella.eu.conf, abl-metal.com.conf,
megan-consult.cz.conf, stopservis-vestec.cz.conf, kadernik-olga.eu.conf,
kk-med.eu.conf, kadernictvi-salon.eu.conf, doska-fr.ru.conf,
doska-pl.ru.conf, doska-it.ru.conf, doska-cz.ru.conf, doska-gr.ru.conf,
doska-hun.ru.conf, doska-isl.ru.conf, doska-mld.ru.conf, doska-de.ru.conf,
doska-ua.ru.conf, doska-esp.ru.conf, balance-b2b.eu.conf,
autoservis-rychlik.cz.conf, car-bus-autoservice.cz.conf, hulk-jobs.cz.conf,
lybawa.com.conf, gadanie-tel.eu.conf, wowflow.cz.conf
```

### 4.4 wp-login location added to timan-kuchyne.cz

**`/etc/nginx/fastpanel2-available/nata_popkova/timan-kuchyne.cz.conf`**
Added to both server{} blocks (HTTP and HTTPS) before the closing `}`:
```nginx
location = /wp-login.php {
    limit_req zone=wp_login_222 burst=3 nodelay;
    include /etc/nginx/fastcgi_params;
    fastcgi_pass unix:/var/run/timan-kuchyne.cz.sock;
    fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
    fastcgi_param DOCUMENT_ROOT $realpath_root;
}
```

### 4.5 .htaccess restored on timan-kuchyne.cz ✅

**Date:** 12.04.2026, ~17:13 CEST

`wphealth` detected missing `.htaccess` on `timan-kuchyne.cz` — without it WordPress does not function correctly (all permalinks return 404), and Nginx-level protection was also not applied.

Standard WordPress `.htaccess` created:
```
/var/www/timan/data/www/timan-kuchyne.cz/.htaccess
```
```apache
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
```

**Result after restoration:**
```
wphealth → OK: 27  WARN: 0  FAIL: 0  (skipped non-WP: 6)
```

---

## 5. Nginx architecture on this server (important to know)

```
/etc/nginx/conf.d/                    ← global directives (zones, map, geo)
    00-wp-protection-zones.conf       ← our zones file (the only one!)
    meta_crawler_limit.conf           ← Meta crawler protection + limit_req_status 429
    cloudflare_real_ip.conf           ← restore real IP from CF headers

/etc/nginx/fastpanel2-includes/       ← included in EVERY server{} block
    *.conf                            ← DO NOT add location = blocks here!

/etc/nginx/fastpanel2-available/      ← real site configs (edit here)
    user_name/domain.conf

/etc/nginx/fastpanel2-sites/          ← symlinks to fastpanel2-available/ (do not edit)
    domain.conf -> ../fastpanel2-available/user/domain.conf
```

**Important rule:** to modify a site config — edit in `fastpanel2-available/`, not in `fastpanel2-sites/` (symlinks there).

---

## 6. Current wp-login protection policy (after changes)

| Level | Rule | Result |
|-------|------|--------|
| Cloudflare WAF | Rule 30: Managed Challenge on /wp-login.php | Bots cannot pass challenge |
| Cloudflare WAF | Rule 20: Block /xmlrpc.php | Hard block |
| Nginx rate limit | rate=6r/m, burst=3 nodelay | 4th fast request = 429 |
| CrowdSec | wordpress-scan scenario | Ban at iptables/bouncer level |

**Cloudflare only works if the domain is proxied (orange cloud).**
Verification: `curl -s -I https://domain/wp-login.php | grep cf-ray`

---

## 7. What still needs to be done

- [ ] Enable orange cloud (proxy) for `timan-kuchyne.cz` in Cloudflare DNS
- [ ] Check all other domains — are they all proxied through Cloudflare
- [ ] Set up Cloudflare WAF at Account-level (so new domains automatically get protection)
- [ ] Add `location = /wp-login.php` to site configs that don't have it

---

## 8. Diagnostic commands for the future

```bash
# Check top attacking IPs in the last hour
awk -v d="$(date -d '1 hour ago' '+%d/%b/%Y:%H')" '$0 ~ d' /var/log/nginx/access.log \
  | awk '{print $1}' | sort | uniq -c | sort -rn | head -10

# Check whether domain goes through Cloudflare
curl -s -I https://DOMAIN/wp-login.php | grep -i "cf-ray\|server"

# Check current rate limit zones
nginx -T 2>/dev/null | grep "limit_req_zone\|limit_req_status"

# Check burst in all active configs
grep -r "wp_login_222 burst=" /etc/nginx/fastpanel2-available/ | grep -v ".bak"

# Check active CrowdSec bans
cscli decisions list

# Test rate limit (should return 429 starting from 4th request)
for i in 1 2 3 4 5; do
  echo -n "Request $i: "
  curl -s -o /dev/null -w "%{http_code}\n" -X POST https://DOMAIN/wp-login.php \
    -d "log=test&pwd=test"
done
```

---

## 9. IP Whitelist — both protection levels (12.04.2026, ~21:40 CEST)

**Context:** While working on wp-login protection, it was discovered that trusted IPs (VladiMIR + AmneziaWG clients + infrastructure servers) had no exclusions — they could be banned just like attacking bots. Fixed simultaneously at two levels.

### 9.1 Nginx — geo whitelist in 00-wp-protection-zones.conf

**Mechanism:** the `geo` module assigns trusted IPs the key `""` (empty string). A `limit_req_zone` with an empty key does not create an entry in the zone — rate-limit for these IPs **does not apply at all**. This is an officially supported Nginx pattern.

File: `/etc/nginx/conf.d/00-wp-protection-zones.conf`
Commit: `65577477` — [github.com/GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public/blob/main/222/00-wp-protection-zones.conf)

### 9.2 CrowdSec — allowlist `trusted-ips`

**Mechanism:** CrowdSec allowlist completely excludes IPs from all detection scenarios and prevents issuing a ban either manually or automatically.

```bash
# Created with commands:
cscli allowlists create "trusted-ips" --description "VladiMIR + AmneziaWG clients + servers — no ban ever"
cscli allowlists add trusted-ips 185.100.197.16 90.181.133.10 ...

# Verification:
cscli allowlists inspect trusted-ips
```

**Result:** `Size: 16`, `Expiration: never` for all IPs.

### 9.3 Full list of trusted IPs

| IP | Name | Purpose |
|----|------|---------|
| `185.100.197.16` | VladiMIR home | Nupaky — home/work PC |
| `90.181.133.10` | VladiMIR #2 | backup home IP |
| `185.14.233.235` | VladiMIR #3 | backup IP |
| `185.14.232.0` | VladiMIR #4 | backup IP |
| `109.234.38.47` | ALEX_47 | AmneziaWG + Samba |
| `144.124.228.237` | 4TON_237 | AmneziaWG + Samba + Prometheus |
| `144.124.232.9` | TATRA_9 | AmneziaWG + Samba + Kuma Monitoring |
| `144.124.228.227` | SHAHIN_227 | AmneziaWG + Samba |
| `144.124.239.24` | STOLB_24 | AmneziaWG + Samba + AdGuard Home |
| `195.63.138.33` | PILIK_33 | AmneziaWG + Samba |
| `146.103.110.176` | ILYA_176 | AmneziaWG + Samba |
| `144.124.233.38` | SO_38 | AmneziaWG + Samba |
| `152.53.182.222` | 222-DE-NetCup | this server |
| `212.109.223.109` | RU-FastVDS | second server |
| `141.101.234.14` | infra-1 | Cloudflare / infrastructure |
| `82.112.63.133` | infra-2 | infrastructure |

### 9.4 How to add a new IP in the future

**Nginx** — edit `00-wp-protection-zones.conf`, add line to `geo` block, then:
```bash
nginx -t && systemctl reload nginx
```

**CrowdSec** — one command:
```bash
cscli allowlists add trusted-ips NEW_IP_HERE
```

> ⚠️ **Important:** IPs must be added at **both levels** simultaneously. Nginx and CrowdSec work independently — exclusion in only one does not provide full protection against accidental banning.

---

*= Rooted by VladiMIR + AI | v.2026.07.11 | github.com/GinCz =*
