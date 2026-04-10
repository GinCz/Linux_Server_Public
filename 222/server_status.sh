#!/usr/bin/env bash
# ============================================================
# server_status.sh — Real-Time Server Snapshot
# = Rooted by VladiMIR | AI =
# Version: v2026-04-10
# Server: 222-DE-NetCup | IP: 152.53.182.222 | Ubuntu 24 / FASTPANEL
# GitHub: https://github.com/GinCz/Linux_Server_Public
#
# PURPOSE:
#   Instant full snapshot of server health — WHO is eating resources,
#   WHICH services are running, HOW MUCH memory/CPU each process uses,
#   Docker containers status, PHP-FPM pool load, MySQL threads,
#   active wp-login.php attacks, CrowdSec bans, open connections.
#
# INSTALL (persistent after reboot):
#   cp /root/Linux_Server_Public/222/server_status.sh /usr/local/bin/server_status.sh
#   chmod +x /usr/local/bin/server_status.sh
#   echo "alias status='bash /usr/local/bin/server_status.sh'" >> /root/.bashrc
#   source /root/.bashrc
#
# USAGE:
#   status         — full snapshot
#   status 2>/dev/null | less -R   — paginated
#
# CRON (optional — auto-log every hour):
#   0 * * * * /usr/local/bin/server_status.sh >> /var/log/server_status.log 2>&1
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

have()  { command -v "$1" >/dev/null 2>&1; }
safe()  { "$@" 2>/dev/null || true; }
sep()   { echo -e "${Y}------------------------------------------------------------${X}"; }
head_()  { echo -e "\n${Y}==================== $1 ====================${X}"; }

# ---------- Timestamp ----------
NOW=$(date '+%Y-%m-%d %H:%M:%S')
HOST=$(hostname)
IP=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)

echo -e "${W}╔══════════════════════════════════════════════════════════╗${X}"
echo -e "${W}║  SERVER STATUS SNAPSHOT — ${G}${NOW}${W}  ║${X}"
echo -e "${W}║  ${C}${HOST}${W} | ${G}${IP}${W}                                    ║${X}"
echo -e "${W}╚══════════════════════════════════════════════════════════╝${X}"

# ============================================================
# 1. LOAD AVERAGE + UPTIME
# ============================================================
head_ "LOAD AVERAGE & UPTIME"
UPTIME=$(uptime)
LOAD=$(awk '{print $1, $2, $3}' /proc/loadavg)
CORES=$(nproc 2>/dev/null || echo 1)
LOAD1=$(awk '{print $1}' /proc/loadavg)
LOAD_PCT=$(awk "BEGIN{printf \"%.0f\", ($LOAD1/$CORES)*100}")
if   [ "$LOAD_PCT" -ge 90 ]; then LC="$R"
elif [ "$LOAD_PCT" -ge 60 ]; then LC="$Y"
else LC="$G"; fi
echo -e "${C}Uptime:${X}      $UPTIME"
echo -e "${C}Load 1/5/15:${X} ${LC}$LOAD${X}  (${LC}${LOAD_PCT}%${X} of ${CORES} cores)"

# ============================================================
# 2. MEMORY (RAM + SWAP)
# ============================================================
head_ "MEMORY (RAM + SWAP)"
free -h | awk '
  NR==1 { printf "              %-10s %-10s %-10s %-10s %-10s\n", $1, $2, $3, $4, $6 }
  NR==2 { printf "  \033[1;36mRAM:   \033[0m      %-10s %-10s %-10s %-10s %-10s\n", $2, $3, $4, $5, $7 }
  NR==3 { printf "  \033[1;36mSwap:  \033[0m      %-10s %-10s %-10s\n", $2, $3, $4 }
'

# ============================================================
# 3. DISK
# ============================================================
head_ "DISK USAGE"
df -h --output=source,size,used,avail,pcent,target | grep -E '^(Filesystem|/dev)' | \
  awk 'NR==1{printf "  %-20s %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6; next}
       {printf "  \033[1;36m%-20s\033[0m %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6}'

# ============================================================
# 4. TOP PROCESSES BY MEMORY (RSS)
# ============================================================
head_ "TOP 20 PROCESSES BY MEMORY (RSS)"
echo -e "${C}  PID     USER       %CPU  %MEM     RSS MB   COMMAND${X}"
ps -eo pid,user,%cpu,pmem,rss,args --sort=-rss 2>/dev/null | head -21 | tail -20 | \
  awk '{
    rss_mb = $5/1024
    printf "  %-7s %-10s %5s %5s  %7.1f MB  %s\n", $1, $2, $3, $4, rss_mb, $6
  }'

# ============================================================
# 5. CPU HOGS (top 10 by CPU%)
# ============================================================
head_ "TOP 10 PROCESSES BY CPU%"
echo -e "${C}  PID     USER       %CPU  %MEM   COMMAND${X}"
ps -eo pid,user,%cpu,pmem,args --sort=-%cpu 2>/dev/null | head -11 | tail -10 | \
  awk '{printf "  %-7s %-10s %5s %5s   %s\n", $1, $2, $3, $4, $5}'

# ============================================================
# 6. PHP-FPM POOLS (per pool — how many workers & memory)
# ============================================================
head_ "PHP-FPM POOLS (workers per pool + total RSS)"
echo -e "${C}  POOL (user)              WORKERS   TOTAL RSS${X}"
ps -eo user,rss,args 2>/dev/null | grep 'php-fpm\|php-cgi' | \
  awk '{
    pool=$1; rss=$2
    count[pool]++; total[pool]+=rss
  }
  END{
    for (p in count)
      printf "  \033[1;36m%-26s\033[0m %4d wk   %7.1f MB\n", p, count[p], total[p]/1024
  }' | sort -k4 -rn

# ============================================================
# 7. MYSQL / MARIADB STATUS
# ============================================================
head_ "MYSQL / MARIADB"
if have mysql; then
  # Active threads
  THREADS=$(mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_connected';" 2>/dev/null | awk '{print $2}')
  RUNNING=$(mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_running';" 2>/dev/null | awk '{print $2}')
  QUERIES=$(mysql -N -e "SHOW GLOBAL STATUS LIKE 'Questions';" 2>/dev/null | awk '{print $2}')
  QPS=$(mysql -N -e "SHOW GLOBAL STATUS LIKE 'Queries';" 2>/dev/null | awk '{print $2}')
  SLOW=$(mysql -N -e "SHOW GLOBAL STATUS LIKE 'Slow_queries';" 2>/dev/null | awk '{print $2}')
  UPDB=$(mysql -N -e "SHOW GLOBAL STATUS LIKE 'Uptime';" 2>/dev/null | awk '{print $2}')
  echo -e "  ${C}Threads connected:${X}  ${G}${THREADS:-N/A}${X}"
  echo -e "  ${C}Threads running:${X}    ${G}${RUNNING:-N/A}${X}"
  echo -e "  ${C}Total queries:${X}      ${G}${QUERIES:-N/A}${X}"
  echo -e "  ${C}Slow queries:${X}       ${SLOW:-N/A}"
  echo -e "  ${C}DB uptime:${X}          $(awk "BEGIN{printf \"%d h %d m\", ${UPDB:-0}/3600, (${UPDB:-0}%3600)/60}")"
  echo -e "\n  ${C}Active processes (SHOW PROCESSLIST):${X}"
  mysql -e "SHOW PROCESSLIST;" 2>/dev/null | head -15 | awk 'NR==1{next}{printf "  %s\n",$0}'
else
  echo -e "  ${R}MySQL/MariaDB not found or not accessible without password${X}"
fi

# ============================================================
# 8. NGINX — connections & requests
# ============================================================
head_ "NGINX STATUS"
if have nginx; then
  NGINX_PID=$(pgrep -x nginx | head -1)
  NGINX_WORKERS=$(pgrep -x nginx | wc -l)
  echo -e "  ${C}Workers (master+children):${X} ${G}${NGINX_WORKERS}${X}"
  # connections via stub_status if available
  STUB=$(curl -s --max-time 2 http://127.0.0.1/nginx_status 2>/dev/null)
  if [ -n "$STUB" ]; then
    echo -e "  ${C}stub_status:${X}"
    echo "$STUB" | awk '{printf "    %s\n",$0}'
  else
    echo -e "  ${Y}stub_status not available on 127.0.0.1/nginx_status${X}"
  fi
  # Count active connections via ss
  CONN_TOTAL=$(ss -s 2>/dev/null | awk '/TCP:/{print $4}' | tr -d ',')
  CONN_EST=$(ss -tnp state established 2>/dev/null | wc -l)
  echo -e "  ${C}TCP established connections:${X} ${G}${CONN_EST}${X} / total sockets: ${CONN_TOTAL}"
else
  echo -e "  ${R}Nginx not found${X}"
fi

# ============================================================
# 9. DOCKER CONTAINERS
# ============================================================
head_ "DOCKER CONTAINERS"
if have docker; then
  echo -e "  ${C}CONTAINER NAME               STATUS          CPU%   MEM USAGE / LIMIT${X}"
  # docker stats --no-stream for live snapshot
  docker stats --no-stream --format \
    "  {{.Name}}\t{{.Status}}\t{{.CPUPerc}}\t{{.MemUsage}}" \
    2>/dev/null | awk '{
      printf "  \033[1;36m%-28s\033[0m %-16s %-7s %s\n", $1, $2, $3, $4
    }'
  echo ""
  echo -e "  ${C}All containers (including stopped):${X}"
  docker ps -a --format "  {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null | \
    awk '{
      status=$2
      color=(status~/Up/) ? "\033[1;32m" : "\033[1;31m"
      printf "  \033[1;36m%-28s\033[0m %s%-10s\033[0m  %s\n", $1, color, $2, $3
    }'
else
  echo -e "  ${Y}Docker not installed or not running${X}"
fi

# ============================================================
# 10. SERVICES STATUS (key services)
# ============================================================
head_ "KEY SERVICES STATUS"
SERVICES=(
  nginx mariadb mysql php8.1-fpm php8.2-fpm php8.3-fpm php8.4-fpm
  crowdsec crowdsec-firewall-bouncer netdata
  exim4 dovecot named postfix
  docker ssh cron
)
for SVC in "${SERVICES[@]}"; do
  if systemctl list-units --type=service --all 2>/dev/null | grep -q "${SVC}.service"; then
    STATE=$(systemctl is-active "$SVC" 2>/dev/null)
    ENABLED=$(systemctl is-enabled "$SVC" 2>/dev/null || echo "unknown")
    if   [ "$STATE" = "active" ];   then SC="$G"
    elif [ "$STATE" = "inactive" ]; then SC="$Y"
    else SC="$R"; fi
    printf "  ${C}%-35s${X} %b%-10s${X}  enabled: %s\n" "${SVC}" "$SC" "$STATE" "$ENABLED"
  fi
done

# ============================================================
# 11. CROWDSEC — current bans
# ============================================================
head_ "CROWDSEC — ACTIVE BANS"
if have cscli; then
  BAN_COUNT=$(cscli decisions list 2>/dev/null | grep -c 'ban' || echo 0)
  echo -e "  ${C}Total active bans:${X} ${R}${BAN_COUNT}${X}"
  echo -e "  ${C}Last 10 bans:${X}"
  cscli decisions list 2>/dev/null | head -12 | tail -10 | awk '{printf "  %s\n",$0}'
else
  echo -e "  ${Y}cscli not found${X}"
fi

# ============================================================
# 12. WP-LOGIN BRUTE FORCE — live attack log scan
# ============================================================
head_ "WP-LOGIN.PHP ATTACKS (last 24h in access logs)"
echo -e "  ${C}Hits  IP Address${X}"
grep -h "wp-login.php" \
  /var/www/*/data/logs/*access.log \
  /var/log/nginx/*.log 2>/dev/null | \
  awk '{print $1}' | \
  sort | uniq -c | sort -rn | head -15 | \
  awk '{
    color=(($1>100) ? "\033[1;31m" : (($1>20) ? "\033[1;33m" : "\033[1;37m"))
    printf "  %s%5d\033[0m  %s\n", color, $1, $2
  }'

# ============================================================
# 13. OPEN PORTS (listening)
# ============================================================
head_ "OPEN PORTS (LISTENING)"
ss -tlnp 2>/dev/null | awk 'NR>1{
  printf "  \033[1;36m%-28s\033[0m %s\n", $4, $NF
}' | head -30

# ============================================================
# 14. LAST LOGINS
# ============================================================
head_ "LAST LOGINS (last 5)"
last -n 5 2>/dev/null | head -5 | awk '{printf "  %s\n",$0}'

# ============================================================
# 15. FAILED SSH LOGINS (last 15 unique IPs)
# ============================================================
head_ "FAILED SSH LOGIN ATTEMPTS"
journal_cmd="journalctl -u ssh --since '24 hours ago' --no-pager -q 2>/dev/null"
if journalctl -u ssh --since '1 hour ago' --no-pager -q 2>/dev/null | grep -q 'Failed'; then
  echo -e "  ${C}Unique IPs with failed SSH (last 24h):${X}"
  journalctl -u ssh --since '24 hours ago' --no-pager -q 2>/dev/null | \
    grep 'Failed' | \
    grep -oP 'from \K[\d.]+' | \
    sort | uniq -c | sort -rn | head -15 | \
    awk '{printf "  \033[1;31m%5d\033[0m  %s\n", $1, $2}'
else
  echo -e "  ${G}No failed SSH logins in last 24h (or journal not available)${X}"
fi

# ============================================================
# 16. TOP 5 USERS BY DISK USAGE (/var/www)
# ============================================================
head_ "DISK USAGE BY SITE (/var/www — top 10)"
if [ -d /var/www ]; then
  du -sh /var/www/*/data/www 2>/dev/null | sort -rh | head -10 | \
    awk '{printf "  \033[1;36m%-12s\033[0m  %s\n", $1, $2}'
else
  echo -e "  ${Y}/var/www not found${X}"
fi

# ============================================================
# FOOTER
# ============================================================
echo ""
echo -e "${W}╔══════════════════════════════════════════════════════════╗${X}"
echo -e "${W}║  = Rooted by VladiMIR | AI =   v2026-04-10              ║${X}"
echo -e "${W}║  https://github.com/GinCz/Linux_Server_Public           ║${X}"
echo -e "${W}╚══════════════════════════════════════════════════════════╝${X}"
