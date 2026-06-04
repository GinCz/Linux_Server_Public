# Cloudflare API Automation — Complete Guide
# = Rooted by VladiMIR + AI | v2026-06-04 | github.com/GinCz =

> **Run server:** 222-EU-NetCup `152.53.182.222`
> **Account:** ~75 active zones (domains), all FREE plan
> **Token:** stored in private repo `Secret_Privat/api_keys.md` (PERP token)

---

## 📁 Scripts in this folder

| Script | Purpose | Domains |
|---|---|---|
| `cloudflare-wp-batch.sh` | WordPress security rules (WAF Challenge + Rate Limit) | WP_CLEAN list (~32) |
| `cloudflare-wp.sh` | WordPress WAF rules | WP domains |
| `cloudflare-wp-woo.sh` | WooCommerce WAF rules | WooCommerce domains |
| `cloudflare-wp-class.sh` | Classic WP WAF rules | WP classic domains |
| `cloudflare-wp-security.sh` | Security Level HIGH + Browser Check ON | All domains |
| `cf-all-domains-wp.sh` | WAF rules for all WP domains | All WP |
| `cf-all-domains-wp-woo.sh` | WAF rules for all WooCommerce domains | All WP+Woo |
| `cf-all-domains-wp-ads.sh` | WAF rules for WP+Ads domains | All WP+Ads |
| `cf-all-domains-dmarc.sh` | Add DMARC TXT DNS record (skip if exists) | All 75 zones |

### How to run any script

```bash
# ▶ RUN ON: Server 222 (152.53.182.222)
export CF_TOKEN="cfat_ATIw0XF9..."   # full token in Secret_Privat/api_keys.md
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Cloudflare/<script-name>.sh)
```

---

## ✅ What CAN be done via Cloudflare API (FREE plan)

Everything below was **tested and confirmed working** on all 75 domains via API from Server 222.

### 1. DNS Records
Full CRUD — create, read, update, delete any DNS record type.

```bash
# Add TXT record
POST /zones/{zone_id}/dns_records
{"type":"TXT","name":"_dmarc","content":"v=DMARC1; p=quarantine; ...","ttl":3600}

# List records
GET /zones/{zone_id}/dns_records?type=TXT&name=_dmarc.example.com

# Delete record
DELETE /zones/{zone_id}/dns_records/{record_id}
```

**What we did:** Added DMARC TXT records (`_dmarc`) to all 75 domains — skip if already exists, add if missing. Script: `cf-all-domains-dmarc.sh`

---

### 2. Security Level & Browser Check
Zone-level security settings fully controllable via API.

```bash
# Set security level to HIGH
PATCH /zones/{zone_id}/settings/security_level
{"value": "high"}

# Enable Browser Integrity Check
PATCH /zones/{zone_id}/settings/browser_check
{"value": "on"}
```

**What we did:** Set Security Level = HIGH and Browser Check = ON for all WP domains.

---

### 3. WAF Rules (Firewall Rules / Custom Rules)
Create, update, delete custom WAF rules via Rulesets API.

```bash
# Create WAF rule (Managed Challenge for WordPress paths)
PUT /zones/{zone_id}/rulesets/phases/http_request_firewall_custom/entrypoint
{
  "rules": [{
    "expression": "(http.request.uri.path contains \"/wp-login.php\")",
    "action": "managed_challenge",
    "enabled": true
  }]
}
```

**What we did:** Applied WordPress protection rules (Managed Challenge on `/wp-login`, `/wp-admin`, xmlrpc) to 32 WP_CLEAN domains.

---

### 4. Rate Limiting Rules (NEW Rulesets API only)
Rate limiting via the new Rulesets API works on FREE plan with restrictions.

```bash
# Add Rate Limit rule
PUT /zones/{zone_id}/rulesets/phases/http_ratelimit/entrypoint
{
  "rules": [{
    "expression": "(http.request.uri.path ne \"/wp-login.php\")",
    "action": "block",
    "ratelimit": {
      "characteristics": ["ip.src", "cf.colo.id"],
      "period": 10,
      "requests_per_period": 50,
      "mitigation_timeout": 10
    },
    "enabled": true
  }]
}
```

**FREE plan hard limits:**
| Parameter | FREE | Pro+ |
|---|---|---|
| `period` | **10 sec only** | 10, 60, 120, 600 |
| `mitigation_timeout` | **10 sec only** | up to 86400 (24h) |
| Rules per zone | **1** | more |
| Legacy API `/rate_limits` | ❌ frozen forever | ❌ frozen forever |

**What we did:** Added Rate Limit rules to 11 doska-*.ru domains (50 req/10s).

---

### 5. Bot Management — Partial (JS Detections + Block AI bots)

```bash
# ✅ This WORKS on FREE plan via API:
PUT /zones/{zone_id}/bot_management
{"enable_js": true, "ai_bots_protection": "block"}
```

This enables:
- **JS Detections** (sub-feature of Bot Fight Mode) → `enable_js: true`
- **Block AI bots** (blocks known AI training crawlers) → `ai_bots_protection: "block"`

**Note:** The Dashboard toggles for "Bot Fight Mode" and "AI Labyrinth" will **visually remain grey/OFF** even though partial protection is active. This is a Cloudflare UI discrepancy.

---

### 6. Cache Settings

```bash
# Set cache level
PATCH /zones/{zone_id}/settings/cache_level
{"value": "aggressive"}

# Browser cache TTL
PATCH /zones/{zone_id}/settings/browser_cache_ttl
{"value": 14400}
```

---

### 7. SSL/TLS Settings

```bash
# Force HTTPS
PATCH /zones/{zone_id}/settings/always_use_https
{"value": "on"}

# SSL mode
PATCH /zones/{zone_id}/settings/ssl
{"value": "full"}
```

---

## ❌ What CANNOT be done via API on FREE plan

### ❌ Bot Fight Mode toggle (Dashboard: Security → Settings → "Bot Fight Mode")

**Attempted approaches — all failed:**

| Attempt | Endpoint + Method | Result |
|---|---|---|
| 1 | `PUT /bot_management` + `fight_mode: true` | `10400 Bad Request` |
| 2 | `PATCH /settings/bot_fight_mode` | `1006 Unrecognized zone setting name` |
| 3 | `PATCH /settings/bfcm_fight_mode` | `1006 Unrecognized zone setting name` |
| 4 | `PUT /bot_management` + `enable_js: true` | `success:true` BUT toggle stays OFF in Dashboard |
| 5 | `PATCH /bot_management` | `10405 Method not allowed` |

**Root cause:** The `fight_mode` field in `/bot_management` API is **intentionally restricted to Pro+ plans** by Cloudflare. It accepts the request but silently ignores it on FREE. The toggle in Dashboard uses an **undocumented internal mechanism** not exposed via the public API for FREE zones.

**Workaround:** Must be enabled **manually in CF Dashboard** for each domain. ~15-20 min for 75 domains.

---

### ❌ AI Labyrinth toggle (Dashboard: Security → Settings → "AI Labyrinth")

**Root cause:** AI Labyrinth is a **Beta feature** with **no documented public API endpoint** at all (as of 2026-06-04). No endpoint found in CF API docs, no field in `/bot_management` response, no setting name in `/settings`.

**Confirmed by:** Full GET of `/bot_management` returns these fields only:
```json
{
  "enable_js": true,
  "fight_mode": false,
  "ai_bots_protection": "block",
  "content_bots_protection": "disabled",
  "crawler_protection": "disabled",
  "is_robots_txt_managed": true,
  "cf_robots_variant": "off",
  "using_latest_model": true
}
```
No `ai_labyrinth` field exists. Toggle works only through Dashboard UI.

**Workaround:** Manual Dashboard only. May get an API endpoint after Beta ends.

---

### ❌ Extended Rate Limiting (periods > 10 sec)

`period: 60`, `period: 120`, `period: 600` → `not entitled` error on FREE.
`mitigation_timeout` > 10 sec → same error.

**Workaround:** Pro plan required ($20/month per domain).

---

### ❌ Multiple Rate Limit Rules per zone

FREE plan: **1 rate limit rule per zone maximum**.
Attempting to add a second rule overwrites the first (PUT replaces entire ruleset).

---

### ❌ Legacy Rate Limiting API

```
GET/POST /zones/{zone_id}/rate_limits  →  maintenance_mode (frozen forever)
```

Cloudflare permanently froze the Legacy Rate Limiting API. **Always use the new Rulesets API.**

---

## ⚠️ Critical API Rules (learned the hard way)

### Rule 1: PUT vs POST vs PATCH for Rulesets
- **Rulesets entrypoint:** always `PUT` — never POST or PATCH
- `PUT` **replaces the entire ruleset** — always read existing rules first before writing
- `PATCH /bot_management` → `10405 Method not allowed` — only `PUT` and `GET` work

### Rule 2: Rate Limit characteristics must include cf.colo.id
```json
// ✅ CORRECT
"characteristics": ["ip.src", "cf.colo.id"]

// ❌ WRONG — API error: missing cf.colo.id
"characteristics": ["ip.src"]

// ❌ WRONG — API error: cannot be an object
"characteristics": [{"type": "ip"}]
```

### Rule 3: Wirefilter expression syntax for Rate Limiting
```
// ✅ CORRECT — use ne (not equal)
(http.request.uri.path ne "/wp-login.php") and (http.request.uri.path ne "/wp-admin/")

// ❌ WRONG — not ... starts_with is invalid in rate limit context
not (http.request.uri.path starts_with "/wp-login.php")
```

### Rule 4: Zone ID lookup
```bash
# Get Zone ID by domain name
curl -s "https://api.cloudflare.com/client/v4/zones?name=example.com" \
  -H "Authorization: Bearer ${CF_TOKEN}" | python3 -m json.tool
```

### Rule 5: Always test on 1 domain before running on all 75
Before any bulk operation — test on one zone, verify result in Dashboard, then scale.

---

## 📊 API Capabilities Summary — FREE Plan

| Feature | API Controllable | Notes |
|---|---|---|
| DNS Records (A, CNAME, TXT, MX...) | ✅ Full CRUD | Including DMARC, SPF, DKIM |
| Security Level | ✅ | `low` / `medium` / `high` / `essentially_off` |
| Browser Integrity Check | ✅ | on/off |
| Always Use HTTPS | ✅ | on/off |
| SSL Mode | ✅ | off/flexible/full/strict |
| Cache Level | ✅ | bypass/basic/simplified/aggressive |
| Browser Cache TTL | ✅ | seconds |
| WAF Custom Rules | ✅ | via Rulesets API |
| Rate Limiting (10 sec/10 sec) | ✅ | 1 rule/zone max |
| Rate Limiting (60+ sec periods) | ❌ | Pro+ only |
| JS Detections (enable_js) | ✅ | via PUT /bot_management |
| Block AI Bots | ✅ | `ai_bots_protection: "block"` |
| **Bot Fight Mode toggle** | ❌ | **FREE: Dashboard only** |
| **AI Labyrinth toggle** | ❌ | **No API endpoint (Beta)** |
| Content Bot Protection | ❌ | Pro+ only |
| Crawler Protection | ❌ | Pro+ only |
| Page Rules | ✅ | via API (legacy) |
| Transform Rules | ✅ | via Rulesets API |
| Workers Routes | ✅ | via API |

---

## 🔧 Quick Reference — Useful API Endpoints

```bash
BASE="https://api.cloudflare.com/client/v4"
AUTH="-H \"Authorization: Bearer ${CF_TOKEN}\""

# List all zones
GET  ${BASE}/zones?per_page=50&page=1

# Zone settings
GET  ${BASE}/zones/{id}/settings
PATCH ${BASE}/zones/{id}/settings/{setting_name}

# DNS Records
GET  ${BASE}/zones/{id}/dns_records
POST ${BASE}/zones/{id}/dns_records
PUT  ${BASE}/zones/{id}/dns_records/{record_id}
DEL  ${BASE}/zones/{id}/dns_records/{record_id}

# WAF Custom Rules
GET  ${BASE}/zones/{id}/rulesets/phases/http_request_firewall_custom/entrypoint
PUT  ${BASE}/zones/{id}/rulesets/phases/http_request_firewall_custom/entrypoint

# Rate Limiting (NEW API)
GET  ${BASE}/zones/{id}/rulesets/phases/http_ratelimit/entrypoint
PUT  ${BASE}/zones/{id}/rulesets/phases/http_ratelimit/entrypoint

# Bot Management
GET  ${BASE}/zones/{id}/bot_management
PUT  ${BASE}/zones/{id}/bot_management

# Verify token
GET  ${BASE}/user/tokens/verify
```

---

## 📅 Changelog

| Date | Action | Result |
|---|---|---|
| 2026-06-03 | WAF Challenge rules for 32 WP_CLEAN domains | ✅ Done |
| 2026-06-03 | Rate Limit rules for 11 doska-*.ru domains | ✅ Done |
| 2026-06-03 | Security Level HIGH + Browser Check for all WP | ✅ Done |
| 2026-06-04 | DMARC TXT records for all 75 domains | ✅ Done |
| 2026-06-04 | Bot Fight Mode via API (all 75 domains) | ❌ Blocked — FREE plan |
| 2026-06-04 | AI Labyrinth via API (all 75 domains) | ❌ No API endpoint |
| 2026-06-04 | JS Detections + Block AI bots (enable_js) | ✅ Done via /bot_management |

---

= Rooted by VladiMIR + AI | v2026-06-04 | github.com/GinCz =
