#!/bin/bash
clear
# =============================================================================
#  docker_backup.sh
# =============================================================================
#  = Rooted by VladiMIR | AI =
# -----------------------------------------------------------------------------
#  Version    : v2026-04-08g
#  Author     : Ing. VladiMIR Bulantsev
#  GitHub     : https://github.com/GinCz/Linux_Server_Public
#  License    : MIT
# =============================================================================

# --- Colors (bright only) ---
CY="\033[1;96m"         # bright cyan
GN="\033[1;92m"         # bright green
LG="\033[38;5;120m"     # light green
YL="\033[1;93m"         # bright yellow
LY="\033[38;5;228m"     # light yellow
PK="\033[1;95m"         # bright pink/magenta
RD="\033[1;91m"         # bright red
OR="\033[38;5;214m"     # orange
WH="\033[1;97m"         # bright white
X="\033[0m"             # reset

# HR = 95x ═  (fits 95-col terminal with 2-space indent)
HR="${CY}\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550${X}"

# =============================================================================
#  CONFIG
# =============================================================================

TOKEN=""
CHAT_ID=""
BACKUP_ROOT="/BACKUP/222/docker"
KEEP=3
SERVER_LABEL="222-DE-NetCup"

# =============================================================================
#  CONTAINERS CONFIG
# =============================================================================

CONTAINER_1_LABEL="crypto-bot"
CONTAINER_1_STRATEGY="volumes"
CONTAINER_1_COMPOSE_DIR="/root/crypto-docker"
CONTAINER_1_DATA_DIR="/root/crypto-docker"
CONTAINER_1_IMAGE="crypto-docker_crypto-bot"
CONTAINER_1_CLEANUP="
    find /root/crypto-docker -type f \( -name '*.log' -o -name '*.pyc' -o -name '*.tmp' -o -name '*.bak' \) -delete 2>/dev/null;
    find /root/crypto-docker -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null;
"

CONTAINER_2_LABEL="semaphore"
CONTAINER_2_STRATEGY="volumes"
CONTAINER_2_COMPOSE_DIR=""
CONTAINER_2_DATA_DIR="/root/semaphore-data"
CONTAINER_2_IMAGE="semaphore"
CONTAINER_2_CLEANUP="
    find /root/semaphore-data -type f \( -name '*.log' -o -name '*.tmp' -o -name '*.bak' -o -name '*.sh.orig' \) -delete 2>/dev/null;
"

CONTAINER_3_NAME="amnezia-awg"
CONTAINER_3_LABEL="amnezia-awg"
CONTAINER_3_STRATEGY="commit"
CONTAINER_3_CLEANUP="
    find /tmp -type f -delete 2>/dev/null;
    find /var/log -type f \( -name '*.log' -o -name '*.gz' \) -delete 2>/dev/null;
"

# =============================================================================
#  INTERNAL VARIABLES
# =============================================================================

DATE=$(date +%Y-%m-%d_%H-%M)
ERRORS=0
SUMMARY=""
TOTAL_CONTAINERS=3
START_TIME=$(date +%s)

if command -v pigz &>/dev/null; then
    COMPRESS="pigz"; COMPRESS_OPT="--use-compress-program=pigz"; COMP_LABEL="pigz \u26a1"
else
    COMPRESS="gzip"; COMPRESS_OPT=""; COMP_LABEL="gzip"
fi

# =============================================================================
#  HELPERS
# =============================================================================

log()    { echo -e "${CY}$(date +%H:%M:%S)${X} $1"; }
log_ok() { echo -e "${GN}$(date +%H:%M:%S) \u2714 $1${X}"; }
fail()   { echo -e "${RD}$(date +%H:%M:%S) \u2718 $1${X}"; ERRORS=$((ERRORS+1)); }
info()   { echo -e "${YL}$(date +%H:%M:%S) \u25ba $1${X}"; }

tg() {
    [ -z "$TOKEN" ] || [ -z "$CHAT_ID" ] && return
    curl -s "https://api.telegram.org/bot${TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}&text=$1&parse_mode=Markdown" >/dev/null
}

rotate() {
    ls -t "$1"/*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f
}

# =============================================================================
#  BACKUP: VOLUMES strategy
# =============================================================================
backup_volumes() {
    local label="$1" image="$2" compose_dir="$3" data_dir="$4"
    local cleanup="$5" dest_dir="$6"
    local arch="${dest_dir}/${label}_${DATE}.tar.gz"
    local sz t_start t_end elapsed

    mkdir -p "$dest_dir"
    local data_sz=""
    [ -d "$data_dir" ] && data_sz=$(du -sh "$data_dir" 2>/dev/null | cut -f1)

    log "  ${PK}\u25bc${X} ${YL}${label}${X} cleanup...  ${WH}data: ${LY}${data_sz:-?}${X}"
    eval "$cleanup" 2>/dev/null

    log "  ${CY}\u25a6${X} ${YL}${label}${X} saving image..."
    local img_full img_sz
    img_full=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -i "$image" | head -1)
    if [ -n "$img_full" ]; then
        img_sz=$(docker images --format "{{.Repository}}:{{.Tag}} {{.Size}}" | grep -i "$image" | head -1 | awk '{print $2}')
        log "     ${LG}\u2514\u2500 ${YL}${img_full}${X} ${WH}(${OR}${img_sz}${WH})${X}"
        docker save "$img_full" | ${COMPRESS} > /tmp/${label}-image.tar.gz
    else
        info "${label}: image not found, skipping"
        touch /tmp/${label}-image.tar.gz
    fi

    [ -n "$compose_dir" ] && cd "$compose_dir" && docker-compose stop 2>/dev/null

    log "  ${OR}\u25a3${X} ${YL}${label}${X} archiving ${WH}(${COMP_LABEL})${X}..."
    t_start=$(date +%s)
    tar -c ${COMPRESS_OPT} -f "$arch" "$data_dir" /tmp/${label}-image.tar.gz 2>/dev/null
    t_end=$(date +%s)
    elapsed=$((t_end - t_start))
    rm -f /tmp/${label}-image.tar.gz
    [ -n "$compose_dir" ] && cd "$compose_dir" && docker-compose up -d 2>/dev/null

    if [ -s "$arch" ]; then
        sz=$(du -sh "$arch" | cut -f1)
        local raw_bytes speed=""
        raw_bytes=$(stat -c%s "$arch" 2>/dev/null || echo 0)
        [ "$elapsed" -gt 0 ] && speed=$(echo "scale=1; $raw_bytes / $elapsed / 1048576" | bc 2>/dev/null) && speed="  ${CY}@ ${LG}${speed} MB/s${X}"
        log_ok "${YL}${label}${GN}: ${LY}$(basename "$arch")${X}"
        echo -e "     ${WH}\u251c\u2500 Size   : ${GN}${sz}${X}"
        echo -e "     ${WH}\u251c\u2500 Time   : ${CY}${elapsed}s${speed}${X}"
        echo -e "     ${WH}\u2514\u2500 Status : ${GN}OK \u2713${X}"
        SUMMARY="${SUMMARY}[OK] ${label}: ${sz} (${elapsed}s)%0A"
    else
        fail "${label}: archive FAILED or empty"
    fi

    rotate "$dest_dir"
    local cnt
    cnt=$(ls "$dest_dir"/*.tar.gz 2>/dev/null | wc -l)
    printf "     ${PK}\u25a4 Archives: ${WH}%d/%d kept${X}" "$cnt" "$KEEP"
    local old_archives
    old_archives=$(ls -t "$dest_dir"/*.tar.gz 2>/dev/null | tail -n +2 | head -2)
    if [ -n "$old_archives" ]; then
        echo
        while IFS= read -r f; do
            local f_sz f_date
            f_sz=$(du -sh "$f" 2>/dev/null | cut -f1)
            f_date=$(stat -c%y "$f" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
            echo -e "        ${CY}\u2514\u2500 ${OR}${f_sz}${X} ${WH}${f_date}${X} \u2014 $(basename "$f")"
        done <<< "$old_archives"
    else
        echo
    fi
    echo
}

# =============================================================================
#  BACKUP: COMMIT strategy
# =============================================================================
backup_commit() {
    local label="$1" cleanup="$2" dest_dir="$3"
    local arch="${dest_dir}/${label}_${DATE}.tar.gz"
    local sz t_start t_end elapsed

    mkdir -p "$dest_dir"

    log "  ${PK}\u25bc${X} ${YL}${label}${X} cleanup inside container..."
    docker exec "$label" sh -c "$cleanup" 2>/dev/null

    log "  ${CY}\u25cf${X} ${YL}${label}${X} docker commit snapshot..."
    local commit_id
    commit_id=$(docker commit "$label" "${label}-backup:${DATE}" 2>/dev/null | cut -d: -f2 | cut -c1-12)

    if [ -n "$commit_id" ]; then
        log "     ${LG}\u2514\u2500 commit: ${YL}${commit_id}${X}"
        log "  ${OR}\u25a3${X} ${YL}${label}${X} archiving ${WH}(${COMP_LABEL})${X}..."
        t_start=$(date +%s)
        docker save "${label}-backup:${DATE}" | ${COMPRESS} > "$arch"
        t_end=$(date +%s)
        elapsed=$((t_end - t_start))
        docker rmi "${label}-backup:${DATE}" >/dev/null 2>&1

        if [ -s "$arch" ]; then
            sz=$(du -sh "$arch" | cut -f1)
            local raw_bytes speed=""
            raw_bytes=$(stat -c%s "$arch" 2>/dev/null || echo 0)
            [ "$elapsed" -gt 0 ] && speed=$(echo "scale=1; $raw_bytes / $elapsed / 1048576" | bc 2>/dev/null) && speed="  ${CY}@ ${LG}${speed} MB/s${X}"
            log_ok "${YL}${label}${GN}: ${LY}$(basename "$arch")${X}"
            echo -e "     ${WH}\u251c\u2500 Size   : ${GN}${sz}${X}"
            echo -e "     ${WH}\u251c\u2500 Time   : ${CY}${elapsed}s${speed}${X}"
            echo -e "     ${WH}\u2514\u2500 Status : ${GN}OK \u2713${X}"
            SUMMARY="${SUMMARY}[OK] ${label}: ${sz} (${elapsed}s)%0A"
        else
            fail "${label}: archive FAILED (empty file)"
        fi
    else
        fail "${label}: docker commit FAILED (container not running?)"
    fi

    rotate "$dest_dir"
    local cnt
    cnt=$(ls "$dest_dir"/*.tar.gz 2>/dev/null | wc -l)
    echo -e "     ${PK}\u25a4 Archives: ${WH}${cnt}/${KEEP} kept${X}"
}

# --- Section header ---
print_header() {
    echo -e "$HR"
    echo -e "  ${CY}[$1/$TOTAL_CONTAINERS]${X} ${YL}$2${X}   ${WH}strategy: ${PK}$3${X}"
}

# =============================================================================
#  MAIN
# =============================================================================

echo -e "$HR"
echo -e "  ${CY}\u2756 DOCKER BACKUP${X}  ${WH}|||${X}  ${YL}${SERVER_LABEL}${X}  ${WH}|||${X}  ${WH}IP: $(hostname -I | awk '{print $1}')${X}  ${WH}|||${X}  ${YL}= Rooted by VladiMIR | AI =${X}"
echo -e "  ${WH}|||${X} ${CY}$(date '+%Y-%m-%d')${X}  ${WH}|||${X}  ${CY}$(date '+%H:%M:%S')${X}   ${WH}compression: ${GN}${COMP_LABEL}${X}"
echo -e "  ${CY}\u25ba Disk free: ${GN}$(df -h /BACKUP 2>/dev/null | awk 'NR==2{print $4}' || df -h / | awk 'NR==2{print $4}')${X}   ${WH}Load: ${LY}$(uptime | awk -F'load average:' '{print $2}' | xargs)${X}"
echo -e "  ${CY}\u25a3 Containers: ${WH}${TOTAL_CONTAINERS}${X}   ${CY}Keep: ${WH}${KEEP}${X}   ${CY}Root: ${YL}${BACKUP_ROOT}${X}"

if ! command -v pigz &>/dev/null; then
    echo -e "$HR"
    info "pigz not found \u2014 installing..."
    apt-get install -y pigz -qq 2>/dev/null
    COMPRESS="pigz"; COMPRESS_OPT="--use-compress-program=pigz"; COMP_LABEL="pigz \u26a1"
fi

print_header "1" "$CONTAINER_1_LABEL" "$CONTAINER_1_STRATEGY"
backup_volumes \
    "$CONTAINER_1_LABEL" "$CONTAINER_1_IMAGE" \
    "$CONTAINER_1_COMPOSE_DIR" "$CONTAINER_1_DATA_DIR" \
    "$CONTAINER_1_CLEANUP" "${BACKUP_ROOT}/crypto"

print_header "2" "$CONTAINER_2_LABEL" "$CONTAINER_2_STRATEGY"
backup_volumes \
    "$CONTAINER_2_LABEL" "$CONTAINER_2_IMAGE" \
    "$CONTAINER_2_COMPOSE_DIR" "$CONTAINER_2_DATA_DIR" \
    "$CONTAINER_2_CLEANUP" "${BACKUP_ROOT}/semaphore"

print_header "3" "$CONTAINER_3_LABEL" "$CONTAINER_3_STRATEGY"
backup_commit \
    "$CONTAINER_3_NAME" \
    "$CONTAINER_3_CLEANUP" \
    "${BACKUP_ROOT}/amnezia"

# =============================================================================
#  SUMMARY
# =============================================================================

END_TIME=$(date +%s)
TOTAL_ELAPSED=$((END_TIME - START_TIME))
TOTAL_SZ=$(du -sh "${BACKUP_ROOT}/" 2>/dev/null | cut -f1)

echo -e "$HR"
if [ "$ERRORS" -eq 0 ]; then
    echo -e "  ${GN}\u2714  ALL DONE \u2014 NO ERRORS${X}"
    MSG="\u2705 *DOCKER BACKUP OK* | ${SERVER_LABEL}%0A%0A${SUMMARY}%0ATotal: ${TOTAL_SZ}%0ATime: ${TOTAL_ELAPSED}s%0A$(date '+%Y-%m-%d %H:%M')"
else
    echo -e "  ${RD}\u26a0  COMPLETED WITH ${ERRORS} ERROR(S)${X}"
    MSG="\u26a0 *DOCKER BACKUP ERRORS* | ${SERVER_LABEL}%0AErrors: ${ERRORS}%0A%0A${SUMMARY}%0A$(date '+%Y-%m-%d %H:%M')"
fi
echo -e "  ${WH}\u251c\u2500 Total size  : ${GN}${TOTAL_SZ}${X}"
echo -e "  ${WH}\u251c\u2500 Total time  : ${CY}${TOTAL_ELAPSED}s${X}"
echo -e "  ${WH}\u251c\u2500 Errors      : $([ $ERRORS -eq 0 ] && echo "${GN}0${X}" || echo "${RD}${ERRORS}${X}")${X}"
echo -e "  ${WH}\u2514\u2500 Finished at : ${YL}$(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "$HR"
echo -e "              ${YL}= Rooted by VladiMIR | AI =${X}"
echo

tg "$MSG"
