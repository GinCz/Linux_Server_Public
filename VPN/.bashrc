# ~/.bashrc — VPN Servers (AmneziaWG)
# Version: v2026-03-24
# PS1 color: Turquoise

export PS1='\[\e[38;5;87m\]\u@\h:\w\$\[\e[m\] '

[ -z "$PS1" ] && return

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# --- VPN server-specific aliases ---
alias sos='bash /root/Linux_Server_Public/VPN/vpn_server_audit.sh 1h'
alias sos3='bash /root/Linux_Server_Public/VPN/vpn_server_audit.sh 3h'
alias sos24='bash /root/Linux_Server_Public/VPN/vpn_server_audit.sh 24h'
alias sos120='bash /root/Linux_Server_Public/VPN/vpn_server_audit.sh 120h'
alias infooo='bash /root/Linux_Server_Public/VPN/infooo.sh'
alias backup='bash /root/Linux_Server_Public/VPN/system_backup.sh'
alias banlog='cscli alerts list -l 20 2>/dev/null || echo "CrowdSec not installed"'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias la='ls -A'
alias l='ls -CF'
alias m='mc'
alias 00='clear'

# --- Shared aliases (load / save / aw) ---
source /root/Linux_Server_Public/scripts/shared_aliases.sh
