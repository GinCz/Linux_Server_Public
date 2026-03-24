#!/bin/bash
clear
# amnezia_stat.sh — AmneziaWG / WireGuard clients statistics
# Version: v2026-03-24
# Author: Ing. VladiMIR Bulantsev
# Universal: works on 222, 109, VPN servers
# Usage: bash /root/Linux_Server_Public/scripts/amnezia_stat.sh

C="\033[1;36m"; Y="\033[1;33m"; R="\033[0m"

echo -e "${C}=== WG Stats v2026-03-24 ===${R}\n"
echo -e "${C}┌─────────────────────┬──────────────────────────────────────────┬──────────────┬──────────────┬──────────────┐${R}"
echo -e "${C}│ ${Y}IP Address          ${C}│ ${Y}User Name                                ${C}│ ${Y}Inbound(GB)  ${C}│ ${Y}Outbound(GB) ${C}│ ${Y}Total(GB)    ${C}│${R}"
echo -e "${C}├─────────────────────┼──────────────────────────────────────────┼──────────────┼──────────────┼──────────────┤${R}"

J=$(docker exec amnezia-awg cat /opt/amnezia/awg/clientsTable 2>/dev/null)

if docker exec amnezia-awg awg show awg0 dump >/dev/null 2>&1; then
    D="awg show awg0 dump"
else
    D="wg show wg0 dump"
fi

docker exec amnezia-awg $D | tail -n +2 | awk '{print $1, $6, $7}' | while read k r t; do
    b=$(echo "$J" | grep -B5 -A5 "$k")
    n=$(echo "$b" | grep '"clientName"' | sed 's/.*"clientName": "//;s/".*//' | head -1)
    ip=$(echo "$b" | grep '"allowedIps"' | sed 's/.*"allowedIps": "//;s/".*//;s|/32||' | head -1)
    [ -z "$n" ] || [ "$n" = "null" ] && n="Unknown"
    [ -z "$ip" ] && ip="N/A"
    rg=$(awk -v r="$r" 'BEGIN {printf "%.2f", r/1073741824}')
    tg=$(awk -v t="$t" 'BEGIN {printf "%.2f", t/1073741824}')
    tt=$(awk -v r="$r" -v t="$t" 'BEGIN {printf "%.2f", (r+t)/1073741824}')
    echo "$tt|$ip|$n|$rg|$tg"
done | sort -t'|' -k1 -rn | while IFS='|' read tt ip n rg tg; do
    printf "${C}│${R} %-19s ${C}│${R} %-40s ${C}│${R} %-12s ${C}│${R} %-12s ${C}│${R} %-12s ${C}│${R}\n" \
        "$ip" "$n" "$rg" "$tg" "$tt"
done

echo -e "${C}├─────────────────────┼──────────────────────────────────────────┼──────────────┼──────────────┼──────────────┤${R}"

TOTALS=$(docker exec amnezia-awg $D | tail -n +2 | awk '{r+=$6; t+=$7} END {printf "%.2f %.2f %.2f", r/1073741824, t/1073741824, (r+t)/1073741824}')
TIN=$(echo $TOTALS | awk '{print $1}')
TOUT=$(echo $TOTALS | awk '{print $2}')
TTOT=$(echo $TOTALS | awk '{print $3}')

printf "${C}│${Y} %-19s ${C}│${Y} %-40s ${C}│${Y} %-12s ${C}│${Y} %-12s ${C}│${Y} %-12s ${C}│${R}\n" \
    "TOTAL" "All Clients Combined" "$TIN" "$TOUT" "$TTOT"
echo -e "${C}└─────────────────────┴──────────────────────────────────────────┴──────────────┴──────────────┴──────────────┘${R}"
