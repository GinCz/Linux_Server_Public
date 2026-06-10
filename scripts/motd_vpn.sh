#!/bin/bash
# =============================================================================
# motd_vpn.sh — MOTD banner for VPN nodes (AmneziaWG / Xray)
# Version     : v2026-06-10
# = Rooted by VladiMIR | AI =
# =============================================================================

shopt -q login_shell || return 0 2>/dev/null || exit 0
[ -n "$SSH_CONNECTION" ] || return 0 2>/dev/null || exit 0

C="\033[01;96m"
G="\033[1;32m"
Y="\033[1;33m"
W="\033[1;37m"
R="\033[1;31m"
X="\033[0m"
LINE="\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501"

HN=$(cat /etc/hostname 2>/dev/null | head -1 | tr -d '[:space:]')
[[ -z "$HN" ]] && HN=$(hostname 2>/dev/null || echo "unknown")
IP=$(hostname -I 2>/dev/null | awk '{print $1}')
RAM_USED=$(free -m | awk '/Mem:/{print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
CPU=$(top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}')
UPTIME=$(uptime -p | sed 's/up //')
LOAD=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

# AmneziaWG peers
AWG_LINE=""
if docker exec amnezia-awg wg show wg0 dump &>/dev/null 2>&1; then
  PEERS_TOTAL=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 | wc -l)
  PEERS_ONLINE=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 \
    | awk -v t="$(date +%s)" '$5>0 && (t-$5)<180 {c++} END{print c+0}')
  [[ -z "$PEERS_TOTAL" ]]  && PEERS_TOTAL=0
  [[ -z "$PEERS_ONLINE" ]] && PEERS_ONLINE=0
  AWG_LINE="  ${Y}AmneziaWG:${X} ${G}${PEERS_ONLINE} online${X} / ${W}${PEERS_TOTAL} total peers${X}"
fi

# CrowdSec — always show status (green=active, red=inactive)
if systemctl is-active --quiet crowdsec 2>/dev/null; then
  BAN_COUNT=$(cscli decisions list -o raw 2>/dev/null | grep -c ',' || echo 0)
  CS_LINE="  ${Y}CrowdSec:${X} ${G}\u25cf ACTIVE${X} | bans: ${W}${BAN_COUNT}${X}"
else
  CS_LINE="  ${Y}CrowdSec:${X} ${R}\u2717 INACTIVE \u2014 no protection!${X}"
fi

echo -e "${C}${LINE}${X}"
echo -e "  ${C}\U0001f5a5  ${W}${HN}${X}  ${Y}${IP}${X}  RAM:${W}${RAM_USED}/${RAM_TOTAL}MB${X}  CPU:${W}${CPU}%%${X}"
echo -e "${AWG_LINE}"
echo -e "${CS_LINE}"
echo -e "${C}${LINE}${X}"
echo -e "  ${Y}VPN MANAGEMENT            SERVER                    GIT${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}banlog${X}(ban list)         ${G}sos${X}(audit 1h)           ${G}save${X}(git push)"
echo -e "  ${G}banblock${X}(ban IP)         ${G}sos3${X}(audit 3h)          ${G}load${X}(git pull+deploy)"
echo -e "  ${G}antivir${X}(ClamAV scan)     ${G}sos24${X}(audit 24h)        ${G}mc${X}(Midnight Cmdr)"
echo -e "  ${G}backup${X}(VPN configs)      ${G}infooo${X}(server info)     ${G}00${X}(clear screen)"
echo -e "${C}${LINE}${X}"
echo -e "  ${Y}Ubuntu 24${X} | ${Y}VPN Node${X} | up ${W}${UPTIME}${X} | load: ${G}${LOAD}${X}"
echo
