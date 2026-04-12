# Cloudflare WAF Custom Rules — Server 222-DE-NetCup
**Applied to:** ALL domains on 222-DE-NetCup (via Cloudflare Account-level or per-zone)  
**Updated:** 12.04.2026  

---

## Context

On 07.04.2026 site `diamond-odtah.cz` was under a bot attack.
Top attacker: `85.203.23.4` — 471 requests in last 1000 log lines.
Bursts up to 150 req/min observed. Bots were hitting WordPress entry points.

On 12.04.2026 site `timan-kuchyne.cz` was under attack: `103.186.31.44` made 1113 requests
to `/wp-login.php` in 1 hour. Root cause: domain was NOT proxied through Cloudflare (no cf-ray header),
so WAF rules never triggered. Fix: Nginx rate limit hardened server-side.

---

## ⚠️ Important: Cloudflare only works if domain is PROXIED (orange cloud)

Verify all domains are proxied:
```bash
curl -s -I https://domain.cz/wp-login.php | grep -i "cf-ray"
```
If no `cf-ray:` header → domain is DNS-only → WAF does NOT work → add orange cloud in Cloudflare DNS.

---

## Rule 20 — Block XMLRPC
**Action:** Block (hard block, no challenge)  
**Reason:** `xmlrpc.php` is a legacy WordPress XML API, almost never used legitimately.
Commonly abused for brute-force amplification attacks (one request → thousands of login attempts).

```
(http.request.uri.path eq "/xmlrpc.php") or (http.request.uri.path eq "//xmlrpc.php")
```
The `//xmlrpc.php` variant catches double-slash bypass attempts.

---

## Rule 30 — Challenge WP-Admin + WP-Login
**Action:** Managed Challenge (Cloudflare's smart challenge — bot → blocked, human → passes)  
**Reason:** All WordPress admin and login URLs should require human verification.
Bots cannot pass Managed Challenge.

```
(http.request.uri.path eq "/wp-login.php" or http.request.uri.path eq "//wp-login.php")
or (
  (starts_with(http.request.uri.path, "/wp-admin/") or starts_with(http.request.uri.path, "//wp-admin/"))
  and not (http.request.uri.path eq "/wp-admin/admin-ajax.php" or http.request.uri.path eq "//wp-admin/admin-ajax.php")
)
```

**Important exception:** `admin-ajax.php` is excluded from the challenge.  
Why: WooCommerce cart, WP frontend AJAX calls, contact forms all use this endpoint
for legitimate unauthenticated requests. Challenging it would break frontend functionality.

---

## Where to add in Cloudflare

1. Login to Cloudflare → select domain (or use Account-level rules for all domains)
2. Security → WAF → Custom Rules → Create Rule
3. Name the rule exactly as above (20-Block-XMLRPC, 30-Challenge-WP-Admin+Login)
4. Paste the expression, set action, Save
5. Make sure rules are ordered: Rule 20 before Rule 30

---

## Nginx server-side protection (fallback when Cloudflare not proxied)

See `00-wp-protection-zones.conf` — rate limit zones applied globally.

All sites: `burst=3 nodelay` on `wp-login.php` → 4th rapid request gets 429.
Zone: `rate=6r/m` = 1 request per 10 seconds per IP after burst exhausted.

Sites without explicit `location = /wp-login.php` (e.g. timan-kuchyne.cz):
added manually to `fastpanel2-available/nata_popkova/timan-kuchyne.cz.conf`.

---
_= Rooted by VladiMIR | AI =_
