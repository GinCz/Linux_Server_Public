clear
# = Rooted by VladiMIR + AI | v.2026.05.20 | github.com/GinCz =
# shared_aliases_109.sh — aliases for 109-RU-FastVDS (212.109.223.109)
# Loaded by: ~/Linux_Server_Public/109/.bashrc
# Docs: 109/ALIASES.md

REPO="/root/Linux_Server_Public"

# --- SYSTEM ---
alias 00='clear'
alias infooo="bash $REPO/109/infooo.sh 2>/dev/null || bash /root/infooo.sh"
alias domains="bash $REPO/109/domains.sh"
alias cleanup="bash $REPO/109/server_cleanup.sh"
alias allinfo="bash $REPO/109/all_servers_info.sh"
alias ports='ss -tlnp'

# --- SOS HEALTH MONITOR ---
alias sos="bash $REPO/109/sos.sh 1h"
alias sos1="bash $REPO/109/sos.sh 1h"
alias sos3="bash $REPO/109/sos.sh 3h"
alias sos24="bash $REPO/109/sos.sh 24h"
alias sos120="bash $REPO/109/sos.sh 120h"

# --- SECURITY ---
alias fight="bash $REPO/109/block_bots.sh"
alias banlog="bash $REPO/109/banlog.sh 30"
alias banlog50="bash $REPO/109/banlog.sh 50"
alias banlist="bash $REPO/109/banlog.sh 30"
alias banunblock='cscli decisions delete --ip'
alias banblock='cscli decisions add --ip'

# --- NGINX / PHP-FPM ---
alias nginx-reload='nginx -t && systemctl reload nginx'
alias fpm-reload='php-fpm8.3 -t && systemctl reload php8.3-fpm'
alias reload-all='php-fpm8.3 -t && systemctl reload php8.3-fpm && nginx -t && systemctl reload nginx'
alias watchdog="bash $REPO/109/php_fpm_watchdog.sh"

# --- WORDPRESS ---
alias wpupd="bash $REPO/109/wp_update_all.sh"
alias wpcron="bash $REPO/109/run_all_wp_cron.sh"
alias wphealth="bash $REPO/109/wphealth.sh"

# --- BACKUP & ANTIVIRUS ---
alias backup="bash $REPO/109/system_backup.sh"
alias antivir="bash $REPO/109/scan_clamav.sh"
alias aws-test="bash $REPO/109/aws_test.sh"

# --- MAIL ---
alias mailclean="bash $REPO/109/mailclean.sh"

# --- GIT REPO ---
alias repo='cd /root/Linux_Server_Public && git pull origin main'
alias secret='cd ~/Secret_Privat && git pull'
alias save="bash $REPO/109/save.sh"
alias load='cd /root/Linux_Server_Public && git pull origin main && source ~/.bashrc'
