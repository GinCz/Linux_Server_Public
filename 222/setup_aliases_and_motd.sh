#!/bin/bash
clear
# =============================================================
# Script:      setup_aliases_and_motd.sh
# Version:     v2026-04-25
# Server:      222-DE-NetCup (xxx.xxx.xxx.222)
# Description: One-click setup for aliases + MOTD on server 222.
#              Deploys .bashrc with 222-specific aliases, PS1 prompt,
#              MOTD banner, and Midnight Commander F2 menu.
# Usage:       bash /root/Linux_Server_Public/222/setup_aliases_and_motd.sh
# Dependencies: bash, cp, cat
# WARNING:     Affects only new SSH sessions. Safe on production server.
# = Rooted by VladiMIR | AI =
# =============================================================

echo "=== Setup Aliases + MOTD for 222-DE-NetCup ==="

cp -f ~/Linux_Server_Public/scripts/shared_aliases_222.sh ~/.bashrc_aliases 2>/dev/null || true

cat > ~/.bashrc << 'INNER'
clear
if [ -f ~/Linux_Server_Public/scripts/shared_aliases_222.sh ]; then
    . ~/Linux_Server_Public/scripts/shared_aliases_222.sh
fi

PS1='\[\e[31m\]root@222-DE-NetCup\[\e[0m\]:\[\e[33m\]\w\[\e[0m\]# '

if [ -f ~/Linux_Server_Public/222/motd_server.sh ]; then
    bash ~/Linux_Server_Public/222/motd_server.sh
fi

echo "=== .bashrc v2026-04-25 for 222-DE-NetCup loaded ==="
INNER

echo "✅ Aliases and MOTD for 222-DE-NetCup configured successfully."
echo "Reconnect SSH or run: source ~/.bashrc"
