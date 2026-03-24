# ~/.bashrc — 222-DE-NetCup
# Version: v2026-03-24
# PS1 color: YELLOW

export PS1='\[\033[01;33m\]\u@\h:\w\$\[\033[00m\] '

[ -z "$PS1" ] && return

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# --- Server-specific aliases ---
alias sos='bash /root/Linux_Server_Public/222/sos.sh 1h'
alias sos3='bash /root/Linux_Server_Public/222/sos.sh 3h'
alias sos24='bash /root/Linux_Server_Public/222/sos.sh 24h'
alias sos120='bash /root/Linux_Server_Public/222/sos.sh 120h'
alias i='bash /root/Linux_Server_Public/222/infooo.sh'
alias d='bash /root/Linux_Server_Public/222/domains.sh'
alias fight='bash /root/Linux_Server_Public/222/block_bots.sh'
alias cronwp='bash /root/Linux_Server_Public/222/run_all_wp_cron.sh'
alias watchdog='bash /root/Linux_Server_Public/222/php_fpm_watchdog.sh'
alias backup='bash /root/Linux_Server_Public/222/system_backup.sh'
alias antivir='bash /root/Linux_Server_Public/222/scan_clamav.sh'
alias banlog='cscli alerts list -l 20'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias la='ls -A'
alias l='ls -CF'
alias m='mc'
alias 00='clear'

# --- Shared aliases (load / save / common) ---
source /root/Linux_Server_Public/scripts/shared_aliases.sh
