#!/usr/bin/env bash
# Script:  wp_health.sh
# Version: v2026-03-18
# Purpose: Check health of all WordPress sites on the server (FastPanel structure)
# FastPanel path: /var/www/USER/data/www/DOMAIN/wp-config.php
# Usage:   /opt/server_tools/scripts/wp_health.sh
# Alias:   wphealth

clear
echo "========================================"
echo " WordPress Health Check - $(hostname)"
echo " $(date '+%Y-%m-%d %H:%M')"
echo "========================================"

WP_DIRS=$(find /var/www -maxdepth 6 -name "wp-config.php" 2>/dev/null | sed 's|/wp-config.php||')

if [ -z "$WP_DIRS" ]; then
    echo "No WordPress installations found."
    exit 0
fi

TOTAL=0
WARN=0

for WPDIR in $WP_DIRS; do
    DOMAIN=$(basename "$WPDIR")
    echo ""
    echo "--- $DOMAIN ---"

    # WordPress version
    WP_VER=$(grep -r '\$wp_version' "$WPDIR/wp-includes/version.php" 2>/dev/null | grep -oP "'\K[0-9.]+")
    [ -n "$WP_VER" ] && echo "  WP version:  $WP_VER"

    # DB name and size
    DB_NAME=$(grep "DB_NAME" "$WPDIR/wp-config.php" 2>/dev/null | grep -oP "'\K[^']+" | head -1)
    if [ -n "$DB_NAME" ]; then
        DB_SIZE=$(mysql -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) FROM information_schema.tables WHERE table_schema='$DB_NAME';" 2>/dev/null | tail -1)
        echo "  DB:          $DB_NAME (${DB_SIZE} MB)"
    fi

    # Dir size
    DIR_SIZE=$(du -sh "$WPDIR" 2>/dev/null | cut -f1)
    echo "  Dir size:    $DIR_SIZE"

    # Uploads size
    UPL_SIZE=$(du -sh "$WPDIR/wp-content/uploads" 2>/dev/null | cut -f1)
    [ -n "$UPL_SIZE" ] && echo "  Uploads:     $UPL_SIZE"

    # WP Cron
    if grep -q "DISABLE_WP_CRON.*true" "$WPDIR/wp-config.php" 2>/dev/null; then
        echo "  WP Cron:     disabled (external cron OK)"
    else
        echo "  WP Cron:     built-in"
    fi

    # Debug mode
    if grep -q "WP_DEBUG.*true" "$WPDIR/wp-config.php" 2>/dev/null; then
        echo "  DEBUG:       ON - disable on production!"
        ((WARN++))
    fi

    # Debug log
    ERR_LOG="$WPDIR/wp-content/debug.log"
    if [ -f "$ERR_LOG" ]; then
        LOG_SIZE=$(du -sh "$ERR_LOG" 2>/dev/null | cut -f1)
        echo "  debug.log:   $LOG_SIZE"
        ((WARN++))
    fi

    ((TOTAL++))
done

echo ""
echo "========================================"
echo " Total: $TOTAL sites  |  Warnings: $WARN"
echo "========================================"
