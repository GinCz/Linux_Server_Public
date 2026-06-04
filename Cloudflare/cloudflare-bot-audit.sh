#!/bin/bash
# ════════════════════════════════════════════════════════════════════
#   cloudflare-bot-audit.sh
#   Cloudflare Bot & Security Audit — Full zone-wide overview
#
#   Version  : v2026.06.04
#   Author   : Rooted by VladiMIR + AI
#   GitHub   : https://github.com/GinCz/Linux_Server_Public
#   License  : MIT
# ════════════════════════════════════════════════════════════════════
#
#   Checks all active Cloudflare zones in the account:
#     ✦ Bot Fight Mode         (fight_mode)
#     ✦ JS Detections          (enable_js)
#     ✦ Block AI Bots          (ai_bots_protection)
#     ✦ Rate Limit rules count (http_ratelimit phase)
#     ✦ Security Level         (security_level setting)
#
#   Output:
#     - Live colored table in terminal
#     - CSV file in /tmp/cf-bot-audit-YYYYMMDD-HHMMSS.csv
#
#   Usage:
#     export CF_TOKEN="cfat_XXXXXXXXXXXXXXXXXXXXXXXX"
#     bash cloudflare-bot-audit.sh
#
#   Requirements: curl, python3
#
#   NOTE: This script is AUDIT ONLY — it does NOT change any settings.
#   NOTE: On FREE plan, Bot Fight Mode can only be toggled in Dashboard.
# ════════════════════════════════════════════════════════════════════

API="https://api.cloudflare.com/client/v4"
VERSION="v2026.06.04"

GREEN="\033[0;32m"; RED="\033[0;31m"; YELLOW="\033[1;33m"
CYAN="\033[0;36m"; NC="\033[0m"; BOLD="\033[1m"

if [[ -z "${CF_TOKEN}" ]]; then
    echo -e "${RED}ERROR:${NC} CF_TOKEN is not set."
    echo "  export CF_TOKEN=\"cfat_XXXXXXXXXXXXXXXXXXXXXXXX\""
    echo "  Get your token: https://dash.cloudflare.com/profile/api-tokens"
    exit 1
fi

PAGE=1; TOTAL=0; ISSUES=0
CSV="/tmp/cf-bot-audit-$(date +%Y%m%d-%H%M%S).csv"
echo "Domain,Zone_ID,BotFight,JS_Detect,BlockAIBots,RateLimitRules,SecurityLevel" > "$CSV"

echo
echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║  CLOUDFLARE BOT & SECURITY AUDIT — ALL ACTIVE ZONES           ║${NC}"
echo -e "${BOLD}${CYAN}║  cloudflare-bot-audit.sh  ${VERSION}  github.com/GinCz       ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo -e "   Started : $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "   CSV     : ${CSV}"
echo

printf "${BOLD}%-35s %-10s %-10s %-17s %-11s %-12s${NC}\n" \
    "Domain" "BotFight" "JS_Detect" "BlockAIBots" "RateLimit" "Sec.Level"
printf '%0.s─' {1..100}; echo

while true; do
    RESP=$(curl -s "${API}/zones?per_page=50&page=${PAGE}&status=active" \
        -H "Authorization: Bearer ${CF_TOKEN}")

    ZONES=$(echo "$RESP" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for z in d.get('result', []):
    print(z['id'] + '|' + z['name'])
")
    COUNT=$(echo "$RESP" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('result',[])))")
    [[ "$COUNT" -eq 0 ]] && break

    while IFS='|' read -r ZONE_ID DOMAIN; do
        [[ -z "$ZONE_ID" ]] && continue

        BOT=$(curl -s "${API}/zones/${ZONE_ID}/bot_management" \
            -H "Authorization: Bearer ${CF_TOKEN}")

        FIGHT=$(echo "$BOT" | python3 -c "import sys,json; r=json.load(sys.stdin).get('result',{}); print('ON' if r.get('fight_mode') else 'off')" 2>/dev/null)
        JS=$(echo "$BOT"    | python3 -c "import sys,json; r=json.load(sys.stdin).get('result',{}); print('ON' if r.get('enable_js') else 'off')" 2>/dev/null)
        AI=$(echo "$BOT"    | python3 -c "import sys,json; r=json.load(sys.stdin).get('result',{}); print(r.get('ai_bots_protection','?'))" 2>/dev/null)

        SEC=$(curl -s "${API}/zones/${ZONE_ID}/settings/security_level" \
            -H "Authorization: Bearer ${CF_TOKEN}" | \
            python3 -c "import sys,json; print(json.load(sys.stdin).get('result',{}).get('value','?'))" 2>/dev/null)

        RL=$(curl -s "${API}/zones/${ZONE_ID}/rulesets/phases/http_ratelimit/entrypoint" \
            -H "Authorization: Bearer ${CF_TOKEN}" | \
            python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('result',{}).get('rules',[])))" 2>/dev/null || echo "0")

        FIGHT_C="${RED}${FIGHT}${NC}"; [[ "$FIGHT" == "ON"    ]] && FIGHT_C="${GREEN}${FIGHT}${NC}"
        JS_C="${RED}${JS}${NC}";       [[ "$JS"    == "ON"    ]] && JS_C="${GREEN}${JS}${NC}"
        AI_C="${RED}${AI}${NC}";       [[ "$AI"    == "block" ]] && AI_C="${GREEN}${AI}${NC}"
        SEC_C="${YELLOW}${SEC}${NC}";  [[ "$SEC"   == "high"  ]] && SEC_C="${GREEN}${SEC}${NC}"

        MARK="  "
        if [[ "$FIGHT" != "ON" ]] || [[ "$JS" != "ON" ]] || [[ "$AI" != "block" ]] || [[ "$SEC" != "high" ]]; then
            MARK="${RED}!${NC} "; ISSUES=$((ISSUES+1))
        fi

        printf "${MARK}%-35s %-18b %-18b %-24b %-11s %-12b\n" \
            "$DOMAIN" "$FIGHT_C" "$JS_C" "$AI_C" "$RL" "$SEC_C"

        echo "${DOMAIN},${ZONE_ID},${FIGHT},${JS},${AI},${RL},${SEC}" >> "$CSV"
        TOTAL=$((TOTAL+1))
    done <<< "$ZONES"

    PAGE=$((PAGE+1))
done

printf '%0.s─' {1..100}; echo
echo
echo -e "${BOLD}SUMMARY${NC}"
echo -e "  Total domains   : ${BOLD}${TOTAL}${NC}"
[[ "$ISSUES" -eq 0 ]] \
    && echo -e "  Issues found    : ${GREEN}${BOLD}0 — all zones fully protected ✓${NC}" \
    || echo -e "  Issues found    : ${RED}${BOLD}${ISSUES} zone(s) with open settings  ← fix needed${NC}"
echo -e "  CSV saved       : ${BOLD}${CSV}${NC}"
echo
echo -e "${BOLD}LEGEND${NC}"
echo "  BotFight    : ON    = Bot Fight Mode active"
echo "  JS_Detect   : ON    = JS Detections active      (settable via API)"
echo "  BlockAIBots : block = AI bots protection active (settable via API)"
echo "  RateLimit   : number of active rate-limit rules in the zone"
echo "  Sec.Level   : Cloudflare security level — target: high"
echo
echo -e "${BOLD}NOTES${NC}"
echo "  !  = zone has at least one setting below recommended level"
echo "  Bot Fight Mode [off] on FREE plan — fix in Dashboard:"
echo "  → dash.cloudflare.com → [domain] → Security → Settings → Bot Fight Mode → ON"
echo
