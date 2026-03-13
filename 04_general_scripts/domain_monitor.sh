#!/usr/bin/env bash
# English comments: Turbo Domain Monitor v3.0 (3 attempts with 15s delay)
source /root/.server_env

# Собираем уникальный список доменов
DOMAINS=$(grep -roP 'server_name \K[^; ]+' /etc/nginx/fastpanel2-sites/ /etc/nginx/fastpanel2-available/ 2>/dev/null | awk -F: '{print $2}' | tr ' ' '\n' | sed 's/^www\.//' | grep "\." | sort -u)

for DOMAIN in $DOMAINS; do
    SUCCESS=false
    
    # Цикл на 3 попытки
    for ATTEMPT in {1..3}; do
        STATUS=$(curl -4 -Ls -o /dev/null -w "%{http_code}" --connect-timeout 5 "https://$DOMAIN" 2>/dev/null || echo "000")
        
        if [ "$STATUS" -eq 200 ]; then
            SUCCESS=true
            break # Выходим из цикла попыток, если всё ок
        fi
        
        # Если это не последняя попытка — ждем 15 секунд
        if [ $ATTEMPT -lt 3 ]; then
            sleep 15
        fi
    done

    # Если после 3 попыток статус всё еще не 200 — пишем в Telegram
    if [ "$SUCCESS" = false ]; then
        MESSAGE="🚨 CRITICAL: $DOMAIN is DOWN!%0A📊 Status: $STATUS (after 3 attempts)%0A🌐 Server: ${SERVER_TAG:-$(hostname)}"
        curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
             -d "chat_id=${TG_CHAT_ID}" -d "text=$MESSAGE" > /dev/null
    fi
done
