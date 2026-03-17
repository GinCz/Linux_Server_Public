#!/usr/bin/env bash

# Server Audit
# Version: v2026-03-17
#
# Purpose:
#   Generate a compact operational report for the current server over a selected
#   recent time window.
#
# Main Checks:
#   - Top websites by recent access log activity
#   - Active PHP-FPM pools by CPU usage
#   - Most requested URLs from recent access logs
#   - MySQL queries running longer than 2 seconds
#   - Recent critical errors from web server error logs
#   - CrowdSec active bans and recent alerts
#
# Usage:
#   bash /opt/server_tools/scripts/server_audit.sh
#   bash /opt/server_tools/scripts/server_audit.sh 15m
#   bash /opt/server_tools/scripts/server_audit.sh 1h
#   bash /opt/server_tools/scripts/server_audit.sh 24h
#
# Supported Time Windows:
#   15m, 30m, 1h, 3h, 6h, 12h, 24h, 120h
#
# Aliases:
#   sos
#   sos1
#   sos3
#
# Output:
#   A compact server activity report for quick diagnostics, traffic review,
#   attack visibility, and resource pressure analysis.
#
# Notes:
#   - Read-only checks only
#   - No system configuration changes
#   - Designed for FASTPANEL-style website log locations under /var/www/*/data/logs/

clear

TW="${1:-15m}"
HOST="$(hostname)"
NOW="$(date)"

case "$TW" in
  15m|30m|1h|3h|6h|12h|24h|120h) ;;
  *)
    echo "Usage: $0 {15m|30m|1h|3h|6h|12h|24h|120h}"
    exit 1
    ;;
esac

M=15
[[ "$TW" =~ ^([0-9]+)m$ ]] && M="${BASH_REMATCH[1]}"
[[ "$TW" =~ ^([0-9]+)h$ ]] && M="$(( ${BASH_REMATCH[1]} * 60 ))"

echo "============================================================"
echo "SERVER AUDIT REPORT | LAST $TW | $HOST | $NOW"
echo "============================================================"

echo -e "\nTOP-5 SITES (TRAFFIC):"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-$M" -exec wc -l {} + 2>/dev/null | sort -rn | head -n 6

echo -e "\nACTIVE PHP-FPM POOLS (CPU %):"
ps -eo user,pcpu,pmem,args --sort=-pcpu | grep php-fpm | grep -v grep | head -n 5

echo -e "\nTOP URLS (BOTS / ATTACKS / HOT PATHS):"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-$M" -exec tail -n 800 {} + 2>/dev/null \
  | awk -F'"' '{print $2}' \
  | awk '{print $2}' \
  | cut -d'?' -f1 \
  | grep -v '^$' \
  | sort | uniq -c | sort -rn | head -n 12

echo -e "\nMYSQL PROCESSES (>2s):"
if command -v mysql >/dev/null 2>&1; then
  MYSQL_OUT="$(mysql --batch --skip-column-names -e "SHOW FULL PROCESSLIST;" 2>/dev/null \
    | awk -F'\t' '$6 > 2 && $2 != "system user" {print "Time: "$6"s | DB: "$4" | Query: "$8}')"
  if [ -n "$MYSQL_OUT" ]; then
    echo "$MYSQL_OUT"
  else
    echo "No long-running MySQL queries found."
  fi
else
  echo "N/A"
fi

echo -e "\nCRITICAL ERRORS:"
ERROR_OUT="$(find /var/www/*/data/logs/ -name "*error.log" -mmin "-$M" -exec grep -iE "fatal|error|critical|Out of memory" {} + 2>/dev/null | tail -n 8)"
if [ -n "$ERROR_OUT" ]; then
  echo "$ERROR_OUT"
else
  echo "No recent critical errors found."
fi

echo -e "\nCROWDSEC STATUS:"
if command -v cscli >/dev/null 2>&1; then
  echo "Active bans: $(cscli decisions list 2>/dev/null | awk 'BEGIN{c=0} /^\|/ {c++} END{print (c>0?c-1:0)}')"
  cscli alerts list --since "$TW" -l 15 2>/dev/null
else
  echo "N/A"
fi

echo "============================================================"
