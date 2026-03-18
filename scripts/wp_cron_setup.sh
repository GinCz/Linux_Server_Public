#!/usr/bin/env bash
# Script:  wp_cron_setup.sh
# Version: v2026-03-18
# Purpose: Find all WP sites and add system cron once daily at 23:00
# Usage:   /opt/server_tools/scripts/wp_cron_setup.sh
# Alias:   wpcron

clear
echo "========================================"
echo " WP Cron Setup - $(hostname)"
echo " $(date '+%Y-%m-%d %H:%M')"
echo "========================================"

WP_CONFIGS=$(find /var/www -maxdepth 6 -name "wp-config.php" 2>/dev/null)

if [ -z "$WP_CONFIGS" ]; then
    echo "No WordPress installations found."
    exit 0
fi

# Collect current crontab without wp-cron lines
CRON_TEMP=$(mktemp)
crontab -l 2>/dev/null | grep -v "wp-cron.php" > "$CRON_TEMP"

ADDED=0

for WPCFG in $WP_CONFIGS; do
    WPDIR=$(dirname "$WPCFG")
    DOMAIN=$(basename "$WPDIR")

    # Get domain URL from wp-config
    SITEURL=$(grep -i "siteurl\|home" "$WPCFG" 2>/dev/null | grep "define" | grep -oP "https?://[^'\"]+" | head -1)
    if [ -z "$SITEURL" ]; then
        SITEURL="https://$DOMAIN"
    fi

    # Force https
    SITEURL=$(echo "$SITEURL" | sed 's|^http://|https://|')

    echo "  + $DOMAIN -> $SITEURL"

    # Add cron entry once daily at 23:00
    echo "0 23 * * * curl -s \"${SITEURL}/wp-cron.php?doing_wp_cron\" > /dev/null 2>&1" >> "$CRON_TEMP"
    ((ADDED++))
done

# Install new crontab
crontab "$CRON_TEMP"
rm -f "$CRON_TEMP"

echo ""
echo "========================================"
echo " Added $ADDED wp-cron entries (daily at 23:00)"
echo " Run 'crontab -l | grep wp-cron' to verify"
echo "========================================"
