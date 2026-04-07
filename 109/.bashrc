# ~/.bashrc — 109-ru-vds
# Version: v2026-04-07
# PS1 color: light pink (38;5;217m)
# = Rooted by VladiMIR | AI =
#
# SOURCE OF TRUTH: https://github.com/GinCz/Linux_Server_Public/blob/main/109/.bashrc
# To restore: curl -sS https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/109/.bashrc > ~/.bashrc && source ~/.bashrc

export PS1='\[\e[38;5;217m\]\u@\h:\w\$\[\e[m\] '

# [ -z "$PS1" ] && return  # commented out — was blocking aliases in new sessions

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# =============================================================
# QUICK COMMANDS
# =============================================================
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

# =============================================================
# WORDPRESS
# =============================================================

# Run WordPress plugin/theme update on all sites
alias wpupd='bash /root/Linux_Server_Public/109/wp_update_all.sh'

# Run WordPress system cron manually (replaces wp-cron.php)
alias wpcron='bash /root/Linux_Server_Public/109/run_all_wp_cron.sh'

# WordPress health check (status of all WP sites)
alias wphealth='bash /root/Linux_Server_Public/109/wphealth.sh'

# =============================================================
# NGINX & PHP-FPM — RELOAD (zero downtime)
# WARNING: NEVER use restart — it kills ALL sockets → 502 on ALL sites
# Full explanation: /root/Linux_Server_Public/OPERATIONS.md
# =============================================================

# Test nginx config and reload (zero downtime)
alias nginx-reload='nginx -t && systemctl reload nginx && echo "✅ nginx reloaded"'

# Test php-fpm config and reload (zero downtime)
alias fpm-reload='php-fpm8.3 -t && systemctl reload php8.3-fpm && echo "✅ php8.3-fpm reloaded"'

# Both at once: reload php-fpm then nginx
alias reload-all='php-fpm8.3 -t && systemctl reload php8.3-fpm && sleep 1 && nginx -t && systemctl reload nginx && echo "✅ php-fpm + nginx reloaded — zero downtime"'

# CrowdSec bans log
alias banlog='cscli alerts list -l 20'

# =============================================================
# REPO
# =============================================================

# Pull latest from public repo
alias repo='cd /root/Linux_Server_Public && git pull && echo "✅ repo updated"'

# Go to private repo
alias secret='cd ~/Secret_Privat && git pull && ls -la'

# =============================================================
# ALL SERVERS RAM & DISK OVERVIEW (run from server-109)
# =============================================================
alias allinfo='bash /root/Linux_Server_Public/109/all_servers_info.sh'

# =============================================================
# SHARED ALIASES (load / save / aw / grep / ls / mc)
# =============================================================
source /root/Linux_Server_Public/scripts/shared_aliases.sh
