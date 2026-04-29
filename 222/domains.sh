#!/usr/bin/env bash
# =============================================================================
# domains.sh — Check all domains hosted on 222-DE-NetCup via Nginx
# Version     : v2026-04-30
# Server      : 222-DE-NetCup (152.53.182.222)
# Usage       : domains  (alias) or bash /root/Linux_Server_Public/222/domains.sh
# = Rooted by VladiMIR | AI =
# =============================================================================
clear

C='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; X='\033[0m'
SERVER_NAME=$(hostname)
REPORT_MSG="📊 SERVER: ${SERVER_NAME}\n---------------------------\n"

echo -e "${Y}🚀 Checking domains on ${SERVER_NAME}...${X}"
echo "---------------------------"

DOMAINS=$(nginx -T 2>/dev/null | grep "server_name " | awk '{for(i=2;i<=NF;i++) print $i}' | tr -d ';' | grep "\." | grep -v "^www\." | grep -v "localhost" | sort -u)

if [ -z "$DOMAINS" ]; then
    echo -e "${R}❌ No domains found in Nginx config!${X}"
    exit 1
fi

for domain in $DOMAINS; do
    STATUS=$(curl -o /dev/null -s -L -w "%{http_code}" --max-time 5 "http://$domain")
    if [ "$STATUS" == "200" ] || [ "$STATUS" == "301" ] || [ "$STATUS" == "302" ]; then
        COLOR=$C; SYMBOL="✅"
    else
        COLOR=$R; SYMBOL="❌"
    fi
    echo -e "${SYMBOL} ${domain} | ${COLOR}${STATUS}${X}"
    REPORT_MSG="${REPORT_MSG}${SYMBOL} ${domain} | ${STATUS}\n"
done

echo "---------------------------"
echo -e "${C}Done!${X}"

[ -n "${TG_TOKEN:-}" ] && curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
  -d "chat_id=${TG_CHAT_ID}" \
  -d "text=$(echo -e "$REPORT_MSG")" > /dev/null
