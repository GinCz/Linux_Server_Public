#!/bin/bash
# amnezia_stat.sh — AmneziaWG2 Stats (awg show + clientsTable names)
# Version : v2026-04-18a
# = Rooted by VladiMIR | AI =

command -v jq &>/dev/null || { apt-get install -y jq --no-install-recommends -qq 2>/dev/null || { wget -qO /usr/local/bin/jq https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 && chmod +x /usr/local/bin/jq; }; }

clear

CY="\033[1;96m"; YL="\033[1;93m"; GN="\033[1;92m"; RD="\033[1;91m"; WH="\033[1;97m"; OR="\033[38;5;214m"; X="\033[0m"
HR="==========================================================================================================="

echo -e "${YL}  ${HR}\n   AmneziaWG Stats v2026-04-18a  |  $(hostname)  |  $(date '+%Y-%m-%d %H:%M:%S')\n  ${HR}${X}\n"

# --- Get names from clientsTable (ip -> name mapping) ---
TABLE=$(docker exec amnezia-awg2 cat /opt/amnezia/awg/clientsTable 2>/dev/null)
[[ -z "$TABLE" ]] && echo -e "${RD}  ERROR: clientsTable empty. Check: docker ps | grep amnezia${X}" && exit 1

# Build ip->name map: "10.8.1.2=Vlad_Honor_VPN"
NAMEMAP=$(echo "$TABLE" | jq -r '.[] | (.userData.allowedIps | gsub("/32";"")) + "=" + .userData.clientName')

# --- Get real-time stats from awg show ---
AWG_OUT=$(docker exec amnezia-awg2 awg show 2>/dev/null)
[[ -z "$AWG_OUT" ]] && echo -e "${RD}  ERROR: awg show failed. Check container.${X}" && exit 1

# Parse awg show into lines: ip|hs_raw|rx|tx
PEERS=$(echo "$AWG_OUT" | awk '
/^peer:/        { if(ip!="") printf "%s|%s|%s|%s\n",ip,hs,rx,tx; ip=""; hs="never"; rx="0 B"; tx="0 B" }
/allowed ips:/  { match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip=substr($0,RSTART,RLENGTH) }
/latest handshake:/ { sub(/.*latest handshake: /,""); hs=$0 }
/transfer:/     {
    match($0,/[0-9.]+ [KMGiB]+ received/); rx_raw=substr($0,RSTART,RLENGTH); sub(/ received/,"",rx_raw)
    match($0,/[0-9.]+ [KMGiB]+ sent/);    tx_raw=substr($0,RSTART,RLENGTH); sub(/ sent/,"",tx_raw)
    rx=rx_raw; tx=tx_raw
}
END { if(ip!="") printf "%s|%s|%s|%s\n",ip,hs,rx,tx }
')

[[ -z "$PEERS" ]] && echo -e "${RD}  ERROR: No peers found in awg show.${X}" && exit 1

# --- Format handshake: "3 hours, 29 minutes, 12 seconds ago" -> "3h, 29m ago" ---
fmt_hs() {
    local hs="$1"
    [[ "$hs" == "never" || -z "$hs" ]] && echo "never" && return
    local h=0 m=0 s=0
    [[ "$hs" =~ ([0-9]+)\ hour ]]   && h=${BASH_REMATCH[1]}
    [[ "$hs" =~ ([0-9]+)\ minute ]] && m=${BASH_REMATCH[1]}
    [[ "$hs" =~ ([0-9]+)\ second ]] && s=${BASH_REMATCH[1]}
    if   [[ $h -gt 0 ]]; then echo "${h}h, ${m}m ago"
    elif [[ $m -gt 0 ]]; then echo "${m}m, ${s}s ago"
    else echo "${s}s ago"
    fi
}

# --- Handshake to seconds ---
hs_to_secs() {
    local hs="$1"
    [[ "$hs" == "never" || -z "$hs" ]] && echo 999999 && return
    local h=0 m=0 s=0
    [[ "$hs" =~ ([0-9]+)\ hour ]]   && h=${BASH_REMATCH[1]}
    [[ "$hs" =~ ([0-9]+)\ minute ]] && m=${BASH_REMATCH[1]}
    [[ "$hs" =~ ([0-9]+)\ second ]] && s=${BASH_REMATCH[1]}
    echo $(( h*3600 + m*60 + s ))
}

# --- Print table header ---
printf "${CY}  %-15s  %-28s  %-20s  %-14s  %-14s  %-11s${X}\n" "IP" "Name" "Last Handshake" "Inbound" "Outbound" "Total"
echo -e "${CY}  ${HR}${X}"

# --- Build formatted peer lines for awk (sort by total traffic desc) ---
while IFS='|' read -r ip hs_raw rx tx; do
    [[ -z "$ip" ]] && continue
    name=$(echo "$NAMEMAP" | grep "^${ip}=" | cut -d= -f2-)
    [[ -z "$name" ]] && name="Unknown"
    hs_short=$(fmt_hs "$hs_raw")
    printf '%s|%s|%s|%s|%s\n' "$ip" "$name" "$hs_short" "$rx" "$tx"
done < <(echo "$PEERS") | awk -F'|' \
    -v CY="$CY" -v YL="$YL" -v GN="$GN" -v RD="$RD" -v WH="$WH" -v OR="$OR" -v X="$X" '
function toGiB(s,  a,v,u){if(s=="-"||s==""||s=="0 B")return 0;split(s,a," ");v=a[1]+0;u=a[2];if(u=="GiB")return v;if(u=="MiB")return v/1024;if(u=="KiB")return v/1048576;if(u=="B")return v/1073741824;return 0}
function fmt(g) {if(g==0)return "-";if(g>=1)return sprintf("%.2f GiB",g);if(g*1024>=1)return sprintf("%.2f MiB",g*1024);return sprintf("%.2f KiB",g*1024*1024)}
function fmtT(g){if(g==0)return "-";if(g>=1)return sprintf("%.1f GiB",g);if(g*1024>=1)return sprintf("%.1f MiB",g*1024);return sprintf("%.1f KiB",g*1024*1024)}
{lines[NR]=$0; tots[NR]=toGiB($4)+toGiB($5)}
END{
    n=NR
    for(i=1;i<=n;i++) for(j=i+1;j<=n;j++) if(tots[i]<tots[j]){
        t=lines[i];lines[i]=lines[j];lines[j]=t
        t=tots[i];tots[i]=tots[j];tots[j]=t
    }
    trx=0; ttx=0
    for(i=1;i<=n;i++){
        split(lines[i],f,"|")
        ip=f[1]; name=substr(f[2],1,28); hs=substr(f[3],1,20); rx=f[4]; tx=f[5]
        rxg=toGiB(rx); txg=toGiB(tx); tot=rxg+txg
        hsc=OR
        if(hs~/^[0-9]+s ago$/ || hs~/^[0-9]+m, [0-9]+s ago$/ || hs~/^[0-9]+m ago$/) hsc=GN
        if(hs~/^[0-9]+h,/ || hs=="never" || hs=="") hsc=RD
        ipc=(ip=="N/A") ? RD : WH
        printf "  %s%-15s%s  %s%-28s%s  %s%-20s%s  %s%-14s%s  %s%-14s%s  %s%-11s%s\n",
            ipc,ip,X, YL,name,X, hsc,hs,X,
            GN,fmt(rxg),X, CY,fmt(txg),X, OR,fmtT(tot),X
        trx+=rxg; ttx+=txg
    }
    print "\033[1;96m  ===========================================================================================================\033[0m"
    printf "  %s%-15s  %-28s  %-20s%s  %s%-14s%s  %s%-14s%s  %s%-11s%s\n",
        YL,"TOTAL","All Clients","",X,
        GN,fmt(trx),X, CY,fmt(ttx),X, OR,fmtT(trx+ttx),X
}'

# --- Active peers (last 15 min) ---
echo -e "\n${YL}  Active peers — last 15 min:${X}\n"

HAS_ACTIVE=0
while IFS='|' read -r ip hs_raw rx tx; do
    [[ -z "$ip" ]] && continue
    secs=$(hs_to_secs "$hs_raw")
    [[ $secs -gt 900 ]] && continue
    HAS_ACTIVE=1
    name=$(echo "$NAMEMAP" | grep "^${ip}=" | cut -d= -f2-)
    [[ -z "$name" ]] && name="Unknown"
    hs_short=$(fmt_hs "$hs_raw")
    printf "  ${WH}%-15s${X}  ${YL}%-28s${X}  ${GN}%-20s${X}  ${CY}in: %-14s${X}  ${OR}out: %s${X}\n" \
        "$ip" "${name:0:28}" "$hs_short" "$rx" "$tx"
done < <(echo "$PEERS")

[[ $HAS_ACTIVE -eq 0 ]] && echo -e "  ${RD}No active peers in last 15 minutes.${X}"

echo ""
