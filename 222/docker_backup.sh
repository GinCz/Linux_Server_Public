#!/bin/bash
clear
# =============================================================================
#  docker_backup.sh
# =============================================================================
#  Version    : v2026-04-08
#  Author     : Ing. VladiMIR Bulantsev
#  GitHub     : https://github.com/GinCz/Linux_Server_Public
#  License    : MIT
# =============================================================================
#  = Rooted by VladiMIR | AI =
# =============================================================================

# --- Colors (only bright, high-contrast) ---
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

HR="${CY}══════════════════════════════════════════════════════════════════════════════════════════════${X}"
HRS="${CY}  ──────────────────────────────────────────────────────────────────────────────────────────${X}"

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

# --- [1] crypto-bot (Strategy A: VOLUMES) ---
CONTAINER_1_NAME="crypto-docker_crypto-bot"
CONTAINER_1_LABEL="crypto-bot"
CONTAINER_1_STRATEGY="volumes"
CONTAINER_1_COMPOSE_DIR="/root/crypto-docker"
CONTAINER_1_DATA_DIR="/root/crypto-docker"
CONTAINER_1_IMAGE="crypto-docker_crypto-bot"
CONTAINER_1_CLEANUP="
    find /root/crypto-docker -type f \( -name '*.log' -o -name '*.pyc' -o -name '*.tmp' -o -name '*.bak' \) -delete 2>/dev/null;
    find /root/crypto-docker -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null;
"

# --- [2] semaphore (Strategy A: VOLUMES) ---
CONTAINER_2_NAME="semaphore"
CONTAINER_2_LABEL="semaphore"
CONTAINER_2_STRATEGY="volumes"
CONTAINER_2_COMPOSE_DIR=""
CONTAINER_2_DATA_DIR="/root/semaphore-data"
CONTAINER_2_IMAGE="semaphore"
CONTAINER_2_CLEANUP="
    find /root/semaphore-data -type f \( -name '*.log' -o -name '*.tmp' -o -name '*.bak' -o -name '*.sh.orig' \) -delete 2>/dev/null;
"

# --- [3] amnezia-awg (Strategy B: COMMIT) ---
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
    COMPRESS="pigz"; COMPRESS_OPT="--use-compress-program=pigz"; COMP_LABEL="pigz ⚡"
else
    COMPRESS="gzip"; COMPRESS_OPT=""; COMP_LABEL="gzip"
fi

# =============================================================================
#  HELPERS
# =============================================================================

log()    { echo -e "${CY}$(date +%H:%M:%S)${X} $1"; }
log_ok() { echo -e "${GN}$(date +%H:%M:%S) ✅ $1${X}"; }
fail()   { echo -e "${RD}$(date +%H:%M:%S) ❌ $1${X}"; ERRORS=$((ERRORS+1)); }
info()   { echo -e "${YL}$(date +%H:%M:%S) ℹ️  $1${X}"; }

tg() {
    [ -z "$TOKEN" ] || [ -z "$CHAT_ID" ] && return
    curl -s "https://api.telegram.org/bot${TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}&text=$1&parse_mode=Markdown" >/dev/null
}

rotate() {
    ls -t "$1"/*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f
}

# --- Mini star progress bar (10 steps) ---
# Usage: star_progress <step> <total_steps> <label>
star_progress() {
    local step=$1 total=$2 label="$3"
    local filled=$(( step * 10 / total ))
    local bar=""
    for ((i=0; i<filled; i++));  do bar+="★"; done
    for ((i=filled; i<10; i++)); do bar+="☆"; done
    local pct=$(( step * 100 / total ))
    printf "          ${PK}[${YL}%s${PK}]${X} ${LY}%3d%%${X}  ${WH}%s${X}\n" "$bar" "$pct" "$label"
}

# --- Spinner during archiving ---
archive_spinner() {
    local label="$1" pid="$2" target="$3"
    local sp=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local i=0 elapsed=0
    while kill -0 "$pid" 2>/dev/null; do
        local sz=""
        [ -f "$target" ] && sz=$(du -sh "$target" 2>/dev/null | cut -f1)
        printf "\r          ${PK}%s${X} ${WH}packing${X} ${YL}%-18s${X}  ${CY}%ds${X}  ${OR}%-8s${X}" \
            "${sp[$i]}" "$label" "$elapsed" "${sz:-...}"
        i=$(( (i+1) % 10 ))
        elapsed=$((elapsed+1))
        sleep 1
    done
    printf "\r%-80s\r" " "
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

    star_progress 1 5 "starting backup..."
    log "  ${PK}🧹 ${label}:${X} cleanup dirty files..."
    eval "$cleanup" 2>/dev/null
    log "  ${LG}   └─ done${X} ${WH}(data dir: ${YL}${data_sz:-?}${WH})${X}"
    star_progress 2 5 "cleanup done"

    log "  ${CY}💾 ${label}:${X} saving docker image..."
    local img_full img_sz
    img_full=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -i "$image" | head -1)
    if [ -n "$img_full" ]; then
        img_sz=$(docker images --format "{{.Repository}}:{{.Tag}} {{.Size}}" | grep -i "$image" | head -1 | awk '{print $2}')
        log "  ${LG}   └─ image: ${YL}${img_full}${X} ${WH}(${OR}${img_sz}${WH})${X}"
        docker save "$img_full" | ${COMPRESS} > /tmp/${label}-image.tar.gz
    else
        info "${label}: image not found, skipping"
        touch /tmp/${label}-image.tar.gz
    fi
    star_progress 3 5 "image saved"

    [ -n "$compose_dir" ] && cd "$compose_dir" && docker-compose stop 2>/dev/null

    log "  ${OR}📦 ${label}:${X} creating archive ${WH}(${COMP_LABEL})${X}..."
    t_start=$(date +%s)
    tar -c ${COMPRESS_OPT} -f "$arch" "$data_dir" /tmp/${label}-image.tar.gz 2>/dev/null &
    local tar_pid=$!
    archive_spinner "$label" "$tar_pid" "$arch"
    wait "$tar_pid"
    t_end=$(date +%s)
    elapsed=$((t_end - t_start))
    rm -f /tmp/${label}-image.tar.gz
    [ -n "$compose_dir" ] && cd "$compose_dir" && docker-compose up -d 2>/dev/null
    star_progress 4 5 "archive done"

    if [ -s "$arch" ]; then
        sz=$(du -sh "$arch" | cut -f1)
        local raw_bytes speed=""
        raw_bytes=$(stat -c%s "$arch" 2>/dev/null || echo 0)
        [ "$elapsed" -gt 0 ] && speed=$(echo "scale=1; $raw_bytes / $elapsed / 1048576" | bc 2>/dev/null) && speed=" ${CY}@${X} ${LG}${speed} MB/s${X}"
        log_ok "${label}: ${LY}${arch}${X}"
        echo -e "          ${WH}├─ Size   : ${GN}${sz}${X}"
        echo -e "          ${WH}├─ Time   : ${CY}${elapsed}s${speed}${X}"
        echo -e "          ${WH}└─ Status : ${GN}OK ✓${X}"
        SUMMARY="${SUMMARY}📦 ${label}: ${sz} (${elapsed}s)%0A"
    else
        fail "${label}: archive FAILED or empty"
    fi

    rotate "$dest_dir"
    local cnt
    cnt=$(ls "$dest_dir"/*.tar.gz 2>/dev/null | wc -l)
    echo -e "          ${PK}📂 Archives: ${WH}${cnt}/${KEEP} kept${X}"
    local old_archives
    old_archives=$(ls -t "$dest_dir"/*.tar.gz 2>/dev/null | tail -n +2 | head -2)
    if [ -n "$old_archives" ]; then
        while IFS= read -r f; do
            local f_sz f_date
            f_sz=$(du -sh "$f" 2>/dev/null | cut -f1)
            f_date=$(stat -c%y "$f" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
            echo -e "          ${CY}   └─ ${OR}${f_sz}${X} ${WH}${f_date}${X} — $(basename "$f")"
        done <<< "$old_archives"
    fi
    star_progress 5 5 "DONE ✓"
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

    star_progress 1 4 "starting backup..."
    log "  ${PK}🧹 ${label}:${X} cleanup inside container..."
    docker exec "$label" sh -c "$cleanup" 2>/dev/null
    log "  ${LG}   └─ done${X}"
    star_progress 2 4 "cleanup done"

    log "  ${CY}📸 ${label}:${X} docker commit snapshot..."
    local commit_id
    commit_id=$(docker commit "$label" "${label}-backup:${DATE}" 2>/dev/null | cut -d: -f2 | cut -c1-12)

    if [ -n "$commit_id" ]; then
        log "  ${LG}   └─ commit: ${YL}${commit_id}${X}"
        log "  ${OR}📦 ${label}:${X} creating archive ${WH}(${COMP_LABEL})${X}..."
        t_start=$(date +%s)
        docker save "${label}-backup:${DATE}" | ${COMPRESS} > "$arch" &
        local tar_pid=$!
        archive_spinner "$label" "$tar_pid" "$arch"
        wait "$tar_pid"
        t_end=$(date +%s)
        elapsed=$((t_end - t_start))
        docker rmi "${label}-backup:${DATE}" >/dev/null 2>&1
        star_progress 3 4 "archive done"

        if [ -s "$arch" ]; then
            sz=$(du -sh "$arch" | cut -f1)
            local raw_bytes speed=""
            raw_bytes=$(stat -c%s "$arch" 2>/dev/null || echo 0)
            [ "$elapsed" -gt 0 ] && speed=$(echo "scale=1; $raw_bytes / $elapsed / 1048576" | bc 2>/dev/null) && speed=" ${CY}@${X} ${LG}${speed} MB/s${X}"
            log_ok "${label}: ${LY}${arch}${X}"
            echo -e "          ${WH}├─ Size   : ${GN}${sz}${X}"
            echo -e "          ${WH}├─ Time   : ${CY}${elapsed}s${speed}${X}"
            echo -e "          ${WH}└─ Status : ${GN}OK ✓${X}"
            SUMMARY="${SUMMARY}📦 ${label}: ${sz} (${elapsed}s)%0A"
        else
            fail "${label}: archive FAILED (empty file)"
        fi
    else
        fail "${label}: docker commit FAILED (container not running?)"
    fi

    rotate "$dest_dir"
    local cnt
    cnt=$(ls "$dest_dir"/*.tar.gz 2>/dev/null | wc -l)
    echo -e "          ${PK}📂 Archives: ${WH}${cnt}/${KEEP} kept${X}"
    star_progress 4 4 "DONE ✓"
    echo
}

# --- Container section header ---
print_header() {
    local num="$1" label="$2" strategy="$3"
    echo -e "$HR"
    echo -e "  ${CY}[${num}/${TOTAL_CONTAINERS}]${X} ${YL}${label}${X}   ${WH}strategy: ${PK}${strategy}${X}"
    echo -e "$HRS"
}

# =============================================================================
#  MAIN
# =============================================================================

echo -e "$HR"
echo -e "  ${CY}🐳 DOCKER BACKUP   ${YL}${SERVER_LABEL}${X}"
echo -e "  ${CY}📅 $(date '+%Y-%m-%d %H:%M:%S')   ${WH}compression: ${GN}${COMP_LABEL}${X}"
echo -e "  ${CY}🖥️  Hostname: ${PK}$(hostname)${X}   ${WH}IP: ${YL}$(hostname -I | awk '{print $1}')${X}"
echo -e "  ${CY}💿 Disk free: ${GN}$(df -h /BACKUP 2>/dev/null | awk 'NR==2{print $4}' || df -h / | awk 'NR==2{print $4}')${X}   ${WH}Load: ${LY}$(uptime | awk -F'load average:' '{print $2}' | xargs)${X}"
echo -e "  ${CY}📦 Containers: ${WH}${TOTAL_CONTAINERS}${X}   ${CY}Keep: ${WH}${KEEP}${X}   ${CY}Root: ${YL}${BACKUP_ROOT}${X}"
echo -e "$HR"
echo

if ! command -v pigz &>/dev/null; then
    info "pigz not found — installing..."
    apt-get install -y pigz -qq 2>/dev/null
    COMPRESS="pigz"; COMPRESS_OPT="--use-compress-program=pigz"; COMP_LABEL="pigz ⚡"
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
    echo -e "  ${GN}✅  ALL DONE — NO ERRORS${X}"
    MSG="✅ *DOCKER BACKUP OK* | ${SERVER_LABEL}%0A%0A${SUMMARY}%0A💾 Total: ${TOTAL_SZ}%0A⏱ Time: ${TOTAL_ELAPSED}s%0A🕐 $(date '+%Y-%m-%d %H:%M')"
else
    echo -e "  ${RD}⚠️   COMPLETED WITH ${ERRORS} ERROR(S)${X}"
    MSG="⚠️ *DOCKER BACKUP ERRORS* | ${SERVER_LABEL}%0AErrors: ${ERRORS}%0A%0A${SUMMARY}%0A🕐 $(date '+%Y-%m-%d %H:%M')"
fi
echo -e "  ${WH}├─ Total size  : ${GN}${TOTAL_SZ}${X}"
echo -e "  ${WH}├─ Total time  : ${CY}${TOTAL_ELAPSED}s${X}"
echo -e "  ${WH}├─ Errors      : $([ $ERRORS -eq 0 ] && echo "${GN}0${X}" || echo "${RD}${ERRORS}${X}")${X}"
echo -e "  ${WH}└─ Finished at : ${YL}$(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "$HR"
echo -e "${YL}              = Rooted by VladiMIR | AI =${X}"
echo -e "$HR"
echo

tg "$MSG"
