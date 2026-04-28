#!/bin/bash
clear
# =============================================================
# Script:      setup_aliases_and_motd.sh
# Version:     v2026-04-25
# Server:      All VPN nodes (STOLB_24 / TATRA_9 / ALEX_47 / 4TON_237 / SO_38)
# Description: One-click universal setup for VPN server aliases + MOTD.
#              Deploys .bashrc with VPN-specific aliases, PS1 prompt,
#              MOTD banner (with AdGuard Home, Uptime Kuma support),
#              and Midnight Commander F2 menu.
# Usage:       bash /root/Linux_Server_Public/VPN/setup_aliases_and_motd.sh
# Dependencies: bash, cp, cat
# WARNING:     Affects only new SSH sessions. Safe on production VPN node.
# = Rooted by VladiMIR | AI =
# =============================================================

echo "=== Setup Aliases + MOTD for VPN Nodes ==="

cat > ~/.bashrc << 'INNER'
clear
if [ -f ~/Linux_Server_Public/VPN/shared_aliases_vpn.sh ]; then
    . ~/Linux_Server_Public/VPN/shared_aliases_vpn.sh
fi

PS1='\[\e[32m\]root@VPN-Node\[\e[0m\]:\[\e[33m\]\w\[\e[0m\]# '

if [ -f ~/Linux_Server_Public/VPN/motd_server.sh ]; then
    bash ~/Linux_Server_Public/VPN/motd_server.sh
fi

echo "=== .bashrc v2026-04-25 for VPN-Node loaded ==="
INNER

echo "✅ Universal VPN aliases and MOTD configured (AdGuard + Uptime Kuma support)."
echo "Reconnect SSH or run: source ~/.bashrc"
