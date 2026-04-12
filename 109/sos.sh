#!/usr/bin/env bash
TW="${1:-1h}"
clear
G=$'\033[1;32m'; C=$'\033[1;36m'; Y=$'\033[1;33m'; R=$'\033[1;31m'; W=$'\033[1;37m'; X=$'\033[0m'
EM=$'\342\200\224'
have(){ command -v "$1" >/dev/null 2>&1; }
H(){ printf "${Y}=== %s ===${X}\n" "$1"; }
SEP="${Y}$(printf '=%.0s' {1..90})${X}"
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
printf "%s\n" "$SEP"
printf "  ${Y}DISK${X}\n"
df -h --output=source,size,used,avail,pcent,target 2>/dev/null | grep -E '^(Filesystem|/dev)' | \
  awk -v c="$C" -v x="$X" 'NR==1{printf "  %-20s %6s %6s %6s %5s  %s\n",$1,$2,$3,$4,$5,$6;next}{printf "  %s%-20s%s %6s %6s %6s %5s  %s\n",c,$1,x,$2,$3,$4,$5,$6}'
printf "%s\n" "$SEP"
printf "  ${Y}TOP 10 CPU%%${X}\n"
ps -eo pid,user,%cpu,pmem,args --sort=-%cpu 2>/dev/null | head -11 | tail -10 | \
  awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-10s %5s %5s  %s\n",c,$1,x,$2,$3,$4,$5}'
printf "%s\n" "$SEP"
printf "  ${Y}TOP 15 RAM${X}\n"
ps -eo pid,user,%cpu,pmem,rss,args --sort=-rss 2>/dev/null | head -16 | tail -15 | \
  awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-10s %5s %5s  %6.1fMB  %s\n",c,$1,x,$2,$3,$4,$5/1024,$6}'
printf "%s\n" "$SEP"
printf "  ${Y}PHP-FPM POOLS${X}\n"
ps -eo user,rss,args 2>/dev/null | grep 'php-fpm\|php-cgi' | \
  awk -v c="$C" -v x="$X" '{p=$1;r=$2;cnt[p]++;tot[p]+=r}END{for(p in cnt)printf "  %s%-26s%s %4d wk  %7.1fMB\n",c,p,x,cnt[p],tot[p]/1024}' | sort -k4 -rn
printf "%s\n" "$SEP"
printf "  ${Y}TOP-5 TRAFFIC (last %s)${X}\n" "$TW"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" -exec wc -l {} + 2>/dev/null | sort -rn | head -6 | \
  awk '{printf "  %7d  %s\n",$1,$2}'
printf "%s\n" "$SEP"
printf "  ${Y}TOP-10 IPs (last %s)${X}\n" "$TW"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" -exec tail -n 2000 {} + 2>/dev/null | \
  awk '{print $1}' | sort | uniq -c | sort -rn | head -10 | \
  awk -v em="$EM" '{printf "  %6d %s %s\n",$1,em,$2}'
printf "%s\n" "$SEP"
printf "  ${Y}HTTP STATUS (last %s)${X}\n" "$TW"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" -exec tail -n 2000 {} + 2>/dev/null | \
  awk '{print $9}' | grep -E '^[0-9]{3}$' | sort | uniq -c | sort -rn | head -10 | \
  awk -v g="$G" -v c="$C" -v y="$Y" -v r="$R" -v x="$X" -v em="$EM" \
    '{if($2~/^2/)col=g; else if($2~/^3/)col=c; else if($2~/^4/)col=y; else col=r; printf "  %6d %s %sHTTP %s%s\n",$1,em,col,$2,x}'
printf "%s\n" "$SEP"
printf "  ${Y}WP-LOGIN ATTACKS (last %s)${X}\n" "$TW"
grep -h 'wp-login.php' /var/www/*/data/logs/*access.log /var/log/nginx/*.log 2>/dev/null | \
  awk '{print $1}' | sort | uniq -c | sort -rn | head -10 | \
  awk -v r="$R" -v y="$Y" -v w="$W" -v x="$X" \
    '{col=(($1>100)?r:(($1>20)?y:w)); printf "  %s%5d%s  %s\n",col,$1,x,$2}'
printf "%s\n" "$SEP"
printf "  ${Y}NGINX${X}\n"
have nginx && {
  printf "  ${C}Workers:${X} ${G}%s${X}  TCP: ${G}%s${X}\n" "$(pgrep -x nginx | wc -l)" "$(ss -tnp state established 2>/dev/null | wc -l)"
  STUB=$(curl -s --max-time 2 http://127.0.0.1/nginx_status 2>/dev/null)
  [ -n "$STUB" ] && echo "$STUB" | awk '/Active/{printf "  Active: %s\n",$3}'
}
printf "%s\n" "$SEP"
printf "  ${Y}MYSQL${X}\n"
have mysql && {
  mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_connected';" 2>/dev/null | awk -v c="$C" -v g="$G" -v x="$X" '{printf "  %sConnected:%s %s%s%s\n",c,x,g,$2,x}'
  mysql -N -e "SHOW GLOBAL STATUS LIKE 'Threads_running';"   2>/dev/null | awk -v c="$C" -v g="$G" -v x="$X" '{printf "  %sRunning:%s   %s%s%s\n",c,x,g,$2,x}'
  mysql -N -e "SHOW GLOBAL STATUS LIKE 'Slow_queries';"      2>/dev/null | awk -v c="$C" -v x="$X"             '{printf "  %sSlow:%s      %s\n",c,x,$2}'
}
printf "%s\n" "$SEP"
printf "  ${Y}DOCKER${X}\n"
have docker && docker ps -a --format "  {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null | \
  awk -v g="$G" -v r="$R" -v c="$C" -v x="$X" '{col=($2~/Up/)?g:r; printf "  %s%-28s%s %s%s%s  %s\n",c,$1,x,col,$2,x,$3}'
printf "%s\n" "$SEP"
printf "  ${Y}CRITICAL ERRORS (last %s)${X}\n" "$TW"
find /var/www/*/data/logs/ -name "*error.log" -mmin "-${M}" \
  -exec grep -iE 'fatal|Out of memory|upstream timed out|connect\(\) failed|no live upstreams' {} + 2>/dev/null | tail -10
printf "%s\n" "$SEP"
printf "  ${Y}CROWDSEC${X}\n"
have cscli && {
  BANS=$(cscli decisions list 2>/dev/null | awk 'BEGIN{c=0}/^\|/{c++}END{print (c>0?c-1:0)}')
  printf "  ${C}Bans:${X} ${R}%s${X}\n" "$BANS"
  cscli alerts list --since "$TW" -l 10 2>/dev/null | head -12 | sed 's/^/  /'
}
printf "%s\n" "$SEP"
printf "  ${Y}SERVICES${X}\n"
for SVC in nginx mariadb mysql php8.1-fpm php8.2-fpm php8.3-fpm php8.4-fpm crowdsec crowdsec-firewall-bouncer exim4 postfix docker ssh; do
  systemctl list-units --type=service --all 2>/dev/null | grep -q "${SVC}.service" && {
    STATE=$(systemctl is-active "$SVC" 2>/dev/null)
    [ "$STATE" = "active" ] && SC="$G" || SC="$R"
    printf "  ${C}%-35s${X} %s%s${X}\n" "$SVC" "$SC" "$STATE"
  }
done
printf "%s\n" "$SEP"
printf "  ${Y}SWAP TOP-3 PROCESSES${X}\n"
awk '/VmSwap/{swap=$2} /Name/{name=$2} swap>0{print swap,name}' /proc/*/status 2>/dev/null | sort -rn | head -3 | \
  awk -v c="$C" -v x="$X" '{printf "  %s%-30s%s %6.1f MB\n",c,$2,x,$1/1024}'
printf "%s\n" "$SEP"
printf "  ${Y}PHP-FPM SLOW LOG (last 24h)${X}\n"
shopt -s nullglob
for SLOW in /var/log/php*-fpm*slow* /var/log/php*/slow.log /var/www/*/data/logs/*slow*; do
  [ -f "$SLOW" ] || continue
  CNT=$(grep -c '\[pool' "$SLOW" 2>/dev/null || echo 0)
  POOL=$(echo "$SLOW" | grep -oP '/\K[^/]+(?=[-._]slow)' || basename "$SLOW")
  [ "$CNT" -gt 0 ] && COL="$R" || COL="$G"
  printf "  ${C}%-30s${X} %s%d slow${X}\n" "$POOL" "$COL" "$CNT"
done
shopt -u nullglob
printf "%s\n" "$SEP"
printf "  ${Y}HTTP 502/503 BY DOMAIN (last %s)${X}\n" "$TW"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" 2>/dev/null | while read -r LOG; do
  DOM=$(echo "$LOG" | grep -oP '/var/www/\K[^/]+')
  CNT=$(tail -n 5000 "$LOG" 2>/dev/null | awk '$9=="502"||$9=="503"{c++}END{print c+0}')
  [ "$CNT" -gt 0 ] && {
    [ "$CNT" -ge 10 ] && COL="$R" || COL="$Y"
    printf "  ${C}%-35s${X} %s%d errors${X}\n" "$DOM" "$COL" "$CNT"
  }
done
printf "%s\n" "$SEP"
printf "  ${Y}DISK I/O${X}\n"
DEV=$(lsblk -dno NAME,TYPE 2>/dev/null | awk '$2=="disk"{print $1}' | head -1)
[ -n "$DEV" ] && {
  R1=$(awk -v d="$DEV" '$3==d{print $6}' /proc/diskstats 2>/dev/null)
  W1=$(awk -v d="$DEV" '$3==d{print $10}' /proc/diskstats 2>/dev/null)
  sleep 1
  R2=$(awk -v d="$DEV" '$3==d{print $6}' /proc/diskstats 2>/dev/null)
  W2=$(awk -v d="$DEV" '$3==d{print $10}' /proc/diskstats 2>/dev/null)
  RMB=$(awk "BEGIN{printf \"%.2f\",(${R2:-0}-${R1:-0})*512/1048576}")
  WMB=$(awk "BEGIN{printf \"%.2f\",(${W2:-0}-${W1:-0})*512/1048576}")
  printf "  ${C}Device:${X} /dev/%s  ${C}Read:${X} ${G}%s MB/s${X}  ${C}Write:${X} ${G}%s MB/s${X}\n" "$DEV" "$RMB" "$WMB"
}
printf "%s\n" "$SEP"
printf "  ${Y}CROWDSEC METRICS${X}\n"
have cscli && cscli metrics 2>/dev/null | awk '/Parsers/{p=1} p&&/\|/{printf "  %s\n",$0}' | head -8
printf "%s\n" "$SEP"
printf "  ${Y}MARIADB UPTIME${X}\n"
have mysql && {
  UPSEC=$(mysql -N -e "SHOW GLOBAL STATUS LIKE 'Uptime';" 2>/dev/null | awk '{print $2}')
  if [ -n "$UPSEC" ]; then
    UPDAY=$((UPSEC/86400)); UPHR=$(( (UPSEC%86400)/3600 )); UPMIN=$(( (UPSEC%3600)/60 ))
    if [ "$UPDAY" -eq 0 ] && [ "$UPHR" -lt 24 ]; then COL="$R"; WARN=" ⚠️  RECENT RESTART!"
    else COL="$G"; WARN=""; fi
    printf "  ${C}MariaDB uptime:${X} %s%dd %dh %dm${X}%s\n" "$COL" "$UPDAY" "$UPHR" "$UPMIN" "$WARN"
  fi
}
printf "%s\n  ${W}Rooted by VladiMIR | AI   v2026-04-13f${X}\n%s\n" "$SEP" "$SEP"
