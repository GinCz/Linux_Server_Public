#!/bin/bash
clear
# =============================================================
# = Rooted by VladiMIR + AI | v.2026.05.07 | github.com/GinCz =
# =============================================================
# wpupdate.sh — Update WordPress core, plugins, themes for all sites
# Usage: ./wpupdate.sh
# Cron example: 0 3 * * 1 /root/wpupdate.sh >> /var/log/wpupdate.log 2>&1

WP_ROOT="/var/www"
LOG_FILE="/var/log/wpupdate.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "============================================="
echo " WordPress Update | $DATE"
echo "============================================="

# Find all WordPress installations by wp-config.php
SITES=$(find "$WP_ROOT" -maxdepth 4 -name "wp-config.php" 2>/dev/null | sed 's|/wp-config.php||')

if [ -z "$SITES" ]; then
    echo "[!] No WordPress installations found in $WP_ROOT"
    exit 1
fi

TOTAL=0
UPDATED=0

for SITE_PATH in $SITES; do
    SITE_NAME=$(basename "$SITE_PATH")
    OWNER=$(stat -c '%U' "$SITE_PATH")

    echo ""
    echo "---------------------------------------------"
    echo "[>] Site: $SITE_NAME | Path: $SITE_PATH | User: $OWNER"
    echo "---------------------------------------------"

    TOTAL=$((TOTAL + 1))

    # Run wp-cli as the site owner to avoid permission issues
    sudo -u "$OWNER" -- wp --path="$SITE_PATH" core update --allow-root 2>&1
    sudo -u "$OWNER" -- wp --path="$SITE_PATH" plugin update --all --allow-root 2>&1
    sudo -u "$OWNER" -- wp --path="$SITE_PATH" theme update --all --allow-root 2>&1

    UPDATED=$((UPDATED + 1))
done

echo ""
echo "============================================="
echo " Done: $UPDATED / $TOTAL sites processed"
echo " Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================="
