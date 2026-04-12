# ~/.bashrc — 109-RU-FastVDS
# Version: v2026-04-13
# PS1 color: light pink (38;5;217m)
# = Rooted by VladiMIR | AI =
#
# HOW TO EDIT:
#   1. nano /root/Linux_Server_Public/109/.bashrc   <- ПРАВИЛЬНЫЙ файл!
#   2. source /root/Linux_Server_Public/109/.bashrc (apply without re-login)
#   3. Save to repo: cd /root/Linux_Server_Public && save
#   NOTE: .bash_profile загружает ЭТОТ файл (из репо), а НЕ /root/.bashrc

export PS1='\[\e[38;5;217m\]\u@\h:\w\$\[\e[m\] '

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# --- SOS ---
alias sos='bash /root/Linux_Server_Public/109/sos.sh 1h'
alias sos1='bash /root/Linux_Server_Public/109/sos.sh 1h'
alias sos3='bash /root/Linux_Server_Public/109/sos.sh 3h'
alias sos24='bash /root/Linux_Server_Public/109/sos.sh 24h'
alias sos120='bash /root/Linux_Server_Public/109/sos.sh 120h'

# --- Quick commands ---
alias 00='clear'
alias infooo='bash /root/Linux_Server_Public/109/infooo.sh'
alias domains='bash /root/Linux_Server_Public/109/domains.sh'
alias fight='bash /root/Linux_Server_Public/109/block_bots.sh'
alias watchdog='bash /root/Linux_Server_Public/109/php_fpm_watchdog.sh'
alias backup='bash /root/Linux_Server_Public/109/system_backup.sh'
alias antivir='bash /root/Linux_Server_Public/109/scan_clamav.sh'
alias mailclean='bash /root/Linux_Server_Public/109/mailclean.sh'
alias cleanup='bash /root/Linux_Server_Public/109/server_cleanup.sh'
alias aws-test='bash /root/Linux_Server_Public/109/aws_test.sh'
alias allinfo='bash /root/Linux_Server_Public/109/all_servers_info.sh'
alias nginx-reload='nginx -t && systemctl reload nginx && echo "OK nginx reloaded"'
alias fpm-reload='php-fpm8.3 -t && systemctl reload php8.3-fpm && echo "OK php8.3-fpm reloaded"'
alias reload-all='php-fpm8.3 -t && systemctl reload php8.3-fpm && sleep 1 && nginx -t && systemctl reload nginx && echo "OK all reloaded"'

# --- CrowdSec ---
alias banlog='bash /root/Linux_Server_Public/109/banlog.sh 30'
alias banlog50='bash /root/Linux_Server_Public/109/banlog.sh 50'
alias banunblock='cscli decisions delete --ip'
alias banblock='cscli decisions add --ip'

# --- WordPress ---
alias wpupd='bash /root/Linux_Server_Public/109/wp_update_all.sh'
alias wpcron='bash /root/Linux_Server_Public/109/run_all_wp_cron.sh'
alias wphealth='bash /root/Linux_Server_Public/109/wphealth.sh'

# --- Shared aliases (load / save / aw / grep / ls / mc) ---
source /root/Linux_Server_Public/scripts/shared_aliases.sh
