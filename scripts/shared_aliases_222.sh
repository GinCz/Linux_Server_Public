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
alias infooo="bash $REPO/infooo.sh"
alias domains="bash $REPO/domains.sh"
alias cleanup="bash $REPO/server_cleanup.sh 2>/dev/null || echo 'server_cleanup.sh not found'"
alias banlist="bash $REPO/banlog.sh 30 2>/dev/null || echo 'banlog.sh not found'"

# --- SOS HEALTH MONITOR ---
alias sos='sos 1h'
alias sos1='sos 1h'
alias sos3='sos 3h'
alias sos24='sos 24h'
alias sos120='sos 120h'

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
alias backup="bash /root/Linux_Server_Public/222/backup_all_servers.sh"
alias antivir="bash $REPO/scan_clamav.sh"

# --- CRYPTOBOT (only 222) ---
alias bot='cd /root/cryptobot && docker compose ps'
alias bot-log='docker compose -f /root/cryptobot/docker-compose.yml logs --tail=50 -f'
alias bot-restart='docker compose -f /root/cryptobot/docker-compose.yml restart'

# --- GIT REPO ---
alias save="bash $REPO/save.sh"
alias load="bash $REPO/load.sh"
alias repo='cd /root/Linux_Server_Public'

# = Rooted by VladiMIR | AI = v2026-06-10 = github.com/GinCz/Linux_Server_Public
