# 222-EU Server Colors: YELLOW theme
export PS1="\[\033[01;33m\]\u@\h:\w\[\033[00m\]\$ "

# Source shared aliases + local
source /root/Linux_Server_Public/222/shared_aliases.sh
source /root/Linux_Server_Public/scripts/shared_aliases.sh

# Local server-specific aliases
alias infooo="cd /root/Linux_Server_Public/222 && ./infooo.sh"
alias save="cd /root/Linux_Server_Public/222 && git add -A && git commit -m 'Update 222: $(date +%Y-%m-%d)' && git push origin main && cd -"
alias mc="mc -S /root/Linux_Server_Public/222/mc.menu"
alias audit="cd /root/Linux_Server_Public/222 && ./server_audit.sh"
alias cronwp="cd /root/Linux_Server_Public/222 && ./run_all_wp_cron.sh"
alias watchdog="cd /root/Linux_Server_Public/222 && ./php_fpm_watchdog.sh"
alias blockbots="cd /root/Linux_Server_Public/222 && ./block_bots.sh"
