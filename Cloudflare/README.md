# Cloudflare Security Scripts

> **Server:** 222-DE-NetCup (152.53.182.222)  
> **Run with:** `export CF_TOKEN="cfat_..."` then `bash <(curl -sL ...)`  
> **= Rooted by VladiMIR + AI | v2026.06.04b | github.com/GinCz =**

---

## Overview

All scripts apply **3-layer Cloudflare WAF security** to **ALL active zones** (auto-fetched from CF account).

| Rule # | Name | Action |
|--------|------|--------|
| **27** | Whitelist Skip | 14 trusted IPs → bypass ALL CF rules |
| **37** | Firewall (variant) | Attack paths + bad UA → Managed Challenge |
| **47** | Rate Limit | 100 req / 10s → Block 429 |

---

## Scripts

### `cf-all-domains-wp.sh` — WordPress Extended

WP attack paths + bad User-Agents + scanners.

```bash
export CF_TOKEN="cfat_..."
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Cloudflare/cf-all-domains-wp.sh)
```

**Rule 37 protects:**
- `/wp-login.php`, `/xmlrpc.php`, `/wp-cron.php`, `/wp-signup.php`, `/wp-register.php`
- `/wp-trackback.php`, `/wp-comments-post.php`
- `/wp-config`, `/.env`, `/.git`, `/.htaccess`, `/config.php`
- `/setup.php`, `/install.php`, `/upgrade.php`, `/phpinfo`
- `/adminer`, `/phpmyadmin`, `/pma`, `/mysql`
- `/wp-content/debug.log`, `/wp-includes/ms-files.php`
- `/wp-admin/*` (except `admin-ajax.php`)
- `/wp-json/wp/v2/users`, `/wp/v2/settings`
- Empty UA, `sqlmap`, `nikto`, `nmap`, `masscan`, `zgrab`
- `python-requests`, `go-http-client`, `curl/`, `libwww-perl`
- `WPScan`, `Acunetix`, `dirbuster`, `nuclei`

---

### `cf-all-domains-wp-woo.sh` — WordPress + WooCommerce

All WP Extended paths + WooCommerce-specific attack vectors.

```bash
export CF_TOKEN="cfat_..."
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Cloudflare/cf-all-domains-wp-woo.sh)
```

**WooCommerce additions (Rule 37):**
- `/wc-api/` — REST API abuse
- `/wp-json/wc/` — WC REST API unauthorized access
- `?wc-ajax=` — AJAX flood
- `/checkout/` — carding attacks
- `/my-account/` — brute force accounts
- `/cart/` — cart flooding

---

### `cf-all-domains-wp-ads.sh` — WordPress + Classified Ads

All WP Extended paths + classified ads platform attack vectors.

```bash
export CF_TOKEN="cfat_..."
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Cloudflare/cf-all-domains-wp-ads.sh)
```

**Classified Ads additions (Rule 37):**
- `/wp-json/*/listings` — listing scraping
- `?action=dokan*`, `?action=wcfm*` — vendor AJAX abuse
- `/author/` — user enumeration via author pages
- `?s=` with scanner UA — automated search scraping
- `/feed/` — RSS/Atom feed scraping
- `/?attachment_id=` — media enumeration
- Bad bots: `AhrefsBot`, `SemrushBot`, `MJ12bot`, `DotBot`, `PetalBot`

---

## Whitelisted IPs (Rule 27)

All 14 trusted IPs always bypass Cloudflare rules:

| IP | Server / Name |
|----|---------------|
| `152.53.182.222` | DE server 222 |
| `212.109.223.109` | RU server 109 |
| `109.234.38.47` | VPN ALEX_47 |
| `144.124.228.237` | VPN 4TON_237 |
| `144.124.232.9` | VPN TATRA_9 |
| `144.124.228.227` | VPN SHAHIN_227 |
| `144.124.239.24` | VPN STOLB_24 |
| `91.84.118.178` | VPN PILIK_178 |
| `146.103.110.176` | VPN ILYA_176 |
| `144.124.233.38` | VPN SO_38 |
| `185.100.197.16` | Home IP |
| `185.14.233.235` | Home IP |
| `185.14.232.0` | Home IP |
| `90.181.133.10` | Work IP |

---

## Legacy Scripts (single-domain)

Older single-zone scripts remain in this folder for reference:
- `cloudflare-wp.sh` — original WP single-domain
- `cloudflare-wp-woo.sh` — original WP+Woo single-domain
- `cloudflare-wp-class.sh` — original classified ads single-domain
- `cloudflare-wp-security.sh` — original extended security single-domain
- `cloudflare-wp-batch.sh` — batch script for specific domain list
