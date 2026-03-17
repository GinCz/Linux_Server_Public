#!/usr/bin/env bash
# Script:  domains.sh
# Version: v2026-03-17
# Purpose: Check all nginx domains and send status report to Telegram.
# Usage:   /opt/server_tools/scripts/domains.sh
# Alias:   domains

source /opt/server_tools/scripts/common.sh 2>/dev/null || true
source /root/.server_alliances.conf 2>/dev/null || true

clear
C='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; X='\033[0m'
SERVER_NAME=$(hostname)
REPORT_MSG="📊 SERVER: ${SERVER_NAME}\n---------------------------\n"

echo -e "${Y}Starting domain check on ${SERVER_NAME}...${X}"
echo "---------------------------"

DOMAINS=$(nginx -T 2>/dev/null \
    | grep "server_name " \
    | awk '{for(i=2;i<=NF;i++) print $i}' \
    | tr -d ';' \
    | grep "\." \
    | grep -v "^www\." \
    | grep -v "localhost" \
    | sort -u)

if [ -z "$DOMAINS" ]; then
    echo -e "${R}No domains found in nginx config.${X}"
    exit 1
fi

for domain in $DOMAINS; do
    STATUS=$(curl -o /dev/null -s -L -w "%{http_code}" --max-time 5 "http://$domain")

    if [[ "$STATUS" == "200" || "$STATUS" == "301" || "$STATUS" == "302" ]]; then
        COLOR=$C; SYMBOL="✅"
    else
        COLOR=$R; SYMBOL="❌"
    fi

    echo -e "${SYMBOL} ${domain} | ${COLOR}${STATUS}${X}"
    REPORT_MSG="${REPORT_MSG}${SYMBOL} ${domain} | ${STATUS}\n"
done

echo "---------------------------"
echo -e "${C}Sending report to Telegram...${X}"

curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -d "chat_id=${TG_CHAT_ID}" \
    -d "text=$(echo -e "$REPORT_MSG")" >/dev/null 2>&1 || true

echo "Done."
