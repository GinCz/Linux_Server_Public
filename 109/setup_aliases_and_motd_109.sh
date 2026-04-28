#!/bin/bash
clear
# ===================================================================
# Script: setup_aliases_and_motd_109.sh
# Version: v2026-04-25
# Server: 109-RU-FastVDS (212.109.223.109)
# Purpose: One-click setup for aliases + MOTD on server 109
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== Setup Aliases + MOTD for 109 v2026-04-25 ==="

cat > ~/.bashrc << 'INNER'
clear
if [ -f ~/Linux_Server_Public/scripts/shared_aliases_109.sh ]; then
    . ~/Linux_Server_Public/scripts/shared_aliases_109.sh
fi

PS1='\[\e[31m\]root@109-RU-FastVDS\[\e[0m\]:\[\e[33m\]\w\[\e[0m\]# '

if [ -f ~/Linux_Server_Public/109/motd_server_v2026-04-25.sh ]; then
    bash ~/Linux_Server_Public/109/motd_server_v2026-04-25.sh
fi

echo "=== .bashrc v2026-04-25 for 109 loaded ==="
INNER

echo "✅ Aliases and MOTD for 109 configured successfully."
echo "Reconnect SSH or run: source ~/.bashrc"
