#!/usr/bin/env bash
# Domains Checker (FastPanel Fix) for Ing. VladiMIR Bulantsev | 2026

# Load colors and TG functions
source /root/scripts/System/common.sh 2>/dev/null

clear
C='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; X='\033[0m'
SERVER_NAME=$(hostname)
REPORT_MSG="📊 SERVER: ${SERVER_NAME}\n---------------------------\n"

echo -e "${Y}🚀 Starting Live Domain Check on ${SERVER_NAME}...${X}"
echo "---------------------------"

# Путь к конфигам в FastPanel
FP_PATH="/etc/nginx/fastpanel2-sites"
# Если папки FastPanel нет, откатываемся на стандартную
[ ! -d "$FP_PATH" ] && FP_PATH="/etc/nginx/sites-enabled"

# Получаем список доменов: ищем server_name, убираем лишнее, фильтруем www.
DOMAINS=$(grep -r "server_name" "$FP_PATH" 2>/dev/null | awk '{print $3}' | tr -d ';' | grep "\." | grep -v "^www\." | sort -u)

if [ -z "$DOMAINS" ]; then
    echo -e "${R}❌ Домены не найдены в $FP_PATH${X}"
    exit 1
fi

for domain in $DOMAINS; do
    # Проверка статус-кода (с редиректами -L)
    STATUS=$(curl -o /dev/null -s -L -w "%{http_code}" --max-time 5 "http://$domain")
    
    if [ "$STATUS" == "200" ] || [ "$STATUS" == "301" ] || [ "$STATUS" == "302" ]; then
        COLOR=$C
        SYMBOL="✅"
    else
        COLOR=$R
        SYMBOL="❌"
    fi
    
    # Вывод в консоль в реальном времени
    echo -e "${SYMBOL} ${domain} | ${COLOR}${STATUS}${X}"
    # Накопление для Telegram (без цветовых кодов)
    REPORT_MSG="${REPORT_MSG}${SYMBOL} ${domain} | ${STATUS}\n"
done

echo "---------------------------"
echo -e "${C}Done! Sending report to Telegram...${X}"

# Отправка в Телеграм (используем нашу функцию из common.sh)
if [[ $(type -t send_tg) == function ]]; then
    send_tg "$REPORT_MSG"
else
    # Если функции нет, пробуем отправить напрямую (на всякий случай)
    [ -n "$TG_TOKEN" ] && curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" -d "chat_id=${TG_CHAT_ID}&text=$(echo -e "$REPORT_MSG")" > /dev/null
fi
