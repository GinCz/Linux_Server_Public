#!/usr/bin/env bash
# =============================================================
# Script:      sos_v2026-04-28.sh
# Version:     v2026-04-28c
# Servers:     222-DE-NetCup xxx.xxx.xxx.222 / 109-RU-FastVDS xxx.xxx.xxx.109
# Description: Universal server stress analyzer and health monitor.
#              Auto-detects server role (WEB / VPN / DOCKER) and shows
#              relevant sections: CPU, RAM, Disk, Network, PHP-FPM, Nginx,
#              MariaDB, CrowdSec, Fail2Ban, UFW, Docker, OOM, Swap, I/O.
# Usage:       sos [time_window]
#                sos          -> default 1h
#                sos 30m      -> last 30 minutes
#                sos 1h       -> last 1 hour
#                sos 3h       -> last 3 hours
#                sos 24h      -> last 24 hours
#                sos 120h     -> last 120 hours
# Install:     cp sos_v2026-04-28.sh /usr/local/bin/sos && chmod +x /usr/local/bin/sos
# Dependencies: bash, ps, df, free, ss, ip, awk, grep, find, dmesg
#               Optional: nginx, mysql/mariadb, php-fpm, docker, crowdsec,
#                         fail2ban, ufw, wg, awg, xray
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
have(){ command -v "$1" >/dev/null 2>&1; }          # check if command exists
SEP="${Y}$(printf '=%.0s' {1..90})${X}"             # full-width separator line
H(){ printf "\n${Y}=============== %s${X}\n" "$1"; } # section header printer

# ── parse time window to minutes ──────────────────────────────────────────────
# Default: 60 min. Accepts: 30m, 1h, 3h, 24h, 120h, etc.
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
# Color-code load: green < 60%, yellow 60-90%, red >= 90%
[ "$LOAD_PCT" -ge 90 ] && LC="$R" || { [ "$LOAD_PCT" -ge 60 ] && LC="$Y" || LC="$G"; }

# ── auto-detect server role ────────────────────────────────────────────────────
# Role determines which sections are shown (WEB / VPN / DOCKER / GENERIC)
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

# ══════════════════════════════════════════════════════════════════════════════
# SECTION: DISK USAGE
# Shows all /dev partitions with size, used, available, percent, mountpoint
# ══════════════════════════════════════════════════════════════════════════════
H "DISK"
df -h --output=source,size,used,avail,pcent,target 2>/dev/null \
  | grep -E '^(Filesystem|/dev)' \
  | awk -v c="$C" -v x="$X" \
    'NR==1{printf "  %-20s %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6;next}
           {printf "  %s%-20s%s %6s %6s %6s %5s  %s\n",c,$1,x,$2,$3,$4,$5,$6}'

# ══════════════════════════════════════════════════════════════════════════════
# SECTION: TOP PROCESSES BY CPU AND RAM
# ══════════════════════════════════════════════════════════════════════════════
H "TOP 10 CPU%"
ps -eo pid,user,%cpu,pmem,args --sort=-%cpu 2>/dev/null \
  | head -11 | tail -10 \
  | awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-10s %5s %5s  %s\n",c,$1,x,$2,$3,$4,$5}'

H "TOP 15 RAM"
ps -eo pid,user,%cpu,pmem,rss,args --sort=-rss 2>/dev/null \
  | head -16 | tail -15 \
  | awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-10s %5s %5s  %6.1fMB  %s\n",c,$1,x,$2,$3,$4,$5/1024,$6}'

# ══════════════════════════════════════════════════════════════════════════════
# SECTION: OOM KILLER
# Checks dmesg (since last boot) and syslog for Out-Of-Memory kill events
# ══════════════════════════════════════════════════════════════════════════════
H "OOM KILLER (last boot)"
OOM_HITS=$(dmesg 2>/dev/null | grep -c 'oom-kill\|Out of memory\|Killed process' || echo 0)
if [ "${OOM_HITS:-0}" -gt 0 ]; then
  printf "  ${R}OOM events: %d${X}\n" "$OOM_HITS"
  dmesg 2>/dev/null | grep -E 'oom-kill|Out of memory|Killed process' | tail -5 \
    | awk -v r="$R" -v x="$X" '{printf "  %s%s%s\n",r,$0,x}'
else
  printf "  ${G}No OOM kills detected${X}\n"
fi
# Also check syslog for recent OOM entries (last 200 lines)
OOM_SYSLOG=$(grep -E 'oom-kill|Out of memory|Killed process' /var/log/syslog 2>/dev/null \
  | tail -n 200 | wc -l)
[ "${OOM_SYSLOG:-0}" -gt 0 ] && \
  printf "  ${R}OOM entries in syslog: %d${X}\n" "$OOM_SYSLOG"

# ══════════════════════════════════════════════════════════════════════════════
# SECTION: NETWORK
# Shows socket summary and per-interface RX/TX traffic counters
# ══════════════════════════════════════════════════════════════════════════════
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

# ══════════════════════════════════════════════════════════════════════════════
# WEB SERVER SECTIONS — only shown when ROLE=WEB (nginx + /var/www present)
# Covers: PHP-FPM, traffic, HTTP status, attacks, errors, DB, security
# ══════════════════════════════════════════════════════════════════════════════
if [ "$ROLE" = "WEB" ]; then

  # PHP-FPM worker count and total RAM per pool user
  H "PHP-FPM POOLS"
  ps -eo user,rss,args 2>/dev/null | grep 'php-fpm\|php-cgi' \
    | awk -v c="$C" -v x="$X" \
      '{p=$1;r=$2;cnt[p]++;tot[p]+=r}
       END{for(p in cnt)printf "  %s%-26s%s %4d wk  %7.1fMB\n",c,p,x,cnt[p],tot[p]/1024}' \
    | sort -k4 -rn

  # Top 5 access logs by line count (= traffic volume) in the time window
  H "TOP-5 TRAFFIC (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
    -exec wc -l {} + 2>/dev/null | sort -rn | head -6 \
    | awk '{printf "  %7d  %s\n",$1,$2}'

  # Top 10 source IPs across all access logs in the time window
  H "TOP-10 IPs (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
    -exec tail -n 2000 {} + 2>/dev/null \
    | awk '{print $1}' | sort | uniq -c | sort -rn | head -10 \
    | awk -v em="$EM" '{printf "  %6d %s %s\n",$1,em,$2}'

  # HTTP response code distribution: 2xx=green, 3xx=cyan, 4xx=yellow, 5xx=red
  H "HTTP STATUS (last $TW)"
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
    -exec tail -n 2000 {} + 2>/dev/null \
    | awk '{print $9}' | grep -E '^[0-9]{3}$' | sort | uniq -c | sort -rn | head -10 \
    | awk -v g="$G" -v c="$C" -v y="$Y" -v r="$R" -v x="$X" -v em="$EM" \
      '{if($2~/^2/)col=g; else if($2~/^3/)col=c; else if($2~/^4/)col=y; else col=r;
        printf "  %6d %s %sHTTP %s%s\n",$1,em,col,$2,x}'

  # WordPress brute-force detection: IPs hitting wp-login.php
  # >100 hits = red (attack), >20 = yellow (suspicious), else white
  H "WP-LOGIN ATTACKS (last $TW)"
  {
    find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" \
      -exec grep -h 'wp-login.php' {} + 2>/dev/null
    [ -d /var/log/nginx ] && grep -rh 'wp-login.php' /var/log/nginx/*.log 2>/dev/null
  } | awk '{print $1}' | sort | uniq -c | sort -rn | head -10 \
    | awk -v r="$R" -v y="$Y" -v w="$W" -v x="$X" \
      '{col=(($1>100)?r:(($1>20)?y:w)); printf "  %s%5d%s  %s\n",col,$1,x,$2}'

  # Count 502/503 errors per domain — yellow >=1, red >=10
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

  # PHP-FPM slow log entries — red if any slow queries found
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

  # Nginx slow requests: scan access logs for request_time >= 3s
  # Scans last 5000 lines per log; parses last float field as request_time
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

  # PHP error rate per domain: errors / total requests * 100%
  # Red >= 5%, yellow >= 1%, green < 1%
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

  # Nginx worker count, TCP connections, stub status (if enabled)
  H "NGINX"
  have nginx && {
    printf "  ${C}Workers:${X} ${G}%s${X}  TCP established: ${G}%s${X}\n" \
      "$(pgrep -x nginx | wc -l)" \
      "$(ss -tnp state established 2>/dev/null | wc -l)"
    STUB=$(curl -s --max-time 2 http://127.0.0.1/nginx_status 2>/dev/null)
    [ -n "$STUB" ] && echo "$STUB" | awk '/Active/{printf "  Active connections: %s\n",$3}'
  }

  # MariaDB: connected threads, running queries, slow queries, uptime
  # Warns if MariaDB was restarted within last 24 hours
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

  # Database sizes from information_schema — red >= 500MB, yellow >= 100MB
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

  # Critical nginx/php error patterns in error logs within the time window
  H "CRITICAL ERRORS (last $TW)"
  find /var/www/*/data/logs/ -name "*error.log" -mmin "-${M}" \
    -exec grep -iE 'fatal|Out of memory|upstream timed out|connect\(\) failed|no live upstreams' {} + \
    2>/dev/null | tail -10

  # CrowdSec active bans and recent alerts
  H "CROWDSEC"
  have cscli && {
    BANS=$(cscli decisions list 2>/dev/null | awk 'BEGIN{c=0}/^\|/{c++}END{print (c>0?c-1:0)}')
    printf "  ${C}Bans:${X} ${R}%s${X}\n" "$BANS"
    cscli alerts list --since "$TW" -l 10 2>/dev/null | head -12 | sed 's/^/  /'
  }

  # Fail2ban: current and total bans per jail; UFW status and active rules
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
# ── end WEB sections ──────────────────────────────────────────────────────────

# ══════════════════════════════════════════════════════════════════════════════
# VPN SERVER SECTIONS — only shown when ROLE=VPN/* (xray / wg / awg present)
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$ROLE" == VPN* ]]; then

  # WireGuard / AmneziaWG interface info
  H "VPN STATUS"
  for WG_CMD in wg awg; do
    have "$WG_CMD" && {
      printf "  ${C}%s interfaces:${X}\n" "$WG_CMD"
      "$WG_CMD" show all 2>/dev/null \
        | grep -E '^interface|peer|endpoint|transfer|latest' | sed 's/^/    /'
    }
  done
  # Xray process status and active TCP connections
  have xray && {
    printf "  ${C}Xray:${X} "
    systemctl is-active xray 2>/dev/null \
      | awk -v g="$G" -v r="$R" -v x="$X" '{col=($0=="active")?g:r; printf "%s%s%s\n",col,$0,x}'
    XRAY_CONNS=$(ss -tnp state established 2>/dev/null \
      | grep -c 'xray\|/usr/local/bin/xray' || echo 0)
    printf "  ${C}Xray TCP established:${X} ${G}%s${X}\n" "$XRAY_CONNS"
  }

  # Total peer count per VPN interface
  H "VPN PEERS"
  for WG_CMD in wg awg; do
    have "$WG_CMD" && {
      PC=$("$WG_CMD" show all peers 2>/dev/null | wc -l)
      printf "  ${C}%s peers total:${X} ${G}%s${X}\n" "$WG_CMD" "$PC"
    }
  done

  # RX/TX counters for VPN tunnel interfaces (wg, awg, tun)
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

  # Fail2ban and UFW for VPN servers
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
# ── end VPN sections ──────────────────────────────────────────────────────────

# ══════════════════════════════════════════════════════════════════════════════
# SECTION: DOCKER — shown on all server roles
# ══════════════════════════════════════════════════════════════════════════════
H "DOCKER"
if have docker; then
  # Green = running (Up), red = stopped/exited
  docker ps -a --format "  {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null \
    | awk -v g="$G" -v r="$R" -v c="$C" -v x="$X" \
      '{col=($2~/Up/)?g:r; printf "  %s%-28s%s %s%s%s  %s\n",c,$1,x,col,$2,x,$3}'
else
  printf "  ${Y}docker not installed${X}\n"
fi

# ══════════════════════════════════════════════════════════════════════════════
# SECTION: SYSTEMD SERVICES
# Checks predefined list — skips services not installed on this server
# ══════════════════════════════════════════════════════════════════════════════
H "SERVICES"
SVC_LIST=(
  nginx mariadb mysql
  php8.1-fpm php8.2-fpm php8.3-fpm php8.4-fpm
  crowdsec crowdsec-firewall-bouncer
  fail2ban
  exim4 postfix docker ssh
  xray wg-quick@wg0 amnezia-wg
)
for SVC in "${SVC_LIST[@]}"; do
  systemctl list-units --type=service --all 2>/dev/null | grep -q "${SVC}.service" && {
    STATE=$(systemctl is-active "$SVC" 2>/dev/null)
    [ "$STATE" = "active" ] && SC="$G" || SC="$R"
    printf "  ${C}%-38s${X} %s%s${X}\n" "$SVC" "$SC" "$STATE"
  }
done

# ══════════════════════════════════════════════════════════════════════════════
# SECTION: DISK I/O
# 1-second sample of read/write throughput from /proc/diskstats
# ══════════════════════════════════════════════════════════════════════════════
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

# ══════════════════════════════════════════════════════════════════════════════
# SECTION: SWAP USAGE BY PROCESS
# Reads VmSwap from /proc/*/status — red >= 200MB, yellow >= 50MB
# ══════════════════════════════════════════════════════════════════════════════
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

# ══════════════════════════════════════════════════════════════════════════════
# SECTION: DMESG ERRORS
# Kernel ring buffer — last 10 error/warn/panic/oom/fail lines
# ══════════════════════════════════════════════════════════════════════════════
H "DMESG ERRORS"
dmesg -T 2>/dev/null | grep -iE 'error|fail|oom|kill|panic|warn' | tail -10 | sed 's/^/  /'

# ══════════════════════════════════════════════════════════════════════════════
# SECTION: CROWDSEC METRICS
# Parser hit/miss stats — useful for verifying detection is working
# ══════════════════════════════════════════════════════════════════════════════
H "CROWDSEC METRICS"
have cscli && cscli metrics 2>/dev/null \
  | awk '/Parsers/{p=1} p&&/\|/{printf "  %s\n",$0}' | head -8

# ── footer ─────────────────────────────────────────────────────────────────────
printf "\n%s\n  ${W}Rooted by VladiMIR | AI   v2026-04-28c${X}\n%s\n" "$SEP" "$SEP"
