#!/usr/bin/env bash
# ==========================================================================================
#  ----  CLUSTER RESOURCE & VPN LIVE MONITOR (5-STAR UNICODE) v14.0  ----
#  Author  : Vladimir Bulantsev (GinCz)
#  GitHub  : https://github.com/GinCz/Linux_Server_Public
# ==========================================================================================
set +m

export LC_ALL=C.UTF-8 2>/dev/null || export LC_ALL=en_US.UTF-8 2>/dev/null
export LANG=C.UTF-8 2>/dev/null || export LANG=en_US.UTF-8 2>/dev/null

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

STAR_FILLED=$(printf '\xe2\x98\x85')
STAR_EMPTY=$(printf '\xe2\x98\x86')

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
        "222-DE-NetCup:152.53.182.222:Ubuntu_24"
        "109-RU-FastVDS:212.109.223.109:Ubuntu_22"
        "ALEX_51:212.34.148.51:Debian_12"
        "4TON_237:144.124.228.237:Debian_12"
        "TATRA_9:144.124.232.9:Debian_12"
        "SHAHIN_227:144.124.228.227:Debian_12"
        "STOLB_24:144.124.239.24:Debian_12"
        "PILIK_33:195.63.138.33:Debian_12"
        "ILYA_176:146.103.110.176:Debian_12"
        "SO_38:144.124.233.38:Debian_12"
        "ORACLE_230:130.61.139.230:Debian_12"
        "IONOS_38:82.223.116.38:Debian_12"
        "ORACLE_157:130.61.101.157:Debian_12"
        "Amazon_Win_67:52.57.7.67:Windows_10"
        "AWS_Amazon_82:3.67.43.82:Windows_10"
    )
fi

LOCAL_IPS=$(hostname -I 2>/dev/null)
is_local() {
    local ip="$1"
    [[ " $LOCAL_IPS " == *" $ip "* ]]
}

draw_stars_5() {
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
    for ((i=0; i<filled; i++)); do stars="${stars}${STAR_FILLED}"; done
    for ((i=0; i<empty; i++)); do stars="${stars}${STAR_EMPTY}"; done

    printf "${col}[%s]${RESET}" "$stars"
}

# Line width: 113 characters
LINE_EQ="${SLATE_CYAN}$(printf '=%.0s' {1..113})${RESET}"

CMD='
NOW=$(date +%s)
TOT_USERS=0; ON_USERS=0; HAS_VPN=0; VPN_RUN=0

if systemctl is-active --quiet x-ui 2>/dev/null || pgrep -f "xray-linux" >/dev/null 2>&1 || pgrep -f "x-ui" >/dev/null 2>&1 || systemctl is-active --quiet xray 2>/dev/null || pgrep -f "xray" >/dev/null 2>&1; then
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

GET_OS_CMD='
if [ -f /etc/os-release ]; then
    . /etc/os-release
    D=$(echo "$NAME" | awk "{print \$1}")
    V=$(echo "$VERSION_ID" | cut -d. -f1)
    if [ -n "$D" ] && [ -n "$V" ]; then
        echo "${D}_${V}"
    elif [ -n "$D" ]; then
        echo "$D"
    else
        uname -s
    fi
else
    uname -s
fi
'

stty -echo 2>/dev/null
tput civis 2>/dev/null
clear

while true; do
    for idx in "${!SERVERS[@]}"; do
        (
            export LC_ALL=C.UTF-8 2>/dev/null
            ITEM="${SERVERS[$idx]}"
            NAME=$(echo "$ITEM" | cut -d: -f1)
            IP=$(echo "$ITEM" | cut -d: -f2)
            CONFIG_OS=$(echo "$ITEM" | cut -d: -f3)

            if is_local "$IP"; then
                OS_DET=$(eval "$GET_OS_CMD" 2>/dev/null)
                [ -z "$OS_DET" ] && OS_DET="Linux"
                echo "${CONFIG_OS:-$OS_DET}" > "$TMP_DIR/$idx.res"
                bash -c "$CMD" >> "$TMP_DIR/$idx.res" 2>/dev/null
            else
                # Fast SSH with 1s ConnectTimeout
                SSH_OUT=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=1 -o ServerAliveInterval=1 -o BatchMode=yes \
                            -i /root/.ssh/id_ed25519 root@"$IP" \
                            "OS=\$($GET_OS_CMD 2>/dev/null); echo \${OS:-Linux}; $CMD" 2>/dev/null)

                if [[ -n "$SSH_OUT" && $(echo "$SSH_OUT" | wc -l) -ge 5 ]]; then
                    echo "$SSH_OUT" | tail -6 > "$TMP_DIR/$idx.res"
                else
                    # Try Windows Administrator SSH with 1s timeout
                    WIN_SSH=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=1 -o BatchMode=yes \
                                -i /root/.ssh/id_ed25519 Administrator@"$IP" \
                                'powershell -Command "echo Windows_10; echo \"FAIL 0 0\"; $c=[int](Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average; echo $c; $r=Get-CimInstance Win32_OperatingSystem; $rt=[int]($r.TotalVisibleMemorySize/1024); $ru=$rt-[int]($r.FreePhysicalMemory/1024); echo \"$rt $ru\"; $d=Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID=\x27C:\x27\"; $dt=[int]($d.Size/1MB); $df=[int]($d.FreeSpace/1MB); echo \"$dt $($dt-$df) $df\"; $smb=if((Get-Service LanmanServer -EA 0).Status -eq \x27Running\x27){1}else{0}; echo $smb"' 2>/dev/null)

                    if [[ -n "$WIN_SSH" && $(echo "$WIN_SSH" | wc -l) -ge 5 ]]; then
                        echo "$WIN_SSH" | tail -6 > "$TMP_DIR/$idx.res"
                    elif nc -z -w 1 "$IP" 445 2>/dev/null || nc -z -w 1 "$IP" 3389 2>/dev/null || ping -c 1 -w 1 "$IP" >/dev/null 2>&1; then
                        EXPECTED_OS="${CONFIG_OS:-Windows_10}"
                        SMB_VAL=0
                        nc -z -w 1 "$IP" 445 2>/dev/null && SMB_VAL=1
                        {
                            echo "$EXPECTED_OS"
                            echo "FAIL 0 0"
                            echo "N/A"
                            echo "0 0"
                            echo "0 0 0"
                            echo "$SMB_VAL"
                        } > "$TMP_DIR/$idx.res"
                    fi
                fi
            fi
        ) >/dev/null 2>&1 &
    done

    wait >/dev/null 2>&1

    printf '\033[H'

    echo -e "$LINE_EQ"
    # Spacing: NAME (15) + 2 + IP (15) + 3 + OS (10) + 3 + SMB (3) + 3 + Xray (5) + 2 + CPU (7) + 3 + RAM (17) + 3 + DISK (20)
    printf "  ${YELLOW}%-15s  %-15s   %-10s   %-3s   %-5s  %-7s   %-17s   %-20s${RESET}\n" \
           "SERVER NAME" "IP ADDRESS" "OS" "SMB" "Xray" "CPU" "RAM" "DISK (GB)"
    echo -e "$LINE_EQ"

    for idx in "${!SERVERS[@]}"; do
        ITEM="${SERVERS[$idx]}"
        NAME=$(echo "$ITEM" | cut -d: -f1)
        IP=$(echo "$ITEM" | cut -d: -f2)
        CONFIG_OS=$(echo "$ITEM" | cut -d: -f3)
        RES_FILE="$TMP_DIR/$idx.res"

        if [[ ! -s "$RES_FILE" || $(wc -l < "$RES_FILE") -lt 5 ]]; then
            DISPLAY_OS="${CONFIG_OS:-—}"
            printf "  ${BOLD}${WHITE}%-15s${RESET}  ${DIM}%-15s${RESET}   ${YELLOW}%-10s${RESET}   ${RED}%-3s${RESET}   ${RED}%-5s${RESET}  ${RED}%-7s${RESET}   ${RED}%-17s${RESET}   ${RED}%-20s${RESET}\n" \
                   "$NAME" "$IP" "$DISPLAY_OS" "OFF" "OFF" "UNREACH" "UNREACHABLE" "UNREACHABLE"
        else
            OS_VAL=$(sed -n '1p' "$RES_FILE" | tr -d '\r')
            DISPLAY_OS="${OS_VAL:-${CONFIG_OS:-Linux}}"

            VPN_STATUS=$(sed -n '2p' "$RES_FILE" | tr -d '\r')
            STATUS_TYPE=$(echo "$VPN_STATUS" | awk '{print $1}')
            ON_CNT=$(echo "$VPN_STATUS" | awk '{print $2}')
            TOT_CNT=$(echo "$VPN_STATUS" | awk '{print $3}')

            if [[ "$STATUS_TYPE" == "FAIL" ]]; then
                VPN_STR=$(printf "${RED}%-5s${RESET}" "OFF")
            else
                VPN_STR=$(printf "${GREEN}%d/%-3d${RESET}" "$ON_CNT" "$TOT_CNT")
            fi

            CPU_VAL=$(sed -n '3p' "$RES_FILE" | tr -d '\r')
            if [[ "$CPU_VAL" == "N/A" || -z "$CPU_VAL" ]]; then
                CPU_STR=$(printf "${DIM}%-7s${RESET}" "N/A")
            else
                CPU_PCT=${CPU_VAL:-0}
                CPU_STR=$(draw_stars_5 "$CPU_PCT")
            fi

            RAM_TOTAL=$(awk 'NR==4{print $1}' "$RES_FILE")
            RAM_USED=$(awk 'NR==4{print $2}' "$RES_FILE")
            if [[ -z "$RAM_TOTAL" || "$RAM_TOTAL" -eq 0 ]]; then
                RAM_STR=$(printf "${DIM}%-17s${RESET}" "N/A")
            else
                RAM_PCT=$(( RAM_USED * 100 / RAM_TOTAL ))
                if (( RAM_TOTAL >= 1024 )); then
                    RAM_TXT=$(awk "BEGIN{printf \"%.1fG/%.1fG\", $RAM_USED/1024, $RAM_TOTAL/1024}")
                else
                    RAM_TXT="${RAM_USED}M/${RAM_TOTAL}M"
                fi
                STARS_RAM=$(draw_stars_5 "$RAM_PCT")
                RAM_STR=$(printf "%b %-9s" "$STARS_RAM" "$RAM_TXT")
            fi

            DISK_TOTAL=$(awk 'NR==5{print $1}' "$RES_FILE")
            DISK_USED=$(awk 'NR==5{print $2}' "$RES_FILE")
            DISK_FREE=$(awk 'NR==5{print $3}' "$RES_FILE")
            if [[ -z "$DISK_TOTAL" || "$DISK_TOTAL" -eq 0 ]]; then
                DISK_STR=$(printf "${DIM}%-20s${RESET}" "N/A")
            else
                DISK_PCT=$(( DISK_USED * 100 / DISK_TOTAL ))
                DISK_USED_GB=$(( (DISK_TOTAL - DISK_FREE) / 1024 ))
                DISK_TOT_GB=$(( DISK_TOTAL / 1024 ))
                DISK_TXT="${DISK_USED_GB}/${DISK_TOT_GB}"
                STARS_DISK=$(draw_stars_5 "$DISK_PCT")
                DISK_STR=$(printf "%b %-7s %3d%%" "$STARS_DISK" "$DISK_TXT" "$DISK_PCT")
            fi

            SMB_VAL=$(sed -n '6p' "$RES_FILE" | tr -d '\r')
            if [[ "$SMB_VAL" == "1" ]]; then
                SMB_STR=$(printf "${GREEN}ON ${RESET}")
            else
                SMB_STR=$(printf "${RED}OFF${RESET}")
            fi

            printf "  ${BOLD}${WHITE}%-15s${RESET}  ${CYAN}%-15s${RESET}   ${YELLOW}%-10s${RESET}   %-3b   %-5b  %b   %b   %b\n" \
                   "$NAME" "$IP" "$DISPLAY_OS" "$SMB_STR" "$VPN_STR" "$CPU_STR" "$RAM_STR" "$DISK_STR"
        fi
        echo -e "$LINE_EQ"
    done

    # Status & Control Footer
    NOW_TIME=$(date '+%H:%M:%S')
    printf "  ${LIGHT_GRAY}[ ${NOW_TIME} ]  |  ${WHITE}[Ctrl+C]${LIGHT_GRAY} Exit  |  Auto-Refresh: 3s${RESET}\n"

    if [[ "$1" == "--once" || "$1" == "-1" || ! -t 1 ]]; then
        break
    fi

    sleep 3
done