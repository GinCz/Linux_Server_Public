#!/bin/bash
# =============================================================================
# SOS — VPN Node System Overview Script
# Version: v2026-04-10
# Author:  = Rooted by VladiMIR | AI =
# Purpose: Quick multi-section health check for AmneziaWG VPN nodes
# Usage:   sos [15m|30m|1h|3h|6h|12h|24h|120h]
# Default: 1h
# =============================================================================

clear

TW="${1:-1h}"
case "$TW" in
  15m|30m|1h|3h|6h|12h|24h|120h) ;;
  *) echo "Usage: sos [15m|30m|1h|3h|6h|12h|24h|120h]"; exit 1 ;;
esac

# ---- Color codes
G='\033[1;32m'
C='\033[1;36m'
Y='\033[1;33m'
R='\033[1;31m'
W='\033[1;37m'
X='\033[0m'

# ---- Helper functions
have(){ command -v "$1" >/dev/null 2>&1; }
H()  { echo -e "\n${Y}==================== $1 ====================${X}"; }

# ---- Time window in minutes
M=60
[[ "$TW" =~ ^([0-9]+)m$ ]] && M="${BASH_REMATCH[1]}"
[[ "$TW" =~ ^([0-9]+)h$ ]] && M="$(( ${BASH_REMATCH[1]}*60 ))"

# ---- Host info
NOW=$(date '+%Y-%m-%d %H:%M:%S')
HOST=$(hostname)
IP=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
CORES=$(nproc || echo 1)
LOAD=$(awk '{print $1,$2,$3}' /proc/loadavg)
LOAD1=$(awk '{print $1}' /proc/loadavg)
LOAD_PCT=$(awk "BEGIN{printf \"%.0f\",($LOAD1/$CORES)*100}")
[ "$LOAD_PCT" -ge 90 ] && LC="$R" || { [ "$LOAD_PCT" -ge 60 ] && LC="$Y" || LC="$G"; }

# ---- Header
echo -e "${W}╔═══════════════════════════════════════════════════════╗
║  📊 SOS — ${Y}${TW}${W}  |  ${G}${NOW}${W}
║  ${C}${HOST}${W} | ${G}${IP}${W} | Load: ${LC}${LOAD}${W} (${LC}${LOAD_PCT}%${W}/${CORES}c)
╚═══════════════════════════════════════════════════════╝${X}"

# ---- SYSTEM
H "⚙️  SYSTEM"
echo -e "  ${C}Uptime:${X} $(uptime -p)"
free -h | awk '/^Mem:/{printf "  \033[1;36mRAM:\033[0m  used %s / total %s (free %s)\n",$3,$2,$4}'
free -h | awk '/^Swap:/{printf "  \033[1;36mSwap:\033[0m used %s / total %s\n",$3,$2}'

# ---- DISK
H "💿 DISK"
df -h --output=source,size,used,avail,pcent,target 2>/dev/null \
  | grep -E '^(Filesystem|/dev)' \
  | awk 'NR==1{printf "  %-20s %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6; next}
             {printf "  \033[1;36m%-20s\033[0m %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6}'

# ---- TOP CPU
H "🔥 TOP 10 CPU%"
ps -eo pid,user,%cpu,pmem,args --sort=-%cpu 2>/dev/null \
  | head -11 | tail -10 \
  | awk '{printf "  \033[1;36m%-7s\033[0m %-10s %5s %5s  %s\n",$1,$2,$3,$4,$5}'

# ---- TOP RAM
H "🔍 TOP 15 RAM"
ps -eo pid,user,%cpu,pmem,rss,args --sort=-rss 2>/dev/null \
  | head -16 | tail -15 \
  | awk '{printf "  \033[1;36m%-7s\033[0m %-10s %5s %5s  %6.1fMB  %s\n",$1,$2,$3,$4,$5/1024,$6}'

# ---- PHP-FPM POOLS
H "🧠 PHP-FPM POOLS"
ps -eo user,rss,args 2>/dev/null \
  | grep 'php-fpm\|php-cgi' \
  | awk '{p=$1;r=$2;c[p]++;t[p]+=r}
    END{for(p in c) printf "  \033[1;36m%-26s\033[0m %4d wk  %7.1fMB\n",p,c[p],t[p]/1024}' \
  | sort -k4 -rn

# ---- TRAFFIC (web logs)
H "🚀 TOP-5 TRAFFIC (last ${TW})"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
  -exec wc -l {} + 2>/dev/null \
  | sort -rn | head -6 \
  | awk '{printf "  %7d  %s\n",$1,$2}'

# ---- TOP IPs
H "🌍 TOP-10 IPs (last ${TW})"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
  -exec tail -n 2000 {} + 2>/dev/null \
  | awk '{print $1}' | sort | uniq -c | sort -rn | head -10 \
  | awk '{printf "  %6d — %s\n",$1,$2}'

# ---- HTTP STATUS
H "📈 HTTP STATUS (last ${TW})"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
  -exec tail -n 2000 {} + 2>/dev/null \
  | awk '{print $9}' | grep -E '^[0-9]{3}$' | sort | uniq -c | sort -rn | head -10 \
  | awk '{if($2~/^2/)c="\033[1;32m"; else if($2~/^3/)c="\033[1;36m"; \
          else if($2~/^4/)c="\033[1;33m"; else c="\033[1;31m"; \
          printf "  %6d — %sHTTP %s\033[0m\n",$1,c,$2}'

# ---- WP-LOGIN ATTACKS
H "🔐 WP-LOGIN ATTACKS (last ${TW})"
grep -h 'wp-login.php' \
  /var/www/*/data/logs/*access.log \
  /var/log/nginx/*.log 2>/dev/null \
  | awk '{print $1}' | sort | uniq -c | sort -rn | head -10 \
  | awk '{c=(($1>100)?"\033[1;31m":(($1>20)?"\033[1;33m":"\033[1;37m"));
          printf "  %s%5d\033[0m  %s\n",c,$1,$2}'

# ---- NGINX
H "🔗 NGINX"
have nginx && {
  echo -e "  ${C}Workers:${X} ${G}$(pgrep -x nginx | wc -l)${X}  TCP: ${G}$(ss -tnp state established 2>/dev/null | wc -l)${X}"
  STUB=$(curl -s --max-time 2 http://127.0.0.1/nginx_status 2>/dev/null)
  [ -n "$STUB" ] && echo "$STUB" | awk '/Active/{printf "  Active: %s\n",$3}'
}

# ---- MYSQL
H "💾 MYSQL"
have mysql && {
  mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_connected';" 2>/dev/null \
    | awk '{printf "  \033[1;36mConnected:\033[0m \033[1;32m%s\033[0m\n",$2}'
  mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_running';" 2>/dev/null \
    | awk '{printf "  \033[1;36mRunning:\033[0m   \033[1;32m%s\033[0m\n",$2}'
  mysql -N -e "SHOW GLOBAL STATUS LIKE 'Slow_queries';" 2>/dev/null \
    | awk '{printf "  \033[1;36mSlow:\033[0m      %s\n",$2}'
}

# ---- DOCKER
H "🐳 DOCKER"
have docker && docker ps -a --format "  {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null \
  | awk '{c=($2~/Up/)?"\033[1;32m":"\033[1;31m";
          printf "  \033[1;36m%-28s\033[0m %s%s\033[0m  %s\n",$1,c,$2,$3}'

# ---- CRITICAL ERRORS
H "❌ CRITICAL ERRORS (last ${TW})"
find /var/www/*/data/logs/ -name "*error.log" -mmin "-${M}" \
  -exec grep -iE 'fatal|Out of memory|upstream timed out|connect\(\) failed|no live upstreams' {} + 2>/dev/null \
  | tail -10

# ---- CROWDSEC
H "🛡️  CROWDSEC"
have cscli && {
  BANS=$(cscli decisions list 2>/dev/null | awk 'BEGIN{c=0}/^\|/{c++}END{print (c>0?c-1:0)}')
  echo -e "  ${C}Bans:${X} ${R}${BANS}${X}"
  cscli alerts list --since "$TW" -l 10 2>/dev/null | head -12 | sed 's/^/  /'
}

# ---- SERVICES
H "🔧 SERVICES"
for SVC in nginx mariadb mysql php8.1-fpm php8.2-fpm php8.3-fpm php8.4-fpm \
           crowdsec crowdsec-firewall-bouncer netdata exim4 postfix docker ssh; do
  systemctl list-units --type=service --all 2>/dev/null | grep -q "${SVC}.service" && {
    STATE=$(systemctl is-active "$SVC" 2>/dev/null)
    [ "$STATE" = "active" ] && SC="$G" || SC="$R"
    printf "  ${C}%-35s${X} %b%s${X}\n" "$SVC" "$SC" "$STATE"
  }
done

# ---- Footer
echo -e "\n${W}╔═══════════════════════════════════════════════════════╗
║  = Rooted by VladiMIR | AI =   v2026-04-10          ║
╚═══════════════════════════════════════════════════════╝${X}"
