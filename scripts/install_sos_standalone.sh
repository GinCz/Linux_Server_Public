#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  install_sos_standalone.sh | [v2026-05-25]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Standalone SOS system auditor installer
# Servers     : All Linux Nodes
# Usage       : bash scripts/install_sos_standalone.sh
# ==========================================================================================
set -e

DEST="/usr/local/bin/sos"

echo "Installing SOS -> $DEST ..."

echo -en "  Install SOS? [y/n]: "
read -r OK
[[ "${OK:-y}" =~ ^[yY]$ ]] || { echo "Aborted"; exit 1; }
echo

cat > "$DEST" << 'SOS_SCRIPT'
#!/usr/bin/env bash
clear
TW="${1:-24h}"
G=$'\033[1;32m'; C=$'\033[1;36m'; Y=$'\033[1;33m'; R=$'\033[1;31m'; W=$'\033[1;37m'; X=$'\033[0m'
EM=$'\342\200\224'
have(){ command -v "$1" >/dev/null 2>&1; }
SEP="${C}$(printf '=%.0s' {1..90})${X}"
H(){ printf "\n${C}=============== %s${X}\n" "$1"; }
M=1440
[[ "$TW" =~ ^([0-9]+)m$ ]] && M="${BASH_REMATCH[1]}"
[[ "$TW" =~ ^([0-9]+)h$ ]] && M="$(( ${BASH_REMATCH[1]} * 60 ))"
NOW=$(date '+%Y-%m-%d %H:%M:%S'); HOST=$(hostname)
IP=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
CORES=$(nproc 2>/dev/null || echo 1)
LOAD=$(awk '{print $1,$2,$3}' /proc/loadavg); LOAD1=$(awk '{print $1}' /proc/loadavg)
LOAD_PCT=$(awk -v l="$LOAD1" -v c="$CORES" 'BEGIN{printf "%.0f",(l/c)*100}')
[ "${LOAD_PCT:-0}" -ge 90 ] && LC="$R" || { [ "${LOAD_PCT:-0}" -ge 60 ] && LC="$Y" || LC="$G"; }
ROLE="GENERIC"
have nginx && [ -d /var/www ] && ROLE="WEB"
have xray  && ROLE="VPN/XRAY"
have wg    && ROLE="VPN/WG"
have awg   && ROLE="VPN/AWG"
[ "$ROLE" = "GENERIC" ] && have docker && ROLE="DOCKER/NODE"
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
  | head -6 | tail -5 \
  | awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-12s CPU:%5s%%  MEM:%5s%%  %s\n",c,$1,x,$2,$3,$4,$5}'
printf "\n  ${C}Top 5 by RAM:${X}\n"
ps -eo pid,user,%cpu,%mem,rss,args --sort=-rss 2>/dev/null \
  | head -6 | tail -5 \
  | awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-12s CPU:%5s%%  MEM:%5s%%  %6.1fMB  %s\n",c,$1,x,$2,$3,$4,$5/1024,$6}'
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
OOM_SYSLOG=$(grep -E 'oom-kill|Out of memory|Killed process' /var/log/syslog 2>/dev/null | tail -n 200 | wc -l)
[ "${OOM_SYSLOG:-0}" -gt 0 ] && printf "  ${R}OOM entries in syslog: %d${X}\n" "$OOM_SYSLOG"
H "SWAP"
SWAP_TOTAL=$(free -m 2>/dev/null | awk '/^Swap:/{print $2+0}')
SWAP_USED=$(free -m  2>/dev/null | awk '/^Swap:/{print $3+0}')
SWAP_FREE=$(free -m  2>/dev/null | awk '/^Swap:/{print $4+0}')
if [ "${SWAP_TOTAL:-0}" -gt 0 ]; then
  SWAP_PCT=$(awk -v u="${SWAP_USED:-0}" -v t="${SWAP_TOTAL:-1}" 'BEGIN{printf "%.0f",(u/t)*100}')
  [ "${SWAP_PCT:-0}" -ge 80 ] && SC="$R" || { [ "${SWAP_PCT:-0}" -ge 40 ] && SC="$Y" || SC="$G"; }
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
     /still logged/{printf "  %s%-10s%s  %-16s  %s%s%s\n",g,$1,x,$3,$g,"still logged in",$x;next}
     /^$|^wtmp/{next}
     {printf "  %s%-10s%s  %-16s  %s\n",c,$1,x,$3,substr($0,28)}' \
  | head -12
printf "\n  ${C}Currently logged in:${X}\n"
who 2>/dev/null | awk -v g="$G" -v c="$C" -v x="$X" \
  '{printf "  %s%-12s%s  tty: %-10s  from: %s  since: %s %s\n",g,$1,x,$2,$NF,$3,$4}' \
  | head -5
H "APT UPDATES"
UPD_COUNT=$(apt list --upgradable 2>/dev/null | grep -c '/') || UPD_COUNT=0
SEC_COUNT=$(apt list --upgradable 2>/dev/null | grep -ci 'security') || SEC_COUNT=0
if [ "${UPD_COUNT:-0}" -gt 0 ]; then
  [ "${SEC_COUNT:-0}" -gt 0 ] && COL="$R" || COL="$Y"
  printf "  ${C}Upgradable packages:${X} %s%d${X}  (security: %s%d${X})\n" \
    "$COL" "$UPD_COUNT" "$R" "$SEC_COUNT"
  printf "  ${Y}Top 10:${X}\n"
  apt list --upgradable 2>/dev/null | grep '/' | head -10 \
    | awk -v c="$C" -v x="$X" '{printf "    %s%s%s\n",c,$1,x}'
else
  printf "  ${G}System is up to date${X}\n"
fi
H "CRON JOBS"
printf "  ${C}System crontab (/etc/crontab):${X}\n"
grep -v '^#\|^$' /etc/crontab 2>/dev/null \
  | awk -v c="$C" -v x="$X" '{printf "    %s%s%s\n",c,$0,x}' | head -15
printf "\n  ${C}Cron.d files (/etc/cron.d/):${X}\n"
for F in /etc/cron.d/*; do
  [ -f "$F" ] || continue
  CNT=$(grep -cv '^#\|^$' "$F" 2>/dev/null || echo 0)
  [ "${CNT:-0}" -eq 0 ] && continue
  printf "  ${W}%-30s${X} (%d jobs)\n" "$(basename "$F")" "$CNT"
  grep -v '^#\|^$' "$F" 2>/dev/null \
    | awk -v c="$C" -v x="$X" '{printf "    %s%s%s\n",c,$0,x}' | head -5
done
printf "\n  ${C}Root crontab:${X}\n"
crontab -l 2>/dev/null | grep -v '^#\|^$' \
  | awk -v c="$C" -v x="$X" '{printf "    %s%s%s\n",c,$0,x}' | head -15 \
  || printf "    ${Y}(empty or no root crontab)${X}\n"
printf "\n  ${C}Hourly/Daily/Weekly/Monthly scripts:${X}\n"
for DIR in /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly; do
  CNT=$(ls "$DIR" 2>/dev/null | wc -l)
  [ "${CNT:-0}" -gt 0 ] && printf "    ${G}%-22s${X} %d scripts\n" "$DIR" "$CNT"
done
if [ -f /var/log/syslog ]; then
  CRON_FAIL=$(grep -c 'CRON.*error\|cron.*fail\|crontab.*error' /var/log/syslog 2>/dev/null || echo 0)
  [ "${CRON_FAIL:-0}" -gt 0 ] && printf "\n  ${R}Cron errors in syslog: %d${X}\n" "$CRON_FAIL"
fi
H "FAIL2BAN"
if have fail2ban-client; then
  F2B_ST=$(systemctl is-active fail2ban 2>/dev/null)
  [ "$F2B_ST" = "active" ] && SC="$G" || SC="$R"
  printf "  ${C}Service:${X} %s%s${X}\n" "$SC" "$F2B_ST"
  JAIL_LIST=$(fail2ban-client status 2>/dev/null | grep 'Jail list' \
    | sed 's/.*Jail list://;s/,/ /g' | tr -d '\t')
  JAIL_COUNT=$(echo "$JAIL_LIST" | wc -w)
  printf "  ${C}Active jails:${X} ${W}%s${X}\n" "$JAIL_COUNT"
  TOTAL_BANNED=0
  for JAIL in $JAIL_LIST; do
    [ -z "$JAIL" ] && continue
    BANNED=$(fail2ban-client status "$JAIL" 2>/dev/null | awk '/Currently banned/{print $NF}')
    TOTAL_B=$(fail2ban-client status "$JAIL" 2>/dev/null | awk '/Total banned/{print $NF}')
    [ "${BANNED:-0}" -gt 0 ] && COL="$R" || COL="$G"
    TOTAL_BANNED=$((TOTAL_BANNED + ${BANNED:-0}))
    printf "    %s%-25s%s banned now: %s%s%s  total: %s\n" \
      "$C" "$JAIL" "$X" "$COL" "${BANNED:-0}" "$X" "${TOTAL_B:-0}"
  done
  [ "$TOTAL_BANNED" -gt 0 ] \
    && printf "  ${R}Total currently banned IPs: %d${X}\n" "$TOTAL_BANNED" \
    || printf "  ${G}No IPs currently banned${X}\n"
else
  printf "  ${Y}fail2ban not installed${X}\n"
fi
H "DOCKER"
if have docker; then
  DOCK_ST=$(systemctl is-active docker 2>/dev/null)
  [ "$DOCK_ST" = "active" ] && SC="$G" || SC="$R"
  printf "  ${C}Service:${X} %s%s${X}\n" "$SC" "$DOCK_ST"
  DOCK_RUN=$(docker ps  --format "{{.Names}}" 2>/dev/null | wc -l)
  DOCK_ALL=$(docker ps -a --format "{{.Names}}" 2>/dev/null | wc -l)
  printf "    Running: ${G}%s${X}  /  Total: ${W}%s${X}\n" "$DOCK_RUN" "$DOCK_ALL"
  docker ps -a --format "  {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null \
    | awk -v g="$G" -v r="$R" -v c="$C" -v x="$X" \
      '{col=($2~/Up/)?g:r; printf "    %s%-28s%s %s%-20s%s  %s\n",c,$1,x,col,$2,x,$3}'
  printf "  ${C}Images:${X} %s\n" "$(docker images 2>/dev/null | tail -n +2 | wc -l)"
  docker system df 2>/dev/null | sed 's/^/    /'
else
  printf "  ${Y}Docker not installed${X}\n"
fi
H "SERVICES"
SVC_LIST=(nginx mariadb mysql php8.1-fpm php8.2-fpm php8.3-fpm php8.4-fpm crowdsec crowdsec-firewall-bouncer fail2ban smbd nmbd exim4 postfix docker ssh xray wg-quick@wg0 amnezia-wg AdGuardHome adguardhome semaphore)
for SVC in "${SVC_LIST[@]}"; do
  systemctl list-units --type=service --all 2>/dev/null | grep -q "${SVC}.service" && {
    STATE=$(systemctl is-active "$SVC" 2>/dev/null)
    [ "$STATE" = "active" ] && SC="$G" || SC="$R"
    printf "  ${C}%-38s${X} %s%s${X}\n" "$SVC" "$SC" "$STATE"
  }
done
H "WIREGUARD"
if have wg; then
  WG_IFACES=$(wg show interfaces 2>/dev/null)
  [ -n "$WG_IFACES" ] && for IFACE in $WG_IFACES; do
    printf "  ${C}Interface:${X} ${G}%s${X}\n" "$IFACE"
    WG_INFO=$(wg show "$IFACE" 2>/dev/null)
    printf "    ${C}Port:${X}  ${G}%s${X}   ${C}Peers:${X} ${G}%s${X}\n" \
      "$(echo "$WG_INFO" | awk '/listening port/{print $NF}')" \
      "$(echo "$WG_INFO" | grep -c '^peer:')"
  done || printf "  ${Y}WireGuard installed but no interfaces active${X}\n"
else
  printf "  ${Y}WireGuard not installed${X}\n"
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
  RMB=$(awk -v r2="${R2:-0}" -v r1="${R1:-0}" 'BEGIN{printf "%.2f",(r2-r1)*512/1048576}')
  WMB=$(awk -v w2="${W2:-0}" -v w1="${W1:-0}" 'BEGIN{printf "%.2f",(w2-w1)*512/1048576}')
  printf "  ${C}Device:${X} /dev/%s  ${C}Read:${X} ${G}%s MB/s${X}  ${C}Write:${X} ${G}%s MB/s${X}\n" \
    "$DEV" "$RMB" "$WMB"
else
  printf "  ${Y}no block device found${X}\n"
fi
H "DMESG ERRORS"
dmesg -T 2>/dev/null | grep -iE 'error|fail|oom|kill|panic|warn' | tail -10 | sed 's/^/  /'
H "ALL OPEN PORTS"
printf "  ${C}TCP listening:${X}\n"
ss -tlnp 2>/dev/null \
  | awk 'NR>1 && /LISTEN/ {
      addr=$4; proc=$NF
      gsub(/users:\(\(|\)\)/,"",proc); sub(/,.*/,"",proc)
      printf "    %-25s %s\n", addr, proc
    }' | sort -t: -k2 -n
printf "\n  ${C}UDP listening:${X}\n"
ss -ulnp 2>/dev/null \
  | awk 'NR>1 {
      addr=$4; proc=$NF
      gsub(/users:\(\(|\)\)/,"",proc); sub(/,.*/,"",proc)
      printf "    %-25s %s\n", addr, proc
    }' | sort -t: -k2 -n
printf "\n  ${C}Key ports status:${X}\n"
declare -A PORT_NAMES=([22]="SSH" [25]="SMTP" [53]="DNS/AdGuard" [80]="HTTP" [443]="HTTPS" [445]="Samba" [139]="Samba-NB" [853]="DoT" [3000]="Semaphore/AGH" [8080]="AGH-Web" [8443]="HTTPS-alt" [51820]="WireGuard")
for PORT in 22 25 53 80 139 443 445 853 3000 8080 8443 51820; do
  NAME="${PORT_NAMES[$PORT]}"
  TCP_OK=$(ss -tlnp 2>/dev/null | grep -c ":${PORT} " || echo 0)
  UDP_OK=$(ss -ulnp 2>/dev/null | grep -c ":${PORT} " || echo 0)
  TOTAL=$((TCP_OK + UDP_OK))
  if [ "$TOTAL" -gt 0 ]; then
    PROTO=""; [ "$TCP_OK" -gt 0 ] && PROTO="${PROTO}TCP "; [ "$UDP_OK" -gt 0 ] && PROTO="${PROTO}UDP"
    printf "    ${G}%-6s${X} ${C}%-12s${X} ${G}open${X} [%s]\n" "$PORT" "$NAME" "$PROTO"
  else
    printf "    ${Y}%-6s${X} ${C}%-12s${X} ${Y}closed${X}\n" "$PORT" "$NAME"
  fi
done
printf "\n%s\n  ${W}SOS v2026.05.25${X} | default: ${C}24h${X} | ${W}Rooted by VladiMIR + AI${X} | ${C}github.com/GinCz${X}\n%s\n" "$SEP" "$SEP"
SOS_SCRIPT

chmod +x "$DEST"
echo "OK: $DEST installed"

# ── aliases ────────────────────────────────────────────────────────────────────
for F in /root/.bashrc /root/.bash_profile; do
    sed -i '/alias sos[0-9]*=/d' "$F" 2>/dev/null
    printf '\nalias sos="/usr/local/bin/sos 24h"\nalias sos1="/usr/local/bin/sos 1h"\nalias sos3="/usr/local/bin/sos 3h"\nalias sos24="/usr/local/bin/sos 24h"\nalias sos120="/usr/local/bin/sos 120h"\n' >> "$F"
done

source /root/.bashrc 2>/dev/null || true

echo ""
echo "=== SOS INSTALLED ==="
echo "  sos        -> 24h (default)"
echo "  sos1       -> 1h"
echo "  sos3       -> 3h"
echo "  sos24      -> 24h"
echo "  sos120     -> 120h"
echo "  sos 30m    -> custom"
echo "============================"
echo ""
echo "Run now: source ~/.bashrc && sos"
echo

if [ -t 0 ]; then
    read -rp "  Запустить sos прямо сейчас? [Y/n]: " RUN_NOW
else
    read -rp "  Запустить sos прямо сейчас? [Y/n]: " RUN_NOW < /dev/tty 2>/dev/null || RUN_NOW="y"
fi
if [[ "$RUN_NOW" =~ ^[YyДд]?$ || -z "$RUN_NOW" ]]; then
    exec /usr/local/bin/sos
fi
