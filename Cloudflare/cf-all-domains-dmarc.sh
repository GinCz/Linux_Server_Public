#!/bin/bash
# =============================================================
# Script:      cf-all-domains-dmarc.sh
# Version:     v2026-06-04a
# Location:    Cloudflare/cf-all-domains-dmarc.sh
# Server:      222-DE-NetCup (152.53.182.222)
# Run:
#   export CF_TOKEN="cfat_..."
#   bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Cloudflare/cf-all-domains-dmarc.sh)
#
# Description: Check and add DMARC TXT record for ALL zones.
#   - If _dmarc record EXISTS  -> skip (do NOT overwrite)
#   - If _dmarc record MISSING -> create it
#
# DMARC record:
#   v=DMARC1; p=quarantine; pct=100; sp=quarantine;
#   adkim=r; aspf=r; fo=0; rf=afrf; ri=86400; np=quarantine
#
# = Rooted by VladiMIR + AI | v2026.06.04a | github.com/GinCz =
# =============================================================

clear

C_CYAN='\033[1;96m'
C_YELLOW='\033[1;93m'
C_GREEN='\033[1;92m'
C_RED='\033[1;91m'
C_WHITE='\033[1;97m'
C_GRAY='\033[0;37m'
C_RESET='\033[0m'

SEP="${C_YELLOW}========================================================================================${C_RESET}"
SEP2="${C_CYAN}--------------------------------------------------------------------------------${C_RESET}"

API_SLEEP=0.4
DMARC_VALUE='v=DMARC1; p=quarantine; pct=100; sp=quarantine; adkim=r; aspf=r; fo=0; rf=afrf; ri=86400; np=quarantine'

CF_TOKEN="${CF_TOKEN:-}"
if [[ -z "$CF_TOKEN" ]]; then
  echo -e "${C_RED}ERROR: CF_TOKEN not set.${C_RESET}"
  echo -e "${C_WHITE}  export CF_TOKEN=\"cfat_...\"${C_RESET}"
  exit 1
fi
API="https://api.cloudflare.com/client/v4"

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

# Check if _dmarc TXT record exists, return its ID or empty string
get_dmarc_record_id() {
  local ZONE_ID="$1"
  cf_api GET "/zones/${ZONE_ID}/dns_records?type=TXT&name=_dmarc.${DOMAIN}" \
    | python3 -c "
import sys,json
d=json.load(sys.stdin)
recs=d.get('result',[])
if recs: print(recs[0]['id'])
" 2>/dev/null
}

create_dmarc() {
  local ZONE_ID="$1"
  local PAYLOAD
  PAYLOAD=$(python3 -c "
import json,sys
print(json.dumps({
  'type': 'TXT',
  'name': '_dmarc',
  'content': sys.argv[1],
  'ttl': 3600,
  'comment': 'DMARC policy - VladiMIR'
}))
" "$DMARC_VALUE")
  cf_api POST "/zones/${ZONE_ID}/dns_records" "$PAYLOAD"
}

# == MAIN ==

echo ""
echo -e "$SEP"
echo -e "${C_CYAN}  CLOUDFLARE DNS -- DMARC Check & Add  |  ALL DOMAINS  |  Server 222${C_RESET}"
echo -e "${C_CYAN}  Fetching ALL zones from Cloudflare account...${C_RESET}"
echo -e "${C_GREEN}  = Rooted by VladiMIR + AI | v2026.06.04a | github.com/GinCz =${C_RESET}"
echo -e "$SEP"

mapfile -t ZONE_LINES < <(fetch_all_zones)
TOTAL=${#ZONE_LINES[@]}

if [[ $TOTAL -eq 0 ]]; then
  echo -e "${C_RED}  No active zones found! Check CF_TOKEN permissions.${C_RESET}"
  exit 1
fi

echo -e "${C_YELLOW}  Found ${TOTAL} active zones${C_RESET}"
echo -e "${C_YELLOW}  Mode: CHECK first, ADD only if missing (never overwrite)${C_RESET}"
echo -e "$SEP"
echo -e "${C_WHITE}  DMARC value:${C_RESET}"
echo -e "  ${C_GRAY}${DMARC_VALUE}${C_RESET}"
echo -e "$SEP"

DONE=0
SKIPPED=0
ADDED=0
FAIL=0

for ZONE_LINE in "${ZONE_LINES[@]}"; do
  ZONE_ID=$(echo "$ZONE_LINE" | cut -d'|' -f1)
  DOMAIN=$(echo "$ZONE_LINE" | cut -d'|' -f2)
  DONE=$((DONE + 1))

  echo ""
  echo -e "$SEP2"
  echo -e "  ${C_CYAN}[${DONE}/${TOTAL}]  ${C_WHITE}${DOMAIN}${C_RESET}  ${C_YELLOW}(${ZONE_ID})${C_RESET}"

  # Check existing _dmarc record
  EXISTING_ID=$(get_dmarc_record_id "$ZONE_ID")

  if [[ -n "$EXISTING_ID" ]]; then
    echo -e "  ${C_GREEN}[SKIP]  _dmarc already exists -- not overwriting${C_RESET}"
    SKIPPED=$((SKIPPED + 1))
  else
    echo -ne "  ${C_WHITE}[ADD]   Creating _dmarc TXT record...  ${C_RESET}"
    RES=$(create_dmarc "$ZONE_ID")
    if cf_ok "$RES" 2>/dev/null; then
      echo -e "${C_GREEN}OK${C_RESET}"
      ADDED=$((ADDED + 1))
    else
      MSG=$(echo "$RES" | python3 -c "
import sys,json
try:
  d=json.load(sys.stdin); e=d.get('errors',[]); print(e[0].get('message','?') if e else '?')
except: print('parse error')
" 2>/dev/null)
      echo -e "${C_RED}FAILED: ${MSG}${C_RESET}"
      FAIL=$((FAIL + 1))
    fi
  fi

done

echo ""
echo -e "$SEP"
echo -e "${C_YELLOW}  ========================  FINAL SUMMARY  ========================${C_RESET}"
echo -e "$SEP"
echo -e "  ${C_WHITE}Total zones:   ${TOTAL}${C_RESET}"
echo -e "  ${C_GREEN}Already had _dmarc (skipped):  ${SKIPPED}${C_RESET}"
echo -e "  ${C_GREEN}DMARC added:   ${ADDED}${C_RESET}"
[[ $FAIL -gt 0 ]] && echo -e "  ${C_RED}FAILED:        ${FAIL}${C_RESET}"
echo ""
echo -e "  ${C_WHITE}DMARC record:${C_RESET}"
echo -e "  ${C_GRAY}TXT  _dmarc  \"${DMARC_VALUE}\"${C_RESET}"
echo -e "  ${C_WHITE}Verify: CF Dashboard -> DNS -> TXT records${C_RESET}"
echo -e "$SEP"
echo -e "${C_GREEN}  = Rooted by VladiMIR + AI | v2026.06.04a | github.com/GinCz =${C_RESET}"
echo -e "$SEP"
echo ""
