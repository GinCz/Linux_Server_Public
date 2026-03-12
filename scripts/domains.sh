#!/usr/bin/env bash
clear
source /root/.server_env

echo ">>> Scanning for domains..."
DOMAINS=$(find /var/www/*/data/www -mindepth 1 -maxdepth 1 -type d ! -name "html" -printf "%f\n" | sort -u)
COUNT=$(echo "$DOMAINS" | grep -v '^$' | wc -l)

if [ "$COUNT" -eq 0 ]; then
    echo "No domains found."
    exit 0
fi
echo "Found $COUNT domains."
echo ">>> Parallel check started... (Real-time mode)"

TMP_FILE=$(mktemp)

for DOMAIN in $DOMAINS; do
    (
        HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" -L -m 7 "http://$DOMAIN")
        if curl -s -I -m 5 "https://$DOMAIN" > /dev/null 2>&1; then
            SSL_STATUS="SSL OK"
        else
            SSL_STATUS="SSL FAIL"
        fi
        
        if [[ "$HTTP_CODE" =~ ^(200|301|302|403)$ ]] && [[ "$SSL_STATUS" == "SSL OK" ]]; then
            RESULT="[\e[32mOK\e[0m] $DOMAIN ($HTTP_CODE | $SSL_STATUS)"
        else
            RESULT="[\e[31mFAIL\e[0m] $DOMAIN (HTTP: $HTTP_CODE | $SSL_STATUS)"
        fi
        
        # 1. Выводим на экран мгновенно!
        echo -e "$RESULT"
        
        # 2. Пишем в файл для Telegram
        echo -e "$RESULT" >> $TMP_FILE
    ) &
    
    if [[ $(jobs -r -p | wc -l) -ge 15 ]]; then
        wait -n
    fi
done
wait

BAD_DOMAINS=$(grep "FAIL" $TMP_FILE | sed -r "s/\x1B\[[0-9;]*[a-zA-Z]//g")
BAD_COUNT=$(grep -c "FAIL" $TMP_FILE)

echo -e "\n>>> Done at $(date +%H:%M:%S)"

if [ "$BAD_COUNT" -eq 0 ]; then
    MSG="✅ *Domain Check: $SERVER_TAG*
Все $COUNT доменов работают отлично!
(Коды ответов и SSL сертификаты в норме)"
else
    MSG="🚨 *DOMAIN ALERT: $SERVER_TAG*
Проверено: $COUNT доменов
Ошибок/Офлайн: $BAD_COUNT

☠️ *Проблемные домены:*
$BAD_DOMAINS"
fi

curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
    -d "chat_id=$TG_CHAT_ID" \
    -d "text=$MSG" > /dev/null

rm -f $TMP_FILE
echo ">>> Telegram report sent!"
