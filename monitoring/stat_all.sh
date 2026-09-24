#!/usr/bin/env bash
# ==========================================================================================
#  ----  CLUSTER RESOURCE & VPN LIVE MONITOR (5-STAR UNICODE) v15.0  ----
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
        "222_DE_NetCup:152.53.182.222:Ubuntu_24"
        "109_RU_FirstVDS:212.109.223.109:Ubuntu_24"
        "ORACLE_157:130.61.101.157:Debian_12_ARM"
        "4Ton_Deb12_237:144.124.228.237:Debian_12"
        "Alex_Deb12_39:89.110.121.39:Debian_12"
        "Tatra_Kuma_9:144.124.232.9:Debian_12"
        "STOLB_AdGuard_24:144.124.239.24:Debian_12"
        "Shahin_Deb12_227:144.124.228.227:Debian_12"
        "4er_Deb12_108:78.40.193.108:Debian_12"
        "ILYA_Deb12_221:89.110.69.221:Debian_12"
        "SO_Deb12_38:144.124.233.38:Debian_12"
        "IONOS_Deb12_38:82.223.116.38:Debian_12"
        "Oracle_Deb12_230:130.61.139.230:Debian_12_ARM"
        "AWS_WIN_67:52.57.7.67:Windows_10_Micro"
        "AWS_WIN_82:3.67.43.82:Windows_10_LTSC"
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

# Line width: exactly 127 characters
LINE_EQ="${SLATE_CYAN}$(printf '=%.0s' {1..127})${RESET}"

read -r -d '' CMD << 'EOF'
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
        PORTS=$(grep -oE "\"port\":\s*[0-9]+" /usr/local/x-ui/bin/config.json | awk -F: '{print $2}' | tr -d " " | grep -vE "^62789$|^11111$|^10316$")
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
        L_HANDSHAKES=$( { wg show all latest-handshakes 2>/dev/null || awg show all latest-handshakes 2>/dev/null; } | awk '{print $NF}' )
        for HS in $L_HANDSHAKES; do
            if [ -n "$HS" ] && [ "$HS" -gt 0 ]; then
                DIFF=$(( NOW - HS ))
                if [ "$DIFF" -le 180 ]; then
                    ON_USERS=$(( ON_USERS + 1 ))
                fi
            fi
        done
    fi
fi

if [ "$HAS_VPN" -eq 1 ]; then
    echo "OK $ON_USERS $TOT_USERS"
elif [ "$VPN_RUN" -eq 1 ]; then
    echo "OK 0 0"
else
    echo "FAIL 0 0"
fi

stat1=( $(grep "^cpu " /proc/stat 2>/dev/null) )
user1=${stat1[1]:-0}; nice1=${stat1[2]:-0}; sys1=${stat1[3]:-0}; idle1=${stat1[4]:-0}
iow1=${stat1[5]:-0}; irq1=${stat1[6]:-0}; sirq1=${stat1[7]:-0}; steal1=${stat1[8]:-0}
total1=$(( user1 + nice1 + sys1 + idle1 + iow1 + irq1 + sirq1 + steal1 ))

sleep 0.15

stat2=( $(grep "^cpu " /proc/stat 2>/dev/null) )
user2=${stat2[1]:-0}; nice2=${stat2[2]:-0}; sys2=${stat2[3]:-0}; idle2=${stat2[4]:-0}
iow2=${stat2[5]:-0}; irq2=${stat2[6]:-0}; sirq2=${stat2[7]:-0}; steal2=${stat2[8]:-0}
total2=$(( user2 + nice2 + sys2 + idle2 + iow2 + irq2 + sirq2 + steal2 ))

didle=$(( idle2 - idle1 ))
dtotal=$(( total2 - total1 ))
INSTANT=0
if (( dtotal > 0 )); then
    INSTANT=$(( (dtotal - didle) * 100 / dtotal ))
fi

CORES=$(nproc 2>/dev/null || echo 1)
L1=$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo 0)
LOAD_PCT=$(awk -v l="$L1" -v c="$CORES" 'BEGIN{p=int((l/c)*100); if(p>100)p=100; if(p<0)p=0; print p}')

CPU=$INSTANT
(( LOAD_PCT > CPU )) && CPU=$LOAD_PCT
(( CPU > 100 )) && CPU=100

RAM=$(free -m | awk 'NR==2{printf "%d %d", $2, $3}')
DISK=$(df -m / | awk 'NR==2{printf "%d %d %d", $2, $3, $4}')

SMB_ON=0
if systemctl is-active --quiet smbd 2>/dev/null || pgrep -x smbd >/dev/null 2>&1; then
    SMB_ON=1
fi

echo "$CPU"
echo "$RAM"
echo "$DISK"
echo "$SMB_ON"
EOF

read -r -d '' GET_OS_CMD << 'EOF'
if [ -f /etc/os-release ]; then
    . /etc/os-release
    D=$(echo "$NAME" | awk '{print $1}')
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
EOF

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
    # Column widths: NAME(18) IP(16) OS(18) SMB(4) Xray(6) CPU(8) RAM(20) DISK(21)
    printf "  ${YELLOW}%-18s  %-16s  %-18s  %-4s  %-6s  %-8s  %-20s  %-21s${RESET}\n" \
           "SERVER NAME" "IP ADDRESS" "OS" "SMB" "Xray" "CPU" "RAM (USED/TOTAL)" "DISK (USED/TOT  PCT)"
    echo -e "$LINE_EQ"

    for idx in "${!SERVERS[@]}"; do
        ITEM="${SERVERS[$idx]}"
        NAME=$(echo "$ITEM" | cut -d: -f1)
        IP=$(echo "$ITEM" | cut -d: -f2)
        CONFIG_OS=$(echo "$ITEM" | cut -d: -f3)
        RES_FILE="$TMP_DIR/$idx.res"

        if [[ ! -s "$RES_FILE" || $(wc -l < "$RES_FILE") -lt 5 ]]; then
            DISPLAY_OS="${CONFIG_OS:-N/A}"
            printf "  ${BOLD}${WHITE}%-18s${RESET}  ${DIM}%-16s${RESET}  ${YELLOW}%-18s${RESET}  ${RED}%-4s${RESET}  ${RED}%-6s${RESET}  ${RED}%-8s${RESET}  ${RED}%-20s${RESET}  ${RED}%-21s${RESET}\n" \
                   "$NAME" "$IP" "$DISPLAY_OS" "OFF" "OFF" "UNREACH" "UNREACHABLE" "UNREACHABLE"
        else
            OS_VAL=$(sed -n '1p' "$RES_FILE" | tr -d '\r')
            DISPLAY_OS="${OS_VAL:-${CONFIG_OS:-Linux}}"

            VPN_STATUS=$(sed -n '2p' "$RES_FILE" | tr -d '\r')
            STATUS_TYPE=$(echo "$VPN_STATUS" | awk '{print $1}')
            ON_CNT=$(echo "$VPN_STATUS" | awk '{print $2}')
            TOT_CNT=$(echo "$VPN_STATUS" | awk '{print $3}')

            if [[ "$STATUS_TYPE" == "FAIL" ]]; then
                VPN_STR=$(printf "${RED}%-6s${RESET}" "OFF")
            else
                VPN_TXT="${ON_CNT}/${TOT_CNT}"
                VPN_STR=$(printf "${GREEN}%-6s${RESET}" "$VPN_TXT")
            fi

            CPU_VAL=$(sed -n '3p' "$RES_FILE" | tr -d '\r')
            if [[ "$CPU_VAL" == "N/A" || -z "$CPU_VAL" ]]; then
                CPU_STR=$(printf "${DIM}%-8s${RESET}" "N/A")
            else
                CPU_PCT=${CPU_VAL:-0}
                CPU_STR="$(draw_stars_5 "$CPU_PCT") "
            fi

            RAM_TOTAL=$(awk 'NR==4{print $1}' "$RES_FILE")
            RAM_USED=$(awk 'NR==4{print $2}' "$RES_FILE")
            if [[ -z "$RAM_TOTAL" || "$RAM_TOTAL" -eq 0 ]]; then
                RAM_STR=$(printf "${DIM}%-20s${RESET}" "N/A")
            else
                RAM_PCT=$(( RAM_USED * 100 / RAM_TOTAL ))
                if (( RAM_TOTAL >= 1024 )); then
                    RAM_TXT=$(awk "BEGIN{printf \"%.1fG/%.1fG\", $RAM_USED/1024, $RAM_TOTAL/1024}")
                else
                    RAM_TXT="${RAM_USED}M/${RAM_TOTAL}M"
                fi
                STARS_RAM=$(draw_stars_5 "$RAM_PCT")
                RAM_STR=$(printf "%b %-12s" "$STARS_RAM" "$RAM_TXT")
            fi

            DISK_TOTAL=$(awk 'NR==5{print $1}' "$RES_FILE")
            DISK_USED=$(awk 'NR==5{print $2}' "$RES_FILE")
            DISK_FREE=$(awk 'NR==5{print $3}' "$RES_FILE")
            if [[ -z "$DISK_TOTAL" || "$DISK_TOTAL" -eq 0 ]]; then
                DISK_STR=$(printf "${DIM}%-21s${RESET}" "N/A")
            else
                DISK_PCT=$(( DISK_USED * 100 / DISK_TOTAL ))
                DISK_USED_GB=$(( (DISK_TOTAL - DISK_FREE) / 1024 ))
                DISK_TOT_GB=$(( DISK_TOTAL / 1024 ))
                DISK_TXT="${DISK_USED_GB}/${DISK_TOT_GB}"
                DISK_PCT_STR="${DISK_PCT}%"
                STARS_DISK=$(draw_stars_5 "$DISK_PCT")
                DISK_STR=$(printf "%b %-8s %4s" "$STARS_DISK" "$DISK_TXT" "$DISK_PCT_STR")
            fi

            SMB_VAL=$(sed -n '6p' "$RES_FILE" | tr -d '\r')
            if [[ "$SMB_VAL" == "1" ]]; then
                SMB_STR=$(printf "${GREEN}%-4s${RESET}" "ON")
            else
                SMB_STR=$(printf "${RED}%-4s${RESET}" "OFF")
            fi

            printf "  ${BOLD}${WHITE}%-18s${RESET}  ${CYAN}%-16s${RESET}  ${YELLOW}%-18s${RESET}  %b  %b  %b  %b  %b\n" \
                   "$NAME" "$IP" "$DISPLAY_OS" "$SMB_STR" "$VPN_STR" "$CPU_STR" "$RAM_STR" "$DISK_STR"
        fi
        echo -e "$LINE_EQ"
    done

    # Status & Control Footer
    NOW_TIME=$(date '+%H:%M:%S')
    printf "  ${LIGHT_GRAY}[ ${NOW_TIME} ]  |  ${WHITE}[Ctrl+C]${LIGHT_GRAY} Exit  |  Auto-Refresh: 5s${RESET}\n"

    if [[ "$1" == "--once" || "$1" == "-1" || ! -t 1 ]]; then
        break
    fi

    sleep 5
done
