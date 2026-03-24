# 222-EU Server Colors: YELLOW theme
# Version: v2026-03-24
# PS1 color: yellow only (033[01;33m)
export PS1="\[\033[01;33m\]\u@\h:\w\[\033[00m\]\$ "

# Source shared aliases
source /root/Linux_Server_Public/scripts/shared_aliases.sh

# Local server-specific aliases
alias 00='clear'
alias m='mc'
alias infooo='bash /root/Linux_Server_Public/222/infooo.sh'
alias save='bash /root/Linux_Server_Public/222/save.sh'
alias sos='bash /root/Linux_Server_Public/222/sos.sh 1h'
alias sos15='bash /root/Linux_Server_Public/222/sos.sh 15m'
alias sos3='bash /root/Linux_Server_Public/222/sos.sh 3h'
alias sos6='bash /root/Linux_Server_Public/222/sos.sh 6h'
alias sos24='bash /root/Linux_Server_Public/222/sos.sh 24h'
alias sos120='bash /root/Linux_Server_Public/222/sos.sh 120h'
alias cronwp='bash /root/Linux_Server_Public/222/run_all_wp_cron.sh'
alias watchdog='bash /root/Linux_Server_Public/222/php_fpm_watchdog.sh'
alias blockbots='bash /root/Linux_Server_Public/222/block_bots.sh'
alias domains='bash /root/Linux_Server_Public/222/domains.sh'
alias backup='bash /root/Linux_Server_Public/222/system_backup.sh'
alias mc='mc -S /root/Linux_Server_Public/222/mc.menu'
