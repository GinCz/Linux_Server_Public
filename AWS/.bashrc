# ~/.bashrc — AWS Amazon Server
# Version: v2026-03-24
# PS1 color: light blue (38;5;117m)
export PS1='\[\e[38;5;117m\]\u@\h:\w\$\[\e[m\] '

[ -z "$PS1" ] && return

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

alias 00='clear'
alias m='mc'
alias infooo='bash /root/Linux_Server_Public/AWS/infooo.sh'
alias save='bash /root/Linux_Server_Public/AWS/save.sh'
alias sos='bash /root/Linux_Server_Public/AWS/vpn_server_audit.sh 1h'
alias sos15='bash /root/Linux_Server_Public/AWS/vpn_server_audit.sh 15m'
alias sos3='bash /root/Linux_Server_Public/AWS/vpn_server_audit.sh 3h'
alias sos24='bash /root/Linux_Server_Public/AWS/vpn_server_audit.sh 24h'
alias backup='bash /root/Linux_Server_Public/AWS/system_backup.sh'
alias awsping='bash /root/Linux_Server_Public/AWS/aws_ping.sh'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias la='ls -A'
alias l='ls -CF'

source /root/Linux_Server_Public/scripts/shared_aliases.sh
