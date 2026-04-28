#!/bin/bash
clear
# =============================================================
# Script:      setup_aliases_and_motd.sh
# Version:     v2026-04-28
# Server:      109-RU-FastVDS (xxx.xxx.xxx.109)
# Description: One-click setup for aliases + MOTD on server 109.
#              Deploys .bashrc with 109-specific aliases, PS1 prompt,
#              MOTD banner, and Midnight Commander F2 menu.
# Usage:       bash /root/Linux_Server_Public/109/setup_aliases_and_motd.sh
# Dependencies: bash, cp, cat
# WARNING:     Affects only new SSH sessions. Safe on production server.
# = Rooted by VladiMIR | AI =
# =============================================================

echo "=== Setup Aliases + MOTD for 109-RU-FastVDS ==="

cp -f ~/Linux_Server_Public/scripts/shared_aliases_109.sh ~/.bashrc_aliases 2>/dev/null || true

cat > ~/.bashrc << 'INNER'
clear
if [ -f ~/Linux_Server_Public/scripts/shared_aliases_109.sh ]; then
    . ~/Linux_Server_Public/scripts/shared_aliases_109.sh
fi

PS1='\[\e[34m\]root@109-RU-FastVDS\[\e[0m\]:\[\e[33m\]\w\[\e[0m\]# '

if [ -f ~/Linux_Server_Public/109/motd_server.sh ]; then
    bash ~/Linux_Server_Public/109/motd_server.sh
fi

echo "=== .bashrc v2026-04-28 for 109-RU-FastVDS loaded ==="
INNER

echo "✅ Aliases and MOTD for 109-RU-FastVDS configured successfully."
echo "Reconnect SSH or run: source ~/.bashrc"
