#!/bin/bash
# = Rooted by VladiMIR | AI =
# v2026-04-07
# AmneziaWG statistics script — shows all peers with traffic + recent activity (15 min)
# Usage: bash amnezia_stat.sh

clear

C="\033[1;36m"
Y="\033[1;33m"
G="\033[1;32m"
R="\033[0m"

echo -e "${C}=== AmneziaWG Stats v2026-04-07 ===${R}\n"

# ── SECTION 1: Traffic table ─────────────────────────────────────────────────
printf "${C}┌─────────────────────┬──────────────────────────────────────────┬──────────────┬──────────────┬──────────────┐${R}\n"
printf "${C}│ ${Y}%-19s ${C}│ ${Y}%-40s ${C}│ ${Y}%-12s ${C}│ ${Y}%-12s ${C}│ ${Y}%-12s ${C}│${R}\n" \
  "IP Address" "User Name" "Inbound(GB)" "Outbound(GB)" "Total(GB)"
printf "${C}├─────────────────────┼──────────────────────────────────────────┼──────────────┼──────────────┼──────────────┤${R}\n"

J=$(docker exec amnezia-awg cat /opt/amnezia/awg/clientsTable 2>/dev/null)

# Detect awg or wg inside container
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
awk -F'|' -v c="$C" -v y="$Y" -v r="$R" '{
  si+=$4; so+=$5; st+=$1
  printf "%s│ %s%-19s %s│ %s%-40s %s│ %s%-12s %s│ %s%-12s %s│ %s%-12s %s│%s\n",
    c,r,$2,c,r,$3,c,r,$4,c,r,$5,c,r,$1,c,r
} END {
  printf "%s├─────────────────────┼──────────────────────────────────────────┼──────────────┼──────────────┼──────────────┤%s\n", c, r
  printf "%s│ %s%-19s %s│ %s%-40s %s│ %s%-12.2f %s│ %s%-12.2f %s│ %s%-12.2f %s│%s\n",
    c,y,"TOTAL",c,y,"All Clients Combined",c,y,si,c,y,so,c,y,st,c,r
  printf "%s└─────────────────────┴──────────────────────────────────────────┴──────────────┴──────────────┴──────────────┘%s\n", c, r
}'

# ── SECTION 2: Active in last 15 minutes ─────────────────────────────────────
echo -e "\n${Y}=== Active peers (last 15 minutes) ===${R}\n"

NOW=$(date +%s)
THRESH=900  # 15 minutes in seconds

J=$(docker exec amnezia-awg cat /opt/amnezia/awg/clientsTable 2>/dev/null)

if docker exec amnezia-awg awg show awg0 dump >/dev/null 2>&1; then
  D="awg show awg0 dump"
else
  D="wg show wg0 dump"
fi

FOUND=0

docker exec amnezia-awg $D | tail -n +2 | awk '{print $1, $4, $5, $6, $7}' | \
while read pubkey endpoint last_hs rx tx; do
  # last_hs = latest handshake unix timestamp (0 if never)
  if [ "$last_hs" -eq 0 ] 2>/dev/null; then continue; fi
  DIFF=$(( NOW - last_hs ))
  if [ "$DIFF" -le "$THRESH" ]; then
    b=$(echo "$J" | grep -B5 -A5 "$pubkey")
    n=$(echo "$b" | grep '"clientName"' | sed 's/.*"clientName": "//;s/".*//' | head -1)
    ip=$(echo "$b" | grep '"allowedIps"' | sed 's/.*"allowedIps": "//;s/".*//;s|/32||' | head -1)
    [ -z "$n" ] || [ "$n" == "null" ] && n="Unknown"
    [ -z "$ip" ] && ip="N/A"
    # Format handshake age
    if [ "$DIFF" -lt 60 ]; then
      AGE="${DIFF}s ago"
    elif [ "$DIFF" -lt 3600 ]; then
      AGE="$(( DIFF/60 ))m $(( DIFF%60 ))s ago"
    else
      AGE="$(( DIFF/3600 ))h $(( (DIFF%3600)/60 ))m ago"
    fi
    rg=$(awk -v r="$rx" 'BEGIN {printf "%.2f MB", r/1048576}')
    tg=$(awk -v t="$tx" 'BEGIN {printf "%.2f MB", t/1048576}')
    printf "${G}  %-20s %-35s %-20s  rx:%-14s tx:%s${R}\n" \
      "$ip" "$n" "$AGE" "$rg" "$tg"
    FOUND=1
  fi
done

[ "$FOUND" -eq 0 ] 2>/dev/null && echo -e "  ${R}No peers active in last 15 minutes.${R}"

echo ""
