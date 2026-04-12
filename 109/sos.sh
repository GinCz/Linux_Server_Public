#!/usr/bin/env bash
# Use via aliases only: sos | sos1 | sos3 | sos24 | sos120
TW="${1:-1h}"
clear
G=$'\033[1;32m'; C=$'\033[1;36m'; Y=$'\033[1;33m'; R=$'\033[1;31m'; W=$'\033[1;37m'; X=$'\033[0m'
EM=$'\342\200\224'
have(){ command -v "$1" >/dev/null 2>&1; }
H(){ printf "\n${Y}==================== %s ====================${X}\n" "$1"; }
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
printf "${W}\u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557\n"
printf "\u2551  \U0001F4CA SOS \u2014 ${Y}%s${W}  |  ${G}%s${W}\n" "$TW" "$NOW"
printf "\u2551  ${C}%s${W} | ${G}%s${W} | Load: ${LC}%s${W} (${LC}%s%%${W}/%sc)\n" "$HOST" "$IP" "$LOAD" "$LOAD_PCT" "$CORES"
printf "${W}\u255a\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255d${X}\n"

H $'\u2699\ufe0f  SYSTEM'
printf "  ${C}Uptime:${X} %s\n" "$(uptime -p)"
free -h | awk -v c="$C" -v x="$X" '/^Mem:/{printf "  %sRAM:%s  used %s / total %s (free %s)\n",c,x,$3,$2,$4}'
free -h | awk -v c="$C" -v x="$X" '/^Swap:/{printf "  %sSwap:%s used %s / total %s\n",c,x,$3,$2}'

H $'\U0001F4BF DISK'
df -h --output=source,size,used,avail,pcent,target 2>/dev/null | grep -E '^(Filesystem|/dev)' | \
  awk -v c="$C" -v x="$X" 'NR==1{printf "  %-20s %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6;next}{printf "  %s%-20s%s %6s %6s %6s %5s  %s\n",c,$1,x,$2,$3,$4,$5,$6}'

H $'\U0001F525 TOP 10 CPU%'
ps -eo pid,user,%cpu,pmem,args --sort=-%cpu 2>/dev/null | head -11 | tail -10 | \
  awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-10s %5s %5s  %s\n",c,$1,x,$2,$3,$4,$5}'

H $'\U0001F50D TOP 15 RAM'
ps -eo pid,user,%cpu,pmem,rss,args --sort=-rss 2>/dev/null | head -16 | tail -15 | \
  awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-10s %5s %5s  %6.1fMB  %s\n",c,$1,x,$2,$3,$4,$5/1024,$6}'

H $'\U0001F9E0 PHP-FPM POOLS'
ps -eo user,rss,args 2>/dev/null | grep 'php-fpm\|php-cgi' | \
  awk -v c="$C" -v x="$X" '{p=$1;r=$2;cnt[p]++;tot[p]+=r}END{for(p in cnt)printf "  %s%-26s%s %4d wk  %7.1fMB\n",c,p,x,cnt[p],tot[p]/1024}' | sort -k4 -rn

H $'\U0001F680 TOP-5 TRAFFIC (last '"$TW"')'
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" -exec wc -l {} + 2>/dev/null | sort -rn | head -6 | \
  awk '{printf "  %7d  %s\n",$1,$2}'

H $'\U0001F30D TOP-10 IPs (last '"$TW"')'
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" -exec tail -n 2000 {} + 2>/dev/null | \
  awk '{print $1}' | sort | uniq -c | sort -rn | head -10 | \
  awk -v em="$EM" '{printf "  %6d %s %s\n",$1,em,$2}'

H $'\U0001F4C8 HTTP STATUS (last '"$TW"')'
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" -exec tail -n 2000 {} + 2>/dev/null | \
  awk '{print $9}' | grep -E '^[0-9]{3}$' | sort | uniq -c | sort -rn | head -10 | \
  awk -v g="$G" -v c="$C" -v y="$Y" -v r="$R" -v x="$X" -v em="$EM" \
    '{if($2~/^2/)col=g; else if($2~/^3/)col=c; else if($2~/^4/)col=y; else col=r; printf "  %6d %s %sHTTP %s%s\n",$1,em,col,$2,x}'

H $'\U0001F510 WP-LOGIN ATTACKS (last '"$TW"')'
grep -h 'wp-login.php' /var/www/*/data/logs/*access.log /var/log/nginx/*.log 2>/dev/null | \
  awk '{print $1}' | sort | uniq -c | sort -rn | head -10 | \
  awk -v r="$R" -v y="$Y" -v w="$W" -v x="$X" \
    '{col=(($1>100)?r:(($1>20)?y:w)); printf "  %s%5d%s  %s\n",col,$1,x,$2}'

H $'\U0001F517 NGINX'
have nginx && {
  printf "  ${C}Workers:${X} ${G}%s${X}  TCP: ${G}%s${X}\n" "$(pgrep -x nginx | wc -l)" "$(ss -tnp state established 2>/dev/null | wc -l)"
  STUB=$(curl -s --max-time 2 http://127.0.0.1/nginx_status 2>/dev/null)
  [ -n "$STUB" ] && echo "$STUB" | awk '/Active/{printf "  Active: %s\n",$3}'
}

H $'\U0001F4BE MYSQL'
have mysql && {
  mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_connected';" 2>/dev/null | awk -v c="$C" -v g="$G" -v x="$X" '{printf "  %sConnected:%s %s%s%s\n",c,x,g,$2,x}'
  mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_running';"   2>/dev/null | awk -v c="$C" -v g="$G" -v x="$X" '{printf "  %sRunning:%s   %s%s%s\n",c,x,g,$2,x}'
  mysql -N -e "SHOW GLOBAL STATUS LIKE 'Slow_queries';"      2>/dev/null | awk -v c="$C" -v x="$X"             '{printf "  %sSlow:%s      %s\n",c,x,$2}'
}

H $'\U0001F433 DOCKER'
have docker && docker ps -a --format "  {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null | \
  awk -v g="$G" -v r="$R" -v c="$C" -v x="$X" '{col=($2~/Up/)?g:r; printf "  %s%-28s%s %s%s%s  %s\n",c,$1,x,col,$2,x,$3}'

H $'\u274c CRITICAL ERRORS (last '"$TW"')'
find /var/www/*/data/logs/ -name "*error.log" -mmin "-${M}" \
  -exec grep -iE 'fatal|Out of memory|upstream timed out|connect\(\) failed|no live upstreams' {} + 2>/dev/null | tail -10

H $'\U0001F6E1\ufe0f  CROWDSEC'
have cscli && {
  BANS=$(cscli decisions list 2>/dev/null | awk 'BEGIN{c=0}/^\|/{c++}END{print (c>0?c-1:0)}')
  printf "  ${C}Bans:${X} ${R}%s${X}\n" "$BANS"
  cscli alerts list --since "$TW" -l 10 2>/dev/null | head -12 | sed 's/^/  /'
}

H $'\U0001F527 SERVICES'
for SVC in nginx mariadb mysql php8.1-fpm php8.2-fpm php8.3-fpm php8.4-fpm crowdsec crowdsec-firewall-bouncer exim4 postfix docker ssh; do
  systemctl list-units --type=service --all 2>/dev/null | grep -q "${SVC}.service" && {
    STATE=$(systemctl is-active "$SVC" 2>/dev/null)
    [ "$STATE" = "active" ] && SC="$G" || SC="$R"
    printf "  ${C}%-35s${X} %s%s${X}\n" "$SVC" "$SC" "$STATE"
  }
done

H $'\U0001F4A4 SWAP TOP-3 PROCESSES'
awk '/VmSwap/{swap=$2} /Name/{name=$2} swap>0{print swap,name}' /proc/*/status 2>/dev/null | sort -rn | head -3 | \
  awk -v c="$C" -v x="$X" '{printf "  %s%-30s%s %6.1f MB\n",c,$2,x,$1/1024}'

H $'\U0001F422 PHP-FPM SLOW LOG (last 24h)'
shopt -s nullglob
for SLOW in /var/log/php*-fpm*slow* /var/log/php*/slow.log /var/www/*/data/logs/*slow*; do
  [ -f "$SLOW" ] || continue
  CNT=$(grep -c '\[pool' "$SLOW" 2>/dev/null || echo 0)
  POOL=$(echo "$SLOW" | grep -oP '/\K[^/]+(?=[-._]slow)' || basename "$SLOW")
  [ "$CNT" -gt 0 ] && COL="$R" || COL="$G"
  printf "  ${C}%-30s${X} %s%d slow${X}\n" "$POOL" "$COL" "$CNT"
done
shopt -u nullglob

H $'\U0001F534 HTTP 502/503 BY DOMAIN (last '"$TW"')'
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" 2>/dev/null | while read -r LOG; do
  DOM=$(echo "$LOG" | grep -oP '/var/www/\K[^/]+')
  CNT=$(tail -n 5000 "$LOG" 2>/dev/null | awk '$9=="502"||$9=="503"{c++}END{print c+0}')
  [ "$CNT" -gt 0 ] && {
    [ "$CNT" -ge 10 ] && COL="$R" || COL="$Y"
    printf "  ${C}%-35s${X} %s%d errors${X}\n" "$DOM" "$COL" "$CNT"
  }
done

H $'\U0001F4BD DISK I/O (NVMe)'
DEV=$(lsblk -dno NAME,TYPE 2>/dev/null | awk '$2=="disk"{print $1}' | head -1)
[ -n "$DEV" ] && {
  R1=$(awk -v d="$DEV" '$3==d{print $6}' /proc/diskstats 2>/dev/null)
  W1=$(awk -v d="$DEV" '$3==d{print $10}' /proc/diskstats 2>/dev/null)
  sleep 1
  R2=$(awk -v d="$DEV" '$3==d{print $6}' /proc/diskstats 2>/dev/null)
  W2=$(awk -v d="$DEV" '$3==d{print $10}' /proc/diskstats 2>/dev/null)
  RMB=$(awk "BEGIN{printf \"%.2f\",(${R2:-0}-${R1:-0})*512/1048576}")
  WMB=$(awk "BEGIN{printf \"%.2f\",(${W2:-0}-${W1:-0})*512/1048576}")
  printf "  ${C}Device:${X} ${W}/dev/%s${X}  ${C}Read:${X} ${G}%s MB/s${X}  ${C}Write:${X} ${G}%s MB/s${X}\n" "$DEV" "$RMB" "$WMB"
}

H $'\U0001F6E1\ufe0f  CROWDSEC METRICS'
have cscli && cscli metrics 2>/dev/null | awk '/Parsers/{p=1} p&&/\|/{printf "  %s\n",$0}' | head -8

H $'\U0001F5C4\ufe0f  MARIADB UPTIME'
have mysql && {
  UPSEC=$(mysql -N -e "SHOW GLOBAL STATUS LIKE 'Uptime';" 2>/dev/null | awk '{print $2}')
  if [ -n "$UPSEC" ]; then
    UPDAY=$((UPSEC/86400))
    UPHR=$(( (UPSEC%86400)/3600 ))
    UPMIN=$(( (UPSEC%3600)/60 ))
    if [ "$UPDAY" -eq 0 ] && [ "$UPHR" -lt 24 ]; then
      COL="$R"; WARN=$' \u26a0\ufe0f  RECENT RESTART!'
    else
      COL="$G"; WARN=""
    fi
    printf "  ${C}MariaDB uptime:${X} %s%dd %dh %dm${X}%s\n" "$COL" "$UPDAY" "$UPHR" "$UPMIN" "$WARN"
  fi
}

printf "\n${W}\u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557\n"
printf "\u2551  = Rooted by VladiMIR | AI =   v2026-04-13e         \u2551\n"
printf "${W}\u255a\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255d${X}\n"
