#!/usr/bin/env bash
# ============================================================
# sos.sh — Server Full Status + Log Analyzer
# = Rooted by VladiMIR | AI =
# Version: v2026-04-10
# Server: 222-DE-NetCup | IP: 152.53.182.222 | Ubuntu 24 / FASTPANEL
# GitHub: https://github.com/GinCz/Linux_Server_Public
#
# USAGE:
#   sos          — last 1h  (default)
#   sos3         — last 3h
#   sos24        — last 24h
#   sos120       — last 120h
#   bash sos.sh 30m  — custom period
#
# VALID PERIODS: 15m | 30m | 1h | 3h | 6h | 12h | 24h | 120h
# ============================================================

clear

# ---------- Colors ----------
G='\033[1;32m'   # green
C='\033[1;36m'   # cyan
Y='\033[1;33m'   # yellow
R='\033[1;31m'   # red
M='\033[1;35m'   # magenta
W='\033[1;37m'   # white
X='\033[0m'      # reset

have() { command -v "$1" >/dev/null 2>&1; }
sep()  { echo -e "${Y}------------------------------------------------------------${X}"; }
head_() { echo -e "\n${Y}==================== $1 ====================${X}"; }

# ---------- Time period ----------
TW="${1:-1h}"
case "$TW" in
  15m|30m|1h|3h|6h|12h|24h|120h) ;;
  *) echo -e "${R}Usage: sos [15m|30m|1h|3h|6h|12h|24h|120h]${X}"; exit 1;;
esac
M=60
[[ "$TW" =~ ^([0-9]+)m$ ]] && M="${BASH_REMATCH[1]}"
[[ "$TW" =~ ^([0-9]+)h$ ]] && M="$(( ${BASH_REMATCH[1]} * 60 ))"

# ---------- Header ----------
NOW=$(date '+%Y-%m-%d %H:%M:%S')
HOST=$(hostname)
IP=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
CORES=$(nproc 2>/dev/null || echo 1)
LOAD=$(awk '{print $1, $2, $3}' /proc/loadavg)
LOAD1=$(awk '{print $1}' /proc/loadavg)
LOAD_PCT=$(awk "BEGIN{printf \"%.0f\", ($LOAD1/$CORES)*100}")
if   [ "$LOAD_PCT" -ge 90 ]; then LC="$R"
elif [ "$LOAD_PCT" -ge 60 ]; then LC="$Y"
else LC="$G"; fi

echo -e "${W}╔════════════════════════════════════════════════════════════╗${X}"
echo -e "${W}║  📊 SOS REPORT — PERIOD: ${Y}${TW}${W}  |  ${G}${NOW}${W}  ║${X}"
echo -e "${W}║  ${C}${HOST}${W} | ${G}${IP}${W}  |  Load: ${LC}${LOAD}${W} (${LC}${LOAD_PCT}%${W} / ${CORES} cores)      ║${X}"
echo -e "${W}╚════════════════════════════════════════════════════════════╝${X}"

# ============================================================
# 1. SYSTEM OVERVIEW
# ============================================================
head_ "⚙️  SYSTEM OVERVIEW"
echo -e "  ${C}Uptime:${X}      $(uptime -p)"
echo -e "  ${C}Load 1/5/15:${X} ${LC}${LOAD}${X}  (${LC}${LOAD_PCT}%${X} of ${CORES} cores)"
MEM=$(free -h | awk '/^Mem:/{printf "used %s / total %s (free %s)", $3, $2, $4}')
SWAP=$(free -h | awk '/^Swap:/{printf "used %s / total %s", $3, $2}')
echo -e "  ${C}RAM:${X}         $MEM"
echo -e "  ${C}Swap:${X}        $SWAP"

# ============================================================
# 2. DISK USAGE
# ============================================================
head_ "💿 DISK USAGE"
df -h --output=source,size,used,avail,pcent,target 2>/dev/null | grep -E '^(Filesystem|/dev)' | \
  awk 'NR==1{printf "  %-20s %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6; next}
       {printf "  \033[1;36m%-20s\033[0m %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6}'

# ============================================================
# 3. TOP 20 PROCESSES BY MEMORY
# ============================================================
head_ "🔍 TOP 20 PROCESSES BY MEMORY (RSS)"
echo -e "  ${C}PID     USER       %CPU  %MEM     RSS MB   COMMAND${X}"
ps -eo pid,user,%cpu,pmem,rss,args --sort=-rss 2>/dev/null | head -21 | tail -20 | \
  awk '{rss_mb=$5/1024; printf "  %-7s %-10s %5s %5s  %7.1f MB  %s\n",$1,$2,$3,$4,rss_mb,$6}'

# ============================================================
# 4. TOP 10 PROCESSES BY CPU%
# ============================================================
head_ "🔥 TOP 10 PROCESSES BY CPU%"
echo -e "  ${C}PID     USER       %CPU  %MEM   COMMAND${X}"
ps -eo pid,user,%cpu,pmem,args --sort=-%cpu 2>/dev/null | head -11 | tail -10 | \
  awk '{printf "  %-7s %-10s %5s %5s   %s\n",$1,$2,$3,$4,$5}'

# ============================================================
# 5. PHP-FPM POOLS
# ============================================================
head_ "🧠 PHP-FPM POOLS (workers + RSS per pool)"
echo -e "  ${C}POOL (user)              WORKERS   TOTAL RSS${X}"
ps -eo user,rss,args 2>/dev/null | grep 'php-fpm\|php-cgi' | \
  awk '{pool=$1; rss=$2; count[pool]++; total[pool]+=rss}
  END{for(p in count) printf "  \033[1;36m%-26s\033[0m %4d wk   %7.1f MB\n",p,count[p],total[p]/1024}' | sort -k4 -rn

echo -e "\n  ${C}PHP-FPM pool process count:${X}"
ps -eo args 2>/dev/null | grep 'php-fpm: pool' | grep -v grep | \
  awk '{print $NF}' | sort | uniq -c | sort -rn | head -10 | \
  awk '{printf "  %3d processes — pool %s\n",$1,$2}'

# ============================================================
# 6. TOP-5 SITES BY TRAFFIC (period)
# ============================================================
head_ "🚀 TOP-5 SITES BY TRAFFIC (last ${TW})"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
  -exec wc -l {} + 2>/dev/null | sort -rn | head -6 | \
  awk '{printf "  %7d  %s\n",$1,$2}'

# ============================================================
# 7. TOP URLs (bots/attacks, period)
# ============================================================
head_ "🔎 TOP URLs — BOTS/ATTACKS (last ${TW})"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
  -exec tail -n 2000 {} + 2>/dev/null | \
  awk '{print $7}' | cut -d'?' -f1 | sort | uniq -c | sort -rn | head -15 | \
  awk '{printf "  %6d  %s\n",$1,$2}'

# ============================================================
# 8. TOP IPs (period)
# ============================================================
head_ "🌍 TOP-10 IPs (last ${TW})"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
  -exec tail -n 2000 {} + 2>/dev/null | \
  awk '{print $1}' | sort | uniq -c | sort -rn | head -10 | \
  awk '{printf "  %6d requests — %s\n",$1,$2}'

# ============================================================
# 9. HTTP STATUS CODES (period)
# ============================================================
head_ "📈 HTTP STATUS CODES (last ${TW})"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
  -exec tail -n 2000 {} + 2>/dev/null | \
  awk '{print $9}' | grep -E '^[0-9]{3}$' | sort | uniq -c | sort -rn | head -10 | \
  awk '{
    if ($2~/^2/) c="\033[1;32m"
    else if ($2~/^3/) c="\033[1;36m"
    else if ($2~/^4/) c="\033[1;33m"
    else c="\033[1;31m"
    printf "  %6d — %sHTTP %s\033[0m\n",$1,c,$2
  }'

# ============================================================
# 10. WP-LOGIN BRUTE FORCE (period)
# ============================================================
head_ "🔒 WP-LOGIN.PHP ATTACKS (last ${TW})"
echo -e "  ${C}Hits  IP Address${X}"
grep -h 'wp-login.php' \
  /var/www/*/data/logs/*access.log \
  /var/log/nginx/*.log 2>/dev/null | \
  awk '{print $1}' | sort | uniq -c | sort -rn | head -15 | \
  awk '{
    color=(($1>100)?"\033[1;31m":(($1>20)?"\033[1;33m":"\033[1;37m"))
    printf "  %s%5d\033[0m  %s\n",color,$1,$2
  }'

# ============================================================
# 11. NGINX CONNECTIONS
# ============================================================
head_ "🔗 NGINX CONNECTIONS"
if have nginx; then
  NGINX_WORKERS=$(pgrep -x nginx | wc -l)
  echo -e "  ${C}Workers (master+children):${X} ${G}${NGINX_WORKERS}${X}"
  STUB=$(curl -s --max-time 2 http://127.0.0.1/nginx_status 2>/dev/null)
  if [ -n "$STUB" ]; then
    echo "$STUB" | awk '
      /Active/   {printf "  Active connections : %s\n",$3}
      /Reading/  {printf "  Reading: %s  Writing: %s  Waiting: %s\n",$2,$4,$6}
      /requests/ {printf "  Total requests     : %s\n",$3}'
  else
    ss -s 2>/dev/null | awk '/TCP:/{printf "  TCP connections: %s\n",$0}'
  fi
  CONN_EST=$(ss -tnp state established 2>/dev/null | wc -l)
  echo -e "  ${C}TCP established:${X} ${G}${CONN_EST}${X}"
else
  echo -e "  ${R}Nginx not found${X}"
fi

# ============================================================
# 12. MYSQL / MARIADB
# ============================================================
head_ "💾 MYSQL / MARIADB"
if have mysql; then
  THREADS=$(mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_connected';" 2>/dev/null | awk '{print $2}')
  RUNNING=$(mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_running';" 2>/dev/null | awk '{print $2}')
  QUERIES=$(mysql -N -e "SHOW GLOBAL STATUS LIKE 'Questions';" 2>/dev/null | awk '{print $2}')
  SLOW=$(mysql -N -e "SHOW GLOBAL STATUS LIKE 'Slow_queries';" 2>/dev/null | awk '{print $2}')
  UPDB=$(mysql -N -e "SHOW GLOBAL STATUS LIKE 'Uptime';" 2>/dev/null | awk '{print $2}')
  echo -e "  ${C}Threads connected:${X} ${G}${THREADS:-N/A}${X}"
  echo -e "  ${C}Threads running:${X}   ${G}${RUNNING:-N/A}${X}"
  echo -e "  ${C}Total queries:${X}     ${G}${QUERIES:-N/A}${X}"
  echo -e "  ${C}Slow queries:${X}      ${SLOW:-N/A}"
  echo -e "  ${C}DB uptime:${X}         $(awk "BEGIN{printf \"%d h %d m\",${UPDB:-0}/3600,(${UPDB:-0}%3600)/60}")"
  echo -e "\n  ${C}Slow processes (>2s):${X}"
  RESULT=$(mysql -e "SHOW FULL PROCESSLIST;" 2>/dev/null | awk '$6>2 && $2!="system"{print "  Time: "$6"s | DB: "$4" | Query: "$8}')
  [ -n "$RESULT" ] && echo "$RESULT" || echo -e "  ${G}No slow queries${X}"
  echo -e "\n  ${C}DB sizes (top 10):${X}"
  mysql -e "SELECT table_schema AS 'Database', ROUND(SUM(data_length+index_length)/1024/1024,1) AS 'MB' FROM information_schema.tables GROUP BY table_schema ORDER BY 2 DESC LIMIT 10;" 2>/dev/null | \
    awk 'NR>1{printf "  \033[1;36m%-30s\033[0m %s MB\n",$1,$2}' || echo "  N/A"
else
  echo -e "  ${R}MySQL not found or not accessible${X}"
fi

# ============================================================
# 13. DOCKER CONTAINERS
# ============================================================
head_ "🐳 DOCKER CONTAINERS"
if have docker; then
  echo -e "  ${C}CONTAINER NAME               STATUS          CPU%   MEM USAGE${X}"
  docker stats --no-stream --format \
    "  {{.Name}}\t{{.Status}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | \
    awk '{printf "  \033[1;36m%-28s\033[0m %-16s %-7s %s\n",$1,$2,$3,$4}'
  echo ""
  docker ps -a --format "  {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null | \
    awk '{
      color=($2~/Up/)? "\033[1;32m" : "\033[1;31m"
      printf "  \033[1;36m%-28s\033[0m %s%-16s\033[0m %s\n",$1,color,$2,$3
    }'
else
  echo -e "  ${Y}Docker not installed${X}"
fi

# ============================================================
# 14. CRITICAL ERRORS IN LOGS (period)
# ============================================================
head_ "❌ CRITICAL ERRORS IN LOGS (last ${TW})"
find /var/www/*/data/logs/ -name "*error.log" -mmin "-${M}" \
  -exec grep -iE 'fatal|Out of memory|upstream timed out|connect\(\) failed|no live upstreams' {} + \
  2>/dev/null | tail -10 | awk '{printf "  %s\n",$0}'

# ============================================================
# 15. CROWDSEC
# ============================================================
head_ "🛡️  CROWDSEC STATUS"
if have cscli; then
  BANS=$(cscli decisions list 2>/dev/null | awk 'BEGIN{c=0}/^\|/{c++}END{print (c>0?c-1:0)}')
  echo -e "  ${C}Active bans:${X} ${R}${BANS}${X}"
  echo -e "  ${C}Recent alerts (last ${TW}):${X}"
  cscli alerts list --since "$TW" -l 10 2>/dev/null | head -12 | sed 's/^/  /'
else
  echo -e "  ${Y}CrowdSec not installed${X}"
fi

# ============================================================
# 16. KEY SERVICES
# ============================================================
head_ "🔧 KEY SERVICES STATUS"
SERVICES=(
  nginx mariadb mysql
  php8.1-fpm php8.2-fpm php8.3-fpm php8.4-fpm
  crowdsec crowdsec-firewall-bouncer netdata
  exim4 dovecot postfix
  docker ssh cron
)
for SVC in "${SERVICES[@]}"; do
  if systemctl list-units --type=service --all 2>/dev/null | grep -q "${SVC}.service"; then
    STATE=$(systemctl is-active "$SVC" 2>/dev/null)
    ENABLED=$(systemctl is-enabled "$SVC" 2>/dev/null || echo 'unknown')
    if   [ "$STATE" = "active" ];   then SC="$G"
    elif [ "$STATE" = "inactive" ]; then SC="$Y"
    else SC="$R"; fi
    printf "  ${C}%-35s${X} %b%-10s${X}  enabled: %s\n" "$SVC" "$SC" "$STATE" "$ENABLED"
  fi
done

# ============================================================
# 17. RECENTLY MODIFIED WEB FILES (last 30min)
# ============================================================
head_ "📝 RECENTLY MODIFIED WEB FILES (last 30min)"
find /var/www/*/data/public_html/ -mmin -30 \
  -not -path '*/cache/*' -not -path '*/logs/*' -not -name '*.log' \
  -type f 2>/dev/null | head -10 | sed 's/^/  /' || echo -e "  ${G}None${X}"

# ============================================================
# 18. DISK USAGE BY SITE (/var/www top 10)
# ============================================================
head_ "📊 DISK USAGE BY SITE (/var/www — top 10)"
if [ -d /var/www ]; then
  du -sh /var/www/*/data/www 2>/dev/null | sort -rh | head -10 | \
    awk '{printf "  \033[1;36m%-12s\033[0m  %s\n",$1,$2}'
else
  echo -e "  ${Y}/var/www not found${X}"
fi

# ============================================================
# FOOTER
# ============================================================
echo ""
echo -e "${W}╔════════════════════════════════════════════════════════════╗${X}"
echo -e "${W}║  = Rooted by VladiMIR | AI =   v2026-04-10                ║${X}"
echo -e "${W}║  https://github.com/GinCz/Linux_Server_Public             ║${X}"
echo -e "${W}╚════════════════════════════════════════════════════════════╝${X}"
