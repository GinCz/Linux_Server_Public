#!/usr/bin/env bash
# Description: Web Server Stress Analyzer (SOS)
clear; TW="${1:-15m}"; HOST="$(hostname)"; NOW="$(date)"
case "$TW" in 15m|30m|1h|3h|6h|12h|24h|120h) ;; *) echo "Use: 15m|1h|3h|24h|120h"; exit 1;; esac
M=15; [[ "$TW" =~ ^([0-9]+)m$ ]] && M="${BASH_REMATCH[1]}"; [[ "$TW" =~ ^([0-9]+)h$ ]] && M="$(( ${BASH_REMATCH[1]} * 60 ))"
echo "============================================================"
echo "📊 SERVER LOAD REPORT (LAST $TW) | $HOST | $NOW"
echo "============================================================"
echo -e "\n🚀 TOP-5 SITES (TRAFFIC):"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-$M" -exec wc -l {} + 2>/dev/null | sort -rn | head -n 6
echo -e "\n🔥 ACTIVE PHP POOLS (CPU %):"
ps -eo user,pcpu,pmem,args --sort=-pcpu | grep php-fpm | grep -v grep | head -n 5
echo -e "\n🔎 TOP URLs (BOTS/ATTACKS):"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-$M" -exec tail -n 800 {} + 2>/dev/null | awk '{print $7}' | cut -d'?' -f1 | sort | uniq -c | sort -rn | head -n 12
echo -e "\n💾 MYSQL PROCESSES (>2s):"
command -v mysql >/dev/null && mysql -e "SHOW FULL PROCESSLIST;" 2>/dev/null | awk '$6 > 2 && $2 != "system" {print "Time: "$6"s | DB: "$4" | Query: "$8}' || echo "N/A"
echo -e "\n❌ CRITICAL ERRORS:"
find /var/www/*/data/logs/ -name "*error.log" -mmin "-$M" -exec grep -iE "fatal|error|critical|Out of memory" {} + 2>/dev/null | tail -n 8
echo -e "\n🛡️ CROWDSEC STATUS:"
if command -v cscli >/dev/null; then
  echo "Active bans: $(cscli decisions list 2>/dev/null | awk 'BEGIN{c=0} /^\|/ {c++} END{print (c>0?c-1:0)}')"
  cscli alerts list --since "$TW" -l 15 2>/dev/null
fi
echo -e "============================================================"
