#!/usr/bin/env bash
# SSH Login Notification with Whitelist
source /root/scripts/common.sh

# Get connection details
USER_NAME=$(whoami)
IP_ADDRESS=$(echo $SSH_CLIENT | awk '{print $1}')
SERVER_NAME=$(hostname)
DATE_TIME=$(date '+%d-%m-%Y %H:%M:%S')

# Check if IP is whitelisted
WHITELIST="/root/scripts/scripts/ssh_whitelist.txt"
if [ -f "$WHITELIST" ]; then
    if grep -q "$IP_ADDRESS" "$WHITELIST"; then
        # IP is whitelisted, exit silently
        exit 0
    fi
fi

# Send Telegram alert if not in whitelist
MESSAGE="🔓 *SSH Login Detected*
🌐 Server: ${SERVER_NAME}
👤 User: ${USER_NAME}
📍 IP: ${IP_ADDRESS}
⏰ Time: ${DATE_TIME}"

send_tg "$MESSAGE"
