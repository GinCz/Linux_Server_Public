#!/usr/bin/env bash
# =============================================================================
# run_all_wp_cron.sh — Run WP-Cron for all WordPress sites via PHP-CLI
# Version     : v2026-04-30
# Server      : 222-DE-NetCup (152.53.182.222)
# Usage       : wpcron  (alias) or bash /root/Linux_Server_Public/222/run_all_wp_cron.sh
# NOTE        : Runs via PHP-CLI, bypasses Cloudflare and web-server limits.
#               Works with PHP 8.4+.
# = Rooted by VladiMIR | AI =
# =============================================================================
clear

echo "=== WordPress Cron Runner: $(date) ==="
echo

COUNT=0
find /var/www/*/data/www/* -name "wp-cron.php" 2>/dev/null | while read cron_path; do
    DOMAIN=$(echo "$cron_path" | awk -F/ '{print $7}')
    echo "  ► Running cron: $DOMAIN"
    php "$cron_path" > /dev/null 2>&1
done

echo
echo "=== All WP cron jobs triggered: $(date) ==="
