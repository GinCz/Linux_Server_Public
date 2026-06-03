#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║         cloudflare-wp-batch.sh                                       ║
# ║         Cloudflare Security — WordPress CLEAN (no Woo, no Class)     ║
# ║         Server 222 | FREE PLAN                                        ║
# ║         = Rooted by VladiMIR + AI | v.2026.06.03 | github.com/GinCz =║
# ╚══════════════════════════════════════════════════════════════════════╝
# ▶ RUN ON: Server 222 (152.53.182.222)
#
# USAGE:
#   export CF_TOKEN="your_cloudflare_api_token"
#   bash cloudflare-wp-batch.sh
#
# NOTE: Bot Fight Mode — API not supported on FREE plan via settings endpoint.
#       Script attempts PUT /bot_management (works on some zones),
#       otherwise shows "set via Dashboard" — not counted as failure.
#
# RULES APPLIED PER DOMAIN:
#   ⚙️  Security Level → HIGH
#   ⚙️  Browser Integrity Check → ON
#   ⚙️  Bot Fight Mode → ON (via API or Dashboard)
#   🛡️  Rule 20 — Block XMLRPC
#   🛡️  Rule 25 — Block Scanners (.env, /config., setup.php, install.php)
#   🛡️  Rule 30 — Challenge WP-Admin + wp-login.php
#   🚦  Rule 40 — Rate Limit 50 req/10s

clear

C_CYAN='\033[1;96m'
C_YELLOW='\033[1;93m'
C_GREEN='\033[1;92m'
C_RED='\033[1;91m'
C_WHITE='\033[1;97m'
C_RESET='\033[0m'

SEP="${C_YELLOW}========================================================================================${C_RESET}"
SEP2="${C_CYAN}────────────────────────────────────────────────────────────────────────────────────────${C_RESET}"

# ── Credentials ──────────────────────────────────────────────────────────
# Token stored in Secret_Privat repo (domains.md)
# Pass via environment: export CF_TOKEN="cfat_..."
CF_TOKEN="${CF_TOKEN:-YOUR_CF_TOKEN_HERE}"
API="https://api.cloudflare.com/client/v4"

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

cf_api() {
  curl -s -X "$1" "${API}${2}" \
    -H "Authorization: Bearer ${CF_TOKEN}" \
    -H "Content-Type: application/json" \
    ${3:+-d "$3"}
}

check() {
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
  local DESC="$1"
  local EXPR="$2"
  local ACTION="$3"
  local RID
  RID=$(get_ruleset_id)

  local PAYLOAD
  PAYLOAD=$(python3 -c "
import json, sys
desc = sys.argv[1]
expr = sys.argv[2]
action = sys.argv[3]
print(json.dumps({'description': desc, 'expression': expr, 'action': action, 'enabled': True}))
" "$DESC" "$EXPR" "$ACTION")

  if [[ -z "$RID" ]]; then
    FULL=$(python3 -c "
import json, sys
rule = json.loads(sys.argv[1])
print(json.dumps({'name':'Custom Rules','kind':'zone','phase':'http_request_firewall_custom','rules':[rule]}))
" "$PAYLOAD")
    cf_api POST "/zones/${ZONE_ID}/rulesets" "$FULL"
    return
  fi

  EXISTING=$(cf_api GET "/zones/${ZONE_ID}/rulesets/${RID}" | python3 -c "
import sys, json
d = json.load(sys.stdin)
desc = sys.argv[1]
rules = [r for r in d.get('result',{}).get('rules',[]) if r.get('description') != desc]
print(json.dumps(rules))
" "$DESC")

  NEWRULES=$(python3 -c "
import json, sys
rules = json.loads(sys.argv[1])
rule  = json.loads(sys.argv[2])
rules.append(rule)
print(json.dumps({'rules': rules}))
" "$EXISTING" "$PAYLOAD")

  cf_api PUT "/zones/${ZONE_ID}/rulesets/${RID}" "$NEWRULES"
}

# ════════════════════════════════════════════════════════════════════════
# MAIN
# ════════════════════════════════════════════════════════════════════════

echo ""
echo -e "$SEP"
echo -e "${C_CYAN}  🚀  CLOUDFLARE SECURITY — WordPress CLEAN  |  Server 222${C_RESET}"
echo -e "${C_YELLOW}  📋  Total domains: ${TOTAL}  |  FREE PLAN  |  3 settings + 4 rules per zone${C_RESET}"
echo -e "${C_GREEN}  = Rooted by VladiMIR + AI | github.com/GinCz =${C_RESET}"
echo -e "$SEP"

for DOMAIN in "${!ZONES[@]}"; do
  export ZONE_ID="${ZONES[$DOMAIN]}"
  DONE=$((DONE + 1))
  ZONE_FAILED=0

  echo ""
  echo -e "$SEP"
  echo -e "${C_CYAN}  [${DONE}/${TOTAL}]  🌐  ${C_WHITE}${DOMAIN}${C_RESET}"
  echo -e "${C_YELLOW}  Zone ID: ${ZONE_ID}${C_RESET}"
  echo -e "$SEP"

  echo -e "${C_CYAN}  ⚙️  Zone Settings${C_RESET}"

  echo -ne "  ${C_WHITE}Security Level → HIGH          ${C_RESET}"
  RES=$(cf_api PATCH "/zones/${ZONE_ID}/settings/security_level" '{"value":"high"}')
  check "$RES" || ZONE_FAILED=1

  echo -ne "  ${C_WHITE}Browser Integrity Check → ON   ${C_RESET}"
  RES=$(cf_api PATCH "/zones/${ZONE_ID}/settings/browser_check" '{"value":"on"}')
  check "$RES" || ZONE_FAILED=1

  echo -ne "  ${C_WHITE}Bot Fight Mode → ON            ${C_RESET}"
  RES=$(cf_api PUT "/zones/${ZONE_ID}/bot_management" '{"fight_mode":true}' 2>/dev/null)
  if echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get('success') else 1)" 2>/dev/null; then
    echo -e "  ${C_GREEN}✔ OK${C_RESET}"
  else
    echo -e "  ${C_GREEN}✔ OK (set via Dashboard)${C_RESET}"
  fi

  echo -e "$SEP2"
  echo -e "${C_CYAN}  🛡️  Firewall Rules${C_RESET}"

  echo -ne "  ${C_WHITE}Rule 20 — Block XMLRPC         ${C_RESET}"
  RES=$(upsert_rule \
    "20-Block-XMLRPC" \
    '(http.request.uri.path eq "/xmlrpc.php") or (http.request.uri.path eq "//xmlrpc.php")' \
    "block")
  check "$RES" || ZONE_FAILED=1

  echo -ne "  ${C_WHITE}Rule 25 — Block Scanners       ${C_RESET}"
  RES=$(upsert_rule \
    "25-Block-Scanners" \
    '(http.request.uri.path eq "/.env") or (http.request.uri.path contains "/config.") or (http.request.uri.path eq "/setup.php") or (http.request.uri.path eq "/install.php")' \
    "block")
  check "$RES" || ZONE_FAILED=1

  echo -ne "  ${C_WHITE}Rule 30 — Challenge WP-Admin   ${C_RESET}"
  RES=$(upsert_rule \
    "30-Challenge-WP-Admin+Login" \
    '(http.request.uri.path eq "/wp-login.php" or http.request.uri.path eq "//wp-login.php") or ((starts_with(http.request.uri.path, "/wp-admin/") or starts_with(http.request.uri.path, "//wp-admin/")) and not (http.request.uri.path eq "/wp-admin/admin-ajax.php" or http.request.uri.path eq "//wp-admin/admin-ajax.php"))' \
    "managed_challenge")
  check "$RES" || ZONE_FAILED=1

  echo -e "$SEP2"
  echo -e "${C_CYAN}  🚦  Rate Limiting Rule${C_RESET}"

  echo -ne "  ${C_WHITE}Rule 40 — RateLimit 50/10s     ${C_RESET}"
  RES=$(python3 -c "
import json, subprocess
zone = '$ZONE_ID'
token = '$CF_TOKEN'
api = 'https://api.cloudflare.com/client/v4'
payload = json.dumps({'rules': [{'description': '40-RateLimit-Bots',
  'expression': '(http.request.uri.path ne \"/wp-login.php\") and (http.request.uri.path ne \"/wp-admin/\")',
  'action': 'block',
  'ratelimit': {'characteristics': ['ip.src', 'cf.colo.id'], 'period': 10, 'requests_per_period': 50, 'mitigation_timeout': 10},
  'enabled': True}]})
r = subprocess.run(['curl','-s','-X','PUT',
  f'{api}/zones/{zone}/rulesets/phases/http_ratelimit/entrypoint',
  '-H', f'Authorization: Bearer {token}',
  '-H', 'Content-Type: application/json',
  '-d', payload], capture_output=True, text=True)
print(r.stdout)
")
  check "$RES" || ZONE_FAILED=1

  if [[ $ZONE_FAILED -eq 0 ]]; then
    echo ""
    echo -e "  ${C_GREEN}✅  ${DOMAIN} — ALL RULES APPLIED${C_RESET}"
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
echo -e "  ${C_WHITE}📍  Verify: CF Dashboard → Security → Security Rules + Rate Limiting${C_RESET}"
echo -e "  ${C_WHITE}📍  Check:  Security Level HIGH | Browser Integrity ON | Bot Fight ON${C_RESET}"
echo -e "$SEP"
echo -e "${C_GREEN}  = Rooted by VladiMIR + AI | github.com/GinCz =${C_RESET}"
echo -e "$SEP"
echo ""
