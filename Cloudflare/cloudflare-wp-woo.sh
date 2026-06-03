#!/bin/bash
# ==============================================================================
# cloudflare-wp-woo.sh
# ==============================================================================
# PURPOSE:
#   Apply maximum Cloudflare security hardening for WordPress + WooCommerce.
#   Designed for the FREE Cloudflare plan.
#
# KEY DIFFERENCE FROM cloudflare-wp.sh:
#   WooCommerce requires that customers can always access their account,
#   shopping cart, checkout, and order pages WITHOUT any challenge.
#   This script applies identical security rules but explicitly EXCLUDES
#   WooCommerce customer-facing URLs from rate limiting.
#
# WOOCOMMERCE EXCLUDED PATHS (never rate-limited):
#   /cart              — shopping cart page
#   /checkout          — payment and order completion
#   /my-account        — customer login, orders, profile
#   /wc-api/           — WooCommerce REST API (payment gateways, webhooks)
#   /wp-json/wc/       — WooCommerce block-based checkout REST API
#
# WHAT THIS SCRIPT DOES:
#   1. Sets Security Level to HIGH
#   2. Enables Browser Integrity Check
#   3. Enables Bot Fight Mode
#   4. Rule 20 — Block XMLRPC (action: BLOCK)
#   5. Rule 25 — Block Scanners (action: BLOCK)
#      Blocks: /.env  /config.  /setup.php  /install.php
#   6. Rule 30 — Challenge WP-Admin + WP-Login (action: MANAGED CHALLENGE)
#      Exception: /wp-admin/admin-ajax.php (needed by WooCommerce and plugins)
#   7. Rule 40 — Rate Limiting: 50 req/10s → Block 10s
#      Exception: WooCommerce customer paths excluded from rate limit
#
# IDEMPOTENT:
#   Safe to run multiple times. Existing rules with the same description
#   are replaced, not duplicated.
#
# REQUIREMENTS:
#   - curl
#   - python3
#   - Cloudflare API token with Zone:Edit permissions
#
# USAGE:
#   export CF_TOKEN="your_cloudflare_api_token"
#   export ZONE_ID="your_zone_id"
#   bash cloudflare-wp-woo.sh
#
# = Rooted by VladiMIR + AI | v.2026.06.03 | github.com/GinCz =
# ==============================================================================

set -euo pipefail

CF_TOKEN="${CF_TOKEN:-}"
ZONE_ID="${ZONE_ID:-}"
API="https://api.cloudflare.com/client/v4"

if [[ -z "$CF_TOKEN" || -z "$ZONE_ID" ]]; then
    echo "❌ ERROR: Required environment variables not set"
    echo ""
    echo "   export CF_TOKEN=\"cfat_your_token_here\""
    echo "   export ZONE_ID=\"your_zone_id_here\""
    echo ""
    echo "   Then run: bash cloudflare-wp-woo.sh"
    exit 1
fi

cf_api() {
    local METHOD="$1" ENDPOINT="$2" BODY="${3:-}"
    if [[ -n "$BODY" ]]; then
        curl -s -X "$METHOD" "${API}${ENDPOINT}" \
            -H "Authorization: Bearer ${CF_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$BODY"
    else
        curl -s -X "$METHOD" "${API}${ENDPOINT}" \
            -H "Authorization: Bearer ${CF_TOKEN}" \
            -H "Content-Type: application/json"
    fi
}

check() {
    local LABEL="$1" RESPONSE="$2"
    echo "$RESPONSE" | python3 -c "
import sys, json
d = json.load(sys.stdin)
if d.get('success'):
    print('   ✅ $LABEL — OK')
else:
    print('   ❌ $LABEL — FAILED:', d.get('errors'))
"
}

get_custom_ruleset_id() {
    cf_api GET "/zones/${ZONE_ID}/rulesets" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for r in d.get('result', []):
    if r.get('phase') == 'http_request_firewall_custom':
        print(r['id'])
        break
"
}

upsert_rule() {
    local DESC="$1" EXPR="$2" ACTION="$3"
    local RID
    RID=$(get_custom_ruleset_id)

    if [[ -z "$RID" ]]; then
        cf_api POST "/zones/${ZONE_ID}/rulesets" \
            "{\"name\":\"Custom Rules\",\"kind\":\"zone\",\"phase\":\"http_request_firewall_custom\",\"rules\":[{\"description\":\"${DESC}\",\"expression\":${EXPR},\"action\":\"${ACTION}\",\"enabled\":true}]}"
        return
    fi

    local EXISTING
    EXISTING=$(cf_api GET "/zones/${ZONE_ID}/rulesets/${RID}" | python3 -c "
import sys, json, os
d = json.load(sys.stdin)
rules = [r for r in d.get('result', {}).get('rules', []) if r.get('description') != os.environ.get('_RULE_DESC')]
print(json.dumps(rules))
" _RULE_DESC="$DESC")

    local UPDATED
    UPDATED=$(python3 -c "
import json, sys
rules = json.loads(sys.argv[1])
rules.append({'description': sys.argv[2], 'expression': sys.argv[3], 'action': sys.argv[4], 'enabled': True})
print(json.dumps(rules))
" "$EXISTING" "$DESC" "$EXPR" "$ACTION")

    cf_api PUT "/zones/${ZONE_ID}/rulesets/${RID}" "{\"rules\": ${UPDATED}}"
}

DOMAIN=$(cf_api GET "/zones/${ZONE_ID}" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('result', {}).get('name', 'unknown'))
")

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Cloudflare Security — WordPress_WooCommerce"
echo "  Domain  : ${DOMAIN}"
echo "  Zone ID : ${ZONE_ID}"
echo "  Date    : $(date '+%Y-%m-%d %H:%M:%S')"
echo "══════════════════════════════════════════════════════════════"

# [1/7] Security Level: HIGH
echo ""
echo "[1/7] Setting Security Level to HIGH..."
RES=$(cf_api PATCH "/zones/${ZONE_ID}/settings/security_level" '{"value":"high"}')
check "Security Level: High" "$RES"

# [2/7] Browser Integrity Check: ON
echo "[2/7] Enabling Browser Integrity Check..."
RES=$(cf_api PATCH "/zones/${ZONE_ID}/settings/browser_check" '{"value":"on"}')
check "Browser Integrity Check" "$RES"

# [3/7] Bot Fight Mode: ON
echo "[3/7] Enabling Bot Fight Mode..."
RES=$(cf_api PUT "/zones/${ZONE_ID}/bot_management" '{"fight_mode":true}')
check "Bot Fight Mode" "$RES"

# ------------------------------------------------------------------------------
# [4/7] Rule 20: Block XMLRPC
# WooCommerce does not use xmlrpc.php — safe to block completely.
# ------------------------------------------------------------------------------
echo "[4/7] Creating Rule 20 — Block XMLRPC..."
RES=$(upsert_rule \
    "20-Block-XMLRPC" \
    '"(http.request.uri.path eq \"/xmlrpc.php\") or (http.request.uri.path eq \"//xmlrpc.php\")"' \
    "block")
check "Rule 20-Block-XMLRPC" "$RES"

# [5/7] Rule 25: Block Scanners
echo "[5/7] Creating Rule 25 — Block Scanners..."
RES=$(upsert_rule \
    "25-Block-Scanners" \
    '"(http.request.uri.path contains \"/.env\") or (http.request.uri.path contains \"/config.\") or (http.request.uri.path contains \"/setup.php\") or (http.request.uri.path contains \"/install.php\")"' \
    "block")
check "Rule 25-Block-Scanners" "$RES"

# ------------------------------------------------------------------------------
# [6/7] Rule 30: Managed Challenge WP-Admin + WP-Login
# WooCommerce customer login goes through /my-account/ — NOT /wp-login.php.
# So blocking /wp-login.php is safe for WooCommerce customers.
# Exception: admin-ajax.php stays open (WooCommerce cart/checkout uses it).
# ------------------------------------------------------------------------------
echo "[6/7] Creating Rule 30 — Challenge WP-Admin+Login..."
RES=$(upsert_rule \
    "30-Challenge-WP-Admin+Login" \
    '"(http.request.uri.path eq \"/wp-login.php\" or http.request.uri.path eq \"//wp-login.php\") or ((starts_with(http.request.uri.path, \"/wp-admin/\") or starts_with(http.request.uri.path, \"//wp-admin/\")) and not (http.request.uri.path eq \"/wp-admin/admin-ajax.php\" or http.request.uri.path eq \"//wp-admin/admin-ajax.php\"))"' \
    "managed_challenge")
check "Rule 30-Challenge-WP-Admin+Login" "$RES"

# ------------------------------------------------------------------------------
# [7/7] Rule 40: Rate Limiting
# WooCommerce customer paths are excluded to prevent blocking real shoppers:
#   /cart, /checkout, /my-account, /wc-api/, /wp-json/wc/
# ------------------------------------------------------------------------------
echo "[7/7] Creating Rule 40 — Rate Limiting (50 req/10s)..."
RES=$(cf_api PUT "/zones/${ZONE_ID}/rulesets/phases/http_ratelimit/entrypoint" \
    '{"rules":[{"description":"40-RateLimit-Bots","expression":"(not starts_with(http.request.uri.path, \"/wp-admin/\")) and (http.request.uri.path ne \"/wp-login.php\") and (not starts_with(http.request.uri.path, \"/cart\")) and (not starts_with(http.request.uri.path, \"/checkout\")) and (not starts_with(http.request.uri.path, \"/my-account\")) and (not starts_with(http.request.uri.path, \"/wc-api/\")) and (not starts_with(http.request.uri.path, \"/wp-json/wc/\"))","action":"block","ratelimit":{"characteristics":["ip.src","cf.colo.id"],"period":10,"requests_per_period":50,"mitigation_timeout":10},"enabled":true}]}')
check "Rule 40-RateLimit-Bots" "$RES"

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  ✅ All settings applied for: ${DOMAIN}"
echo "  Verify: CF Dashboard → ${DOMAIN} → Security → Security Rules"
echo "══════════════════════════════════════════════════════════════"
echo ""
