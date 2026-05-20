#!/usr/bin/env bash
# =============================================================
# File:        shared_aliases_109.sh
# Version:     v2026.05.21
# Location:    scripts/shared_aliases_109.sh
# Server:      109-RU-FastVDS (212.109.223.109)
# Description: Aliases for ~/.bashrc on server 109.
#              Loaded via: source ~/Linux_Server_Public/scripts/shared_aliases_109.sh
# = Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =
# =============================================================

REPO="/root/Linux_Server_Public/scripts"

# --- SYSTEM ---
alias 00='clear'
alias infooo="bash $REPO/infooo.sh"
alias domains="bash $REPO/domains.sh"
alias cleanup="bash $REPO/server_cleanup.sh 2>/dev/null || echo 'server_cleanup.sh not found'"
alias ports='ss -tlnp'
alias banlist="bash $REPO/banlog.sh 30 2>/dev/null || echo 'banlog.sh not found'"

# --- SOS HEALTH MONITOR ---
alias sos="bash $REPO/sos-fastpanel.sh 1h"
alias sos1="bash $REPO/sos-fastpanel.sh 1h"
alias sos3="bash $REPO/sos-fastpanel.sh 3h"
alias sos24="bash $REPO/sos-fastpanel.sh 24h"
alias sos120="bash $REPO/sos-fastpanel.sh 120h"

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
alias antivir="bash $REPO/scan_clamav.sh"

# --- MAIL ---
alias mailclean="bash $REPO/mailclean.sh 2>/dev/null || echo 'mailclean.sh not found'"

# --- GIT REPO ---
alias save="bash $REPO/save.sh"
alias load="bash $REPO/load.sh"
alias repo='cd /root/Linux_Server_Public'
