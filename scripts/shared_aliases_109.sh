#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  shared_aliases_109.sh | [v2026-05-21]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Shared aliases and bash functions for server 109-RU
# Servers     : 109-RU FastVDS
# Usage       : bash scripts/shared_aliases_109.sh
# ==========================================================================================
REPO="/root/Linux_Server_Public/scripts"

# --- SYSTEM ---
alias 00='clear'
alias infooo="/usr/local/bin/infooo.sh"
alias domains="/usr/local/bin/domains.sh"
alias cleanup="/usr/local/bin/server_cleanup.sh 2>/dev/null || echo 'server_cleanup.sh not found'"
alias ports='ss -tlnp'
alias banlist="/usr/local/bin/banlog.sh 2>/dev/null || echo 'banlog.sh not found'"

# --- SOS HEALTH MONITOR ---
alias sos="/usr/local/bin/sos"
alias sos1="/usr/local/bin/sos"
alias sos3="/usr/local/bin/sos"
alias sos24="/usr/local/bin/sos"
alias sos120="/usr/local/bin/sos"

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
alias antivir="/usr/local/bin/scan_clamav.sh"

# --- MAIL ---
alias mailclean="/usr/local/bin/mailclean.sh 2>/dev/null || echo 'mailclean.sh not found'"

# --- GIT REPO ---
alias save="bash $REPO/save.sh"
alias load="bash $REPO/load.sh"
alias repo='cd /root/Linux_Server_Public'

# = Rooted by VladiMIR | AI = v2026-05-21 = github.com/GinCz/Linux_Server_Public
