#!/bin/bash
clear
CY="\033[1;96m"; YL="\033[1;93m"; GN="\033[1;92m"; RD="\033[1;91m"
WH="\033[1;97m"; OR="\033[38;5;214m"; X="\033[0m"

HR="════════════════════════════════════════════════════════════════════════"
echo -e "${YL}  ${HR}${X}"
echo -e "${YL}   AmneziaWG Stats v2026-04-13i  |  $(hostname)  |  $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "${YL}  ${HR}${X}\n"

TABLE=$(docker exec amnezia-awg cat /opt/amnezia/awg/clientsTable 2>/dev/null)

printf "${CY}  %-15s  %-28s  %-24s  %-11s  %-11s  %-11s${X}\n" \
  "IP" "Name" "Last Handshake" "Inbound" "Outbound" "Total"
printf "${CY}  %-15s  %-28s  %-24s  %-11s  %-11s  %-11s${X}\n" \
  "───────────────" "────────────────────────────" "────────────────────────" "───────────" "───────────" "───────────"

echo "$TABLE" | jq -c '.[]' | while read -r obj; do
    ip=$(echo "$obj"   | jq -r '.userData.allowedIps // "N/A"' | sed 's|/32||')
    name=$(echo "$obj" | jq -r '.userData.clientName // "Unknown"')
    hs=$(echo "$obj"   | jq -r '.userData.latestHandshake // "never"')
    rx=$(echo "$obj"   | jq -r '.userData.dataReceived // "-"')
    tx=$(echo "$obj"   | jq -r '.userData.dataSent // "-"')
    printf '%s|%s|%s|%s|%s\n' "$ip" "$name" "$hs" "$rx" "$tx"
done | sort -t'|' -k1V | \
awk -F'|' -v CY="$CY" -v YL="$YL" -v GN="$GN" -v RD="$RD" -v WH="$WH" -v OR="$OR" -v X="$X" '
function toGiB(s,   a,v,u) {
    if (s=="-"||s=="") return 0
    split(s,a," "); v=a[1]+0; u=a[2]
    if (u=="GiB") return v
    if (u=="MiB") return v/1024
    if (u=="KiB") return v/1048576
    if (u=="B")   return v/1073741824
    return 0
}
function fmt(g) {
    if (g==0) return "-"
    if (g>=1) return sprintf("%.2f GiB",g)
    if (g*1024>=1) return sprintf("%.2f MiB",g*1024)
    return sprintf("%.2f KiB",g*1024*1024)
}
{
    ip=$1; name=substr($2,1,28); hs=substr($3,1,24); rx=$4; tx=$5
    rxg=toGiB(rx); txg=toGiB(tx); tot=rxg+txg
    hsc=OR
    if (hs ~ /^[0-9]+s ago$/ || hs ~ /^[0-9]+m, [0-9]+s ago$/ || hs ~ /^[0-9]+m ago$/) hsc=GN
    if (hs=="never" || hs=="") hsc=RD
    ipc=(ip=="N/A") ? RD : WH
    printf "  %s%-15s%s  %s%-28s%s  %s%-24s%s  %s%-11s%s  %s%-11s%s  %s%-11s%s\n", \
      ipc,ip,X, YL,name,X, hsc,hs,X, GN,fmt(rxg),X, CY,fmt(txg),X, OR,fmt(tot),X
    trx+=rxg; ttx+=txg
}
END {
    printf "%s  %-15s  %-28s  %-24s  %-11s  %-11s  %-11s%s\n", CY,\
      "───────────────","────────────────────────────","────────────────────────","───────────","───────────","───────────",X
    printf "  %s%-15s  %-28s  %-24s%s  %s%-11s%s  %s%-11s%s  %s%-11s%s\n",\
      YL,"TOTAL","All Clients","",X,\
      GN,sprintf("%.2f GiB",trx),X,\
      CY,sprintf("%.2f GiB",ttx),X,\
      OR,sprintf("%.2f GiB",trx+ttx),X
}'

# АКТИВНЫЕ ПИРЫ — из clientsTable
echo -e "\n${YL}  Active peers — last 15 min:${X}\n"
echo "$TABLE" | jq -c '.[]' | while read -r obj; do
    hs=$(echo "$obj" | jq -r '.userData.latestHandshake // ""')
    [[ -z "$hs" || "$hs" == "never" ]] && continue
    secs=9999
    if echo "$hs" | grep -qE "^[0-9]+s ago$"; then
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
    name=$(echo "$obj" | jq -r '.userData.clientName // "Unknown"')
    cip=$(echo "$obj"  | jq -r '.userData.allowedIps // "N/A"' | sed 's|/32||')
    rx=$(echo "$obj"   | jq -r '.userData.dataReceived // "-"')
    tx=$(echo "$obj"   | jq -r '.userData.dataSent // "-"')
    printf "  ${WH}%-15s${X}  ${YL}%-28s${X}  ${GN}%-16s${X}  ${CY}in: %-12s${X}  ${OR}out: %s${X}\n" \
      "$cip" "${name:0:28}" "$hs" "$rx" "$tx"
done
echo ""
