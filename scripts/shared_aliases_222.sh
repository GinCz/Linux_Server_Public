clear
# = Rooted by VladiMIR + AI | v.2026.05.20 | github.com/GinCz =
# shared_aliases_222.sh — aliases for 222-EU-NetCup (152.53.182.222)
# Loaded by: ~/.bashrc
# All scripts are in: ~/Linux_Server_Public/scripts/

REPO="/root/Linux_Server_Public/scripts"

# --- SYSTEM ---
alias 00='clear'
alias infooo="bash $REPO/infooo.sh"
alias domains="bash $REPO/domains.sh"
alias cleanup="bash $REPO/server_cleanup.sh 2>/dev/null || echo 'server_cleanup.sh not found'"
alias ports='ss -tlnp'
alias banlist="bash $REPO/banlog.sh 30 2>/dev/null"

# --- SOS HEALTH MONITOR ---
alias sos="bash $REPO/sos.sh 1h"
alias sos1="bash $REPO/sos.sh 1h"
alias sos3="bash $REPO/sos.sh 3h"
alias sos24="bash $REPO/sos.sh 24h"
alias sos120="bash $REPO/sos.sh 120h"

# --- SECURITY ---
alias fight="bash $REPO/block_bots.sh"
alias banunblock='cscli decisions delete --ip'
alias banblock='cscli decisions add --ip'

# --- NGINX / PHP-FPM ---
alias nginx-reload='nginx -t && systemctl reload nginx'
alias fpm-reload='php-fpm8.3 -t && systemctl reload php8.3-fpm'
alias reload-all='php-fpm8.3 -t && systemctl reload php8.3-fpm && nginx -t && systemctl reload nginx'
alias watchdog="bash $REPO/php_fpm_watchdog.sh"

# --- WORDPRESS ---
alias wpupd="bash $REPO/wp_update_all.sh 2>/dev/null || echo 'wp_update_all.sh not found'"
alias wpcron="bash $REPO/run_all_wp_cron.sh"

# --- BACKUP & ANTIVIRUS ---
alias backup="bash $REPO/system_backup.sh"
alias antivir="bash $REPO/scan_clamav.sh"

# --- CRYPTOBOT (только 222) ---
alias bot='cd /root/cryptobot && docker compose ps'
alias bot-log='docker compose -f /root/cryptobot/docker-compose.yml logs --tail=50 -f'
alias bot-restart='docker compose -f /root/cryptobot/docker-compose.yml restart'

# --- GIT REPO ---
alias save="bash $REPO/save.sh"
alias load='cd /root/Linux_Server_Public && git pull origin main && source ~/.bashrc && echo "Loaded OK"'
alias repo='cd /root/Linux_Server_Public && git pull origin main'
