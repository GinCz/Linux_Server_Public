#!/usr/bin/env bash
# Script:  php_error_watch.sh
# Version: v2026-03-18
# Purpose: Show top PHP errors across all sites for last 24h
# Usage:   /opt/server_tools/scripts/php_error_watch.sh
# Alias:   phperr

clear
echo "========================================"
echo " PHP Error Watch - $(hostname)"
echo " Last 24 hours | $(date '+%Y-%m-%d %H:%M')"
echo "========================================"

LOG_DIRS=(
    "/var/log/php"
    "/var/log"
    "/var/www"
)

SINCE=$(date -d '24 hours ago' '+%Y-%m-%d')
TOTAL=0

echo ""
echo "--- FastPanel PHP-FPM error logs ---"

# FastPanel specific PHP logs
for LOG in /var/log/php*.log /var/log/php-fpm*.log; do
    [ -f "$LOG" ] || continue
    COUNT=$(grep -c "$SINCE" "$LOG" 2>/dev/null || echo 0)
    [ "$COUNT" -gt 0 ] && echo "  $LOG: $COUNT errors"
    TOTAL=$((TOTAL + COUNT))
done

echo ""
echo "--- Top PHP errors by type ---"
find /var/log -name "*.log" -newer /var/log/dpkg.log 2>/dev/null | while read LOG; do
    grep -h "PHP.*Error\|PHP.*Warning\|PHP.*Notice\|PHP.*Fatal" "$LOG" 2>/dev/null
done | grep -oP "PHP \w+ error" | sort | uniq -c | sort -rn | head -15

echo ""
echo "--- Top error sources (files) ---"
find /var/log -name "*.log" 2>/dev/null | while read LOG; do
    grep -h "PHP.*Error\|PHP.*Fatal" "$LOG" 2>/dev/null
done | grep -oP "in /\S+" | sort | uniq -c | sort -rn | head -10

echo ""
echo "--- WordPress debug.log files ---"
find /var/www -name "debug.log" 2>/dev/null | while read F; do
    SIZE=$(du -sh "$F" | cut -f1)
    CNT=$(wc -l < "$F")
    echo "  $F ($SIZE, $CNT lines)"
    echo "  Last 3 errors:"
    tail -3 "$F" | sed 's/^/    /'
done

echo ""
echo "========================================"
echo " Done."
echo "========================================"
