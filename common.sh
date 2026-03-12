#!/usr/bin/env bash
# Common functions for VladiMIR Infrastructure

YELLOW='\033[1;33m'
CYAN='\033[1;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

lock_or_exit() {
    LOCKFILE="/tmp/${1:-script}.lock"
    if [ -e "${LOCKFILE}" ] && kill -0 $(cat "${LOCKFILE}") 2>/dev/null; then
        echo -e "${RED}Error: Script is already running.${NC}"
        exit 1
    fi
    echo $$ > "${LOCKFILE}"
    trap "rm -f '${LOCKFILE}'" EXIT
}

# Telegram function without server tag
send_tg() {
    [ -f /root/.server_env ] && source /root/.server_env
    local MSG="$1"

    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        --data-urlencode "chat_id=${TG_CHAT_ID}" \
        --data-urlencode "text=${MSG}" > /dev/null
}
