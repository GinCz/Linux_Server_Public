#!/usr/bin/env bash
# English comments: Silent Domain Check (Alerts only if status != 200)
source /root/.server_env

DOMAINS=$(grep -roP 'server_name \K[^; ]+' /etc/nginx/fastpanel2-sites/ /etc/nginx/fastpanel2-available/ 2>/dev/null | awk -F: '{print $2}' | tr ' ' '\n' | sed 's/^www\.//' | grep "\." | sort -u)

for DOMAIN in $DOMAINS; do
    STATUS=$(curl -4 -Ls -o /dev/null -w "%{http_code}" --connect-timeout 2 "https://$DOMAIN" 2>/dev/null || echo "000")
    
    if [ "$STATUS" -ne 200 ]; then
        MESSAGE="🚨 SITE DOWN: $DOMAIN (Status: $STATUS) | Server: ${SERVER_TAG:-$(hostname)}"
        curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
             -d "chat_id=${TG_CHAT_ID}" -d "text=$MESSAGE" > /dev/null
    fi
done
