#!/usr/bin/env bash
# ==============================================================================
# AI API KEYS MONITOR & REAL-TIME BALANCE AUDIT (Public Template)
# Rooted by VladiMIR + Antigravity AI | https://github.com/GinCz/Linux_Server_Public
# ==============================================================================
clear

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

fmt_num() {
    local val="$1"
    if [[ "$val" =~ ^[0-9]+$ ]]; then
        echo "$val" | awk '{
            len = length($0);
            res = "";
            for (i = 1; i <= len; i++) {
                res = res substr($0, i, 1);
                if ((len - i) % 3 == 0 && i != len) {
                    res = res " ";
                }
            }
            print res;
        }'
    else
        echo "$val"
    fi
}

echo -e "${BOLD}${CYAN}=====================================================================================${NC}"
echo -e "${BOLD}${CYAN}                   AI API KEYS MONITOR & REAL-TIME BALANCE AUDIT                     ${NC}"
echo -e "${BOLD}${CYAN}                   Master Node: DE-222 | $(date -u '+%Y-%m-%d %H:%M:%S UTC')                   ${NC}"
echo -e "${BOLD}${CYAN}=====================================================================================${NC}"
echo ""

CONF_FILE="/root/.ai_keys.conf"
KEYS_CONFIG=()

if [[ -f "$CONF_FILE" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        KEYS_CONFIG+=("$line")
    done < "$CONF_FILE"
fi

if [[ ${#KEYS_CONFIG[@]} -eq 0 ]]; then
    echo -e "${YELLOW}Notice: No configuration found in $CONF_FILE. Please configure your keys.${NC}"
    echo "Example format in $CONF_FILE:"
    echo "tooken|AI_01|login|tc_live_KEY|5000000|tooken.club/dashboard|https://tooken.club/v1/balance"
    exit 0
fi

printf "${BOLD}%-7s %-7s %-16s %-16s %-24s %-14s${NC}\n" "STATUS" "NAME" "CURRENT TOKENS" "INITIAL TOKENS" "DASHBOARD" "LOGIN"
echo "-------------------------------------------------------------------------------------"

TOTAL_CURRENT=0
TOTAL_INITIAL=0
ACTIVE_COUNT=0
TOTAL_COUNT=${#KEYS_CONFIG[@]}

for item in "${KEYS_CONFIG[@]}"; do
    IFS="|" read -r ktype name login key initial domain endpoint <<< "$item"
    resp=$(curl -s -m 5 -H "Authorization: Bearer $key" "$endpoint" 2>/dev/null)
    bal=""
    if command -v jq >/dev/null 2>&1; then
        bal=$(echo "$resp" | jq -r '.balance // empty' 2>/dev/null)
    else
        bal=$(echo "$resp" | grep -o '"balance":[0-9]*' | head -n1 | cut -d':' -f2)
    fi
    
    if [[ -n "$bal" && "$bal" =~ ^[0-9]+$ ]]; then
        status_disp="${GREEN}[OK]  ${NC}"
        ((ACTIVE_COUNT++))
        if [[ "$ktype" == "claudehub" ]]; then
            bal=$((bal * 30000))
        fi
        TOTAL_CURRENT=$((TOTAL_CURRENT + bal))
        TOTAL_INITIAL=$((TOTAL_INITIAL + initial))
        cur_disp=$(fmt_num "$bal")
        init_disp=$(fmt_num "$initial")
        printf "%b %-7s ${GREEN}%-16s${NC} %-16s %-24s ${YELLOW}%-14s${NC}\n" "$status_disp" "$name" "$cur_disp" "$init_disp" "$domain" "$login"
    else
        status_disp="${RED}[FAIL]${NC}"
        init_disp=$(fmt_num "$initial")
        TOTAL_INITIAL=$((TOTAL_INITIAL + initial))
        printf "%b %-7s ${RED}%-16s${NC} %-16s %-24s ${YELLOW}%-14s${NC}\n" "$status_disp" "$name" "OFFLINE" "$init_disp" "$domain" "$login"
    fi
done

echo "-------------------------------------------------------------------------------------"
TOTAL_USED=$((TOTAL_INITIAL - TOTAL_CURRENT))
FMT_CUR=$(fmt_num "$TOTAL_CURRENT")
FMT_INIT=$(fmt_num "$TOTAL_INITIAL")
FMT_USED=$(fmt_num "$TOTAL_USED")

echo ""
echo -e "${BOLD}SUMMARY (ALL TOKENS):${NC}"
echo -e "  * Active Keys:           ${GREEN}${ACTIVE_COUNT}${NC} of ${TOTAL_COUNT}"
echo -e "  * Total Current Balance: ${GREEN}${FMT_CUR}${NC} tokens"
echo -e "  * Total Initial Tokens:  ${CYAN}${FMT_INIT}${NC} tokens"
echo -e "  * Total Tokens Used:     ${YELLOW}${FMT_USED}${NC} tokens"
echo -e "${BOLD}${CYAN}=====================================================================================${NC}"
echo ""