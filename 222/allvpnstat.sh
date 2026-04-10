#!/bin/bash
# = Rooted by VladiMIR | AI = v2026-04-10
# =============================================================================
# Script:   allvpnstat.sh
# Version:  v2026-04-10
# Server:   222-DE-NetCup  (xxx.xx.xxx.222)  — main management server
# Location: /root/allvpnstat.sh
# Alias:    allvpnstat='bash /root/allvpnstat.sh'
# =============================================================================
#
# PURPOSE:
#   Centralized AmneziaWG VPN statistics collector.
#   This script runs on the MASTER server (222) and connects via SSH
#   to all 10 VPN nodes (including itself) to gather per-user traffic
#   statistics and show which users were active in the last 15 minutes.
#
# HOW IT WORKS:
#   1. The master server (222) loops through all 10 VPN server IPs.
#   2. For each remote server it runs a REMOTE_SCRIPT block via SSH.
#   3. The remote script queries the Docker container "amnezia-awg":
#      - reads /opt/amnezia/awg/clientsTable (JSON with user names + IPs)
#      - reads "awg show awg0 dump" (or "wg show wg0 dump" as fallback)
#        to get per-peer traffic counters (rx bytes, tx bytes)
#        and last-handshake timestamps
#   4. Results are printed locally in a color-coded table:
#      - Yellow bordered box  = server header (#N  NAME  IP)
#      - Cyan table           = all users with In/Out/Total traffic in GB
#      - Yellow TOTAL row     = sum of all traffic for that server
#      - Active section       = users seen within the last 15 minutes
#   5. After all servers: green summary box with completion timestamp.
#
# REQUIREMENTS:
#   - SSH key of server 222 must be in authorized_keys on all VPN nodes
#     (passwordless SSH as root, key: /root/.ssh/id_ed25519)
#   - Docker container named "amnezia-awg" must be running on each VPN node
#   - AmneziaWG installed via Amnezia Windows app on each VPN node
#   - Ubuntu 22.04 / 24.04 on all nodes
#
# INSTALLATION (run once on server 222):
#   cp allvpnstat.sh /root/allvpnstat.sh
#   chmod +x /root/allvpnstat.sh
#   echo "alias allvpnstat='bash /root/allvpnstat.sh'" >> /root/.bashrc
#   source /root/.bashrc
#
# USAGE:
#   allvpnstat
#
# VPN NODE LIST (IPs masked for public repo — last octet shown only):
#   #1   222-DE-NetCup     xxx.xx.xxx.222   Germany / NetCup   (master server)
#   #2   109-RU-FastVDS    xxx.xxx.xxx.109  Russia  / FastVDS
#   #3   ALEX_47           xxx.xxx.xx.47    VPN node + Samba
#   #4   4TON_237          xxx.xxx.xxx.237  VPN node + Samba + Prometheus
#   #5   TATRA_9           xxx.xxx.xxx.9    VPN node + Samba + Kuma Monitoring
#   #6   SHAHIN_227        xxx.xxx.xxx.227  VPN node + Samba
#   #7   STOLB_24          xxx.xxx.xxx.24   VPN node + Samba + AdGuard Home
#   #8   PILIK_178         xx.xx.xxx.178    VPN node + Samba
#   #9   ILYA_176          xxx.xxx.xxx.176  VPN node + Samba
#   #10  SO_38             xxx.xxx.xxx.38   VPN node + Samba
#
# OUTPUT COLUMNS:
#   IP Address  — VPN tunnel IP assigned to the user (10.8.1.x)
#   User Name   — client name from AmneziaWG config (truncated to 36 chars)
#   In (GB)     — bytes received by the server from this peer (download)
#   Out (GB)    — bytes sent by the server to this peer (upload)
#   Total (GB)  — combined In + Out traffic
#
# NOTES:
#   - Traffic counters reset when Docker container is restarted
#   - "N/A" in IP column means the peer key was not found in clientsTable
#   - Users with 0.00 / 0.00 / 0.00 have never connected since last restart
#   - Active section shows only peers with handshake within last 900 seconds
# =============================================================================

clear

# ----------------------------------------------------------------------------
# VPN SERVER LIST
# Format: "REAL_IP:DISPLAY_NAME"
# Replace xxx values with actual IPs before deploying on your server
# ----------------------------------------------------------------------------
ALL_SERVERS=(
    "xxx.xx.xxx.222:222-DE-NetCup"
    "xxx.xxx.xxx.109:109-RU-FastVDS"
    "xxx.xxx.xx.47:ALEX_47"
    "xxx.xxx.xxx.237:4TON_237"
    "xxx.xxx.xxx.9:TATRA_9"
    "xxx.xxx.xxx.227:SHAHIN_227"
    "xxx.xxx.xxx.24:STOLB_24"
    "xx.xx.xxx.178:PILIK_178"
    "xxx.xxx.xxx.176:ILYA_176"
    "xxx.xxx.xxx.38:SO_38"
)

# ----------------------------------------------------------------------------
# ANSI COLOR CODES
# ----------------------------------------------------------------------------
C="\033[1;36m"    # Cyan       — table borders
Y="\033[1;33m"    # Yellow     — server header boxes + TOTAL row
G="\033[1;32m"    # Green      — server name in header + active users + final box
RD="\033[1;31m"   # Red        — errors and warnings
R="\033[0m"       # Reset      — back to default color
BOLD="\033[1m"    # Bold text

# ----------------------------------------------------------------------------
# REMOTE_SCRIPT — executed on each VPN node via SSH (or locally for server 222)
# This script runs inside the remote shell and outputs lines prefixed with
# "USER|" or "ACTIVE|" which are then parsed by the main loop below.
# ----------------------------------------------------------------------------
REMOTE_SCRIPT='
# Read the AmneziaWG client table (JSON file with user names and assigned IPs)
J=$(docker exec amnezia-awg cat /opt/amnezia/awg/clientsTable 2>/dev/null)

# Detect interface name: AmneziaWG uses awg0, fallback to wg0
if docker exec amnezia-awg awg show awg0 dump >/dev/null 2>&1; then
    D="awg show awg0 dump"
else
    D="wg show wg0 dump"
fi

# Current Unix timestamp for calculating "last seen" time
NOW=$(date +%s)

# --- USERS section: output all peers with traffic totals ---
echo "=USERS="
docker exec amnezia-awg $D 2>/dev/null | tail -n +2 | awk "{print \$1, \$6, \$7}" | while read k r t; do
    # Look up user name and assigned IP from clientsTable JSON by public key
    b=$(echo "$J" | grep -B5 -A5 "$k")
    n=$(echo "$b" | grep "\"clientName\"" | sed "s/.*\"clientName\": \"//;s/\".*//" | head -1)
    ip=$(echo "$b" | grep "\"allowedIps\"" | sed "s/.*\"allowedIPs\": \"//;s/.*\"allowedIps\": \"//;s/\".*//;s|/32||" | head -1)
    [ -z "$n" ] || [ "$n" = "null" ] && n="Unknown"
    [ -z "$ip" ] && ip="N/A"
    # Convert bytes to GB (1 GB = 1073741824 bytes)
    rg=$(awk -v r="$r" "BEGIN{printf \"%.2f\",r/1073741824}")
    tg=$(awk -v t="$t" "BEGIN{printf \"%.2f\",t/1073741824}")
    tt=$(awk -v r="$r" -v t="$t" "BEGIN{printf \"%.2f\",(r+t)/1073741824}")
    echo "USER|$ip|$n|$rg|$tg|$tt"
done

# --- ACTIVE section: peers with handshake within last 15 minutes (900 sec) ---
echo "=ACTIVE="
docker exec amnezia-awg $D 2>/dev/null | tail -n +2 | while read k ps ep ip hs rx tx ka; do
    [ "$hs" = "0" ] && continue          # skip peers that never connected
    DIFF=$((NOW - hs))
    [ $DIFF -gt 900 ] && continue        # skip peers inactive more than 15 min
    b=$(echo "$J" | grep -B5 -A5 "$k")
    n=$(echo "$b" | grep "\"clientName\"" | sed "s/.*\"clientName\": \"//;s/\".*//" | head -1)
    cip=$(echo "$b" | grep "\"allowedIps\"" | sed "s/.*\"allowedIPs\": \"//;s/.*\"allowedIps\": \"//;s/\".*//;s|/32||" | head -1)
    [ -z "$n" ] || [ "$n" = "null" ] && n="Unknown"
    [ -z "$cip" ] && cip="N/A"
    # Format "time ago" string
    if [ $DIFF -lt 60 ]; then AGO="${DIFF}s ago"
    elif [ $DIFF -lt 3600 ]; then AGO="$((DIFF/60))m $((DIFF%60))s ago"
    else AGO="$((DIFF/3600))h $((DIFF%3600/60))m ago"; fi
    # Convert session bytes to MB for active display
    RMB=$(awk -v b="$rx" "BEGIN{printf \"%.1f\",b/1048576}")
    TMB=$(awk -v t="$tx" "BEGIN{printf \"%.1f\",t/1048576}")
    echo "ACTIVE|$cip|$n|$AGO|$RMB|$TMB"
done
'

# ----------------------------------------------------------------------------
# TABLE AND BOX DRAWING ELEMENTS
# Total table width = 106 terminal columns
# Box frame width   = 106 terminal columns (╔ + 104×═ + ╗)
# Column widths: IP=18, UserName=36, In=12, Out=12, Total=12
# ----------------------------------------------------------------------------
HR=$(printf '═%.0s' {1..104})        # horizontal line for yellow/green boxes
BLANK=$(printf ' %.0s' {1..104})     # blank inner line for green summary box

TBL_T="${C}┌────────────────────┬──────────────────────────────────────┬──────────────┬──────────────┬──────────────┐${R}"
TBL_H="${C}│ ${Y}%-18s ${C}│ ${Y}%-36s ${C}│ ${Y}%-12s ${C}│ ${Y}%-12s ${C}│ ${Y}%-12s ${C}│${R}"
TBL_D="${C}├────────────────────┼──────────────────────────────────────┼──────────────┼──────────────┼──────────────┤${R}"
TBL_R="${C}│ ${R}%-18s ${C}│ ${R}%-36s ${C}│ ${R}%-12s ${C}│ ${R}%-12s ${C}│ ${R}%-12s ${C}│${R}"
TBL_F="${C}│ ${Y}%-18s ${C}│ ${Y}%-36s ${C}│ ${Y}%-12s ${C}│ ${Y}%-12s ${C}│ ${Y}%-12s ${C}│${R}"
TBL_B="${C}└────────────────────┴──────────────────────────────────────┴──────────────┴──────────────┴──────────────┘${R}"

# ----------------------------------------------------------------------------
# MAIN LOOP — iterate over all 10 VPN servers
# ----------------------------------------------------------------------------
SRV_NUM=0

for ENTRY in "${ALL_SERVERS[@]}"; do
    IP="${ENTRY%%:*}"      # extract IP (before colon)
    NAME="${ENTRY##*:}"    # extract display name (after colon)
    SRV_NUM=$((SRV_NUM+1))

    echo ""

    # --- Draw yellow server header box ---
    # PAD is calculated using ${#TITLE} which counts Unicode characters correctly
    # ensuring the right border ║ aligns with the table edge (106 columns total)
    TITLE="  ■  #${SRV_NUM}  ${NAME}  (${IP})"
    PAD=$((104 - ${#TITLE}))
    [ $PAD -lt 0 ] && PAD=0
    SPACES=$(printf ' %.0s' $(seq 1 $PAD))
    echo -e "${BOLD}${Y}╔${HR}╗${R}"
    echo -e "${BOLD}${Y}║${G}${TITLE}${Y}${SPACES}║${R}"
    echo -e "${BOLD}${Y}╚${HR}╝${R}"

    # --- Collect data: locally for server 222, via SSH for all others ---
    if [ "$IP" = "xxx.xx.xxx.222" ]; then
        # Run remote script locally on master server (server 222 also runs AmneziaWG)
        RAW=$(bash -c "$REMOTE_SCRIPT" 2>/dev/null)
    else
        # SSH into remote VPN node and execute the remote script
        RAW=$(ssh -o ConnectTimeout=8 -o StrictHostKeyChecking=no root@$IP "$REMOTE_SCRIPT" 2>/dev/null)
        if [ $? -ne 0 ]; then
            echo -e "  ${RD}❌  No connection to ${IP}${R}"
            continue
        fi
    fi

    # --- Draw user traffic table ---
    echo ""
    echo -e "$TBL_T"
    printf "$TBL_H\n" "IP Address" "User Name" "In (GB)" "Out (GB)" "Total (GB)"
    echo -e "$TBL_D"

    USERS_FOUND=0
    SI=0; SO=0; ST=0   # accumulators for TOTAL row (In, Out, Total)

    while IFS= read -r LINE; do
        [[ "$LINE" != USER\|* ]] && continue
        IFS='|' read -r _ uip uname uin uout utot <<< "$LINE"
        USERS_FOUND=1
        uname="${uname:0:36}"   # truncate user name to fit column width
        printf "$TBL_R\n" "$uip" "$uname" "$uin" "$uout" "$utot"
        # Accumulate totals using awk for floating point addition
        SI=$(awk -v a="$SI" -v b="$uin"  'BEGIN{printf "%.2f",a+b}')
        SO=$(awk -v a="$SO" -v b="$uout" 'BEGIN{printf "%.2f",a+b}')
        ST=$(awk -v a="$ST" -v b="$utot" 'BEGIN{printf "%.2f",a+b}')
    done <<< "$RAW"

    # Show warning if Docker is not running or no users found
    [ "$USERS_FOUND" = "0" ] && printf "${C}│ ${RD}%-104s${C}│${R}\n" "  ⚠  No users found / Docker container not running"

    # --- TOTAL row ---
    echo -e "$TBL_D"
    printf "$TBL_F\n" "TOTAL" "-- All Users --" "$SI" "$SO" "$ST"
    echo -e "$TBL_B"

    # --- Active connections section (last 15 minutes) ---
    echo ""
    echo -e "${Y}  ⏱  Active in the last 15 minutes:${R}"

    ACTIVE_FOUND=0
    while IFS= read -r LINE; do
        [[ "$LINE" != ACTIVE\|* ]] && continue
        IFS='|' read -r _ aip aname aago arx atx <<< "$LINE"
        ACTIVE_FOUND=1
        aname="${aname:0:24}"   # truncate for active line display
        printf "    ${C}%-18s${R}  ${G}%-24s${R}  %-18s  ${C}rx: %-14s${R}  ${Y}tx: %s${R}\n" \
            "$aip" "$aname" "$aago" "${arx} MB" "${atx} MB"
    done <<< "$RAW"

    [ "$ACTIVE_FOUND" = "0" ] && echo -e "    ${RD}-- No active connections${R}"

done

# ----------------------------------------------------------------------------
# FINAL GREEN SUMMARY BOX
# ----------------------------------------------------------------------------
echo ""
TS=$(date '+%Y-%m-%d %H:%M:%S')
TSMSG="    ■  allvpnstat completed — ${TS}"
TSPAD=$((104 - ${#TSMSG}))
[ $TSPAD -lt 0 ] && TSPAD=0
TSSPACES=$(printf ' %.0s' $(seq 1 $TSPAD))
echo -e "${BOLD}${G}╔${HR}╗${R}"
echo -e "${BOLD}${G}║${BLANK}║${R}"
echo -e "${BOLD}${G}║${TSMSG}${TSSPACES}║${R}"
echo -e "${BOLD}${G}║${BLANK}║${R}"
echo -e "${BOLD}${G}╚${HR}╝${R}"
echo ""
