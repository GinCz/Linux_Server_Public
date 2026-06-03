# Cloudflare Security Scripts

> = Rooted by VladiMIR + AI | github.com/GinCz =

Three bash scripts to apply maximum Cloudflare security hardening for WordPress sites
on the **FREE Cloudflare plan** via API.
Each script is fully idempotent — safe to run multiple times without creating duplicate rules.

---

## Scripts

| Script | Site type | Rules |
|--------|-----------|-------|
| `cloudflare-wp.sh` | WordPress only — no exceptions | 20 + 25 + 30 + 40 |
| `cloudflare-wp-woo.sh` | WordPress + WooCommerce (online shop) | 20 + 25 + 30 + 40 + WOO exceptions |
| `cloudflare-wp-class.sh` | WordPress + Directorist (classifieds) | 20 + 25 + 30 + 40 + DIR exceptions |

---

## What Each Script Applies

### Zone Settings (all 3 scripts)

| Setting | Value | Effect |
|---------|-------|--------|
| Security Level | HIGH | Challenges IPs with poor reputation |
| Browser Integrity Check | ON | Blocks bots missing standard HTTP headers |
| Bot Fight Mode | ON | Blocks known bots at Cloudflare edge |

### Security Rules (all 3 scripts)

| Rule | Name | Action | Protects against |
|------|------|--------|------------------|
| 20 | Block-XMLRPC | BLOCK | Brute-force and DDoS via xmlrpc.php |
| 25 | Block-Scanners | BLOCK | Automated vulnerability scanners (/.env, /config., /setup.php, /install.php) |
| 30 | Challenge-WP-Admin+Login | MANAGED CHALLENGE | Bot login attempts to wp-admin and wp-login |
| 40 | RateLimit-Bots | BLOCK 10s | Any IP making >50 requests in 10 seconds |

### Exceptions by Script

**`cloudflare-wp-woo.sh`** — WooCommerce paths excluded from rate limiting:
- `/cart` — shopping cart
- `/checkout` — payment page
- `/my-account` — customer account
- `/wc-api/` — WooCommerce REST API
- `/wp-json/wc/` — WooCommerce blocks API

**`cloudflare-wp-class.sh`** — Directorist paths excluded from rate limiting:
- `/listing/` — single listing page
- `/listings/` — listings archive
- `/add-listing/` — submit new listing
- `/edit-listing/` — edit existing listing
- `/dashboard/` — user dashboard
- `/login/` — frontend login
- `/registration/` — frontend registration

---

## Requirements

- `curl`
- `python3`
- Cloudflare API token with **Zone:Edit** permissions

---

## Usage

### Single domain

```bash
export CF_TOKEN="cfat_your_token_here"
export ZONE_ID="your_zone_id_here"
bash cloudflare-wp.sh
```

### Multiple domains in a loop

```bash
export CF_TOKEN="cfat_your_token_here"

ZONES=(
    "zone_id_1"  # domain1.com
    "zone_id_2"  # domain2.com
    "zone_id_3"  # domain3.com
)

for ZONE_ID in "${ZONES[@]}"; do
    export ZONE_ID
    bash cloudflare-wp-class.sh
done
```

### Find your Zone ID

```bash
curl -s "https://api.cloudflare.com/client/v4/zones?per_page=50" \
    -H "Authorization: Bearer YOUR_TOKEN" | python3 -c "
import sys, json
for z in json.load(sys.stdin)['result']:
    print(z['name'], z['id'])
"
```

---

## Verify Results

After running a script:

1. Open Cloudflare Dashboard
2. Select your domain
3. Go to **Security → Security Rules**
4. You should see: `20-Block-XMLRPC`, `25-Block-Scanners`, `30-Challenge-WP-Admin+Login`, `40-RateLimit-Bots`

---

## Free Plan Limits

| Feature | Free Limit | Used |
|---------|-----------|------|
| Custom Security Rules | 5 per zone | 3 used |
| Rate Limiting Rules | 1 per zone | 1 used |
| Rate Limit min period | 10 seconds | 10s |
| Rate Limit min timeout | 10 seconds | 10s |
| Bot Fight Mode | ✅ Free | Enabled |
| Browser Integrity Check | ✅ Free | Enabled |

---

Updated: 2026-06-03
= Rooted by VladiMIR + AI =
