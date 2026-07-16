#!/usr/bin/env bash
# = Rooted by VladiMIR + AI | v.2026.07.16 | github.com/GinCz =
# =============================================================
# Script: sos.sh
# Version: v2026.07.16
#
# Changes v2026.07.16:
#   - fix: ROLE detection now falls back to pgrep for xray/xray-linux-amd64
#     when xray binary is not in PATH (common with x-ui setup)
#   - fix: section 24 xray-process now shows PID + uptime when running
#     and clearer hint when process is not found
#
# Changes v2026.07.04:
#   - fix: added timeout 5 to ALL cscli calls (sections 06,11,21,29,32)
#     to prevent SOS from hanging when CrowdSec LAPI is unresponsive
#     (reproduced on server 222: DB grew to 170MB, LAPI stopped responding)
#
# === FROM GITHUB (bash <(curl ...)) ===
# First prompt: 1) Run 2) Install
# Run → asks for time window → runs audit
# Install → installs + sets alias → runs audit for 24h
#
# === INSTALLED (/usr/local/bin/sos) ===
# sos       → asks for time window → runs audit
# sos 1h    → runs audit immediately for 1h
# sos 3h    → runs audit immediately for 3h
# sos 24h   → runs audit immediately for 24h
# sos 120h  → runs audit immediately for 120h
# =============================================================
G=$'\033[1;32m'; C=$'\033[1;36m'; Y=$'\033[1;33m'
R=$'\033[1;31m'; W=$'\033[1;37m'; X=$'\033[0m'
EM=$'\342\200\224'
SEP="${Y}$(printf '=%.0s' {1..90})${X}"
SOS_URL="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh"
SOS_BIN="/usr/local/bin/sos"

# ==============================================================================
# DETECT MODE
# ==============================================================================
SELF_REAL="$(realpath "$0" 2>/dev/null || echo "$0")"
SOS_BIN_REAL="$(realpath "$SOS_BIN" 2>/dev/null || echo "$SOS_BIN")"
if [ "$SELF_REAL" = "$SOS_BIN_REAL" ]; then
  IS_INSTALLED=1
else
  IS_INSTALLED=0
fi

# ==============================================================================
# TIME WINDOW PROMPT
# ==============================================================================
prompt_time(){
  printf "\n%s\n" "$SEP"
  printf " ${W}SOS — select time window:${X}\n"
  printf "%s\n" "$SEP"
  printf "\n ${C}1)${X} 1 hour\n"
  printf " ${C}2)${X} 3 hours\n"
  printf " ${C}3)${X} ${G}24 hours${X} ${Y}(default, press Enter)${X}\n"
  printf " ${C}4)${X} 120 hours\n"
  printf "\n ${Y}»${X} "
  read -r TW_CHOICE
  case "$TW_CHOICE" in
    1) TW="1h"   ;;
    2) TW="3h"   ;;
    4) TW="120h" ;;
    *) TW="24h"  ;;
  esac
}

# ==============================================================================
# INSTALL FUNCTION
# ==============================================================================
do_install(){
  clear
  printf "%s\n" "$SEP"
  printf " ${G}SOS INSTALLER${X} — downloading from GitHub...\n"
  printf "%s\n" "$SEP"
  printf " ${Y}[1/2] Downloading %s...${X}\n" "$SOS_BIN"
  if curl -fsSL "$SOS_URL" -o "$SOS_BIN"; then
    chmod +x "$SOS_BIN"
    printf " ${G}Installed: %s${X}\n" "$SOS_BIN"
  else
    printf " ${R}ERROR: failed to download %s${X}\n" "$SOS_URL"
    exit 1
  fi
  printf " ${Y}[2/2] Writing aliases...${X}\n"
  for FILE in /root/.bashrc /root/.bash_profile; do
    sed -i '/# === sos aliases ===/d' "$FILE" 2>/dev/null
    sed -i '/alias sos/d' "$FILE" 2>/dev/null
    printf '%s\n' \
      "" \
      "# === sos aliases ===" \
      "alias sos='/usr/local/bin/sos'" >> "$FILE"
  done
  source /root/.bashrc 2>/dev/null
  printf "%s\n" "$SEP"
  printf " ${G}Done! SOS installed.${X}\n"
  printf " ${C}Alias:${X} ${G}sos${X} → /usr/local/bin/sos\n"
  printf " ${C}Usage:${X} type ${G}sos${X} — it will ask for a time window and run the audit.\n"
  printf " ${C}Or with argument:${X} ${G}sos 1h${X} / ${G}sos 3h${X} / ${G}sos 24h${X} / ${G}sos 120h${X}\n"
  printf " To activate alias in current shell: ${C}source ~/.bashrc${X}\n"
  printf "%s\n" "$SEP"
  TW="24h"
}

# ==============================================================================
# ENTRY POINT
# ==============================================================================
if [ "$IS_INSTALLED" -eq 0 ]; then
  clear
  printf "%s\n" "$SEP"
  printf " ${W}SOS${X} ${Y}v.2026.07.16${X} | ${C}%s${X} | ${G}%s${X}\n" \
    "$(hostname)" "$(date '+%Y-%m-%d %H:%M:%S')"
  printf "%s\n" "$SEP"
  printf "\n ${W}What would you like to do?${X}\n\n"
  printf " ${C}1)${X} ${W}Run${X}     — run audit now (without installing)\n"
  printf " ${C}2)${X} ${W}Install${X} — install sos on this server + set alias\n"
  printf "\n ${Y}»${X} "
  read -r MAIN_CHOICE
  case "$MAIN_CHOICE" in
    2) do_install ;;
    *) prompt_time ;;
  esac
else
  if [ $# -eq 0 ]; then
    prompt_time
  else
    TW="$1"
  fi
fi

# ==============================================================================
# AUDIT
# ==============================================================================
clear
have(){ command -v "$1" >/dev/null 2>&1; }
H(){ printf "\n${Y}=============== ${W}%s${X}\n" "$1"; }
safe_int(){ local v; v="$(printf '%s' "${1:-}" | head -1 | tr -cd '0-9')"
  printf '%s\n' "${v:-0}"
}
safe_float(){ local v="${1:-}"
  [[ "$v" =~ ^[0-9]+([.][0-9]+)?$ ]] && printf '%s\n' "$v" || printf '0\n'
}
safe_pct(){ local a b
  a="$(safe_int "${1:-0}")"; b="$(safe_int "${2:-0}")"
  [ "$b" -gt 0 ] && awk -v a="$a" -v b="$b" 'BEGIN{printf "%.1f",(a/b)*100}' || printf '0.0'
}
draw_bar(){
  local used_kb="$(safe_int "${1:-0}")"
  local total_kb="$(safe_int "${2:-0}")"
  local pct=0
  [ "$total_kb" -gt 0 ] && pct=$(( used_kb * 100 / total_kb ))
  local filled=$(( pct / 10 )); [ "$filled" -gt 10 ] && filled=10
  local empty=$(( 10 - filled ))
  local col; [ "$pct" -ge 90 ] && col="$R" || { [ "$pct" -ge 60 ] && col="$Y" || col="$G"; }
  local bar="${col}["
  local i
  for (( i=0; i<filled; i++ )); do bar="${bar}*"; done
  for (( i=0; i<empty;  i++ )); do bar="${bar}."; done
  bar="${bar}]${X}"
  printf '%s %d%%' "$bar" "$pct"
}

NOW=$(date '+%Y-%m-%d %H:%M:%S')
case "$TW" in
  1h)   M=60    ;;
  3h)   M=180   ;;
  120h) M=7200  ;;
  *)    M=1440  ;;
esac

HOST=$(hostname -s 2>/dev/null || hostname)
IP=$(hostname -I 2>/dev/null | awk '{print $1}' | head -n1)
CORES=$(nproc 2>/dev/null || echo 1); CORES="$(safe_int "$CORES")"; [ "$CORES" -eq 0 ] && CORES=1
LOAD=$(awk '{print $1,$2,$3}' /proc/loadavg 2>/dev/null)
LOAD1=$(awk '{print $1}' /proc/loadavg 2>/dev/null); LOAD1="$(safe_float "$LOAD1")"
LOAD_PCT=$(awk -v l="$LOAD1" -v c="$CORES" 'BEGIN{if(c>0)printf "%.0f",(l/c)*100;else print 0}')
[ "$LOAD_PCT" -ge 90 ] && LC="$R" || { [ "$LOAD_PCT" -ge 60 ] && LC="$Y" || LC="$G"; }
KERNEL=$(uname -r 2>/dev/null)
OS_NAME=$(grep '^PRETTY_NAME' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
[ -z "$OS_NAME" ] && OS_NAME=$(lsb_release -d 2>/dev/null | awk -F'\t' '{print $2}')

ROLE="GENERIC"
have nginx && [ -d /var/www ] && ROLE="WEB"
(have xray || pgrep -x xray-linux-amd64 >/dev/null 2>&1 || pgrep -x xray >/dev/null 2>&1) && ROLE="VPN/XRAY"
have wg   && ROLE="VPN/WG"
have awg  && ROLE="VPN/AWG"
[ "$ROLE" = "GENERIC" ] && have docker && ROLE="DOCKER/NODE"

# --- perf fix v2026.07.16: cscli called once, cached for sections 06,11,21,29,32 ---
CS_DECISIONS_CACHE=""
CS_METRICS_CACHE=""
if have cscli; then
  CS_DECISIONS_CACHE="$(timeout 5 cscli decisions list 2>/dev/null || true)"
  CS_METRICS_CACHE="$(timeout 5 cscli metrics 2>/dev/null || true)"
fi

# --- perf fix v2026.07.16: single cscli call cached, reused by sections 06,11,21,29,32 ---
CS_DECISIONS_CACHE=""
CS_METRICS_CACHE=""
if have cscli; then
  CS_DECISIONS_CACHE="$(timeout 5 cscli decisions list 2>/dev/null || true)"
  CS_METRICS_CACHE="$(timeout 5 cscli metrics 2>/dev/null || true)"
fi
case "$ROLE" in
  WEB)        TESTS=32 ;;
  VPN*|DOCKER*) TESTS=17 ;;
  *)          TESTS=13 ;;
esac

# --- perf fix v2026.07.16: cscli called ONCE, cached for sections 06,11,21,29,32 ---
CS_DECISIONS_CACHE=""
CS_METRICS_CACHE=""
if have cscli; then
  CS_DECISIONS_CACHE="$(timeout 5 cscli decisions list 2>/dev/null || true)"
  CS_METRICS_CACHE="$(timeout 5 cscli metrics 2>/dev/null || true)"
fi


printf "%s\n" "$SEP"
printf " ${W}SOS ${Y}%s${X} | ${G}%s${X} | ${Y}v.2026.07.16${X}\n" "$TW" "$NOW"
printf " ${C}%s${X} ${G}%s${X} | Load: ${LC}%s${X} (${LC}%s%%${X}/%sc) ${W}[%s | %d tests]${X}\n" \
  "$HOST" "$IP" "$LOAD" "$LOAD_PCT" "$CORES" "$ROLE" "$TESTS"
printf " ${C}Kernel:${X} ${W}%s${X} | ${C}OS:${X} ${W}%s${X}\n" "$KERNEL" "$OS_NAME"
printf "%s\n" "$SEP"
printf " ${C}Uptime:${X} ${W}%s${X}\n" "$(uptime -p)"

RAM_TOTAL=$(free -k | awk '/^Mem:/{print $2}'); RAM_TOTAL="$(safe_int "$RAM_TOTAL")"
RAM_USED=$( free -k | awk '/^Mem:/{print $3}'); RAM_USED="$(safe_int "$RAM_USED")"
printf " ${C}RAM:${X}  %s ${W}%s used / %s total (free %s)${X}\n" \
  "$(draw_bar "$RAM_USED" "$RAM_TOTAL")" \
  "$(free -h | awk '/^Mem:/{print $3}')" \
  "$(free -h | awk '/^Mem:/{print $2}')" \
  "$(free -h | awk '/^Mem:/{print $4}')"
SWAP_TOTAL=$(free -k | awk '/^Swap:/{print $2}'); SWAP_TOTAL="$(safe_int "$SWAP_TOTAL")"
SWAP_USED=$( free -k | awk '/^Swap:/{print $3}'); SWAP_USED="$(safe_int "$SWAP_USED")"
if [ "$SWAP_TOTAL" -gt 0 ]; then
  printf " ${C}Swap:${X} %s ${W}%s used / %s total${X}\n" \
    "$(draw_bar "$SWAP_USED" "$SWAP_TOTAL")" \
    "$(free -h | awk '/^Swap:/{print $3}')" \
    "$(free -h | awk '/^Swap:/{print $2}')"
else
  printf " ${C}Swap:${X} ${Y}not configured${X}\n"
fi

H "01. DISK"
printf "  %-20s %6s %6s %6s %5s %-6s\n" "Filesystem" "Size" "Used" "Avail" "Use%" "Mount"
df -k --output=source,size,used,avail,pcent,target 2>/dev/null | grep '^/dev' \
  | while read -r SRC SIZE USED AVAIL PCT MNT; do
    SIZE_H=$(df -h --output=size  "$SRC" 2>/dev/null | tail -1 | tr -d ' ')
    USED_H=$(df -h --output=used  "$SRC" 2>/dev/null | tail -1 | tr -d ' ')
    AVAIL_H=$(df -h --output=avail "$SRC" 2>/dev/null | tail -1 | tr -d ' ')
    printf "  ${C}%-20s${X} %6s %6s %6s %s %s\n" \
      "$SRC" "$SIZE_H" "$USED_H" "$AVAIL_H" "$(draw_bar "$USED" "$SIZE")" "$MNT"
  done

H "02. TOP 10 CPU%"
ps -eo pid,user,%cpu,pmem,args --sort=-%cpu 2>/dev/null \
  | awk 'NR==1||($5!~/^(ps|awk|grep|head|tail|sort)$/)' | head -15 | tail -10 \
  | awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-10s %5s %5s  %s\n",c,$1,x,$2,$3,$4,$5}'

H "03. TOP 15 RAM"
ps -eo pid,user,%cpu,pmem,rss,args --sort=-rss 2>/dev/null \
  | awk 'NR==1||($6!~/^(ps|awk|grep|head|tail|sort)$/)' | head -20 | tail -15 \
  | awk -v c="$C" -v x="$X" '{printf "  %s%-7s%s %-10s %5s %5s %6.1fMB  %s\n",c,$1,x,$2,$3,$4,$5/1024,$6}'

H "04. OOM KILLER (last boot)"
OOM_HITS=$(dmesg 2>/dev/null | grep -cE 'oom-kill|Out of memory|Killed process')
OOM_HITS="$(safe_int "$OOM_HITS")"
if [ "$OOM_HITS" -gt 0 ]; then
  printf "  ${R}OOM events: %d${X}\n" "$OOM_HITS"
  dmesg 2>/dev/null | grep -E 'oom-kill|Out of memory|Killed process' | tail -5 \
    | awk -v r="$R" -v x="$X" '{printf "  %s%s%s\n",r,$0,x}'
else
  printf "  ${G}No OOM kills detected${X}\n"
fi
OOM_SYSLOG=$(grep -cE 'oom-kill|Out of memory|Killed process' /var/log/syslog 2>/dev/null | head -1)
OOM_SYSLOG="$(safe_int "$OOM_SYSLOG")"
[ "$OOM_SYSLOG" -gt 0 ] && printf "  ${R}OOM entries in syslog: %d${X}\n" "$OOM_SYSLOG"

H "05. NETWORK"
printf "  ${C}Connections:${X}\n"
ss -s 2>/dev/null | grep -E 'Total|TCP:|UDP:' | sed 's/^/    /'
printf "  ${G}Interface traffic (session):${X}\n"
ip -s link 2>/dev/null \
  | awk '/^[0-9]+: (eth|ens|enp|wg|awg|tun|vmbr)/{ iface=$2; sub(/:/,"",iface)
      getline;getline;rx=$1;getline;tx=$1
      rxf=(rx/1024/1024>1024)?sprintf("%.1fG",rx/1024/1024/1024):sprintf("%.1fM",rx/1024/1024)
      txf=(tx/1024/1024>1024)?sprintf("%.1fG",tx/1024/1024/1024):sprintf("%.1fM",tx/1024/1024)
      printf "    %-10s RX=%-8s TX=%-8s\n",iface,rxf,txf
    }'
if have vnstat; then
  printf "  ${G}Monthly traffic:${X}\n"
  vnstat --iflist 2>/dev/null | grep -oE '[a-z]+[a-z0-9]+' | while read -r IFACE; do
    MONTH_DATA=$(vnstat -i "$IFACE" -m 2>/dev/null | awk -v mon="$(date '+%Y-%m')" '$0~mon{print}' | tail -1)
    [ -z "$MONTH_DATA" ] && continue
    RX_M=$(echo "$MONTH_DATA" | awk '{for(i=1;i<=NF;i++) if($i~/^[0-9]/&&$(i+1)~/^(GiB|MiB|TiB|KiB)$/){print $i" "$(i+1);break}}')
    TX_M=$(echo "$MONTH_DATA" | awk '{f=0;for(i=1;i<=NF;i++){if($i~/^[0-9]/&&$(i+1)~/^(GiB|MiB|TiB|KiB)$/){f++;if(f==2){print $i" "$(i+1);break}}}}')
    [ -n "$RX_M" ] && printf "    ${C}%-10s${X} RX=${G}%-10s${X} TX=${G}%s${X}\n" "$IFACE" "$RX_M" "$TX_M"
  done
fi

H "06. BLACKLIST SYSTEM"
IPSET_STATUS="${R}not loaded${X}"
IPSET_COUNT=0
if have ipset; then
  _RAW=$(ipset list vladblacklist 2>/dev/null | awk '/Number of entries/{print $NF}')
  _RAW="$(safe_int "$_RAW")"
  if [ "$_RAW" -gt 0 ]; then
    IPSET_COUNT="$_RAW"; IPSET_STATUS="${G}loaded — ${IPSET_COUNT} IPs/subnets${X}"
  elif ipset list vladblacklist >/dev/null 2>&1; then
    IPSET_STATUS="${Y}exists but empty${X}"
  fi
else
  IPSET_STATUS="${Y}ipset not installed${X}"
fi
printf "  ${C}ipset vladblacklist:${X}    %b\n" "$IPSET_STATUS"
IPTABLES_STATUS="${R}MISSING — not protected!${X}"
if have iptables && iptables -L INPUT -n 2>/dev/null | grep -q 'vladblacklist'; then
  RULE_NUM=$(iptables -L INPUT -n --line-numbers 2>/dev/null | awk '/vladblacklist/{print $1;exit}')
  IPTABLES_STATUS="${G}ACTIVE${X} (INPUT rule #${RULE_NUM})"
fi
printf "  ${C}iptables DROP rule:${X}     %b\n" "$IPTABLES_STATUS"
DEPLOY_LOG="/var/log/vladblacklist.log"
if [ -f "$DEPLOY_LOG" ]; then
  LAST_LINE=$(tail -1 "$DEPLOY_LOG" 2>/dev/null)
  [ -n "$LAST_LINE" ] && echo "$LAST_LINE" | grep -qiE 'error|fail|warn' \
    && printf "  ${C}Last deploy:${X}           ${R}%s${X}\n" "$LAST_LINE" \
    || printf "  ${C}Last deploy:${X}           ${G}%s${X}\n" "$LAST_LINE"
else
  printf "  ${C}Last deploy:${X}           ${Y}no log yet${X}\n"
fi
CRON_OK="${Y}not scheduled${X}"
crontab -l 2>/dev/null | grep -q 'deploy-blacklist.sh' && CRON_OK="${G}cron active${X}"
printf "  ${C}Auto-update:${X}           %b\n" "$CRON_OK"
if have cscli; then
  # timeout 5: prevent hang when CrowdSec LAPI is unresponsive (fix v.2026.07.04)
  CS_BANS=$(printf '%s\n' "$CS_DECISIONS_CACHE" | awk 'BEGIN{c=0}/^\|/{c++}END{print (c>0?c-1:0)}')
  CS_BANS="$(safe_int "$CS_BANS")"
  [ "$CS_BANS" -gt 0 ] && CS_COL="$R" || CS_COL="$G"
  printf "  ${C}CrowdSec active bans:${X}  %s%d IPs${X}\n" "$CS_COL" "$CS_BANS"
  CS_ALERTS=$(timeout 5 cscli alerts list --since 24h -l 3 2>/dev/null | grep -E '^\|' | grep -v 'Reason\|---' | head -3)
  [ -n "$CS_ALERTS" ] && printf "  ${C}Recent alerts (24h):${X}\n" && echo "$CS_ALERTS" | sed 's/^/    /'
else
  printf "  ${C}CrowdSec:${X} ${Y}not installed${X}\n"
fi

# ===============================================
# WEB ROLE
# ===============================================
if [ "$ROLE" = "WEB" ]; then

H "07. PHP-FPM POOLS"
ps -eo user,rss,args 2>/dev/null | grep -E 'php-fpm|php-cgi' | grep -v grep \
  | awk '{p=$1;r=$2;cnt[p]++;tot[p]+=r} END{for(p in cnt) printf "%s\t%d\t%.1f\n",p,cnt[p],tot[p]/1024}' \
  | sort -k3,3nr | head -10 \
  | awk -v c="$C" -v x="$X" '{printf "  %s%-26s%s %4d procs %7.1fMB\n",c,$1,x,$2,$3}'

H "08. TOP-10 TRAFFIC (last $TW)"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" -exec wc -l {} + 2>/dev/null \
  | awk '$2!="total"{print $1,$2}' | sort -rn | head -10 \
  | awk '{printf "  %7d  %s\n",$1,$2}'

H "09. TOP-10 IPs (last $TW)"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" -exec tail -n 2000 {} + 2>/dev/null \
  | awk '{print $1}' | grep -E '^[0-9a-fA-F.:]+$' | grep -vE '^$|^-$' \
  | sort | uniq -c | sort -rn | head -10 \
  | awk -v em="$EM" '{printf "  %6d %s %s\n",$1,em,$2}'

H "10. HTTP STATUS (last $TW)"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" -exec tail -n 2000 {} + 2>/dev/null \
  | awk '{print $9}' | grep -E '^[0-9]{3}$' | sort | uniq -c | sort -rn | head -10 \
  | awk -v g="$G" -v c="$C" -v y="$Y" -v r="$R" -v x="$X" -v em="$EM" '{
      if($2~/^2/)col=g; else if($2~/^3/)col=c; else if($2~/^4/)col=y; else col=r
      printf "  %6d %s %sHTTP %s%s\n",$1,em,col,$2,x
    }'

H "11. WP-LOGIN ATTACKS (last $TW)"
# timeout 5: prevent hang when CrowdSec LAPI is unresponsive (fix v.2026.07.04)
CS_BANNED_IPS=""
if have cscli; then
  CS_BANNED_IPS=$(printf '%s\n' "$CS_DECISIONS_CACHE" | awk -F'|' '/ban/{gsub(/ /,"",$3); print $3}')
fi
F2B_BANNED_IPS=""
if have fail2ban-client; then
  F2B_BANNED_IPS=$(fail2ban-client status nginx-wp-login 2>/dev/null | grep 'Banned IP' | sed 's/.*Banned IP list://;s/^ *//')
fi
{
  find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" -exec grep -h 'wp-login.php' {} + 2>/dev/null
  [ -d /var/log/nginx ] && grep -rh 'wp-login.php' /var/log/nginx/*.log 2>/dev/null
} | awk '{print $1}' | sort | uniq -c | sort -rn | head -10 \
  | while read -r COUNT IP_ADDR; do
      BAN_STATUS="${R}✗ NOT BANNED${X}"
      if echo "$CS_BANNED_IPS" | grep -q "^${IP_ADDR}$"; then
        BAN_STATUS="${G}✓ CrowdSec${X}"
      elif echo "$F2B_BANNED_IPS" | grep -q "$IP_ADDR"; then
        BAN_STATUS="${G}✓ fail2ban${X}"
      elif have ipset && ipset test vladblacklist "$IP_ADDR" 2>/dev/null; then
        BAN_STATUS="${G}✓ ipset${X}"
      fi
      COUNT_COL=$([ "$COUNT" -gt 100 ] && echo "$R" || { [ "$COUNT" -gt 20 ] && echo "$Y" || echo "$W"; })
      printf "  %s%5d%s  %-18s %b\n" "$COUNT_COL" "$COUNT" "$X" "$IP_ADDR" "$BAN_STATUS"
    done

H "12. HTTP 502/503 BY DOMAIN (last $TW)"
REDIRECT_DOMAINS=""
for CONF in /etc/nginx/sites-enabled/* /etc/nginx/conf.d/*.conf; do
  [ -f "$CONF" ] || continue
  DOMAIN_IN_CONF=$(grep -oP 'server_name\s+\K[^;]+' "$CONF" 2>/dev/null | awk '{print $1}' | head -1)
  [ -z "$DOMAIN_IN_CONF" ] && continue
  HAS_RETURN301=$(grep -cE 'return\s+301' "$CONF" 2>/dev/null || echo 0)
  HAS_PROXY=$(grep -cE 'proxy_pass|fastcgi_pass' "$CONF" 2>/dev/null || echo 0)
  HAS_RETURN301=$(safe_int "$HAS_RETURN301")
  HAS_PROXY=$(safe_int "$HAS_PROXY")
  if [ "$HAS_RETURN301" -gt 0 ] && [ "$HAS_PROXY" -eq 0 ]; then
    REDIRECT_DOMAINS="${REDIRECT_DOMAINS} ${DOMAIN_IN_CONF}"
  fi
done

find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" 2>/dev/null \
  | while read -r LOG; do
    DOMAIN=$(basename "$LOG" | sed 's/-frontend.*//; s/-backend.*//; s/-ssl.*//')
    CNT=$(tail -n 5000 "$LOG" 2>/dev/null | awk '$9=="502"||$9=="503"{c++}END{print c+0}')
    [ "${CNT:-0}" -eq 0 ] && continue
    printf "%d %s\n" "$CNT" "$DOMAIN"
  done \
  | sort -rn | head -10 \
  | while read -r COUNT DOMAIN; do
      IS_REDIRECT=0
      for RD in $REDIRECT_DOMAINS; do
        [ "$RD" = "$DOMAIN" ] && IS_REDIRECT=1 && break
      done
      if [ "$IS_REDIRECT" -eq 1 ]; then
        printf "  ${C}%-40s${X} ${G}→ 301 redirect (by design, OK)${X}\n" "$DOMAIN"
      else
        [ "$COUNT" -ge 10 ] && COL="$R" || COL="$Y"
        printf "  ${C}%-40s${X} %s%d errors%s\n" "$DOMAIN" "$COL" "$COUNT" "$X"
      fi
    done

H "13. PHP-FPM SLOW LOG (last 24h)"
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

H "14. NGINX SLOW REQUESTS >3s (last $TW)"
SLOW_TMP=$(mktemp)
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" 2>/dev/null \
  | while read -r LOG; do
    tail -n 5000 "$LOG" 2>/dev/null \
      | awk '{for(i=NF;i>=1;i--){if($i~/^[0-9]+\.[0-9]+$/&&$i+0>=3){printf "%.3f %s %s\n",$i,$7,$1;break}}}'
  done > "$SLOW_TMP"
SLOW_REQ=$(wc -l < "$SLOW_TMP" 2>/dev/null); SLOW_REQ="$(safe_int "$SLOW_REQ")"
if [ "$SLOW_REQ" -gt 0 ]; then
  printf "  ${R}Slow requests (>3s): %d${X}\n" "$SLOW_REQ"
  sort -rn "$SLOW_TMP" | head -10 \
    | awk -v r="$R" -v y="$Y" -v x="$X" '{col=($1+0>=10)?r:y;printf "    %s%7.3fs%s  %-50s  %s\n",col,$1,x,$2,$3}'
else
  printf "  ${G}No slow requests >3s detected${X}\n"
fi
rm -f "$SLOW_TMP"

H "15. PHP ERROR RATE (last $TW)"
find /var/www/*/data/logs/ -name "*access.log" -mmin "-${M}" 2>/dev/null \
  | while read -r LOG; do
    TOTAL=$(tail -n 5000 "$LOG" 2>/dev/null | wc -l | head -1); TOTAL="$(safe_int "$TOTAL")"
    [ "$TOTAL" -eq 0 ] && continue
    ERRLOG=$(echo "$LOG" | sed 's/access/error/')
    [ -f "$ERRLOG" ] || continue
    ERRS=$(tail -n 2000 "$ERRLOG" 2>/dev/null | grep -cE 'PHP Fatal|PHP Warning|PHP Notice|PHP Parse')
    ERRS="$(safe_int "$ERRS")"
    printf "%s\t%s\t%s\t%s\n" "$(basename "$LOG")" "$ERRS" "$TOTAL" "$(safe_pct "$ERRS" "$TOTAL")"
  done \
  | sort -t$'\t' -k4,4nr | head -10 \
  | awk -F'\t' -v c="$C" -v g="$G" -v y="$Y" -v r="$R" -v x="$X" '{
      pcti=$4+0; col=(pcti>=5)?r:((pcti>=1)?y:g)
      printf "  "c"%-40s"x" %s%s errs / %s req = %s%%%s\n",$1,col,$2,$3,$4,x
    }'

H "16. FONT FILE NAME TOO LONG (Flatsome)"
FONT_HITS=$(grep -r "File name too long" /var/www/*/data/logs/*frontend.error.log 2>/dev/null \
  | grep -i fonts | awk -F: '{print $1}' | sort -u)
if [ -n "$FONT_HITS" ]; then
  printf "  ${R}Sites with font filename errors:${X}\n"
  echo "$FONT_HITS" | while read -r LOGFILE; do
    DOMAIN=$(echo "$LOGFILE" | grep -oP '/var/www/\K[^/]+')
    CNT=$(grep 'File name too long' "$LOGFILE" 2>/dev/null | grep -ic fonts)
    CNT="$(safe_int "$CNT")"
    printf "  ${C}%-40s${X} ${R}%d errors${X}\n" "$DOMAIN" "$CNT"
  done
else
  printf "  ${G}No font filename errors found${X}\n"
fi

H "17. NGINX"
if have nginx; then
  printf "  ${C}Workers:${X} ${G}%s${X}  TCP established: ${G}%s${X}\n" \
    "$(pgrep -x nginx 2>/dev/null | wc -l)" \
    "$(ss -tnp state established 2>/dev/null | wc -l)"
  STUB=$(curl -s --max-time 2 http://127.0.0.1/nginx_status 2>/dev/null)
  [ -n "$STUB" ] && echo "$STUB" | awk '/Active/{printf "  Active connections: %s\n",$3}'
fi

H "18. MYSQL / MARIADB"
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
    if [ "$UPDAY" -eq 0 ] && [ "$UPHR" -lt 24 ]; then
      WCOL="$R"; WARN=" WARNING: RECENT RESTART!"
    else
      WCOL="$G"; WARN=""
    fi
    printf "  ${C}MariaDB uptime:${X} %s%dd %dh %dm${X}%s\n" "$WCOL" "$UPDAY" "$UPHR" "$UPMIN" "$WARN"
  fi
fi

H "19. MARIADB DATABASE SIZES"
if have mysql; then
  mysql -N -e "
    SELECT table_schema, ROUND(SUM(data_length+index_length)/1024/1024,1) AS mb
    FROM information_schema.tables
    WHERE table_schema NOT IN ('information_schema','performance_schema','sys','mysql')
    GROUP BY table_schema ORDER BY mb DESC;
  " 2>/dev/null | head -15 \
  | awk -v c="$C" -v g="$G" -v y="$Y" -v r="$R" -v x="$X" '{
      col=($2+0>=500)?r:(($2+0>=100)?y:g)
      printf "  %s%-35s%s %s%6.1f MB%s\n",c,$1,x,col,$2,x
    }'
fi

H "20. CRITICAL ERRORS (last $TW)"
find /var/www/*/data/logs/ -name "*error.log" -mmin "-${M}" \
  -exec grep -iE 'fatal|Out of memory|upstream timed out|connect\(\) failed|no live upstreams' {} + 2>/dev/null \
  | tail -10

H "21. CROWDSEC"
if have cscli; then
  # timeout 5: prevent hang when CrowdSec LAPI is unresponsive (fix v.2026.07.04)
  BANS=$(printf '%s\n' "$CS_DECISIONS_CACHE" | awk 'BEGIN{c=0}/^\|/{c++}END{print (c>0?c-1:0)}')
  BANS="$(safe_int "$BANS")"
  printf "  ${C}Bans:${X} ${R}%s${X}\n" "$BANS"
  timeout 5 cscli alerts list --since "$TW" -l 10 2>/dev/null | head -12 | sed 's/^/  /'
fi

H "22. FAIL2BAN / UFW"
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
else
  printf "  ${Y}fail2ban not installed${X}\n"; fi
printf "  ${C}UFW:${X} "
if have ufw; then
  UFW_ST=$(ufw status 2>/dev/null | head -1)
  [[ "$UFW_ST" == *active* ]] && printf "${G}%s${X}\n" "$UFW_ST" || printf "${Y}%s${X}\n" "$UFW_ST"
  ufw status numbered 2>/dev/null | grep -E '^\[' | tail -10 | sed 's/^/    /'
else
  printf "${Y}not installed${X}\n"; fi

fi # end WEB

# ===============================================
# VPN ROLE
# ===============================================
if [[ "$ROLE" == VPN* ]]; then

H "07. VPN STATUS"
for WG_CMD in wg awg; do
  have "$WG_CMD" || continue
  printf "  ${C}%s interfaces:${X}\n" "$WG_CMD"
  "$WG_CMD" show all 2>/dev/null \
    | grep -E '^interface|peer|endpoint|transfer|latest' | sed 's/^/    /'
done
if have xray || pgrep -x xray-linux-amd64 >/dev/null 2>&1; then
  printf "  ${C}Xray process:${X} "
  XRAY_PID=$(pgrep -x xray-linux-amd64 2>/dev/null | head -1)
  [ -z "$XRAY_PID" ] && XRAY_PID=$(pgrep -x xray 2>/dev/null | head -1)
  if [ -n "$XRAY_PID" ]; then
    printf "${G}running${X}  PID: ${W}%s${X}  uptime: ${W}%s${X}\n" \
      "$XRAY_PID" "$(ps -o etime= -p "$XRAY_PID" 2>/dev/null | tr -d ' ')"
  else
    printf "${R}NOT running${X}\n"
  fi
  XRAY_CONNS=$(ss -tnp state established 2>/dev/null | grep -cE 'xray|xray-linux-amd64')
  printf "  ${C}Xray TCP established:${X} ${G}%s${X}\n" "$(safe_int "$XRAY_CONNS")"
fi
XUI_ST=$(systemctl is-active x-ui 2>/dev/null)
if [ -n "$XUI_ST" ]; then
  [ "$XUI_ST" = "active" ] && XUI_COL="$G" || XUI_COL="$R"
  printf "  ${C}x-ui panel:${X} %s%s${X}" "$XUI_COL" "$XUI_ST"
  XUI_CLIENTS=$(ss -tnp state established 2>/dev/null | grep -c 'xray\|x-ui')
  printf "  (active TCP: ${W}%s${X})\n" "$(safe_int "$XUI_CLIENTS")"
fi

H "08. VPN PEERS"
for WG_CMD in wg awg; do
  have "$WG_CMD" || continue
  PC=$("$WG_CMD" show all peers 2>/dev/null | wc -l)
  printf "  ${C}%s peers total:${X} ${G}%s${X}\n" "$WG_CMD" "$(safe_int "$PC")"
done

H "09. VPN TRAFFIC (interfaces)"
ip -s link 2>/dev/null | awk '/^[0-9]+: (wg|awg|tun)/{ iface=$2; sub(/:/,"",iface)
    getline;getline;rx=$1;getline;tx=$1
    rxg=(rx/1024/1024>1024)?sprintf("%.2fG",rx/1024/1024/1024):sprintf("%.2fM",rx/1024/1024)
    txg=(tx/1024/1024>1024)?sprintf("%.2fG",tx/1024/1024/1024):sprintf("%.2fM",tx/1024/1024)
    printf "  %-10s RX=%-10s TX=%-10s\n",iface,rxg,txg
  }'

H "10. FAIL2BAN / UFW"
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
else
  printf "  ${Y}fail2ban not installed${X}\n"; fi
printf "  ${C}UFW:${X} "
if have ufw; then
  UFW_ST=$(ufw status 2>/dev/null | head -1)
  [[ "$UFW_ST" == *active* ]] && printf "${G}%s${X}\n" "$UFW_ST" || printf "${Y}%s${X}\n" "$UFW_ST"
  ufw status numbered 2>/dev/null | grep -E '^\[' | tail -10 | sed 's/^/    /'
else
  printf "${Y}not installed${X}\n"; fi

fi # end VPN

H "23. DOCKER"
if have docker; then
  docker ps -a --format "{{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null | head -10 \
    | awk -F'\t' -v g="$G" -v r="$R" -v c="$C" -v x="$X" '{
        col=($2~/^Up/)?g:r
        printf "  %s%-28s%s %s%s%s  %s\n",c,$1,x,col,$2,x,$3
      }'
else
  printf "  ${Y}docker not installed${X}\n"
fi

H "24. SERVICES"
SVC_LIST=(nginx mariadb mysql php8.1-fpm php8.2-fpm php8.3-fpm php8.4-fpm \
  crowdsec crowdsec-firewall-bouncer fail2ban exim4 postfix docker \
  ssh xray wg-quick@wg0 amnezia-wg smbd nmbd vnstat x-ui)
for SVC in "${SVC_LIST[@]}"; do
  systemctl list-units --type=service --all 2>/dev/null | grep -q "${SVC}.service" && {
    STATE=$(systemctl is-active "$SVC" 2>/dev/null)
    [ "$STATE" = "active" ] && SC="$G" || SC="$R"
    printf "  ${C}%-38s${X} %s%s${X}\n" "$SVC" "$SC" "$STATE"
  }
done
printf "  ${C}%-38s${X} " "xray-process"
XRAY_PID=$(pgrep -x xray-linux-amd64 2>/dev/null | head -1)
[ -z "$XRAY_PID" ] && XRAY_PID=$(pgrep -x xray 2>/dev/null | head -1)
if [ -n "$XRAY_PID" ]; then
  printf "${G}running${X}  PID: ${W}%s${X}  uptime: ${W}%s${X}\n" \
    "$XRAY_PID" "$(ps -o etime= -p "$XRAY_PID" 2>/dev/null | tr -d ' ')"
else
  printf "${R}not running${X} ${Y}(xray/xray-linux-amd64 process not found; if x-ui is installed, check panel status and spawned core)${X}\n"
fi

H "25. FASTPANEL2 SERVICES"
FP_FOUND=0
while IFS= read -r UNIT; do
  SVC_NAME=$(echo "$UNIT" | awk '{print $1}' | sed 's/\.service//')
  STATE=$(systemctl is-active "$SVC_NAME" 2>/dev/null)
  [ "$STATE" = "active" ] && SC="$G" || SC="$R"
  printf "  ${C}%-38s${X} %s%s${X}\n" "$SVC_NAME" "$SC" "$STATE"
  FP_FOUND=1
done < <(systemctl list-units --type=service --all 2>/dev/null \
  | grep -E 'fastpanel|fpanel|fp2' | awk '{print $1}')
[ "$FP_FOUND" -eq 0 ] && printf "  ${Y}FastPanel2 not detected on this server${X}\n"

H "26. SWAP TOP-5 PROCESSES"
awk '/^Pid:/{pid=$2}/^Name:/{name=$2}/^VmSwap:/{swap=$2;if(swap+0>0)print swap,pid,name}' \
  /proc/*/status 2>/dev/null | sort -rn | head -5 \
  | awk -v c="$C" -v y="$Y" -v r="$R" -v x="$X" '{
      col=($1/1024>=200)?r:(($1/1024>=50)?y:c)
      printf "  %sPID %-7s%s %-25s %s%6.1f MB%s\n",c,$2,x,$3,col,$1/1024,x
    }'

# ==============================================================================
# 27. OPEN PORTS
# ==============================================================================
H "27. OPEN PORTS"

_ports_dedup() {
  local proto="$1"
  local ss_flag="$2"

  ss ${ss_flag} 2>/dev/null | awk -v proto="$proto" '
    NR > 1 {
      addr = $4
      proc = $NF
      if (match(proc, /"([^"]+)"/, arr)) {
        pname = arr[1]
      } else {
        pname = proc
      }
      key = addr SUBSEP pname
      if (seen[key]++) next
      print addr, pname
    }
  ' | sort -t: -k2 -n
}

printf "  ${C}TCP LISTEN:${X}\n"
_ports_dedup tcp "-tlnp" \
  | awk -v c="${C}" -v g="${G}" -v x="${X}" '{
      printf "    %s%-36s%s %s\"%s\"%s\n", c, $1, x, g, $2, x
    }'

printf "\n  ${C}UDP LISTEN:${X}\n"
_ports_dedup udp "-ulnp" \
  | awk -v c="${C}" -v g="${G}" -v x="${X}" '{
      printf "    %s%-36s%s %s\"%s\"%s\n", c, $1, x, g, $2, x
    }'

printf "\n  ${C}Key ports:${X}\n"
declare -A KPNAMES=(
  [21]="FTP"          [22]="SSH"         [25]="SMTP"
  [53]="DNS"          [80]="HTTP"        [110]="POP3"
  [139]="Samba-NB"    [143]="IMAP"       [443]="HTTPS"
  [445]="Samba"       [465]="SMTPS"      [587]="SMTP-sub"
  [993]="IMAPS"       [995]="POP3S"      [2222]="SSH-alt"
  [3000]="Semaphore/AGH" [7777]="FP2-panel" [8080]="AGH-Web"
  [8443]="HTTPS-alt"  [8888]="FP2-http"  [9100]="Prometheus"
  [30452]="x-ui"      [51820]="WireGuard"
)
for PORT in 21 22 25 53 80 110 139 143 443 445 465 587 993 995 2222 3000 7777 8080 8443 8888 9100 30452 51820; do
  KNAME="${KPNAMES[$PORT]}"
  TC=$(ss -tlnp 2>/dev/null | awk -v p=":${PORT} " '$0~p{c++}END{print c+0}')
  UC=$(ss -ulnp 2>/dev/null | awk -v p=":${PORT} " '$0~p{c++}END{print c+0}')
  TC=${TC:-0}; UC=${UC:-0}
  TOTAL=$(( TC + UC ))
  if [ "$TOTAL" -gt 0 ]; then
    PROTO=""
    [ "$TC" -gt 0 ] && PROTO="${PROTO}TCP "
    [ "$UC" -gt 0 ] && PROTO="${PROTO}UDP"
    printf "    ${G}%-6s${X} ${C}%-15s${X} ${G}open${X}   [%s]\n" "$PORT" "$KNAME" "$PROTO"
  else
    printf "    ${Y}%-6s${X} ${C}%-15s${X} ${Y}closed${X}\n" "$PORT" "$KNAME"
  fi
done

H "28. DMESG ERRORS"
dmesg -T 2>/dev/null | grep -iE 'error|fail|oom|kill|panic|warn' | tail -10 | sed 's/^/  /'

H "29. CROWDSEC METRICS"
# timeout 5: prevent hang when CrowdSec LAPI is unresponsive (fix v.2026.07.04)
[ -n "$CS_METRICS_CACHE" ] && printf '%s\n' "$CS_METRICS_CACHE" \
  | awk '/Parsers/{p=1} p&&/\|/{printf "  %s\n",$0}' | head -8

H "30. CRONTAB ROOT"
CRON_LINES=$(crontab -l 2>/dev/null | grep -v '^#' | grep -v '^[[:space:]]*$')
if [ -n "$CRON_LINES" ]; then
  printf "  ${C}crontab -l (root):${X}\n"
  echo "$CRON_LINES" \
    | awk -v y="$Y" -v g="$G" -v x="$X" '{
        col=($0~/blacklist|deploy|backup|sync/)?y:g
        printf "  %s%s%s\n",col,$0,x
      }'
else
  printf "  ${Y}No active cron jobs for root${X}\n"
fi
if [ -d /etc/cron.d ] && ls /etc/cron.d/ >/dev/null 2>&1; then
  printf "  ${C}Files in /etc/cron.d/:${X} "
  ls /etc/cron.d/ 2>/dev/null | tr '\n' ' '; printf "\n"
fi

H "31. LAST LOGINS SSH"
last -n 8 2>/dev/null | grep -v '^$\|^wtmp' \
  | awk -v c="$C" -v g="$G" -v y="$Y" -v x="$X" '{
      user=$1;tty=$2
      if(user=="reboot")col=y
      else if(tty~/pts/)col=g
      else col=c
      printf "  %s%-12s%s %-8s %-18s %s %s %s\n",col,user,x,tty,$3,$4,$5,$6
    }'

# ==============================================================================
# 32. CROWDSEC SYNC CHECK (WEB role only)
# ==============================================================================
if [ "$ROLE" = "WEB" ] && have cscli && have iptables; then
H "32. CROWDSEC SYNC CHECK"
SYNC_ISSUES=0

# timeout 5: prevent hang when CrowdSec LAPI is unresponsive (fix v.2026.07.04)
CS_IPS=$(printf '%s\n' "$CS_DECISIONS_CACHE" \
  | awk -F'|' '/ban/{gsub(/ /,"",$3); if($3~/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) print $3}' \
  | sort -u | head -30)

if [ -z "$CS_IPS" ]; then
  printf "  ${G}No CrowdSec bans to check${X}\n"
else
  CS_CHAIN_EXISTS=0
  iptables -L CROWDSEC_CHAIN -n 2>/dev/null | grep -q 'Chain CROWDSEC_CHAIN' && CS_CHAIN_EXISTS=1

  if [ "$CS_CHAIN_EXISTS" -eq 0 ]; then
    printf "  ${R}WARNING: CROWDSEC_CHAIN missing from iptables! Bouncer not working!${X}\n"
    SYNC_ISSUES=1
  else
    printf "  ${G}CROWDSEC_CHAIN: present in iptables${X}\n"
  fi

  CS_IPSET_COUNT=0
  if have ipset && ipset list crowdsec-blacklists >/dev/null 2>&1; then
    CS_IPSET_COUNT=$(ipset list crowdsec-blacklists 2>/dev/null | awk '/Number of entries/{print $NF}')
    CS_IPSET_COUNT="$(safe_int "$CS_IPSET_COUNT")"
    printf "  ${C}crowdsec-blacklists ipset:${X} ${G}%d entries${X}\n" "$CS_IPSET_COUNT"
  else
    printf "  ${Y}crowdsec-blacklists ipset: not found (bouncer may use iptables directly)${X}\n"
  fi

  CHECKED=0; MISSING=0
  while IFS= read -r BAN_IP; do
    [ -z "$BAN_IP" ] && continue
    [ "$CHECKED" -ge 5 ] && break
    BLOCKED=0
    have ipset && ipset test crowdsec-blacklists "$BAN_IP" 2>/dev/null && BLOCKED=1
    [ "$BLOCKED" -eq 0 ] && have ipset && ipset test vladblacklist "$BAN_IP" 2>/dev/null && BLOCKED=1
    [ "$BLOCKED" -eq 0 ] && iptables -L CROWDSEC_CHAIN -n 2>/dev/null | grep -q "$BAN_IP" && BLOCKED=1
    if [ "$BLOCKED" -eq 0 ]; then
      printf "  ${R}DESYNC: %s — in CrowdSec decisions but NOT in firewall!${X}\n" "$BAN_IP"
      MISSING=$(( MISSING + 1 ))
      SYNC_ISSUES=1
    fi
    CHECKED=$(( CHECKED + 1 ))
  done <<< "$CS_IPS"

  if [ "$SYNC_ISSUES" -eq 0 ]; then
    CS_TOTAL=$(echo "$CS_IPS" | wc -l | tr -d ' ')
    printf "  ${G}✓ Bouncer in sync — checked %d sample IPs, all blocked in firewall${X}\n" "$CHECKED"
    printf "  ${G}✓ Total CrowdSec decisions: %d IPs${X}\n" "$CS_TOTAL"
  else
    printf "  ${R}ACTION NEEDED: Run: systemctl restart crowdsec-firewall-bouncer${X}\n"
  fi
fi
fi # end CROWDSEC SYNC CHECK

printf "\n%s\n ${W}= Rooted by VladiMIR + AI | v.2026.07.16 | github.com/GinCz =${X}\n%s\n" "$SEP" "$SEP"
