#!/usr/bin/env bash
# =============================================================
# Script:      sos.sh
# Version:     v2026-05-01
# Location:    scripts/sos.sh  (universal — used by all servers)
# Servers:     222-DE-NetCup / 109-RU-FastVDS / any new server
# Description: Universal server stress analyzer and health monitor.
#              Auto-detects server role (WEB / VPN / DOCKER) and shows
#              relevant sections: CPU, RAM, Disk, Network, PHP-FPM, Nginx,
#              MariaDB, CrowdSec, Fail2Ban, UFW, Docker, OOM, Swap, I/O,
#              Samba, WireGuard, AmneziaWG, AdGuard Home, Semaphore,
#              open ports full picture.
# Usage:       sos [time_window]
#                sos          -> default 1h
#                sos 30m      -> last 30 minutes
#                sos 1h       -> last 1 hour
#                sos 3h       -> last 3 hours
#                sos 24h      -> last 24 hours
#                sos 120h     -> last 120 hours
# Install:     cp scripts/sos.sh /usr/local/bin/sos && chmod +x /usr/local/bin/sos
# Dependencies: bash, ps, df, free, ss, ip, awk, grep, find, dmesg
#               Optional: nginx, mysql/mariadb, php-fpm, docker, crowdsec,
#                         fail2ban, ufw, wg, awg, xray, samba, AdGuardHome,
#                         semaphore
# WARNING:     Read-only script — safe to run at any time, no side effects.
# = Rooted by VladiMIR | AI =
# =============================================================

clear

TW="${1:-1h}"

# ── terminal colors ────────────────────────────────────────────────────────────
G=$'\033[1;32m'   # green  — OK / active
C=$'\033[1;36m'   # cyan   — labels / section info
Y=$'\033[1;33m'   # yellow — warnings / separators
R=$'\033[1;31m'   # red    — errors / critical
W=$'\033[1;37m'   # white  — highlights
X=$'\033[0m'      # reset
EM=$'\342\200\224' # em dash — visual separator

# ── helper functions ───────────────────────────────────────────────────────────
have(){ command -v "$1" >/dev/null 2>&1; }
SEP="${Y}$(printf '=%.0s' {1..90})${X}"
H(){ printf "\n${Y}=============== %s${X}\n" "$1"; }

# ── parse time window to minutes ──────────────────────────────────────────────
M=60
[[ "$TW" =~ ^([0-9]+)m$ ]] && M="${BASH_REMATCH[1]}"
[[ "$TW" =~ ^([0-9]+)h$ ]] && M="$(( ${BASH_REMATCH[1]} * 60 ))"

# ── collect base system info ───────────────────────────────────────────────────
NOW=$(date '+%Y-%m-%d %H:%M:%S')
HOST=$(hostname)
IP=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
CORES=$(nproc 2>/dev/null || echo 1)
LOAD=$(awk '{print $1,$2,$3}' /proc/loadavg)
LOAD1=$(awk '{print $1}' /proc/loadavg)
LOAD_PCT=$(awk "BEGIN{printf \"%.0f\",($LOAD1/$CORES)*100}")
[ "$LOAD_PCT" -ge 90 ] && LC="$R" || { [ "$LOAD_PCT" -ge 60 ] && LC="$Y" || LC="$G"; }

# ── auto-detect server role ────────────────────────────────────────────────────
ROLE="GENERIC"
have nginx && [ -d /var/www ] && ROLE="WEB"
have xray  && ROLE="VPN/XRAY"
have wg    && ROLE="VPN/WG"
have awg   && ROLE="VPN/AWG"
[ "$ROLE" = "GENERIC" ] && have docker && ROLE="DOCKER/NODE"

# ── header block ──────────────────────────────────────────────────────────────
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

H "TOP 10 CPU%"
ps -eo pid,user,%cpu,pmem,args --sort=-%cpu 2>/dev/null \
  | head -11 | tail -10 \
  | awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-10s %5s %5s  %s\n",c,$1,x,$2,$3,$4,$5}'

H "TOP 15 RAM"
ps -eo pid,user,%cpu,pmem,rss,args --sort=-rss 2>/dev/null \
  | head -16 | tail -15 \
  | awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-10s %5s %5s  %6.1fMB  %s\n",c,$1,x,$2,$3,$4,$5/1024,$6}'

H "OOM KILLER (last boot)"
OOM_HITS=$(dmesg 2>/dev/null | grep -c 'oom-kill\|Out of memory\|Killed process' || echo 0)
if [ "${OOM_HITS:-0}" -gt 0 ]; then
  printf "  ${R}OOM events: %d${X}\n" "$OOM_HITS"
  dmesg 2>/dev/null | grep -E 'oom-kill|Out of memory|Killed process' | tail -5 \
    | awk -v r="$R" -v x="$X" '{printf "  %s%s%s\n",r,$0,x}'
else
  printf "  ${G}No OOM kills detected${X}\n"
fi
OOM_SYSLOG=$(grep -E 'oom-kill|Out of memory|Killed process' /var/log/syslog 2>/dev/null \
  | tail -n 200 | wc -l)
[ "${OOM_SYSLOG:-0}" -gt 0 ] && \
  printf "  ${R}OOM entries in syslog: %d${X}\n" "$OOM_SYSLOG"

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

if [ "$ROLE" = "WEB" ]; then

  H "PHP-FPM POOLS"
  ps -eo user,rss,args 2>/dev/null | grep 'php-fpm\|php-cgi' \
    | awk -v c="$C" -v x="$X" \
      '{p=$1;r=$2;cnt[p]++;tot[p]+=r}
       END{for(p in cnt)printf "  %s%-26s%s %4d wk  %7.1fMB\n",c,p,x,cnt[p],tot[p]/1024}' \
    | sort -k4 -rn

  H "TOP-5 TRAFFIC (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
    -exec wc -l {} + 2>/dev/null | sort -rn | head -6 \
    | awk '{printf "  %7d  %s\n",$1,$2}'

  H "TOP-10 IPs (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
    -exec tail -n 2000 {} + 2>/dev/null \
    | awk '{print $1}' | sort | uniq -c | sort -rn | head -10 \
    | awk -v em="$EM" '{printf "  %6d %s %s\n",$1,em,$2}'

  H "HTTP STATUS (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
    -exec tail -n 2000 {} + 2>/dev/null \
    | awk '{print $9}' | grep -E '^[0-9]{3}$' | sort | uniq -c | sort -rn | head -10 \
    | awk -v g="$G" -v c="$C" -v y="$Y" -v r="$R" -v x="$X" -v em="$EM" \
      '{if($2~/^2/)col=g; else if($2~/^3/)col=c; else if($2~/^4/)col=y; else col=r;
        printf "  %6d %s %sHTTP %s%s\n",$1,em,col,$2,x}'

  H "WP-LOGIN ATTACKS (last $TW)"
  {
    find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
      -exec grep -h 'wp-login.php' {} + 2>/dev/null
    [ -d /var/log/nginx ] && grep -rh 'wp-login.php' /var/log/nginx/*.log 2>/dev/null
  } | awk '{print $1}' | sort | uniq -c | sort -rn | head -10 \
    | awk -v r="$R" -v y="$Y" -v w="$W" -v x="$X" \
      '{col=(($1>100)?r:(($1>20)?y:w)); printf "  %s%5d%s  %s\n",col,$1,x,$2}'

  H "HTTP 502/503 BY DOMAIN (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" 2>/dev/null \
    | while read -r LOG; do
        DOM=$(echo "$LOG" | grep -oP '/var/www/\K[^/]+')
        CNT=$(tail -n 5000 "$LOG" 2>/dev/null | awk '$9=="502"||$9=="503"{c++}END{print c+0}')
        [ "$CNT" -gt 0 ] && {
          [ "$CNT" -ge 10 ] && COL="$R" || COL="$Y"
          printf "  ${C}%-35s${X} %s%d errors${X}\n" "$DOM" "$COL" "$CNT"
        }
      done

  H "PHP-FPM SLOW LOG (last 24h)"
  shopt -s nullglob
  for SLOW in /var/log/php*-fpm*slow* /var/log/php*/slow.log /var/www/*/data/logs/*slow*; do
    [ -f "$SLOW" ] || continue
    CNT=$(grep -c '\[pool' "$SLOW" 2>/dev/null || echo 0)
    POOL=$(echo "$SLOW" | grep -oP '/\K[^/]+(?=[-._]slow)' || basename "$SLOW")
    [ "$CNT" -gt 0 ] && COL="$R" || COL="$G"
    printf "  ${C}%-30s${X} %s%d slow${X}\n" "$POOL" "$COL" "$CNT"
  done
  shopt -u nullglob

  H "NGINX SLOW REQUESTS >3s (last $TW)"
  SLOW_TMP=$(mktemp)
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" 2>/dev/null \
    | while read -r LOG; do
        tail -n 5000 "$LOG" 2>/dev/null \
          | awk '{
              for(i=NF;i>=1;i--){
                if($i~/^[0-9]+\.[0-9]+$/ && $i+0>=3){
                  printf "%.3f %s %s\n",$i,$7,$1
                  break
                }
              }
            }'
      done > "$SLOW_TMP"
  SLOW_REQ=$(wc -l < "$SLOW_TMP")
  if [ "${SLOW_REQ:-0}" -gt 0 ]; then
    printf "  ${R}Slow requests (>3s): %d${X}\n" "$SLOW_REQ"
    printf "  ${Y}Top 5 slowest:${X}\n"
    sort -rn "$SLOW_TMP" | head -5 \
      | awk -v r="$R" -v y="$Y" -v x="$X" \
          '{col=($1+0>=10)?r:y; printf "  %s%7.3fs%s  %-50s  %s\n",col,$1,x,$2,$3}'
  else
    printf "  ${G}No slow requests >3s detected${X}\n"
  fi
  rm -f "$SLOW_TMP"

  H "PHP ERROR RATE (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" 2>/dev/null \
    | while read -r LOG; do
        TOTAL=$(tail -n 5000 "$LOG" 2>/dev/null | wc -l)
        [ "${TOTAL:-0}" -eq 0 ] && continue
        ERRLOG=$(echo "$LOG" | sed 's/access/error/')
        [ -f "$ERRLOG" ] || continue
        ERRS=$(tail -n 2000 "$ERRLOG" 2>/dev/null \
          | grep -cE 'PHP Fatal|PHP Warning|PHP Notice|PHP Parse' || echo 0)
        [ "${ERRS:-0}" -eq 0 ] && continue
        PCT=$(awk "BEGIN{printf \"%.1f\",($ERRS/$TOTAL)*100}")
        PCT_INT=$(awk "BEGIN{printf \"%.0f\",$PCT}")
        [ "$PCT_INT" -ge 5 ] && COL="$R" || { [ "$PCT_INT" -ge 1 ] && COL="$Y" || COL="$G"; }
        printf "  ${C}%-40s${X} %s%d errs / %d req = %s%%%s\n" \
          "$(basename "$LOG")" "$COL" "$ERRS" "$TOTAL" "$PCT" "$X"
      done

  H "NGINX"
  have nginx && {
    printf "  ${C}Workers:${X} ${G}%s${X}  TCP established: ${G}%s${X}\n" \
      "$(pgrep -x nginx | wc -l)" \
      "$(ss -tnp state established 2>/dev/null | wc -l)"
    STUB=$(curl -s --max-time 2 http://127.0.0.1/nginx_status 2>/dev/null)
    [ -n "$STUB" ] && echo "$STUB" | awk '/Active/{printf "  Active connections: %s\n",$3}'
  }

  H "MYSQL / MARIADB"
  have mysql && {
    mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_connected';" 2>/dev/null \
      | awk -v c="$C" -v g="$G" -v x="$X" '{printf "  %sConnected:%s %s%s%s\n",c,x,g,$2,x}'
    mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_running';" 2>/dev/null \
      | awk -v c="$C" -v g="$G" -v x="$X" '{printf "  %sRunning:%s   %s%s%s\n",c,x,g,$2,x}'
    mysql -N -e "SHOW GLOBAL STATUS LIKE 'Slow_queries';" 2>/dev/null \
      | awk -v c="$C" -v x="$X" '{printf "  %sSlow:%s      %s\n",c,x,$2}'
    UPSEC=$(mysql -N -e "SHOW GLOBAL STATUS LIKE 'Uptime';" 2>/dev/null | awk '{print $2}')
    if [ -n "$UPSEC" ]; then
      UPDAY=$((UPSEC/86400)); UPHR=$(( (UPSEC%86400)/3600 )); UPMIN=$(( (UPSEC%3600)/60 ))
      if [ "$UPDAY" -eq 0 ] && [ "$UPHR" -lt 24 ]; then
        WCOL="$R"; WARN=" \u26a0\ufe0f  RECENT RESTART!"
      else
        WCOL="$G"; WARN=""
      fi
      printf "  ${C}MariaDB uptime:${X} %s%dd %dh %dm${X}%s\n" "$WCOL" "$UPDAY" "$UPHR" "$UPMIN" "$WARN"
    fi
  }

  H "MARIADB DATABASE SIZES"
  have mysql && {
    mysql -N -e "
      SELECT table_schema,
             ROUND(SUM(data_length+index_length)/1024/1024,1) AS mb
      FROM information_schema.tables
      WHERE table_schema NOT IN ('information_schema','performance_schema','sys','mysql')
      GROUP BY table_schema
      ORDER BY mb DESC;
    " 2>/dev/null \
    | awk -v c="$C" -v g="$G" -v y="$Y" -v r="$R" -v x="$X" '{
        col=($2+0>=500)?r:(($2+0>=100)?y:g)
        printf "  %s%-35s%s %s%6.1f MB%s\n",c,$1,x,col,$2,x
      }'
  }

  H "CRITICAL ERRORS (last $TW)"
  find /var/www/*/data/logs/ -name "*error.log" -mmin "-${M}" \
    -exec grep -iE 'fatal|Out of memory|upstream timed out|connect\(\) failed|no live upstreams' {} + \
    2>/dev/null | tail -10

  H "CROWDSEC"
  have cscli && {
    BANS=$(cscli decisions list 2>/dev/null | awk 'BEGIN{c=0}/^\|/{c++}END{print (c>0?c-1:0)}')
    printf "  ${C}Bans:${X} ${R}%s${X}\n" "$BANS"
    cscli alerts list --since "$TW" -l 10 2>/dev/null | head -12 | sed 's/^/  /'
  }

  H "FAIL2BAN / UFW"
  if have fail2ban-client; then
    printf "  ${C}Fail2ban jails:${X}\n"
    fail2ban-client status 2>/dev/null | grep 'Jail list' \
      | sed 's/.*Jail list://;s/,/\n/g' | tr -d '\t ' \
      | while read -r JAIL; do
          [ -z "$JAIL" ] && continue
          BANNED=$(fail2ban-client status "$JAIL" 2>/dev/null | awk '/Currently banned/{print $NF}')
          TOTAL_B=$(fail2ban-client status "$JAIL" 2>/dev/null | awk '/Total banned/{print $NF}')
          [ "${BANNED:-0}" -gt 0 ] && COL="$R" || COL="$G"
          printf "    %s%-25s%s banned: %s%s%s  total: %s\n" \
            "$C" "$JAIL" "$X" "$COL" "${BANNED:-0}" "$X" "${TOTAL_B:-0}"
        done
  else
    printf "  ${Y}fail2ban not installed${X}\n"
  fi
  printf "  ${C}UFW:${X} "
  if have ufw; then
    UFW_ST=$(ufw status 2>/dev/null | head -1)
    [[ "$UFW_ST" == *active* ]] && printf "${G}%s${X}\n" "$UFW_ST" || printf "${Y}%s${X}\n" "$UFW_ST"
    ufw status numbered 2>/dev/null | grep -E '^\[' | tail -10 | sed 's/^/    /'
  else
    printf "${Y}not installed${X}\n"
  fi

fi

if [[ "$ROLE" == VPN* ]]; then

  H "VPN STATUS"
  for WG_CMD in wg awg; do
    have "$WG_CMD" && {
      printf "  ${C}%s interfaces:${X}\n" "$WG_CMD"
      "$WG_CMD" show all 2>/dev/null \
        | grep -E '^interface|peer|endpoint|transfer|latest' | sed 's/^/    /'
    }
  done
  have xray && {
    printf "  ${C}Xray:${X} "
    systemctl is-active xray 2>/dev/null \
      | awk -v g="$G" -v r="$R" -v x="$X" '{col=($0=="active")?g:r; printf "%s%s%s\n",col,$0,x}'
    XRAY_CONNS=$(ss -tnp state established 2>/dev/null \
      | grep -c 'xray\|/usr/local/bin/xray' || echo 0)
    printf "  ${C}Xray TCP established:${X} ${G}%s${X}\n" "$XRAY_CONNS"
  }

  H "VPN PEERS"
  for WG_CMD in wg awg; do
    have "$WG_CMD" && {
      PC=$("$WG_CMD" show all peers 2>/dev/null | wc -l)
      printf "  ${C}%s peers total:${X} ${G}%s${X}\n" "$WG_CMD" "$PC"
    }
  done

  H "VPN TRAFFIC (interfaces)"
  ip -s link 2>/dev/null | awk '
    /^[0-9]+: (wg|awg|tun)/ {
      iface=$2; sub(/:/,"",iface)
      getline; getline; rx=$1
      getline; tx=$1
      rxg=(rx/1024/1024>1024)?sprintf("%.2fG",rx/1024/1024/1024):sprintf("%.2fM",rx/1024/1024)
      txg=(tx/1024/1024>1024)?sprintf("%.2fG",tx/1024/1024/1024):sprintf("%.2fM",tx/1024/1024)
      printf "  %-10s RX=%-10s TX=%-10s\n", iface, rxg, txg
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
          [ "${BANNED:-0}" -gt 0 ] && COL="$R" || COL="$G"
          printf "    %s%-25s%s banned: %s%s%s  total: %s\n" \
            "$C" "$JAIL" "$X" "$COL" "${BANNED:-0}" "$X" "${TOTAL_B:-0}"
        done
  else
    printf "  ${Y}fail2ban not installed${X}\n"
  fi
  printf "  ${C}UFW:${X} "
  if have ufw; then
    UFW_ST=$(ufw status 2>/dev/null | head -1)
    [[ "$UFW_ST" == *active* ]] && printf "${G}%s${X}\n" "$UFW_ST" || printf "${Y}%s${X}\n" "$UFW_ST"
    ufw status numbered 2>/dev/null | grep -E '^\[' | tail -10 | sed 's/^/    /'
  else
    printf "${Y}not installed${X}\n"
  fi

fi

H "DOCKER"
if have docker; then
  docker ps -a --format "  {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null \
    | awk -v g="$G" -v r="$R" -v c="$C" -v x="$X" \
      '{col=($2~/Up/)?g:r; printf "  %s%-28s%s %s%s%s  %s\n",c,$1,x,col,$2,x,$3}'
else
  printf "  ${Y}docker not installed${X}\n"
fi

H "SERVICES"
SVC_LIST=(
  nginx mariadb mysql
  php8.1-fpm php8.2-fpm php8.3-fpm php8.4-fpm
  crowdsec crowdsec-firewall-bouncer
  fail2ban
  smbd nmbd
  exim4 postfix docker ssh
  xray wg-quick@wg0 amnezia-wg
  AdGuardHome adguardhome
  semaphore
)
for SVC in "${SVC_LIST[@]}"; do
  systemctl list-units --type=service --all 2>/dev/null | grep -q "${SVC}.service" && {
    STATE=$(systemctl is-active "$SVC" 2>/dev/null)
    [ "$STATE" = "active" ] && SC="$G" || SC="$R"
    printf "  ${C}%-38s${X} %s%s${X}\n" "$SVC" "$SC" "$STATE"
  }
done

# ── WIREGUARD ─────────────────────────────────────────────────────────────────
H "WIREGUARD"
if have wg; then
  WG_IFACES=$(wg show interfaces 2>/dev/null)
  if [ -n "$WG_IFACES" ]; then
    for IFACE in $WG_IFACES; do
      printf "  ${C}Interface:${X} ${G}%s${X}\n" "$IFACE"
      WG_INFO=$(wg show "$IFACE" 2>/dev/null)
      LISTEN_PORT=$(echo "$WG_INFO" | awk '/listening port/{print $NF}')
      PEERS=$(echo "$WG_INFO" | grep -c '^peer:')
      printf "    ${C}Port:${X}  ${G}%s${X}   ${C}Peers:${X} ${G}%s${X}\n" \
        "${LISTEN_PORT:-n/a}" "$PEERS"
      # Show peers with last handshake
      echo "$WG_INFO" | awk -v g="$G" -v y="$Y" -v c="$C" -v r="$R" -v x="$X" '
        /^peer:/{peer=substr($0,7,10)"..."}
        /latest handshake:/{
          t=$0; sub(/.*latest handshake: /,"",t)
          # flag stale if > 3 minutes ago (contains "minutes" with value > 3 or "hours"/"days")
          stale=0
          if(t~/hours|days/) stale=1
          if(t~/minutes/ && t+0>3) stale=1
          col=stale?r:g
          printf "    %s%-14s%s handshake: %s%s%s\n",c,peer,x,col,t,x
        }
        /transfer:/{t=$0; sub(/.*transfer: /,"",t); printf "    %s%-14s%s tx/rx: %s\n",c,peer,x,t}'
  done
  else
    printf "  ${Y}WireGuard installed but no interfaces active${X}\n"
  fi
  # Show wg-quick services
  printf "  ${C}wg-quick services:${X}\n"
  systemctl list-units --type=service --all 2>/dev/null \
    | grep 'wg-quick' \
    | awk -v g="$G" -v r="$R" -v c="$C" -v x="$X" \
      '{state=$4; col=(state=="active")?g:r; printf "    %s%-30s%s %s%s%s\n",c,$1,x,col,state,x}'
else
  printf "  ${Y}WireGuard (wg) not installed${X}\n"
fi

# ── AMNEZIA WIREGUARD ─────────────────────────────────────────────────────────
H "AMNEZIA WIREGUARD"
if have awg; then
  AWG_IFACES=$(awg show interfaces 2>/dev/null)
  if [ -n "$AWG_IFACES" ]; then
    for IFACE in $AWG_IFACES; do
      printf "  ${C}Interface:${X} ${G}%s${X}\n" "$IFACE"
      AWG_INFO=$(awg show "$IFACE" 2>/dev/null)
      LISTEN_PORT=$(echo "$AWG_INFO" | awk '/listening port/{print $NF}')
      PEERS=$(echo "$AWG_INFO" | grep -c '^peer:')
      printf "    ${C}Port:${X}  ${G}%s${X}   ${C}Peers:${X} ${G}%s${X}\n" \
        "${LISTEN_PORT:-n/a}" "$PEERS"
      echo "$AWG_INFO" | awk -v g="$G" -v y="$Y" -v c="$C" -v r="$R" -v x="$X" '
        /^peer:/{peer=substr($0,7,10)"..."}
        /latest handshake:/{
          t=$0; sub(/.*latest handshake: /,"",t)
          stale=0
          if(t~/hours|days/) stale=1
          if(t~/minutes/ && t+0>3) stale=1
          col=stale?r:g
          printf "    %s%-14s%s handshake: %s%s%s\n",c,peer,x,col,t,x
        }
        /transfer:/{t=$0; sub(/.*transfer: /,"",t); printf "    %s%-14s%s tx/rx: %s\n",c,peer,x,t}'
    done
  else
    printf "  ${Y}AmneziaWG installed but no interfaces active${X}\n"
  fi
  # Show amnezia-wg services
  printf "  ${C}amnezia-wg services:${X}\n"
  systemctl list-units --type=service --all 2>/dev/null \
    | grep -iE 'amnezia|awg-quick' \
    | awk -v g="$G" -v r="$R" -v c="$C" -v x="$X" \
      '{state=$4; col=(state=="active")?g:r; printf "    %s%-30s%s %s%s%s\n",c,$1,x,col,state,x}'
else
  printf "  ${Y}AmneziaWG (awg) not installed${X}\n"
fi

# ── ADGUARD HOME ──────────────────────────────────────────────────────────────
H "ADGUARD HOME"
AGH_BIN=""
[ -x /opt/AdGuardHome/AdGuardHome ] && AGH_BIN="/opt/AdGuardHome/AdGuardHome"
[ -x /usr/local/bin/AdGuardHome ]   && AGH_BIN="/usr/local/bin/AdGuardHome"
if [ -n "$AGH_BIN" ]; then
  # Service state
  AGH_SVC="AdGuardHome"
  AGH_STATE=$(systemctl is-active "$AGH_SVC" 2>/dev/null)
  [ "$AGH_STATE" = "active" ] && SC="$G" || { SC="$R"; AGH_SVC="adguardhome"; AGH_STATE=$(systemctl is-active "$AGH_SVC" 2>/dev/null); [ "$AGH_STATE" = "active" ] && SC="$G" || SC="$R"; }
  printf "  ${C}Service:${X}    %s%s${X}\n" "$SC" "$AGH_STATE"
  printf "  ${C}Uptime:${X}     %s\n" "$(systemctl show "$AGH_SVC" -p ActiveEnterTimestamp --value 2>/dev/null)"

  # DNS port 53 listening?
  DNS_UDP=$(ss -ulnp 2>/dev/null | grep -c ':53 ')
  DNS_TCP=$(ss -tlnp 2>/dev/null | grep -c ':53 ')
  [ "${DNS_UDP:-0}" -gt 0 ] && D53U="${G}OK${X}" || D53U="${R}DOWN${X}"
  [ "${DNS_TCP:-0}" -gt 0 ] && D53T="${G}OK${X}" || D53T="${R}DOWN${X}"
  printf "  ${C}DNS port 53:${X}  UDP=%b  TCP=%b\n" "$D53U" "$D53T"

  # Web UI port
  AGH_WEB=$(ss -tlnp 2>/dev/null | grep AdGuardHome | grep -oP ':\K[0-9]+' | sort -u | tr '\n' ' ')
  [ -n "$AGH_WEB" ] \
    && printf "  ${C}Web UI ports:${X} ${G}%s${X}\n" "$AGH_WEB" \
    || printf "  ${C}Web UI ports:${X} ${R}not found!${X}\n"

  # DoT port 853
  DOT=$(ss -tlnp 2>/dev/null | grep -c ':853 ')
  [ "${DOT:-0}" -gt 0 ] \
    && printf "  ${C}DoT port 853:${X} ${G}listening${X}\n" \
    || printf "  ${C}DoT port 853:${X} ${Y}not active${X}\n"

  # UFW rules for AdGuard
  printf "  ${C}UFW rules (AdGuard):${X}\n"
  ufw status 2>/dev/null | grep -E ':53|8080|8443|853|3000' \
    | awk '{printf "    %s\n",$0}' \
    | grep . || printf "    ${R}No AdGuard ports found in UFW!${X}\n"

  # Local DNS test
  if have dig; then
    DNS_TEST=$(dig @127.0.0.1 google.com +short +timeout=3 2>/dev/null | head -1)
    [ -n "$DNS_TEST" ] \
      && printf "  ${C}DNS local test:${X} ${G}OK -> %s${X}\n" "$DNS_TEST" \
      || printf "  ${C}DNS local test:${X} ${R}FAILED — DNS not responding!${X}\n"
  elif have nslookup; then
    DNS_TEST=$(nslookup -timeout=3 google.com 127.0.0.1 2>/dev/null | awk '/^Address/{last=$NF}END{print last}')
    [ -n "$DNS_TEST" ] \
      && printf "  ${C}DNS local test:${X} ${G}OK -> %s${X}\n" "$DNS_TEST" \
      || printf "  ${C}DNS local test:${X} ${R}FAILED${X}\n"
  fi

  # AdGuard version
  AGH_VER=$("$AGH_BIN" --version 2>/dev/null | awk '{print $NF}')
  [ -n "$AGH_VER" ] && printf "  ${C}Version:${X}    ${W}%s${X}\n" "$AGH_VER"

else
  printf "  ${Y}AdGuard Home not installed${X}\n"
fi

# ── SEMAPHORE CI ──────────────────────────────────────────────────────────────
H "SEMAPHORE"
SEM_BIN=""
have semaphore        && SEM_BIN=$(command -v semaphore)
[ -x /usr/bin/semaphore ]       && SEM_BIN="/usr/bin/semaphore"
[ -x /usr/local/bin/semaphore ] && SEM_BIN="/usr/local/bin/semaphore"
if [ -n "$SEM_BIN" ]; then
  SEM_STATE=$(systemctl is-active semaphore 2>/dev/null)
  [ "$SEM_STATE" = "active" ] && SC="$G" || SC="$R"
  printf "  ${C}Service:${X}  %s%s${X}\n" "$SC" "$SEM_STATE"

  # Web UI port (default 3000)
  SEM_PORT=$(ss -tlnp 2>/dev/null | grep semaphore | grep -oP ':\K[0-9]+' | sort -u | tr '\n' ' ')
  [ -n "$SEM_PORT" ] \
    && printf "  ${C}Port:${X}     ${G}%s${X}\n" "$SEM_PORT" \
    || printf "  ${C}Port:${X}     ${Y}not listening (check config)${X}\n"

  # UFW rule check for semaphore port
  printf "  ${C}UFW rules:${X}\n"
  ufw status 2>/dev/null | grep -E ':3000|semaphore' \
    | awk '{printf "    %s\n",$0}' \
    | grep . || printf "    ${Y}Port 3000 not in UFW (may be reverse-proxied)${X}\n"

  # Version
  SEM_VER=$("$SEM_BIN" version 2>/dev/null | head -1)
  [ -n "$SEM_VER" ] && printf "  ${C}Version:${X}  ${W}%s${X}\n" "$SEM_VER"
else
  printf "  ${Y}Semaphore not installed${X}\n"
fi

# ── SAMBA ─────────────────────────────────────────────────────────────────────
H "SAMBA USERS & SHARES"
if have pdbedit || have smbpasswd; then

  printf "  ${C}Users (pdbedit):${X}\n"
  pdbedit -L -v 2>/dev/null \
    | awk -v g="$G" -v r="$R" -v y="$Y" -v c="$C" -v x="$X" '
        /^Unix username:/ { user = $NF }
        /^Account Flags:/ {
          match($0, /\[.*\]/)
          flags = substr($0, RSTART, RLENGTH)
          if (flags ~ /D/)      col = r
          else if (flags ~ /U/) col = g
          else                  col = y
          printf "  %s%-25s%s %s%s%s\n", c, user, x, col, flags, x
        }
      '

  printf "\n  ${C}Shares (testparm -s):${X}\n"
  if have testparm; then
    testparm -s 2>/dev/null \
      | awk -v c="$C" -v g="$G" -v y="$Y" -v w="$W" -v x="$X" '
          /^\[/ {
            share = substr($0, 2, length($0)-2)
            skip = (share == "global" || share == "printers" || share == "print$")
            if (!skip) printf "\n  %s[%s]%s\n", w, share, x
          }
          !skip && /path[[:space:]]*=/ {
            sub(/^[[:space:]]+/, "")
            printf "    %spath:%s       %s\n", c, x, $0
            n = split($0, a, "=")
            if (n >= 2) {
              gsub(/^[[:space:]]+|[[:space:]]+$/, "", a[2])
              cmd = "ls -lad \"" a[2] "\" 2>/dev/null | awk '"'"'{ printf \"    perms: %s  owner: %s/%s\n\",$1,$3,$4 }'"'"'"
              system(cmd)
            }
          }
          !skip && /valid users[[:space:]]*=/ {
            sub(/^[[:space:]]+/, "")
            printf "    %svalid users:%s %s\n", c, x, $0
          }
          !skip && /read only[[:space:]]*=/ {
            sub(/^[[:space:]]+/, "")
            val = $NF
            col = (val == "No") ? g : y
            printf "    %sread only:%s   %s%s%s\n", c, x, col, val, x
          }
          !skip && /writable[[:space:]]*=/ {
            sub(/^[[:space:]]+/, "")
            val = $NF
            col = (val == "Yes") ? g : y
            printf "    %swritable:%s    %s%s%s\n", c, x, col, val, x
          }
        ' | head -60
  else
    printf "  ${Y}testparm not found — install samba-common-bin${X}\n"
  fi

else
  printf "  ${Y}Samba not installed${X}\n"
fi

H "DISK I/O (1s sample)"
DEV=$(awk '{print $3}' /proc/diskstats 2>/dev/null \
  | grep -E '^(vd|sd|nvme)[a-z0-9]+$' | grep -v '[0-9]$' | head -1)
if [ -n "$DEV" ]; then
  R1=$(awk -v d="$DEV" '$3==d{print $6;exit}' /proc/diskstats)
  W1=$(awk -v d="$DEV" '$3==d{print $10;exit}' /proc/diskstats)
  sleep 1
  R2=$(awk -v d="$DEV" '$3==d{print $6;exit}' /proc/diskstats)
  W2=$(awk -v d="$DEV" '$3==d{print $10;exit}' /proc/diskstats)
  RMB=$(awk "BEGIN{printf \"%.2f\",(${R2:-0}-${R1:-0})*512/1048576}")
  WMB=$(awk "BEGIN{printf \"%.2f\",(${W2:-0}-${W1:-0})*512/1048576}")
  printf "  ${C}Device:${X} /dev/%s  ${C}Read:${X} ${G}%s MB/s${X}  ${C}Write:${X} ${G}%s MB/s${X}\n" \
    "$DEV" "$RMB" "$WMB"
else
  printf "  ${Y}no block device found${X}\n"
fi

H "SWAP TOP-5 PROCESSES"
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

H "DMESG ERRORS"
dmesg -T 2>/dev/null | grep -iE 'error|fail|oom|kill|panic|warn' | tail -10 | sed 's/^/  /'

H "CROWDSEC METRICS"
have cscli && cscli metrics 2>/dev/null \
  | awk '/Parsers/{p=1} p&&/\|/{printf "  %s\n",$0}' | head -8

# ── ALL OPEN PORTS ────────────────────────────────────────────────────────────
H "ALL OPEN PORTS"
printf "  ${C}TCP listening:${X}\n"
ss -tlnp 2>/dev/null \
  | awk 'NR>1 && /LISTEN/ {
      addr=$4; proc=$NF
      gsub(/users:\(\(|\)\)/,"",proc)
      sub(/,.*/,"",proc)
      # color well-known ports
      split(addr,a,":"); port=a[length(a)]
      printf "    %-25s %s\n", addr, proc
    }' | sort -t: -k2 -n

printf "\n  ${C}UDP listening:${X}\n"
ss -ulnp 2>/dev/null \
  | awk 'NR>1 {
      addr=$4; proc=$NF
      gsub(/users:\(\(|\)\)/,"",proc)
      sub(/,.*/,"",proc)
      printf "    %-25s %s\n", addr, proc
    }' | sort -t: -k2 -n

# Summary of key ports with status
printf "\n  ${C}Key ports status:${X}\n"
declare -A PORT_NAMES=(
  [22]="SSH"        [25]="SMTP"       [53]="DNS/AdGuard"
  [80]="HTTP"       [443]="HTTPS"     [445]="Samba"
  [139]="Samba-NB"  [853]="DoT"       [3000]="Semaphore/AGH"
  [8080]="AGH-Web"  [8443]="HTTPS-alt" [51820]="WireGuard"
)
for PORT in 22 25 53 80 139 443 445 853 3000 8080 8443 51820; do
  NAME="${PORT_NAMES[$PORT]}"
  TCP_OK=$(ss -tlnp 2>/dev/null | grep -c ":${PORT} " || echo 0)
  UDP_OK=$(ss -ulnp 2>/dev/null | grep -c ":${PORT} " || echo 0)
  TOTAL=$((TCP_OK + UDP_OK))
  if [ "$TOTAL" -gt 0 ]; then
    PROTO=""
    [ "$TCP_OK" -gt 0 ] && PROTO="${PROTO}TCP "
    [ "$UDP_OK" -gt 0 ] && PROTO="${PROTO}UDP"
    printf "    ${G}%-6s${X} ${C}%-12s${X} ${G}open${X} [%s]\n" "$PORT" "$NAME" "$PROTO"
  else
    # Check if UFW blocks it or just not running
    printf "    ${Y}%-6s${X} ${C}%-12s${X} ${Y}closed${X}\n" "$PORT" "$NAME"
  fi
done

printf "\n%s\n  ${W}Rooted by VladiMIR | AI   v2026-05-01${X}\n%s\n" "$SEP" "$SEP"
