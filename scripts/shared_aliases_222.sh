#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  shared_aliases_222.sh | [v2026-06-10]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Shared aliases and bash functions for server 222-DE
# Servers     : 222-DE NetCup
# Usage       : bash scripts/shared_aliases_222.sh
# ==========================================================================================
REPO="/root/Linux_Server_Public/scripts"

# --- SYSTEM ---
alias 00='clear'
alias stars="bash /root/Linux_Server_Public/scripts/all_servers_stars.sh 2>/dev/null || bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/all_servers_stars.sh)"
alias infooo="/usr/local/bin/infooo.sh"
alias domains="/usr/local/bin/domains.sh"
alias cleanup="/usr/local/bin/server_cleanup.sh 2>/dev/null || echo 'server_cleanup.sh not found'"
alias banlist="/usr/local/bin/banlog.sh 2>/dev/null || echo 'banlog.sh not found'"

# --- SOS HEALTH MONITOR ---
alias sos='sos 1h'
alias sos1='sos 1h'
alias sos3='sos 3h'
alias sos24='sos 24h'
alias sos120='sos 120h'

# --- SECURITY ---
alias fight="/usr/local/bin/block_bots.sh"
alias banunblock='cscli decisions delete --ip'
alias banblock='cscli decisions add --ip'

# --- NGINX / PHP-FPM ---
alias nginx-reload='nginx -t && systemctl reload nginx'
alias fpm-reload='php-fpm8.3 -t && systemctl reload php8.3-fpm'
alias reload-all='php-fpm8.3 -t && systemctl reload php8.3-fpm && nginx -t && systemctl reload nginx'
alias watchdog="/usr/local/bin/php_fpm_watchdog.sh"

# --- WORDPRESS ---
alias wpupd="/usr/local/bin/wp_update_all.sh 2>/dev/null || echo 'wp_update_all.sh not found'"
alias wpcron="/usr/local/bin/run_all_wp_cron.sh"

# --- BACKUP & ANTIVIRUS ---
alias backup="/usr/local/bin/system_backup.sh"
alias antivir="/usr/local/bin/scan_clamav.sh"

# --- CRYPTOBOT (only 222) ---
alias bot='cd /root/cryptobot && docker compose ps'
alias bot-log='docker compose -f /root/cryptobot/docker-compose.yml logs --tail=50 -f'
alias bot-restart='docker compose -f /root/cryptobot/docker-compose.yml restart'

# --- GIT REPO & THEME ---
alias save="bash $REPO/save.sh"
alias load="bash $REPO/load.sh"
alias repo='cd /root/Linux_Server_Public'
alias style="bash /root/Linux_Server_Public/scripts/new_server_install.sh 2>/dev/null || bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh)"
alias theme='style'

# = Rooted by VladiMIR | AI = v2026-06-10 = github.com/GinCz/Linux_Server_Public
