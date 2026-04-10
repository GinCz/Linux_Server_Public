#!/usr/bin/env bash
# = Rooted by VladiMIR | AI =
# Version: v2026-04-10
# Description: Web Server Stress Analyzer (SOS) — 222-DE-NetCup
clear
TW="${1:-24h}"; HOST="$(hostname)"; NOW="$(date)"
case "$TW" in 15m|30m|1h|3h|6h|12h|24h|120h) ;; *) echo "Use: 15m|30m|1h|3h|6h|12h|24h|120h"; exit 1;; esac
M=15
[[ "$TW" =~ ^([0-9]+)m$ ]] && M="${BASH_REMATCH[1]}"
[[ "$TW" =~ ^([0-9]+)h$ ]] && M="$(( ${BASH_REMATCH[1]} * 60 ))"

SEP="============================================================"
echo "$SEP"
echo "📊 SERVER LOAD REPORT (LAST $TW) | $HOST | $NOW"
echo "$SEP"

# --- SYSTEM OVERVIEW ---
echo -e "\n⚙️  SYSTEM OVERVIEW:"
echo "  Uptime   : $(uptime -p)"
echo "  Load avg : $(cut -d' ' -f1-3 /proc/loadavg)  (1m 5m 15m)"
echo "  CPU cores: $(nproc)"
MEM=$(free -h | awk '/^Mem:/{printf "used %s / total %s (free %s)", $3, $2, $4}')
echo "  RAM      : $MEM"
SWAP=$(free -h | awk '/^Swap:/{printf "used %s / total %s", $3, $2}')
echo "  Swap     : $SWAP"

# --- DISK USAGE ---
echo -e "\n💿 DISK USAGE:"
df -h --output=target,size,used,avail,pcent 2>/dev/null | grep -E "^(/|/BACKUP|/var |/home|/boot)" | \
  awk '{printf "  %-20s %6s used / %6s total  free: %6s  [%s]\n", $1, $3, $2, $4, $5}'

# --- TOP-5 SITES BY TRAFFIC ---
echo -e "\n🚀 TOP-5 SITES (TRAFFIC last $TW):"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-$M" -exec wc -l {} + 2>/dev/null | sort -rn | head -n 6

# --- ACTIVE PHP POOLS ---
echo -e "\n🔥 ACTIVE PHP POOLS (CPU %):"
ps -eo user,pcpu,pmem,args --sort=-pcpu | grep php-fpm | grep -v grep | head -n 8

# --- PHP-FPM POOL PROCESSES COUNT ---
echo -e "\n🧮 PHP-FPM POOL PROCESS COUNT:"
ps -eo args | grep "php-fpm: pool" | grep -v grep | awk '{print $NF}' | sort | uniq -c | sort -rn | head -n 10 | \
  awk '{printf "  %3d processes — pool %s\n", $1, $2}'

# --- TOP URLs ---
echo -e "\n🔎 TOP URLs (BOTS/ATTACKS last $TW):"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-$M" -exec tail -n 2000 {} + 2>/dev/null | \
  awk '{print $7}' | cut -d'?' -f1 | sort | uniq -c | sort -rn | head -n 15

# --- TOP IPs ---
echo -e "\n🌍 TOP-10 IPs (last $TW):"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-$M" -exec tail -n 2000 {} + 2>/dev/null | \
  awk '{print $1}' | sort | uniq -c | sort -rn | head -n 10 | \
  awk '{printf "  %6d requests — %s\n", $1, $2}'

# --- HTTP STATUS CODES ---
echo -e "\n📈 HTTP STATUS CODES (last $TW):"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-$M" -exec tail -n 2000 {} + 2>/dev/null | \
  awk '{print $9}' | grep -E '^[0-9]{3}$' | sort | uniq -c | sort -rn | head -n 10 | \
  awk '{printf "  %6d — HTTP %s\n", $1, $2}'

# --- NGINX CONNECTIONS ---
echo -e "\n🔗 NGINX CONNECTIONS:"
if curl -s http://127.0.0.1/nginx_status 2>/dev/null | grep -q "Active"; then
  curl -s http://127.0.0.1/nginx_status 2>/dev/null | awk '
    /Active/ {print "  Active connections : "$3}
    /Reading/ {print "  Reading: "$2"  Writing: "$4"  Waiting: "$6}
    /requests/ {print "  Total requests     : "$3}'
else
  ss -s | awk '/TCP:/{print "  TCP connections: "$0}'
fi

# --- DOCKER CONTAINERS ---
echo -e "\n🐳 DOCKER CONTAINERS:"
docker ps --format "  {{.Status}}\t{{.Names}}\t{{.Image}}" 2>/dev/null | \
  awk -F'\t' '{printf "  %-20s %-30s %s\n", $1, $2, $3}' | head -n 15

# --- MYSQL SLOW PROCESSES ---
echo -e "\n💾 MYSQL SLOW PROCESSES (>2s):"
if command -v mysql >/dev/null; then
  RESULT=$(mysql -e "SHOW FULL PROCESSLIST;" 2>/dev/null | awk '$6 > 2 && $2 != "system" {print "  Time: "$6"s | DB: "$4" | Query: "$8}')
  [ -n "$RESULT" ] && echo "$RESULT" || echo "  No slow queries"
else
  echo "  N/A"
fi

# --- MYSQL DB SIZES ---
echo -e "\n🗄️  MYSQL DATABASE SIZES:"
mysql -e "SELECT table_schema AS 'Database', ROUND(SUM(data_length+index_length)/1024/1024,1) AS 'MB' FROM information_schema.tables GROUP BY table_schema ORDER BY 2 DESC LIMIT 10;" 2>/dev/null | \
  awk 'NR>1{printf "  %-30s %s MB\n", $1, $2}' || echo "  N/A"

# --- CRITICAL ERRORS ---
echo -e "\n❌ CRITICAL ERRORS (last $TW):"
find /var/www/*/data/logs/ -name "*error.log" -mmin "-$M" -exec grep -iE "fatal|Out of memory|upstream timed out|connect() failed|no live upstreams" {} + 2>/dev/null | tail -n 10

# --- CROWDSEC ---
echo -e "\n🛡️  CROWDSEC STATUS:"
if command -v cscli >/dev/null; then
  BANS=$(cscli decisions list 2>/dev/null | awk 'BEGIN{c=0} /^\|/ {c++} END{print (c>0?c-1:0)}')
  echo "  Active bans : $BANS"
  echo "  Recent alerts (last $TW):"
  cscli alerts list --since "$TW" -l 10 2>/dev/null | head -n 15 | sed 's/^/  /'
else
  echo "  CrowdSec not installed"
fi

# --- RECENTLY MODIFIED FILES ---
echo -e "\n📝 RECENTLY MODIFIED WEB FILES (last 30min, excl. logs/cache):"
find /var/www/*/data/public_html/ -newer /proc/1 -mmin -30 \
  -not -path "*/cache/*" -not -path "*/logs/*" -not -name "*.log" \
  -type f 2>/dev/null | head -n 10 | sed 's/^/  /' || echo "  None"

# --- KEY SERVICES ---
echo -e "\n🔧 KEY SERVICES STATUS:"
for svc in nginx mysql php8.1-fpm php8.2-fpm php8.3-fpm docker crowdsec fail2ban; do
  STATUS=$(systemctl is-active "$svc" 2>/dev/null)
  [ "$STATUS" = "active" ] && ICON="✅" || ICON="❌"
  [ "$STATUS" = "inactive" ] && continue
  printf "  %s %-20s %s\n" "$ICON" "$svc" "$STATUS"
done

echo -e "\n$SEP"
echo "  = Rooted by VladiMIR | AI ="
echo "$SEP"
