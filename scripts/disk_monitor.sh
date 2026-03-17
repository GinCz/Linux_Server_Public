#!/usr/bin/env bash
# Script:  disk_monitor.sh
# Version: v2026-03-17
# Purpose: Silent disk space monitor. Sends Telegram alert only when usage > 90%.
# Usage:   /opt/server_tools/scripts/disk_monitor.sh
# Cron:    0 * * * * /opt/server_tools/scripts/disk_monitor.sh

source /root/.server_alliances.conf 2>/dev/null || true

THRESHOLD=90
DISK_USAGE=$(df / | awk 'NR==2{print $5}' | tr -d '%')

if [[ "$DISK_USAGE" =~ ^[0-9]+$ ]]; then
    if [ "$DISK_USAGE" -gt "$THRESHOLD" ]; then
        MESSAGE="🚨 LOW DISK SPACE: ${DISK_USAGE}% on ${SERVER_TAG:-$(hostname)}"
        curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
            -d "chat_id=${TG_CHAT_ID}" \
            -d "text=$MESSAGE" >/dev/null 2>&1 || true
    fi
fi
