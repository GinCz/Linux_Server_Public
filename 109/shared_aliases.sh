#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  shared_aliases.sh | [v2026-08-15]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Shared aliases and bash environment shortcuts for server 109-RU
# Servers     : 109-RU FastVDS (212.109.223.109)
# Usage       : source 109/shared_aliases.sh
# ==========================================================================================

REPO="/root/Linux_Server_Public/scripts"

# --- SYSTEM ---
alias 00='clear'
alias infooo="bash $REPO/infooo.sh"
alias qs="bash $REPO/quick_status.sh"
alias domains="bash $REPO/domains.sh"
alias cleanup="bash $REPO/server_cleanup.sh"
alias ports='ss -tlnp'
alias banlist="bash $REPO/banlog.sh 30"
alias banlog="bash $REPO/banlog.sh 30"

# --- SOS HEALTH MONITOR ---
alias sos="/usr/local/bin/sos 1h"
alias sos1="/usr/local/bin/sos 1h"
alias sos3="/usr/local/bin/sos 3h"
alias sos24="/usr/local/bin/sos 24h"
alias sos120="/usr/local/bin/sos 120h"

# --- SECURITY ---
alias fight="bash $REPO/block_bots.sh"
alias banunblock='cscli decisions delete --ip'
alias banblock='cscli decisions add --ip'

# --- NGINX / PHP-FPM ---
alias nginx-reload='nginx -t && systemctl reload nginx'
alias fpm-reload='systemctl reload php8.3-fpm 2>/dev/null || systemctl reload php8.1-fpm 2>/dev/null'
alias reload-all='nginx -t && systemctl reload nginx && systemctl restart php*-fpm 2>/dev/null'
alias watchdog="bash $REPO/php_fpm_watchdog.sh"

# --- WORDPRESS ---
alias wpupd="bash $REPO/wp_update_all.sh"
alias wpcron="bash $REPO/run_all_wp_cron.sh"

# --- ANTIVIRUS ---
alias antivir="bash $REPO/scan_clamav.sh"

# --- MAIL ---
alias mailclean="bash $REPO/mailclean.sh"

# --- GIT REPO & THEME ---
alias save="bash $REPO/save.sh"
alias load="bash $REPO/load.sh"
alias repo='cd /root/Linux_Server_Public'
alias style="bash /root/Linux_Server_Public/scripts/new_server_install.sh 2>/dev/null || bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh)"
alias theme='style'

# = Rooted by VladiMIR | AI = v2026-08-15 = github.com/GinCz/Linux_Server_Public
