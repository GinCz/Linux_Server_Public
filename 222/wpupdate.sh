#!/bin/bash
clear
# =============================================================
# = Rooted by VladiMIR + AI | v.2026.05.07 | github.com/GinCz =
# =============================================================
# wpupdate.sh — Update WordPress core, plugins, themes for all FastPanel sites
# FastPanel path: /var/www/DOMAIN/data/
# Usage:  wpupdate  (alias) or bash /root/Linux_Server_Public/222/wpupdate.sh
# Cron:   0 3 * * 1 bash /root/Linux_Server_Public/222/wpupdate.sh >> /var/log/wpupdate.log 2>&1

DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "============================================="
echo " WordPress Update | $DATE"
echo "============================================="

# FastPanel stores sites in /var/www/DOMAIN/data/
# Search up to depth 5 to handle subdirectory installs
SITES=$(find /var/www -maxdepth 5 -name "wp-config.php" 2>/dev/null | sed 's|/wp-config.php||')

if [ -z "$SITES" ]; then
    echo "[!] No WordPress installations found."
    echo "    Searched: /var/www (depth 5)"
    echo "    Check manually: find /var/www -name wp-config.php"
    exit 1
fi

TOTAL=0
UPDATED=0
ERRORS=0

while IFS= read -r SITE_PATH; do
    SITE_NAME=$(echo "$SITE_PATH" | awk -F'/' '{print $4}')  # extract domain from path
    OWNER=$(stat -c '%U' "$SITE_PATH" 2>/dev/null || echo "www-data")

    echo ""
    echo "--- [$((TOTAL+1))] $SITE_NAME ---"
    echo "    Path : $SITE_PATH"
    echo "    Owner: $OWNER"

    TOTAL=$((TOTAL + 1))

    # Core update
    echo "  [core]"
    sudo -u "$OWNER" -- wp --path="$SITE_PATH" core update --quiet 2>&1 || \
        wp --path="$SITE_PATH" core update --allow-root --quiet 2>&1

    # Plugins update
    echo "  [plugins]"
    sudo -u "$OWNER" -- wp --path="$SITE_PATH" plugin update --all --quiet 2>&1 || \
        wp --path="$SITE_PATH" plugin update --all --allow-root --quiet 2>&1

    # Themes update
    echo "  [themes]"
    sudo -u "$OWNER" -- wp --path="$SITE_PATH" theme update --all --quiet 2>&1 || \
        wp --path="$SITE_PATH" theme update --all --allow-root --quiet 2>&1

    echo "  [OK] $SITE_NAME done"
    UPDATED=$((UPDATED + 1))

done <<< "$SITES"

echo ""
echo "============================================="
echo " Done : $UPDATED / $TOTAL sites updated"
echo " Errors: $ERRORS"
echo " Time  : $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================="
