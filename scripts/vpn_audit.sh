#!/bin/bash
# =============================================================================
# vpn_audit.sh — Server audit for VPN nodes (AmneziaWG / Xray)
# Version     : v2026-04-30
# Install     : cp scripts/vpn_audit.sh /usr/local/bin/audit && chmod +x /usr/local/bin/audit
# Usage       : audit [1h|3h|24h|120h]
# = Rooted by VladiMIR | AI =
# =============================================================================
clear

WINDOW="${1:-1h}"
case "${WINDOW}" in
  1h)   MINS=60 ;;
  3h)   MINS=180 ;;
  24h)  MINS=1440 ;;
  120h) MINS=7200 ;;
  *)    MINS=60; WINDOW="1h" ;;
esac
SINCE=$(date --date="${MINS} minutes ago" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || date -v-${MINS}M '+%Y-%m-%dT%H:%M:%S')

G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; R='\033[1;31m'; W='\033[1;37m'; X='\033[0m'
LINE="$(printf '=%.0s' {1..60})"

hdr() { echo; echo -e "${Y}${LINE}${X}"; echo -e "${C}  $1${X}"; echo -e "${Y}${LINE}${X}"; }

echo -e "${Y}${LINE}${X}"
echo -e "${C}  VPN AUDIT (${WINDOW}) | $(hostname) | $(date)${X}"
echo -e "${Y}${LINE}${X}"

# --- System ---
hdr "⚙️  SYSTEM"
RAM_USED=$(free -m | awk '/Mem:/{print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
RAM_PCT=$(free | awk '/Mem:/{printf "%d", $3/$2*100}')
SWAP=$(free -m | awk '/Swap:/{print $3"/"$2"MB"}')
CPU=$(top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}')
LOAD=$(awk '{print $1"/"$2"/"$3}' /proc/loadavg)
echo -e "  RAM:  ${RAM_USED}/${RAM_TOTAL}MB (${RAM_PCT}%)  |  Swap: ${SWAP}"
echo -e "  CPU:  ${CPU}%  |  Load 1/5/15m: ${LOAD}"
echo -e "  Up:   $(uptime -p | sed 's/up //')"
echo
df -h | awk 'NR==1 || /^\/dev/{printf "  %-20s %6s %6s %6s %5s\n",$1,$2,$3,$4,$5}'

# --- Docker containers ---
hdr "🐳  DOCKER CONTAINERS"
if command -v docker &>/dev/null; then
    docker ps -a --format '  {{.Names}}\t{{.Status}}\t{{.Image}}' 2>/dev/null | \
        awk '{status=$2; if(status~/^Up/) c="\033[1;32m"; else c="\033[1;31m"; \
        printf "  \033[1;36m%-25s\033[0m %s%s\033[0m\n", $1, c, substr($0, index($0,$2))}' || \
        echo "  No containers"
else
    echo "  Docker not installed"
fi

# --- AmneziaWG ---
hdr "🔒  AMNEZIAWG STATUS"
if docker exec amnezia-awg wg show wg0 dump &>/dev/null 2>&1; then
    TOTAL=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 | wc -l)
    ONLINE=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 \
        | awk -v t="$(date +%s)" '$5>0 && (t-$5)<180 {c++} END{print c+0}')
    echo -e "  ${G}${ONLINE} online${X} / ${W}${TOTAL} total peers${X}"
    echo
    docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 | \
        awk -v t="$(date +%s)" '{
            age = (t - $5); ago = (age<60)?age"s":(age<3600)?int(age/60)"m":int(age/3600)"h"
            rx=sprintf("%.1fMB",$6/1048576); tx=sprintf("%.1fMB",$7/1048576)
            status = ($5>0 && age<180) ? "\033[1;32mONLINE\033[0m" : "\033[0;37mOFFLINE\033[0m"
            printf "  %-20s  %s  RX:%-10s TX:%-10s last:%s ago\n", substr($1,1,20), status, rx, tx, ago
        }' | head -20
elif command -v wg &>/dev/null; then
    wg show 2>/dev/null || echo "  WireGuard not running"
else
    echo "  AmneziaWG not running or Docker not available"
fi

# --- Xray / x-ui ---
hdr "🌐  XRAY / X-UI STATUS"
if systemctl is-active --quiet x-ui 2>/dev/null; then
    echo -e "  x-ui: ${G}ACTIVE${X}"
    ss -tulnp 2>/dev/null | grep -E ':443|:80|xray' | awk '{printf "  %s\n", $0}' | head -5
else
    echo -e "  x-ui: ${R}INACTIVE${X} (not installed or stopped)"
fi

# --- CrowdSec ---
hdr "🛡️  CROWDSEC"
if systemctl is-active --quiet crowdsec 2>/dev/null; then
    BAN_COUNT=$(cscli decisions list 2>/dev/null | grep -c ' ban ' || echo 0)
    echo -e "  Engine: ${G}ACTIVE${X}  |  Active bans: ${W}${BAN_COUNT}${X}"
    echo
    cscli decisions list 2>/dev/null | head -10 || true
else
    echo -e "  CrowdSec: ${R}NOT RUNNING${X}"
fi

# --- Auth failures ---
hdr "🔐  SSH AUTH FAILURES (last ${WINDOW})"
FAILS=$(journalctl _SYSTEMD_UNIT=ssh.service --since "${SINCE}" 2>/dev/null \
    | grep -i 'failed\|invalid\|refused' | wc -l || echo 0)
echo -e "  Failed auth attempts: ${W}${FAILS}${X}"
if [[ ${FAILS} -gt 0 ]]; then
    journalctl _SYSTEMD_UNIT=ssh.service --since "${SINCE}" 2>/dev/null \
        | grep -oP 'from \K[0-9.]+' | sort | uniq -c | sort -rn | head -10 \
        | awk '{printf "  %5sx  %s\n", $1, $2}'
fi

# --- System errors ---
hdr "❌  SYSTEM ERRORS (last ${WINDOW})"
ERR_COUNT=$(journalctl -p err --since "${SINCE}" 2>/dev/null | grep -v '^--' | wc -l || echo 0)
echo -e "  Errors in journal: ${W}${ERR_COUNT}${X}"
if [[ ${ERR_COUNT} -gt 0 ]]; then
    journalctl -p err --since "${SINCE}" 2>/dev/null | grep -v '^--' | tail -10 \
        | awk '{printf "  %s\n", $0}'
fi

echo
echo -e "${Y}${LINE}${X}"
echo -e "${C}  audit ${WINDOW} done | $(hostname) | $(date +%H:%M)${X}"
echo -e "${Y}${LINE}${X}"
echo
