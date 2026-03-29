#!/bin/bash
clear
# =============================================================================
# docker_backup.sh — Backup all 3 Docker containers on 222-DE-NetCup
# =============================================================================
# Version     : v2026-03-30
# Author      : Ing. VladiMIR Bulantsev
# GitHub      : https://github.com/GinCz/Linux_Server_Public
# =============================================================================
# Containers:
#   [1/3] crypto-bot    → tar (image + /root/crypto-docker/) → /BACKUP/222/docker/crypto/
#   [2/3] semaphore     → tar (image + /root/semaphore-data/) → /BACKUP/222/docker/semaphore/
#   [3/3] amnezia-awg   → docker commit + docker save        → /BACKUP/222/docker/amnezia/
# Schedule:   cron 0 3 * * *   (every night at 03:00)
# Restore:    docker load < image.tar.gz && docker-compose up -d
# Alias:      dbackup
# = Rooted by VladiMIR | AI =
# =============================================================================

C="\033[1;36m"; G="\033[1;32m"; Y="\033[1;33m"; R="\033[1;31m"; X="\033[0m"
HR="${C}══════════════════════════════════════════════════════════════${X}"

TOKEN="1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ"
CHAT_ID="261784949"
DATE=$(date +%Y-%m-%d_%H-%M)
KEEP=7
ERRORS=0

log()  { echo -e "${C}$(date +%H:%M:%S)${X} $1"; }
fail() { echo -e "${R}$(date +%H:%M:%S) ❌ $1${X}"; ERRORS=$((ERRORS+1)); }
tg()   {
    local msg="$1"
    curl -s "https://api.telegram.org/bot${TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}&text=${msg}&parse_mode=Markdown" >/dev/null
}

rotate() {
    local dir="$1"
    ls -t "${dir}"/*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f
}

echo -e "$HR"
echo -e "${C}   DOCKER BACKUP — 222-DE-NetCup — 3 containers${X}"
echo -e "${C}   $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "$HR"
echo

# =============================================================================
# [1/3] CRYPTO-BOT — tar (image + project files)
# =============================================================================
log "[1/3] crypto-bot backup..."
DIR_CRYPTO="/BACKUP/222/docker/crypto"
mkdir -p "$DIR_CRYPTO"
ARCH_CRYPTO="${DIR_CRYPTO}/crypto_${DATE}.tar.gz"

cd /root/crypto-docker && docker-compose stop 2>/dev/null
docker save crypto-docker_crypto-bot 2>/dev/null | gzip > /tmp/crypto-bot-image.tar.gz

tar -czf "$ARCH_CRYPTO" \
    /root/crypto-docker \
    /tmp/crypto-bot-image.tar.gz \
    --exclude='*/__pycache__' \
    --exclude='*/logs/*' \
    --exclude='*.pyc' \
    2>/dev/null

rm -f /tmp/crypto-bot-image.tar.gz
docker-compose up -d 2>/dev/null

if [ -s "$ARCH_CRYPTO" ]; then
    SZ1=$(du -sh "$ARCH_CRYPTO" | cut -f1)
    log "  ✅ crypto   : $ARCH_CRYPTO ($SZ1)"
else
    fail "crypto-bot archive FAILED or empty"
fi

rotate "$DIR_CRYPTO"
C1=$(ls "$DIR_CRYPTO"/*.tar.gz 2>/dev/null | wc -l)
log "  crypto   : ${C1}/${KEEP} архивов в хранилище"

echo

# =============================================================================
# [2/3] SEMAPHORE — tar (image + data)
# =============================================================================
log "[2/3] semaphore backup..."
DIR_SEM="/BACKUP/222/docker/semaphore"
mkdir -p "$DIR_SEM"
ARCH_SEM="${DIR_SEM}/semaphore_${DATE}.tar.gz"

# Save semaphore image
SEMA_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -i semaphore | head -1)
if [ -n "$SEMA_IMAGE" ]; then
    docker save "$SEMA_IMAGE" 2>/dev/null | gzip > /tmp/semaphore-image.tar.gz
else
    log "  ⚠️  semaphore image not found, skipping image save"
    touch /tmp/semaphore-image.tar.gz
fi

tar -czf "$ARCH_SEM" \
    /root/semaphore-data \
    /tmp/semaphore-image.tar.gz \
    2>/dev/null

rm -f /tmp/semaphore-image.tar.gz

if [ -s "$ARCH_SEM" ]; then
    SZ2=$(du -sh "$ARCH_SEM" | cut -f1)
    log "  ✅ semaphore: $ARCH_SEM ($SZ2)"
else
    fail "semaphore archive FAILED or empty"
fi

rotate "$DIR_SEM"
C2=$(ls "$DIR_SEM"/*.tar.gz 2>/dev/null | wc -l)
log "  semaphore: ${C2}/${KEEP} архивов в хранилище"

echo

# =============================================================================
# [3/3] AMNEZIA-AWG — docker commit (all data inside container)
# =============================================================================
log "[3/3] amnezia-awg backup (docker commit)..."
DIR_AWG="/BACKUP/222/docker/amnezia"
mkdir -p "$DIR_AWG"
ARCH_AWG="${DIR_AWG}/amnezia_${DATE}.tar.gz"

COMMIT_ID=$(docker commit amnezia-awg amnezia-backup:${DATE} 2>/dev/null | cut -d: -f2 | cut -c1-12)

if [ -n "$COMMIT_ID" ]; then
    docker save "amnezia-backup:${DATE}" | gzip > "$ARCH_AWG"
    docker rmi "amnezia-backup:${DATE}" >/dev/null 2>&1
    if [ -s "$ARCH_AWG" ]; then
        SZ3=$(du -sh "$ARCH_AWG" | cut -f1)
        log "  ✅ amnezia  : $ARCH_AWG ($SZ3)"
    else
        fail "amnezia archive FAILED (empty file)"
    fi
else
    fail "amnezia commit FAILED (container not running?)"
    SZ3="0"
fi

rotate "$DIR_AWG"
C3=$(ls "$DIR_AWG"/*.tar.gz 2>/dev/null | wc -l)
log "  amnezia  : ${C3}/${KEEP} архивов в хранилище"

echo

# =============================================================================
# ИТОГ
# =============================================================================
echo -e "$HR"
TOTAL=$(du -sh /BACKUP/222/docker/ 2>/dev/null | cut -f1)

if [ "$ERRORS" -eq 0 ]; then
    STATUS="✅ ALL OK"
    MSG="✅ *DOCKER BACKUP OK* | 222-EU%0A%0A📦 crypto:    ${SZ1:-?}%0A📦 semaphore: ${SZ2:-?}%0A📦 amnezia:   ${SZ3:-?}%0A%0A💾 Total: ${TOTAL} in /BACKUP/222/docker/%0A🕐 $(date '+%Y-%m-%d %H:%M')"
else
    STATUS="⚠️  ERRORS: ${ERRORS}"
    MSG="⚠️ *DOCKER BACKUP ERRORS* | 222-EU%0AErrors: ${ERRORS}%0A%0A💾 /BACKUP/222/docker/%0A🕐 $(date '+%Y-%m-%d %H:%M')"
fi

log "${STATUS}"
echo -e "$HR"
echo -e "${C}        = Rooted by VladiMIR | AI =${X}"
echo -e "$HR"
echo

tg "$MSG"
