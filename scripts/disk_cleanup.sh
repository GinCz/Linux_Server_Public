#!/usr/bin/env bash
# Script:  disk_cleanup.sh
# Version: v2026-03-18
# Purpose: Clean old logs, PHP sessions, tmp, apt cache. Safe for production.
# Usage:   /opt/server_tools/scripts/disk_cleanup.sh
# Cron:    0 3 * * 0  /opt/server_tools/scripts/disk_cleanup.sh >> /var/log/disk_cleanup.log 2>&1
# Alias:   cleanup

clear
echo "========================================"
echo " Disk Cleanup - $(hostname)"
echo " $(date '+%Y-%m-%d %H:%M')"
echo "========================================"

df_before=$(df / | awk 'NR==2{print $3}')

echo ""
echo "[1] APT cache..."
apt-get clean -y 2>/dev/null
apt-get autoremove -y 2>/dev/null
echo "    Done."

echo ""
echo "[2] Old logs (>30 days)..."
find /var/log -type f -name "*.gz" -mtime +30 -delete 2>/dev/null
find /var/log -type f -name "*.1" -mtime +7 -delete 2>/dev/null
find /var/log -type f -name "*.old" -mtime +7 -delete 2>/dev/null
journalctl --vacuum-time=14d 2>/dev/null
echo "    Done."

echo ""
echo "[3] PHP sessions (>24h)..."
SESS_DIR=$(php -r "echo ini_get('session.save_path');" 2>/dev/null || echo "/var/lib/php/sessions")
if [ -d "$SESS_DIR" ]; then
    COUNT=$(find "$SESS_DIR" -type f -mtime +1 | wc -l)
    find "$SESS_DIR" -type f -mtime +1 -delete 2>/dev/null
    echo "    Removed $COUNT session files."
fi

echo ""
echo "[4] /tmp files (>3 days)..."
COUNT=$(find /tmp -type f -mtime +3 | wc -l)
find /tmp -type f -mtime +3 -delete 2>/dev/null
echo "    Removed $COUNT tmp files."

echo ""
echo "[5] WordPress cache dirs..."
find /var/www -type d -name "cache" -path "*/wp-content/*" 2>/dev/null | while read CACHEDIR; do
    SIZE=$(du -sh "$CACHEDIR" 2>/dev/null | cut -f1)
    echo "    $CACHEDIR ($SIZE) - skipping (managed by WP)"
done
echo "    WP cache: not touched (managed by plugins)."

echo ""
echo "[6] Old FastPanel backup logs..."
find /var/log -name "fastpanel*" -mtime +14 -delete 2>/dev/null
echo "    Done."

df_after=$(df / | awk 'NR==2{print $3}')
FREED_KB=$((df_before - df_after))
FREED_MB=$((FREED_KB / 1024))

echo ""
echo "========================================"
echo " Freed: ${FREED_MB} MB"
df -h / | awk 'NR==2{print " Disk usage: used=" $3 " free=" $4 " (" $5 ")"  }'
echo "========================================"
