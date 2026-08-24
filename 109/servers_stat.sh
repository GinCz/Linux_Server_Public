#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█  CLUSTER RESOURCE & VPN MONITOR (LIVE 10-STAR) v6.0  █▓▒░
#  Author  : Vladimir Bulantsev (GinCz)
#  GitHub  : https://github.com/GinCz/Secret_Privat
# ==========================================================================================
set +m

# ANSI Цвета
CYAN="\e[96m"
WHITE="\e[97m"
LIGHT_GRAY="\e[37m"
YELLOW="\e[93m"
GREEN="\e[92m"
RED="\e[91m"
DIM="\e[90m"
RESET="\e[0m"
BOLD="\e[1m"

# Временная папка
TMP_DIR=$(mktemp -d /tmp/cluster_mon.XXXXXX 2>/dev/null || mktemp -d)

# Чистый выход при Ctrl+C или закрытии
cleanup() {
    tput cnorm 2>/dev/null
    rm -rf "$TMP_DIR"
    echo -e "\n${RESET}"
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# Список серверов
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

# Функция генерации 10 звёздочек
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

LINE_EQ="${CYAN}$(printf '═%.0s' {1..140})${RESET}"

# Команда сбора метрик с каждого сервера
CMD='
NOW=$(date +%s)

# 1. Подсчёт клиентов Xray + WireGuard (Online / Total)
TOT_USERS=0
ON_USERS=0
HAS_VPN=0
VPN_RUN=1

if systemctl list-unit-files 2>/dev/null | grep -q "x-ui.service"; then
    if ! systemctl is-active --quiet x-ui 2>/dev/null && ! pgrep -f "xray-linux" >/dev/null 2>&1; then
        VPN_RUN=0
    fi
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

# Если база не дала клиентов, проверяем config.json
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
        TOT_USERS=$(( TOT_USERS + TOT_WG ))
        WG_ON=$( { wg show all latest-handshakes 2>/dev/null || awg show all latest-handshakes 2>/dev/null; } | awk -v n="$NOW" "\$3>0 && (n-\$3)<180 {c++} END{print c+0}" )
        ON_USERS=$(( ON_USERS + WG_ON ))
    fi
fi

# C) Docker AmneziaWG
DOC=$(docker ps --format "{{.Names}}" 2>/dev/null | grep -Ei "amnezia.?awg|awg.?amnezia|amneziawg" | head -1)
if [ -n "$DOC" ]; then
    HAS_VPN=1
    DOC_TABLE=$(docker exec "$DOC" cat /opt/amnezia/awg/clientsTable 2>/dev/null)
    TOT_DOC=$(echo "$DOC_TABLE" | grep -c "\"clientId\":" 2>/dev/null || echo 0)
    TOT_USERS=$(( TOT_USERS + TOT_DOC ))
    DOC_ON=$(echo "$DOC_TABLE" | grep -Eo "[0-9]+(s|m) ago" | wc -l)
    ON_USERS=$(( ON_USERS + DOC_ON ))
fi

if [ "$VPN_RUN" -eq 0 ]; then
    echo "FAIL $ON_USERS $TOT_USERS"
elif [ "$HAS_VPN" -eq 0 ] || [ "$TOT_USERS" -eq 0 ]; then
    echo "NONE"
else
    echo "OK $ON_USERS $TOT_USERS"
fi

# 2. Точный замер CPU через /proc/stat
S1=$(grep "cpu " /proc/stat 2>/dev/null)
sleep 0.12
S2=$(grep "cpu " /proc/stat 2>/dev/null)
CPU=$(awk -v s1="$S1" -v s2="$S2" '\''BEGIN{
    split(s1, a); split(s2, b);
    u1=a[2]+a[4]; t1=a[2]+a[4]+a[5];
    u2=b[2]+b[4]; t2=b[2]+b[4]+b[5];
    dt=t2-t1; du=u2-u1;
    if (dt>0) printf "%d", (du*100)/dt; else print 0;
}'\'' 2>/dev/null)
[[ -z "$CPU" || "$CPU" -gt 100 ]] && CPU=$(awk '\''{c=int($1*100); if(c>100)c=100; print c}'\'' /proc/loadavg 2>/dev/null || echo 0)

# 3. RAM
RAM=$(free -m | awk '\''NR==2{printf "%d %d", $2, $3}'\'')

# 4. DISK
DISK=$(df -m / | awk '\''NR==2{printf "%d %d %d", $2, $3, $4}'\'')

echo "$CPU"
echo "$RAM"
echo "$DISK"
'

# Скрываем курсор для красивого живого обновления без мерцания
tput civis 2>/dev/null
clear

FIRST_RUN=1

# Главный бесконечный цикл живого мониторинга
while true; do
    # 1. Параллельный сбор данных в фоне (Double-Buffering)
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

    # Ожидание завершения сбора данных
    wait >/dev/null 2>&1

    # 2. Мгновенная отрисовка поверх экрана (Flicker-Free: курсор в 0,0)
    printf '\033[H'

    echo -e "$LINE_EQ"
    printf "  ${YELLOW}%-17s   %-16s   %-10s   %-18s   %-31s   %-38s${RESET}\n" \
           "SERVER NAME" "IP ADDRESS" "Xray" "CPU" "RAM" "DISK"
    echo -e "$LINE_EQ"

    for idx in "${!SERVERS[@]}"; do
        ITEM="${SERVERS[$idx]}"
        NAME="${ITEM%%:*}"
        IP="${ITEM##*:}"
        RES_FILE="$TMP_DIR/$idx.res"

        if [[ ! -s "$RES_FILE" || $(wc -l < "$RES_FILE") -lt 4 ]]; then
            printf "  ${BOLD}${WHITE}%-17s${RESET}   ${DIM}%-16s${RESET}   ${RED}%-10s   %-18s   %-31s   %-38s${RESET}\n" \
                   "$NAME" "$IP" "🔴 OFFLINE" "🔴 UNREACHABLE" "🔴 UNREACHABLE" "🔴 UNREACHABLE"
        else
            # 1. Xray / VPN Online Status (ровно 8 символов ширины)
            VPN_STATUS=$(sed -n '1p' "$RES_FILE" | tr -d '\r')
            STATUS_TYPE=$(echo "$VPN_STATUS" | awk '{print $1}')
            ON_CNT=$(echo "$VPN_STATUS" | awk '{print $2}')
            TOT_CNT=$(echo "$VPN_STATUS" | awk '{print $3}')

            if [[ "$STATUS_TYPE" == "FAIL" ]]; then
                VPN_STR=$(printf "${RED}✖ %2d${RESET}${LIGHT_GRAY}/%-3d${RESET}" "$ON_CNT" "$TOT_CNT")
            elif [[ "$STATUS_TYPE" == "NONE" || -z "$STATUS_TYPE" || "$TOT_CNT" -eq 0 ]]; then
                VPN_STR="${LIGHT_GRAY}   —    ${RESET}"
            elif [[ "$ON_CNT" -eq 0 ]]; then
                # Светло-серый (как free в DISK)
                VPN_STR=$(printf "${LIGHT_GRAY}   0/%-3d${RESET}" "$TOT_CNT")
            else
                # Зелёная точка и светло-серая цифра total
                VPN_STR=$(printf "${GREEN}● %2d${RESET}${LIGHT_GRAY}/%-3d${RESET}" "$ON_CNT" "$TOT_CNT")
            fi

            # 2. CPU
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

            # Вывод строки сервера
            printf "  ${BOLD}${WHITE}%-17s${RESET}   ${CYAN}%-16s${RESET}   %-8b   " "$NAME" "$IP" "$VPN_STR"
            draw_stars "$CPU_PCT"
            printf "   %-10s   " "$RAM_STR"
            draw_stars "$RAM_PCT"
            printf "   %-17s   " "$DISK_STR"
            draw_stars "$DISK_PCT"
            printf "\n"
        fi
        echo -e "$LINE_EQ"
    done

    # Строка состояния и управления внизу
    NOW_TIME=$(date '+%H:%M:%S')
    printf "  ${LIGHT_GRAY}⏱ ${NOW_TIME}  |  ${WHITE}[Ctrl+C]${LIGHT_GRAY} Выход  |  ${WHITE}[F5 / Enter]${LIGHT_GRAY} Обновить сейчас  |  Автообновление: 5 сек${RESET}\n"

    # Ожидание 5 секунд или мгновенное обновление по нажатию клавиши (F5 / Enter / любая клавиша)
    read -t 5 -n 4 -s KEY 2>/dev/null
    if [[ "$KEY" == $'\x03' || "$KEY" == "q" || "$KEY" == "Q" ]]; then
        cleanup
    fi
done