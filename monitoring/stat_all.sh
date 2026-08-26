#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█  CLUSTER RESOURCE & VPN LIVE MONITOR (5-STAR COMPACT) v10.0  █▓▒░
#  Author  : Vladimir Bulantsev (GinCz)
#  GitHub  : https://github.com/GinCz/Linux_Server_Public
# ==========================================================================================
set +m

# ANSI Colors
SLATE_CYAN="\e[38;5;67m"
CYAN="\e[96m"
WHITE="\e[97m"
LIGHT_GRAY="\e[37m"
YELLOW="\e[93m"
GREEN="\e[92m"
RED="\e[91m"
DIM="\e[90m"
RESET="\e[0m"
BOLD="\e[1m"

TMP_DIR=$(mktemp -d /tmp/cluster_mon.XXXXXX 2>/dev/null || mktemp -d)

cleanup() {
    stty echo 2>/dev/null
    tput cnorm 2>/dev/null
    rm -rf "$TMP_DIR"
    echo -e "\n${RESET}"
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

CONFIG_FILE="/etc/stat_all/servers.conf"
USER_CONFIG="$HOME/.config/stat_all/servers.conf"
LOCAL_CONFIG="./servers.conf"

SERVERS=()

if [[ -f "$CONFIG_FILE" ]]; then
    mapfile -t SERVERS < <(grep -vE '^\s*#|^\s*$' "$CONFIG_FILE")
elif [[ -f "$USER_CONFIG" ]]; then
    mapfile -t SERVERS < <(grep -vE '^\s*#|^\s*$' "$USER_CONFIG")
elif [[ -f "$LOCAL_CONFIG" ]]; then
    mapfile -t SERVERS < <(grep -vE '^\s*#|^\s*$' "$LOCAL_CONFIG")
fi

if [[ ${#SERVERS[@]} -eq 0 ]]; then
    SERVERS=(
        "De_222:152.53.182.222"
        "Ru_109:212.109.223.109"
        "Alex_47:109.234.38.47"
        "4ton_237:144.124.228.237"
        "Tatra_9:144.124.232.9"
        "Shahin_227:144.124.228.227"
        "Stolb_24:144.124.239.24"
        "Pilik_33:195.63.138.33"
        "Ilya_176:146.103.110.176"
        "So_38:144.124.233.38"
        "Aws_67:52.57.7.67"
        "Ionos_38:82.223.116.38"
        "Oracle_112:92.5.2.112"
    )
fi

LOCAL_IPS=$(hostname -I 2>/dev/null)
is_local() {
    local ip="$1"
    [[ " $LOCAL_IPS " == *" $ip "* ]]
}

draw_stars() {
    local pct=$1
    (( pct > 100 )) && pct=100
    (( pct < 0 )) && pct=0

    local filled=$(( (pct + 10) / 20 ))
    (( filled > 5 )) && filled=5
    local empty=$(( 5 - filled ))

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

LINE_EQ="${SLATE_CYAN}$(printf '═%.0s' {1..109})${RESET}"

CMD='
NOW=$(date +%s)
TOT_USERS=0; ON_USERS=0; HAS_VPN=0; VPN_RUN=0

if systemctl is-active --quiet x-ui 2>/dev/null || pgrep -f "xray-linux" >/dev/null 2>&1 || pgrep -f "x-ui" >/dev/null 2>&1; then
    VPN_RUN=1
fi

if [ -f /etc/x-ui/x-ui.db ]; then
    chmod 755 /etc/x-ui 2>/dev/null
    DB_CLIENTS=$(sqlite3 /etc/x-ui/x-ui.db "SELECT count(*) FROM client_traffics;" 2>/dev/null)
    if [[ -z "$DB_CLIENTS" || "$DB_CLIENTS" -eq 0 ]]; then
        DB_CLIENTS=$(sqlite3 /etc/x-ui/x-ui.db "SELECT count(*) FROM clients;" 2>/dev/null)
    fi
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

if [ "$VPN_RUN" -eq 0 ] && [ "$HAS_VPN" -eq 0 ]; then
    echo "FAIL $ON_USERS $TOT_USERS"
else
    echo "OK $ON_USERS $TOT_USERS"
fi

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

RAM=$(free -m | awk '\''NR==2{printf "%d %d", $2, $3}'\'')
DISK=$(df -m / | awk '\''NR==2{printf "%d %d %d", $2, $3, $4}'\'')

SMB_ON=0
if systemctl is-active --quiet smbd 2>/dev/null || pgrep -x smbd >/dev/null 2>&1; then
    SMB_ON=1
fi

echo "$CPU"
echo "$RAM"
echo "$DISK"
echo "$SMB_ON"
'

stty -echo 2>/dev/null
tput civis 2>/dev/null
clear

while true; do
    for idx in "${!SERVERS[@]}"; do
        (
            ITEM="${SERVERS[$idx]}"
            IP="${ITEM##*:}"

            if is_local "$IP"; then
                bash -c "$CMD" > "$TMP_DIR/$idx.res" 2>/dev/null
            else
                ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 -o BatchMode=yes \
                    -i /root/.ssh/id_ed25519 root@"$IP" "$CMD" 2>/dev/null | tail -5 > "$TMP_DIR/$idx.res"
            fi
        ) >/dev/null 2>&1 &
    done

    wait >/dev/null 2>&1

    printf '\033[H'

    echo -e "$LINE_EQ"
    printf "  ${YELLOW}%-15s %-15s %-4s %-6s %-12s %-22s %-25s${RESET}\n" \
           "SERVER NAME" "IP ADDRESS" "SMB" "Xray" "CPU" "RAM" "DISK FREE"
    echo -e "$LINE_EQ"

    for idx in "${!SERVERS[@]}"; do
        ITEM="${SERVERS[$idx]}"
        NAME="${ITEM%%:*}"
        IP="${ITEM##*:}"
        RES_FILE="$TMP_DIR/$idx.res"

        if [[ ! -s "$RES_FILE" || $(wc -l < "$RES_FILE") -lt 4 ]]; then
            printf "  ${BOLD}${WHITE}%-15s${RESET} ${DIM}%-15s${RESET} ${RED}%-4s${RESET} ${RED}%-6s${RESET} %-12s %-22s %-25s${RESET}\n" \
                   "$NAME" "$IP" "✗" "OFF" "🔴 UNREACH" "🔴 UNREACH" "🔴 UNREACHABLE"
        else
            VPN_STATUS=$(sed -n '1p' "$RES_FILE" | tr -d '\r')
            STATUS_TYPE=$(echo "$VPN_STATUS" | awk '{print $1}')
            ON_CNT=$(echo "$VPN_STATUS" | awk '{print $2}')
            TOT_CNT=$(echo "$VPN_STATUS" | awk '{print $3}')

            if [[ "$STATUS_TYPE" == "FAIL" ]]; then
                VPN_STR=$(printf "${RED}%-6s${RESET}" "OFF")
            else
                # All digits and slash green
                VPN_STR=$(printf "${GREEN}%d/%-4d${RESET}" "$ON_CNT" "$TOT_CNT")
            fi

            CPU_VAL=$(sed -n '2p' "$RES_FILE" | tr -d '\r')
            CPU_PCT=${CPU_VAL:-0}

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

            DISK_TOTAL=$(awk 'NR==4{print $1}' "$RES_FILE")
            DISK_USED=$(awk 'NR==4{print $2}' "$RES_FILE")
            DISK_FREE=$(awk 'NR==4{print $3}' "$RES_FILE")
            DISK_PCT=0
            if [[ -n "$DISK_TOTAL" && "$DISK_TOTAL" -gt 0 ]]; then
                DISK_PCT=$(( DISK_USED * 100 / DISK_TOTAL ))
            fi

            DISK_TOT_GB=$(awk "BEGIN{printf \"%.0fG\", $DISK_TOTAL/1024}")
            DISK_FREE_GB=$(awk "BEGIN{printf \"%.1fG\", $DISK_FREE/1024}")
            DISK_STR=$(printf "%-5s (%s)" "$DISK_FREE_GB" "$DISK_TOT_GB")

            SMB_VAL=$(sed -n '5p' "$RES_FILE" | tr -d '\r')
            if [[ "$SMB_VAL" == "1" ]]; then
                SMB_STR=$(printf "${GREEN}●${RESET}  ")
            else
                SMB_STR=$(printf "${RED}✗${RESET}  ")
            fi

            printf "  ${BOLD}${WHITE}%-15s${RESET} ${CYAN}%-15s${RESET} %-4b %-6b " "$NAME" "$IP" "$SMB_STR" "$VPN_STR"
            draw_stars "$CPU_PCT"
            printf " %-9s " "$RAM_STR"
            draw_stars "$RAM_PCT"
            printf " %-12s " "$DISK_STR"
            draw_stars "$DISK_PCT"
            printf "\n"
        fi
        echo -e "$LINE_EQ"
    done

    # Status & Control Footer
    NOW_TIME=$(date '+%H:%M:%S')
    printf "  ${LIGHT_GRAY}[ ${NOW_TIME} ]  |  ${WHITE}[Ctrl+C]${LIGHT_GRAY} Exit  |  Auto-Refresh: 3s${RESET}\n"

    sleep 3
done