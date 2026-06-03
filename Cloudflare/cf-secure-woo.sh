#!/bin/bash
# ============================================================
# cf-secure-woo.sh
# Cloudflare security hardening for WordPress + WooCommerce
# FREE PLAN | WooCommerce paths excluded from rate limiting
# = Rooted by VladiMIR + AI | v.2026.06.03 | github.com/GinCz =
# ============================================================
# USAGE:
#   export CF_TOKEN="your_api_token"
#   export ZONE_ID="your_zone_id"
#   bash cf-secure-woo.sh
# ============================================================

set -euo pipefail

CF_TOKEN="${CF_TOKEN:-}"
ZONE_ID="${ZONE_ID:-}"
API="https://api.cloudflare.com/client/v4"

if [[ -z "$CF_TOKEN" || -z "$ZONE_ID" ]]; then
    echo "❌ ERROR: CF_TOKEN and ZONE_ID must be set"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " CF Security — WordPress + WooCommerce  |  Zone: $ZONE_ID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cf_api() {
    curl -s -X "$1" "${API}${2}" \
        -H "Authorization: Bearer ${CF_TOKEN}" \
        -H "Content-Type: application/json" \
        ${3:+-d "$3"}
}

get_ruleset_id() {
    cf_api GET "/zones/${ZONE_ID}/rulesets" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for r in d.get('result', []):
    if r.get('phase') == 'http_request_firewall_custom':
        print(r['id']); break
"
}

upsert_rule() {
    local DESC="$1" EXPR="$2" ACTION="$3"
    local RID=$(get_ruleset_id)
    if [[ -z "$RID" ]]; then
        cf_api POST "/zones/${ZONE_ID}/rulesets" \
            "{\"name\":\"Custom Rules\",\"kind\":\"zone\",\"phase\":\"http_request_firewall_custom\",\"rules\":[{\"description\":\"${DESC}\",\"expression\":${EXPR},\"action\":\"${ACTION}\",\"enabled\":true}]}"
        return
    fi
    EXISTING=$(cf_api GET "/zones/${ZONE_ID}/rulesets/${RID}" | python3 -c "
import sys, json, os
d = json.load(sys.stdin)
rules = [r for r in d.get('result',{}).get('rules',[]) if r.get('description') != os.environ.get('_DESC')]
print(json.dumps(rules))
" _DESC="$DESC")
    NEW=$(python3 -c "
import json, sys
rules = json.loads(sys.argv[1])
rules.append({'description': sys.argv[2], 'expression': sys.argv[3], 'action': sys.argv[4], 'enabled': True})
print(json.dumps(rules))
" "$EXISTING" "$DESC" "$EXPR" "$ACTION")
    cf_api PUT "/zones/${ZONE_ID}/rulesets/${RID}" "{\"rules\": ${NEW}}"
}

check() {
    echo "$1" | python3 -c "
import sys, json
d = json.load(sys.stdin)
if d.get('success'): print('   ✅ OK')
else: print('   ❌ FAILED:', d.get('errors'))
"
}

# ================================================================
# RULE 20 — Block XMLRPC
# ================================================================
echo ""
echo "🛡️  Rule 1/3: 20-Block-XMLRPC"
RES=$(upsert_rule \
    "20-Block-XMLRPC" \
    '"(http.request.uri.path eq \"/xmlrpc.php\") or (http.request.uri.path eq \"//xmlrpc.php\")"' \
    "block")
check "$RES"

# ================================================================
# RULE 30 — Challenge WP Admin + Login
# ================================================================
echo ""
echo "🛡️  Rule 2/3: 30-Challenge-WP-Admin+Login"
RES=$(upsert_rule \
    "30-Challenge-WP-Admin+Login" \
    '"(http.request.uri.path eq \"/wp-login.php\" or http.request.uri.path eq \"//wp-login.php\") or ((starts_with(http.request.uri.path, \"/wp-admin/\") or starts_with(http.request.uri.path, \"//wp-admin/\")) and not (http.request.uri.path eq \"/wp-admin/admin-ajax.php\" or http.request.uri.path eq \"//wp-admin/admin-ajax.php\"))"' \
    "managed_challenge")
check "$RES"

# ================================================================
# RULE 40 — Rate Limiting with WooCommerce exceptions
# Excluded: /my-account, /cart, /checkout, /wp-json/wc/, ?wc-ajax=
# ================================================================
echo ""
echo "🛡️  Rule 3/3: 40-RateLimit-Bots (50 req/10s) [WooCommerce exceptions]"
RES=$(cf_api PUT "/zones/${ZONE_ID}/rulesets/phases/http_ratelimit/entrypoint" \
    '{"rules": [{"description": "40-RateLimit-Bots",
      "expression": "(http.request.uri.path ne \"/wp-login.php\") and (http.request.uri.path ne \"/wp-admin/\") and not starts_with(http.request.uri.path, \"/my-account\") and not starts_with(http.request.uri.path, \"/cart\") and not starts_with(http.request.uri.path, \"/checkout\") and not starts_with(http.request.uri.path, \"/wp-json/wc/\") and not (http.request.uri.query contains \"wc-ajax\")",
      "action": "block",
      "ratelimit": {"characteristics": ["ip.src", "cf.colo.id"], "period": 10, "requests_per_period": 50, "mitigation_timeout": 10},
      "enabled": true}]}')
check "$RES"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " ✅ Done! WooCommerce paths excluded from rate limiting."
echo " CF Dashboard → domain → Security → Security rules"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
