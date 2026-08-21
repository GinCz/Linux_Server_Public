#!/bin/bash
# =============================================================================
# AmneziaWG Stats v2026-04-22
# Description : Display AmneziaWG VPN peer statistics with colors,
#               sorted by total traffic descending.
#               Shows all peers + active peers (last 15 min) separately.
#               Auto-detects container name (amnezia-awg, amnezia-awg2, etc).
#               Auto-installs jq if not present.
# Author      : VladiMIR (GinCz)
# GitHub      : https://github.com/GinCz/Linux_Server_Public
# Alias       : aw  (defined in scripts/shared_aliases.sh)
# Requires    : docker, jq (auto-installed if missing)
# Usage       : bash /root/Linux_Server_Public/VPN/amnezia_stat.sh
#               or simply: aw
# = Rooted by VladiMIR | AI =
# =============================================================================

clear

# --- Auto-install jq if missing ---
if ! command -v jq &>/dev/null; then
  echo "  [jq] not found — installing..."
  apt-get install -y jq --no-install-recommends -qq 2>/dev/null \
  || { wget -qO /usr/local/bin/jq \
         https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 \
       && chmod +x /usr/local/bin/jq; }
  if ! command -v jq &>/dev/null; then
    echo "  [jq] ERROR: failed to install jq. Please install manually: apt-get install jq"
    exit 1
  fi
  echo "  [jq] installed: $(jq --version)"
  clear
fi

# --- ANSI color codes ---
CY="\033[1;96m"
YL="\033[1;93m"
GN="\033[1;92m"
RD="\033[1;91m"
WH="\033[1;97m"
OR="\033[38;5;214m"
X="\033[0m"

HR="══════════════════════════════════════════════════════════════════════════════════════════════════════════"
SEP="──────────────────────────────────────────────────────────────────────────────────────────────────────────"

# --- Auto-detect AmneziaWG container name ---
CONTAINER=$(docker ps --format '{{.Names}}' 2>/dev/null | grep -Ei 'amnezia.?awg|awg.?amnezia|amneziawg' | head -1)
if [[ -z "$CONTAINER" ]]; then
  CONTAINER=$(docker ps --format '{{.Names}}' 2>/dev/null | grep -i 'awg' | head -1)
fi
if [[ -z "$CONTAINER" ]]; then
  echo -e "${RD}  ERROR: AmneziaWG container not found. Check: docker ps${X}"
  echo -e "${YL}  Running containers:${X}"
  docker ps --format '  {{.Names}}  ({{.Image}})'
  exit 1
fi

# --- Header block ---
echo -e "${YL}  ${HR}"
echo -e "   AmneziaWG Stats v2026-04-22  |  $(hostname)  |  Container: ${CONTAINER}  |  $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "  ${HR}${X}\n"

# --- Read peer table from AmneziaWG Docker container ---
TABLE=$(docker exec "$CONTAINER" cat /opt/amnezia/awg/clientsTable 2>/dev/null)
if [[ -z "$TABLE" ]] || [[ "$TABLE" == "[]" ]]; then
  echo -e "${RD}  ERROR: clientsTable is empty or not found."
  echo -e "  Container: $CONTAINER"
  echo -e "  Check: docker exec $CONTAINER ls /opt/amnezia/awg/${X}"
  exit 1
fi

# --- Column headers ---
printf "${CY}  %-15s  %-28s  %-20s  %-11s  %-11s  %-9s${X}\n" \
  "IP" "Name" "Last Handshake" "Inbound" "Outbound" "Total"
echo -e "${CY}  ${SEP}${X}"

# --- Extract each peer as pipe-delimited line: ip|name|handshake|rx|tx ---
echo "$TABLE" | jq -c '.[]' | while read -r o; do
  ip=$(echo "$o"   | jq -r '.userData.allowedIps // "N/A"' | sed 's|/32||')
  name=$(echo "$o" | jq -r '.userData.clientName // "Unknown"')
  hs=$(echo "$o"   | jq -r '.userData.latestHandshake // "never"')
  rx=$(echo "$o"   | jq -r '.userData.dataReceived // "-"')
  tx=$(echo "$o"   | jq -r '.userData.dataSent // "-"')
  printf '%s|%s|%s|%s|%s\n' "$ip" "$name" "$hs" "$rx" "$tx"
done | \

# --- PASS 1: sort all rows by total traffic (rx+tx) descending ---
awk -F'|' '
  function toGiB(s,a,v,u) {
    if (s=="-"||s=="") return 0
    split(s,a," "); v=a[1]+0; u=a[2]
    if (u=="GiB") return v
    if (u=="MiB") return v/1024
    if (u=="KiB") return v/1048576
    if (u=="B")   return v/1073741824
    return 0
  }
  { lines[NR]=$0; tots[NR]=toGiB($4)+toGiB($5) }
  END {
    n=NR
    for (i=1;i<=n;i++) for (j=i+1;j<=n;j++)
      if (tots[i]<tots[j]) {
        t=lines[i]; lines[i]=lines[j]; lines[j]=t
        t=tots[i];  tots[i]=tots[j];  tots[j]=t
      }
    for (i=1;i<=n;i++) print lines[i]
  }
' | \

# --- PASS 2: colorize rows and print with TOTAL footer ---
awk -F'|' \
  -v CY="$CY" -v YL="$YL" -v GN="$GN" -v RD="$RD" \
  -v WH="$WH" -v OR="$OR" -v X="$X" \
  -v SEP="$SEP" '
  function toGiB(s,a,v,u) {
    if (s=="-"||s=="") return 0
    split(s,a," "); v=a[1]+0; u=a[2]
    if (u=="GiB") return v
    if (u=="MiB") return v/1024
    if (u=="KiB") return v/1048576
    if (u=="B")   return v/1073741824
    return 0
  }
  function fmt(g) {
    if (g==0)       return "-"
    if (g>=1)       return sprintf("%.2f GiB",g)
    if (g*1024>=1)  return sprintf("%.2f MiB",g*1024)
    return sprintf("%.2f KiB",g*1024*1024)
  }
  function fmtT(g) {
    if (g==0)       return "-"
    if (g>=1)       return sprintf("%.1f GiB",g)
    if (g*1024>=1)  return sprintf("%.1f MiB",g*1024)
    return sprintf("%.1f KiB",g*1024*1024)
  }
  {
    ip=$1; name=substr($2,1,28); hs=substr($3,1,20); rx=$4; tx=$5
    rxg=toGiB(rx); txg=toGiB(tx); tot=rxg+txg
    hsc=OR
    if (hs~/^[0-9]+s ago$/||
        hs~/^[0-9]+m, [0-9]+s ago$/||
        hs~/^[0-9]+m ago$/) hsc=GN
    if (hs=="never"||hs=="")  hsc=RD
    ipc=(ip=="N/A") ? RD : WH
    printf "  %s%-15s%s  %s%-28s%s  %s%-20s%s  %s%-11s%s  %s%-11s%s  %s%-9s%s\n",
      ipc,ip,X, YL,name,X, hsc,hs,X,
      GN,fmt(rxg),X, CY,fmt(txg),X, OR,fmtT(tot),X
    trx+=rxg; ttx+=txg
  }
  END {
    print CY "  " SEP X
    printf "  %s%-15s  %-28s  %-20s%s  %s%-11s%s  %s%-11s%s  %s%-9s%s\n",
      YL,"TOTAL","All Clients","",X,
      GN,sprintf("%.2f GiB",trx),X,
      CY,sprintf("%.2f GiB",ttx),X,
      OR,sprintf("%.1f GiB",trx+ttx),X
  }
'

# --- Active peers: only those seen within last 15 minutes ---
echo -e "\n${YL}  Active peers — last 15 min:${X}\n"
echo "$TABLE" | jq -c '.[]' | while read -r o; do
  hs=$(echo "$o" | jq -r '.userData.latestHandshake // ""')
  [[ -z "$hs" || "$hs" == "never" ]] && continue

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
