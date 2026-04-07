# ~/.bashrc — 109-RU-FastVDS
# Version: v2026-04-08
# PS1 color: light pink (38;5;217m)
# = Rooted by VladiMIR | AI =
#
# SOURCE OF TRUTH: https://github.com/GinCz/Linux_Server_Public/blob/main/109/.bashrc
# To restore: curl -sS https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/109/.bashrc > ~/.bashrc && source ~/.bashrc
#
# HOW TO EDIT ALIASES:
#   1. nano /root/.bashrc
#   2. Add/remove alias lines below
#   3. source /root/.bashrc     (apply without re-login)
#   4. Also update MOTD: nano /etc/profile.d/motd_server.sh
#   5. Save to repo: cd /root/Linux_Server_Public && cp /root/.bashrc 109/.bashrc && save
#
# HOW TO EDIT MOTD MENU (login banner):
#   File on server : /etc/profile.d/motd_server.sh
#   File in repo   : 109/motd_server.sh
#   After editing  : bash /etc/profile.d/motd_server.sh   (test instantly)
#   Save to repo   : cp /etc/profile.d/motd_server.sh 109/motd_server.sh && save

export PS1='\[\e[38;5;217m\]\u@\h:\w\$\[\e[m\] '

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

# =============================================================
# CROWDSEC
# =============================================================
alias banlog='bash /root/Linux_Server_Public/109/banlog.sh 30'
alias banlog50='bash /root/Linux_Server_Public/109/banlog.sh 50'
alias banunblock='cscli decisions delete --ip'
alias banblock='cscli decisions add --ip'

# =============================================================
# WORDPRESS
# =============================================================
alias wpupd='bash /root/Linux_Server_Public/109/wp_update_all.sh'
alias wpcron='bash /root/Linux_Server_Public/109/run_all_wp_cron.sh'
alias wphealth='bash /root/Linux_Server_Public/109/wphealth.sh'

# =============================================================
# NGINX & PHP-FPM — RELOAD (zero downtime)
# WARNING: NEVER use restart — it kills ALL sockets -> 502 on ALL sites
# =============================================================
alias nginx-reload='nginx -t && systemctl reload nginx && echo "OK nginx reloaded"'
alias fpm-reload='php-fpm8.3 -t && systemctl reload php8.3-fpm && echo "OK php8.3-fpm reloaded"'
alias reload-all='php-fpm8.3 -t && systemctl reload php8.3-fpm && sleep 1 && nginx -t && systemctl reload nginx && echo "OK php-fpm + nginx reloaded — zero downtime"'

# =============================================================
# REPO
# =============================================================
alias repo='cd /root/Linux_Server_Public && git pull && source /root/.bashrc && echo "=== Public repo loaded ==="'
alias secret='cd ~/Secret_Privat && git pull && ls -la'

# =============================================================
# ALL SERVERS INFO
# =============================================================
alias allinfo='bash /root/Linux_Server_Public/109/all_servers_info.sh'

# =============================================================
# SHARED ALIASES (load / save / aw / grep / ls / mc)
# =============================================================
source /root/Linux_Server_Public/scripts/shared_aliases.sh
