#!/usr/bin/env bash
# Script:  domain_monitor.sh
# Version: v2026-03-17
# Purpose: Monitor all nginx domains. Sends Telegram alert if site is down
#          after 3 attempts with 15s delay. Works on 222 and 109.
# Usage:   /opt/server_tools/scripts/domain_monitor.sh
# Cron:    */30 * * * * /opt/server_tools/scripts/domain_monitor.sh

source /root/.server_alliances.conf 2>/dev/null || true

DOMAINS=$(grep -roP 'server_name \K[^; ]+' \
    /etc/nginx/fastpanel2-sites/ \
    /etc/nginx/fastpanel2-available/ 2>/dev/null \
    | awk -F: '{print $2}' | tr ' ' '\n' \
    | sed 's/^www\.//' | grep "\." | sort -u)

for DOMAIN in $DOMAINS; do
    SUCCESS=false

    for ATTEMPT in {1..3}; do
        STATUS=$(curl -4 -Ls -o /dev/null -w "%{http_code}" \
            --connect-timeout 5 "https://$DOMAIN" 2>/dev/null || echo "000")

        if [ "$STATUS" -eq 200 ]; then
            SUCCESS=true
            break
        fi

        [ $ATTEMPT -lt 3 ] && sleep 15
    done

    if [ "$SUCCESS" = false ]; then
        MESSAGE="🚨 CRITICAL: $DOMAIN is DOWN!%0A📊 Status: $STATUS (after 3 attempts)%0A🌐 Server: ${SERVER_TAG:-$(hostname)}"
        curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
            -d "chat_id=${TG_CHAT_ID}" \
            -d "text=$MESSAGE" >/dev/null 2>&1 || true
    fi
done
