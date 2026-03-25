#!/bin/bash
clear
# =============================================================================
# docker_backup.sh — Backup crypto-docker → /BACKUP/222/
# =============================================================================
# Version     : v2026-03-25
# Author      : Ing. VladiMIR Bulantsev
# GitHub      : https://github.com/GinCz/Linux_Server_Public
# -----------------------------------------------------------------------------
# Backup: /root/crypto-docker → /BACKUP/222/docker/
# Excludes: __pycache__  logs  *.pyc
# =============================================================================
# = Rooted by VladiMIR | AI =
# =============================================================================

C="\033[1;36m"; G="\033[1;32m"; Y="\033[1;33m"; R="\033[1;31m"; X="\033[0m"
HR="${Y}╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋${X}"

TOKEN="1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ"
CHAT_ID="261784949"
LOCAL_DIR="/BACKUP/222/docker"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M)
FILENAME="docker_crypto_${TIMESTAMP}.tar.gz"
TMPFILE="/tmp/${FILENAME}"

echo -e "$HR"
echo -e "${Y}   DOCKER BACKUP — crypto-bot${X}"
echo -e "$HR"
echo

# --- [1] Сохранить Docker image ---
echo -e "${C}[1/4] Saving Docker image...${X}"
docker save crypto-docker_crypto-bot | gzip > /tmp/crypto-bot-image.tar.gz
echo -e "      ${G}OK${X}"

# --- [2] Создать архив ---
echo -e "${C}[2/4] Creating archive...${X}"
tar -czf "${TMPFILE}" \
    /root/crypto-docker \
    /tmp/crypto-bot-image.tar.gz \
    --exclude='*/__pycache__' \
    --exclude='*/logs/*' \
    --exclude='*.pyc' \
    2>/dev/null
rm -f /tmp/crypto-bot-image.tar.gz
SIZE=$(du -sh "${TMPFILE}" 2>/dev/null | cut -f1)
echo -e "      ${G}OK — ${FILENAME} (${SIZE})${X}"

# --- [3] Сохранить локально ---
echo -e "${C}[3/4] Saving to ${LOCAL_DIR}...${X}"
mkdir -p "${LOCAL_DIR}"
cp "${TMPFILE}" "${LOCAL_DIR}/"
# Хранить только последние 10 копий
ls -t "${LOCAL_DIR}"/docker_crypto_*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm -f
rm -f "${TMPFILE}"
echo -e "      ${G}OK${X}"

# --- [4] Telegram ---
echo -e "${C}[4/4] Telegram notification...${X}"
MSG="✅ *DOCKER BACKUP OK* | 222-EU%0A📦 ${FILENAME}%0A📊 Size: ${SIZE}%0A💾 /BACKUP/222/docker/"
curl -s "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}&text=${MSG}&parse_mode=Markdown" >/dev/null
echo -e "      ${G}OK${X}"

echo
echo -e "$HR"
echo -e "${Y}              = Rooted by VladiMIR | AI =${X}"
echo -e "$HR"
echo
