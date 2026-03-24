#!/usr/bin/env bash
# English comments: Silent Disk Monitor (Alerts only on >90%)
source /root/.server_env

THRESHOLD=90
# Берем использование основной партиции и убираем знак %
DISK_USAGE=$(df / | grep / | awk '{ print $5 }' | sed 's/%//')

# Проверяем, что значение — число, чтобы не было ошибки "integer expression expected"
if [[ "$DISK_USAGE" =~ ^[0-9]+$ ]]; then
    if [ "$DISK_USAGE" -gt "$THRESHOLD" ]; then
        MESSAGE="🚨 LOW DISK SPACE: ${DISK_USAGE}% on ${SERVER_TAG:-$(hostname)}"
        curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
             -d "chat_id=${TG_CHAT_ID}" -d "text=$MESSAGE" > /dev/null
    fi
fi
