#!/bin/bash
clear
# =============================================================================
#  docker_backup.sh
# =============================================================================
#  Version    : v2026-03-30c
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
#  Keeps the last KEEP=7 archives per container. Older ones are deleted.
#
#  NOTIFICATIONS
#  -------------
#  Sends a Telegram message on completion (success or error).
#  Set TOKEN and CHAT_ID in the CONFIG section below.
#
#  USAGE
#  -----
#  Manual run:   bash /root/docker_backup.sh
#  Alias:        dbackup
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

# --- Colors ---
C="\033[1;36m"; G="\033[1;32m"; Y="\033[1;33m"; R="\033[1;31m"; X="\033[0m"
HR="${C}═══════════════════════════════════════════════════════════════════════════════════════════════${X}"

# =============================================================================
#  CONFIG
# =============================================================================

# Telegram notification (set empty to disable)
TOKEN="1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ"
CHAT_ID="261784949"

# Backup destination root
BACKUP_ROOT="/BACKUP/222/docker"

# How many archives to keep per container (older ones are deleted)
KEEP=7

# Server label for Telegram messages
SERVER_LABEL="222-DE-NetCup"

# =============================================================================
#  CONTAINERS CONFIG
#  One block per container. Add/remove as needed.
# =============================================================================

# --- [1] crypto-bot (Strategy A: VOLUMES) ---
# Docker Compose project dir, image name as shown by "docker images"
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
# No host volume — all config/keys stored inside container
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

# Use pigz (parallel gzip) if available — much faster on multi-core CPUs
if command -v pigz &>/dev/null; then
    COMPRESS="pigz"
    COMPRESS_OPT="--use-compress-program=pigz"
    COMP_LABEL="pigz"
else
    COMPRESS="gzip"
    COMPRESS_OPT=""
    COMP_LABEL="gzip"
fi

# =============================================================================
#  HELPER FUNCTIONS
# =============================================================================

log()  { echo -e "${C}$(date +%H:%M:%S)${X} $1"; }
fail() { echo -e "${R}$(date +%H:%M:%S) ❌ $1${X}"; ERRORS=$((ERRORS+1)); }

tg() {
    [ -z "$TOKEN" ] || [ -z "$CHAT_ID" ] && return
    curl -s "https://api.telegram.org/bot${TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}&text=$1&parse_mode=Markdown" >/dev/null
}

rotate() {
    # Remove oldest archives, keep only KEEP most recent
    ls -t "$1"/*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f
}

# backup_volumes LABEL IMAGE COMPOSE_DIR DATA_DIR CLEANUP DEST_DIR
backup_volumes() {
    local label="$1" image="$2" compose_dir="$3" data_dir="$4"
    local cleanup="$5" dest_dir="$6"
    local arch="${dest_dir}/${label}_${DATE}.tar.gz"
    local sz

    mkdir -p "$dest_dir"

    # Cleanup before archive
    log "  🧹 ${label}: cleanup..."
    eval "$cleanup"

    log "  💾 ${label}: saving image..."
    # Find image by partial name
    local img_full
    img_full=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -i "$image" | head -1)
    if [ -n "$img_full" ]; then
        docker save "$img_full" | ${COMPRESS} > /tmp/${label}-image.tar.gz
    else
        log "  ${Y}⚠️ ${label}: image not found, skipping image save${X}"
        touch /tmp/${label}-image.tar.gz
    fi

    # Stop compose if dir provided
    [ -n "$compose_dir" ] && cd "$compose_dir" && docker-compose stop 2>/dev/null

    log "  📦 ${label}: creating archive (${COMP_LABEL})..."
    tar -c ${COMPRESS_OPT} -f "$arch" \
        "$data_dir" \
        /tmp/${label}-image.tar.gz \
        2>/dev/null
    rm -f /tmp/${label}-image.tar.gz

    # Start compose back
    [ -n "$compose_dir" ] && cd "$compose_dir" && docker-compose up -d 2>/dev/null

    if [ -s "$arch" ]; then
        sz=$(du -sh "$arch" | cut -f1)
        log "  ✅ ${label}: ${arch} (${Y}${sz}${X})"
        SUMMARY="${SUMMARY}📦 ${label}: ${sz}%0A"
    else
        fail "${label}: archive FAILED or empty"
        sz="ERR"
    fi

    rotate "$dest_dir"
    local cnt
    cnt=$(ls "$dest_dir"/*.tar.gz 2>/dev/null | wc -l)
    log "  📂 ${label}: ${cnt}/${KEEP} archives stored"
    echo
}

# backup_commit LABEL CLEANUP DEST_DIR
backup_commit() {
    local label="$1" cleanup="$2" dest_dir="$3"
    local arch="${dest_dir}/${label}_${DATE}.tar.gz"
    local sz

    mkdir -p "$dest_dir"

    # Cleanup inside container before snapshot
    log "  🧹 ${label}: cleanup inside container..."
    docker exec "$label" sh -c "$cleanup" 2>/dev/null

    log "  📸 ${label}: docker commit snapshot..."
    local commit_id
    commit_id=$(docker commit "$label" "${label}-backup:${DATE}" 2>/dev/null | cut -d: -f2 | cut -c1-12)

    if [ -n "$commit_id" ]; then
        docker save "${label}-backup:${DATE}" | ${COMPRESS} > "$arch"
        docker rmi "${label}-backup:${DATE}" >/dev/null 2>&1
        if [ -s "$arch" ]; then
            sz=$(du -sh "$arch" | cut -f1)
            log "  ✅ ${label}: ${arch} (${Y}${sz}${X})"
            SUMMARY="${SUMMARY}📦 ${label}: ${sz}%0A"
        else
            fail "${label}: archive FAILED (empty file)"
            sz="ERR"
        fi
    else
        fail "${label}: docker commit FAILED (container not running?)"
    fi

    rotate "$dest_dir"
    local cnt
    cnt=$(ls "$dest_dir"/*.tar.gz 2>/dev/null | wc -l)
    log "  📂 ${label}: ${cnt}/${KEEP} archives stored"
    echo
}

# =============================================================================
#  MAIN
# =============================================================================

echo -e "$HR"
echo -e "${C}   🐳 DOCKER BACKUP — ${SERVER_LABEL} — compression: ${COMP_LABEL}${X}"
echo -e "${C}   📅 $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "$HR"
echo

# Check: install pigz if missing (optional, comment out if not desired)
if ! command -v pigz &>/dev/null; then
    log "${Y}⚠️  pigz not found — installing for faster compression...${X}"
    apt-get install -y pigz -qq 2>/dev/null && COMPRESS="pigz" COMPRESS_OPT="--use-compress-program=pigz" COMP_LABEL="pigz (just installed)"
fi

log "[1/3] crypto-bot backup..."
backup_volumes \
    "$CONTAINER_1_LABEL" \
    "$CONTAINER_1_IMAGE" \
    "$CONTAINER_1_COMPOSE_DIR" \
    "$CONTAINER_1_DATA_DIR" \
    "$CONTAINER_1_CLEANUP" \
    "${BACKUP_ROOT}/crypto"

log "[2/3] semaphore backup..."
backup_volumes \
    "$CONTAINER_2_LABEL" \
    "$CONTAINER_2_IMAGE" \
    "$CONTAINER_2_COMPOSE_DIR" \
    "$CONTAINER_2_DATA_DIR" \
    "$CONTAINER_2_CLEANUP" \
    "${BACKUP_ROOT}/semaphore"

log "[3/3] amnezia-awg backup..."
backup_commit \
    "$CONTAINER_3_NAME" \
    "$CONTAINER_3_CLEANUP" \
    "${BACKUP_ROOT}/amnezia"

# =============================================================================
#  SUMMARY
# =============================================================================

echo -e "$HR"
TOTAL=$(du -sh "${BACKUP_ROOT}/" 2>/dev/null | cut -f1)

if [ "$ERRORS" -eq 0 ]; then
    log "${G}✅ ALL OK — total backup size: ${TOTAL}${X}"
    MSG="✅ *DOCKER BACKUP OK* | ${SERVER_LABEL}%0A%0A${SUMMARY}%0A💾 Total: ${TOTAL}%0A🕐 $(date '+%Y-%m-%d %H:%M')"
else
    log "${R}⚠️  COMPLETED WITH ${ERRORS} ERROR(S)${X}"
    MSG="⚠️ *DOCKER BACKUP ERRORS* | ${SERVER_LABEL}%0AErrors: ${ERRORS}%0A%0A${SUMMARY}%0A🕐 $(date '+%Y-%m-%d %H:%M')"
fi

echo -e "$HR"
echo -e "${C}              = Rooted by VladiMIR | AI =${X}"
echo -e "$HR"
echo

tg "$MSG"
