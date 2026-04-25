#!/usr/bin/env bash
# English comments: Main Node Setup (222) - FastPanel & GitHub Sync
source /root/.server_env

echo "--- [001] Starting Main Node Configuration ---"

# Настройка Samba с использованием переменных из .server_env
(echo "$SAMBA_PASS_VLAD"; echo "$SAMBA_PASS_VLAD") | smbpasswd -a -s vlad
(echo "$SAMBA_PASS_USR"; echo "$SAMBA_PASS_USR") | smbpasswd -a -s usr

# Telegram Alert также через переменные
curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
     -d "chat_id=${TG_CHAT_ID}" \
     -d "text=💎 MAIN NODE UPDATED: ${SERVER_TAG:-$(hostname)}" >/dev/null

echo "✅ Main Node Setup Finished!"

echo "========================================="
echo "📘 HOW TO ADD USERS (READ THIS):"
echo "https://github.com/GinCz/Linux_Server_Public/tree/main/xray"
echo "========================================="

