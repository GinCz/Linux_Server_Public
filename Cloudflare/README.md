# Cloudflare Security Rules — Free Plan

> **= Rooted by VladiMIR + AI | v.2026.06.03 | github.com/GinCz =**

Automated security hardening for WordPress sites on Cloudflare **Free plan**.
Sets all 4 protection layers via Cloudflare API in one command.

## Scripts

| Script | For | Rules |
|---|---|---|
| `cf-secure-wp.sh` | WordPress (no WooCommerce) | 20 + 30 + 40 |
| `cf-secure-woo.sh` | WordPress + WooCommerce | 20 + 30 + 40 (with WC exceptions) |
| `cf-secure-classifieds.sh` | Classifieds / Doska (Directorist, AWPCP) | 20 + 25 + 30 + 40 |

## Quick Start

```bash
# 1. Clone or download
git clone https://github.com/GinCz/Linux_Server_Public.git
cd Linux_Server_Public/Cloudflare

# 2. Set your Cloudflare credentials
export CF_TOKEN="your_api_token_here"
export ZONE_ID="your_zone_id_here"

# 3. Run the script for your site type
bash cf-secure-wp.sh            # plain WordPress
bash cf-secure-woo.sh           # WordPress + WooCommerce
bash cf-secure-classifieds.sh   # Classifieds / Doska
```

## What it sets up (Free plan)

| Rule | Name | Action | For |
|---|---|---|---|
| 20 | Block-XMLRPC | Block | All |
| 25 | Block-Scanners | Block | Classifieds only |
| 30 | Challenge-WP-Admin+Login | Managed Challenge | All |
| 40 | RateLimit-Bots | Block 50req/10s | All |

## Rules detail

### 20-Block-XMLRPC
Blocks the legacy XML-RPC endpoint used by bots for brute-force and DDoS.
```
(http.request.uri.path eq "/xmlrpc.php") or (http.request.uri.path eq "//xmlrpc.php")
```

### 25-Block-Scanners (classifieds only)
Blocks common scanner/exploit paths. Not needed for WooCommerce (no `/my-account` block).
```
(http.request.uri.path eq "/my-account/")
or (http.request.uri.path contains "/.env")
or (http.request.uri.path contains "/.git")
or (http.request.uri.path contains "/config.php")
or (http.request.uri.path contains "/setup.php")
or (http.request.uri.path contains "/install.php")
or (http.request.uri.path contains "/wp-config")
or (http.request.uri.path contains "/phpinfo")
or (http.request.uri.path contains "/adminer")
or (http.request.uri.path contains "/.htaccess")
```

### 30-Challenge-WP-Admin+Login
Managed Challenge (human verification) for all admin and login pages.
Excludes `admin-ajax.php` (needed for AJAX calls from frontend).
```
(http.request.uri.path eq "/wp-login.php" or http.request.uri.path eq "//wp-login.php")
or (
  (starts_with(http.request.uri.path, "/wp-admin/") or starts_with(http.request.uri.path, "//wp-admin/"))
  and not (http.request.uri.path eq "/wp-admin/admin-ajax.php"
           or http.request.uri.path eq "//wp-admin/admin-ajax.php")
)
```

### 40-RateLimit-Bots
Blocks IPs that send more than 50 requests in 10 seconds (bot/scanner behaviour).
Excludes admin/login pages (already handled by rule 30).
For WooCommerce: also excludes `/cart`, `/checkout`, `/my-account`, `/wp-json/wc/`.

## Free Plan Limitations

| Parameter | Free | Pro+ |
|---|---|---|
| `period` | **10 sec only** | 10/60/120/600 |
| `mitigation_timeout` | **10 sec only** | up to 86400 |
| Rate Limiting rules | **1 per zone** | more |
| Custom rules | **5 per zone** | more |
| Legacy `/rate_limits` API | deprecated | deprecated |

## How to find Zone ID
```
Cloudflare Dashboard → your domain → Overview → right sidebar → Zone ID
```

## Required API token permissions
```
Firewall Services → Edit
Zone WAF Rules → Edit
```

## Apply to multiple domains (loop example)
```bash
export CF_TOKEN="your_token"

declare -A ZONES=(
  ["doska-cz.ru"]="d377dd8df7e53dd5a7ad6557e350ff3b"
  ["doska-de.ru"]="137d6436e48fdbb7883ebd384a4f4930"
  ["doska-esp.ru"]="030c4064bd9bd0c24236ed6eb68677f5"
)

for domain in "${!ZONES[@]}"; do
  echo "=== $domain ==="
  export ZONE_ID="${ZONES[$domain]}"
  bash cf-secure-classifieds.sh
done
```
