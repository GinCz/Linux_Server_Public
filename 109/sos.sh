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
free -h | awk -v c="$C" -v x="$X" '/^Mem:/{printf "   %sRAM:%s %s/%s (free %s)",c,x,$3,$2,$4}'
free -h | awk -v c="$C" -v x="$X" '/^Swap:/{printf "   %sSwap:%s %s/%s\n",c,x,$3,$2}'
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
for SVC in nginx mariadb mysql php8.1-fpm php8.2-fpm php8.3-fpm php8.4-fpm \
           crowdsec crowdsec-firewall-bouncer exim4 postfix docker ssh; do
  systemctl list-units --type=service --all 2>/dev/null | grep -q "${SVC}.service" && {
    STATE=$(systemctl is-active "$SVC" 2>/dev/null)
    [ "$STATE" = "active" ] && SC="$G" || SC="$R"
    printf "  ${C}%-35s${X} %s%s${X}\n" "$SVC" "$SC" "$STATE"
  }
done
H "SWAP TOP-3 PROCESSES"
awk '/VmSwap/{swap=$2} /Name/{name=$2} swap>0{print swap,name}' /proc/*/status 2>/dev/null | \
  sort -rn | head -3 | awk -v c="$C" -v x="$X" '{printf "  %s%-30s%s %6.1f MB\n",c,$2,x,$1/1024}'
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
H "HTTP 502/503 BY DOMAIN (last $TW)"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" 2>/dev/null | while read -r LOG; do
  DOM=$(echo "$LOG" | grep -oP '/var/www/\K[^/]+')
  CNT=$(tail -n 5000 "$LOG" 2>/dev/null | awk '$9=="502"||$9=="503"{c++}END{print c+0}')
  [ "$CNT" -gt 0 ] && {
    [ "$CNT" -ge 10 ] && COL="$R" || COL="$Y"
    printf "  ${C}%-35s${X} %s%d errors${X}\n" "$DOM" "$COL" "$CNT"
  }
done
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
have cscli && cscli metrics 2>/dev/null | awk '/Parsers/{p=1} p&&/\|/{printf "  %s\n",$0}' | head -8
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
H "WP PLUGIN HEALTH"
# wpval KEY — парсит wp-config.php через stdin
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
  printf "  ${G}\xe2\x9c\x85 \xd0\x92\xd1\x81\xd0\xb5 OK \xe2\x80\x94 \xd0\xbd\xd0\xb5\xd1\x82 \xd0\xb4\xd0\xbe\xd0\xbc\xd0\xb5\xd0\xbd\xd0\xbe\xd0\xb2 \xd1\x81 502/503 \xd0\xb8\xd0\xbb\xd0\xb8 memory errors${X}\n"
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
    # --- Топ-3 тяжёлых PHP-FPM процесса для этого домена/пула (по RAM) ---
    HEAVY_PROCS=$(ps -eo user,%cpu,rss,args --sort=-rss 2>/dev/null \
      | awk -v u="$WWWDIR" '$1==u && /php-fpm/{printf "    CPU:%s  RAM:%6.1fMB  %s\n",$2,$3/1024,$4}' \
      | head -3)
    # --- slow log ---
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
printf "%s\n  ${W}Rooted by VladiMIR | AI   v2026-04-13n${X}\n%s\n" "$SEP" "$SEP"
