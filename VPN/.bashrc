# =============================================================================
# ~/.bashrc — VPN Servers (AmneziaWG / WireGuard)
# =============================================================================
# Version  : v2026-04-07
# Author   : Ing. VladiMIR Bulantsev
# GitHub   : https://github.com/GinCz/Linux_Server_Public
# Color    : Turquoise (38;5;87)
# Servers  : VPN-EU-4Ton-237, VPN-EU-Tatra-9, VPN-EU-Pilik-178, VPN-EU-Alex-47, ...
# =============================================================================
#
# ALIASES ON THIS SERVER:
#
#   aw      — WireGuard peers stats + active last 15 min
#   audit   — Security + load audit (vpn_node_clean_audit.sh)
#   infooo  — Full server info (VPN/infooo.sh)
#   backup  — Backup configs (VPN/system_backup.sh)
#   banlog  — CrowdSec ban list (last 20)
#   load    — git pull + deploy_vpn_node.sh (MOTD + cleanup)
#   save    — git push
#   00      — clear
#   la      — ls -A (show hidden files)
#   mc      — Midnight Commander
# =============================================================================

export PS1='\[\e[38;5;87m\]\u@\h:\w\$\[\e[m\] '

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# =============================================================================
# VPN SERVER ALIASES
# All scripts are in /root/Linux_Server_Public/VPN/
# =============================================================================

alias audit='bash /root/Linux_Server_Public/VPN/vpn_node_clean_audit.sh'
alias infooo='bash /root/Linux_Server_Public/VPN/infooo.sh'
alias backup='bash /root/Linux_Server_Public/VPN/system_backup.sh'
alias banlog='cscli alerts list -l 20 2>/dev/null || echo "CrowdSec not installed"'

# load — git pull + full deploy (MOTD update + old files cleanup)
# After this: reconnect SSH to see updated MOTD
alias load='cd /root/Linux_Server_Public && git pull --rebase && bash /root/Linux_Server_Public/VPN/deploy_vpn_node.sh'

# =============================================================================
# SHARED ALIASES (save / aw / grep / ls / mc / 00 / la / ll)
# Source: /root/Linux_Server_Public/scripts/shared_aliases.sh
# =============================================================================
source /root/Linux_Server_Public/scripts/shared_aliases.sh
