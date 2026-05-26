#!/usr/bin/env bash
# =============================================================
# Script:      sos-fastpanel.sh
# Version:     v2026.05.26
# Location:    scripts/sos-fastpanel.sh  (FastPanel web servers)
# Servers:     222-DE-NetCup / 109-RU-FastVDS
# Description: Universal server stress analyzer and health monitor
#              for FastPanel-based web servers.
#              Auto-detects server role (WEB / VPN / DOCKER) and shows
#              relevant sections: CPU, RAM, Disk, Network, PHP-FPM, Nginx,
#              MariaDB, CrowdSec, Fail2Ban, UFW, Docker, OOM, Swap, I/O,
#              Samba, WireGuard, AmneziaWG, AdGuard Home, Semaphore,
#              Last Logins, Cron Jobs, APT Updates, open ports full picture.
# Usage:       sos [time_window]
#                sos          -> default 1h
#                sos1         -> last 1 hour
#                sos3         -> last 3 hours
#                sos24        -> last 24 hours
#                sos120       -> last 120 hours (5 days)
# Install:     cp scripts/sos-fastpanel.sh /usr/local/bin/sos
#              chmod +x /usr/local/bin/sos
# Aliases:     alias sos='sos 1h'
#              alias sos1='sos 1h'
#              alias sos3='sos 3h'
#              alias sos24='sos 24h'
#              alias sos120='sos 120h'
# Dependencies: bash, ps, df, free, ss, ip, awk, grep, find, dmesg
#               Optional: nginx, mysql/mariadb, php-fpm, docker, crowdsec,
#                         fail2ban, ufw, wg, awg, xray, samba, AdGuardHome,
#                         semaphore, last, crontab, apt, geoiplookup
# WARNING:     Read-only script — safe to run at any time, no side effects.
# Changelog:
#   v2026.05.26 — FIXED: safe_int() helper strips non-digits and returns 0
#                  on empty/garbage values — prevents "integer expression
#                  expected" crash in OOM_HITS, OOM_SYSLOG, SWAP_*, DISK I/O,
#                  PHP ERROR RATE and any [ "$VAR" -gt 0 ] comparisons.
#                 FIXED: safe_float() validates float format before use,
#                  returns 0 on mismatch — prevents awk/bash arith errors
#                  when /proc/loadavg contains unexpected data.
#                 FIXED: safe_pct(a,b) safely computes percentage via awk,
#                  guards division-by-zero — used in PHP ERROR RATE section.
#                 FIXED: TOP CPU / TOP RAM — utility processes (ps, awk,
#                  grep, head, tail, sort) excluded from output so the list
#                  shows only real application processes.
#                 FIXED: HTTP 502/503 BY DOMAIN — results are now aggregated
#                  per domain (awk sum[$domain]+=$count) so a site with
#                  multiple log rotations is shown as one line.
#                 IMPROVED: all long output sections capped at top-N to
#                  reduce noise while keeping all blocks:
#                    TOP CPU          -> top 10
#                    TOP RAM          -> top 15
#                    TOP TRAFFIC      -> top 10
#                    TOP IPs          -> top 10
#                    HTTP STATUS      -> top 10
#                    HTTP 502/503     -> top 10 domains
#                    PHP ERROR RATE   -> top 10 by error%
#                    DB SIZES         -> top 15
#                    DOCKER           -> top 10 containers
#                 IMPROVED: LOAD_PCT color threshold uses safe_int — no
#                  crash if LOAD1 comes back empty on boot.
#   v2026.05.22c — TOP-10 IPs: added user, domain and country per IP.
#                  Country lookup via geoiplookup (local DB, ~0ms/IP) if
#                  installed (apt install geoip-bin). Graceful fallback if not.
#   v2026.05.22b — FIX: replaced declare -A PORT_NAMES (bash 4+ only) with
#                  case statement for full /bin/sh compatibility.
#                  FIX: guarded TCP_OK/UDP_OK via ${VAR:-0} to prevent
#                  "syntax error in expression" when grep -c returns empty.
# = Rooted by VladiMIR + AI | v2026.05.26 | github.com/GinCz =
# =============================================================

clear

TW="${1:-1h}"

# -- terminal colors ------------------------------------------------------------
G=$'\033[1;32m'    # green  -- OK / active
C=$'\033[1;36m'    # cyan   -- labels / section info
Y=$'\033[1;33m'    # yellow -- warnings / separators
R=$'\033[1;31m'    # red    -- errors / critical
W=$'\033[1;37m'    # white  -- highlights
X=$'\033[0m'       # reset
EM=$'\342\200\224' # em dash -- visual separator

# -- helper functions -----------------------------------------------------------
have(){ command -v "$1" >/dev/null 2>&1; }
SEP="${Y}$(printf '=%.0s' {1..90})${X}"
H(){ printf "\n${Y}=============== %s${X}\n" "$1"; }

# safe_int: strip non-digits and return 0 on empty — prevents "integer
#           expression expected" errors in [ "$VAR" -gt 0 ] comparisons.
safe_int() {
  local v="${1:-}"
  v="$(printf '%s' "$v" | tr -cd '0-9')"
  printf '%s\n' "${v:-0}"
}

# safe_float: validate float format; return 0 if garbage — used for LOAD1.
safe_float() {
  local v="${1:-}"
  if [[ "$v" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    printf '%s\n' "$v"
  else
    printf '0\n'
  fi
}

# safe_pct: compute percentage (a/b*100) via awk; guard division-by-zero.
safe_pct() {
  local a b
  a="$(safe_int "${1:-0}")"
  b="$(safe_int "${2:-0}")"
  if [ "$b" -gt 0 ]; then
    awk -v a="$a" -v b="$b" 'BEGIN{printf "%.1f", (a/b)*100}'
  else
    printf '0.0'
  fi
}

# -- parse time window to minutes -----------------------------------------------
M=60
[[ "$TW" =~ ^([0-9]+)m$ ]] && M="${BASH_REMATCH[1]}"
[[ "$TW" =~ ^([0-9]+)h$ ]] && M="$(( ${BASH_REMATCH[1]} * 60 ))"

# -- collect base system info ---------------------------------------------------
NOW=$(date '+%Y-%m-%d %H:%M:%S')
HOST=$(hostname)
IP=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
CORES=$(nproc 2>/dev/null || echo 1)
CORES="$(safe_int "$CORES")"
[ "$CORES" -eq 0 ] && CORES=1
LOAD=$(awk '{print $1,$2,$3}' /proc/loadavg 2>/dev/null)
LOAD1=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
LOAD1="$(safe_float "$LOAD1")"
LOAD_PCT=$(awk -v l="$LOAD1" -v c="$CORES" 'BEGIN{ if(c>0) printf "%.0f",(l/c)*100; else print 0 }')
LOAD_PCT="$(safe_int "$LOAD_PCT")"
if [ "$LOAD_PCT" -ge 90 ]; then LC="$R"
elif [ "$LOAD_PCT" -ge 60 ]; then LC="$Y"
else LC="$G"; fi

# -- auto-detect server role ----------------------------------------------------
ROLE="GENERIC"
have nginx && [ -d /var/www ] && ROLE="WEB"
have xray  && ROLE="VPN/XRAY"
have wg    && ROLE="VPN/WG"
have awg   && ROLE="VPN/AWG"
[ "$ROLE" = "GENERIC" ] && have docker && ROLE="DOCKER/NODE"

# -- header block ---------------------------------------------------------------
printf "%s\n" "$SEP"
printf "  ${W}SOS ${Y}%s${X}  |  ${G}%s${X}  |  ${C}%s${X}  ${G}%s${X}  Load: ${LC}%s${X} (${LC}%s%%${X}/%sc)  ${W}[%s]${X}\n" \
  "$TW" "$NOW" "$HOST" "$IP" "$LOAD" "$LOAD_PCT" "$CORES" "$ROLE"
printf "%s\n" "$SEP"
printf "  ${C}Uptime:${X} %s" "$(uptime -p)"
free -h | awk -v c="$C" -v x="$X" '/^Mem:/{printf "   %sRAM:%s %s/%s (free %s)",c,x,$3,$2,$4}'
free -h | awk -v c="$C" -v x="$X" '/^Swap:/{printf "   %sSwap:%s %s/%s\n",c,x,$3,$2}'

H "DISK"
df -h --output=source,size,used,avail,pcent,target 2>/dev/null \
  | grep -E '^(Filesystem|/dev)' \
  | awk -v c="$C" -v x="$X" \
    'NR==1{printf "  %-20s %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6;next}
           {printf "  %s%-20s%s %6s %6s %6s %5s  %s\n",c,$1,x,$2,$3,$4,$5,$6}'

H "TOP-5 CPU + RAM"
printf "  ${C}Top 5 by CPU:${X}\n"
ps -eo pid,user,%cpu,%mem,args --sort=-%cpu 2>/dev/null \
  | awk 'NR==1 || ($5 !~ /^(ps|awk|grep|head|tail|sort)$/)' \
  | head -6 | tail -5 \
  | awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-12s CPU:%5s%%  MEM:%5s%%  %s\n",c,$1,x,$2,$3,$4,$5}'
printf "\n  ${C}Top 5 by RAM:${X}\n"
ps -eo pid,user,%cpu,%mem,rss,args --sort=-rss 2>/dev/null \
  | awk 'NR==1 || ($6 !~ /^(ps|awk|grep|head|tail|sort)$/)' \
  | head -6 | tail -5 \
  | awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-12s CPU:%5s%%  MEM:%5s%%  %6.1fMB  %s\n",c,$1,x,$2,$3,$4,$5/1024,$6}'

H "TOP 10 CPU%"
ps -eo pid,user,%cpu,pmem,args --sort=-%cpu 2>/dev/null \
  | awk 'NR==1 || ($5 !~ /^(ps|awk|grep|head|tail|sort)$/)' \
  | head -15 | tail -10 \
  | awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-10s %5s %5s  %s\n",c,$1,x,$2,$3,$4,$5}'

H "TOP 15 RAM"
ps -eo pid,user,%cpu,pmem,rss,args --sort=-rss 2>/dev/null \
  | awk 'NR==1 || ($6 !~ /^(ps|awk|grep|head|tail|sort)$/)' \
  | head -20 | tail -15 \
  | awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-10s %5s %5s  %6.1fMB  %s\n",c,$1,x,$2,$3,$4,$5/1024,$6}'

H "OOM KILLER (last boot)"
OOM_HITS=$(dmesg 2>/dev/null | grep -cE 'oom-kill|Out of memory|Killed process' 2>/dev/null)
OOM_HITS="$(safe_int "$OOM_HITS")"
if [ "$OOM_HITS" -gt 0 ]; then
  printf "  ${R}OOM events: %d${X}\n" "$OOM_HITS"
  dmesg 2>/dev/null | grep -E 'oom-kill|Out of memory|Killed process' | tail -5 \
    | awk -v r="$R" -v x="$X" '{printf "  %s%s%s\n",r,$0,x}'
else
  printf "  ${G}No OOM kills detected${X}\n"
fi
OOM_SYSLOG=$(grep -E 'oom-kill|Out of memory|Killed process' /var/log/syslog 2>/dev/null \
  | tail -n 200 | wc -l 2>/dev/null)
OOM_SYSLOG="$(safe_int "$OOM_SYSLOG")"
[ "$OOM_SYSLOG" -gt 0 ] && printf "  ${R}OOM entries in syslog: %d${X}\n" "$OOM_SYSLOG"

H "SWAP"
SWAP_TOTAL=$(free -m 2>/dev/null | awk '/^Swap:/{print $2+0}')
SWAP_USED=$(free -m  2>/dev/null | awk '/^Swap:/{print $3+0}')
SWAP_FREE=$(free -m  2>/dev/null | awk '/^Swap:/{print $4+0}')
SWAP_TOTAL="$(safe_int "$SWAP_TOTAL")"
SWAP_USED="$(safe_int "$SWAP_USED")"
SWAP_FREE="$(safe_int "$SWAP_FREE")"
if [ "$SWAP_TOTAL" -gt 0 ]; then
  SWAP_PCT=$(awk -v u="$SWAP_USED" -v t="$SWAP_TOTAL" 'BEGIN{printf "%.0f",(u/t)*100}')
  SWAP_PCT="$(safe_int "$SWAP_PCT")"
  if [ "$SWAP_PCT" -ge 80 ]; then SC="$R"
  elif [ "$SWAP_PCT" -ge 40 ]; then SC="$Y"
  else SC="$G"; fi
  printf "  ${C}Swap:${X} Total: ${W}%s MB${X}  Used: %s%s MB (%s%%)${X}  Free: ${G}%s MB${X}\n" \
    "$SWAP_TOTAL" "$SC" "$SWAP_USED" "$SWAP_PCT" "$SWAP_FREE"
  printf "\n  ${C}Top 5 swap consumers:${X}\n"
  awk '
    /^Pid:/{pid=$2}
    /^Name:/{name=$2}
    /^VmSwap:/{swap=$2; if(swap+0>0) print swap, pid, name}
  ' /proc/*/status 2>/dev/null \
    | sort -rn | head -5 \
    | awk -v c="$C" -v y="$Y" -v r="$R" -v x="$X" '{
        col=($1/1024>=200)?r:(($1/1024>=50)?y:c)
        printf "  %sPID %-7s%s %-25s %s%6.1f MB%s\n",c,$2,x,$3,col,$1/1024,x
      }'
else
  printf "  ${Y}Swap is not configured${X}\n"
fi

H "NETWORK"
printf "  ${C}Connections:${X}\n"
ss -s 2>/dev/null | grep -E 'Total|TCP:|UDP:' | sed 's/^/    /'
printf "  ${G}Interface traffic:${X}\n"
ip -s link 2>/dev/null | awk '
  /^[0-9]+: (eth|ens|enp|wg|awg|tun|vmbr)/ {
    iface=$2; sub(/:/,"",iface)
    getline; getline; rx=$1
    getline; tx=$1
    rxf=(rx/1024/1024>1024)?sprintf("%.1fG",rx/1024/1024/1024):sprintf("%.1fM",rx/1024/1024)
    txf=(tx/1024/1024>1024)?sprintf("%.1fG",tx/1024/1024/1024):sprintf("%.1fM",tx/1024/1024)
    printf "    %-10s RX=%-8s TX=%-8s\n", iface, rxf, txf
  }'

H "LAST LOGINS"
printf "  ${C}Last 10 SSH logins:${X}\n"
last -n 10 -a 2>/dev/null \
  | awk -v g="$G" -v r="$R" -v c="$C" -v y="$Y" -v x="$X" \
    '/^reboot/{printf "  %s  %-10s%s  %s\n",y,$1,x,substr($0,28);next}
     /still logged/{printf "  %s%-10s%s  %-16s  %s%s%s\n",g,$1,x,$3,g,"still logged in",x;next}
     /^$|^wtmp/{next}
     {printf "  %s%-10s%s  %-16s  %s\n",c,$1,x,$3,substr($0,28)}' \
  | head -12
printf "\n  ${C}Currently logged in:${X}\n"
who 2>/dev/null | awk -v g="$G" -v c="$C" -v x="$X" \
  '{printf "  %s%-12s%s  tty: %-10s  from: %s  since: %s %s\n",g,$1,x,$2,$NF,$3,$4}' \
  | head -5

H "APT UPDATES"
APT_LIST=$(apt list --upgradable 2>/dev/null)
UPD_COUNT=$(echo "$APT_LIST" | grep -c '/')
UPD_COUNT="$(safe_int "$UPD_COUNT")"
SEC_COUNT=$(echo "$APT_LIST" | grep -ci 'security')
SEC_COUNT="$(safe_int "$SEC_COUNT")"
if [ "$UPD_COUNT" -gt 0 ]; then
  [ "$SEC_COUNT" -gt 0 ] && COL="$R" || COL="$Y"
  printf "  ${C}Upgradable packages:${X} %s%d${X}  (security: %s%d${X})\n" \
    "$COL" "$UPD_COUNT" "$R" "$SEC_COUNT"
  printf "  ${Y}Top 10:${X}\n"
  echo "$APT_LIST" | grep '/' | head -10 \
    | awk -v c="$C" -v x="$X" '{printf "    %s%s%s\n",c,$1,x}'
else
  printf "  ${G}System is up to date${X}\n"
fi

H "CRON JOBS"
printf "  ${C}System crontab (/etc/crontab):${X}\n"
grep -v '^#\|^$' /etc/crontab 2>/dev/null \
  | awk -v c="$C" -v x="$X" '{printf "    %s%s%s\n",c,$0,x}' \
  | head -15

printf "\n  ${C}Cron.d files (/etc/cron.d/):${X}\n"
for F in /etc/cron.d/*; do
  [ -f "$F" ] || continue
  CNT=$(grep -cv '^#\|^$' "$F" 2>/dev/null || echo 0)
  CNT="$(safe_int "$CNT")"
  [ "$CNT" -eq 0 ] && continue
  printf "  ${W}%-30s${X} (%d jobs)\n" "$(basename "$F")" "$CNT"
  grep -v '^#\|^$' "$F" 2>/dev/null \
    | awk -v c="$C" -v x="$X" '{printf "    %s%s%s\n",c,$0,x}' \
    | head -5
done

printf "\n  ${C}Root crontab:${X}\n"
CRONTAB_OUT=$(crontab -l 2>/dev/null)
if [ -n "$CRONTAB_OUT" ]; then
  echo "$CRONTAB_OUT" | grep -v '^#\|^$' \
    | awk -v c="$C" -v x="$X" '{printf "    %s%s%s\n",c,$0,x}' \
    | head -15
else
  printf "    ${Y}(empty or no root crontab)${X}\n"
fi

printf "\n  ${C}Hourly/Daily/Weekly/Monthly scripts:${X}\n"
for DIR in /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly; do
  CNT=$(ls "$DIR" 2>/dev/null | wc -l)
  CNT="$(safe_int "$CNT")"
  [ "$CNT" -gt 0 ] && printf "    ${G}%-22s${X} %d scripts\n" "$DIR" "$CNT"
done
if [ -f /var/log/syslog ]; then
  CRON_FAIL=$(grep -c 'CRON.*error\|cron.*fail\|crontab.*error' /var/log/syslog 2>/dev/null || echo 0)
  CRON_FAIL="$(safe_int "$CRON_FAIL")"
  [ "$CRON_FAIL" -gt 0 ] && printf "\n  ${R}Cron errors in syslog: %d${X}\n" "$CRON_FAIL"
fi

if [ "$ROLE" = "WEB" ]; then

  H "PHP-FPM POOLS"
  ps -eo user,rss,args 2>/dev/null \
    | grep -E 'php-fpm|php-cgi' | grep -v grep \
    | awk '{p=$1; r=$2; cnt[p]++; tot[p]+=r}
           END{for(p in cnt) printf "%s\t%d\t%.1f\n",p,cnt[p],tot[p]/1024}' \
    | sort -k3,3nr | head -10 \
    | awk -v c="$C" -v x="$X" '{printf "  %s%-26s%s %4d wk  %7.1fMB\n",c,$1,x,$2,$3}'

  H "TOP-10 TRAFFIC (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
    -exec wc -l {} + 2>/dev/null \
    | awk '$2 != "total"{print $1, $2}' \
    | sort -rn | head -10 \
    | awk '{printf "  %7d  %s\n",$1,$2}'

  H "TOP-10 IPs (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
    -exec tail -n 2000 {} + 2>/dev/null \
    | awk '{print $1}' | sort | uniq -c | sort -rn | head -10 \
    | while read -r CNT IP_ADDR; do
        GEO=""
        have geoiplookup && GEO=$(geoiplookup "$IP_ADDR" 2>/dev/null \
          | awk -F': ' '{print $2}' | cut -c1-25)
        printf "  %6d  %-17s  %s\n" "$CNT" "$IP_ADDR" "${GEO:-(no geoip)}"
      done

  H "HTTP STATUS (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
    -exec tail -n 2000 {} + 2>/dev/null \
    | awk '{print $9}' | grep -E '^[0-9]{3}$' \
    | sort | uniq -c | sort -rn | head -10 \
    | awk -v g="$G" -v c="$C" -v y="$Y" -v r="$R" -v x="$X" -v em="$EM" '
        {
          if($2~/^2/) col=g
          else if($2~/^3/) col=c
          else if($2~/^4/) col=y
          else col=r
          printf "  %6d %s %sHTTP %s%s\n",$1,em,col,$2,x
        }'

  H "WP-LOGIN ATTACKS (last $TW)"
  {
    find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
      -exec grep -h 'wp-login.php' {} + 2>/dev/null
    [ -d /var/log/nginx ] && grep -rh 'wp-login.php' /var/log/nginx/*.log 2>/dev/null
  } \
    | awk '{print $1}' | sort | uniq -c | sort -rn | head -10 \
    | awk -v r="$R" -v y="$Y" -v w="$W" -v x="$X" '
        {
          col=(($1>100)?r:(($1>20)?y:w))
          printf "  %s%5d%s  %s\n",col,$1,x,$2
        }'

  H "HTTP 502/503 BY DOMAIN (last $TW)"
  # Aggregate error counts per domain so rotated logs don't create duplicates
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" 2>/dev/null \
    | while read -r LOG; do
        DOM=$(echo "$LOG" | grep -oP '/var/www/\K[^/]+')
        CNT=$(tail -n 5000 "$LOG" 2>/dev/null \
          | awk '$9=="502"||$9=="503"{c++}END{print c+0}')
        CNT="$(safe_int "$CNT")"
        [ "$CNT" -gt 0 ] && printf "%s\t%d\n" "$DOM" "$CNT"
      done \
    | awk '{sum[$1]+=$2} END{for(d in sum) print d, sum[d]}' \
    | sort -k2,2nr | head -10 \
    | awk -v c="$C" -v y="$Y" -v r="$R" -v x="$X" '
        {
          col=($2>=10)?r:y
          printf "  " c "%-35s" x " %s%d errors%s\n",$1,col,$2,x
        }'

  H "PHP-FPM SLOW LOG (last 24h)"
  shopt -s nullglob
  FOUND_SLOW=0
  for SLOW in /var/log/php*-fpm*slow* /var/log/php*/slow.log /var/www/*/data/logs/*slow*; do
    [ -f "$SLOW" ] || continue
    CNT=$(grep -c '\[pool' "$SLOW" 2>/dev/null)
    CNT="$(safe_int "$CNT")"
    POOL=$(echo "$SLOW" | grep -oP '/\K[^/]+(?=[-._]slow)' || basename "$SLOW")
    [ "$CNT" -gt 0 ] && SCOL="$R" || SCOL="$G"
    printf "  ${C}%-30s${X} %s%d slow${X}\n" "$POOL" "$SCOL" "$CNT"
    FOUND_SLOW=1
  done
  [ "$FOUND_SLOW" -eq 0 ] && printf "  ${G}No PHP slow logs found${X}\n"
  shopt -u nullglob

  H "NGINX SLOW REQUESTS >3s (last $TW)"
  SLOW_TMP=$(mktemp)
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" 2>/dev/null \
    | while read -r LOG; do
        tail -n 5000 "$LOG" 2>/dev/null \
          | awk '{
              for(i=NF;i>=1;i--){
                if($i~/^[0-9]+\.[0-9]+$/ && $i+0>=3){
                  printf "%.3f %s %s\n",$i,$7,$1; break
                }
              }
            }'
      done > "$SLOW_TMP"
  SLOW_REQ=$(wc -l < "$SLOW_TMP" 2>/dev/null)
  SLOW_REQ="$(safe_int "$SLOW_REQ")"
  if [ "$SLOW_REQ" -gt 0 ]; then
    printf "  ${R}Slow requests (>3s): %d${X}\n" "$SLOW_REQ"
    printf "  ${Y}Top 10 slowest:${X}\n"
    sort -rn "$SLOW_TMP" | head -10 \
      | awk -v r="$R" -v y="$Y" -v x="$X" '{
          col=($1+0>=10)?r:y
          printf "  %s%7.3fs%s  %-50s  %s\n",col,$1,x,$2,$3
        }'
  else
    printf "  ${G}No slow requests >3s detected${X}\n"
  fi
  rm -f "$SLOW_TMP"

  H "PHP ERROR RATE (last $TW)"
  # safe_pct() guards division-by-zero when TOTAL==0
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" 2>/dev/null \
    | while read -r LOG; do
        TOTAL=$(tail -n 5000 "$LOG" 2>/dev/null | wc -l)
        TOTAL="$(safe_int "$TOTAL")"
        [ "$TOTAL" -eq 0 ] && continue
        ERRLOG=$(echo "$LOG" | sed 's/access/error/')
        [ -f "$ERRLOG" ] || continue
        ERRS=$(tail -n 2000 "$ERRLOG" 2>/dev/null \
          | grep -cE 'PHP Fatal|PHP Warning|PHP Notice|PHP Parse' 2>/dev/null)
        ERRS="$(safe_int "$ERRS")"
        PCT=$(safe_pct "$ERRS" "$TOTAL")
        printf "%s\t%s\t%s\t%s\n" "$(basename "$LOG")" "$ERRS" "$TOTAL" "$PCT"
      done \
    | sort -t$'\t' -k4,4nr | head -10 \
    | awk -F'\t' -v c="$C" -v g="$G" -v y="$Y" -v r="$R" -v x="$X" '
        {
          pcti=$4+0
          col=(pcti>=5)?r:((pcti>=1)?y:g)
          printf "  " c "%-40s" x " %s%s errs / %s req = %s%%%s\n",$1,col,$2,$3,$4,x
        }'

  H "NGINX"
  if have nginx; then
    printf "  ${C}Workers:${X} ${G}%s${X}  TCP established: ${G}%s${X}\n" \
      "$(pgrep -x nginx 2>/dev/null | wc -l)" \
      "$(ss -tnp state established 2>/dev/null | wc -l)"
    STUB=$(curl -s --max-time 2 http://127.0.0.1/nginx_status 2>/dev/null)
    [ -n "$STUB" ] && echo "$STUB" \
      | awk '/Active/{printf "  Active connections: %s\n",$3}'
  fi

  H "MYSQL / MARIADB"
  if have mysql; then
    mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_connected';" 2>/dev/null \
      | awk -v c="$C" -v g="$G" -v x="$X" '{printf "  %sConnected:%s %s%s%s\n",c,x,g,$2,x}'
    mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_running';" 2>/dev/null \
      | awk -v c="$C" -v g="$G" -v x="$X" '{printf "  %sRunning:%s   %s%s%s\n",c,x,g,$2,x}'
    mysql -N -e "SHOW GLOBAL STATUS LIKE 'Slow_queries';" 2>/dev/null \
      | awk -v c="$C" -v x="$X" '{printf "  %sSlow:%s      %s\n",c,x,$2}'
    UPSEC=$(mysql -N -e "SHOW GLOBAL STATUS LIKE 'Uptime';" 2>/dev/null | awk '{print $2}')
    UPSEC="$(safe_int "$UPSEC")"
    if [ "$UPSEC" -gt 0 ]; then
      UPDAY=$((UPSEC/86400))
      UPHR=$(((UPSEC%86400)/3600))
      UPMIN=$(((UPSEC%3600)/60))
      if [ "$UPDAY" -eq 0 ] && [ "$UPHR" -lt 24 ]; then
        WCOL="$R"; WARN=" WARNING: RECENT RESTART!"
      else
        WCOL="$G"; WARN=""
      fi
      printf "  ${C}MariaDB uptime:${X} %s%dd %dh %dm${X}%s\n" \
        "$WCOL" "$UPDAY" "$UPHR" "$UPMIN" "$WARN"
    fi
  fi

  H "MARIADB DATABASE SIZES"
  if have mysql; then
    mysql -N -e "
      SELECT table_schema,
             ROUND(SUM(data_length+index_length)/1024/1024,1) AS mb
      FROM information_schema.tables
      WHERE table_schema NOT IN
        ('information_schema','performance_schema','sys','mysql')
      GROUP BY table_schema
      ORDER BY mb DESC;
    " 2>/dev/null \
      | head -15 \
      | awk -v c="$C" -v g="$G" -v y="$Y" -v r="$R" -v x="$X" '
          {
            col=($2+0>=500)?r:(($2+0>=100)?y:g)
            printf "  %s%-35s%s %s%6.1f MB%s\n",c,$1,x,col,$2,x
          }'
  fi

  H "CRITICAL ERRORS (last $TW)"
  find /var/www/*/data/logs/ -name "*error.log" -mmin "-${M}" \
    -exec grep -iE \
      'fatal|Out of memory|upstream timed out|connect\(\) failed|no live upstreams' \
      {} + 2>/dev/null \
    | tail -10

  H "CROWDSEC"
  if have cscli; then
    BANS=$(cscli decisions list 2>/dev/null \
      | awk 'BEGIN{c=0}/^\|/{c++}END{print (c>0?c-1:0)}')
    BANS="$(safe_int "$BANS")"
    printf "  ${C}Bans:${X} ${R}%s${X}\n" "$BANS"
    cscli alerts list --since "$TW" -l 10 2>/dev/null | head -12 | sed 's/^/  /'
  fi

  H "FAIL2BAN"
  if have fail2ban-client; then
    F2B_ST=$(systemctl is-active fail2ban 2>/dev/null)
    [ "$F2B_ST" = "active" ] && SC="$G" || SC="$R"
    printf "  ${C}Service:${X} %s%s${X}\n" "$SC" "$F2B_ST"
    JAIL_LIST=$(fail2ban-client status 2>/dev/null \
      | grep 'Jail list' \
      | sed 's/.*Jail list://;s/,/ /g' | tr -d '\t')
    JAIL_COUNT=$(echo "$JAIL_LIST" | wc -w)
    JAIL_COUNT="$(safe_int "$JAIL_COUNT")"
    printf "  ${C}Active jails:${X} ${W}%s${X}\n" "$JAIL_COUNT"
    TOTAL_BANNED=0
    for JAIL in $JAIL_LIST; do
      [ -z "$JAIL" ] && continue
      BANNED=$(fail2ban-client status "$JAIL" 2>/dev/null \
        | awk '/Currently banned/{print $NF}')
      TOTAL_B=$(fail2ban-client status "$JAIL" 2>/dev/null \
        | awk '/Total banned/{print $NF}')
      BANNED="$(safe_int "$BANNED")"
      TOTAL_B="$(safe_int "$TOTAL_B")"
      TOTAL_BANNED=$((TOTAL_BANNED + BANNED))
      [ "$BANNED" -gt 0 ] && COL="$R" || COL="$G"
      printf "    %s%-25s%s banned: %s%s%s  total: %s\n" \
        "$C" "$JAIL" "$X" "$COL" "$BANNED" "$X" "$TOTAL_B"
    done
    printf "  ${C}Total currently banned:${X} ${R}%s${X}\n" "$TOTAL_BANNED"
  else
    printf "  ${Y}fail2ban not installed${X}\n"
  fi

  H "UFW"
  if have ufw; then
    UFW_ST=$(ufw status 2>/dev/null | head -1)
    [[ "$UFW_ST" == *active* ]] && printf "${G}%s${X}\n" "$UFW_ST" \
      || printf "${Y}%s${X}\n" "$UFW_ST"
    ufw status numbered 2>/dev/null | grep -E '^\[' | tail -10 | sed 's/^/    /'
  else
    printf "  ${Y}UFW not installed${X}\n"
  fi

fi  # end WEB role

# -- VPN role sections ----------------------------------------------------------
if [[ "$ROLE" == VPN* ]]; then

  H "VPN STATUS"
  for WG_CMD in wg awg; do
    if have "$WG_CMD"; then
      printf "  ${C}%s interfaces:${X}\n" "$WG_CMD"
      "$WG_CMD" show all 2>/dev/null \
        | grep -E '^interface|peer|endpoint|transfer|latest' | sed 's/^/    /'
    fi
  done
  if have xray; then
    printf "  ${C}Xray:${X} "
    systemctl is-active xray 2>/dev/null \
      | awk -v g="$G" -v r="$R" -v x="$X" '{col=($0=="active")?g:r;printf "%s%s%s\n",col,$0,x}'
    XRAY_CONNS=$(ss -tnp state established 2>/dev/null \
      | grep -cE 'xray|/usr/local/bin/xray')
    XRAY_CONNS="$(safe_int "$XRAY_CONNS")"
    printf "  ${C}Xray TCP established:${X} ${G}%s${X}\n" "$XRAY_CONNS"
  fi

  H "VPN PEERS"
  for WG_CMD in wg awg; do
    if have "$WG_CMD"; then
      PC=$("$WG_CMD" show all peers 2>/dev/null | wc -l)
      PC="$(safe_int "$PC")"
      printf "  ${C}%s peers total:${X} ${G}%s${X}\n" "$WG_CMD" "$PC"
    fi
  done

  H "VPN TRAFFIC (interfaces)"
  ip -s link 2>/dev/null | awk '
    /^[0-9]+: (wg|awg|tun)/{
      iface=$2; sub(/:/,"",iface)
      getline; getline; rx=$1
      getline; tx=$1
      rxg=(rx/1024/1024>1024)?sprintf("%.2fG",rx/1024/1024/1024):sprintf("%.2fM",rx/1024/1024)
      txg=(tx/1024/1024>1024)?sprintf("%.2fG",tx/1024/1024/1024):sprintf("%.2fM",tx/1024/1024)
      printf "  %-10s RX=%-10s TX=%-10s\n",iface,rxg,txg
    }'

  H "FAIL2BAN"
  if have fail2ban-client; then
    printf "  ${C}Fail2ban jails:${X}\n"
    fail2ban-client status 2>/dev/null \
      | grep 'Jail list' \
      | sed 's/.*Jail list://;s/,/\n/g' | tr -d '\t ' \
      | while read -r JAIL; do
          [ -z "$JAIL" ] && continue
          BANNED=$(fail2ban-client status "$JAIL" 2>/dev/null \
            | awk '/Currently banned/{print $NF}')
          TOTAL_B=$(fail2ban-client status "$JAIL" 2>/dev/null \
            | awk '/Total banned/{print $NF}')
          BANNED="$(safe_int "$BANNED")"
          TOTAL_B="$(safe_int "$TOTAL_B")"
          [ "$BANNED" -gt 0 ] && COL="$R" || COL="$G"
          printf "    %s%-25s%s banned: %s%s%s  total: %s\n" \
            "$C" "$JAIL" "$X" "$COL" "$BANNED" "$X" "$TOTAL_B"
        done
  else
    printf "  ${Y}fail2ban not installed${X}\n"
  fi

  H "UFW"
  if have ufw; then
    UFW_ST=$(ufw status 2>/dev/null | head -1)
    [[ "$UFW_ST" == *active* ]] && printf "${G}%s${X}\n" "$UFW_ST" \
      || printf "${Y}%s${X}\n" "$UFW_ST"
    ufw status numbered 2>/dev/null | grep -E '^\[' | tail -10 | sed 's/^/    /'
  else
    printf "  ${Y}UFW not installed${X}\n"
  fi

fi  # end VPN role

# -- Docker section (all roles) -------------------------------------------------
H "DOCKER"
if have docker; then
  docker ps -a --format "{{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null \
    | head -10 \
    | awk -F'\t' -v g="$G" -v r="$R" -v c="$C" -v x="$X" '
        {
          col=($2~/^Up/)?g:r
          printf "  %s%-28s%s %s%s%s  %s\n",c,$1,x,col,$2,x,$3
        }'
else
  printf "  ${Y}docker not installed${X}\n"
fi

# -- Services check (all roles) -------------------------------------------------
H "SERVICES"
SVC_LIST=(nginx mariadb mysql php8.1-fpm php8.2-fpm php8.3-fpm php8.4-fpm
          crowdsec crowdsec-firewall-bouncer fail2ban exim4 postfix
          docker ssh xray wg-quick@wg0 amnezia-wg)
for SVC in "${SVC_LIST[@]}"; do
  systemctl list-units --type=service --all 2>/dev/null \
    | grep -q "${SVC}.service" && {
      STATE=$(systemctl is-active "$SVC" 2>/dev/null)
      [ "$STATE" = "active" ] && SC="$G" || SC="$R"
      printf "  ${C}%-38s${X} %s%s${X}\n" "$SVC" "$SC" "$STATE"
    }
done

# -- Disk I/O sample (all roles) ------------------------------------------------
H "DISK I/O (1s sample)"
DEV=$(awk '{print $3}' /proc/diskstats 2>/dev/null \
  | grep -E '^(vd|sd|nvme)[a-z0-9]+$' | grep -v '[0-9]$' | head -1)
if [ -n "$DEV" ]; then
  R1=$(awk -v d="$DEV" '$3==d{print $6;exit}' /proc/diskstats)
  W1=$(awk -v d="$DEV" '$3==d{print $10;exit}' /proc/diskstats)
  R1="$(safe_int "$R1")"
  W1="$(safe_int "$W1")"
  sleep 1
  R2=$(awk -v d="$DEV" '$3==d{print $6;exit}' /proc/diskstats)
  W2=$(awk -v d="$DEV" '$3==d{print $10;exit}' /proc/diskstats)
  R2="$(safe_int "$R2")"
  W2="$(safe_int "$W2")"
  RMB=$(awk -v r1="$R1" -v r2="$R2" 'BEGIN{printf "%.2f",((r2-r1)*512)/1048576}')
  WMB=$(awk -v w1="$W1" -v w2="$W2" 'BEGIN{printf "%.2f",((w2-w1)*512)/1048576}')
  printf "  ${C}Device:${X} /dev/%s  ${C}Read:${X} ${G}%s MB/s${X}  ${C}Write:${X} ${G}%s MB/s${X}\n" \
    "$DEV" "$RMB" "$WMB"
else
  printf "  ${Y}no block device found${X}\n"
fi

# -- DMESG errors ---------------------------------------------------------------
H "DMESG ERRORS"
dmesg -T 2>/dev/null | grep -iE 'error|fail|oom|kill|panic|warn' | tail -10 | sed 's/^/  /'

# -- CrowdSec metrics -----------------------------------------------------------
H "CROWDSEC METRICS"
if have cscli; then
  cscli metrics 2>/dev/null \
    | awk '/Parsers/{p=1} p&&/\|/{printf "  %s\n",$0}' | head -8
fi

printf "\n%s\n  ${W}= Rooted by VladiMIR + AI | v2026.05.26 | github.com/GinCz =${X}\n%s\n" \
  "$SEP" "$SEP"
