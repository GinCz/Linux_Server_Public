#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█  CLUSTER RESOURCE & VPN LIVE MONITOR (10-STAR) v9.0  █▓▒░
#  Author  : Vladimir Bulantsev (GinCz)
#  GitHub  : https://github.com/GinCz/Linux_Server_Public
# ==========================================================================================
set +m

# ANSI Colors (balanced, high-contrast)
SLATE_CYAN="\e[38;5;67m"     # Muted Slate Cyan for border lines
CYAN="\e[96m"                 # Bright Cyan for IP addresses
WHITE="\e[97m"                # White for server names
LIGHT_GRAY="\e[37m"           # Light Grey (matches "free" in DISK column)
YELLOW="\e[93m"               # Yellow for column headers
GREEN="\e[92m"                # Green for active status & low load
RED="\e[91m"                  # Red for errors, high load & disabled state
DIM="\e[90m"                  # Dark Grey
RESET="\e[0m"
BOLD="\e[1m"

# Temp working directory
TMP_DIR=$(mktemp -d /tmp/cluster_mon.XXXXXX 2>/dev/null || mktemp -d)

# Clean exit handler
cleanup() {
    tput cnorm 2>/dev/null
    rm -rf "$TMP_DIR"
    echo -e "\n${RESET}"
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# Cluster Servers List
SERVERS=(
    "222-DE-NetCup:152.53.182.222"
    "109-RU-FastVDS:212.109.223.109"
    "alex47:109.234.38.47"
    "4ton237:144.124.228.237"
    "tatra9:144.124.232.9"
    "shahin227:144.124.228.227"
    "stolb24:144.124.239.24"
    "pilik33:195.63.138.33"
    "ilya176:146.103.110.176"
    "so38:144.124.233.38"
)

LOCAL_IPS=$(hostname -I 2>/dev/null)
is_local() {
    local ip="$1"
    [[ " $LOCAL_IPS " == *" $ip "* ]]
}

# 10-Star Visual Meter (Strictly 17 visible characters: "[★★★★★★★★★★]  99%")
draw_stars() {
    local pct=$1
    (( pct > 100 )) && pct=100
    (( pct < 0 )) && pct=0

    local filled=$(( (pct + 5) / 10 ))
    (( filled > 10 )) && filled=10
    local empty=$(( 10 - filled ))

    local col="$GREEN"
    if (( pct >= 90 )); then
        col="$RED"
    elif (( pct >= 75 )); then
        col="$YELLOW"
    fi

    local stars=""
    for ((i=0; i<filled; i++)); do stars="${stars}★"; done
    for ((i=0; i<empty; i++)); do stars="${stars}☆"; done

    printf "${col}[%s] %3d%%${RESET}" "$stars" "$pct"
}

# Exact table width line (137 characters)
LINE_EQ="${SLATE_CYAN}$(printf '═%.0s' {1..137})${RESET}"

# Remote probe script executed concurrently on nodes
CMD='
NOW=$(date +%s)

# 1. VPN / Xray Client Counters (Online / Total)
TOT_USERS=0
ON_USERS=0
HAS_VPN=0
VPN_RUN=0

if systemctl is-active --quiet x-ui 2>/dev/null || pgrep -f "xray-linux" >/dev/null 2>&1 || pgrep -f "x-ui" >/dev/null 2>&1; then
    VPN_RUN=1
fi

# A) 3X-UI SQLite Database
if [ -f /etc/x-ui/x-ui.db ]; then
    chmod 755 /etc/x-ui 2>/dev/null
    DB_CLIENTS=$(sqlite3 /etc/x-ui/x-ui.db "SELECT count(*) FROM client_traffics;" 2>/dev/null)
    if [[ -n "$DB_CLIENTS" && "$DB_CLIENTS" -gt 0 ]]; then
        HAS_VPN=1
        TOT_USERS=$(( TOT_USERS + DB_CLIENTS ))
    fi
    DB_PORTS=$(sqlite3 /etc/x-ui/x-ui.db "SELECT port FROM inbounds WHERE enable=1;" 2>/dev/null)
    if [ -n "$DB_PORTS" ]; then
        HAS_VPN=1
        for P in $DB_PORTS; do
            X_ON=$(ss -Hnt state established 2>/dev/null | awk "\$3 ~ /:$P\$/ {print \$4}" | sed "s/.*ffff://; s/].*//; s/:.*//" | sort -u | grep -Ev "^127\.|^$" | wc -l)
            ON_USERS=$(( ON_USERS + X_ON ))
        done
    fi
fi

# Fallback to config.json
if [ "$TOT_USERS" -eq 0 ] && [ -f /usr/local/x-ui/bin/config.json ]; then
    CFG_CLIENTS=$(grep -c "\"email\":" /usr/local/x-ui/bin/config.json 2>/dev/null || echo 0)
    if [ "$CFG_CLIENTS" -gt 0 ]; then
        HAS_VPN=1
        TOT_USERS=$(( TOT_USERS + CFG_CLIENTS ))
        PORTS=$(grep -oE "\"port\":\s*[0-9]+" /usr/local/x-ui/bin/config.json | awk -F: "{print \$2}" | tr -d " " | grep -vE "^62789$|^11111$|^10316$")
        for P in $PORTS; do
            X_ON=$(ss -Hnt state established 2>/dev/null | awk "\$3 ~ /:$P\$/ {print \$4}" | sed "s/.*ffff://; s/].*//; s/:.*//" | sort -u | grep -Ev "^127\.|^$" | wc -l)
            ON_USERS=$(( ON_USERS + X_ON ))
        done
    fi
fi

# B) WireGuard / AWG
if command -v wg >/dev/null 2>&1 || command -v awg >/dev/null 2>&1; then
    TOT_WG=$( { wg show all peers 2>/dev/null || awg show all peers 2>/dev/null; } | wc -l )
    if [ "$TOT_WG" -gt 0 ]; then
        HAS_VPN=1
        VPN_RUN=1
        TOT_USERS=$(( TOT_USERS + TOT_WG ))
        WG_ON=$( { wg show all latest-handshakes 2>/dev/null || awg show all latest-handshakes 2>/dev/null; } | awk -v n="$NOW" "\$3>0 && (n-\$3)<180 {c++} END{print c+0}" )
        ON_USERS=$(( ON_USERS + WG_ON ))
    fi
fi

# C) Docker AmneziaWG
DOC=$(docker ps --format "{{.Names}}" 2>/dev/null | grep -Ei "amnezia.?awg|awg.?amnezia|amneziawg" | head -1)
if [ -n "$DOC" ]; then
    HAS_VPN=1
    VPN_RUN=1
    DOC_TABLE=$(docker exec "$DOC" cat /opt/amnezia/awg/clientsTable 2>/dev/null)
    TOT_DOC=$(echo "$DOC_TABLE" | grep -c "\"clientId\":" 2>/dev/null || echo 0)
    TOT_USERS=$(( TOT_USERS + TOT_DOC ))
    DOC_ON=$(echo "$DOC_TABLE" | grep -Eo "[0-9]+(s|m) ago" | wc -l)
    ON_USERS=$(( ON_USERS + DOC_ON ))
fi

if [ "$VPN_RUN" -eq 0 ] || [ "$HAS_VPN" -eq 0 ] || [ "$TOT_USERS" -eq 0 ]; then
    echo "FAIL $ON_USERS $TOT_USERS"
else
    echo "OK $ON_USERS $TOT_USERS"
fi

# 2. Precision CPU Measurement (Instant + Normalized LoadAvg)
read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ < /proc/stat
sleep 0.22
read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ < /proc/stat
idle1=$(( i1 + w1 ))
total1=$(( u1 + n1 + s1 + i1 + w1 + q1 + sq1 + st1 ))
idle2=$(( i2 + w2 ))
total2=$(( u2 + n2 + s2 + i2 + w2 + q2 + sq2 + st2 ))
didle=$(( idle2 - idle1 ))
dtotal=$(( total2 - total1 ))
INSTANT=0
if (( dtotal > 0 )); then
    INSTANT=$(( (dtotal - didle) * 100 / dtotal ))
fi

CORES=$(nproc 2>/dev/null || echo 1)
L1=$(awk '\''{print $1}'\'' /proc/loadavg 2>/dev/null || echo 0)
LOAD_PCT=$(awk -v l="$L1" -v c="$CORES" '\''BEGIN{p=int((l/c)*100); if(p>100)p=100; if(p<0)p=0; print p}'\'')

CPU=$INSTANT
(( LOAD_PCT > CPU )) && CPU=$LOAD_PCT
(( CPU > 100 )) && CPU=100

# 3. RAM
RAM=$(free -m | awk '\''NR==2{printf "%d %d", $2, $3}'\'')

# 4. DISK
DISK=$(df -m / | awk '\''NR==2{printf "%d %d %d", $2, $3, $4}'\'')

echo "$CPU"
echo "$RAM"
echo "$DISK"
'

# Hide cursor for flicker-free live rendering
tput civis 2>/dev/null
clear

# Main Live Monitoring Loop
while true; do
    # 1. Concurrent background probe (Double-Buffering)
    for idx in "${!SERVERS[@]}"; do
        (
            ITEM="${SERVERS[$idx]}"
            IP="${ITEM##*:}"

            if is_local "$IP"; then
                bash -c "$CMD" > "$TMP_DIR/$idx.res" 2>/dev/null
            else
                ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 -o BatchMode=yes \
                    -i /root/.ssh/id_ed25519 root@"$IP" "$CMD" 2>/dev/null | tail -4 > "$TMP_DIR/$idx.res"
            fi
        ) >/dev/null 2>&1 &
    done

    # Await probe completion (~0.5s)
    wait >/dev/null 2>&1

    # 2. Instant repaint at cursor (0,0)
    printf '\033[H'

    echo -e "$LINE_EQ"
    printf "  ${YELLOW}%-15s  %-16s   %-8s   %-17s   %-29s   %-36s${RESET}\n" \
           "SERVER NAME" "IP ADDRESS" "Xray" "CPU" "RAM" "DISK"
    echo -e "$LINE_EQ"

    for idx in "${!SERVERS[@]}"; do
        ITEM="${SERVERS[$idx]}"
        NAME="${ITEM%%:*}"
        IP="${ITEM##*:}"
        RES_FILE="$TMP_DIR/$idx.res"

        if [[ ! -s "$RES_FILE" || $(wc -l < "$RES_FILE") -lt 4 ]]; then
            printf "  ${BOLD}${WHITE}%-15s${RESET}  ${DIM}%-16s${RESET}   ${RED}%-8s${RESET}   %-17s   %-29s   %-36s${RESET}\n" \
                   "$NAME" "$IP" "✗  OFF  " "🔴 UNREACHABLE" "🔴 UNREACHABLE" "🔴 UNREACHABLE"
        else
            # 1. Xray / VPN Online Status (8 characters)
            VPN_STATUS=$(sed -n '1p' "$RES_FILE" | tr -d '\r')
            STATUS_TYPE=$(echo "$VPN_STATUS" | awk '{print $1}')
            ON_CNT=$(echo "$VPN_STATUS" | awk '{print $2}')
            TOT_CNT=$(echo "$VPN_STATUS" | awk '{print $3}')

            if [[ "$STATUS_TYPE" == "FAIL" || "$TOT_CNT" -eq 0 ]]; then
                # Clean, full-width red cross indicator
                VPN_STR=$(printf "${RED}✗  OFF  ${RESET}")
            elif [[ "$ON_CNT" -eq 0 ]]; then
                # Active service with 0 online: green dot + light grey 0/Total
                VPN_STR=$(printf "${GREEN}● ${LIGHT_GRAY}%2d/%-3d${RESET}" 0 "$TOT_CNT")
            else
                # Active service with online clients
                VPN_STR=$(printf "${GREEN}● %2d${RESET}${LIGHT_GRAY}/%-3d${RESET}" "$ON_CNT" "$TOT_CNT")
            fi

            # 2. CPU (17 characters)
            CPU_VAL=$(sed -n '2p' "$RES_FILE" | tr -d '\r')
            CPU_PCT=${CPU_VAL:-0}

            # 3. RAM
            RAM_TOTAL=$(awk 'NR==3{print $1}' "$RES_FILE")
            RAM_USED=$(awk 'NR==3{print $2}' "$RES_FILE")
            RAM_PCT=0
            if [[ -n "$RAM_TOTAL" && "$RAM_TOTAL" -gt 0 ]]; then
                RAM_PCT=$(( RAM_USED * 100 / RAM_TOTAL ))
            fi

            if (( RAM_TOTAL >= 1024 )); then
                RAM_STR=$(awk "BEGIN{printf \"%.1fG/%.1fG\", $RAM_USED/1024, $RAM_TOTAL/1024}")
            else
                RAM_STR="${RAM_USED}M/${RAM_TOTAL}M"
            fi

            # 4. DISK
            DISK_TOTAL=$(awk 'NR==4{print $1}' "$RES_FILE")
            DISK_USED=$(awk 'NR==4{print $2}' "$RES_FILE")
            DISK_FREE=$(awk 'NR==4{print $3}' "$RES_FILE")
            DISK_PCT=0
            if [[ -n "$DISK_TOTAL" && "$DISK_TOTAL" -gt 0 ]]; then
                DISK_PCT=$(( DISK_USED * 100 / DISK_TOTAL ))
            fi

            DISK_TOT_GB=$(awk "BEGIN{printf \"%.0fG\", $DISK_TOTAL/1024}")
            DISK_FREE_GB=$(awk "BEGIN{printf \"%.1fG\", $DISK_FREE/1024}")
            DISK_STR="${DISK_FREE_GB} free (${DISK_TOT_GB})"

            # Render row (Strictly 137 visible characters)
            printf "  ${BOLD}${WHITE}%-15s${RESET}  ${CYAN}%-16s${RESET}   %-8b   " "$NAME" "$IP" "$VPN_STR"
            draw_stars "$CPU_PCT"
            printf "   %-10s  " "$RAM_STR"
            draw_stars "$RAM_PCT"
            printf "   %-17s  " "$DISK_STR"
            draw_stars "$DISK_PCT"
            printf "\n"
        fi
        echo -e "$LINE_EQ"
    done

    # English Status & Control Footer
    NOW_TIME=$(date '+%H:%M:%S')
    printf "  ${LIGHT_GRAY}⏱ ${NOW_TIME}  |  ${WHITE}[Ctrl+C]${LIGHT_GRAY} Exit  |  ${WHITE}[F5 / Enter]${LIGHT_GRAY} Refresh now  |  Auto-refresh: 5s${RESET}\n"

    # 5-second non-blocking wait with instant key trigger
    read -t 5 -n 4 -s KEY 2>/dev/null
    if [[ "$KEY" == $'\x03' || "$KEY" == "q" || "$KEY" == "Q" ]]; then
        cleanup
    fi
done