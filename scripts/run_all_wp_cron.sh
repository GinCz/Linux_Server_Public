#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  run_all_wp_cron.sh | [v2026-08-15]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Execute WP-CLI cron jobs for all virtual hosts
# Servers     : 222-DE / 109-RU Web Nodes
# Usage       : bash scripts/run_all_wp_cron.sh
# ==========================================================================================
echo ">>> Processing WordPress Crons: $(date)"

# Finding all WP installations in FastPanel structure
find /var/www/*/data/www/* -name "wp-cron.php" | while read cron_path; do
    DOMAIN=$(echo "$cron_path" | awk -F/ '{print $7}')
    echo "Running for: $DOMAIN"
    
    # Run via PHP-CLI (Bypasses web-server limits and Cloudflare blocks)
    # This ensures updates work even on PHP 8.4
    php "$cron_path" > /dev/null 2>&1
done
echo ">>> All tasks triggered: $(date)"

# = Rooted by VladiMIR | AI = v2026-08-15 = github.com/GinCz/Linux_Server_Public
