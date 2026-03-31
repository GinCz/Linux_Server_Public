#!/bin/bash
clear
# =============================================================================
# crypto_restore.sh — Restore crypto-bot Docker from backup
# =============================================================================
# Version  : v2026-03-31
# Author   : Ing. VladiMIR Bulantsev
# GitHub   : https://github.com/GinCz/Linux_Server_Public
# -----------------------------------------------------------------------------
# WHAT IT DOES:
#   - Lists the last 3 backups from /BACKUP/222/docker/crypto/
#   - Lets you choose which backup to restore
#   - Stops and removes the current crypto-bot container
#   - Extracts files to /
#   - Loads the Docker image from /tmp/crypto-bot-image.tar.gz
#   - Starts the container via docker-compose
# = Rooted by VladiMIR | AI =
# =============================================================================

BACKUP_DIR="/BACKUP/222/docker/crypto"
COMPOSE_DIR="/root/crypto-docker"

# --- Verify backup directory exists ---
if [ ! -d "${BACKUP_DIR}" ]; then
    echo "[ERROR] Backup directory not found: ${BACKUP_DIR}"
    exit 1
fi

# --- List last 3 backups (sorted by modification time, newest first) ---
echo "============================================"
echo " Crypto-bot backup restore"
echo "============================================"
echo ""
echo "Available backups (last 3):"
echo ""

mapfile -t BACKUPS < <(ls -t "${BACKUP_DIR}"/*.tar.gz 2>/dev/null | head -3)

if [ ${#BACKUPS[@]} -eq 0 ]; then
    echo "[ERROR] No backups found in ${BACKUP_DIR}"
    exit 1
fi

for i in "${!BACKUPS[@]}"; do
    SIZE=$(du -sh "${BACKUPS[$i]}" 2>/dev/null | cut -f1)
    DATE=$(stat -c '%y' "${BACKUPS[$i]}" | cut -d'.' -f1)
    echo "  [$((i+1))] $(basename "${BACKUPS[$i]}")  [${SIZE}]  ${DATE}"
done

echo ""
read -rp "Select backup [1-${#BACKUPS[@]}]: " CHOICE

# --- Validate input ---
if ! [[ "${CHOICE}" =~ ^[1-3]$ ]] || [ "${CHOICE}" -gt "${#BACKUPS[@]}" ]; then
    echo "[ERROR] Invalid selection."
    exit 1
fi

SELECTED="${BACKUPS[$((CHOICE-1))]}"
echo ""
echo "[INFO] Selected: $(basename "${SELECTED}")"
echo ""

# --- Confirmation ---
read -rp "Are you sure you want to restore? Current crypto-docker will be stopped! [y/N]: " CONFIRM
if [[ ! "${CONFIRM}" =~ ^[Yy]$ ]]; then
    echo "[CANCELLED] Nothing changed."
    exit 0
fi

# --- Stop and remove running container ---
echo ""
echo "[1/5] Stopping and removing crypto-bot container..."
docker stop crypto-bot 2>/dev/null && docker rm crypto-bot 2>/dev/null
echo "      Done."

# --- Backup current state ---
BACK_STAMP=$(date +%Y-%m-%d_%H-%M)
echo "[2/5] Backing up current /root/crypto-docker to /root/crypto-docker.bak_${BACK_STAMP}..."
cp -a "${COMPOSE_DIR}" "/root/crypto-docker.bak_${BACK_STAMP}"
echo "      Done."

# --- Extract archive ---
echo "[3/5] Extracting backup to /..."
tar -xzf "${SELECTED}" -C /
echo "      Done."

# --- Load Docker image if present ---
DOCKER_IMAGE="/tmp/crypto-bot-image.tar.gz"
if [ -f "${DOCKER_IMAGE}" ]; then
    echo "[4/5] Loading Docker image from ${DOCKER_IMAGE}..."
    docker load -i "${DOCKER_IMAGE}"
    echo "      Done."
else
    echo "[4/5] No Docker image found in archive, skipping."
fi

# --- Start container ---
echo "[5/5] Starting crypto-bot via docker-compose..."
cd "${COMPOSE_DIR}" && docker-compose up -d
echo ""
echo "============================================"
echo " RESTORE COMPLETE"
echo "============================================"
echo ""
docker ps | grep crypto
