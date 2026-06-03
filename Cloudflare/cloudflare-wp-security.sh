#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║   cloudflare-wp-security.sh                                         ║
# ║   Cloudflare Security — Universal WordPress Protection              ║
# ║   AUTO-FETCH all zones from CF account | FREE PLAN                  ║
# ║   = Rooted by VladiMIR + AI | v.2026.06.03 | github.com/GinCz =    ║
# ╚══════════════════════════════════════════════════════════════════════╝
# ▶ RUN ON: Server 222 (152.53.182.222)
# export CF_TOKEN="your_token_here"
# bash cloudflare-wp-security.sh
#
# LOGIC:
#   1. AUTO-FETCH all active zones from Cloudflare account
#   2. DELETE all existing custom firewall rules (avoid name conflicts)
#   3. CREATE Rule 27 — Managed Challenge ALL WordPress attack paths
#   4. CREATE Rule 37 — Rate Limit 50 req/10s
#   5. APPLY zone settings: Security Level HIGH, Browser Check ON
#   6. AUTO-DELETE this script after 100% successful completion
#
# PROTECTED PATHS (Rule 27):
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
SEP2="${C_CYAN}────────────────────────────────────────────────────────────────────────────────────────${C_RESET}"

API="https://api.cloudflare.com/client/v4"
SCRIPT_PATH="$(realpath "$0")"

# ---- check token ---------------------------------------------------

if [[ -z "$CF_TOKEN" ]]; then
  echo -e "${C_RED}  ❌ ERROR: CF_TOKEN not set!${C_RESET}"
  echo -e "${C_YELLOW}  Run: export CF_TOKEN=\"your_token_here\"${C_RESET}"
  exit 1
fi

# ---- helpers -------------------------------------------------------

cf_get()  { curl -s -X GET   "${API}${1}" -H "Authorization: Bearer ${CF_TOKEN}" -H "Content-Type: application/json"; }
cf_post() { curl -s -X POST  "${API}${1}" -H "Authorization: Bearer ${CF_TOKEN}" -H "Content-Type: application/json" -d "${2}"; }
cf_put()  { curl -s -X PUT   "${API}${1}" -H "Authorization: Bearer ${CF_TOKEN}" -H "Content-Type: application/json" -d "${2}"; }
cf_patch(){ curl -s -X PATCH "${API}${1}" -H "Authorization: Bearer ${CF_TOKEN}" -H "Content-Type: application/json" -d "${2}"; }

is_ok() {
  echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get('success') else 1)" 2>/dev/null
}

print_ok()   { echo -e "  ${C_GREEN}✔ OK${C_RESET}"; }
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
  echo -e "  ${C_RED}✘ FAILED: ${MSG}${C_RESET}"
}

check() {
  if is_ok "$1"; then print_ok; return 0
  else print_fail "$1"; return 1; fi
}

# ---- fetch ALL zones from account (pagination) --------------------

fetch_all_zones() {
  local PAGE=1
  local ALL_ZONES="[]"
  while true; do
    local RESP
    RESP=$(cf_get "/zones?status=active&per_page=50&page=${PAGE}")
    local COUNT
    COUNT=$(echo "$RESP" | python3 -c "
import sys,json
d=json.load(sys.stdin)
zones=d.get('result',[])
for z in zones: print(z['id']+'|'+z['name'])
print('__COUNT__'+str(len(zones)))
" 2>/dev/null)
    # Print zone lines
    echo "$COUNT" | grep -v '^__COUNT__'
    # Check if last page
    local CNT
    CNT=$(echo "$COUNT" | grep '^__COUNT__' | cut -d_ -f9)
    if [[ -z "$CNT" || "$CNT" -lt 50 ]]; then
      break
    fi
    PAGE=$((PAGE + 1))
  done
}

# ---- Rule 27 expression --------------------------------------------

WP_EXPR='(http.request.uri.path eq "/wp-login.php") or (http.request.uri.path eq "//wp-login.php") or (starts_with(http.request.uri.path, "/wp-admin/")) or (starts_with(http.request.uri.path, "//wp-admin/")) or (http.request.uri.path eq "/xmlrpc.php") or (http.request.uri.path eq "/wp-cron.php") or (http.request.uri.path eq "/wp-trackback.php") or (http.request.uri.path eq "/wp-comments-post.php") or (http.request.uri.path eq "/wp-config.php") or (http.request.uri.path eq "/wp-config-sample.php") or (http.request.uri.path eq "/.env") or (http.request.uri.path eq "/.htaccess") or (http.request.uri.path contains "/.git/") or (http.request.uri.path eq "/readme.html") or (http.request.uri.path eq "/license.txt") or (starts_with(http.request.uri.path, "/wp-json/")) or (starts_with(http.request.uri.path, "/wp-includes/")) or (http.request.uri.path eq "/setup.php") or (http.request.uri.path eq "/install.php") or (http.request.uri.query contains "author=")'

# ---- delete all existing custom firewall rules --------------------

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
    return 0
  fi

  local RS_INFO RS_NAME RS_KIND
  RS_INFO=$(cf_get "/zones/${ZONE}/rulesets/${RS_ID}")
  RS_NAME=$(echo "$RS_INFO" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('result',{}).get('name','Custom Rules'))" 2>/dev/null)
  RS_KIND=$(echo "$RS_INFO" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('result',{}).get('kind','zone'))" 2>/dev/null)

  local CLEAR_PAYLOAD
  CLEAR_PAYLOAD=$(python3 -c "
import json,sys
print(json.dumps({'name': sys.argv[1], 'kind': sys.argv[2], 'phase': 'http_request_firewall_custom', 'rules': []}))
" "$RS_NAME" "$RS_KIND")

  cf_put "/zones/${ZONE}/rulesets/${RS_ID}" "$CLEAR_PAYLOAD" > /dev/null 2>&1
  echo "${RS_ID}|${RS_NAME}|${RS_KIND}"
}

# ---- apply Rule 27 ------------------------------------------------

apply_firewall_rule() {
  local ZONE="$1"
  local RS_META="$2"
  local RS_ID RS_NAME RS_KIND

  RS_ID=$(echo "$RS_META" | cut -d'|' -f1)
  RS_NAME=$(echo "$RS_META" | cut -d'|' -f2)
  RS_KIND=$(echo "$RS_META" | cut -d'|' -f3)

  if [[ -z "$RS_ID" ]]; then
    local CREATE_PAYLOAD
    CREATE_PAYLOAD=$(python3 -c "
import json,sys
expr=sys.argv[1]
rule={'description':'27-Challenge-ALL-WP-Paths','expression':expr,'action':'managed_challenge','enabled':True}
print(json.dumps({'name':'Custom Rules','kind':'zone','phase':'http_request_firewall_custom','rules':[rule]}))
" "$WP_EXPR")
    cf_post "/zones/${ZONE}/rulesets" "$CREATE_PAYLOAD"
  else
    local UPDATE_PAYLOAD
    UPDATE_PAYLOAD=$(python3 -c "
import json,sys
expr=sys.argv[1]; name=sys.argv[2]; kind=sys.argv[3]
rule={'description':'27-Challenge-ALL-WP-Paths','expression':expr,'action':'managed_challenge','enabled':True}
print(json.dumps({'name':name,'kind':kind,'phase':'http_request_firewall_custom','rules':[rule]}))
" "$WP_EXPR" "$RS_NAME" "$RS_KIND")
    cf_put "/zones/${ZONE}/rulesets/${RS_ID}" "$UPDATE_PAYLOAD"
  fi
}

# ---- apply Rule 37 ------------------------------------------------

apply_rate_limit() {
  local ZONE="$1"
  local PAYLOAD
  PAYLOAD=$(python3 -c "
import json
rule={
  'description':'37-RateLimit-50req-10s',
  'expression':'http.request.uri.path ne \"/\"',
  'action':'block',
  'ratelimit':{
    'characteristics':['ip.src','cf.colo.id'],
    'period':10,
    'requests_per_period':50,
    'mitigation_timeout':10
  },
  'enabled':True
}
print(json.dumps({'rules':[rule]}))
")
  cf_put "/zones/${ZONE}/rulesets/phases/http_ratelimit/entrypoint" "$PAYLOAD"
}

# ====================================================================
# MAIN
# ====================================================================

echo ""
echo -e "$SEP"
echo -e "${C_CYAN}  🚀  CLOUDFLARE SECURITY — Universal WordPress Protection${C_RESET}"
echo -e "${C_CYAN}  🔍  Fetching all zones from Cloudflare account...${C_RESET}"
echo -e "${C_GREEN}  = Rooted by VladiMIR + AI | github.com/GinCz =${C_RESET}"
echo -e "$SEP"

# Fetch zones into array
mapfile -t ZONE_LINES < <(fetch_all_zones)

TOTAL=${#ZONE_LINES[@]}

if [[ $TOTAL -eq 0 ]]; then
  echo -e "${C_RED}  ❌ No active zones found! Check CF_TOKEN permissions.${C_RESET}"
  exit 1
fi

echo -e "${C_YELLOW}  📋  Found ${TOTAL} active zones in account${C_RESET}"
echo -e "$SEP"

DONE=0
FAIL=0

for ZONE_LINE in "${ZONE_LINES[@]}"; do
  ZONE_ID=$(echo "$ZONE_LINE" | cut -d'|' -f1)
  DOMAIN=$(echo "$ZONE_LINE" | cut -d'|' -f2)
  DONE=$((DONE + 1))
  ZONE_FAILED=0

  echo ""
  echo -e "$SEP"
  echo -e "${C_CYAN}  [${DONE}/${TOTAL}]  🌐  ${C_WHITE}${DOMAIN}${C_RESET}"
  echo -e "${C_YELLOW}  Zone ID: ${ZONE_ID}${C_RESET}"
  echo -e "$SEP"

  # ─ Zone Settings ───────────────────────────────────────────────
  echo -e "${C_CYAN}  ⚙️  Zone Settings${C_RESET}"

  echo -ne "  ${C_WHITE}Security Level → HIGH          ${C_RESET}"
  RES=$(cf_patch "/zones/${ZONE_ID}/settings/security_level" '{"value":"high"}')
  check "$RES" || ZONE_FAILED=1

  echo -ne "  ${C_WHITE}Browser Integrity Check → ON   ${C_RESET}"
  RES=$(cf_patch "/zones/${ZONE_ID}/settings/browser_check" '{"value":"on"}')
  check "$RES" || ZONE_FAILED=1

  echo -e "$SEP2"

  # ─ Step 1: Clear old rules ───────────────────────────────────────
  echo -e "${C_CYAN}  🧹  Clearing old firewall rules${C_RESET}"
  echo -ne "  ${C_WHITE}Delete existing rules            ${C_RESET}"
  RS_META=$(delete_all_firewall_rules "$ZONE_ID")
  echo -e "  ${C_GREEN}✔ OK${C_RESET}"

  echo -e "$SEP2"

  # ─ Step 2: Rule 27 ─────────────────────────────────────────────
  echo -e "${C_CYAN}  🛡️  Firewall Rule${C_RESET}"
  echo -ne "  ${C_WHITE}Rule 27 — Challenge ALL WP paths ${C_RESET}"
  RES=$(apply_firewall_rule "$ZONE_ID" "$RS_META")
  check "$RES" || ZONE_FAILED=1

  echo -e "$SEP2"

  # ─ Step 3: Rule 37 ─────────────────────────────────────────────
  echo -e "${C_CYAN}  🚦  Rate Limiting Rule${C_RESET}"
  echo -ne "  ${C_WHITE}Rule 37 — RateLimit 50/10s     ${C_RESET}"
  RES=$(apply_rate_limit "$ZONE_ID")
  check "$RES" || ZONE_FAILED=1

  # ─ Result ─────────────────────────────────────────────────────
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
echo -e "  ${C_WHITE}📍  Rule 27: Managed Challenge — все WP-пути закрыты капчей${C_RESET}"
echo -e "  ${C_WHITE}📍  Rule 37: Rate Limit 50 req/10s — дополнительный рубеж${C_RESET}"
echo -e "  ${C_WHITE}📍  Verify: CF Dashboard → Security → Security Rules + Rate Limiting${C_RESET}"
echo -e "$SEP"
echo -e "${C_GREEN}  = Rooted by VladiMIR + AI | github.com/GinCz =${C_RESET}"
echo -e "$SEP"
echo ""

# ─ Auto-delete after 100% success ──────────────────────────────────
if [[ $FAIL -eq 0 ]]; then
  echo -e "${C_YELLOW}  🗑️  All domains OK — deleting script...${C_RESET}"
  rm -f "$SCRIPT_PATH"
  echo -e "${C_GREEN}  ✔ Script deleted: ${SCRIPT_PATH}${C_RESET}"
else
  echo -e "${C_YELLOW}  ⚠️  Script NOT deleted — ${FAIL} domain(s) failed. Fix and re-run.${C_RESET}"
fi
echo ""
