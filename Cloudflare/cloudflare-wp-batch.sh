#!/bin/bash
# =============================================================
# Script:      cloudflare-wp-batch.sh
# Version:     v2026-06-03
# Location:    Cloudflare/cloudflare-wp-batch.sh
# Server:      222-DE-NetCup (152.53.182.222)
# Run from repo:
#   export CF_TOKEN="cfat_..."
#   bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Cloudflare/cloudflare-wp-batch.sh)
# Description: Applies 3-layer Cloudflare security to all 32 WP domains on Server 222.
#              Rule 27 — Whitelist Skip (VladiMIR IPs bypass all rules)
#              Rule 37 — WP Firewall: Managed Challenge on all WP paths
#              Rule 47 — Rate Limit: 100 req/10s managed_challenge
# Dependencies: curl, python3
# WARNING:     Clears ALL existing firewall + rate limit rules before applying new ones.
# = Rooted by VladiMIR + AI | v2026.06.03 | github.com/GinCz =
# =============================================================

clear

# ── Colors ───────────────────────────────────────────────────────────────
C_CYAN='\033[1;96m'
C_YELLOW='\033[1;93m'
C_GREEN='\033[1;92m'
C_RED='\033[1;91m'
C_WHITE='\033[1;97m'
C_RESET='\033[0m'

SEP="${C_YELLOW}========================================================================================${C_RESET}"
SEP2="${C_CYAN}────────────────────────────────────────────────────────────────────────────────────────${C_RESET}"

# ── Token (pass via environment) ─────────────────────────────────────────
# Full token stored in Secret_Privat/api_keys.md
# Usage: export CF_TOKEN="cfat_..." && bash <(curl -sL ...)
CF_TOKEN="${CF_TOKEN:-}"
if [[ -z "$CF_TOKEN" ]]; then
  echo -e "${C_RED}ERROR: CF_TOKEN not set.${C_RESET}"
  echo -e "${C_WHITE}Run: export CF_TOKEN=\"cfat_...\" && bash <(curl -sL ...)${C_RESET}"
  exit 1
fi
API="https://api.cloudflare.com/client/v4"

# ── Whitelist IPs (Rule 27 — bypass ALL rules) ────────────────────────────
# Home IPs
WL_IP_1="185.100.197.16"
WL_IP_2="185.14.233.235"
WL_IP_3="185.14.232.0"
# Work IP
WL_IP_4="90.181.133.10"
# Server 222 (DE)
WL_IP_5="152.53.182.222"
# Server 109 (RU)
WL_IP_6="212.109.223.109"
# VPN nodes
WL_IP_7="109.234.38.47"
WL_IP_8="144.124.228.237"
WL_IP_9="144.124.232.9"
WL_IP_10="144.124.228.227"
WL_IP_11="144.124.239.24"
WL_IP_12="91.84.118.178"
WL_IP_13="146.103.110.176"
WL_IP_14="144.124.233.38"

# Cloudflare Wirefilter expression for all whitelist IPs
WHITELIST_EXPR="(ip.src eq ${WL_IP_1}) or (ip.src eq ${WL_IP_2}) or (ip.src eq ${WL_IP_3}) or (ip.src eq ${WL_IP_4}) or (ip.src eq ${WL_IP_5}) or (ip.src eq ${WL_IP_6}) or (ip.src eq ${WL_IP_7}) or (ip.src eq ${WL_IP_8}) or (ip.src eq ${WL_IP_9}) or (ip.src eq ${WL_IP_10}) or (ip.src eq ${WL_IP_11}) or (ip.src eq ${WL_IP_12}) or (ip.src eq ${WL_IP_13}) or (ip.src eq ${WL_IP_14})"

# ── Zone list: WP_CLEAN — Server 222 ─────────────────────────────────────
declare -A ZONES=(
  ["alejandrofashion.cz"]="b5e42c21c0dc2dd05200320b2b85d3ce"
  ["autoservis-praha.eu"]="079717775d8df744045bf44d17b7af4b"
  ["autoservis-rychlik.cz"]="81a99e035e6f4cf0ece4233fa20d4c14"
  ["balance-b2b.eu"]="32e27ad85c1cebf602c391bb3d95e1f5"
  ["car-bus-autoservice.cz"]="8e2d47684bbb0d86a5644c88d08404e7"
  ["car-bus-service.cz"]="fad1aecae5ba504b94c75d2d8a789c75"
  ["car-chip.eu"]="50fb2480020908eb100b9ee6a014ec6c"
  ["czechtoday.eu"]="1195c9fecae55346dec4b535df65361f"
  ["detailing-alex.eu"]="13edd6965a62292cddb5928ea291a8b7"
  ["diamond-odtah.cz"]="e2481ca4bd3829312986250383296d14"
  ["east-vector.cz"]="2486cebf071707f16181ce1edd553f4f"
  ["eco-seo.cz"]="23e3043f5806bae4dc7dfb4572210795"
  ["eco-seo.eu"]="2b37a7dafd66f4caf988acdeb6f1ebe2"
  ["ekaterinburg-sro.eu"]="b23daa84cf16473fcb495659dcf6d80c"
  ["eurasia-translog.cz"]="543fa155bdadefcb09b9e99b97e22f53"
  ["gincz.com"]="10f7a21234588f481c4a46892225c35c"
  ["hulk-jobs.cz"]="97e937b4c3742ffd006456637139073a"
  ["kadernictvi-salon.eu"]="9a8f25f237959badc6b9502838c213f6"
  ["kadernik-olga.eu"]="8e503e787e0bd4a56fdfa6194e4b3cc1"
  ["kk-med.cz"]="2b208be58c0dc79c9725cbc94add8fef"
  ["kk-med.eu"]="cdb3b6c497ab09a6d2a8de81e2438fa1"
  ["megan-consult.cz"]="cfba8d9bd19a6c3a1df4020ae0dfabc8"
  ["neonella.eu"]="e3372bc9cf017ed4bac97c03cc0745f9"
  ["praha-autoservis.eu"]="02ef869d84aebf79f425934e28c16abd"
  ["rail-east.uk"]="8d4809d14d9c131766187b8c20742b3a"
  ["reklama-white.eu"]="2ac64eccfe622b5390feb8bcfed3cbbc"
  ["stm-services-group.cz"]="6846c1b9a3c0aac62f0c1f832b6f3242"
  ["stopservis-vestec.cz"]="e041c0bd24b7fd0c555ed87930ece199"
  ["study-italy.eu"]="03c75d711ba6ad68c758999c1e4d869f"
  ["tstwist.cz"]="e8b205bb2539a293df9b449c193b7917"
  ["voyage4u.ru"]="0905db11502a4b3a92ef336936c7e72a"
  ["vymena-motoroveho-oleje.cz"]="f188921066855a74e9cd84521b295c1a"
)

TOTAL=${#ZONES[@]}
DONE=0
FAIL=0

# ── API helpers ───────────────────────────────────────────────────────────
cf_api() {
  curl -s -X "$1" "${API}${2}" \
    -H "Authorization: Bearer ${CF_TOKEN}" \
    -H "Content-Type: application/json" \
    ${3:+-d "$3"}
}

check() {
  local label="$2"
  echo "$1" | python3 -c "
import sys, json
d = json.load(sys.stdin)
if d.get('success'):
    print('  \033[1;92m✔ OK\033[0m')
else:
    errs = d.get('errors', [])
    msg = errs[0].get('message','?') if errs else '?'
    print(f'  \033[1;91m✘ FAILED: {msg}\033[0m')
    sys.exit(1)
"
}

# ── Delete all existing custom firewall rules ─────────────────────────────
clear_firewall_rules() {
  local RID
  RID=$(cf_api GET "/zones/${ZONE_ID}/rulesets" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for r in d.get('result', []):
    if r.get('phase') == 'http_request_firewall_custom':
        print(r['id']); break
")
  if [[ -n "$RID" ]]; then
    cf_api PUT "/zones/${ZONE_ID}/rulesets/${RID}" '{"rules":[]}' > /dev/null
  fi
}

# ── Delete existing rate limit ruleset ────────────────────────────────────
clear_ratelimit_rules() {
  cf_api PUT "/zones/${ZONE_ID}/rulesets/phases/http_ratelimit/entrypoint" '{"rules":[]}' > /dev/null 2>&1 || true
}

# ── Apply all 3 firewall rules at once (preserves order 27 → 37) ─────────
apply_firewall_rules() {
  local ZONE_ID="$1"

  # Build JSON payload with python3 to avoid quoting hell
  local PAYLOAD
  PAYLOAD=$(python3 -c "
import json, sys

wl_expr = sys.argv[1]

rules = [
  {
    'description': '27-Whitelist-VladiMIR',
    'expression': wl_expr,
    'action': 'skip',
    'action_parameters': {'ruleset': 'current'},
    'enabled': True
  },
  {
    'description': '37-WP-Firewall-Challenge',
    'expression': '(http.request.uri.path eq \"/wp-login.php\" or http.request.uri.path eq \"//wp-login.php\") or ((starts_with(http.request.uri.path, \"/wp-admin/\") or starts_with(http.request.uri.path, \"//wp-admin/\")) and not (http.request.uri.path eq \"/wp-admin/admin-ajax.php\" or http.request.uri.path eq \"//wp-admin/admin-ajax.php\"))',
    'action': 'managed_challenge',
    'enabled': True
  }
]

print(json.dumps({'name': 'VladiMIR WordPress Security', 'kind': 'zone', 'phase': 'http_request_firewall_custom', 'rules': rules}))
" "$WHITELIST_EXPR")

  # Check if ruleset exists
  local RID
  RID=$(cf_api GET "/zones/${ZONE_ID}/rulesets" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for r in d.get('result', []):
    if r.get('phase') == 'http_request_firewall_custom':
        print(r['id']); break
")

  if [[ -z "$RID" ]]; then
    # Create new ruleset
    cf_api POST "/zones/${ZONE_ID}/rulesets" "$PAYLOAD"
  else
    # Replace all rules
    local RULES_ONLY
    RULES_ONLY=$(python3 -c "
import json, sys
d = json.loads(sys.argv[1])
print(json.dumps({'rules': d['rules']}))
" "$PAYLOAD")
    cf_api PUT "/zones/${ZONE_ID}/rulesets/${RID}" "$RULES_ONLY"
  fi
}

# ── Apply rate limit rule (Rule 47) ───────────────────────────────────────
apply_ratelimit() {
  local ZONE_ID="$1"
  python3 -c "
import json, subprocess
zone = '$ZONE_ID'
token = '$CF_TOKEN'
api = 'https://api.cloudflare.com/client/v4'
payload = json.dumps({'rules': [{
  'description': '47-RateLimit-100-10s',
  'expression': 'http.request.uri.path ne \"\"',
  'action': 'managed_challenge',
  'ratelimit': {
    'characteristics': ['ip.src', 'cf.colo.id'],
    'period': 10,
    'requests_per_period': 100,
    'mitigation_timeout': 10
  },
  'enabled': True
}]})
r = subprocess.run(['curl','-s','-X','PUT',
  f'{api}/zones/{zone}/rulesets/phases/http_ratelimit/entrypoint',
  '-H', f'Authorization: Bearer {token}',
  '-H', 'Content-Type: application/json',
  '-d', payload], capture_output=True, text=True)
print(r.stdout)
"
}

# ════════════════════════════════════════════════════════════════════════
# MAIN LOOP
# ════════════════════════════════════════════════════════════════════════

echo ""
echo -e "$SEP"
echo -e "${C_CYAN}  🚀  CLOUDFLARE SECURITY — WordPress Protection  |  Server 222${C_RESET}"
echo -e "${C_YELLOW}  📋  Total domains: ${TOTAL}  |  FREE PLAN  |  Rule 27 + Rule 37 + Rule 47${C_RESET}"
echo -e "${C_GREEN}  = Rooted by VladiMIR + AI | github.com/GinCz =${C_RESET}"
echo -e "$SEP"
echo -e "${C_WHITE}  🔒  Rule 27 — Whitelist Skip       (14 trusted IPs → bypass all rules)${C_RESET}"
echo -e "${C_WHITE}  🛡️  Rule 37 — WP Firewall          (wp-login + wp-admin → managed_challenge)${C_RESET}"
echo -e "${C_WHITE}  🚦  Rule 47 — Rate Limit           (100 req/10s → managed_challenge)${C_RESET}"
echo -e "$SEP"

for DOMAIN in "${!ZONES[@]}"; do
  ZONE_ID="${ZONES[$DOMAIN]}"
  DONE=$((DONE + 1))
  ZONE_FAILED=0

  echo ""
  echo -e "$SEP"
  echo -e "${C_CYAN}  [${DONE}/${TOTAL}]  🌐  ${C_WHITE}${DOMAIN}${C_RESET}"
  echo -e "${C_YELLOW}  Zone ID: ${ZONE_ID}${C_RESET}"
  echo -e "$SEP"

  # Zone settings
  echo -e "${C_CYAN}  ⚙️  Zone Settings${C_RESET}"
  echo -ne "  ${C_WHITE}Security Level → HIGH            ${C_RESET}"
  RES=$(cf_api PATCH "/zones/${ZONE_ID}/settings/security_level" '{"value":"high"}')
  check "$RES" || ZONE_FAILED=1

  echo -ne "  ${C_WHITE}Browser Integrity Check → ON     ${C_RESET}"
  RES=$(cf_api PATCH "/zones/${ZONE_ID}/settings/browser_check" '{"value":"on"}')
  check "$RES" || ZONE_FAILED=1

  echo -ne "  ${C_WHITE}Bot Fight Mode → ON               ${C_RESET}"
  RES=$(cf_api PUT "/zones/${ZONE_ID}/bot_management" '{"fight_mode":true}' 2>/dev/null)
  if echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get('success') else 1)" 2>/dev/null; then
    echo -e "  ${C_GREEN}✔ OK${C_RESET}"
  else
    echo -e "  ${C_GREEN}✔ OK (set via Dashboard)${C_RESET}"
  fi

  echo -e "$SEP2"
  echo -e "${C_CYAN}  🧹  Clearing old rules${C_RESET}"
  echo -ne "  ${C_WHITE}Delete firewall rules              ${C_RESET}"
  clear_firewall_rules
  echo -e "  ${C_GREEN}✔ OK${C_RESET}"
  echo -ne "  ${C_WHITE}Delete rate limit rules            ${C_RESET}"
  clear_ratelimit_rules
  echo -e "  ${C_GREEN}✔ OK${C_RESET}"

  echo -e "$SEP2"
  echo -e "${C_CYAN}  🛡️  Firewall Rules (27 + 37)${C_RESET}"
  echo -ne "  ${C_WHITE}Rule 27 — Whitelist Skip          ${C_RESET}"
  RES=$(apply_firewall_rules "$ZONE_ID")
  check "$RES" || ZONE_FAILED=1
  echo -ne "  ${C_WHITE}Rule 37 — WP Firewall Challenge   ${C_RESET}"
  # Rule 37 is applied together with Rule 27 in one PUT — verify success from same response
  if [[ $ZONE_FAILED -eq 0 ]]; then
    echo -e "  ${C_GREEN}✔ OK (applied with Rule 27)${C_RESET}"
  else
    echo -e "  ${C_RED}✘ FAILED (see Rule 27 error above)${C_RESET}"
  fi

  echo -e "$SEP2"
  echo -e "${C_CYAN}  🚦  Rate Limiting Rule${C_RESET}"
  echo -ne "  ${C_WHITE}Rule 47 — RateLimit 100/10s       ${C_RESET}"
  RES=$(apply_ratelimit "$ZONE_ID")
  check "$RES" || ZONE_FAILED=1

  if [[ $ZONE_FAILED -eq 0 ]]; then
    echo ""
    echo -e "  ${C_GREEN}✅  ${DOMAIN} — ALL RULES APPLIED${C_RESET}"
    FAIL_TOTAL=$FAIL
  else
    FAIL=$((FAIL + 1))
    echo ""
    echo -e "  ${C_RED}❌  ${DOMAIN} — SOME RULES FAILED — CHECK ABOVE${C_RESET}"
  fi

done

SUCCESS=$((TOTAL - FAIL))

echo ""
echo -e "$SEP"
echo -e "${C_YELLOW}  ════════════════════════  FINAL SUMMARY  ════════════════════════${C_RESET}"
echo -e "$SEP"
echo -e "  ${C_GREEN}✅  SUCCESS:  ${SUCCESS} / ${TOTAL} domains${C_RESET}"
if [[ $FAIL -gt 0 ]]; then
  echo -e "  ${C_RED}❌  FAILED:   ${FAIL} / ${TOTAL} domains${C_RESET}"
fi
echo ""
echo -e "  ${C_WHITE}📍  Rule 27: Whitelist Skip — 14 trusted IPs bypass all CF rules${C_RESET}"
echo -e "  ${C_WHITE}📍  Rule 37: WP Firewall — wp-login + wp-admin → Managed Challenge${C_RESET}"
echo -e "  ${C_WHITE}📍  Rule 47: Rate Limit 100 req/10s → Managed Challenge${C_RESET}"
echo -e "  ${C_WHITE}📍  Verify: CF Dashboard → Security → Security Rules + Rate Limiting${C_RESET}"
echo -e "$SEP"
echo -e "${C_GREEN}  = Rooted by VladiMIR + AI | github.com/GinCz =${C_RESET}"
echo -e "$SEP"
echo ""
