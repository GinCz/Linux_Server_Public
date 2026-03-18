#!/usr/bin/env bash
# Script:  wp_cron_setup.sh
# Version: v2026-03-18
# Purpose: Find all WP sites with DISABLE_WP_CRON=true and add system cron
#          Also adds cron for built-in WP cron sites (recommended for performance)
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
SKIPPED=0

for WPCFG in $WP_CONFIGS; do
    WPDIR=$(dirname "$WPCFG")
    DOMAIN=$(basename "$WPDIR")

    # Get domain URL from wp-config or use folder name
    SITEURL=$(grep -i "siteurl\|home" "$WPCFG" 2>/dev/null | grep "define" | grep -oP "https?://[^'\"]+" | head -1)
    if [ -z "$SITEURL" ]; then
        SITEURL="https://$DOMAIN"
    fi

    echo ""
    echo "  Site: $DOMAIN"
    echo "  URL:  $SITEURL"

    # Check if DISABLE_WP_CRON is set
    if grep -q "DISABLE_WP_CRON.*true" "$WPCFG" 2>/dev/null; then
        echo "  Mode: DISABLE_WP_CRON=true -> adding system cron"
    else
        echo "  Mode: built-in cron -> adding system cron (recommended)"
    fi

    # Add cron entry every 15 minutes
    echo "*/15 * * * * curl -s \"${SITEURL}/wp-cron.php?doing_wp_cron\" > /dev/null 2>&1" >> "$CRON_TEMP"
    ((ADDED++))
done

# Install new crontab
crontab "$CRON_TEMP"
rm -f "$CRON_TEMP"

echo ""
echo "========================================"
echo " Added $ADDED wp-cron entries to system cron"
echo " Run 'crontab -l' to verify"
echo "========================================"
