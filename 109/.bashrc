# ~/.bashrc — 109-ru-vds
# Version: v2026-04-02
# PS1 color: light pink (38;5;217m)
# = Rooted by VladiMIR | AI =

export PS1='\[\e[38;5;217m\]\u@\h:\w\$\[\e[m\] '

# [ -z "$PS1" ] && return  # commented out — was blocking aliases in new sessions

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# --- Quick commands ---
alias 00='clear'
alias infooo='bash /root/Linux_Server_Public/109/infooo.sh'
alias domains='bash /root/Linux_Server_Public/109/domains.sh'
alias sos='bash /root/Linux_Server_Public/109/sos.sh 1h'
alias sos3='bash /root/Linux_Server_Public/109/sos.sh 3h'
alias sos24='bash /root/Linux_Server_Public/109/sos.sh 24h'
alias sos120='bash /root/Linux_Server_Public/109/sos.sh 120h'
alias fight='bash /root/Linux_Server_Public/109/block_bots.sh'
alias watchdog='bash /root/Linux_Server_Public/109/php_fpm_watchdog.sh'
alias backup='bash /root/Linux_Server_Public/109/system_backup.sh'
alias antivir='bash /root/Linux_Server_Public/109/scan_clamav.sh'
alias mailclean='bash /root/Linux_Server_Public/109/mailclean.sh'
alias cleanup='bash /root/Linux_Server_Public/109/server_cleanup.sh'
alias aws-test='bash /root/Linux_Server_Public/109/aws_test.sh'
alias banlog='cscli alerts list -l 20'

# --- ALL servers RAM & Disk overview (run from server-109) ---
alias allinfo='bash /root/Linux_Server_Public/109/all_servers_info.sh'

# --- Shared aliases (load / save / aw / grep / ls / mc) ---
source /root/Linux_Server_Public/scripts/shared_aliases.sh
