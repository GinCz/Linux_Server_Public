#!/usr/bin/env bash
# =============================================================
# Script:      sos-fastpanel.sh
# Version:     v2026.06.09
# Location:    scripts/sos-fastpanel.sh  (FastPanel web servers)
# Servers:     222-DE-NetCup / 109-RU-FastVDS
# Description: Universal server stress analyzer and health monitor
#              for FastPanel-based web servers.
# Usage:       sos [time_window]
# Install:     cp scripts/sos-fastpanel.sh /usr/local/bin/sos && chmod +x /usr/local/bin/sos
# Changelog:
#   v2026.06.09 — VPN STATUS: added explicit x-ui (3x-ui panel) check via systemctl +
#                  active client count via ss. SERVICES: priority block at top showing
#                  x-ui, xray, smbd, nmbd, crowdsec, fail2ban before dynamic list.
#   v2026.05.29b — FIX: OPEN PORTS — awk regexp escape caused wrong port numbers.
#                  New approach: ss -tlnup | grep LISTEN, extract port with rev/cut.
#                  FIX: SERVICES — filter out systemd-*, multipathd, networkd-*,
#                  unattended-*, rsyslog, qemu-*, cron from display (system noise).
#                  FIX: DOCKER — removed trailing dash artifact from image column.
#                  VISUAL: removed gray color ($D), all text is white ($W) or cyan ($C).
#                  SEP/H use exactly 90 '=' chars in yellow.
#   v2026.05.29  — DOCKER ports column, SERVICES dynamic, PORTS section, SAMBA users.
#   v2026.05.28c — FIX HTTP 502/503 substr 17 chars.
# = Rooted by VladiMIR + AI | v.2026.06.09 | github.com/GinCz =
# =============================================================

clear

TW="${1:-1h}"

# -- terminal colors ------------------------------------------------------------
G=$'\033[1;32m'    # green   -- OK / active
C=$'\033[1;36m'    # cyan    -- labels
Y=$'\033[1;33m'    # yellow  -- separators / warnings
R=$'\033[1;31m'    # red     -- errors / critical
W=$'\033[1;37m'    # white   -- highlights (replaces gray)
X=$'\033[0m'       # reset
EM=$'\342\200\224' # em dash

# -- helper functions -----------------------------------------------------------
have(){ command -v "$1" >/dev/null 2>&1; }

# Exactly 90 '=' chars in yellow
SEP="${Y}$(printf '=%.0s' {1..90})${X}"

# Section header: yellow '=============== TITLE'
H(){
  local title="$1"
  local pad="==============="
  printf "\n${Y}%s ${W}%s${X}\n" "$pad" "$title"
}

safe_int() {
  local v
  v="$(printf '%s' "${1:-}" | tr -cd '0-9')"
  printf '%s\n' "${v:-0}"
}

safe_float() {
  local v="${1:-}"
  [[ "$v" =~ ^[0-9]+([.][0-9]+)?$ ]] && printf '%s\n' "$v" || printf '0\n'
}

safe_pct() {
  local a b
  a="$(safe_int "${1:-0}")"
  b="$(safe_int "${2:-0}")"
  [ "$b" -gt 0 ] && awk -v a="$a" -v b="$b" 'BEGIN{printf "%.1f",(a/b)*100}' || printf '0.0'
}

# -- parse time window to minutes -----------------------------------------------
M=60
[[ "$TW" =~ ^([0-9]+)m$ ]] && M="${BASH_REMATCH[1]}"
[[ "$TW" =~ ^([0-9]+)h$ ]] && M="$(( ${BASH_REMATCH[1]} * 60 ))"

# -- build nginx timestamp prefix set for 502 filter ---------------------------
TS_FILE=$(mktemp)
for (( i=0; i<=M; i++ )); do
  date -d "${i} minutes ago" '+%d/%b/%Y:%H:%M' 2>/dev/null
done > "$TS_FILE"

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
LOAD_PCT=$(awk -v l="$LOAD1" -v c="$CORES" 'BEGIN{if(c>0)printf "%.0f",(l/c)*100;else print 0}')
LOAD_PCT="$(safe_int "$LOAD_PCT")"
if   [ "$LOAD_PCT" -ge 90 ]; then LC="$R"
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
printf "  ${W}SOS ${Y}%s${X}  |  ${W}%s${X}  |  ${C}%s${X}  ${W}%s${X}  Load: ${LC}%s${X} (${LC}%s%%${X}/%sc)  ${W}[%s]${X}\n" \
  "$TW" "$NOW" "$HOST" "$IP" "$LOAD" "$LOAD_PCT" "$CORES" "$ROLE"
printf "%s\n" "$SEP"
printf "  ${C}Uptime:${X} ${W}%s${X}" "$(uptime -p)"
free -h | awk -v c="$C" -v w="$W" -v x="$X" '/^Mem:/{printf "   %sRAM:%s %s%s/%s%s (free %s%s%s)",c,x,w,$3,x,w,$2,x,w,$4,x}'
free -h | awk -v c="$C" -v w="$W" -v x="$X" '/^Swap:/{printf "   %sSwap:%s %s%s/%s%s\n",c,x,w,$3,x,w,$2,x}'

H "DISK"
df -h --output=source,size,used,avail,pcent,target 2>/dev/null \
  | grep -E '^(Filesystem|/dev)' \
  | awk -v c="$C" -v w="$W" -v x="$X" \
    'NR==1{printf "  %-20s %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6;next}
           {printf "  %s%-20s%s %s%6s%s %s%6s%s %s%6s%s %s%5s%s  %s\n",c,$1,x,w,$2,x,w,$3,x,w,$4,x,w,$5,x,$6}'

H "TOP-5 CPU + RAM"
printf "  ${C}Top 5 by CPU:${X}\n"
ps -eo pid,user,%cpu,%mem,args --sort=-%cpu 2>/dev/null \
  | awk 'NR==1||($5!~/^(ps|awk|grep|head|tail|sort)$/)' \
  | head -6 | tail -5 \
  | awk -v c="$C" -v w="$W" -v x="$X" '{printf "  %s%-7s%s %-12s CPU:%s%5s%%%s  MEM:%s%5s%%%s  %s\n",c,$1,x,$2,w,$3,x,w,$4,x,$5}'
printf "\n  ${C}Top 5 by RAM:${X}\n"
ps -eo pid,user,%cpu,%mem,rss,args --sort=-rss 2>/dev/null \
  | awk 'NR==1||($6!~/^(ps|awk|grep|head|tail|sort)$/)' \
  | head -6 | tail -5 \
  | awk -v c="$C" -v w="$W" -v x="$X" '{printf "  %s%-7s%s %-12s CPU:%s%5s%%%s  MEM:%s%5s%%%s  %s%6.1fMB%s  %s\n",c,$1,x,$2,w,$3,x,w,$4,x,w,$5/1024,x,$6}'

H "TOP 10 CPU%"
ps -eo pid,user,%cpu,pmem,args --sort=-%cpu 2>/dev/null \
  | awk 'NR==1||($5!~/^(ps|awk|grep|head|tail|sort)$/)' \
  | head -15 | tail -10 \
  | awk -v c="$C" -v w="$W" -v x="$X" '{printf "  %s%-7s%s %-10s %s%5s%s %s%5s%s  %s\n",c,$1,x,$2,w,$3,x,w,$4,x,$5}'

H "TOP 15 RAM"
ps -eo pid,user,%cpu,pmem,rss,args --sort=-rss 2>/dev/null \
  | awk 'NR==1||($6!~/^(ps|awk|grep|head|tail|sort)$/)' \
  | head -20 | tail -15 \
  | awk -v c="$C" -v w="$W" -v x="$X" '{printf "  %s%-7s%s %-10s %s%5s%s %s%5s%s  %s%6.1fMB%s  %s\n",c,$1,x,$2,w,$3,x,w,$4,x,w,$5/1024,x,$6}'

H "OOM KILLER (last boot)"
OOM_HITS=$(dmesg 2>/dev/null | grep -cE 'oom-kill|Out of memory|Killed process')
OOM_HITS="$(safe_int "$OOM_HITS")"
if [ "$OOM_HITS" -gt 0 ]; then
  printf "  ${R}OOM events: %d${X}\n" "$OOM_HITS"
  dmesg 2>/dev/null | grep -E 'oom-kill|Out of memory|Killed process' | tail -5 \
    | awk -v r="$R" -v x="$X" '{printf "  %s%s%s\n",r,$0,x}'
else
  printf "  ${G}No OOM kills detected${X}\n"
fi
OOM_SYSLOG=$(grep -E 'oom-kill|Out of memory|Killed process' /var/log/syslog 2>/dev/null | tail -200 | wc -l)
OOM_SYSLOG="$(safe_int "$OOM_SYSLOG")"
[ "$OOM_SYSLOG" -gt 0 ] && printf "  ${R}OOM entries in syslog: %d${X}\n" "$OOM_SYSLOG"

H "SWAP"
SWAP_TOTAL=$(free -m 2>/dev/null | awk '/^Swap:/{print $2+0}')
SWAP_USED=$(free  -m 2>/dev/null | awk '/^Swap:/{print $3+0}')
SWAP_FREE=$(free  -m 2>/dev/null | awk '/^Swap:/{print $4+0}')
SWAP_TOTAL="$(safe_int "$SWAP_TOTAL")"
SWAP_USED="$(safe_int  "$SWAP_USED")"
SWAP_FREE="$(safe_int  "$SWAP_FREE")"
if [ "$SWAP_TOTAL" -gt 0 ]; then
  SWAP_PCT=$(awk -v u="$SWAP_USED" -v t="$SWAP_TOTAL" 'BEGIN{printf "%.0f",(u/t)*100}')
  SWAP_PCT="$(safe_int "$SWAP_PCT")"
  [ "$SWAP_PCT" -ge 80 ] && SC="$R" || { [ "$SWAP_PCT" -ge 40 ] && SC="$Y" || SC="$G"; }
  printf "  ${C}Swap:${X} Total: ${W}%s MB${X}  Used: %s%s MB (%s%%)${X}  Free: ${G}%s MB${X}\n" \
    "$SWAP_TOTAL" "$SC" "$SWAP_USED" "$SWAP_PCT" "$SWAP_FREE"
  printf "\n  ${C}Top 5 swap consumers:${X}\n"
  awk '/^Pid:/{pid=$2}/^Name:/{name=$2}/^VmSwap:/{swap=$2;if(swap+0>0)print swap,pid,name}' \
    /proc/*/status 2>/dev/null \
    | sort -rn | head -5 \
    | awk -v c="$C" -v y="$Y" -v r="$R" -v w="$W" -v x="$X" '{
        col=($1/1024>=200)?r:(($1/1024>=50)?y:w)
        printf "  %sPID %-7s%s %-25s %s%6.1f MB%s\n",c,$2,x,$3,col,$1/1024,x
      }'
else
  printf "  ${Y}Swap is not configured${X}\n"
fi

H "NETWORK"
printf "  ${C}Connections:${X}\n"
ss -s 2>/dev/null | grep -E 'Total|TCP:|UDP:' | sed 's/^/    /'
printf "  ${C}Interface traffic:${X}\n"
ip -s link 2>/dev/null | awk '
  /^[0-9]+: (eth|ens|enp|wg|awg|tun|vmbr)/{
    iface=$2; sub(/:/,"",iface)
    getline; getline; rx=$1; getline; tx=$1
    rxf=(rx/1024/1024>1024)?sprintf("%.1fG",rx/1024/1024/1024):sprintf("%.1fM",rx/1024/1024)
    txf=(tx/1024/1024>1024)?sprintf("%.1fG",tx/1024/1024/1024):sprintf("%.1fM",tx/1024/1024)
    printf "    %-10s RX=%-8s TX=%-8s\n",iface,rxf,txf
  }'

H "LAST LOGINS"
printf "  ${C}Last 10 SSH logins:${X}\n"
last -n 10 -a 2>/dev/null \
  | awk -v g="$G" -v c="$C" -v y="$Y" -v w="$W" -v x="$X" \
    '/^reboot/{printf "  %s  %-10s%s  %s\n",y,$1,x,substr($0,28);next}
     /still logged/{printf "  %s%-10s%s  %-16s  %s%s%s\n",g,$1,x,$3,g,"still logged in",x;next}
     /^$|^wtmp/{next}
     {printf "  %s%-10s%s  %-16s  %s\n",w,$1,x,$3,substr($0,28)}' \
  | head -12
printf "\n  ${C}Currently logged in:${X}\n"
who 2>/dev/null \
  | awk -v g="$G" -v c="$C" -v x="$X" \
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
    | awk -v w="$W" -v x="$X" '{printf "    %s%s%s\n",w,$1,x}'
else
  printf "  ${G}System is up to date${X}\n"
fi

H "CRON JOBS"
printf "  ${C}System crontab (/etc/crontab):${X}\n"
grep -v '^#\|^$' /etc/crontab 2>/dev/null \
  | awk -v w="$W" -v x="$X" '{printf "    %s%s%s\n",w,$0,x}' | head -15

printf "\n  ${C}Cron.d files (/etc/cron.d/):${X}\n"
for F in /etc/cron.d/*; do
  [ -f "$F" ] || continue
  CNT=$(grep -cv '^#\|^$' "$F" 2>/dev/null || echo 0)
  CNT="$(safe_int "$CNT")"
  [ "$CNT" -eq 0 ] && continue
  printf "  ${W}%-30s${X} (%d jobs)\n" "$(basename "$F")" "$CNT"
  grep -v '^#\|^$' "$F" 2>/dev/null \
    | awk -v w="$W" -v x="$X" '{printf "    %s%s%s\n",w,$0,x}' | head -5
done

printf "\n  ${C}Root crontab:${X}\n"
CRONTAB_OUT=$(crontab -l 2>/dev/null)
if [ -n "$CRONTAB_OUT" ]; then
  echo "$CRONTAB_OUT" | grep -v '^#\|^$' \
    | awk -v w="$W" -v x="$X" '{printf "    %s%s%s\n",w,$0,x}' | head -15
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
    | awk '{p=$1;r=$2;cnt[p]++;tot[p]+=r} END{for(p in cnt)printf "%s\t%d\t%.1f\n",p,cnt[p],tot[p]/1024}' \
    | sort -k3,3nr | head -10 \
    | awk -v c="$C" -v w="$W" -v x="$X" '{printf "  %s%-26s%s %s%4d wk%s  %s%7.1fMB%s\n",c,$1,x,w,$2,x,w,$3,x}'

  H "TOP-10 TRAFFIC (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
    -exec wc -l {} + 2>/dev/null \
    | awk '$2!="total"{print $1,$2}' \
    | sort -rn | head -10 \
    | awk -v w="$W" -v c="$C" -v x="$X" '{printf "  %s%7d%s  %s%s%s\n",w,$1,x,c,$2,x}'

  H "TOP-10 IPs (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
    -exec tail -n 2000 {} + 2>/dev/null \
    | awk '{print $1}' | sort | uniq -c | sort -rn | head -10 \
    | while read -r CNT IP_ADDR; do
        GEO=""
        have geoiplookup && GEO=$(geoiplookup "$IP_ADDR" 2>/dev/null \
          | awk -F': ' '{print $2}' | cut -c1-25)
        printf "  %s%6d%s  %s%-17s%s  %s\n" "$W" "$CNT" "$X" "$C" "$IP_ADDR" "$X" "${GEO:-(no geoip)}"
      done

  H "HTTP STATUS (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
    -exec tail -n 2000 {} + 2>/dev/null \
    | awk '{print $9}' | grep -E '^[0-9]{3}$' \
    | sort | uniq -c | sort -rn | head -10 \
    | awk -v g="$G" -v c="$C" -v y="$Y" -v r="$R" -v w="$W" -v x="$X" -v em="$EM" '{
        if($2~/^2/)col=g
        else if($2~/^3/)col=c
        else if($2~/^4/)col=y
        else col=r
        printf "  %s%6d%s %s %sHTTP %s%s\n",w,$1,x,em,col,$2,x
      }'

  H "WP-LOGIN ATTACKS (last $TW)"
  {
    find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
      -exec grep -h 'wp-login.php' {} + 2>/dev/null
    [ -d /var/log/nginx ] && grep -rh 'wp-login.php' /var/log/nginx/*.log 2>/dev/null
  } | awk '{print $1}' | sort | uniq -c | sort -rn | head -10 \
    | awk -v r="$R" -v y="$Y" -v w="$W" -v x="$X" '{
        col=(($1>100)?r:(($1>20)?y:w))
        printf "  %s%5d%s  %s\n",col,$1,x,$2
      }'

  H "HTTP 502/503 BY DOMAIN (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" 2>/dev/null \
    | while read -r LOG; do
        DOM=$(echo "$LOG" | grep -oP '/var/www/\K[^/]+')
        CNT=$(awk -v tsfile="$TS_FILE" '
          BEGIN{while((getline ts < tsfile)>0) valid[ts]=1}
          {dt=substr($4,2,17); if((dt in valid)&&($9=="502"||$9=="503")) c++}
          END{print c+0}' "$LOG" 2>/dev/null)
        CNT="$(safe_int "$CNT")"
        [ "$CNT" -gt 0 ] && printf "%s\t%d\n" "$DOM" "$CNT"
      done \
    | awk '{sum[$1]+=$2} END{for(d in sum) print d,sum[d]}' \
    | sort -k2,2nr | head -10 \
    | awk -v c="$C" -v y="$Y" -v r="$R" -v w="$W" -v x="$X" '{
        col=($2>=10)?r:y
        printf "  %s%-35s%s %s%d errors%s\n",c,$1,x,col,$2,x
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
          | awk '{for(i=NF;i>=1;i--){if($i~/^[0-9]+[.][0-9]+$/&&$i+0>=3){printf "%.3f %s %s\n",$i,$7,$1;break}}}'
      done > "$SLOW_TMP"
  SLOW_REQ=$(wc -l < "$SLOW_TMP")
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
    | awk -F'\t' -v c="$C" -v g="$G" -v y="$Y" -v r="$R" -v w="$W" -v x="$X" '{
        pcti=$4+0
        col=(pcti>=5)?r:((pcti>=1)?y:g)
        printf "  %s%-40s%s %s%s errs / %s req = %s%%%s\n",c,$1,x,col,$2,$3,$4,x
      }'

  H "FONT FILE NAME TOO LONG (Flatsome/local fonts)"
  find /var/www/*/data/logs/ -name "*error.log" -mmin "-${M}" 2>/dev/null \
    | while read -r ERRLOG; do
        CNT=$(grep -c 'could not be resolved.*FontFace\|failed.*woff\|font.*too long\|FontFace.*failed' \
          "$ERRLOG" 2>/dev/null || echo 0)
        CNT="$(safe_int "$CNT")"
        [ "$CNT" -eq 0 ] && continue
        DOM=$(echo "$ERRLOG" | grep -oP '/var/www/\K[^/]+')
        printf "  %s%-40s%s %d errors  %s\n" "$C" "$DOM" "$X" "$CNT" "$ERRLOG"
      done

  H "NGINX"
  if have nginx; then
    printf "  ${C}Workers:${X} ${W}%s${X}  TCP established: ${W}%s${X}\n" \
      "$(pgrep -x nginx 2>/dev/null | wc -l)" \
      "$(ss -tnp state established 2>/dev/null | wc -l)"
    STUB=$(curl -s --max-time 2 http://127.0.0.1/nginx_status 2>/dev/null)
    [ -n "$STUB" ] && echo "$STUB" | awk '/Active/{printf "  Active connections: %s\n",$3}'
  fi

  H "MYSQL / MARIADB"
  if have mysql; then
    mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_connected';" 2>/dev/null \
      | awk -v c="$C" -v w="$W" -v x="$X" '{printf "  %sConnected:%s %s%s%s\n",c,x,w,$2,x}'
    mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_running';" 2>/dev/null \
      | awk -v c="$C" -v w="$W" -v x="$X" '{printf "  %sRunning:%s   %s%s%s\n",c,x,w,$2,x}'
    mysql -N -e "SHOW GLOBAL STATUS LIKE 'Slow_queries';" 2>/dev/null \
      | awk -v c="$C" -v w="$W" -v x="$X" '{printf "  %sSlow:%s      %s%s%s\n",c,x,w,$2,x}'
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
      GROUP BY table_schema ORDER BY mb DESC;
    " 2>/dev/null | head -15 \
      | awk -v c="$C" -v g="$G" -v y="$Y" -v r="$R" -v w="$W" -v x="$X" '{
          col=($2+0>=500)?r:(($2+0>=100)?y:g)
          printf "  %s%-35s%s %s%6.1f MB%s\n",c,$1,x,col,$2,x
        }'
  fi

  H "CRITICAL ERRORS (last $TW)"
  find /var/www/*/data/logs/ -name "*error.log" -mmin "-${M}" \
    -exec grep -iE 'fatal|Out of memory|upstream timed out|connect\(\) failed|no live upstreams' {} + 2>/dev/null \
    | tail -10

  H "BLACKLIST SYSTEM"
  IPSET_COUNT=$(ipset list vladblacklist 2>/dev/null | grep -c '^[0-9]')
  IPSET_COUNT="$(safe_int "$IPSET_COUNT")"
  IPT_RULE=$(iptables -L INPUT -n --line-numbers 2>/dev/null | grep -i 'vladblacklist\|match-set' | head -1)
  LAST_DEPLOY=$(grep 'IPs applied' /var/log/vladblacklist.log 2>/dev/null | tail -1)
  CRON_BL=$(crontab -l 2>/dev/null | grep -c 'blacklist')
  CRON_BL="$(safe_int "$CRON_BL")"
  CS_BANS=$(cscli decisions list 2>/dev/null | awk 'BEGIN{c=0}/^\|/{c++}END{print(c>0?c-1:0)}')
  CS_BANS="$(safe_int "$CS_BANS")"
  [ "$IPSET_COUNT" -gt 0 ] \
    && printf "  ${C}ipset vladblacklist:${X}    ${G}loaded${X} — ${W}%d IPs/subnets${X}\n" "$IPSET_COUNT" \
    || printf "  ${R}ipset vladblacklist: NOT LOADED${X}\n"
  [ -n "$IPT_RULE" ] \
    && printf "  ${C}iptables DROP rule:${X}     ${G}ACTIVE${X} (%s)\n" "$(echo "$IPT_RULE" | awk '{print "INPUT rule #"$1}')" \
    || printf "  ${R}iptables DROP rule: NOT FOUND${X}\n"
  [ -n "$LAST_DEPLOY" ] \
    && printf "  ${C}Last deploy:${X}           ${W}%s${X}\n" "$(echo "$LAST_DEPLOY" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}.*')"
  [ "$CRON_BL" -gt 0 ] \
    && printf "  ${C}Auto-update:${X}           ${G}cron active${X}\n" \
    || printf "  ${R}Auto-update: cron NOT FOUND${X}\n"
  printf "  ${C}CrowdSec active bans:${X}  ${R}%d IPs${X}\n" "$CS_BANS"
  printf "  ${C}Recent alerts (24h):${X}\n"
  cscli alerts list --since 24h -l 10 2>/dev/null | head -12 | sed 's/^/    /'

  H "CROWDSEC"
  if have cscli; then
    BANS=$(cscli decisions list 2>/dev/null | awk 'BEGIN{c=0}/^\|/{c++}END{print(c>0?c-1:0)}')
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
      | grep 'Jail list' | sed 's/.*Jail list://;s/,/ /g' | tr -d '\t')
    JAIL_COUNT=$(echo "$JAIL_LIST" | wc -w)
    JAIL_COUNT="$(safe_int "$JAIL_COUNT")"
    printf "  ${C}Active jails:${X} ${W}%s${X}\n" "$JAIL_COUNT"
    TOTAL_BANNED=0
    for JAIL in $JAIL_LIST; do
      [ -z "$JAIL" ] && continue
      BANNED=$(fail2ban-client status "$JAIL" 2>/dev/null | awk '/Currently banned/{print $NF}')
      TOTAL_B=$(fail2ban-client status "$JAIL" 2>/dev/null | awk '/Total banned/{print $NF}')
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
    [[ "$UFW_ST" == *active* ]] && printf "  ${G}%s${X}\n" "$UFW_ST" || printf "  ${Y}%s${X}\n" "$UFW_ST"
    ufw status numbered 2>/dev/null | grep -E '^\[' | tail -10 | sed 's/^/    /'
  else
    printf "  ${Y}UFW not installed${X}\n"
  fi

fi  # end WEB role

# -- VPN role sections ----------------------------------------------------------
if [[ "$ROLE" == VPN* ]]; then

  H "VPN STATUS"
  # WireGuard / AmneziaWG interfaces
  for WG_CMD in wg awg; do
    if have "$WG_CMD"; then
      printf "  ${C}%s interfaces:${X}\n" "$WG_CMD"
      "$WG_CMD" show all 2>/dev/null \
        | grep -E '^interface|peer|endpoint|transfer|latest' | sed 's/^/    /'
    fi
  done

  # Xray binary check
  if have xray; then
    printf "  ${C}Xray binary:${X} "
    systemctl is-active xray 2>/dev/null \
      | awk -v g="$G" -v r="$R" -v x="$X" '{col=($0=="active")?g:r;printf "%s%s%s\n",col,$0,x}'
    XRAY_CONNS=$(ss -tnp state established 2>/dev/null | grep -cE 'xray|/usr/local/bin/xray')
    XRAY_CONNS="$(safe_int "$XRAY_CONNS")"
    printf "  ${C}Xray TCP established:${X} ${W}%s${X}\n" "$XRAY_CONNS"
  fi

  # x-ui (3x-ui panel) explicit check
  XUI_ST=$(systemctl is-active x-ui 2>/dev/null)
  if [ -n "$XUI_ST" ]; then
    [ "$XUI_ST" = "active" ] && XUI_COL="$G" || XUI_COL="$R"
    printf "  ${C}x-ui panel:${X} %s%s${X}" "$XUI_COL" "$XUI_ST"
    # Count active client connections via xray inbounds (port 443/8443/any VLESS port)
    XUI_CLIENTS=$(ss -tnp state established 2>/dev/null | grep -c 'xray\|x-ui')
    XUI_CLIENTS="$(safe_int "$XUI_CLIENTS")"
    printf "  (active TCP: ${W}%s${X})\n" "$XUI_CLIENTS"
    # Show x-ui service details
    XUI_PID=$(systemctl show x-ui --property=MainPID --value 2>/dev/null)
    [ -n "$XUI_PID" ] && [ "$XUI_PID" != "0" ] && \
      printf "  ${C}x-ui PID:${X} ${W}%s${X}  uptime: ${W}%s${X}\n" \
        "$XUI_PID" \
        "$(ps -o etime= -p "$XUI_PID" 2>/dev/null | tr -d ' ')"
  else
    printf "  ${Y}x-ui: not installed / not found${X}\n"
  fi

  H "VPN PEERS"
  for WG_CMD in wg awg; do
    have "$WG_CMD" || continue
    PC=$("$WG_CMD" show all peers 2>/dev/null | wc -l)
    PC="$(safe_int "$PC")"
    printf "  ${C}%s peers total:${X} ${W}%s${X}\n" "$WG_CMD" "$PC"
  done

  H "VPN TRAFFIC (interfaces)"
  ip -s link 2>/dev/null | awk '
    /^[0-9]+: (wg|awg|tun)/{
      iface=$2; sub(/:/,"",iface)
      getline; getline; rx=$1; getline; tx=$1
      rxg=(rx/1024/1024>1024)?sprintf("%.2fG",rx/1024/1024/1024):sprintf("%.2fM",rx/1024/1024)
      txg=(tx/1024/1024>1024)?sprintf("%.2fG",tx/1024/1024/1024):sprintf("%.2fM",tx/1024/1024)
      printf "  %-10s RX=%-10s TX=%-10s\n",iface,rxg,txg
    }'

fi  # end VPN role

# -- Docker section (all roles) -------------------------------------------------
H "DOCKER (с портами)"
if have docker; then
  # Header line
  printf "  ${C}%-20s %-16s %-38s %s${X}\n" "NAMES" "STATUS" "PORTS" "IMAGE"
  docker ps -a --format '{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}' 2>/dev/null \
    | head -20 \
    | awk -F'\t' -v g="$G" -v r="$R" -v c="$C" -v w="$W" -v x="$X" '{
        col=($2~/^Up/)?g:r
        ports=($3=="")?("-"):$3
        printf "  %s%-20s%s %s%-16s%s %-38s %s%s%s\n",w,$1,x,col,$2,x,ports,c,$4,x
      }'
else
  printf "  ${Y}docker not installed${X}\n"
fi

# -- Services section — priority block first, then dynamic running list ---------
H "SERVICES (running)"

# Priority services — always show status first regardless of role
printf "  ${C}--- Priority services ---${X}\n"
for SVC in x-ui xray smbd nmbd crowdsec fail2ban; do
  ST=$(systemctl is-active "$SVC" 2>/dev/null)
  if [ -z "$ST" ] || [ "$ST" = "" ]; then
    ST="not-found"
  fi
  case "$ST" in
    active)   COL="$G" ;;
    inactive) COL="$Y" ;;
    failed)   COL="$R" ;;
    *)        COL="$W" ;;
  esac
  printf "  ${C}%-20s${X} %s%s${X}\n" "$SVC" "$COL" "$ST"
done
printf "\n  ${C}--- All running services ---${X}\n"

# Filter out low-level systemd internals and well-known always-on daemons
SVC_NOISE='^(systemd-|multipathd|networkd-dispatcher|unattended-upgrades|rsyslog'
SVC_NOISE+='|qemu-guest-agent|cron|dbus|polkit|accounts-daemon|avahi|bluetooth'
SVC_NOISE+='|colord|fwupd|kerneloops|packagekit|rtkit|snapd|thermald|udisks|upower'
SVC_NOISE+='|whoopsie|ModemManager|wpa_supplicant|chrony|getty@|user@|user-runtime'
SVC_NOISE+='|session-|dev-hugepages|dev-mqueue|proc-sys)'

systemctl list-units --type=service --state=running --no-legend --no-pager 2>/dev/null \
  | awk '{print $1}' \
  | sed 's/\.service$//' \
  | grep -vE "$SVC_NOISE" \
  | sort \
  | awk -v c="$C" -v g="$G" -v x="$X" '{printf "  %s%-45s%s %srunning%s\n",c,$1,x,g,x}'

# -- Open ports — unique, correct port extraction, no named duplicates ----------
H "OPEN PORTS (уникальные)"
# Use ss -tlnup, parse local address field (field 5 in newer ss, field 4 in older)
# Extract port as the numeric part after the LAST colon using bash rev+cut approach
# Run in a subshell to avoid affecting outer env
ss -tlnup 2>/dev/null | grep LISTEN | while read -r LINE; do
  # Find the local address column (contains ':')
  # ss columns: Netid State Recv-Q Send-Q Local Address:Port Peer Address:Port Process
  # Local address is field 5 (1-indexed)
  LOCAL=$(echo "$LINE" | awk '{print $5}')
  [ -z "$LOCAL" ] && continue

  # Extract port: everything after the last colon
  PORT=$(echo "$LOCAL" | rev | cut -d: -f1 | rev)
  # Extract bind address: everything before the last colon
  BIND=$(echo "$LOCAL" | rev | cut -d: -f2- | rev)

  # Validate port is numeric
  [[ "$PORT" =~ ^[0-9]+$ ]] || continue

  # Extract process name from the Process column (last field, contains users:(("name",...))
  PROC=$(echo "$LINE" | grep -oP 'users:\(\("\\K[^"]+' | head -1)
  [ -z "$PROC" ] && PROC="-"

  printf "%05d\t%s\t%s\n" "$PORT" "$BIND" "$PROC"
done \
  | sort -k1,1n \
  | awk -F'\t' '!seen[$1]++' \
  | awk -F'\t' -v c="$C" -v g="$G" -v y="$Y" -v w="$W" -v x="$X" '{
      port=$1+0; bind=$2; proc=$3
      col=(port<=1024)?y:g
      printf "  %s%5d%s  %-25s  %s%s%s\n",col,port,x,bind,w,proc,x
    }'

# -- Cleanup --------------------------------------------------------------------
rm -f "$TS_FILE"

printf "\n%s\n" "$SEP"
printf "  ${W}SOS complete${X}  |  ${C}%s${X}  |  ${W}%s${X}\n" "$HOST" "$NOW"
printf "%s\n\n" "$SEP"
