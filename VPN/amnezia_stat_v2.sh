#!/bin/bash
# amnezia_stat_v2.sh — AmneziaWG Stats UNIVERSAL (v1 + v2)
# Version : v2026-04-22
# Auto-detects container: amnezia-awg or amnezia-awg2
# Data source: awg show (real-time, not clientsTable)
# Author  : VladiMIR (GinCz)
# GitHub  : https://github.com/GinCz/Linux_Server_Public
# = Rooted by VladiMIR | AI =
command -v jq &>/dev/null || { apt-get install -y jq --no-install-recommends -qq 2>/dev/null || { wget -qO /usr/local/bin/jq https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 && chmod +x /usr/local/bin/jq; }; }
clear
CY="\033[1;96m";YL="\033[1;93m";GN="\033[1;92m";RD="\033[1;91m";WH="\033[1;97m";OR="\033[38;5;214m";X="\033[0m"
HR="==========================================================================================================="
CONTAINER=$(docker ps --format '{{.Names}}' 2>/dev/null | grep -Ei 'amnezia.?awg|awg.?amnezia|amneziawg' | head -1)
[[ -z "$CONTAINER" ]] && CONTAINER=$(docker ps --format '{{.Names}}' 2>/dev/null | grep -i 'awg' | head -1)
[[ -z "$CONTAINER" ]] && echo -e "${RD}  ERROR: AmneziaWG container not found.\n  Running: $(docker ps --format '{{.Names}}' | tr '\n' ' ')${X}" && exit 1
echo -e "${YL}  ${HR}\n   AmneziaWG Stats v2026-04-22 (universal)  |  $(hostname)  |  Container: ${CONTAINER}  |  $(date '+%Y-%m-%d %H:%M:%S')\n  ${HR}${X}\n"
TABLE=$(docker exec "$CONTAINER" cat /opt/amnezia/awg/clientsTable 2>/dev/null)
[[ -z "$TABLE" ]] && echo -e "${RD}  ERROR: clientsTable empty.${X}" && exit 1
declare -A IP2NAME
while IFS= read -r o; do
  ip=$(echo "$o" | jq -r '.userData.allowedIps // ""' | sed 's|/32||')
  name=$(echo "$o" | jq -r '.userData.clientName // "Unknown"')
  [[ -n "$ip" ]] && IP2NAME["$ip"]="$name"
done < <(echo "$TABLE" | jq -c '.[]')
AWG=$(docker exec "$CONTAINER" awg show 2>/dev/null)
[[ -z "$AWG" ]] && AWG=$(docker exec "$CONTAINER" wg show 2>/dev/null)
echo "$AWG" | awk '/^peer:/{if(ip!="")print ip"|"hs"|"rx"|"tx;ip="";hs="never";rx="-";tx="-"}/allowed ips:/{ip=$3;sub(/\/32/,"",ip)}/latest handshake:/{$1="";$2="";hs=substr($0,3)}/transfer:/{rx=$2" "$3;gsub(/,/,"",rx);tx=$5" "$6}END{if(ip!="")print ip"|"hs"|"rx"|"tx}' | while IFS='|' read -r ip hs rx tx; do name="${IP2NAME[$ip]:-Unknown}"; printf '%s|%s|%s|%s|%s\n' "$ip" "$name" "$hs" "$rx" "$tx"; done | awk -F'|' 'function toGiB(s,a,v,u){if(s=="-"||s=="")return 0;split(s,a," ");v=a[1]+0;u=a[2];if(u~/GiB/)return v;if(u~/MiB/)return v/1024;if(u~/KiB/)return v/1048576;if(u~/^B/)return v/1073741824;return 0}{lines[NR]=$0;tots[NR]=toGiB($4)+toGiB($5)}END{n=NR;for(i=1;i<=n;i++)for(j=i+1;j<=n;j++)if(tots[i]<tots[j]){t=lines[i];lines[i]=lines[j];lines[j]=t;t=tots[i];tots[i]=tots[j];tots[j]=t};for(i=1;i<=n;i++)print lines[i]}' | awk -F'|' -v CY="$CY" -v YL="$YL" -v GN="$GN" -v RD="$RD" -v WH="$WH" -v OR="$OR" -v X="$X" -v HR="$HR" 'function toGiB(s,a,v,u){if(s=="-"||s=="")return 0;split(s,a," ");v=a[1]+0;u=a[2];if(u~/GiB/)return v;if(u~/MiB/)return v/1024;if(u~/KiB/)return v/1048576;if(u~/^B/)return v/1073741824;return 0}function fmt(g){if(g==0)return "-";if(g>=1)return sprintf("%.2f GiB",g);if(g*1024>=1)return sprintf("%.2f MiB",g*1024);return sprintf("%.2f KiB",g*1024*1024)}function fmtT(g){if(g==0)return "-";if(g>=1)return sprintf("%.1f GiB",g);if(g*1024>=1)return sprintf("%.1f MiB",g*1024);return sprintf("%.1f KiB",g*1024*1024)}BEGIN{printf CY"  %-15s  %-28s  %-32s  %-12s  %-12s  %-9s"X"\n","IP","Name","Last Handshake","Inbound","Outbound","Total";print CY"  "HR X}{ip=$1;name=substr($2,1,28);hs=$3;rx=$4;tx=$5;rxg=toGiB(rx);txg=toGiB(tx);hsc=OR;split(hs,a," ");if(a[2]~/^second/||(a[2]~/^minute/&&a[1]+0<15))hsc=GN;if(hs=="never"||hs=="")hsc=RD;printf "  "WH"%-15s"X"  "YL"%-28s"X"  "hsc"%-32s"X"  "GN"%-12s"X"  "CY"%-12s"X"  "OR"%-9s"X"\n",ip,name,hs,fmt(rxg),fmt(txg),fmtT(rxg+txg);trx+=rxg;ttx+=txg}END{print CY"  "HR X;printf "  "YL"%-15s  %-28s  %-32s"X"  "GN"%-12s"X"  "CY"%-12s"X"  "OR"%-9s"X"\n","TOTAL","All Clients","",sprintf("%.2f GiB",trx),sprintf("%.2f GiB",ttx),sprintf("%.1f GiB",trx+ttx)}'
echo -e "\n${YL}  Active peers -- last 15 min:${X}\n"
FOUND=0
while IFS='|' read -r ip hs rx tx; do
  mins=9999
  if echo "$hs" | grep -qE '^[0-9]+ seconds? ago$'; then mins=0
  elif echo "$hs" | grep -qE '^[0-9]+ minutes?'; then mins=$(echo "$hs" | grep -oE '^[0-9]+'); fi
  [[ $mins -gt 14 ]] && continue
  name="${IP2NAME[$ip]:-Unknown}"; FOUND=1
  printf "  ${WH}%-15s${X}  ${YL}%-28s${X}  ${GN}%-32s${X}  ${CY}in: %-12s${X}  ${OR}out: %s${X}\n" "$ip" "${name:0:28}" "$hs" "$rx" "$tx"
done < <(echo "$AWG" | awk '/^peer:/{if(ip!="")print ip"|"hs"|"rx"|"tx;ip="";hs="never";rx="-";tx="-"}/allowed ips:/{ip=$3;sub(/\/32/,"",ip)}/latest handshake:/{$1="";$2="";hs=substr($0,3)}/transfer:/{rx=$2" "$3;gsub(/,/,"",rx);tx=$5" "$6}END{if(ip!="")print ip"|"hs"|"rx"|"tx}')
[[ $FOUND -eq 0 ]] && echo -e "  ${RD}No peers active in last 15 minutes.${X}"
echo ""
