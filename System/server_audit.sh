#!/usr/bin/env bash
# WEB Server Stress Analyzer (Supports: 15m, 1h, 3h, 24h, 120h)
clear
TIMEWIN="${1:-15m}"
case "$TIMEWIN" in
  15m|30m|45m|1h|2h|3h|4h|6h|12h|24h|96h|120h) ;;
  *) echo "Usage: sos [15m|1h|3h|24h|120h]"; exit 1;;
esac

MINS=15
[[ "$TIMEWIN" =~ ^([0-9]+)m$ ]] && MINS="${BASH_REMATCH[1]}"
[[ "$TIMEWIN" =~ ^([0-9]+)h$ ]] && MINS="$(( ${BASH_REMATCH[1]} * 60 ))"

echo "============================================================"
echo "📊 SERVER LOAD REPORT (LAST ${TIMEWIN})"
echo "Server: $(hostname) | Date: $(date)"
echo "============================================================"

echo -e "\n🚀 TOP-5 SITES BY REQUESTS (TRAFFIC):"
echo "------------------------------------------------------------"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${MINS}" -exec wc -l {} + 2>/dev/null | sort -rn | head -n 6

echo -e "\n🔥 ACTIVE PHP POOLS (CPU %):"
echo "------------------------------------------------------------"
ps -eo user,pcpu,pmem,args --sort=-pcpu | grep php-fpm | grep -v grep | head -n 5

echo -e "\n🔎 FREQUENT URLs (BOT/ATTACK SEARCH):"
echo "------------------------------------------------------------"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${MINS}" -exec tail -n 800 {} + 2>/dev/null | awk '{print $7}' | cut -d'?' -f1 | sort | uniq -c | sort -rn | head -n 12

echo -e "\n💾 CURRENT MYSQL PROCESSES (> 2 SEC):"
echo "------------------------------------------------------------"
if command -v mysql >/dev/null 2>&1; then
  mysql -e "SHOW FULL PROCESSLIST;" 2>/dev/null | awk '$6 > 2 && $2 != "system" {print "Time: "$6"s | User: "$2" | DB: "$4" | Query: "$8}'
else
  echo "MySQL client not found"
fi

echo -e "\n❌ CRITICAL PHP/NGINX ERRORS:"
echo "------------------------------------------------------------"
find /var/www/*/data/logs/ -name "*error.log" -mmin "-${MINS}" -exec grep -iE "fatal|error|critical|Out of memory" {} + 2>/dev/null | tail -n 8

echo -e "\n🛡️ CROWDSEC STATUS (Active bans / Top reasons):"
echo "------------------------------------------------------------"
if command -v cscli >/dev/null 2>&1; then
  ACTIVE_BANS="$(cscli decisions list 2>/dev/null | awk 'BEGIN{c=0} /^\|/ {c++} END{print (c>0?c-1:0)}')"
  echo "Active decisions (approx): ${ACTIVE_BANS}"
  echo -e "\nTop decision reasons (first 15):"
  cscli decisions list 2>/dev/null | awk -F'\|' '/\|/ {gsub(/^[ \t]+|[ \t]+$/,"",$5); if($5!="Reason" && $5!="") print $5}' | sort | uniq -c | sort -rn | head -n 15
  echo -e "\nCrowdSec alerts (last ${TIMEWIN}, top 20):"
  cscli alerts list --since "${TIMEWIN}" -l 20 2>/dev/null || true
fi
echo -e "\n============================================================"
