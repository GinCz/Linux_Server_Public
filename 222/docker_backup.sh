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
#
#  DESCRIPTION
#  -----------
#  Universal Docker backup script for any Linux server.
#  Supports two backup strategies per container:
#
#    Strategy A  — VOLUMES  (recommended)
#                  Saves Docker image + host-mounted data directory.
#                  Use when container stores data in a host-side volume.
#                  Restore: docker load < image.tar.gz && docker-compose up -d
#
#    Strategy B  — COMMIT   (fallback)
#                  Uses "docker commit" to snapshot the entire container layer.
#                  Use when container stores data INSIDE (no host volume).
#                  Restore: docker load < snapshot.tar.gz && docker run ...
#
#  COMPRESSION
#  -----------
#  Uses pigz (parallel gzip) if available for maximum speed on multi-core CPUs.
#  Falls back to standard gzip automatically.
#  Install pigz:  apt install pigz
#
#  ROTATION
#  --------
#  Keeps the last KEEP=3 archives per container. Older ones are deleted.
#
#  NOTIFICATIONS
#  -------------
#  Sends a Telegram message on completion (success or error).
#  TOKEN and CHAT_ID are stored in Secret_Privat/telegram.md (private repo).
#  Set them directly on the server — never commit tokens to public repos!
#
#  USAGE
#  -----
#  Manual run:   bash /root/docker_backup.sh
#  Alias:        f5bot
#  Cron (03:00): 0 3 * * * /root/docker_backup.sh >> /var/log/docker_backup.log 2>&1
#
#  HOW TO ADD A NEW CONTAINER
#  --------------------------
#  1. Add a new block in the "CONTAINERS CONFIG" section below.
#  2. Choose strategy: VOLUMES or COMMIT.
#  3. For VOLUMES: set CONTAINER_NAME, IMAGE_NAME, DATA_DIR, COMPOSE_DIR.
#  4. For COMMIT:  set CONTAINER_NAME only.
#
# =============================================================================
#  = Rooted by VladiMIR | AI =
# =============================================================================

# --- Colors (максимально яркие) ---
CYAN="\033[1;96m"       # яркий циан
GREEN="\033[1;92m"      # яркий зелёный
YELLOW="\033[1;93m"     # яркий жёлтый
RED="\033[1;91m"        # яркий красный
PINK="\033[1;95m"       # яркий розовый/магента
BLUE="\033[1;94m"       # яркий синий
WHITE="\033[1;97m"      # яркий белый
ORANGE="\033[38;5;214m" # оранжевый (256-color)
X="\033[0m"             # сброс

# --- Разделители ---
HR_C="${CYAN}╔══════════════════════════════════════════════════════════════════════════════════════════════╗${X}"
HR_M="${CYAN}╠══════════════════════════════════════════════════════════════════════════════════════════════╣${X}"
HR_B="${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════════════╝${X}"
HR_S="${CYAN}║──────────────────────────────────────────────────────────────────────────────────────────────║${X}"

# =============================================================================
#  CONFIG
# =============================================================================

# Telegram notification — set TOKEN and CHAT_ID on server, NOT here!
# See: Secret_Privat/telegram.md (private repo)
TOKEN=""       # e.g.: 1234567890:AAxxxx...
CHAT_ID=""     # e.g.: 261784949

# Backup destination root
BACKUP_ROOT="/BACKUP/222/docker"

# How many archives to keep per container (older ones are deleted)
KEEP=3

# Server label for Telegram messages
SERVER_LABEL="222-DE-NetCup"

# =============================================================================
#  CONTAINERS CONFIG
#  One block per container. Add/remove as needed.
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
CURRENT_CONTAINER=0
START_TIME=$(date +%s)

# Use pigz if available — much faster on multi-core CPUs
if command -v pigz &>/dev/null; then
    COMPRESS="pigz"
    COMPRESS_OPT="--use-compress-program=pigz"
    COMP_LABEL="pigz ⚡"
else
    COMPRESS="gzip"
    COMPRESS_OPT=""
    COMP_LABEL="gzip"
fi

# =============================================================================
#  HELPER FUNCTIONS
# =============================================================================

log()    { echo -e "${CYAN}$(date +%H:%M:%S)${X} $1"; }
log_ok() { echo -e "${GREEN}$(date +%H:%M:%S) ✅ $1${X}"; }
fail()   { echo -e "${RED}$(date +%H:%M:%S) ❌ $1${X}"; ERRORS=$((ERRORS+1)); }
info()   { echo -e "${YELLOW}$(date +%H:%M:%S) ℹ️  $1${X}"; }

tg() {
    [ -z "$TOKEN" ] || [ -z "$CHAT_ID" ] && return
    curl -s "https://api.telegram.org/bot${TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}&text=$1&parse_mode=Markdown" >/dev/null
}

rotate() {
    ls -t "$1"/*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f
}

# --- Прогрессбар во время архивации ---
progress_bar() {
    local label="$1"
    local pid="$2"
    local target_path="$3"
    local chars=("⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷")
    local i=0
    local elapsed=0
    printf "${PINK}          ⏳ Archiving %-20s " "$label"
    while kill -0 "$pid" 2>/dev/null; do
        local sz=""
        [ -f "$target_path" ] && sz=$(du -sh "$target_path" 2>/dev/null | cut -f1)
        printf "\r${PINK}          ${chars[$i]} Archiving ${YELLOW}%-20s${PINK} elapsed: ${WHITE}%ds${PINK}  size so far: ${ORANGE}%-8s${X}" \
            "$label" "$elapsed" "${sz:-...}"
        i=$(( (i+1) % 8 ))
        elapsed=$((elapsed+1))
        sleep 1
    done
    printf "\r%-80s\r" " "  # очистка строки прогресса
}

# backup_volumes LABEL IMAGE COMPOSE_DIR DATA_DIR CLEANUP DEST_DIR
backup_volumes() {
    local label="$1" image="$2" compose_dir="$3" data_dir="$4"
    local cleanup="$5" dest_dir="$6"
    local arch="${dest_dir}/${label}_${DATE}.tar.gz"
    local sz t_start t_end elapsed

    mkdir -p "$dest_dir"

    # Инфо о данных
    local data_sz=""
    [ -d "$data_dir" ] && data_sz=$(du -sh "$data_dir" 2>/dev/null | cut -f1)

    log "  ${PINK}🧹 ${label}:${X} cleanup dirty files..."
    local cleaned
    cleaned=$(eval "$cleanup" 2>&1 | wc -l)
    log "  ${GREEN}   └─ done${X} ${WHITE}(data dir: ${YELLOW}${data_sz:-?}${WHITE})${X}"

    log "  ${BLUE}💾 ${label}:${X} saving docker image..."
    local img_full
    img_full=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -i "$image" | head -1)
    if [ -n "$img_full" ]; then
        local img_sz
        img_sz=$(docker images --format "{{.Repository}}:{{.Tag}} {{.Size}}" | grep -i "$image" | head -1 | awk '{print $2}')
        log "  ${GREEN}   └─ image: ${YELLOW}${img_full}${X} ${WHITE}(${ORANGE}${img_sz}${WHITE})${X}"
        docker save "$img_full" | ${COMPRESS} > /tmp/${label}-image.tar.gz
    else
        info "  ${label}: image not found, skipping image save"
        touch /tmp/${label}-image.tar.gz
    fi

    [ -n "$compose_dir" ] && cd "$compose_dir" && docker-compose stop 2>/dev/null

    log "  ${ORANGE}📦 ${label}:${X} creating archive ${WHITE}(${COMP_LABEL})${X}..."
    t_start=$(date +%s)

    tar -c ${COMPRESS_OPT} -f "$arch" \
        "$data_dir" \
        /tmp/${label}-image.tar.gz \
        2>/dev/null &
    local tar_pid=$!
    progress_bar "$label" "$tar_pid" "$arch"
    wait "$tar_pid"

    t_end=$(date +%s)
    elapsed=$((t_end - t_start))
    rm -f /tmp/${label}-image.tar.gz

    [ -n "$compose_dir" ] && cd "$compose_dir" && docker-compose up -d 2>/dev/null

    if [ -s "$arch" ]; then
        sz=$(du -sh "$arch" | cut -f1)
        local speed=""
        local raw_bytes
        raw_bytes=$(stat -c%s "$arch" 2>/dev/null || echo 0)
        [ "$elapsed" -gt 0 ] && speed=$(echo "scale=1; $raw_bytes / $elapsed / 1048576" | bc 2>/dev/null) && speed=" @ ${speed} MB/s"
        log_ok "  ${label}: ${YELLOW}${arch}${X}"
        echo -e "          ${WHITE}├─ Size   : ${GREEN}${sz}${X}"
        echo -e "          ${WHITE}├─ Time   : ${CYAN}${elapsed}s${speed}${X}"
        echo -e "          ${WHITE}└─ Status : ${GREEN}OK ✓${X}"
        SUMMARY="${SUMMARY}📦 ${label}: ${sz} (${elapsed}s)%0A"
    else
        fail "${label}: archive FAILED or empty"
    fi

    rotate "$dest_dir"
    local cnt
    cnt=$(ls "$dest_dir"/*.tar.gz 2>/dev/null | wc -l)
    local old_archives
    old_archives=$(ls -t "$dest_dir"/*.tar.gz 2>/dev/null | tail -n +2 | head -2)
    echo -e "          ${PINK}📂 Archives: ${WHITE}${cnt}/${KEEP} kept${X}"
    if [ -n "$old_archives" ]; then
        while IFS= read -r f; do
            local f_sz f_date
            f_sz=$(du -sh "$f" 2>/dev/null | cut -f1)
            f_date=$(stat -c%y "$f" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
            echo -e "          ${CYAN}   └─ ${f_sz}${X} ${WHITE}${f_date}${X} — $(basename "$f")"
        done <<< "$old_archives"
    fi
    echo
}

# backup_commit LABEL CLEANUP DEST_DIR
backup_commit() {
    local label="$1" cleanup="$2" dest_dir="$3"
    local arch="${dest_dir}/${label}_${DATE}.tar.gz"
    local sz t_start t_end elapsed

    mkdir -p "$dest_dir"

    log "  ${PINK}🧹 ${label}:${X} cleanup inside container..."
    docker exec "$label" sh -c "$cleanup" 2>/dev/null
    log "  ${GREEN}   └─ done${X}"

    log "  ${BLUE}📸 ${label}:${X} docker commit snapshot..."
    local commit_id
    commit_id=$(docker commit "$label" "${label}-backup:${DATE}" 2>/dev/null | cut -d: -f2 | cut -c1-12)

    if [ -n "$commit_id" ]; then
        log "  ${GREEN}   └─ commit: ${YELLOW}${commit_id}${X}"

        log "  ${ORANGE}📦 ${label}:${X} creating archive ${WHITE}(${COMP_LABEL})${X}..."
        t_start=$(date +%s)

        docker save "${label}-backup:${DATE}" | ${COMPRESS} > "$arch" &
        local tar_pid=$!
        progress_bar "$label" "$tar_pid" "$arch"
        wait "$tar_pid"

        t_end=$(date +%s)
        elapsed=$((t_end - t_start))
        docker rmi "${label}-backup:${DATE}" >/dev/null 2>&1

        if [ -s "$arch" ]; then
            sz=$(du -sh "$arch" | cut -f1)
            local speed=""
            local raw_bytes
            raw_bytes=$(stat -c%s "$arch" 2>/dev/null || echo 0)
            [ "$elapsed" -gt 0 ] && speed=$(echo "scale=1; $raw_bytes / $elapsed / 1048576" | bc 2>/dev/null) && speed=" @ ${speed} MB/s"
            log_ok "  ${label}: ${YELLOW}${arch}${X}"
            echo -e "          ${WHITE}├─ Size   : ${GREEN}${sz}${X}"
            echo -e "          ${WHITE}├─ Time   : ${CYAN}${elapsed}s${speed}${X}"
            echo -e "          ${WHITE}└─ Status : ${GREEN}OK ✓${X}"
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
    echo -e "          ${PINK}📂 Archives: ${WHITE}${cnt}/${KEEP} kept${X}"
    echo
}

# --- Заголовок контейнера ---
print_container_header() {
    local num="$1" label="$2" strategy="$3"
    CURRENT_CONTAINER=$((CURRENT_CONTAINER+1))
    local pct=$(( CURRENT_CONTAINER * 100 / TOTAL_CONTAINERS ))
    local filled=$(( pct / 5 ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=filled; i<20; i++)); do bar+="░"; done
    echo -e "$HR_M"
    echo -e "${CYAN}  [${num}/${TOTAL_CONTAINERS}] ${YELLOW}${label}${X}  ${WHITE}strategy: ${PINK}${strategy}${X}"
    echo -e "${CYAN}  Progress: [${GREEN}${bar}${CYAN}] ${YELLOW}${pct}%${X}"
    echo -e "$HR_S"
}

# =============================================================================
#  MAIN
# =============================================================================

echo -e "$HR_C"
echo -e "${CYAN}  🐳 DOCKER BACKUP   ${YELLOW}${SERVER_LABEL}${X}"
echo -e "${CYAN}  📅 $(date '+%Y-%m-%d %H:%M:%S')   ${WHITE}compression: ${GREEN}${COMP_LABEL}${X}"
echo -e "${CYAN}  🖥️  Hostname: ${PINK}$(hostname)${X}  ${WHITE}IP: ${YELLOW}$(hostname -I | awk '{print $1}')${X}"
echo -e "${CYAN}  💿 Disk free: ${GREEN}$(df -h /BACKUP 2>/dev/null | awk 'NR==2{print $4}' || df -h / | awk 'NR==2{print $4}')${X}  ${WHITE}Load avg: ${YELLOW}$(uptime | awk -F'load average:' '{print $2}' | xargs)${X}"
echo -e "${CYAN}  📦 Containers: ${WHITE}${TOTAL_CONTAINERS}${X}  ${CYAN}Keep: ${WHITE}${KEEP}${X}  ${CYAN}Backup root: ${YELLOW}${BACKUP_ROOT}${X}"
echo -e "$HR_C"
echo

if ! command -v pigz &>/dev/null; then
    info "pigz not found — installing for faster compression..."
    apt-get install -y pigz -qq 2>/dev/null && COMPRESS="pigz" COMPRESS_OPT="--use-compress-program=pigz" COMP_LABEL="pigz ⚡ (just installed)"
fi

print_container_header "1" "$CONTAINER_1_LABEL" "$CONTAINER_1_STRATEGY"
backup_volumes \
    "$CONTAINER_1_LABEL" \
    "$CONTAINER_1_IMAGE" \
    "$CONTAINER_1_COMPOSE_DIR" \
    "$CONTAINER_1_DATA_DIR" \
    "$CONTAINER_1_CLEANUP" \
    "${BACKUP_ROOT}/crypto"

print_container_header "2" "$CONTAINER_2_LABEL" "$CONTAINER_2_STRATEGY"
backup_volumes \
    "$CONTAINER_2_LABEL" \
    "$CONTAINER_2_IMAGE" \
    "$CONTAINER_2_COMPOSE_DIR" \
    "$CONTAINER_2_DATA_DIR" \
    "$CONTAINER_2_CLEANUP" \
    "${BACKUP_ROOT}/semaphore"

print_container_header "3" "$CONTAINER_3_LABEL" "$CONTAINER_3_STRATEGY"
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

echo -e "$HR_M"
if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}  ✅  ALL DONE — NO ERRORS${X}"
    MSG="✅ *DOCKER BACKUP OK* | ${SERVER_LABEL}%0A%0A${SUMMARY}%0A💾 Total: ${TOTAL_SZ}%0A⏱ Time: ${TOTAL_ELAPSED}s%0A🕐 $(date '+%Y-%m-%d %H:%M')"
else
    echo -e "${RED}  ⚠️   COMPLETED WITH ${ERRORS} ERROR(S)${X}"
    MSG="⚠️ *DOCKER BACKUP ERRORS* | ${SERVER_LABEL}%0AErrors: ${ERRORS}%0A%0A${SUMMARY}%0A🕐 $(date '+%Y-%m-%d %H:%M')"
fi
echo -e "${WHITE}  ├─ Total size  : ${GREEN}${TOTAL_SZ}${X}"
echo -e "${WHITE}  ├─ Total time  : ${CYAN}${TOTAL_ELAPSED}s${X}"
echo -e "${WHITE}  ├─ Errors      : ${errors_color}${ERRORS}${X}"
echo -e "${WHITE}  └─ Finished at : ${YELLOW}$(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "$HR_B"
echo -e "${YELLOW}                = Rooted by VladiMIR | AI =${X}"
echo -e "$HR_B"
echo

tg "$MSG"
