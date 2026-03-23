#!/usr/bin/env bash
# Global WP-Cron runner for Ing. VladiMIR Bulantsev | 2026
# Schedule: Every 2 hours (configured in system crontab)
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
