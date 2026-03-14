#!/usr/bin/env bash
# Domains Checker (Nginx-Loaded Fix) for Ing. VladiMIR Bulantsev | 2026

source /root/scripts/System/common.sh 2>/dev/null

clear
C='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; X='\033[0m'
SERVER_NAME=$(hostname)
REPORT_MSG="📊 SERVER: ${SERVER_NAME}\n---------------------------\n"

echo -e "${Y}🚀 Starting Live Domain Check on ${SERVER_NAME}...${X}"
echo "---------------------------"

# Вытаскиваем домены напрямую из активной конфигурации Nginx
DOMAINS=$(nginx -T 2>/dev/null | grep "server_name " | awk '{for(i=2;i<=NF;i++) print $i}' | tr -d ';' | grep "\." | grep -v "^www\." | grep -v "localhost" | sort -u)

if [ -z "$DOMAINS" ]; then
    echo -e "${R}❌ Домены не найдены даже в активной конфигурации Nginx!${X}"
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
echo -e "${C}Done! Sending report to Telegram...${X}"

if [[ $(type -t send_tg) == function ]]; then
    send_tg "$REPORT_MSG"
else
    [ -n "$TG_TOKEN" ] && curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" -d "chat_id=${TG_CHAT_ID}&text=$(echo -e "$REPORT_MSG")" > /dev/null
fi
