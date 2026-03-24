#!/usr/bin/env bash
# Script:  php_fpm_watchdog.sh
# Version: v2026-03-24
# Purpose: Monitor PHP-FPM pools CPU usage.
#          If any pool exceeds 80% CPU for more than 2 minutes,
#          the script automatically restarts the corresponding PHP-FPM service
#          and sends a Telegram notification.
#
# Usage:   Run via cron every 15 minutes:
#          */15 * * * * bash /opt/server_tools/scripts/php_fpm_watchdog.sh
#
# How it works:
#   1. Every 15 min: scan all php-fpm pool processes
#   2. If pool CPU > 80% -> create a state file with current timestamp
#   3. Next run (15 min later): if still > 80% -> that's 15 min, restart + notify
#   4. If CPU drops below 80% -> delete state file (false alarm)
#
# Notifications: Telegram bot @My_WWW_bot
# Log file:      /var/log/php_fpm_watchdog.log

TELEGRAM_TOKEN="1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ"
TELEGRAM_CHAT_ID="261784949"
CPU_THRESHOLD=80
LOG="/var/log/php_fpm_watchdog.log"
STATE_DIR="/tmp/php_watchdog"
mkdir -p "$STATE_DIR"

send_telegram() {
    local msg="$1"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${msg}" \
        -d "parse_mode=HTML" > /dev/null 2>&1
}

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG"
}

while IFS= read -r line; do
    pid=$(echo "$line" | awk '{print $2}')
    cpu=$(echo "$line" | awk '{print $3}' | cut -d. -f1)
    pool=$(echo "$line" | grep -oP 'pool \K\S+')

    [ -z "$pool" ] && continue

    state_file="$STATE_DIR/${pool}.high"

    if [ "$cpu" -ge "$CPU_THRESHOLD" ]; then
        if [ -f "$state_file" ]; then
            flagged_at=$(cat "$state_file")
            now=$(date +%s)
            diff=$((now - flagged_at))

            if [ "$diff" -ge 120 ]; then
                log "RESTART: pool $pool CPU=${cpu}% for ${diff}s"
                php_ver=$(ps -p "$pid" -o cmd= 2>/dev/null | grep -oP 'php\K[\d.]+' | head -1)
                if [ -n "$php_ver" ]; then
                    systemctl restart "php${php_ver}-fpm" 2>/dev/null || true
                fi
                send_telegram "⚠️ <b>$(hostname)</b>%0APHP-FPM pool <b>${pool}</b>%0ACPU=${cpu}%% for $((diff/60))min%0A→ php${php_ver}-fpm restarted automatically%0A🕐 $(date '+%Y-%m-%d %H:%M:%S')"
                rm -f "$state_file"
                log "DONE: restarted php${php_ver}-fpm for pool $pool"
            fi
        else
            date +%s > "$state_file"
            log "FLAG: pool $pool CPU=${cpu}% - watching..."
        fi
    else
        rm -f "$state_file" 2>/dev/null
    fi

done < <(ps aux | grep "php-fpm: pool" | grep -v grep)
