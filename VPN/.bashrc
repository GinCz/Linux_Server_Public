# =============================================================================
# ~/.bashrc — VPN Servers (AmneziaWG)
# =============================================================================
# Version  : v2026-04-10
# Author   : Ing. VladiMIR Bulantsev
# GitHub   : https://github.com/GinCz/Linux_Server_Public
# Color    : Turquoise (38;5;87)
# Servers  : VPN-EU-Alex-47, VPN-EU-4Ton-237, VPN-EU-Tatra-9,
#            VPN-EU-Pilik-178, VPN-EU-Shahin-227, VPN-EU-Stolb-24,
#            VPN-EU-Ilya-176, VPN-EU-So-38
# =============================================================================
#
# ALIASES:
#   sos     — SOS monitoring (default 24h)
#   sos3    — SOS monitoring last 3 hours
#   sos24   — SOS monitoring last 24 hours
#   sos120  — SOS monitoring last 120 hours
#   aw      — AmneziaWG peers stats
#   audit   — security + load audit
#   infooo  — full server info
#   backup  — backup VPN configs to server 222
#   banlog  — CrowdSec ban list (last 20)
#   load    — git pull + deploy (MOTD update + cleanup)
#   save    — git push
#   00      — clear
#   la      — ls -A
#   ll      — ls -lh
#   mc      — Midnight Commander
# =============================================================================

export PS1='\[\e[38;5;87m\]\u@\h:\w\$\[\e[m\] '

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# =============================================================================
# SOS ALIASES
# =============================================================================
alias sos='bash /root/Linux_Server_Public/VPN/sos_vpn.sh 24'
alias sos3='bash /root/Linux_Server_Public/VPN/sos_vpn.sh 3'
alias sos24='bash /root/Linux_Server_Public/VPN/sos_vpn.sh 24'
alias sos120='bash /root/Linux_Server_Public/VPN/sos_vpn.sh 120'

# =============================================================================
# VPN ALIASES
# =============================================================================
alias audit='bash /root/Linux_Server_Public/VPN/vpn_node_clean_audit.sh'
alias infooo='bash /root/Linux_Server_Public/VPN/infooo.sh'
alias backup='bash /root/Linux_Server_Public/VPN/system_backup.sh'
alias banlog='cscli alerts list -l 20 2>/dev/null || echo "CrowdSec not installed"'

# load — git pull + full deploy (MOTD update + old files cleanup + .bashrc reload)
alias load='cd /root/Linux_Server_Public && git pull --rebase && bash /root/Linux_Server_Public/VPN/deploy_vpn_node.sh && source /root/.bashrc'

# =============================================================================
# SHARED ALIASES (save / aw / grep / ls / mc / 00 / la / ll)
# =============================================================================
source /root/Linux_Server_Public/scripts/shared_aliases.sh
