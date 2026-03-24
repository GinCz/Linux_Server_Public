# ~/.bashrc — 109-ru-vds
# Version: v2026-03-25
# PS1 color: light pink (38;5;217m)
export PS1='\[\e[38;5;217m\]\u@\h:\w\$\[\e[m\] '

[ -z "$PS1" ] && return

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# --- Server-specific aliases ---
alias sos='bash /root/Linux_Server_Public/109/sos.sh 1h'
alias sos3='bash /root/Linux_Server_Public/109/sos.sh 3h'
alias sos24='bash /root/Linux_Server_Public/109/sos.sh 24h'
alias sos120='bash /root/Linux_Server_Public/109/sos.sh 120h'
alias i='bash /root/Linux_Server_Public/109/infooo.sh'
alias d='bash /root/Linux_Server_Public/109/domains.sh'
alias fight='bash /root/Linux_Server_Public/109/block_bots.sh'
alias wpcron='bash /root/Linux_Server_Public/109/run_all_wp_cron.sh'
alias cronwp='bash /root/Linux_Server_Public/109/run_all_wp_cron.sh'
alias watchdog='bash /root/Linux_Server_Public/109/php_fpm_watchdog.sh'
alias backup='bash /root/Linux_Server_Public/109/system_backup.sh'
alias antivir='bash /root/Linux_Server_Public/109/scan_clamav.sh'
alias mailclean='bash /root/Linux_Server_Public/109/mailclean.sh'
alias wphealth='bash /root/Linux_Server_Public/109/wphealth.sh'
alias cleanup='bash /root/Linux_Server_Public/109/server_cleanup.sh'
alias aws-test='bash /root/Linux_Server_Public/109/aws_test.sh'
alias banlog='cscli alerts list -l 20'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias la='ls -A'
alias l='ls -CF'
alias m='mc'
alias 00='clear'

# --- Shared aliases (load / save / aw / vpnstat) ---
source /root/Linux_Server_Public/scripts/shared_aliases.sh
