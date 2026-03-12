#!/usr/bin/env bash
# Common functions for VladiMIR Infrastructure

# UI Colors
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Lock function to prevent multiple instances
lock_or_exit() {
    LOCKFILE="/tmp/${1:-script}.lock"
    if [ -e "${LOCKFILE}" ] && kill -0 $(cat "${LOCKFILE}") 2>/dev/null; then
        echo -e "${RED}Error: Script is already running.${NC}"
        exit 1
    fi
    echo $$ > "${LOCKFILE}"
    trap "rm -f '${LOCKFILE}'" EXIT
}

# Telegram Notify function
send_tg() {
    if [ -f /root/.server_env ]; then
        source /root/.server_env
        curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
            -d "chat_id=${TG_CHAT_ID}" \
            -d "text=[${SERVER_TAG}] $1" > /dev/null
    fi
}
