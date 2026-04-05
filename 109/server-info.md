# 🖥️ Server 109 — RU-FastVDS

> **Updated:** 2026-04-05 | = Rooted by VladiMIR | AI =

## 🔧 Hardware
| Parameter | Value |
|---|---|
| **IP** | 212.109.223.109 |
| **Provider** | FastVDS.ru, Russia |
| **Tariff** | VDS-KVM-NVMe-Otriv-10.0 |
| **CPU** | 4 vCore AMD EPYC 7763 |
| **RAM** | 8 GB |
| **Disk** | 80 GB NVMe |
| **OS** | Ubuntu 24 LTS |
| **Panel** | FastPanel (PHP 8.3 / 8.4) |
| **Price** | 13 EUR/mo |
| **Cloudflare** | DNS ONLY — grey cloud (no proxy) |

## 🌐 Network & Security
- **Hostname:** `109-ru-vds`
- **Cloudflare:** DNS management only — **grey cloud (DNS only, no proxy!)**
- **Purpose:** Russian-market sites — required by Russian law to be accessible directly without foreign proxy
- **IMPORTANT:** `$binary_remote_addr` in nginx = **REAL visitor IP** (no Cloudflare proxy)
- **This means:** IP-based rate limiting WORKS correctly on this server
- **CrowdSec:** Active (nginx bouncer + SSH)
- **Fail2ban:** Active

## 🌍 WordPress Sites (Russian market)

Sites on this server are targeted at Russian audience and must be:
- Accessible directly from Russia without Cloudflare proxy
- DNS managed via Cloudflare (grey cloud) for easy DNS management
- Served from Russian IP (212.109.223.109)

**Known active sites:**
| Domain | PHP pool | Notes |
|---|---|---|
| shapkioptom.ru | palantir | WooCommerce shop |
| 4ton-96.ru | foton | Heavy load site |
| stuba-dom.ru | vobs | Active |
| tatra-ural.ru | tatra | Active |

---

## 🛡️ Nginx Security — Bot & Crawler Protection

### ✅ IP-based rate limiting WORKS on server 109

Unlike server 222, on server 109:
- There is NO Cloudflare proxy
- `$binary_remote_addr` = real visitor IP
- IP-based `limit_req_zone` and `geo` blocks work correctly
- Both UA-based AND IP-based protection can be used simultaneously

---

### 🤖 Meta/Facebook Crawler Block (2026-04-05)

#### Problem
Same as server 222 — Meta crawlers aggressively crawl WooCommerce cart/checkout pages causing high PHP-FPM CPU usage. On server 109 the situation is potentially worse because there is no Cloudflare WAF layer in front.

#### Why Meta does this
Meta's crawler (`meta-externalagent`) indexes WooCommerce products for Facebook/Instagram shopping feeds. It hits `/basket/`, `/cart/`, `/checkout/` with `?remove_item=` and `?add-to-cart=` parameters — triggering full WooCommerce PHP execution on every request.

#### Solution chosen
Double protection (stronger than server 222 because real IPs are available):
1. **UA-based rate limit** — same `map` approach as server 222
2. **IPv6 subnet block** — Meta uses subnet `2a03:2880::/32`, blocked at nginx geo level

#### Implementation (2 files on server)

**File 1:** `/etc/nginx/conf.d/meta_crawler_limit.conf`
```nginx
# Meta/Facebook crawler protection | v2026-04-05
# = Rooted by VladiMIR | AI =
# Server: 109-RU-FastVDS — direct IP, no Cloudflare proxy
# Double protection: UA-based rate limit + IPv6 subnet hard block

map $http_user_agent $meta_limit_key {
    default                 "";
    "~*meta-externalagent"  "meta";
    "~*facebookexternalhit" "meta";
    "~*FacebookBot"         "meta";
}

# Additional: block by Meta real IPv6 subnet (works because no Cloudflare proxy)
geo $remote_addr $is_meta_ip {
    default         0;
    2a03:2880::/32  1;  # Meta/Facebook crawler IPv6 range
}

limit_req_zone $meta_limit_key zone=meta_global:10m rate=2r/s;
limit_req_status 429;
```

**File 2:** `/etc/nginx/fastpanel2-includes/meta_crawler_block.conf`
```nginx
# Block Meta crawler from WooCommerce heavy endpoints | v2026-04-05
# = Rooted by VladiMIR | AI =
# Server: 109-RU-FastVDS
# Included in ALL vhosts via fastpanel2-includes mechanism

# Hard block Meta (by IP subnet AND by UA) from cart/checkout/wp-admin
location ~* ^/(basket|cart|checkout|wp-admin|wp-cron\.php) {
    if ($is_meta_ip) {
        return 403;
    }
    if ($meta_limit_key = "meta") {
        return 403;
    }
    try_files $uri $uri/ /index.php?$args;
}

# Block Meta from WooCommerce AJAX
location ~* \?wc-ajax= {
    if ($is_meta_ip) {
        return 403;
    }
    if ($meta_limit_key = "meta") {
        return 403;
    }
    try_files $uri $uri/ /index.php?$args;
}

# Rate limit Meta on all PHP requests
location ~ \.php$ {
    limit_req zone=meta_global burst=5 nodelay;
    include /etc/nginx/fastcgi_params;
    fastcgi_pass unix:/var/run/$server_name.sock;
    fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
    fastcgi_param DOCUMENT_ROOT $realpath_root;
}
```

#### Difference from server 222
| Feature | Server 222 (DE) | Server 109 (RU) |
|---|---|---|
| Cloudflare proxy | YES (orange cloud) | NO (grey cloud / DNS only) |
| `$binary_remote_addr` | Cloudflare IP | Real visitor IP |
| IP-based rate limit | ❌ Broken (all = CF IP) | ✅ Works correctly |
| UA-based rate limit | ✅ Used | ✅ Used |
| IPv6 subnet block (`geo`) | ❌ Useless (CF hides IPs) | ✅ Active (2a03:2880::/32) |
| Protection level | UA only | UA + IPv6 subnet |

#### Possible consequences & what to watch
- **Facebook/Instagram product previews** — still work (product pages accessible)
- **Facebook Shop catalog** — still updates (product pages accessible at 2 req/s)
- **If Meta adds new IPv6 subnets** — update `geo` block in `meta_crawler_limit.conf`. Known Meta ranges: `2a03:2880::/32`, `31.13.24.0/21`, `31.13.64.0/18`, `66.220.144.0/20`
- **If Meta changes User-Agent** — UA block stops working. Monitor: `grep -i "meta\|facebook" /var/www/*/data/logs/*.access.log | grep -v "403\|429"`
- **Cart URLs in Facebook posts** — links like `/basket/?add-to-cart=X` will return 403 to Meta crawler. Real users clicking these links in browser will NOT be blocked (they don't match `$is_meta_ip` and their UA doesn't match)
- **FastPanel vhost files** — NEVER edit `/etc/nginx/fastpanel2-available/` manually. FastPanel overwrites them. Always use `fastpanel2-includes/`.

#### Reload command
```bash
nginx -t && systemctl reload nginx
```

#### Monitor Meta block effectiveness
```bash
# Count 403/429 to Meta crawlers in last hour
grep -i "meta-externalagent\|facebookexternalhit\|FacebookBot" \
  /var/www/*/data/logs/*access.log \
  | awk '{print $9}' | sort | uniq -c

# Check if any Meta requests are still getting through (200 responses)
grep -i "meta-externalagent" /var/www/*/data/logs/*access.log \
  | grep " 200 " | tail -20
```

---

## 📁 Key Files & Paths
```
# Nginx key files:
/etc/nginx/conf.d/meta_crawler_limit.conf                  — Meta crawler map + rate zone + geo
/etc/nginx/fastpanel2-includes/meta_crawler_block.conf     — Meta block locations (all vhosts)
/etc/nginx/fastpanel2-includes/security-wordpress.conf     — WP security rules (all vhosts)
/etc/nginx/fastpanel2-available/                           — FastPanel vhost configs (DO NOT edit manually!)
/etc/nginx/fastpanel2-sites/                               — FastPanel active symlinks
```

## ⚠️ FastPanel Warning
**NEVER edit files in `/etc/nginx/fastpanel2-available/` manually!**
FastPanel will overwrite them when you change site settings via web panel.
Always put custom nginx rules in:
- `/etc/nginx/conf.d/` — global http{} context (maps, zones, geo)
- `/etc/nginx/fastpanel2-includes/` — per-location rules, included in all vhosts automatically
