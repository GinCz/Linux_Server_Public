#!/usr/bin/env bash
# ============================================================
# sos.sh — Server Full Status + Log Analyzer
# = Rooted by VladiMIR | AI =
# Version: v2026-04-10
# Server: 222-DE-NetCup | IP: 152.53.182.222
# ============================================================
clear
G='\033[1;32m'; C='\033[1;36m'; Y='\033[1;33m'
R='\033[1;31m'; W='\033[1;37m'; X='\033[0m'
have() { command -v "$1" >/dev/null 2>&1; }
head_() { echo -e "\n${Y}==================== $1 ====================${X}"; }
TW="${1:-1h}"
case "$TW" in
  15m|30m|1h|3h|6h|12h|24h|120h) ;;
  *) echo -e "${R}Usage: sos [15m|30m|1h|3h|6h|12h|24h|120h]${X}"; exit 1;;
esac
M=60
[[ "$TW" =~ ^([0-9]+)m$ ]] && M="${BASH_REMATCH[1]}"
[[ "$TW" =~ ^([0-9]+)h$ ]] && M="$(( ${BASH_REMATCH[1]} * 60 ))"
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
echo -e "${W}║  📊 SOS — PERIOD: ${Y}${TW}${W}  |  ${G}${NOW}${W}                    ║${X}"
echo -e "${W}║  ${C}${HOST}${W} | ${G}${IP}${W}  |  Load: ${LC}${LOAD}${W} (${LC}${LOAD_PCT}%${W}/${CORES}c)   ║${X}"
echo -e "${W}╚════════════════════════════════════════════════════════════╝${X}"
head_ "⚙️  SYSTEM"
echo -e "  ${C}Uptime:${X} $(uptime -p)"
free -h | awk '/^Mem:/{printf "  \033[1;36mRAM:\033[0m   used %s / total %s (free %s)\n",$3,$2,$4}'
free -h | awk '/^Swap:/{printf "  \033[1;36mSwap:\033[0m  used %s / total %s\n",$3,$2}'
head_ "💿 DISK"
df -h --output=source,size,used,avail,pcent,target 2>/dev/null | grep -E '^(Filesystem|/dev)' | \
  awk 'NR==1{printf "  %-20s %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6;next}
       {printf "  \033[1;36m%-20s\033[0m %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6}'
head_ "🔍 TOP 20 BY MEMORY (RSS)"
echo -e "  ${C}PID     USER       %CPU  %MEM     RSS MB   COMMAND${X}"
ps -eo pid,user,%cpu,pmem,rss,args --sort=-rss 2>/dev/null | head -21 | tail -20 | \
  awk '{printf "  %-7s %-10s %5s %5s  %7.1f MB  %s\n",$1,$2,$3,$4,$5/1024,$6}'
head_ "🔥 TOP 10 BY CPU%"
echo -e "  ${C}PID     USER       %CPU  %MEM   COMMAND${X}"
ps -eo pid,user,%cpu,pmem,args --sort=-%cpu 2>/dev/null | head -11 | tail -10 | \
  awk '{printf "  %-7s %-10s %5s %5s   %s\n",$1,$2,$3,$4,$5}'
head_ "🧠 PHP-FPM POOLS"
echo -e "  ${C}POOL                       WORKERS   TOTAL RSS${X}"
ps -eo user,rss,args 2>/dev/null | grep 'php-fpm\|php-cgi' | \
  awk '{pool=$1;rss=$2;count[pool]++;total[pool]+=rss}
  END{for(p in count)printf "  \033[1;36m%-26s\033[0m %4d wk   %7.1f MB\n",p,count[p],total[p]/1024}' | sort -k4 -rn
echo -e "\n  ${C}Process count per pool:${X}"
ps -eo args 2>/dev/null | grep 'php-fpm: pool' | grep -v grep | \
  awk '{print $NF}' | sort | uniq -c | sort -rn | head -10 | \
  awk '{printf "  %3d — pool %s\n",$1,$2}'
head_ "🚀 TOP-5 SITES BY TRAFFIC (last ${TW})"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
  -exec wc -l {} + 2>/dev/null | sort -rn | head -6 | awk '{printf "  %7d  %s\n",$1,$2}'
head_ "🔎 TOP URLs — BOTS/ATTACKS (last ${TW})"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
  -exec tail -n 2000 {} + 2>/dev/null | \
  awk '{print $7}' | cut -d'?' -f1 | sort | uniq -c | sort -rn | head -15 | \
  awk '{printf "  %6d  %s\n",$1,$2}'
head_ "🌍 TOP-10 IPs (last ${TW})"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
  -exec tail -n 2000 {} + 2>/dev/null | \
  awk '{print $1}' | sort | uniq -c | sort -rn | head -10 | \
  awk '{printf "  %6d — %s\n",$1,$2}'
head_ "📈 HTTP STATUS CODES (last ${TW})"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
  -exec tail -n 2000 {} + 2>/dev/null | \
  awk '{print $9}' | grep -E '^[0-9]{3}$' | sort | uniq -c | sort -rn | head -10 | \
  awk '{if($2~/^2/)c="\033[1;32m";else if($2~/^3/)c="\033[1;36m";else if($2~/^4/)c="\033[1;33m";else c="\033[1;31m";printf "  %6d — %sHTTP %s\033[0m\n",$1,c,$2}'
head_ "🔐 WP-LOGIN ATTACKS (last ${TW})"
grep -h 'wp-login.php' /var/www/*/data/logs/*access.log /var/log/nginx/*.log 2>/dev/null | \
  awk '{print $1}' | sort | uniq -c | sort -rn | head -15 | \
  awk '{c=(($1>100)?"\033[1;31m":(($1>20)?"\033[1;33m":"\033[1;37m"));printf "  %s%5d\033[0m  %s\n",c,$1,$2}'
head_ "🔗 NGINX"
if have nginx; then
  echo -e "  ${C}Workers:${X} ${G}$(pgrep -x nginx | wc -l)${X}"
  STUB=$(curl -s --max-time 2 http://127.0.0.1/nginx_status 2>/dev/null)
  if [ -n "$STUB" ]; then
    echo "$STUB" | awk '/Active/{printf "  Active: %s\n",$3}/Reading/{printf "  R:%s W:%s W:%s\n",$2,$4,$6}'
  else
    ss -s 2>/dev/null | awk '/TCP:/{print "  TCP: "$0}'
  fi
  echo -e "  ${C}TCP established:${X} ${G}$(ss -tnp state established 2>/dev/null | wc -l)${X}"
fi
head_ "💾 MYSQL"
if have mysql; then
  mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_connected';" 2>/dev/null | awk '{printf "  \033[1;36mThreads connected:\033[0m \033[1;32m%s\033[0m\n",$2}'
  mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_running';" 2>/dev/null | awk '{printf "  \033[1;36mThreads running:  \033[0m \033[1;32m%s\033[0m\n",$2}'
  mysql -N -e "SHOW GLOBAL STATUS LIKE 'Slow_queries';" 2>/dev/null | awk '{printf "  \033[1;36mSlow queries:     \033[0m %s\n",$2}'
  echo -e "\n  ${C}Slow processes (>2s):${X}"
  RESULT=$(mysql -e "SHOW FULL PROCESSLIST;" 2>/dev/null | awk '$6>2 && $2!="system"{print "  "$6"s | "$4" | "$8}')
  [ -n "$RESULT" ] && echo "$RESULT" || echo -e "  ${G}None${X}"
  echo -e "\n  ${C}DB sizes:${X}"
  mysql -e "SELECT table_schema, ROUND(SUM(data_length+index_length)/1024/1024,1) FROM information_schema.tables GROUP BY table_schema ORDER BY 2 DESC LIMIT 10;" 2>/dev/null | \
    awk 'NR>1{printf "  \033[1;36m%-30s\033[0m %s MB\n",$1,$2}'
fi
head_ "🐳 DOCKER"
if have docker; then
  docker stats --no-stream --format "  {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | \
    awk '{printf "  \033[1;36m%-28s\033[0m CPU:%-7s MEM:%s\n",$1,$2,$3}'
  echo ""
  docker ps -a --format "  {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null | \
    awk '{c=($2~/Up/)?"\033[1;32m":"\033[1;31m";printf "  \033[1;36m%-28s\033[0m %s%s\033[0m  %s\n",$1,c,$2,$3}'
fi
head_ "❌ CRITICAL ERRORS (last ${TW})"
find /var/www/*/data/logs/ -name "*error.log" -mmin "-${M}" \
  -exec grep -iE 'fatal|Out of memory|upstream timed out|connect\(\) failed|no live upstreams' {} + \
  2>/dev/null | tail -10
head_ "🛡️  CROWDSEC"
if have cscli; then
  BANS=$(cscli decisions list 2>/dev/null | awk 'BEGIN{c=0}/^\|/{c++}END{print (c>0?c-1:0)}')
  echo -e "  ${C}Active bans:${X} ${R}${BANS}${X}"
  cscli alerts list --since "$TW" -l 10 2>/dev/null | head -12 | sed 's/^/  /'
fi
head_ "🔧 SERVICES"
for SVC in nginx mariadb mysql php8.1-fpm php8.2-fpm php8.3-fpm php8.4-fpm crowdsec crowdsec-firewall-bouncer netdata exim4 dovecot postfix docker ssh cron; do
  if systemctl list-units --type=service --all 2>/dev/null | grep -q "${SVC}.service"; then
    STATE=$(systemctl is-active "$SVC" 2>/dev/null)
    EN=$(systemctl is-enabled "$SVC" 2>/dev/null || echo '?')
    if [ "$STATE"="active" ]; then SC="$G"; elif [ "$STATE"="inactive" ]; then SC="$Y"; else SC="$R"; fi
    printf "  ${C}%-35s${X} %b%-10s${X}  %s\n" "$SVC" "$SC" "$STATE" "$EN"
  fi
done
head_ "📝 MODIFIED FILES (last 30min)"
find /var/www/*/data/public_html/ -mmin -30 \
  -not -path '*/cache/*' -not -path '*/logs/*' -not -name '*.log' \
  -type f 2>/dev/null | head -10 | sed 's/^/  /' || echo -e "  ${G}None${X}"
head_ "📊 DISK BY SITE (top 10)"
du -sh /var/www/*/data/www 2>/dev/null | sort -rh | head -10 | \
  awk '{printf "  \033[1;36m%-12s\033[0m  %s\n",$1,$2}'
echo ""
echo -e "${W}╔════════════════════════════════════════════════════════════╗${X}"
echo -e "${W}║  = Rooted by VladiMIR | AI =   v2026-04-10               ║${X}"
echo -e "${W}║  https://github.com/GinCz/Linux_Server_Public            ║${X}"
echo -e "${W}╚════════════════════════════════════════════════════════════╝${X}"
