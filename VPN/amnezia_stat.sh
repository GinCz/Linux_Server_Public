#!/bin/bash
# =============================================================================
# AmneziaWG Stats v2026-04-13k
# Description : Display AmneziaWG VPN peer statistics with colors
# Author      : VladiMIR (GinCz)
# GitHub      : https://github.com/GinCz/Linux_Server_Public
# Requires    : docker, jq
# Usage       : bash /root/amnezia_stat.sh
# =============================================================================

clear

# --- Color definitions ---
CY="\033[1;96m"   # Cyan
YL="\033[1;93m"   # Yellow
GN="\033[1;92m"   # Green
RD="\033[1;91m"   # Red
WH="\033[1;97m"   # White
OR="\033[38;5;214m" # Orange
X="\033[0m"       # Reset

# --- Header ---
HR="════════════════════════════════════════════════════════════════════════"
echo -e "${YL}  ${HR}"
echo -e "   AmneziaWG Stats v2026-04-13k  |  $(hostname)  |  $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "  ${HR}${X}\n"

# --- Read clientsTable from Docker container ---
TABLE=$(docker exec amnezia-awg cat /opt/amnezia/awg/clientsTable 2>/dev/null)
[[ -z "$TABLE" ]] && echo -e "${RD}  ERROR: clientsTable empty. Check: docker ps | grep amnezia${X}" && exit 1

# --- Table header ---
printf "${CY}  %-15s  %-28s  %-20s  %-11s  %-11s  %-9s${X}\n" \
  "IP" "Name" "Last Handshake" "Inbound" "Outbound" "Total"
echo -e "${CY}  ───────────────────────────────────────────────────────────────────────────────────────${X}"

# --- Extract peer data and sort by Total descending ---
echo "$TABLE" | jq -c '.[]' | while read -r o; do
  ip=$(echo "$o"   | jq -r '.userData.allowedIps // "N/A"' | sed 's|/32||')
  name=$(echo "$o" | jq -r '.userData.clientName // "Unknown"')
  hs=$(echo "$o"   | jq -r '.userData.latestHandshake // "never"')
  rx=$(echo "$o"   | jq -r '.userData.dataReceived // "-"')
  tx=$(echo "$o"   | jq -r '.userData.dataSent // "-"')
  printf '%s|%s|%s|%s|%s\n' "$ip" "$name" "$hs" "$rx" "$tx"
done | awk -F'|' '
  # Convert any size string to GiB
  function toGiB(s, a,v,u) {
    if (s=="-" || s=="") return 0
    split(s,a," "); v=a[1]+0; u=a[2]
    if (u=="GiB") return v
    if (u=="MiB") return v/1024
    if (u=="KiB") return v/1048576
    if (u=="B")   return v/1073741824
    return 0
  }
  # Collect rows and sort by total desc
  { lines[NR]=$0; tots[NR]=toGiB($4)+toGiB($5) }
  END {
    n=NR
    for(i=1;i<=n;i++) for(j=i+1;j<=n;j++)
      if(tots[i]<tots[j]) {
        t=lines[i]; lines[i]=lines[j]; lines[j]=t
        t=tots[i];  tots[i]=tots[j];  tots[j]=t
      }
    for(i=1;i<=n;i++) print lines[i]
  }
' | awk -F'|' \
    -v CY="$CY" -v YL="$YL" -v GN="$GN" -v RD="$RD" \
    -v WH="$WH" -v OR="$OR" -v X="$X" '
  function toGiB(s, a,v,u) {
    if (s=="-" || s=="") return 0
    split(s,a," "); v=a[1]+0; u=a[2]
    if (u=="GiB") return v
    if (u=="MiB") return v/1024
    if (u=="KiB") return v/1048576
    if (u=="B")   return v/1073741824
    return 0
  }
  # Format size: 2 decimals for inbound/outbound
  function fmt(g) {
    if (g==0)      return "-"
    if (g>=1)      return sprintf("%.2f GiB", g)
    if (g*1024>=1) return sprintf("%.2f MiB", g*1024)
    return sprintf("%.2f KiB", g*1024*1024)
  }
  # Format size: 1 decimal for Total column
  function fmtT(g) {
    if (g==0)      return "-"
    if (g>=1)      return sprintf("%.1f GiB", g)
    if (g*1024>=1) return sprintf("%.1f MiB", g*1024)
    return sprintf("%.1f KiB",  g*1024*1024)
  }
  {
    ip=$1; name=substr($2,1,28); hs=substr($3,1,20); rx=$4; tx=$5
    rxg=toGiB(rx); txg=toGiB(tx); tot=rxg+txg
    # Handshake color: green=active, orange=old, red=never
    hsc=OR
    if (hs ~ /^[0-9]+s ago$/ || hs ~ /^[0-9]+m, [0-9]+s ago$/ || hs ~ /^[0-9]+m ago$/) hsc=GN
    if (hs=="never" || hs=="") hsc=RD
    ipc=(ip=="N/A") ? RD : WH
    printf "  %s%-15s%s  %s%-28s%s  %s%-20s%s  %s%-11s%s  %s%-11s%s  %s%-9s%s\n",
      ipc,ip,X, YL,name,X, hsc,hs,X,
      GN,fmt(rxg),X, CY,fmt(txg),X, OR,fmtT(tot),X
    trx+=rxg; ttx+=txg
  }
  END {
    print "\033[1;96m  ───────────────────────────────────────────────────────────────────────────────────────\033[0m"
    printf "  %s%-15s  %-28s  %-20s%s  %s%-11s%s  %s%-11s%s  %s%-9s%s\n",
      YL,"TOTAL","All Clients","",X,
      GN,sprintf("%.2f GiB",trx),X,
      CY,sprintf("%.2f GiB",ttx),X,
      OR,sprintf("%.1f GiB",trx+ttx),X
  }
'

# --- Active peers in last 15 minutes ---
echo -e "\n${YL}  Active peers — last 15 min:${X}\n"
echo "$TABLE" | jq -c '.[]' | while read -r o; do
  hs=$(echo "$o" | jq -r '.userData.latestHandshake // ""')
  [[ -z "$hs" || "$hs" == "never" ]] && continue
  # Parse handshake string to seconds
  secs=9999
  if   echo "$hs" | grep -qE "^[0-9]+s ago$"; then
    secs=$(echo "$hs" | grep -oE "^[0-9]+")
  elif echo "$hs" | grep -qE "^[0-9]+m, [0-9]+s ago$"; then
    m=$(echo "$hs" | grep -oE "^[0-9]+")
    s=$(echo "$hs" | grep -oE "[0-9]+s" | grep -oE "[0-9]+")
    secs=$((m*60+s))
  elif echo "$hs" | grep -qE "^[0-9]+m ago$"; then
    m=$(echo "$hs" | grep -oE "^[0-9]+")
    secs=$((m*60))
  fi
  [[ $secs -gt 900 ]] && continue
  name=$(echo "$o" | jq -r '.userData.clientName // "Unknown"')
  cip=$(echo "$o"  | jq -r '.userData.allowedIps // "N/A"' | sed 's|/32||')
  rx=$(echo "$o"   | jq -r '.userData.dataReceived // "-"')
  tx=$(echo "$o"   | jq -r '.userData.dataSent // "-"')
  printf "  ${WH}%-15s${X}  ${YL}%-28s${X}  ${GN}%-16s${X}  ${CY}in: %-12s${X}  ${OR}out: %s${X}\n" \
    "$cip" "${name:0:28}" "$hs" "$rx" "$tx"
done
echo ""
