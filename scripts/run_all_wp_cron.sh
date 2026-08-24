#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  run_all_wp_cron.sh | [v2026-08-24]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Smooth, throttled WP-Cron executor (low CPU & I/O priority + pause)
# Servers     : 222-DE / 109-RU Web Nodes
# Usage       : bash /usr/local/bin/run_all_wp_cron.sh
# ==========================================================================================

LOCKFILE="/var/run/run_all_wp_cron.lock"
exec 200>"$LOCKFILE"
flock -n 200 || { echo "[$(date '+%Y-%m-%d %H:%M:%S')] Another WP-Cron batch is already running. Exiting."; exit 0; }

echo "======================================================================"
echo ">>> Processing WordPress Crons (Smooth Mode): $(date '+%Y-%m-%d %H:%M:%S')"
echo "======================================================================"

# Find all WP installations in FastPanel structure
find /var/www/*/data/www/* -maxdepth 2 -name "wp-cron.php" 2>/dev/null | sort | while read -r cron_path; do
    [ -f "$cron_path" ] || continue
    DOMAIN=$(echo "$cron_path" | awk -F/ '{print $7}')
    SITE_USER=$(stat -c '%U' "$cron_path" 2>/dev/null || echo "www-data")

    echo "[$(date '+%H:%M:%S')] Running WP-Cron for: $DOMAIN (User: $SITE_USER)"
    
    # Run via PHP-CLI with lowest CPU (nice 19) and lowest I/O (ionice 3 - idle)
    # Hard timeout 30s per site to prevent stuck hooks from hanging the queue
    if id "$SITE_USER" &>/dev/null && [ "$SITE_USER" != "root" ]; then
        nice -n 19 ionice -c 3 timeout 30s sudo -u "$SITE_USER" php "$cron_path" > /dev/null 2>&1
    else
        nice -n 19 ionice -c 3 timeout 30s php "$cron_path" > /dev/null 2>&1
    fi

    # Gentle pause to let disk I/O and CPU relax between sites
    sleep 3
done

echo "======================================================================"
echo ">>> All WP-Cron tasks finished: $(date '+%Y-%m-%d %H:%M:%S')"
echo "======================================================================"

# = Rooted by VladiMIR | AI = v2026-08-24 = github.com/GinCz/Linux_Server_Public
