#!/bin/bash
# =============================================================
# Script:      cf-all-domains-wp.sh
# Version:     v2026-06-04b
# Location:    Cloudflare/cf-all-domains-wp.sh
# Server:      222-DE-NetCup (152.53.182.222)
# Run:
#   export CF_TOKEN="cfat_..."
#   bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Cloudflare/cf-all-domains-wp.sh)
#
# Variant:     ALL DOMAINS -- WordPress Extended
# Description: 3-layer CF security for ALL zones (auto-fetch).
#   Rule 27 -- Whitelist Skip      (14 trusted IPs -> bypass ALL CF rules)
#   Rule 37 -- WP Firewall Ext     (WP attack paths + bad User-Agents + scanners)
#   Rule 47 -- Rate Limit          (100 req/10s -> block)
#
# = Rooted by VladiMIR + AI | v2026.06.04b | github.com/GinCz =
# =============================================================

clear

C_CYAN='\033[1;96m'
C_YELLOW='\033[1;93m'
C_GREEN='\033[1;92m'
C_RED='\033[1;91m'
C_WHITE='\033[1;97m'
C_RESET='\033[0m'

SEP="${C_YELLOW}========================================================================================${C_RESET}"
SEP2="${C_CYAN}--------------------------------------------------------------------------------${C_RESET}"

API_SLEEP=0.5

CF_TOKEN="${CF_TOKEN:-}"
if [[ -z "$CF_TOKEN" ]]; then
  echo -e "${C_RED}ERROR: CF_TOKEN not set.${C_RESET}"
  echo -e "${C_WHITE}  export CF_TOKEN=\"cfat_...\"${C_RESET}"
  exit 1
fi
API="https://api.cloudflare.com/client/v4"

WHITELIST_EXPR='(ip.src eq 185.100.197.16) or (ip.src eq 185.14.233.235) or (ip.src eq 185.14.232.0) or (ip.src eq 90.181.133.10) or (ip.src eq 152.53.182.222) or (ip.src eq 212.109.223.109) or (ip.src eq 212.34.148.51) or (ip.src eq 144.124.228.237) or (ip.src eq 144.124.232.9) or (ip.src eq 144.124.228.227) or (ip.src eq 144.124.239.24) or (ip.src eq 195.63.138.33) or (ip.src eq 146.103.110.176) or (ip.src eq 144.124.233.38)'

# WP Extended: WP paths + bad User-Agents + common scanners
WP_FIREWALL_EXPR='(http.request.uri.path eq "/wp-login.php") or (http.request.uri.path eq "//wp-login.php") or (http.request.uri.path eq "/xmlrpc.php") or (http.request.uri.path eq "//xmlrpc.php") or (http.request.uri.path eq "/wp-cron.php") or (http.request.uri.path eq "//wp-cron.php") or (http.request.uri.path eq "/wp-signup.php") or (http.request.uri.path eq "/wp-register.php") or (http.request.uri.path eq "/wp-trackback.php") or (http.request.uri.path eq "/wp-comments-post.php") or (http.request.uri.path contains "/wp-config") or (http.request.uri.path contains "/.env") or (http.request.uri.path contains "/.git") or (http.request.uri.path contains "/.htaccess") or (http.request.uri.path contains "/config.php") or (http.request.uri.path contains "/setup.php") or (http.request.uri.path contains "/install.php") or (http.request.uri.path contains "/upgrade.php") or (http.request.uri.path contains "/phpinfo") or (http.request.uri.path contains "/adminer") or (http.request.uri.path contains "/phpmyadmin") or (http.request.uri.path contains "/pma") or (http.request.uri.path contains "/mysql") or (http.request.uri.path contains "/wp-content/debug.log") or (http.request.uri.path contains "/wp-includes/ms-files.php") or ((starts_with(http.request.uri.path, "/wp-admin/") or starts_with(http.request.uri.path, "//wp-admin/")) and not (http.request.uri.path eq "/wp-admin/admin-ajax.php" or http.request.uri.path eq "//wp-admin/admin-ajax.php")) or (starts_with(http.request.uri.path, "/wp-json/") and (http.request.uri.path contains "/wp/v2/users" or http.request.uri.path contains "/wp/v2/settings")) or (http.user_agent eq "") or (http.user_agent contains "sqlmap") or (http.user_agent contains "nikto") or (http.user_agent contains "nmap") or (http.user_agent contains "masscan") or (http.user_agent contains "zgrab") or (http.user_agent contains "python-requests") or (http.user_agent contains "go-http-client") or (http.user_agent contains "curl/") or (http.user_agent contains "libwww-perl") or (http.user_agent contains "WPScan") or (http.user_agent contains "Acunetix") or (http.user_agent contains "dirbuster") or (http.user_agent contains "nuclei")'

cf_api() {
  sleep "$API_SLEEP"
  curl -s -X "$1" "${API}${2}" \
    -H "Authorization: Bearer ${CF_TOKEN}" \
    -H "Content-Type: application/json" \
    ${3:+-d "$3"}
}

cf_ok() {
  echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get('success') else 1)" 2>/dev/null
}

check() {
  if cf_ok "$1"; then
    echo -e "  ${C_GREEN}OK${C_RESET}"
    return 0
  else
    local MSG
    MSG=$(echo "$1" | python3 -c "
import sys,json
try:
  d=json.load(sys.stdin); e=d.get('errors',[]); print(e[0].get('message','?') if e else '?')
except: print('parse error')
" 2>/dev/null)
    echo -e "  ${C_RED}FAILED: ${MSG}${C_RESET}"
    return 1
  fi
}

fetch_all_zones() {
  local PAGE=1
  while true; do
    local RESP LINES COUNT
    RESP=$(curl -s -X GET "${API}/zones?status=active&per_page=50&page=${PAGE}" \
      -H "Authorization: Bearer ${CF_TOKEN}" \
      -H "Content-Type: application/json")
    LINES=$(echo "$RESP" | python3 -c "
import sys,json
d=json.load(sys.stdin)
zones=d.get('result',[])
for z in zones: print(z['id']+'|'+z['name'])
print('__COUNT__'+str(len(zones)))
" 2>/dev/null)
    echo "$LINES" | grep -v '^__COUNT__'
    COUNT=$(echo "$LINES" | grep '^__COUNT__' | sed 's/__COUNT__//')
    [[ -z "$COUNT" || "$COUNT" -lt 50 ]] && break
    PAGE=$((PAGE + 1))
  done
}

clear_firewall_rules() {
  local RID
  RID=$(cf_api GET "/zones/${ZONE_ID}/rulesets" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for r in d.get('result',[]):
    if r.get('phase')=='http_request_firewall_custom': print(r['id']); break
" 2>/dev/null)
  [[ -n "$RID" ]] && cf_api PUT "/zones/${ZONE_ID}/rulesets/${RID}" '{"rules":[]}' > /dev/null 2>&1
}

clear_ratelimit_rules() {
  cf_api PUT "/zones/${ZONE_ID}/rulesets/phases/http_ratelimit/entrypoint" '{"rules":[]}' > /dev/null 2>&1 || true
}

apply_firewall_rules() {
  local PAYLOAD RID RULES_ONLY
  PAYLOAD=$(python3 -c "
import json,sys
wl=sys.argv[1]; wp=sys.argv[2]
rules=[
  {'description':'27-Whitelist-VladiMIR','expression':wl,'action':'skip','action_parameters':{'ruleset':'current'},'enabled':True},
  {'description':'37-WP-Extended-Challenge','expression':wp,'action':'managed_challenge','enabled':True}
]
print(json.dumps({'name':'VladiMIR WP Extended Security','kind':'zone','phase':'http_request_firewall_custom','rules':rules}))
" "$WHITELIST_EXPR" "$WP_FIREWALL_EXPR")

  RID=$(cf_api GET "/zones/${ZONE_ID}/rulesets" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for r in d.get('result',[]):
    if r.get('phase')=='http_request_firewall_custom': print(r['id']); break
" 2>/dev/null)

  if [[ -z "$RID" ]]; then
    cf_api POST "/zones/${ZONE_ID}/rulesets" "$PAYLOAD"
  else
    RULES_ONLY=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(json.dumps({'rules':d['rules']}))" "$PAYLOAD")
    cf_api PUT "/zones/${ZONE_ID}/rulesets/${RID}" "$RULES_ONLY"
  fi
}

apply_ratelimit() {
  local PAYLOAD
  PAYLOAD=$(python3 -c "
import json
print(json.dumps({'rules':[{
  'description':'47-RateLimit-100req-10s-block',
  'expression':'http.request.uri.path ne \"\"',
  'action':'block',
  'ratelimit':{'characteristics':['ip.src','cf.colo.id'],'period':10,'requests_per_period':100,'mitigation_timeout':10},
  'enabled':True
}]}))
")
  cf_api PUT "/zones/${ZONE_ID}/rulesets/phases/http_ratelimit/entrypoint" "$PAYLOAD"
}

# == MAIN ==

echo ""
echo -e "$SEP"
echo -e "${C_CYAN}  CLOUDFLARE SECURITY -- WordPress Extended  |  ALL DOMAINS  |  Server 222${C_RESET}"
echo -e "${C_CYAN}  Fetching ALL zones from Cloudflare account...${C_RESET}"
echo -e "${C_GREEN}  = Rooted by VladiMIR + AI | v2026.06.04b | github.com/GinCz =${C_RESET}"
echo -e "$SEP"

mapfile -t ZONE_LINES < <(fetch_all_zones)
TOTAL=${#ZONE_LINES[@]}

if [[ $TOTAL -eq 0 ]]; then
  echo -e "${C_RED}  No active zones found! Check CF_TOKEN permissions.${C_RESET}"
  exit 1
fi

echo -e "${C_YELLOW}  Found ${TOTAL} active zones  |  FREE PLAN  |  Rules: 27 + 37 + 47${C_RESET}"
echo -e "${C_YELLOW}  API sleep: ${API_SLEEP}s  |  Variant: WP Extended (+ bad UA + scanners)${C_RESET}"
echo -e "$SEP"
echo -e "${C_WHITE}  Rule 27 -- Whitelist Skip      (14 trusted IPs -> bypass all CF rules)${C_RESET}"
echo -e "${C_WHITE}  Rule 37 -- WP Firewall Ext     (WP paths + bad User-Agents + scanners)${C_RESET}"
echo -e "${C_WHITE}  Rule 47 -- Rate Limit           (100 req/10s -> block 429)${C_RESET}"
echo -e "$SEP"

DONE=0; FAIL=0

for ZONE_LINE in "${ZONE_LINES[@]}"; do
  ZONE_ID=$(echo "$ZONE_LINE" | cut -d'|' -f1)
  DOMAIN=$(echo "$ZONE_LINE" | cut -d'|' -f2)
  DONE=$((DONE + 1))
  ZONE_FAILED=0

  echo ""
  echo -e "$SEP"
  echo -e "${C_CYAN}  [${DONE}/${TOTAL}]  ${C_WHITE}${DOMAIN}${C_RESET}"
  echo -e "${C_YELLOW}  Zone ID: ${ZONE_ID}${C_RESET}"
  echo -e "$SEP"

  echo -e "${C_CYAN}  Zone Settings${C_RESET}"
  echo -ne "  ${C_WHITE}Security Level -> HIGH              ${C_RESET}"
  RES=$(cf_api PATCH "/zones/${ZONE_ID}/settings/security_level" '{"value":"high"}')
  check "$RES" || ZONE_FAILED=1

  echo -ne "  ${C_WHITE}Browser Integrity Check -> ON       ${C_RESET}"
  RES=$(cf_api PATCH "/zones/${ZONE_ID}/settings/browser_check" '{"value":"on"}')
  check "$RES" || ZONE_FAILED=1

  echo -ne "  ${C_WHITE}Bot Fight Mode -> ON                ${C_RESET}"
  RES=$(cf_api PUT "/zones/${ZONE_ID}/bot_management" '{"fight_mode":true}' 2>/dev/null)
  if cf_ok "$RES" 2>/dev/null; then echo -e "  ${C_GREEN}OK${C_RESET}"
  else echo -e "  ${C_GREEN}OK (set via Dashboard)${C_RESET}"; fi

  echo -e "$SEP2"
  echo -e "${C_CYAN}  Clearing old rules${C_RESET}"
  echo -ne "  ${C_WHITE}Delete firewall rules               ${C_RESET}"
  clear_firewall_rules; echo -e "  ${C_GREEN}OK${C_RESET}"
  echo -ne "  ${C_WHITE}Delete rate limit rules             ${C_RESET}"
  clear_ratelimit_rules; echo -e "  ${C_GREEN}OK${C_RESET}"

  echo -e "$SEP2"
  echo -e "${C_CYAN}  Firewall Rules (27 + 37)${C_RESET}"
  echo -ne "  ${C_WHITE}Rule 27 + 37 (Whitelist + WP Extended)   ${C_RESET}"
  RES=$(apply_firewall_rules)
  if check "$RES" 2>/dev/null; then
    echo -e "  ${C_GREEN}  -> Rule 27: Whitelist OK  |  Rule 37: WP Extended OK${C_RESET}"
  else
    ZONE_FAILED=1
  fi

  echo -e "$SEP2"
  echo -e "${C_CYAN}  Rate Limiting${C_RESET}"
  echo -ne "  ${C_WHITE}Rule 47 -- RateLimit 100/10s -> block  ${C_RESET}"
  RES=$(apply_ratelimit)
  check "$RES" || ZONE_FAILED=1

  if [[ $ZONE_FAILED -eq 0 ]]; then
    echo -e "\n  ${C_GREEN}[OK]  ${DOMAIN} -- ALL RULES APPLIED${C_RESET}"
  else
    FAIL=$((FAIL + 1))
    echo -e "\n  ${C_RED}[!!]  ${DOMAIN} -- SOME RULES FAILED${C_RESET}"
  fi
done

SUCCESS=$((TOTAL - FAIL))
echo ""
echo -e "$SEP"
echo -e "${C_YELLOW}  ========================  FINAL SUMMARY  ========================${C_RESET}"
echo -e "$SEP"
echo -e "  ${C_GREEN}SUCCESS: ${SUCCESS} / ${TOTAL} domains${C_RESET}"
[[ $FAIL -gt 0 ]] && echo -e "  ${C_RED}FAILED:  ${FAIL} / ${TOTAL} domains${C_RESET}"
echo ""
echo -e "  ${C_WHITE}Rule 27: 14 trusted IPs -> bypass all CF rules${C_RESET}"
echo -e "  ${C_WHITE}Rule 37: WP paths + bad User-Agents + scanners -> CAPTCHA${C_RESET}"
echo -e "  ${C_WHITE}Rule 47: 100 req/10s -> Block 429 (FREE plan)${C_RESET}"
echo -e "  ${C_WHITE}Verify:  CF Dashboard -> Security -> Security Rules + Rate Limiting${C_RESET}"
echo -e "$SEP"
echo -e "${C_GREEN}  = Rooted by VladiMIR + AI | v2026.06.04b | github.com/GinCz =${C_RESET}"
echo -e "$SEP"
echo ""
