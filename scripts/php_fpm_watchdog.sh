#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  php_fpm_watchdog.sh | [v2026-08-01]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : PHP-FPM crash watchdog and auto-restart service
# Servers     : All FastPanel Web Nodes
# Usage       : bash scripts/php_fpm_watchdog.sh
# ==========================================================================================
source /root/.server_env 2>/dev/null || true
TELEGRAM_TOKEN="${TG_TOKEN:-}"
TELEGRAM_CHAT_ID="${TG_CHAT_ID:-261784949}"
CPU_THRESHOLD=80
LOG="/var/log/php_fpm_watchdog.log"
STATE_DIR="/tmp/php_watchdog"
mkdir -p "$STATE_DIR"

send_telegram() {
    local msg="$1"
    [ -z "$TELEGRAM_TOKEN" ] && return
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

# = Rooted by VladiMIR | AI = v2026-08-01 = github.com/GinCz/Linux_Server_Public
