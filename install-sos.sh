#!/usr/bin/env bash
clear
# = Rooted by VladiMIR + AI | v.2026.05.27 | github.com/GinCz =
#
# install-sos.sh — self-contained SOS installer
# -----------------------------------------------
# Writes the full sos diagnostic script to /usr/local/bin/sos
# and registers aliases in /root/.bashrc.
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/install-sos.sh)
#
# Aliases installed:
#   sos      => /usr/local/bin/sos 24h   (default)
#   sos1     => /usr/local/bin/sos 1h
#   sos3     => /usr/local/bin/sos 3h
#   sos24    => /usr/local/bin/sos 24h
#   sos120   => /usr/local/bin/sos 120h
#   sos 2h   => any custom time window
#
# Server role is detected automatically:
#   WEB        — nginx + /var/www present
#   VPN/XRAY   — xray installed
#   VPN/WG     — wg installed
#   VPN/AWG    — awg installed
#   DOCKER     — docker installed (fallback)
#   GENERIC    — none of the above
# -----------------------------------------------

DEST="/usr/local/bin/sos"
BASHRC="/root/.bashrc"

echo "[1/4] Writing sos to $DEST ..."

cat > "$DEST" << 'EOF_SOS'
#!/usr/bin/env bash
clear
# = Rooted by VladiMIR + AI | v.2026.05.27 | github.com/GinCz =
#
# sos — Server Operational Status
# Usage: sos [time_window]   e.g.  sos 1h  sos 3h  sos 24h  sos 120h
# Default window: 24h

TW="${1:-24h}"

# --- Colors ---
G=$'\033[1;32m'
C=$'\033[1;36m'
Y=$'\033[1;33m'
R=$'\033[1;31m'
W=$'\033[1;37m'
X=$'\033[0m'
EM=$'\342\200\224'

# --- Helpers ---
have(){ command -v "$1" >/dev/null 2>&1; }
SEP="${Y}$(printf '=%.0s' {1..90})${X}"
H(){ printf "\n${Y}=============== %s${X}\n" "$1"; }

# Strip non-numeric characters, return 0 on empty
safe_int() {
  local v="${1:-}"
  v="$(printf '%s' "$v" | tr -cd '0-9')"
  printf '%s\n' "${v:-0}"
}

# Validate float, return 0 on invalid
safe_float() {
  local v="${1:-}"
  if [[ "$v" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    printf '%s\n' "$v"
  else
    printf '0\n'
  fi
}

# Calculate percentage: safe_pct <part> <total>
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

# Draw a 10-char usage bar with color threshold
# Usage: draw_bar <used_kb> <total_kb>
# Green <60% | Yellow 60-89% | Red >=90%
draw_bar() {
  local used_kb="$(safe_int "${1:-0}")"
  local total_kb="$(safe_int "${2:-0}")"
  local pct=0
  [ "$total_kb" -gt 0 ] && pct=$(( used_kb * 100 / total_kb ))
  local filled=$(( pct / 10 ))
  [ "$filled" -gt 10 ] && filled=10
  local empty=$(( 10 - filled ))

  local col
  if   [ "$pct" -ge 90 ]; then col="$R"
  elif [ "$pct" -ge 60 ]; then col="$Y"
  else                          col="$G"
  fi

  local bar="${col}["
  local i
  for (( i=0; i<filled; i++ )); do bar+="*"; done
  for (( i=0; i<empty;  i++ )); do bar+="."; done
  bar+="]${X}"
  printf '%s %s%d%%%s' "$bar" "$col" "$pct" "$X"
}

# --- Parse time window to minutes ---
M=1440
[[ "$TW" =~ ^([0-9]+)m$ ]] && M="${BASH_REMATCH[1]}"
[[ "$TW" =~ ^([0-9]+)h$ ]] && M="$(( ${BASH_REMATCH[1]} * 60 ))"

# --- Basic server info ---
NOW=$(date '+%Y-%m-%d %H:%M:%S')
HOST=$(hostname)
IP=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
CORES=$(nproc 2>/dev/null || echo 1)
CORES="$(safe_int "$CORES")"
[ "$CORES" -eq 0 ] && CORES=1

LOAD=$(awk '{print $1,$2,$3}' /proc/loadavg 2>/dev/null)
LOAD1=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
LOAD1="$(safe_float "$LOAD1")"
LOAD_PCT=$(awk -v l="$LOAD1" -v c="$CORES" 'BEGIN{ if(c>0) printf "%.0f", (l/c)*100; else print 0 }')

if [ "$LOAD_PCT" -ge 90 ]; then LC="$R"
elif [ "$LOAD_PCT" -ge 60 ]; then LC="$Y"
else LC="$G"; fi

# --- Auto-detect server role ---
ROLE="GENERIC"
have nginx && [ -d /var/www ] && ROLE="WEB"
have xray  && ROLE="VPN/XRAY"
have wg    && ROLE="VPN/WG"
have awg   && ROLE="VPN/AWG"
[ "$ROLE" = "GENERIC" ] && have docker && ROLE="DOCKER/NODE"

# --- Header ---
printf "%s\n" "$SEP"
printf "  ${W}SOS ${Y}%s${X}  |  ${G}%s${X}\n" \
  "$TW" "$NOW"
printf "  ${C}%s${X}  ${G}%s${X}  Load: ${LC}%s${X} (${LC}%s%%${X}/%sc)  ${W}[%s]${X}\n" \
  "$HOST" "$IP" "$LOAD" "$LOAD_PCT" "$CORES" "$ROLE"
printf "%s\n" "$SEP"

# --- Uptime ---
printf "  ${C}Uptime:${X} %s\n" "$(uptime -p)"

# --- RAM ---
RAM_INFO=$(free -k | awk '/^Mem:/{print $2,$3,$4}')
RAM_TOTAL=$(echo "$RAM_INFO" | awk '{print $1}')
RAM_USED=$(echo  "$RAM_INFO" | awk '{print $2}')
RAM_FREE=$(echo  "$RAM_INFO" | awk '{print $3}')
RAM_TOTAL="$(safe_int "$RAM_TOTAL")"
RAM_USED="$(safe_int "$RAM_USED")"
RAM_FREE="$(safe_int "$RAM_FREE")"
RAM_TOTAL_H=$(free -h | awk '/^Mem:/{print $2}')
RAM_USED_H=$(free  -h | awk '/^Mem:/{print $3}')
RAM_FREE_H=$(free  -h | awk '/^Mem:/{print $4}')
RAM_BAR=$(draw_bar "$RAM_USED" "$RAM_TOTAL")
printf "  ${C}RAM:${X}  %s  %s used / %s total (free %s)\n" \
  "$RAM_BAR" "$RAM_USED_H" "$RAM_TOTAL_H" "$RAM_FREE_H"

# --- Swap ---
SWAP_INFO=$(free -k | awk '/^Swap:/{print $2,$3,$4}')
SWAP_TOTAL=$(echo "$SWAP_INFO" | awk '{print $1}')
SWAP_USED=$(echo  "$SWAP_INFO" | awk '{print $2}')
SWAP_TOTAL="$(safe_int "$SWAP_TOTAL")"
SWAP_USED="$(safe_int "$SWAP_USED")"
SWAP_TOTAL_H=$(free -h | awk '/^Swap:/{print $2}')
SWAP_USED_H=$(free  -h | awk '/^Swap:/{print $3}')
if [ "$SWAP_TOTAL" -gt 0 ]; then
  SWAP_BAR=$(draw_bar "$SWAP_USED" "$SWAP_TOTAL")
  printf "  ${C}Swap:${X} %s  %s used / %s total\n" \
    "$SWAP_BAR" "$SWAP_USED_H" "$SWAP_TOTAL_H"
else
  printf "  ${C}Swap:${X} ${Y}not configured${X}\n"
fi

# -----------------------------------------------
H "DISK"
# -----------------------------------------------
printf "  %-20s %6s %6s %6s %5s  %-6s\n" "Filesystem" "Size" "Used" "Avail" "Use%" "Mount"
df -k --output=source,size,used,avail,pcent,target 2>/dev/null \
| grep '^/dev' \
| while read -r SRC SIZE USED AVAIL PCT MNT; do
    PCT_NUM=$(printf '%s' "$PCT" | tr -cd '0-9')
    PCT_NUM="$(safe_int "$PCT_NUM")"
    SIZE_H=$(df -h --output=size "$SRC" 2>/dev/null | tail -1 | tr -d ' ')
    USED_H=$(df -h --output=used "$SRC" 2>/dev/null | tail -1 | tr -d ' ')
    AVAIL_H=$(df -h --output=avail "$SRC" 2>/dev/null | tail -1 | tr -d ' ')
    DISK_BAR=$(draw_bar "$USED" "$SIZE")
    printf "  ${C}%-20s${X} %6s %6s %6s  %s  %s\n" \
      "$SRC" "$SIZE_H" "$USED_H" "$AVAIL_H" "$DISK_BAR" "$MNT"
  done

# -----------------------------------------------
H "TOP 10 CPU%"
# -----------------------------------------------
ps -eo pid,user,%cpu,pmem,args --sort=-%cpu 2>/dev/null \
| awk 'NR==1 || ($5 !~ /^(ps|awk|grep|head|tail|sort)$/)' \
| head -15 | tail -10 \
| awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-10s %5s %5s  %s\n",c,$1,x,$2,$3,$4,$5}'

# -----------------------------------------------
H "TOP 15 RAM"
# -----------------------------------------------
ps -eo pid,user,%cpu,pmem,rss,args --sort=-rss 2>/dev/null \
| awk 'NR==1 || ($6 !~ /^(ps|awk|grep|head|tail|sort)$/)' \
| head -20 | tail -15 \
| awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-10s %5s %5s  %6.1fMB  %s\n",c,$1,x,$2,$3,$4,$5/1024,$6}'

# -----------------------------------------------
H "OOM KILLER (last boot)"
# -----------------------------------------------
OOM_HITS=$(dmesg 2>/dev/null | grep -cE 'oom-kill|Out of memory|Killed process' 2>/dev/null)
OOM_HITS="$(safe_int "$OOM_HITS")"
if [ "$OOM_HITS" -gt 0 ]; then
  printf "  ${R}OOM events: %d${X}\n" "$OOM_HITS"
  dmesg 2>/dev/null | grep -E 'oom-kill|Out of memory|Killed process' | tail -5 \
  | awk -v r="$R" -v x="$X" '{printf "  %s%s%s\n",r,$0,x}'
else
  printf "  ${G}No OOM kills detected${X}\n"
fi
OOM_SYSLOG=$(grep -cE 'oom-kill|Out of memory|Killed process' /var/log/syslog 2>/dev/null | tail -n 200)
OOM_SYSLOG="$(safe_int "$OOM_SYSLOG")"
[ "$OOM_SYSLOG" -gt 0 ] && printf "  ${R}OOM entries in syslog: %d${X}\n" "$OOM_SYSLOG"

# -----------------------------------------------
H "NETWORK"
# -----------------------------------------------
printf "  ${C}Connections:${X}\n"
ss -s 2>/dev/null | grep -E 'Total|TCP:|UDP:' | sed 's/^/    /'
printf "  ${G}Interface traffic (session):${X}\n"
ip -s link 2>/dev/null \
| awk '
/^[0-9]+: (eth|ens|enp|wg|awg|tun|vmbr)/{
  iface=$2; sub(/:/,"",iface)
  getline; getline; rx=$1
  getline; tx=$1
  rxf=(rx/1024/1024>1024)?sprintf("%.1fG",rx/1024/1024/1024):sprintf("%.1fM",rx/1024/1024)
  txf=(tx/1024/1024>1024)?sprintf("%.1fG",tx/1024/1024/1024):sprintf("%.1fM",tx/1024/1024)
  printf "    %-10s RX=%-8s TX=%-8s\n",iface,rxf,txf
}'

# Monthly traffic via vnstat (if installed)
if have vnstat; then
  MONTH_START=$(date '+%Y-%m-01')
  printf "  ${G}Monthly traffic (from %s):${X}\n" "$MONTH_START"
  vnstat --iflist 2>/dev/null | grep -oE '[a-z]+[a-z0-9]+' | while read -r IFACE; do
    MONTH_DATA=$(vnstat -i "$IFACE" -m 2>/dev/null \
      | awk -v mon="$(date '+%Y-%m')" '$0~mon{print $0}' \
      | tail -1)
    [ -z "$MONTH_DATA" ] && continue
    RX_M=$(echo "$MONTH_DATA" | awk '{for(i=1;i<=NF;i++) if($i~/^[0-9]/ && $(i+1)~/^(GiB|MiB|TiB|KiB|GB|MB|TB)/) {print $i" "$(i+1); break}}')
    TX_M=$(echo "$MONTH_DATA" | awk '{
      found=0;
      for(i=1;i<=NF;i++){
        if($i~/^[0-9]/ && $(i+1)~/^(GiB|MiB|TiB|KiB|GB|MB|TB)/){
          found++;
          if(found==2){print $i" "$(i+1); break}
        }
      }
    }')
    [ -n "$RX_M" ] && printf "    ${C}%-10s${X} RX=${G}%-10s${X} TX=${G}%s${X}\n" "$IFACE" "$RX_M" "$TX_M"
  done
fi

# ===============================================
# BLACKLIST SYSTEM — universal, works on all nodes
# ===============================================
H "BLACKLIST SYSTEM"

# --- ipset vladblacklist ---
IPSET_COUNT=0
IPSET_STATUS="${R}not loaded${X}"
if have ipset; then
  _RAW=$(ipset list vladblacklist 2>/dev/null | grep 'Number of entries' | awk '{print $NF}')
  _RAW="$(safe_int "$_RAW")"
  if [ "$_RAW" -gt 0 ]; then
    IPSET_COUNT="$_RAW"
    IPSET_STATUS="${G}loaded — ${IPSET_COUNT} IPs/subnets${X}"
  elif ipset list vladblacklist >/dev/null 2>&1; then
    IPSET_STATUS="${Y}exists but empty${X}"
  fi
else
  IPSET_STATUS="${Y}ipset not installed${X}"
fi
printf "  ${C}ipset vladblacklist:${X}    %b\n" "$IPSET_STATUS"

# --- iptables DROP rule ---
IPTABLES_STATUS="${R}MISSING — not protected!${X}"
if have iptables; then
  if iptables -L INPUT -n 2>/dev/null | grep -q 'vladblacklist'; then
    IPSET_RULE=$(iptables -L INPUT -n --line-numbers 2>/dev/null | grep 'vladblacklist' | head -1)
    RULE_NUM=$(echo "$IPSET_RULE" | awk '{print $1}')
    IPTABLES_STATUS="${G}ACTIVE${X} (INPUT rule #${RULE_NUM})"
  fi
fi
printf "  ${C}iptables DROP rule:${X}     %b\n" "$IPTABLES_STATUS"

# --- Last deploy log ---
DEPLOY_LOG="/var/log/vladblacklist.log"
if [ -f "$DEPLOY_LOG" ]; then
  LAST_LINE=$(tail -1 "$DEPLOY_LOG" 2>/dev/null)
  if [ -n "$LAST_LINE" ]; then
    if echo "$LAST_LINE" | grep -qiE 'error|fail|warn'; then
      printf "  ${C}Last deploy:${X}           ${R}%s${X}\n" "$LAST_LINE"
    else
      printf "  ${C}Last deploy:${X}           ${G}%s${X}\n" "$LAST_LINE"
    fi
  else
    printf "  ${C}Last deploy:${X}           ${Y}log empty${X}\n"
  fi
else
  printf "  ${C}Last deploy:${X}           ${Y}no log yet (/var/log/vladblacklist.log)${X}\n"
fi

# --- deploy cron present? ---
CRON_OK="${Y}not scheduled${X}"
if crontab -l 2>/dev/null | grep -q 'deploy-blacklist.sh'; then
  CRON_OK="${G}cron active${X}"
fi
printf "  ${C}Auto-update:${X}           %b\n" "$CRON_OK"

# --- CrowdSec: active bans ---
if have cscli; then
  CS_BANS=$(cscli decisions list 2>/dev/null | awk 'BEGIN{c=0}/^\|/{c++}END{print (c>0?c-1:0)}')
  CS_BANS="$(safe_int "$CS_BANS")"
  [ "$CS_BANS" -gt 0 ] && CS_COL="$R" || CS_COL="$G"
  printf "  ${C}CrowdSec active bans:${X}  %s%d IPs${X}\n" "$CS_COL" "$CS_BANS"
  # Top 3 recent alerts
  CS_ALERTS=$(cscli alerts list --since 24h -l 3 2>/dev/null | grep -E '^\|' | grep -v 'Reason\|---' | head -3)
  if [ -n "$CS_ALERTS" ]; then
    printf "  ${C}Recent alerts (24h):${X}\n"
    echo "$CS_ALERTS" | sed 's/^/    /'
  fi
else
  printf "  ${C}CrowdSec:${X}              ${Y}not installed${X}\n"
fi

# ===============================================
# WEB ROLE — nginx + FastPanel + MariaDB checks
# ===============================================
if [ "$ROLE" = "WEB" ]; then

  H "PHP-FPM POOLS"
  ps -eo user,rss,args 2>/dev/null \
  | grep -E 'php-fpm|php-cgi' | grep -v grep \
  | awk '{p=$1;r=$2;cnt[p]++;tot[p]+=r} END{for(p in cnt) printf "%s\t%d\t%.1f\n",p,cnt[p],tot[p]/1024}' \
  | sort -k3,3nr | head -10 \
  | awk -v c="$C" -v x="$X" '{printf "  %s%-26s%s %4d wk  %7.1fMB\n",c,$1,x,$2,$3}'

  H "TOP-10 TRAFFIC (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" -exec wc -l {} + 2>/dev/null \
  | awk '$2 != "total"{print $1, $2}' | sort -rn | head -10 \
  | awk '{printf "  %7d  %s\n",$1,$2}'

  H "TOP-10 IPs (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" -exec tail -n 2000 {} + 2>/dev/null \
  | awk '{print $1}' | sort | uniq -c | sort -rn | head -10 \
  | awk -v em="$EM" '{printf "  %6d %s %s\n",$1,em,$2}'

  H "HTTP STATUS (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" -exec tail -n 2000 {} + 2>/dev/null \
  | awk '{print $9}' | grep -E '^[0-9]{3}$' | sort | uniq -c | sort -rn | head -10 \
  | awk -v g="$G" -v c="$C" -v y="$Y" -v r="$R" -v x="$X" -v em="$EM" '
    {
      if($2~/^2/) col=g; else if($2~/^3/) col=c; else if($2~/^4/) col=y; else col=r;
      printf "  %6d %s %sHTTP %s%s\n",$1,em,col,$2,x
    }'

  H "WP-LOGIN ATTACKS (last $TW)"
  {
    find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" -exec grep -h 'wp-login.php' {} + 2>/dev/null
    [ -d /var/log/nginx ] && grep -rh 'wp-login.php' /var/log/nginx/*.log 2>/dev/null
  } \
  | awk '{print $1}' | sort | uniq -c | sort -rn | head -10 \
  | awk -v r="$R" -v y="$Y" -v w="$W" -v x="$X" '
    { col=(($1>100)?r:(($1>20)?y:w)); printf "  %s%5d%s  %s\n",col,$1,x,$2 }'

  H "HTTP 502/503 BY DOMAIN (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" 2>/dev/null \
  | while read -r LOG; do
      DOM=$(echo "$LOG" | grep -oP '/var/www/\K[^/]+')
      CNT=$(tail -n 5000 "$LOG" 2>/dev/null | awk '$9=="502"||$9=="503"{c++}END{print c+0}')
      CNT="$(safe_int "$CNT")"
      [ "$CNT" -gt 0 ] && printf "%s\t%d\n" "$DOM" "$CNT"
    done \
  | awk '{sum[$1]+=$2} END{for(d in sum) print d,sum[d]}' \
  | sort -k2,2nr | head -10 \
  | awk -v c="$C" -v y="$Y" -v r="$R" -v x="$X" '
    { col=($2>=10)?r:y; printf "  "c"%-35s"x" %s%d errors%s\n",$1,col,$2,x }'

  H "PHP-FPM SLOW LOG (last 24h)"
  shopt -s nullglob; FOUND_SLOW=0
  for SLOW in /var/log/php*-fpm*slow* /var/log/php*/slow.log /var/www/*/data/logs/*slow*; do
    [ -f "$SLOW" ] || continue
    CNT=$(grep -c '\[pool' "$SLOW" 2>/dev/null); CNT="$(safe_int "$CNT")"
    POOL=$(echo "$SLOW" | grep -oP '/\K[^/]+(?=[-._]slow)' || basename "$SLOW")
    [ "$CNT" -gt 0 ] && COL="$R" || COL="$G"
    printf "  ${C}%-30s${X} %s%d slow${X}\n" "$POOL" "$COL" "$CNT"; FOUND_SLOW=1
  done
  [ "$FOUND_SLOW" -eq 0 ] && printf "  ${G}No PHP slow logs found${X}\n"
  shopt -u nullglob

  H "NGINX SLOW REQUESTS >3s (last $TW)"
  SLOW_TMP=$(mktemp)
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" 2>/dev/null \
  | while read -r LOG; do
      tail -n 5000 "$LOG" 2>/dev/null \
      | awk '{for(i=NF;i>=1;i--){if($i~/^[0-9]+\.[0-9]+$/ && $i+0>=3){printf "%.3f %s %s\n",$i,$7,$1;break}}}'
    done > "$SLOW_TMP"
  SLOW_REQ=$(wc -l < "$SLOW_TMP" 2>/dev/null); SLOW_REQ="$(safe_int "$SLOW_REQ")"
  if [ "$SLOW_REQ" -gt 0 ]; then
    printf "  ${R}Slow requests (>3s): %d${X}\n" "$SLOW_REQ"
    printf "  ${Y}Top 10 slowest:${X}\n"
    sort -rn "$SLOW_TMP" | head -10 \
    | awk -v r="$R" -v y="$Y" -v x="$X" '{col=($1+0>=10)?r:y;printf "  %s%7.3fs%s  %-50s  %s\n",col,$1,x,$2,$3}'
  else
    printf "  ${G}No slow requests >3s detected${X}\n"
  fi
  rm -f "$SLOW_TMP"

  H "PHP ERROR RATE (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" 2>/dev/null \
  | while read -r LOG; do
      TOTAL=$(tail -n 5000 "$LOG" 2>/dev/null | wc -l); TOTAL="$(safe_int "$TOTAL")"
      [ "$TOTAL" -eq 0 ] && continue
      ERRLOG=$(echo "$LOG" | sed 's/access/error/')
      [ -f "$ERRLOG" ] || continue
      ERRS=$(tail -n 2000 "$ERRLOG" 2>/dev/null | grep -cE 'PHP Fatal|PHP Warning|PHP Notice|PHP Parse' 2>/dev/null)
      ERRS="$(safe_int "$ERRS")"
      PCT=$(safe_pct "$ERRS" "$TOTAL")
      printf "%s\t%s\t%s\t%s\n" "$(basename "$LOG")" "$ERRS" "$TOTAL" "$PCT"
    done \
  | sort -t$'\t' -k4,4nr | head -10 \
  | awk -F'\t' -v c="$C" -v g="$G" -v y="$Y" -v r="$R" -v x="$X" '
    { pcti=$4+0; col=(pcti>=5)?r:((pcti>=1)?y:g);
      printf "  "c"%-40s"x" %s%s errs / %s req = %s%%%s\n",$1,col,$2,$3,$4,x }'

  H "NGINX"
  if have nginx; then
    printf "  ${C}Workers:${X} ${G}%s${X}  TCP established: ${G}%s${X}\n" \
      "$(pgrep -x nginx 2>/dev/null | wc -l)" \
      "$(ss -tnp state established 2>/dev/null | wc -l)"
    STUB=$(curl -s --max-time 2 http://127.0.0.1/nginx_status 2>/dev/null)
    [ -n "$STUB" ] && echo "$STUB" | awk '/Active/{printf "  Active connections: %s\n",$3}'
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
      UPDAY=$((UPSEC/86400)); UPHR=$(((UPSEC%86400)/3600)); UPMIN=$(((UPSEC%3600)/60))
      if [ "$UPDAY" -eq 0 ] && [ "$UPHR" -lt 24 ]; then WCOL="$R"; WARN=" WARNING: RECENT RESTART!"
      else WCOL="$G"; WARN=""; fi
      printf "  ${C}MariaDB uptime:${X} %s%dd %dh %dm${X}%s\n" "$WCOL" "$UPDAY" "$UPHR" "$UPMIN" "$WARN"
    fi
  fi

  H "MARIADB DATABASE SIZES"
  if have mysql; then
    mysql -N -e "
      SELECT table_schema, ROUND(SUM(data_length+index_length)/1024/1024,1) AS mb
      FROM information_schema.tables
      WHERE table_schema NOT IN ('information_schema','performance_schema','sys','mysql')
      GROUP BY table_schema ORDER BY mb DESC;
    " 2>/dev/null | head -15 \
    | awk -v c="$C" -v g="$G" -v y="$Y" -v r="$R" -v x="$X" '
      { col=($2+0>=500)?r:(($2+0>=100)?y:g);
        printf "  %s%-35s%s %s%6.1f MB%s\n",c,$1,x,col,$2,x }'
  fi

  H "CRITICAL ERRORS (last $TW)"
  find /var/www/*/data/logs/ -name "*error.log" -mmin "-${M}" \
    -exec grep -iE 'fatal|Out of memory|upstream timed out|connect\(\) failed|no live upstreams' {} + 2>/dev/null \
  | tail -10

  H "CROWDSEC"
  if have cscli; then
    BANS=$(cscli decisions list 2>/dev/null | awk 'BEGIN{c=0}/^\|/{c++}END{print (c>0?c-1:0)}')
    BANS="$(safe_int "$BANS")"
    printf "  ${C}Bans:${X} ${R}%s${X}\n" "$BANS"
    cscli alerts list --since "$TW" -l 10 2>/dev/null | head -12 | sed 's/^/  /'
  fi

  H "FAIL2BAN / UFW"
  if have fail2ban-client; then
    printf "  ${C}Fail2ban jails:${X}\n"
    fail2ban-client status 2>/dev/null | grep 'Jail list' \
    | sed 's/.*Jail list://;s/,/\n/g' | tr -d '\t ' \
    | while read -r JAIL; do
        [ -z "$JAIL" ] && continue
        BANNED=$(fail2ban-client status "$JAIL" 2>/dev/null | awk '/Currently banned/{print $NF}')
        TOTAL_B=$(fail2ban-client status "$JAIL" 2>/dev/null | awk '/Total banned/{print $NF}')
        BANNED="$(safe_int "$BANNED")"; TOTAL_B="$(safe_int "$TOTAL_B")"
        [ "$BANNED" -gt 0 ] && COL="$R" || COL="$G"
        printf "    %s%-25s%s banned: %s%s%s  total: %s\n" "$C" "$JAIL" "$X" "$COL" "$BANNED" "$X" "$TOTAL_B"
      done
  else printf "  ${Y}fail2ban not installed${X}\n"; fi
  printf "  ${C}UFW:${X} "
  if have ufw; then
    UFW_ST=$(ufw status 2>/dev/null | head -1)
    [[ "$UFW_ST" == *active* ]] && printf "${G}%s${X}\n" "$UFW_ST" || printf "${Y}%s${X}\n" "$UFW_ST"
    ufw status numbered 2>/dev/null | grep -E '^\[' | tail -10 | sed 's/^/    /'
  else printf "${Y}not installed${X}\n"; fi

fi  # end WEB

# ===============================================
# VPN ROLE — WireGuard / AmneziaWG / Xray
# ===============================================
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
    XRAY_CONNS=$(ss -tnp state established 2>/dev/null | grep -cE 'xray|/usr/local/bin/xray')
    XRAY_CONNS="$(safe_int "$XRAY_CONNS")"
    printf "  ${C}Xray TCP established:${X} ${G}%s${X}\n" "$XRAY_CONNS"
  fi

  H "VPN PEERS"
  for WG_CMD in wg awg; do
    if have "$WG_CMD"; then
      PC=$("$WG_CMD" show all peers 2>/dev/null | wc -l); PC="$(safe_int "$PC")"
      printf "  ${C}%s peers total:${X} ${G}%s${X}\n" "$WG_CMD" "$PC"
    fi
  done

  H "VPN TRAFFIC (interfaces)"
  ip -s link 2>/dev/null \
  | awk '
  /^[0-9]+: (wg|awg|tun)/+{
    iface=$2; sub(/:/,"",iface)
    getline; getline; rx=$1; getline; tx=$1
    rxg=(rx/1024/1024>1024)?sprintf("%.2fG",rx/1024/1024/1024):sprintf("%.2fM",rx/1024/1024)
    txg=(tx/1024/1024>1024)?sprintf("%.2fG",tx/1024/1024/1024):sprintf("%.2fM",tx/1024/1024)
    printf "  %-10s RX=%-10s TX=%-10s\n",iface,rxg,txg
  }'

  H "FAIL2BAN / UFW"
  if have fail2ban-client; then
    printf "  ${C}Fail2ban jails:${X}\n"
    fail2ban-client status 2>/dev/null | grep 'Jail list' \
    | sed 's/.*Jail list://;s/,/\n/g' | tr -d '\t ' \
    | while read -r JAIL; do
        [ -z "$JAIL" ] && continue
        BANNED=$(fail2ban-client status "$JAIL" 2>/dev/null | awk '/Currently banned/{print $NF}')
        TOTAL_B=$(fail2ban-client status "$JAIL" 2>/dev/null | awk '/Total banned/{print $NF}')
        BANNED="$(safe_int "$BANNED")"; TOTAL_B="$(safe_int "$TOTAL_B")"
        [ "$BANNED" -gt 0 ] && COL="$R" || COL="$G"
        printf "    %s%-25s%s banned: %s%s%s  total: %s\n" "$C" "$JAIL" "$X" "$COL" "$BANNED" "$X" "$TOTAL_B"
      done
  else printf "  ${Y}fail2ban not installed${X}\n"; fi
  printf "  ${C}UFW:${X} "
  if have ufw; then
    UFW_ST=$(ufw status 2>/dev/null | head -1)
    [[ "$UFW_ST" == *active* ]] && printf "${G}%s${X}\n" "$UFW_ST" || printf "${Y}%s${X}\n" "$UFW_ST"
    ufw status numbered 2>/dev/null | grep -E '^\[' | tail -10 | sed 's/^/    /'
  else printf "${Y}not installed${X}\n"; fi

fi  # end VPN

# ===============================================
# DOCKER — container status
# ===============================================
H "DOCKER"
if have docker; then
  docker ps -a --format "{{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null | head -10 \
  | awk -F'\t' -v g="$G" -v r="$R" -v c="$C" -v x="$X" '
    { col=($2~/^Up/)?g:r;
      printf "  %s%-28s%s %s%s%s  %s\n",c,$1,x,col,$2,x,$3 }'
else
  printf "  ${Y}docker not installed${X}\n"
fi

# ===============================================
# SERVICES — systemd status for known services
# ===============================================
H "SERVICES"
SVC_LIST=(nginx mariadb mysql php8.1-fpm php8.2-fpm php8.3-fpm php8.4-fpm \
          crowdsec crowdsec-firewall-bouncer fail2ban exim4 postfix docker \
          ssh xray wg-quick@wg0 amnezia-wg smbd nmbd vnstat)
for SVC in "${SVC_LIST[@]}"; do
  systemctl list-units --type=service --all 2>/dev/null | grep -q "${SVC}.service" && {
    STATE=$(systemctl is-active "$SVC" 2>/dev/null)
    [ "$STATE" = "active" ] && SC="$G" || SC="$R"
    printf "  ${C}%-38s${X} %s%s${X}\n" "$SVC" "$SC" "$STATE"
  }
done

# -----------------------------------------------
H "DISK I/O (1s sample)"
# -----------------------------------------------
DEV=$(awk '{print $3}' /proc/diskstats 2>/dev/null \
  | grep -E '^(vd|sd|nvme)[a-z0-9]+$' | grep -v '[0-9]$' | head -1)
if [ -n "$DEV" ]; then
  R1=$(awk -v d="$DEV" '$3==d{print $6;exit}' /proc/diskstats); R1="$(safe_int "$R1")"
  W1=$(awk -v d="$DEV" '$3==d{print $10;exit}' /proc/diskstats); W1="$(safe_int "$W1")"
  sleep 1
  R2=$(awk -v d="$DEV" '$3==d{print $6;exit}' /proc/diskstats); R2="$(safe_int "$R2")"
  W2=$(awk -v d="$DEV" '$3==d{print $10;exit}' /proc/diskstats); W2="$(safe_int "$W2")"
  RMB=$(awk -v r1="$R1" -v r2="$R2" 'BEGIN{printf "%.2f",((r2-r1)*512)/1048576}')
  WMB=$(awk -v w1="$W1" -v w2="$W2" 'BEGIN{printf "%.2f",((w2-w1)*512)/1048576}')
  printf "  ${C}Device:${X} /dev/%s  ${C}Read:${X} ${G}%s MB/s${X}  ${C}Write:${X} ${G}%s MB/s${X}\n" "$DEV" "$RMB" "$WMB"
else
  printf "  ${Y}no block device found${X}\n"
fi

# -----------------------------------------------
H "SWAP TOP-5 PROCESSES"
# -----------------------------------------------
awk '
/^Pid:/{pid=$2}
/^Name:/{name=$2}
/^VmSwap:/{swap=$2; if(swap+0>0) print swap,pid,name}
' /proc/*/status 2>/dev/null | sort -rn | head -5 \
| awk -v c="$C" -v y="$Y" -v r="$R" -v x="$X" '
  { col=($1/1024>=200)?r:(($1/1024>=50)?y:c);
    printf "  %sPID %-7s%s %-25s %s%6.1f MB%s\n",c,$2,x,$3,col,$1/1024,x }'

# -----------------------------------------------
H "DMESG ERRORS"
# -----------------------------------------------
dmesg -T 2>/dev/null | grep -iE 'error|fail|oom|kill|panic|warn' | tail -10 | sed 's/^/  /'

# -----------------------------------------------
H "CROWDSEC METRICS"
# -----------------------------------------------
have cscli && cscli metrics 2>/dev/null \
| awk '/Parsers/{p=1} p&&/\|/{printf "  %s\n",$0}' | head -8

# --- Footer ---
printf "\n%s\n  ${W}= Rooted by VladiMIR + AI | v.2026.05.27 | github.com/GinCz =${X}\n%s\n" "$SEP" "$SEP"
EOF_SOS

# -----------------------------------------------
echo "[2/4] Setting permissions..."
chmod +x "$DEST"

echo "[3/4] Testing syntax..."
bash -n "$DEST" || { echo "ERROR: syntax check failed"; exit 1; }

# -----------------------------------------------
echo "[4/4] Setting up aliases in $BASHRC ..."
sed -i "/alias sos[0-9]*=/d" "$BASHRC" 2>/dev/null
sed -i "/alias sos=/d"       "$BASHRC" 2>/dev/null

cat >> "$BASHRC" << 'EOF_ALIASES'
# === SOS aliases (installed by install-sos.sh) ===
alias sos='/usr/local/bin/sos 24h'
alias sos1='/usr/local/bin/sos 1h'
alias sos3='/usr/local/bin/sos 3h'
alias sos24='/usr/local/bin/sos 24h'
alias sos120='/usr/local/bin/sos 120h'
# === END SOS aliases ===
EOF_ALIASES

# -----------------------------------------------
echo ""
echo "  ✅ SOS installed to $DEST"
echo ""
echo "  sos      => /usr/local/bin/sos 24h   (default — last 24 hours)"
echo "  sos1     => /usr/local/bin/sos 1h    (last 1 hour)"
echo "  sos3     => /usr/local/bin/sos 3h    (last 3 hours)"
echo "  sos24    => /usr/local/bin/sos 24h   (last 24 hours)"
echo "  sos120   => /usr/local/bin/sos 120h  (last 5 days)"
echo "  sos 2h   => any custom window"
echo ""
echo "  NOTE: run 'source ~/.bashrc' or reconnect SSH for aliases to take effect"
echo ""
echo "= Rooted by VladiMIR + AI | v.2026.05.27 | github.com/GinCz ="
