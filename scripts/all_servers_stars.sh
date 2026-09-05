#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█  CLUSTER RESOURCE & WIREGUARD MONITOR (10-STAR) v3.1  █▓▒░
#  Author  : Vladimir Bulantsev (GinCz)
#  GitHub  : https://github.com/GinCz/Secret_Privat
# ==========================================================================================
set +m
clear

# ANSI Цвета
CYAN="\e[96m"
WHITE="\e[97m"
YELLOW="\e[93m"
GREEN="\e[92m"
RED="\e[91m"
DIM="\e[90m"
RESET="\e[0m"
BOLD="\e[1m"

# Функция генерации шкалы из 10 звёздочек
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

# Список серверов
SERVERS=(
    "222-DE-NetCup:152.53.182.222"
    "109-RU-FastVDS:212.109.223.109"
    "alex47:212.34.148.51"
    "4ton237:144.124.228.237"
    "tatra9:144.124.232.9"
    "shahin227:144.124.228.227"
    "stolb24:144.124.239.24"
    "pilik33:195.63.138.33"
    "ilya176:146.103.110.176"
    "so38:144.124.233.38"
        "aws12:18.195.117.12"
        "ionos38:82.223.116.38"
)

LOCAL_IPS=$(hostname -I 2>/dev/null)
is_local() {
    local ip="$1"
    [[ " $LOCAL_IPS " == *" $ip "* ]]
}

DATE_NOW=$(date '+%Y-%m-%d %H:%M:%S')
LINE_TOP="${CYAN}$(printf '═%.0s' {1..128})${RESET}"
LINE_DIV="${DIM}$(printf '─%.0s' {1..128})${RESET}"

echo -e "$LINE_TOP"
printf "  ${BOLD}${WHITE}%-75s${RESET} ${DIM}%49s${RESET}\n" "⭐ CLUSTER HARDWARE & WIREGUARD MONITOR" "Generated: $DATE_NOW"
echo -e "$LINE_TOP"
printf "  ${YELLOW}%-17s %-16s %-12s %-19s %-28s %-32s${RESET}\n" \
       "SERVER NAME" "IP ADDRESS" "WG ONLINE" "CPU USAGE (10-★)" "RAM: USED / TOTAL (10-★)" "DISK: FREE / TOTAL (10-★)"
echo -e "$LINE_TOP"

# Временная папка для параллельного сбора данных
TMP_DIR=$(mktemp -d /tmp/cluster_mon.XXXXXX 2>/dev/null || mktemp -d)

# Команда сбора данных
CMD='
NOW=$(date +%s)

# 1. WireGuard / AmneziaWG Online
WG_ACT="-"
DOC=$(docker ps --format "{{.Names}}" 2>/dev/null | grep -Ei "amnezia.?awg|awg.?amnezia|amneziawg" | head -1)
if [ -n "$DOC" ]; then
    WG_ACT=$(docker exec "$DOC" cat /opt/amnezia/awg/clientsTable 2>/dev/null | grep -Eo "[0-9]+(s|m) ago" | wc -l)
elif command -v wg >/dev/null 2>&1 || command -v awg >/dev/null 2>&1; then
    WG_ACT=$( { wg show all latest-handshakes 2>/dev/null || awg show all latest-handshakes 2>/dev/null; } | awk -v n="$NOW" '\''$3>0 && (n-$3)<180 {c++} END{print c+0}'\'')
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

echo "$WG_ACT"
echo "$CPU"
echo "$RAM"
echo "$DISK"
'

# Запуск параллельного опроса с отключенным выводом job-control
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

# Ожидание завершения всех потоков
wait >/dev/null 2>&1

# Отрисовка результатов в строгом порядке
for idx in "${!SERVERS[@]}"; do
    ITEM="${SERVERS[$idx]}"
    NAME="${ITEM%%:*}"
    IP="${ITEM##*:}"
    RES_FILE="$TMP_DIR/$idx.res"

    if [[ ! -s "$RES_FILE" || $(wc -l < "$RES_FILE") -lt 4 ]]; then
        printf "  ${BOLD}${WHITE}%-17s${RESET} ${DIM}%-16s${RESET} ${RED}%-12s %-19s %-28s %-32s${RESET}\n" \
               "$NAME" "$IP" "🔴 OFFLINE" "🔴 UNREACHABLE" "🔴 UNREACHABLE" "🔴 UNREACHABLE"
    else
        # 1. WireGuard Online
        WG_VAL=$(sed -n '1p' "$RES_FILE" | tr -d '\r')
        if [[ "$WG_VAL" == "-" || -z "$WG_VAL" ]]; then
            WG_STR="${DIM}   —    ${RESET}"
        elif [[ "$WG_VAL" -eq 0 ]]; then
            WG_STR="${DIM}  0 on  ${RESET}"
        else
            WG_STR="${GREEN}● ${WG_VAL} on  ${RESET}"
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
        printf "  ${BOLD}${WHITE}%-17s${RESET} ${CYAN}%-16s${RESET} %-12b " "$NAME" "$IP" "$WG_STR"
        draw_stars "$CPU_PCT"
        printf "  %-10s " "$RAM_STR"
        draw_stars "$RAM_PCT"
        printf "  %-16s " "$DISK_STR"
        draw_stars "$DISK_PCT"
        printf "\n"
    fi
    echo -e "$LINE_DIV"
done

# Очистка временных данных
rm -rf "$TMP_DIR"

echo -e "$LINE_TOP"
echo -e "  ${DIM}Легенда нагрузки:${RESET} ${GREEN}★ <75% (Норма)${RESET}  ${YELLOW}★ 75-89% (Внимание)${RESET}  ${RED}★ ≥90% (Критично)${RESET}"
echo -e "  ${DIM}WireGuard:${RESET} ${GREEN}● N on${RESET} ${DIM}(активен <3 мин)${RESET}  ${DIM}0 on (нет клиентов)${RESET}  ${DIM}— (WG не установлен)${RESET}\n"