#!/bin/bash
clear
# =============================================================
# = Rooted by VladiMIR + AI | v.2026.05.07 | github.com/GinCz =
# =============================================================
# wpupdate.sh — Update WordPress core, plugins, themes for ALL FastPanel sites
# FastPanel path structure: /var/www/USER/data/www/DOMAIN/
# Alias: wpupdate
# Cron:  0 3 * * 1 bash /root/Linux_Server_Public/222/wpupdate.sh >> /var/log/wpupdate.log 2>&1

DATE=$(date '+%Y-%m-%d %H:%M:%S')
TOTAL=0
UPDATED=0

echo "============================================="
echo " WordPress Update | $DATE"
echo "============================================="

# FastPanel: /var/www/USER/data/www/DOMAIN/wp-config.php
SITES=$(find /var/www -maxdepth 6 -name "wp-config.php" 2>/dev/null | sed 's|/wp-config.php||')

if [ -z "$SITES" ]; then
    echo "[!] No WordPress installations found in /var/www"
    exit 1
fi

while IFS= read -r SITE_PATH; do
    DOMAIN=$(basename "$SITE_PATH")
    OWNER=$(stat -c '%U' "$SITE_PATH" 2>/dev/null || echo "www-data")
    TOTAL=$((TOTAL + 1))

    echo ""
    echo "--- [$TOTAL] $DOMAIN"
    echo "    path : $SITE_PATH"
    echo "    owner: $OWNER"

    echo -n "  core    : "
    sudo -u "$OWNER" -- wp --path="$SITE_PATH" core update 2>&1 | tail -1

    echo -n "  plugins : "
    sudo -u "$OWNER" -- wp --path="$SITE_PATH" plugin update --all 2>&1 | tail -1

    echo -n "  themes  : "
    sudo -u "$OWNER" -- wp --path="$SITE_PATH" theme update --all 2>&1 | tail -1

    UPDATED=$((UPDATED + 1))
done <<< "$SITES"

echo ""
echo "============================================="
echo " Done : $UPDATED / $TOTAL sites"
echo " Time : $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================="
