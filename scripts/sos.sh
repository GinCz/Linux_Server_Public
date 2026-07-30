#!/usr/bin/env bash
TW="${1:-1h}"
clear
G=$'\033[1;32m'; C=$'\033[1;36m'; Y=$'\033[1;33m'; R=$'\033[1;31m'; W=$'\033[1;37m'; X=$'\033[0m'
EM=$'\342\200\224'
have(){ command -v "$1" >/dev/null 2>&1; }
SEP="${Y}$(printf '=%.0s' {1..90})${X}"
H(){ printf "${Y}=============== %s${X}\n" "$1"; }
M=60
[[ "$TW" =~ ^([0-9]+)m$ ]] && M="${BASH_REMATCH[1]}"
[[ "$TW" =~ ^([0-9]+)h$ ]] && M="$(( ${BASH_REMATCH[1]}*60 ))"
NOW=$(date '+%Y-%m-%d %H:%M:%S')
HOST=$(hostname)
IP=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
CORES=$(nproc || echo 1)
LOAD=$(awk '{print $1,$2,$3}' /proc/loadavg)
LOAD1=$(awk '{print $1}' /proc/loadavg)
LOAD_PCT=$(awk "BEGIN{printf \"%.0f\",($LOAD1/$CORES)*100}")
[ "$LOAD_PCT" -ge 90 ] && LC="$R" || { [ "$LOAD_PCT" -ge 60 ] && LC="$Y" || LC="$G"; }
printf "%s\n" "$SEP"
printf "  ${W}SOS ${Y}%s${X}  |  ${G}%s${X}  |  ${C}%s${X}  ${G}%s${X}  Load: ${LC}%s${X} (${LC}%s%%${X}/%sc)\n" "$TW" "$NOW" "$HOST" "$IP" "$LOAD" "$LOAD_PCT" "$CORES"
printf "%s\n" "$SEP"
printf "  ${C}Uptime:${X} %s" "$(uptime -p)"
# FIX #1: RAM — use /proc/meminfo for reliable parsing instead of free -h
awk -v c="$C" -v g="$G" -v y="$Y" -v r="$R" -v x="$X" '
  /^MemTotal:/  { total=$2 }
  /^MemAvailable:/ { avail=$2 }
  /^SwapTotal:/  { stotal=$2 }
  /^SwapFree:/   { sfree=$2 }
  END {
    used=total-avail
    pct=(total>0)?int(used/total*10):0
    pct100=(total>0)?int(used/total*100):0
    bar=""
    for(i=1;i<=10;i++) bar=bar ((i<=pct)?"*":".")
    col=(pct100>=90)?r:((pct100>=70)?y:g)
    printf "   %sRAM:%s  [%s%s%s] %s%d%%%s %s used / %s total\n",
      c,x, col,bar,x, col,pct100,x,
      sprintf("%.0fMi",used/1024), sprintf("%.0fMi",total/1024)
    sused=stotal-sfree
    spct=(stotal>0)?int(sused/stotal*100):0
    scol=(spct>=80)?r:((spct>=50)?y:g)
    printf "   %sSwap:%s %s%d%%%s %s/%s\n",
      c,x, scol,spct,x,
      sprintf("%.0fMi",sused/1024), sprintf("%.0fMi",stotal/1024)
  }
' /proc/meminfo
H "DISK"
df -h --output=source,size,used,avail,pcent,target 2>/dev/null | grep -E '^(Filesystem|/dev)' | \
  awk -v c="$C" -v x="$X" \
    'NR==1{printf "  %-20s %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6;next}
          {printf "  %s%-20s%s %6s %6s %6s %5s  %s\n",c,$1,x,$2,$3,$4,$5,$6}'
H "TOP 10 CPU%"
ps -eo pid,user,%cpu,pmem,args --sort=-%cpu 2>/dev/null | head -11 | tail -10 | \
  awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-10s %5s %5s  %s\n",c,$1,x,$2,$3,$4,$5}'
H "TOP 15 RAM"
ps -eo pid,user,%cpu,pmem,rss,args --sort=-rss 2>/dev/null | head -16 | tail -15 | \
  awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-10s %5s %5s  %6.1fMB  %s\n",c,$1,x,$2,$3,$4,$5/1024,$6}'
H "PHP-FPM POOLS"
ps -eo user,rss,args 2>/dev/null | grep 'php-fpm\|php-cgi' | \
  awk -v c="$C" -v x="$X" \
    '{p=$1;r=$2;cnt[p]++;tot[p]+=r}
     END{for(p in cnt)printf "  %s%-26s%s %4d wk  %7.1fMB\n",c,p,x,cnt[p],tot[p]/1024}' | sort -k4 -rn
H "TOP-5 TRAFFIC (last $TW)"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" -exec wc -l {} + 2>/dev/null | \
  sort -rn | head -6 | awk '{printf "  %7d  %s\n",$1,$2}'
H "TOP-10 IPs (last $TW)"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" -exec tail -n 2000 {} + 2>/dev/null | \
  awk '{print $1}' | sort | uniq -c | sort -rn | head -10 | \
  awk -v em="$EM" '{printf "  %6d %s %s\n",$1,em,$2}'
H "HTTP STATUS (last $TW)"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" -exec tail -n 2000 {} + 2>/dev/null | \
  awk '{print $9}' | grep -E '^[0-9]{3}$' | sort | uniq -c | sort -rn | head -10 | \
  awk -v g="$G" -v c="$C" -v y="$Y" -v r="$R" -v x="$X" -v em="$EM" \
    '{if($2~/^2/)col=g; else if($2~/^3/)col=c; else if($2~/^4/)col=y; else col=r
      printf "  %6d %s %sHTTP %s%s\n",$1,em,col,$2,x}'
H "WP-LOGIN ATTACKS (last $TW)"
grep -h 'wp-login.php' /var/www/*/data/logs/*access.log /var/log/nginx/*.log 2>/dev/null | \
  awk '{print $1}' | sort | uniq -c | sort -rn | head -10 | \
  awk -v r="$R" -v y="$Y" -v w="$W" -v x="$X" \
    '{col=(($1>100)?r:(($1>20)?y:w)); printf "  %s%5d%s  %s\n",col,$1,x,$2}'
H "NGINX"
have nginx && {
  printf "  ${C}Workers:${X} ${G}%s${X}  TCP: ${G}%s${X}\n" \
    "$(pgrep -x nginx | wc -l)" "$(ss -tnp state established 2>/dev/null | wc -l)"
  STUB=$(curl -s --max-time 2 http://127.0.0.1/nginx_status 2>/dev/null)
  [ -n "$STUB" ] && echo "$STUB" | awk '/Active/{printf "  Active: %s\n",$3}'
}
H "MYSQL"
have mysql && {
  mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_connected';" 2>/dev/null | \
    awk -v c="$C" -v g="$G" -v x="$X" '{printf "  %sConnected:%s %s%s%s\n",c,x,g,$2,x}'
  mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_running';" 2>/dev/null | \
    awk -v c="$C" -v g="$G" -v x="$X" '{printf "  %sRunning:%s   %s%s%s\n",c,x,g,$2,x}'
  mysql -N -e "SHOW GLOBAL STATUS LIKE 'Slow_queries';" 2>/dev/null | \
    awk -v c="$C" -v x="$X" '{printf "  %sSlow:%s      %s\n",c,x,$2}'
}
H "DOCKER"
have docker && docker ps -a --format "  {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null | \
  awk -v g="$G" -v r="$R" -v c="$C" -v x="$X" \
    '{col=($2~/Up/)?g:r; printf "  %s%-28s%s %s%s%s  %s\n",c,$1,x,col,$2,x,$3}'
H "CRITICAL ERRORS (last $TW)"
find /var/www/*/data/logs/ -name "*error.log" -mmin "-${M}" \
  -exec grep -iE 'fatal|Out of memory|upstream timed out|connect\(\) failed|no live upstreams' {} + \
  2>/dev/null | tail -20 | while IFS= read -r LINE; do
    printf "  %s\n\n" "$LINE"
done
H "CROWDSEC"
have cscli && {
  BANS=$(cscli decisions list 2>/dev/null | awk 'BEGIN{c=0}/^\|/{c++}END{print (c>0?c-1:0)}')
  printf "  ${C}Bans:${X} ${R}%s${X}\n" "$BANS"
  cscli alerts list --since "$TW" -l 10 2>/dev/null | head -12 | sed 's/^/  /'
}
H "SERVICES"
for SVC in nginx mariadb mysql \
           fp2-php56-fpm fp2-php74-fpm fp2-php80-fpm fp2-php81-fpm fp2-php82-fpm fp2-php83-fpm fp2-php84-fpm \
           crowdsec crowdsec-firewall-bouncer fail2ban \
           x-ui AdGuardHome \
           smbd nmbd \
           exim4 postfix docker ssh; do
  systemctl list-units --type=service --all 2>/dev/null | grep -q "${SVC}.service" && {
    STATE=$(systemctl is-active "$SVC" 2>/dev/null)
    [ "$STATE" = "active" ] && SC="$G" || SC="$R"
    printf "  ${C}%-35s${X} %s%s${X}\n" "$SVC" "$SC" "$STATE"
  }
done
# xray process check
if pgrep -x "xray-linux-amd64" > /dev/null 2>&1 || pgrep -f "xray-linux-amd" > /dev/null 2>&1; then
  printf "  ${C}%-35s${X} ${G}running${X}\n" "xray (process)"
else
  [ -d /usr/local/x-ui ] && printf "  ${C}%-35s${X} ${R}NOT RUNNING${X}\n" "xray (process)"
fi
H "FASTPANEL2 SERVICES"
FP2_FOUND=0
for SVC in fastpanel2 fp2-nginx fp2-php56-fpm fp2-php84-fpm; do
  systemctl list-units --type=service --all 2>/dev/null | grep -q "${SVC}.service" && FP2_FOUND=1
done
if [ "$FP2_FOUND" -eq 0 ]; then
  printf "  ${Y}FastPanel2 not detected on this server${X}\n"
else
  for SVC in fastpanel2 fp2-nginx fp2-php56-fpm fp2-php74-fpm fp2-php80-fpm fp2-php81-fpm fp2-php82-fpm fp2-php83-fpm fp2-php84-fpm; do
    systemctl list-units --type=service --all 2>/dev/null | grep -q "${SVC}.service" && {
      STATE=$(systemctl is-active "$SVC" 2>/dev/null)
      [ "$STATE" = "active" ] && SC="$G" || SC="$R"
      printf "  ${C}%-35s${X} %s%s${X}\n" "$SVC" "$SC" "$STATE"
    }
  done
fi
H "SWAP TOP-5 PROCESSES"
# FIX #2: parse /proc/*/status correctly — one pass per file, not mixed stream
for f in /proc/*/status; do
  pid=$(awk '/^Pid:/{print $2}' "$f" 2>/dev/null)
  name=$(awk '/^Name:/{print $2}' "$f" 2>/dev/null)
  swap=$(awk '/^VmSwap:/{print $2}' "$f" 2>/dev/null)
  [ -n "$swap" ] && [ "$swap" -gt 0 ] 2>/dev/null && echo "$swap $pid $name"
done 2>/dev/null | sort -rn | head -5 | \
  awk -v c="$C" -v x="$X" '{printf "  PID %-7s %s%-30s%s %6.1f MB\n",$2,c,$3,x,$1/1024}'
H "OPEN PORTS"
printf "  TCP LISTEN:\n"
ss -tlnp 2>/dev/null | awk 'NR>1 && $1=="LISTEN" {
  addr=$4; prog=$6
  gsub(/.*users:\(\(/, "", prog); gsub(/,.*/, "", prog); gsub(/"/, "", prog)
  printf "    %-35s %s\n", addr, (prog?"\"" prog "\"":"")
}' | sort -u
printf "\n  UDP LISTEN:\n"
ss -ulnp 2>/dev/null | awk 'NR>1 && $1=="UNCONN" {
  addr=$4; prog=$6
  gsub(/.*users:\(\(/, "", prog); gsub(/,.*/, "", prog); gsub(/"/, "", prog)
  printf "    %-35s %s\n", addr, (prog?"\"" prog "\"":"")
}' | sort -u
printf "\n  Key ports:\n"
check_port(){ local p=$1 n=$2
  ss -tlnp 2>/dev/null | grep -q ":${p}[[:space:]]" && T="open   [TCP ]" || T="closed"
  ss -ulnp 2>/dev/null | grep -q ":${p}[[:space:]]" && U=" [UDP]" || U=""
  [[ "$T" == "open"* ]] && COL="$G" || COL="$Y"
  printf "    %-6s %-15s %s%s${X}%s\n" "$p" "$n" "$COL" "$T" "$U"
}
check_port 22   "SSH"
check_port 53   "DNS"
check_port 80   "HTTP"
check_port 443  "HTTPS"
check_port 445  "Samba"
check_port 8080 "AGH-Web"
check_port 8443 "HTTPS-alt"
check_port 9100 "Prometheus"
# FIX #3: x-ui port — detect dynamically from x-ui db, fallback to process
if [ -d /usr/local/x-ui ]; then
  XUI_PORT=$(sqlite3 /etc/x-ui/x-ui.db "SELECT value FROM settings WHERE key='webPort';" 2>/dev/null)
  [ -z "$XUI_PORT" ] && XUI_PORT=$(ss -tlnp 2>/dev/null | grep x-ui | awk '{print $4}' | grep -oP ':\K[0-9]+' | head -1)
  [ -z "$XUI_PORT" ] && XUI_PORT="54321"
  check_port "$XUI_PORT" "x-ui"
fi
check_port 7777 "FP2-panel"
check_port 8888 "FP2-http"
H "BLACKLIST SYSTEM"
if ipset list vladblacklist > /dev/null 2>&1; then
  COUNT=$(ipset list vladblacklist | awk '/^Members:/{found=1;next} found{count++} END{print count+0}')
  printf "  ${C}ipset vladblacklist:${X}    loaded ${G}$COUNT${X} IPs/subnets\n"
  if iptables -C INPUT -m set --match-set vladblacklist src -j DROP 2>/dev/null; then
    printf "  ${C}iptables DROP rule:${X}     ${G}active — protected${X}\n"
  else
    printf "  ${C}iptables DROP rule:${X}     ${R}MISSING — not protected!${X}\n"
    printf "  ${Y}Fix: iptables -I INPUT -m set --match-set vladblacklist src -j DROP${X}\n"
  fi
else
  printf "  ${Y}ipset vladblacklist: not loaded${X}\n"
fi
H "DISK I/O"
DEV=$(awk '{print $3}' /proc/diskstats 2>/dev/null | grep -E '^(vd|sd|nvme)[a-z0-9]+$' | grep -v '[0-9]$' | head -1)
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
H "CROWDSEC METRICS"
have cscli && cscli metrics 2>/dev/null | awk '/Parsers/{p=1} p&&/\|/{printf "  %s\n",$0}' | head -10
H "MARIADB UPTIME"
have mysql && {
  UPSEC=$(mysql -N -e "SHOW GLOBAL STATUS LIKE 'Uptime';" 2>/dev/null | awk '{print $2}')
  if [ -n "$UPSEC" ]; then
    UPDAY=$((UPSEC/86400)); UPHR=$(( (UPSEC%86400)/3600 )); UPMIN=$(( (UPSEC%3600)/60 ))
    if [ "$UPDAY" -eq 0 ] && [ "$UPHR" -lt 24 ]; then COL="$R"; WARN=" ⚠️  RECENT RESTART!"
    else COL="$G"; WARN=""; fi
    printf "  ${C}MariaDB uptime:${X} %s%dd %dh %dm${X}%s\n" "$COL" "$UPDAY" "$UPHR" "$UPMIN" "$WARN"
  fi
}
H "CRONTAB ROOT"
printf "  crontab -l (root):\n"
crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$' | sed 's/^/  /'
printf "  Files in /etc/cron.d/: $(ls /etc/cron.d/ 2>/dev/null | tr '\n' ' ')\n"
H "LAST LOGINS SSH"
last -n 15 2>/dev/null | head -15 | awk '{printf "  %-12s %-8s %-18s %s %s %s %s\n",$1,$2,$3,$4,$5,$6,$7}'
H "DMESG ERRORS"
dmesg --time-format iso 2>/dev/null | grep -iE 'error|fail|warn|oom' | grep -v 'acpi\|RAS:' | tail -5 | sed 's/^/  /'
H "WP PLUGIN HEALTH"
wpval() {
  local KEY="$1"
  awk -v key="$KEY" '
    {
      gsub(/\/\/.*$/, ""); gsub(/\/\*.*\*\//, ""); gsub(/^[ \t]+|[ \t]+$/, "")
      n = split($0, parts, "define")
      for (i=2; i<=n+1; i++) {
        seg = (i<=n) ? parts[i] : ""
        if (seg == "") continue
        sub(/^[[:space:]]*\([[:space:]]*/, "", seg)
        if (match(seg, /^["'"'"']/) ) {
          q1 = substr(seg,1,1)
          rest = substr(seg,2)
          klen = length(key)
          if (substr(rest,1,klen) == key && substr(rest,klen+1,1) == q1) {
            rest = substr(rest, klen+2)
            if (match(rest, /[[:space:]]*,[[:space:]]*/)) {
              rest = substr(rest, RSTART+RLENGTH)
              if (match(rest, /^["'"'"']/)) {
                q2 = substr(rest,1,1); rest=substr(rest,2)
                val=""
                n2=split(rest,chars,"")
                for(j=1;j<=n2;j++){
                  if(chars[j]==q2) break
                  val=val chars[j]
                }
                if(val!=""){print val; exit}
              }
            }
          }
        }
      }
      if (key == "table_prefix" && match($0, /\$table_prefix[[:space:]]*=[[:space:]]*/)) {
        rest = substr($0, RSTART+RLENGTH)
        if (match(rest, /^["'"'"']/)) {
          q = substr(rest,1,1); rest=substr(rest,2)
          val=""
          n=split(rest,chars,"")
          for(i=1;i<=n;i++){
            if(chars[i]==q) break
            val=val chars[i]
          }
          if(val!=""){print val; exit}
        }
      }
    }
  '
}
read_wpconfig() {
  local CFGFILE="$1/wp-config.php"
  local OWNER
  OWNER=$(stat -c '%U' "$CFGFILE" 2>/dev/null)
  if [ -z "$OWNER" ] || [ "$OWNER" = "root" ]; then
    cat "$CFGFILE" 2>/dev/null
  else
    sudo -n -u "$OWNER" cat "$CFGFILE" 2>/dev/null
  fi
}
PROBLEM_DOMAINS=()
while IFS= read -r LOG; do
  CNT=$(tail -n 10000 "$LOG" 2>/dev/null | awk '$9=="502"||$9=="503"{c++}END{print c+0}')
  CNT=$(echo "$CNT" | tr -d '[:space:]')
  if [[ "$CNT" =~ ^[0-9]+$ ]] && [ "$CNT" -ge 5 ]; then
    DOM=$(basename "$LOG" | sed 's/-frontend\.access\.log//' | sed 's/\.access\.log//')
    WWWDIR=$(echo "$LOG" | grep -oP '/var/www/\K[^/]+')
    PROBLEM_DOMAINS+=("$WWWDIR:$DOM")
  fi
done < <(find /var/www/*/data/logs/ -name "*access.log" -mmin "-1440" 2>/dev/null)
while IFS= read -r LOG; do
  CNT=$(grep -c 'Allowed memory' "$LOG" 2>/dev/null || echo 0)
  CNT=$(echo "$CNT" | tr -d '[:space:]')
  if [[ "$CNT" =~ ^[0-9]+$ ]] && [ "$CNT" -ge 1 ]; then
    DOM=$(basename "$LOG" | sed 's/-frontend\.error\.log//' | sed 's/\.error\.log//')
    WWWDIR=$(echo "$LOG" | grep -oP '/var/www/\K[^/]+')
    PROBLEM_DOMAINS+=("$WWWDIR:$DOM")
  fi
done < <(find /var/www/*/data/logs/ -name "*error.log" -mmin "-1440" 2>/dev/null)
IFS=$'\n' PROBLEM_DOMAINS=($(printf "%s\n" "${PROBLEM_DOMAINS[@]}" | sort -u))
unset IFS
if [ ${#PROBLEM_DOMAINS[@]} -eq 0 ]; then
  printf "  ${G}\xe2\x9c\x85 All OK — no domains with 502/503 or memory errors${X}\n"
else
  for ENTRY in "${PROBLEM_DOMAINS[@]}"; do
    WWWDIR="${ENTRY%%:*}"
    DOM="${ENTRY##*:}"
    WPDIR="/var/www/${WWWDIR}/data/www/${DOM}"
    [ -d "$WPDIR" ] || continue
    WPCFG=$(read_wpconfig "$WPDIR")
    DB_NAME=""; TBL_PREFIX="wp_"; WP_MEM=""
    if [ -n "$WPCFG" ]; then
      DB_NAME=$(echo    "$WPCFG" | wpval DB_NAME)
      TBL_PREFIX=$(echo "$WPCFG" | wpval table_prefix)
      WP_MEM=$(echo     "$WPCFG" | wpval WP_MEMORY_LIMIT)
      TBL_PREFIX="${TBL_PREFIX:-wp_}"
    fi
    MEMLIMIT="not set"
    [ -n "$WP_MEM" ] && MEMLIMIT="WP: ${WP_MEM}"
    POOL_MEM=$(grep -r 'memory_limit' /etc/php/*/fpm/pool.d/ 2>/dev/null \
      | grep -i "${WWWDIR}" | grep -oP '[0-9]+[MmGg]' | head -1)
    [ -z "$POOL_MEM" ] && POOL_MEM=$(grep -r 'memory_limit' /etc/php/*/fpm/pool.d/ 2>/dev/null \
      | grep -i "${DOM}" | grep -oP '[0-9]+[MmGg]' | head -1)
    [ -n "$POOL_MEM" ] && MEMLIMIT="${MEMLIMIT} / pool: ${POOL_MEM}"
    PLUGIN_COUNT=0; ACTIVE_THEME="?"
    if [ -n "$DB_NAME" ]; then
      RAW=$(mysql -N "$DB_NAME" 2>/dev/null \
        -e "SELECT option_name, option_value FROM ${TBL_PREFIX}options \
            WHERE option_name IN ('active_plugins','stylesheet') LIMIT 2;")
      PLUGIN_COUNT=$(echo "$RAW" | grep -P '^active_plugins\t' \
        | grep -oP 's:\d+:"\K[^"]+\.php' | grep -c '\.php' || echo 0)
      PLUGIN_COUNT=$(echo "$PLUGIN_COUNT" | tr -d '[:space:]')
      ACTIVE_THEME=$(echo "$RAW" | grep -P '^stylesheet\t' | cut -f2 | tr -d '[:space:]')
    fi
    HEAVY_PROCS=$(ps -eo user,%cpu,rss,args --sort=-rss 2>/dev/null \
      | awk -v u="$WWWDIR" '$1==u && /php-fpm/{printf "    CPU:%s  RAM:%6.1fMB  %s\n",$2,$3/1024,$4}' \
      | head -3)
    SLOW_FUNCS=""
    for SLOW in /var/log/php*slow* /var/log/php*/slow.log \
                /var/www/"$WWWDIR"/data/logs/*slow*; do
      [ -f "$SLOW" ] || continue
      SF=$(grep -A5 "${DOM}\|${WWWDIR}" "$SLOW" 2>/dev/null \
        | grep 'function name' | grep -oP 'function name: \K\S+' \
        | sort | uniq -c | sort -rn | head -3 \
        | awk -v r="$R" -v y="$Y" -v x="$X" \
            '{col=($1>5)?r:y; printf "    \xf0\x9f\x90\xa2 %s%3d calls%s  %s\n",col,$1,x,$2}')
      [ -n "$SF" ] && { SLOW_FUNCS="$SF"; break; }
    done
    if [ -n "$WPCFG" ]; then CFG_OK="${G}cfg\xe2\x9c\x93${X}"; else CFG_OK="${R}cfg\xe2\x9c\x97${X}"; fi
    if [ -n "$DB_NAME" ];    then DBN_OK="${G}DB:${DB_NAME}${X}"; else DBN_OK="${R}DB?\xe2\x9c\x97${X}"; fi
    [[ "$PLUGIN_COUNT" =~ ^[0-9]+$ ]] && [ "$PLUGIN_COUNT" -ge 20 ] && PC_COL="$R" || PC_COL="$Y"
    printf "\n  ${R}\xe2\x9a\xa0\xef\xb8\x8f  ${C}%s${X}  [${Y}%s${X}]  %s  %s\n" \
      "$DOM" "$WWWDIR" "$CFG_OK" "$DBN_OK"
    printf "      mem: ${Y}%s${X}  plugins: %s%s${X}  theme: ${C}%s${X}\n" \
      "$MEMLIMIT" "$PC_COL" "$PLUGIN_COUNT" "${ACTIVE_THEME:-?}"
    if [ -n "$HEAVY_PROCS" ]; then
      printf "  ${W}Top PHP-FPM processes (pool: %s):${X}\n" "$WWWDIR"
      printf "%s\n" "$HEAVY_PROCS"
    fi
    if [ -n "$SLOW_FUNCS" ]; then
      printf "  ${W}Slow functions:${X}\n%s\n" "$SLOW_FUNCS"
    else
      printf "  ${Y}Slow log empty — enable request_slowlog_timeout = 3s in PHP-FPM pool${X}\n"
    fi
    if [ -z "$WPCFG" ]; then
      printf "  ${R}wp-config.php unreadable. Add to sudoers:\n    root ALL=(%s) NOPASSWD: /bin/cat${X}\n" "$WWWDIR"
    elif [ -z "$DB_NAME" ]; then
      printf "  ${R}DB_NAME not parsed from wp-config.php${X}\n"
      echo "$WPCFG" | grep -i 'define' | head -5 | sed 's/^/    /'
    fi
  done
fi
printf "%s\n  ${W}= Rooted by VladiMIR + AI | v.2026.07.30 | github.com/GinCz =${X}\n%s\n" "$SEP" "$SEP"
