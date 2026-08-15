#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  setup_aliases_and_motd.sh | [v2026-04-29]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Setup interactive shell environment and MOTD banner
# Servers     : 109-RU FastVDS
# Usage       : bash 109/setup_aliases_and_motd.sh
# ==========================================================================================
echo "=== Setup Aliases + MOTD for 109-RU-FastVDS ==="

cp -f ~/Linux_Server_Public/scripts/shared_aliases_109.sh ~/.bashrc_aliases 2>/dev/null || true

cat > ~/.bashrc << 'INNER'
clear
if [ -f ~/Linux_Server_Public/scripts/shared_aliases_109.sh ]; then
    . ~/Linux_Server_Public/scripts/shared_aliases_109.sh
fi

# bright magenta prompt for 109-RU-FastVDS
PS1='\[\e[95m\]root@109-RU-FastVDS\[\e[0m\]:\[\e[33m\]\w\[\e[0m\]# '

if [ -f ~/Linux_Server_Public/109/motd_server.sh ]; then
    bash ~/Linux_Server_Public/109/motd_server.sh
fi

echo "=== .bashrc v2026-04-29 for 109-RU-FastVDS loaded ==="
INNER

echo "\u2705 Aliases and MOTD for 109-RU-FastVDS configured successfully."
echo "Reconnect SSH or run: source ~/.bashrc"

# = Rooted by VladiMIR | AI = v2026-04-29 = github.com/GinCz/Linux_Server_Public
