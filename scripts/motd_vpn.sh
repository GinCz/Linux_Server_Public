#!/bin/bash
# =============================================================================
# motd_vpn.sh — MOTD banner for VPN nodes (AmneziaWG / Xray)
# Version     : v2026-04-30
# Install     : cp /root/Linux_Server_Public/scripts/motd_vpn.sh /etc/profile.d/motd_server.sh
#               chmod +x /etc/profile.d/motd_server.sh
# = Rooted by VladiMIR | AI =
# =============================================================================

shopt -q login_shell || return 0 2>/dev/null || exit 0
[ -n "$SSH_CONNECTION" ] || return 0 2>/dev/null || exit 0

C="\033[1;36m"
G="\033[1;32m"
Y="\033[1;33m"
W="\033[1;37m"
R="\033[1;31m"
X="\033[0m"
LINE="\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501"

# --- Stats ---
IP=$(hostname -I | awk '{print $1}')
RAM_USED=$(free -m | awk '/Mem:/{print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
CPU=$(top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}')
UPTIME=$(uptime -p | sed 's/up //')
HN=$(hostname)
LOAD=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

# --- AmneziaWG ---
PEERS_TOTAL=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 | wc -l || echo 0)
PEERS_ONLINE=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 \
  | awk -v t="$(date +%s)" '$5>0 && (t-$5)<180 {c++} END{print c+0}')
[[ -z "$PEERS_TOTAL" ]] && PEERS_TOTAL=0
[[ -z "$PEERS_ONLINE" ]] && PEERS_ONLINE=0

# --- CrowdSec ---
if systemctl is-active --quiet crowdsec 2>/dev/null; then
  CS_STATUS="${G}\u25cf ACTIVE${X}"
else
  CS_STATUS="${R}\u25cf INACTIVE${X}"
fi

# --- Header ---
echo -e "${C}${LINE}${X}"
printf "  ${C}\U0001f512  %-24s${X} ${W}%-22s${X} ${Y}RAM:${W}%s/%sMB${X}  ${Y}CPU:${W}%s%%${X}\n" \
  "$HN" "$IP" "$RAM_USED" "$RAM_TOTAL" "$CPU"
echo -e "  ${Y}AmneziaWG: ${G}${PEERS_ONLINE} online${X}${Y} / ${W}${PEERS_TOTAL} total peers${X}  ${Y}CrowdSec: ${CS_STATUS}"
echo -e "${C}${LINE}${X}"

# --- Row 1: VPN MANAGEMENT | SERVER | GIT ---
echo -e "  ${Y}VPN MANAGEMENT            SERVER                    GIT${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}aw${X}(WG peers stats)       ${G}audit${X}(security 1h)       ${G}save${X}(git push)"
echo -e "  ${G}banlog${X}(ban list)         ${G}infooo${X}(server info)       ${G}load${X}(git pull+deploy)"
echo -e "  ${G}antivir${X}(ClamAV scan)     ${G}f2${X}(commands menu)        ${G}mc${X}(Midnight Cmdr)"
echo -e "  ${G}backup${X}(VPN configs)      ${G}00${X}(clear screen)         ${G}ll${X}(list long)"
echo -e "  ${G}f5servers${X}(backup menu)   ${G}f9servers${X}(restore menu)   ${G}la${X}(list hidden)"
echo -e "${C}${LINE}${X}"

# --- Footer ---
echo -e "  ${Y}Ubuntu 24${X} | ${Y}VPN Node${X} | ${W}${IP}${X} | up ${W}${UPTIME}${X} | load: ${G}${LOAD}${X}"
echo
