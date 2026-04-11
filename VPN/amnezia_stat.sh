#!/bin/bash
# = Rooted by VladiMIR | AI =
# v2026-04-11
# AmneziaWG statistics — traffic table + active peers last 15 min
# Usage: bash /root/amnezia_stat.sh

clear

C="\033[1;36m"
Y="\033[1;33m"
G="\033[1;32m"
R="\033[0m"

echo -e "${C}=== AmneziaWG Stats v2026-04-11 ===${R}\n"

# ── Get clients table and detect wg/awg ──────────────────────────────────────
J=$(docker exec amnezia-awg cat /opt/amnezia/awg/clientsTable 2>/dev/null)

if docker exec amnezia-awg awg show awg0 dump >/dev/null 2>&1; then
  D="awg0"
else
  D="wg0"
fi

# wg show <iface> dump columns:
# 1=pubkey 2=preshared 3=endpoint 4=allowed_ips 5=last_handshake 6=rx 7=tx 8=keepalive

# ── SECTION 1: Traffic table ──────────────────────────────────────────────────
printf "${C}┌─────────────────────┬──────────────────────────────────────────┬──────────────┬──────────────┬──────────────┐${R}\n"
printf "${C}│ ${Y}%-19s ${C}│ ${Y}%-40s ${C}│ ${Y}%-12s ${C}│ ${Y}%-12s ${C}│ ${Y}%-12s ${C}│${R}\n" \
  "IP Address" "User Name" "Inbound(GB)" "Outbound(GB)" "Total(GB)"
printf "${C}├─────────────────────┼──────────────────────────────────────────┼──────────────┼──────────────┼──────────────┤${R}\n"

docker exec amnezia-awg awg show "$D" dump | tail -n +2 | awk '{print $1, $6, $7}' | \
while read k r t; do
  b=$(echo "$J" | grep -B5 -A5 "$k")
  n=$(echo "$b" | grep '"clientName"' | sed 's/.*"clientName": "//;s/".*//' | head -1)
  ip=$(echo "$b" | grep '"allowedIps"' | sed 's/.*"allowedIps": "//;s/".*//;s|/32||' | head -1)
  [ -z "$n" ] || [ "$n" = "null" ] && n="Unknown"
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

# ── SECTION 2: Active peers in last 15 minutes ───────────────────────────────
echo -e "\n${Y}=== Active peers (last 15 minutes) ===${R}\n"

NOW=$(date +%s)
THRESH=900
TMPFILE=$(mktemp)

docker exec amnezia-awg awg show "$D" dump | tail -n +2 | \
while read pubkey preshared endpoint allowed_ips last_hs rx tx keepalive; do
  # skip peers that never connected
  [ "$last_hs" = "0" ] && continue
  DIFF=$(( NOW - last_hs ))
  [ "$DIFF" -gt "$THRESH" ] && continue

  b=$(echo "$J" | grep -B5 -A5 "$pubkey")
  n=$(echo "$b" | grep '"clientName"' | sed 's/.*"clientName": "//;s/".*//' | head -1)
  ip=$(echo "$b" | grep '"allowedIps"' | sed 's/.*"allowedIps": "//;s/".*//;s|/32||' | head -1)
  [ -z "$n" ] || [ "$n" = "null" ] && n="Unknown"
  [ -z "$ip" ] && ip="N/A"

  if [ "$DIFF" -lt 60 ]; then
    AGE="${DIFF}s ago"
  elif [ "$DIFF" -lt 3600 ]; then
    AGE="$(( DIFF/60 ))m $(( DIFF%60 ))s ago"
  else
    AGE="$(( DIFF/3600 ))h $(( (DIFF%3600)/60 ))m ago"
  fi

  rg=$(awk -v r="$rx" 'BEGIN {printf "%.1f MB", r/1048576}')
  tg=$(awk -v t="$tx" 'BEGIN {printf "%.1f MB", t/1048576}')

  echo "ACTIVE|$ip|$n|$AGE|$rg|$tg" >> "$TMPFILE"
done

if [ -s "$TMPFILE" ]; then
  while IFS='|' read -r _ ip n age rg tg; do
    printf "${G}  %-20s %-35s %-18s  rx:%-12s tx:%s${R}\n" "$ip" "$n" "$age" "$rg" "$tg"
  done < "$TMPFILE"
else
  echo -e "  ${Y}No peers active in last 15 minutes.${R}"
fi

rm -f "$TMPFILE"
echo ""
