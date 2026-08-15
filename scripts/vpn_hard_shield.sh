#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  vpn_hard_shield.sh | [v2026-08-15]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : IPTables shield and log vacuum for low-resource VPN nodes
# Servers     : VPN Nodes
# Usage       : bash scripts/vpn_hard_shield.sh
# ==========================================================================================
apt-get update -qq && apt-get install -y fail2ban -qq; S=$(echo $SSH_CLIENT | awk '{print $1}'); [ -n "$S" ] && iptables -I INPUT -s "$S" -p tcp --dport 22 -j ACCEPT 2>/dev/null; B="144.76.32.114 185.177.72.56"; for i in $B; do iptables -I INPUT -s "$i" -j DROP 2>/dev/null; done; journalctl --vacuum-time=1d; rm -rf /var/log/*.gz /var/log/*.1 2>/dev/null; echo "VPN Hard Shield applied. Logs vacuumed."

# = Rooted by VladiMIR | AI = v2026-08-15 = github.com/GinCz/Linux_Server_Public
