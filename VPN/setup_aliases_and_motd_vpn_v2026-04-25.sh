#!/bin/bash
clear
# ===================================================================
# Script: setup_aliases_and_motd_vpn.sh
# Version: v2026-04-25
# Server: All VPN nodes (STOLB_24 with AdGuard Home, TATRA_9 with Uptime Kuma)
# Purpose: One-click universal setup for VPN servers
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== Setup Aliases + MOTD for VPN v2026-04-25 ==="

cat > ~/.bashrc << 'INNER'
clear
if [ -f ~/Linux_Server_Public/VPN/shared_aliases_vpn.sh ]; then
    . ~/Linux_Server_Public/VPN/shared_aliases_vpn.sh
fi

PS1='\[\e[32m\]root@VPN-Node\[\e[0m\]:\[\e[33m\]\w\[\e[0m\]# '

if [ -f ~/Linux_Server_Public/VPN/motd_server_v2026-04-25.sh ]; then
    bash ~/Linux_Server_Public/VPN/motd_server_v2026-04-25.sh
fi

echo "=== .bashrc v2026-04-25 for VPN loaded ==="
INNER

echo "✅ Universal VPN aliases and MOTD configured (AdGuard + Uptime Kuma support)."
echo "Reconnect SSH or run: source ~/.bashrc"
