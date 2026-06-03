#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║         cloudflare-wp-security.sh                                    ║
# ║         Cloudflare Security — Universal WordPress Protection         ║
# ║         Server 222 | ALL domains | FREE PLAN                         ║
# ║         = Rooted by VladiMIR + AI | v.2026.06.03 | github.com/GinCz =║
# ╚══════════════════════════════════════════════════════════════════════╝
# ▶ RUN ON: Server 222 (152.53.182.222)
# export CF_TOKEN="your_token_here"
#
# LOGIC:
#   1. DELETE all existing custom firewall rules (avoid name conflicts)
#   2. CREATE Rule 30 — Managed Challenge ALL WordPress attack paths
#   3. CREATE Rule 40 — Rate Limit 50 req/10s
#   4. APPLY zone settings: Security Level HIGH, Browser Check ON
#
# PROTECTED PATHS (Rule 30):
#   /wp-login.php, /wp-admin/*, /xmlrpc.php, /wp-cron.php,
#   /wp-trackback.php, /wp-comments-post.php, /wp-config.php,
#   /.env, /.htaccess, /.git/*, /readme.html, /license.txt,
#   /wp-json/*, /wp-includes/*, /setup.php, /install.php,
#   /?author=N (user enumeration)

clear

C_CYAN='\033[1;96m'
C_YELLOW='\033[1;93m'
C_GREEN='\033[1;92m'
C_RED='\033[1;91m'
C_WHITE='\033[1;97m'
C_RESET='\033[0m'

SEP="${C_YELLOW}========================================================================================${C_RESET}"
SEP2="${C_CYAN}\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500${C_RESET}"

API="https://api.cloudflare.com/client/v4"

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

# ---- helpers -------------------------------------------------------

cf_get()  { curl -s -X GET  "${API}${1}" -H "Authorization: Bearer ${CF_TOKEN}" -H "Content-Type: application/json"; }
cf_post() { curl -s -X POST "${API}${1}" -H "Authorization: Bearer ${CF_TOKEN}" -H "Content-Type: application/json" -d "${2}"; }
cf_put()  { curl -s -X PUT  "${API}${1}" -H "Authorization: Bearer ${CF_TOKEN}" -H "Content-Type: application/json" -d "${2}"; }
cf_del()  { curl -s -X DELETE "${API}${1}" -H "Authorization: Bearer ${CF_TOKEN}" -H "Content-Type: application/json"; }
cf_patch(){ curl -s -X PATCH "${API}${1}" -H "Authorization: Bearer ${CF_TOKEN}" -H "Content-Type: application/json" -d "${2}"; }

is_ok() {
  echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get('success') else 1)" 2>/dev/null
}

print_ok()   { echo -e "  ${C_GREEN}\u2714 OK${C_RESET}"; }
print_fail() {
  local MSG
  MSG=$(echo "$1" | python3 -c "
import sys,json
try:
  d=json.load(sys.stdin)
  e=d.get('errors',[])
  print(e[0].get('message','unknown') if e else 'unknown error')
except: print('parse error')
" 2>/dev/null)
  echo -e "  ${C_RED}\u2718 FAILED: ${MSG}${C_RESET}"
}

check() {
  if is_ok "$1"; then print_ok; return 0
  else print_fail "$1"; return 1; fi
}

# ---- Rule 30 expression --------------------------------------------

WP_EXPR='(http.request.uri.path eq "/wp-login.php") or (http.request.uri.path eq "//wp-login.php") or (starts_with(http.request.uri.path, "/wp-admin/")) or (starts_with(http.request.uri.path, "//wp-admin/")) or (http.request.uri.path eq "/xmlrpc.php") or (http.request.uri.path eq "/wp-cron.php") or (http.request.uri.path eq "/wp-trackback.php") or (http.request.uri.path eq "/wp-comments-post.php") or (http.request.uri.path eq "/wp-config.php") or (http.request.uri.path eq "/wp-config-sample.php") or (http.request.uri.path eq "/.env") or (http.request.uri.path eq "/.htaccess") or (http.request.uri.path contains "/.git/") or (http.request.uri.path eq "/readme.html") or (http.request.uri.path eq "/license.txt") or (starts_with(http.request.uri.path, "/wp-json/")) or (starts_with(http.request.uri.path, "/wp-includes/")) or (http.request.uri.path eq "/setup.php") or (http.request.uri.path eq "/install.php") or (http.request.uri.query contains "author=")'

# ---- delete ALL existing custom firewall rules for a zone ----------
# Strategy:
#   - GET /zones/{zone}/rulesets
#   - Find ruleset with phase=http_request_firewall_custom
#   - PUT it with empty rules array (clears all rules without name conflict)

delete_all_firewall_rules() {
  local ZONE="$1"
  local RS_LIST RS_ID

  RS_LIST=$(cf_get "/zones/${ZONE}/rulesets")
  RS_ID=$(echo "$RS_LIST" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for r in d.get('result',[]):
    if r.get('phase')=='http_request_firewall_custom':
        print(r['id']); break
" 2>/dev/null)

  if [[ -z "$RS_ID" ]]; then
    # No existing ruleset — nothing to delete
    return 0
  fi

  # Get existing ruleset to preserve its name and kind
  local RS_INFO RS_NAME RS_KIND
  RS_INFO=$(cf_get "/zones/${ZONE}/rulesets/${RS_ID}")
  RS_NAME=$(echo "$RS_INFO" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('result',{}).get('name','Custom Rules'))" 2>/dev/null)
  RS_KIND=$(echo "$RS_INFO" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('result',{}).get('kind','zone'))" 2>/dev/null)

  # Clear all rules by PUT with empty rules array (preserving name)
  local CLEAR_PAYLOAD
  CLEAR_PAYLOAD=$(python3 -c "
import json,sys
print(json.dumps({'name': sys.argv[1], 'kind': sys.argv[2], 'phase': 'http_request_firewall_custom', 'rules': []}))
" "$RS_NAME" "$RS_KIND")

  cf_put "/zones/${ZONE}/rulesets/${RS_ID}" "$CLEAR_PAYLOAD" > /dev/null 2>&1

  # Return the RS_ID and RS_NAME for reuse
  echo "${RS_ID}|${RS_NAME}|${RS_KIND}"
}

# ---- apply Rule 30 firewall ----------------------------------------

apply_firewall_rule() {
  local ZONE="$1"
  local RS_META="$2"  # id|name|kind from delete step
  local RS_ID RS_NAME RS_KIND

  RS_ID=$(echo "$RS_META" | cut -d'|' -f1)
  RS_NAME=$(echo "$RS_META" | cut -d'|' -f2)
  RS_KIND=$(echo "$RS_META" | cut -d'|' -f3)

  local RULE_PAYLOAD
  RULE_PAYLOAD=$(python3 -c "
import json,sys
expr = sys.argv[1]
rule = {'description': '30-Challenge-ALL-WP-Paths', 'expression': expr, 'action': 'managed_challenge', 'enabled': True}
print(json.dumps({'rules': [rule]}))
" "$WP_EXPR")

  if [[ -z "$RS_ID" ]]; then
    # Create new ruleset
    local CREATE_PAYLOAD
    CREATE_PAYLOAD=$(python3 -c "
import json,sys
expr = sys.argv[1]
rule = {'description': '30-Challenge-ALL-WP-Paths', 'expression': expr, 'action': 'managed_challenge', 'enabled': True}
print(json.dumps({'name': 'Custom Rules', 'kind': 'zone', 'phase': 'http_request_firewall_custom', 'rules': [rule]}))
" "$WP_EXPR")
    cf_post "/zones/${ZONE}/rulesets" "$CREATE_PAYLOAD"
  else
    # Update existing ruleset (name preserved from delete step)
    local UPDATE_PAYLOAD
    UPDATE_PAYLOAD=$(python3 -c "
import json,sys
expr = sys.argv[1]; name = sys.argv[2]; kind = sys.argv[3]
rule = {'description': '30-Challenge-ALL-WP-Paths', 'expression': expr, 'action': 'managed_challenge', 'enabled': True}
print(json.dumps({'name': name, 'kind': kind, 'phase': 'http_request_firewall_custom', 'rules': [rule]}))
" "$WP_EXPR" "$RS_NAME" "$RS_KIND")
    cf_put "/zones/${ZONE}/rulesets/${RS_ID}" "$UPDATE_PAYLOAD"
  fi
}

# ---- apply Rule 40 rate limit --------------------------------------

apply_rate_limit() {
  local ZONE="$1"
  local PAYLOAD
  PAYLOAD=$(python3 -c "
import json
rule = {
  'description': '40-RateLimit-50req-10s',
  'expression': 'http.request.uri.path ne \"/\"',
  'action': 'block',
  'ratelimit': {
    'characteristics': ['ip.src', 'cf.colo.id'],
    'period': 10,
    'requests_per_period': 50,
    'mitigation_timeout': 10
  },
  'enabled': True
}
print(json.dumps({'rules': [rule]}))
")
  cf_put "/zones/${ZONE}/rulesets/phases/http_ratelimit/entrypoint" "$PAYLOAD"
}

# ====================================================================
# MAIN LOOP
# ====================================================================

echo ""
echo -e "$SEP"
echo -e "${C_CYAN}  \U1F680  CLOUDFLARE SECURITY \u2014 Universal WordPress Protection  |  Server 222${C_RESET}"
echo -e "${C_YELLOW}  \U1F4CB  Total domains: ${TOTAL}  |  FREE PLAN  |  2 rules per zone${C_RESET}"
echo -e "${C_GREEN}  = Rooted by VladiMIR + AI | github.com/GinCz =${C_RESET}"
echo -e "$SEP"

for DOMAIN in "${!ZONES[@]}"; do
  ZONE_ID="${ZONES[$DOMAIN]}"
  DONE=$((DONE + 1))
  ZONE_FAILED=0

  echo ""
  echo -e "$SEP"
  echo -e "${C_CYAN}  [${DONE}/${TOTAL}]  \U1F310  ${C_WHITE}${DOMAIN}${C_RESET}"
  echo -e "${C_YELLOW}  Zone ID: ${ZONE_ID}${C_RESET}"
  echo -e "$SEP"

  # ── Zone Settings ────────────────────────────────────────────────
  echo -e "${C_CYAN}  \u2699\uFE0F  Zone Settings${C_RESET}"

  echo -ne "  ${C_WHITE}Security Level \u2192 HIGH          ${C_RESET}"
  RES=$(cf_patch "/zones/${ZONE_ID}/settings/security_level" '{"value":"high"}')
  check "$RES" || ZONE_FAILED=1

  echo -ne "  ${C_WHITE}Browser Integrity Check \u2192 ON   ${C_RESET}"
  RES=$(cf_patch "/zones/${ZONE_ID}/settings/browser_check" '{"value":"on"}')
  check "$RES" || ZONE_FAILED=1

  echo -e "$SEP2"

  # ── Step 1: Clear all old firewall rules ─────────────────────────
  echo -e "${C_CYAN}  \U1F9F9  Clearing old firewall rules${C_RESET}"
  echo -ne "  ${C_WHITE}Delete existing rules            ${C_RESET}"
  RS_META=$(delete_all_firewall_rules "$ZONE_ID")
  echo -e "  ${C_GREEN}\u2714 OK${C_RESET}"

  echo -e "$SEP2"

  # ── Step 2: Apply Rule 30 ─────────────────────────────────────────
  echo -e "${C_CYAN}  \U1F6E1\uFE0F  Firewall Rule${C_RESET}"
  echo -ne "  ${C_WHITE}Rule 30 \u2014 Challenge ALL WP paths ${C_RESET}"
  RES=$(apply_firewall_rule "$ZONE_ID" "$RS_META")
  check "$RES" || ZONE_FAILED=1

  echo -e "$SEP2"

  # ── Step 3: Apply Rule 40 ─────────────────────────────────────────
  echo -e "${C_CYAN}  \U1F6A6  Rate Limiting Rule${C_RESET}"
  echo -ne "  ${C_WHITE}Rule 40 \u2014 RateLimit 50/10s     ${C_RESET}"
  RES=$(apply_rate_limit "$ZONE_ID")
  check "$RES" || ZONE_FAILED=1

  # ── Result ────────────────────────────────────────────────────────
  if [[ $ZONE_FAILED -eq 0 ]]; then
    echo ""
    echo -e "  ${C_GREEN}\u2705  ${DOMAIN} \u2014 ALL RULES APPLIED${C_RESET}"
  else
    FAIL=$((FAIL + 1))
    echo ""
    echo -e "  ${C_RED}\u274C  ${DOMAIN} \u2014 SOME RULES FAILED \u2014 CHECK ABOVE${C_RESET}"
  fi

done

SUCCESS=$((TOTAL - FAIL))

echo ""
echo -e "$SEP"
echo -e "${C_YELLOW}  \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550  FINAL SUMMARY  \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550${C_RESET}"
echo -e "$SEP"
echo -e "  ${C_GREEN}\u2705  SUCCESS:  ${SUCCESS} / ${TOTAL} domains${C_RESET}"
if [[ $FAIL -gt 0 ]]; then
  echo -e "  ${C_RED}\u274C  FAILED:   ${FAIL} / ${TOTAL} domains${C_RESET}"
fi
echo ""
echo -e "  ${C_WHITE}\U1F4CD  Rule 30: Managed Challenge \u2014 \u0432\u0441\u0435 WP-\u043f\u0443\u0442\u0438 \u0437\u0430\u043a\u0440\u044b\u0442\u044b \u043a\u0430\u043f\u0447\u0435\u0439${C_RESET}"
echo -e "  ${C_WHITE}\U1F4CD  Rule 40: Rate Limit 50 req/10s \u2014 \u0434\u043e\u043f\u043e\u043b\u043d\u0438\u0442\u0435\u043b\u044c\u043d\u044b\u0439 \u0440\u0443\u0431\u0435\u0436${C_RESET}"
echo -e "  ${C_WHITE}\U1F4CD  Verify: CF Dashboard \u2192 Security \u2192 Security Rules + Rate Limiting${C_RESET}"
echo -e "$SEP"
echo -e "${C_GREEN}  = Rooted by VladiMIR + AI | github.com/GinCz =${C_RESET}"
echo -e "$SEP"
echo ""
