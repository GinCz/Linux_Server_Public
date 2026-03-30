# =============================================================================
# ~/.bashrc — VPN Servers (AmneziaWG / WireGuard)
# =============================================================================
# Version  : v2026-03-30
# Author   : Ing. VladiMIR Bulantsev
# GitHub   : https://github.com/GinCz/Linux_Server_Public
# Color    : Turquoise (38;5;87)
# Servers  : VPN-EU-4Ton-237, VPN-EU-Tatra-9, VPN-EU-Pilik-178, ...
# =============================================================================

export PS1='\[\e[38;5;87m\]\u@\h:\w\$\[\e[m\] '

# [ -z "$PS1" ] && return  # commented out — was blocking aliases in new sessions

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# =============================================================================
# VPN SERVER ALIASES
# =============================================================================

# --- Server audit (time period) ---
alias sos='bash /root/Linux_Server_Public/VPN/vpn_server_audit.sh 1h'
alias sos3='bash /root/Linux_Server_Public/VPN/vpn_server_audit.sh 3h'
alias sos24='bash /root/Linux_Server_Public/VPN/vpn_server_audit.sh 24h'
alias sos120='bash /root/Linux_Server_Public/VPN/vpn_server_audit.sh 120h'

# --- Server info & monitoring ---
alias infooo='bash /root/Linux_Server_Public/VPN/infooo.sh'
alias backup='bash /root/Linux_Server_Public/VPN/system_backup.sh'
alias banlog='cscli alerts list -l 20 2>/dev/null || echo "CrowdSec not installed"'
alias 00='clear'

# =============================================================================
# SHARED ALIASES (load / save / aw / grep / ls / mc)
# =============================================================================
source /root/Linux_Server_Public/scripts/shared_aliases.sh
