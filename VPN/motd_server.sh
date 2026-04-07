#!/bin/bash
# =============================================================================
# motd_server.sh — MOTD banner for ALL VPN nodes (AmneziaWG)
# Version     : v2026-04-07
# Author      : Ing. VladiMIR Bulantsev
# Install     : cp /root/Linux_Server_Public/VPN/motd_server.sh /etc/profile.d/motd_server.sh
#               chmod +x /etc/profile.d/motd_server.sh
# Update      : load  (= git pull + deploy automatically)
# HOW MENU WORKS: aliases are read automatically from .bashrc — no manual edit needed
# = Rooted by VladiMIR | AI =
# =============================================================================

C="\033[1;36m"   # cyan
G="\033[1;32m"   # green
Y="\033[1;33m"   # yellow
W="\033[1;37m"   # white
X="\033[0m"      # reset
LINE="\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501"

IP=$(hostname -I | awk '{print $1}')
RAM_USED=$(free -m | awk '/Mem:/{print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2+$4)}')
UPTIME=$(uptime -p | sed 's/up //')
HN=$(hostname)

# Load as percent of 1 core (VPN nodes = 1 core); >100% = overloaded
LOAD1=$(awk '{printf "%.0f%%", $1*100}' /proc/loadavg)
LOAD5=$(awk '{printf "%.0f%%", $2*100}' /proc/loadavg)
LOAD15=$(awk '{printf "%.0f%%", $3*100}' /proc/loadavg)

# PEERS online = handshake < 3 min ago | PEERS total = all in wg0 config
PEERS_TOTAL=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 | wc -l || echo 0)
PEERS_ONLINE=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 \
  | awk -v t="$(date +%s)" '$5>0 && (t-$5)<180 {c++} END{print c+0}' || echo 0)

# Collect aliases from .bashrc + shared_aliases.sh automatically
ALIASES=$(grep -h '^alias ' /root/.bashrc /root/Linux_Server_Public/scripts/shared_aliases.sh 2>/dev/null \
  | sed "s/alias //;s/=.*//" | sort -u | tr '\n' ' ')

echo -e "${C}${LINE}${X}"
printf "  ${C}\U0001f512  %-24s${X} ${W}%-22s${X} ${Y}RAM:${W}%s/%sMB${X}  ${Y}CPU:${W}%s%%${X}\n" \
  "$HN" "$IP" "$RAM_USED" "$RAM_TOTAL" "$CPU"
printf "  ${Y}AmneziaWG: ${G}%s online${X}${Y} / ${W}%s total peers${X}\n" "$PEERS_ONLINE" "$PEERS_TOTAL"
echo -e "${C}${LINE}${X}"
echo -e "  ${Y}ALIASES:${X} ${G}${ALIASES}${X}" | fold -s -w 80 | sed '2,$s/^/  /'
echo -e "${C}${LINE}${X}"
echo -e "  ${Y}Ubuntu 24${X} | up ${W}${UPTIME}${X} | load 1m/5m/15m: ${G}${LOAD1} ${LOAD5} ${LOAD15}${X}"
echo
