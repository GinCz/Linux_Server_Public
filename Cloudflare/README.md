# Cloudflare Security Scripts

> = Rooted by VladiMIR + AI | github.com/GinCz =

This folder contains three Bash scripts that configure **maximum Cloudflare security
hardening** for WordPress-based websites using the **Cloudflare API**.
All scripts are designed for the **FREE Cloudflare plan** and work without any paid features.
Every script is **fully idempotent** — safe to run multiple times on the same domain
without creating duplicate rules.

The scripts are organized by site type. Choose the one that matches your WordPress installation.

---

## Files in This Folder

### `cloudflare-wp.sh`
**For:** WordPress sites with no e-commerce and no user accounts (blogs, business cards,
portfolio sites, corporate websites, news portals).

**Security philosophy:** Maximum hardening with zero exceptions. No path on the site
is treated as "user-friendly" — all traffic is subject to full rate limiting and
all admin paths require a Managed Challenge.

**When to use this script:**
- The site has only one or two administrators who log in occasionally
- Regular visitors are just readers — they do not log in or submit anything
- There are no membership areas, no frontend forms that submit to the backend
- WooCommerce is NOT installed
- Directorist or any other classifieds plugin is NOT installed

**What this script applies:**
1. **Security Level → HIGH** — Cloudflare evaluates each visitor's IP reputation.
   IPs with a history of abuse (spam, bots, scrapers) are shown a Managed Challenge
   before they can access any page on the site.
2. **Browser Integrity Check → ON** — Cloudflare inspects the HTTP headers sent by
   each request. Requests that do not include standard browser headers (User-Agent,
   Accept, Accept-Language) are blocked. Most bots and automated scripts fail this check.
3. **Bot Fight Mode → ON** — Cloudflare actively fingerprints incoming traffic and
   blocks requests that match known bot signatures. This happens at the Cloudflare edge
   before the request ever reaches the origin server, saving server CPU and bandwidth.
4. **Rule 20 — Block XMLRPC (action: BLOCK)**
   WordPress exposes `/xmlrpc.php` as a remote procedure call interface. This endpoint
   is massively abused for credential brute-force attacks and DDoS amplification.
   Modern WordPress does not need xmlrpc.php for any user-facing functionality.
   Both `/xmlrpc.php` and `//xmlrpc.php` (double-slash variant used by some scanners)
   are permanently blocked.
5. **Rule 25 — Block Scanners (action: BLOCK)**
   Automated vulnerability scanners constantly probe WordPress sites for exposed
   configuration files, database credentials, and installation artifacts.
   The following paths are blocked: `/.env` (environment variables with DB passwords
   and API keys), `/config.` (any path containing this string — covers config.php,
   config.yml, config.json etc.), `/setup.php` (WordPress and plugin setup scripts),
   `/install.php` (installation scripts left behind after setup).
6. **Rule 30 — Managed Challenge on WP-Admin + WP-Login (action: MANAGED CHALLENGE)**
   All access to `/wp-login.php` and the entire `/wp-admin/` directory is intercepted
   by a Cloudflare Managed Challenge (Turnstile). A legitimate human administrator
   passes the challenge with one click and no CAPTCHA. Bots and automated login
   scripts fail the challenge and are blocked.
   Exception: `/wp-admin/admin-ajax.php` is excluded from the challenge because
   WordPress plugins use this endpoint for AJAX requests from the frontend
   (menus, search, dynamic content loading). Blocking it would break plugin functionality.
7. **Rule 40 — Rate Limiting: 50 requests per 10 seconds → Block for 10 seconds**
   If a single IP address makes more than 50 requests within any 10-second window,
   it is blocked for 10 seconds. This stops bots that crawl the entire site,
   scrapers harvesting content, and low-and-slow brute-force attacks.
   The wp-admin and wp-login paths are excluded from rate limiting because they
   are already protected by Rule 30.
   Note: The FREE Cloudflare plan has a minimum rate limit period of 10 seconds
   and a minimum mitigation timeout of 10 seconds.

---

### `cloudflare-wp-woo.sh`
**For:** WordPress sites with WooCommerce — online shops where customers browse
products, add items to cart, check out, and manage their orders through
a personal account.

**Security philosophy:** Same maximum hardening as `cloudflare-wp.sh`, but with
explicit exceptions for all WooCommerce customer-facing URLs. Without these exceptions,
legitimate shoppers would be blocked by the rate limiter when browsing product
categories, loading cart pages, or completing checkout.

**When to use this script:**
- WooCommerce is installed and active
- Customers register, log in, place orders, and view their order history
- The site has a `/cart`, `/checkout`, and `/my-account` page
- Payment gateways and webhooks use the WooCommerce REST API

**Key difference from `cloudflare-wp.sh`:**
The rate limiting rule (Rule 40) excludes the following WooCommerce paths:
- `/cart` — shopping cart page. A customer loading and refreshing the cart
  should never be blocked.
- `/checkout` — the checkout and payment page. Blocking checkout would
  directly cause lost sales.
- `/my-account` — the WooCommerce customer account area where users log in,
  view orders, update their address, and manage subscriptions.
- `/wc-api/` — the WooCommerce REST API endpoint used by payment gateways
  (PayPal, Stripe, GoPay) to send payment confirmations and webhooks.
  Blocking this would cause failed payment notifications.
- `/wp-json/wc/` — the WooCommerce blocks-based REST API, used by the
  modern WooCommerce block checkout and cart blocks. Required for
  Gutenberg-based WooCommerce pages.

All other rules (20, 25, 30) are identical to `cloudflare-wp.sh`.
Note: WooCommerce customer login goes through `/my-account/` — not through
`/wp-login.php`. So blocking `/wp-login.php` with a Managed Challenge does
not affect WooCommerce customers at all.

---

### `cloudflare-wp-class.sh`
**For:** WordPress sites running **Directorist** — a classifieds and business
directory plugin that allows users to register, log in, and manage their
own listings through the website frontend.

**Security philosophy:** Same maximum hardening as `cloudflare-wp.sh`, but with
explicit exceptions for all Directorist user-facing URLs. Without these exceptions,
registered users submitting or editing listings would be blocked by the rate limiter.

**When to use this script:**
- Directorist (or a similar classifieds plugin) is installed and active
- Users register on the site and log in through a frontend login page (not wp-login.php)
- Users can submit new listings, edit existing listings, and manage them from a dashboard
- The site has listing archive pages with search and filter functionality

**Key difference from `cloudflare-wp.sh`:**
The rate limiting rule (Rule 40) excludes the following Directorist paths:
- `/listing/` — single listing detail page. Visitors and registered users
  view individual listings here.
- `/listings/` — the listings archive page with search, filters, and map.
  Users browsing many listings would otherwise hit the rate limit.
- `/add-listing/` — the frontend form where registered users submit a new listing.
  This page makes multiple AJAX requests during form interaction (map loading,
  category selection, image upload). Rate limiting would break submission.
- `/edit-listing/` — the frontend form where registered users edit their
  existing listings. Same AJAX-heavy behavior as `/add-listing/`.
- `/dashboard/` — the user dashboard where registered users see all their
  listings, manage their account, and track listing status.
- `/login/` — the Directorist frontend login page. This is different from
  `/wp-login.php`. Regular site users log in here, not through the WP admin login.
- `/registration/` — the Directorist frontend registration page where new
  users create their account.

Note: Because Directorist users log in through `/login/` (not `/wp-login.php`),
blocking `/wp-login.php` with a Managed Challenge (Rule 30) does NOT affect
regular classifieds site users. It only affects the site administrator.
The admin-ajax.php exception in Rule 30 is critical for Directorist: the plugin
uses AJAX extensively for listing search, map rendering, and category filtering.

---

## Security Rules Applied by All Three Scripts

| Rule | Name | CF Action | What it blocks |
|------|------|-----------|----------------|
| 20 | 20-Block-XMLRPC | BLOCK | Brute-force and DDoS amplification via xmlrpc.php |
| 25 | 25-Block-Scanners | BLOCK | Automated vulnerability scanners probing for /.env, /config., /setup.php, /install.php |
| 30 | 30-Challenge-WP-Admin+Login | MANAGED CHALLENGE | Bot login attempts to /wp-login.php and /wp-admin/ |
| 40 | 40-RateLimit-Bots | BLOCK 10s | Any IP exceeding 50 requests in 10 seconds |

## Zone Settings Applied by All Three Scripts

| Setting | Value | Effect |
|---------|-------|--------|
| Security Level | HIGH | Challenges IPs with poor reputation score |
| Browser Integrity Check | ON | Blocks requests without standard browser HTTP headers |
| Bot Fight Mode | ON | Blocks known bot fingerprints at Cloudflare edge |

---

## Requirements

- `curl` — for making HTTP requests to the Cloudflare API
- `python3` — for parsing JSON responses (no external libraries needed)
- Cloudflare API token with **Zone:Edit** permissions
  (create at: Cloudflare Dashboard → My Profile → API Tokens → Create Token)

---

## Usage

### Run on a single domain

```bash
# Set your credentials
export CF_TOKEN="cfat_your_token_here"
export ZONE_ID="your_zone_id_here"

# Choose the script that matches your site type:
bash cloudflare-wp.sh          # WordPress only
bash cloudflare-wp-woo.sh      # WordPress + WooCommerce
bash cloudflare-wp-class.sh    # WordPress + Directorist (classifieds)
```

### Run on multiple domains in a loop

```bash
export CF_TOKEN="cfat_your_token_here"

# List your Zone IDs with a comment showing the domain name
ZONES=(
    "b5e42c21c0dc2dd05200320b2b85d3ce"  # alejandrofashion.cz
    "079717775d8df744045bf44d17b7af4b"  # autoservis-praha.eu
    "81a99e035e6f4cf0ece4233fa20d4c14"  # autoservis-rychlik.cz
)

for ZONE_ID in "${ZONES[@]}"; do
    export ZONE_ID
    bash cloudflare-wp.sh
done
```

### Find all Zone IDs for your account

```bash
curl -s "https://api.cloudflare.com/client/v4/zones?per_page=50" \
    -H "Authorization: Bearer $CF_TOKEN" | python3 -c "
import sys, json
for z in json.load(sys.stdin)['result']:
    print(z['id'], z['name'])
"
```

---

## Verify Results After Running

1. Open [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Select the domain you ran the script on
3. Go to **Security → Security Rules**
4. You should see four active rules:
   - `20-Block-XMLRPC` — status: Active
   - `25-Block-Scanners` — status: Active
   - `30-Challenge-WP-Admin+Login` — status: Active
   - `40-RateLimit-Bots` — status: Active (under Rate Limiting Rules section)
5. Go to **Security → Overview** and verify:
   - Security Level: High
   - Browser Integrity Check: On
6. Go to **Security → Bots** and verify:
   - Bot Fight Mode: On

---

## Free Plan Limitations

These scripts are designed to work within the FREE Cloudflare plan limits.

| Feature | Free Plan Limit | Used by scripts |
|---------|----------------|------------------|
| Custom Security Rules per zone | 5 | 3 (rules 20, 25, 30) |
| Rate Limiting Rules per zone | 1 | 1 (rule 40) |
| Rate Limit minimum period | 10 seconds | 10s |
| Rate Limit minimum timeout | 10 seconds | 10s |
| Bot Fight Mode | ✅ Free | Enabled |
| Browser Integrity Check | ✅ Free | Enabled |
| Security Level setting | ✅ Free | Set to HIGH |
| Managed Challenge (Turnstile) | ✅ Free | Used in rule 30 |

The scripts leave 2 custom rule slots free for manual rules you may add later
through the Cloudflare Dashboard.

---

Updated: 2026-06-03  
= Rooted by VladiMIR + AI =
