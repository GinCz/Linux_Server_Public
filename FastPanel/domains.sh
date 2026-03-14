#!/usr/bin/env bash
# Domains Checker (Live Output) for Ing. VladiMIR Bulantsev | 2026
# Version: 2.1 (No www, Real-time display)

# Load colors and TG functions
source /root/scripts/System/common.sh 2>/dev/null

clear
C='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; X='\033[0m'
SERVER_NAME=$(hostname)
REPORT_MSG="📊 SERVER: ${SERVER_NAME}\n---------------------------\n"

echo -e "${Y}🚀 Starting Live Domain Check on ${SERVER_NAME}...${X}"
echo "---------------------------"

# Получаем список доменов без www
DOMAINS=$(grep -r "server_name" /etc/nginx/sites-enabled/ | awk '{print $3}' | sed 's/;//' | grep "\." | grep -v "^www\." | sort -u)

for domain in $DOMAINS; do
    # Проверка (таймаут 5 сек)
    STATUS=$(curl -o /dev/null -s -L -w "%{http_code}" --max-time 5 "http://$domain")
    
    if [ "$STATUS" == "200" ] || [ "$STATUS" == "301" ] || [ "$STATUS" == "302" ]; then
        LINE="✅ ${domain} | ${C}${STATUS}${X}"
        TG_LINE="✅ ${domain} | ${STATUS}"
    else
        LINE="❌ ${domain} | ${R}${STATUS}${X}"
        TG_LINE="❌ ${domain} | ${STATUS}"
    fi
    
    # Сразу выводим в консоль
    echo -e "$LINE"
    # Накапливаем для Telegram
    REPORT_MSG="${REPORT_MSG}${TG_LINE}\n"
done

echo "---------------------------"
echo -e "${C}Done! Sending report to Telegram...${X}"

# Отправка в Телеграм (если функция существует)
if command -v send_tg >/dev/null 2>&1; then
    send_tg "$REPORT_MSG"
fi
