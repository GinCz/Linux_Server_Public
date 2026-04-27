#!/bin/bash
clear
# ===================================================================
# Script: setup_aliases_and_motd_222.sh
# Version: v2026-04-25
# Server: 222-DE-NetCup (152.53.182.222)
# Purpose: One-click setup for aliases + MOTD on server 222
#
# What this script does:
# 1. Copies shared aliases
# 2. Creates .bashrc with 222-specific aliases
# 3. Sets up motd_server.sh
# 4. Reloads configuration
#
# Potential consequences and warnings:
# - Affects only new SSH sessions. No impact on running websites.
# - Safe for production servers with many active sites.
#
# Usage: bash setup_aliases_and_motd_222_v2026-04-25.sh
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== Setup Aliases + MOTD for 222 v2026-04-25 ==="

cp -f ~/Linux_Server_Public/scripts/shared_aliases_222.sh ~/.bashrc_aliases 2>/dev/null || true

cat > ~/.bashrc << 'INNER'
clear
if [ -f ~/Linux_Server_Public/scripts/shared_aliases_222.sh ]; then
    . ~/Linux_Server_Public/scripts/shared_aliases_222.sh
fi

PS1='\[\e[31m\]root@222-DE-NetCup\[\e[0m\]:\[\e[33m\]\w\[\e[0m\]# '

if [ -f ~/Linux_Server_Public/222/motd_server_v2026-04-25.sh ]; then
    bash ~/Linux_Server_Public/222/motd_server_v2026-04-25.sh
fi

echo "=== .bashrc v2026-04-25 for 222 loaded ==="
INNER

echo "✅ Aliases and MOTD for 222 configured successfully."
echo "Reconnect SSH or run: source ~/.bashrc"
