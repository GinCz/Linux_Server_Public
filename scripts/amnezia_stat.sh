#!/bin/bash
# Script:  amnezia_stat.sh
# Version: v2026-03-17
# Purpose: Amnezia VPN client traffic statistics — formatted table.
# Usage:   /opt/server_tools/scripts/amnezia_stat.sh
# Alias:   awgstat

clear

C="\033[1;36m"; Y="\033[1;33m"; R="\033[0m"

echo -e "${C}=== WG Stats v2026-03-17 ===${R}\n"

printf "${C}┌─────────────────────┬──────────────────────────────────────────┬──────────────┬──────────────┬──────────────┐${R}\n"
printf "${C}│ ${Y}%-19s ${C}│ ${Y}%-40s ${C}│ ${Y}%-12s ${C}│ ${Y}%-12s ${C}│ ${Y}%-12s ${C}│${R}\n" \
    "IP Address" "User Name" "Inbound(GB)" "Outbound(GB)" "Total(GB)"
printf "${C}├─────────────────────┼──────────────────────────────────────────┼──────────────┼──────────────┼──────────────┤${R}\n"

J=$(docker exec amnezia-awg cat /opt/amnezia/awg/clientsTable 2>/dev/null)

if docker exec amnezia-awg awg show awg0 dump >/dev/null 2>&1; then
    D="awg show awg0 dump"
else
    D="wg show wg0 dump"
fi

docker exec amnezia-awg $D | tail -n +2 | awk '{print $1, $6, $7}' | \
while read k r t; do
    b=$(echo "$J" | grep -B5 -A5 "$k")
    n=$(echo "$b" | grep '"clientName"' | sed 's/.*"clientName": "//;s/".*//' | head -1)
    ip=$(echo "$b" | grep '"allowedIps"' | sed 's/.*"allowedIps": "//;s/".*//;s|/32||' | head -1)
    [ -z "$n" ] || [ "$n" == "null" ] && n="Unknown"
    [ -z "$ip" ] && ip="N/A"
    rg=$(awk -v r="$r" 'BEGIN {printf "%.2f", r/1073741824}')
    tg=$(awk -v t="$t" 'BEGIN {printf "%.2f", t/1073741824}')
    tt=$(awk -v r="$r" -v t="$t" 'BEGIN {printf "%.2f", (r+t)/1073741824}')
    echo "$tt|$ip|$n|$rg|$tg"
done | sort -t'|' -k1 -rn | \
awk -F'|' -v c="$C" -v y="$Y" -v r="$R" '
{
    si += $4; so += $5; st += $1
    printf "%s│ %s%-19s %s│ %s%-40s %s│ %s%-12s %s│ %s%-12s %s│ %s%-12s %s│%s\n",
        c, r, $2, c, r, $3, c, r, $4, c, r, $5, c, r, $1, c, r
}
END {
    printf "%s├─────────────────────┼──────────────────────────────────────────┼──────────────┼──────────────┼──────────────┤%s\n", c, r
    printf "%s│ %s%-19s %s│ %s%-40s %s│ %s%-12.2f %s│ %s%-12.2f %s│ %s%-12.2f %s│%s\n",
        c, y, "TOTAL", c, y, "All Clients Combined", c, y, si, c, y, so, c, y, st, c, r
    printf "%s└─────────────────────┴──────────────────────────────────────────┴──────────────┴──────────────┴──────────────┘%s\n", c, r
}'
