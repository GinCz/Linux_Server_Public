#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  setup_eu_222.sh | [v2026-05-01]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Main Node Setup (222) configuration helper
# Servers     : 222-DE NetCup (152.53.182.222)
# Usage       : bash 109/setup_eu_222.sh
# ==========================================================================================

source /root/.server_env

echo "--- [001] Starting Main Node Configuration ---"

# Configure Samba users using variables from .server_env
(echo "$SAMBA_PASS_VLAD"; echo "$SAMBA_PASS_VLAD") | smbpasswd -a -s vlad
(echo "$SAMBA_PASS_USR"; echo "$SAMBA_PASS_USR") | smbpasswd -a -s usr

# Telegram Alert notification
curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
     -d "chat_id=${TG_CHAT_ID}" \
     -d "text=💎 MAIN NODE UPDATED: ${SERVER_TAG:-$(hostname)}" >/dev/null

echo "✅ Main Node Setup Finished!"
echo "========================================="

# = Rooted by VladiMIR | AI = v2026-05-01 = github.com/GinCz/Linux_Server_Public


