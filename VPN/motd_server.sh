#!/bin/bash
# =============================================================================
# motd_server.sh — MOTD banner for VPN nodes (AmneziaWG)
# Version     : v2026-03-25
# Author      : Ing. VladiMIR Bulantsev
# Install     : cp VPN/motd_server.sh /etc/profile.d/motd_server.sh && chmod +x /etc/profile.d/motd_server.sh
# = Rooted by VladiMIR | AI =
# =============================================================================

C="\033[1;36m"   # cyan (headers, lines)
G="\033[1;32m"   # green (aliases)
Y="\033[1;33m"   # yellow (labels)
W="\033[1;37m"   # white (values)
X="\033[0m"      # reset

IP=$(hostname -I | awk '{print $1}')
RAM_USED=$(free -m | awk '/Mem:/{print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2+$4)}')
UPTIME=$(uptime -p | sed 's/up //')
HN=$(hostname)
LOAD=$(cat /proc/loadavg | cut -d' ' -f1-3)
PEERS=$(wg show 2>/dev/null | grep -c '^peer' || echo 0)

echo -e "${C}╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋${X}"
printf "  ${C}🔒  %-24s${X} ${W}%-22s${X} ${Y}RAM:${W}%s/%sMB${X}  ${Y}CPU:${W}%s%%${X}\n" "$HN" "$IP" "$RAM_USED" "$RAM_TOTAL" "$CPU"
printf "  ${Y}AmneziaWG peers: ${G}%-3s${X}\n" "$PEERS"
echo -e "${C}╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋${X}"
echo -e "  ${Y}VPN MANAGEMENT            ${Y}SERVER                    ${Y}GIT${X}"
echo -e "${C}╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋${X}"
echo -e "  ${G}aw${X}(WG peers stats)        ${G}sos${X}(now)                  ${G}save${X}(git push)"
echo -e "  ${G}audit${X}(security+load)      ${G}sos3/24/120${X}(3/24/120h)    ${G}load${X}(git pull)"
echo -e "  ${G}backup${X}(backup → 222)      ${G}i${X}(full info)              ${G}m${X}(Midnight Commander)"
echo -e "  ${G}00${X}(clear)                 ${G}la${X}(list hidden)            ${G}banlog${X}(ban list)"
echo -e "${C}╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋${X}"
echo -e "  ${Y}Ubuntu 24${X} | ${W}${IP}${X} | up ${W}${UPTIME}${X} | load: ${G}${LOAD}${X}"
echo
