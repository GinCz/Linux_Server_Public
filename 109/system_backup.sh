#!/bin/bash
clear
# =============================================================================
# system_backup.sh — Server 109 (RU Russia, FastVDS)
# =============================================================================
# Version     : v2026-03-25
# Author      : Ing. VladiMIR Bulantsev
# GitHub      : https://github.com/GinCz/Linux_Server_Public
# -----------------------------------------------------------------------------
# Backup destinations:
#   PRIMARY   : local  /BACKUP/109/   (on this server)
#   SECONDARY : remote /BACKUP/109/   on 222 (xxx.xxx.xxx.222) via user vlad
# Archive includes: /etc  /root  /usr/local/fastpanel2
# Excludes: .git  sessions  cache  www  backups
# =============================================================================
# = Rooted by VladiMIR | AI =
# =============================================================================

C="\033[1;36m"; G="\033[1;32m"; Y="\033[1;33m"; R="\033[1;31m"; X="\033[0m"
HR="${Y}╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋${X}"
SIGN="${Y}              = Rooted by VladiMIR | AI =${X}"

TOKEN="1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ"
CHAT_ID="261784949"
SERVER_NAME="109-RU"
REMOTE_USER="vlad"
REMOTE_IP="xxx.xxx.xxx.222"
LOCAL_DIR="/BACKUP/109"
REMOTE_DIR="/BACKUP/109"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M)
FILENAME="BackUp_${SERVER_NAME}__${TIMESTAMP}.tar.gz"
TMPFILE="/tmp/${FILENAME}"

echo -e "$HR"
echo -e "${Y}   BACKUP — ${SERVER_NAME}  →  local + 222${X}"
echo -e "$HR"
echo

# --- [1] Pre-cleanup ---
echo -e "${C}[1/5] Pre-cleanup...${X}"
journalctl --vacuum-time=1s >/dev/null 2>&1
apt-get clean -qq 2>/dev/null
rm -f /tmp/disk_test_file.* 2>/dev/null
echo -e "      ${G}OK${X}"

# --- [2] Create archive ---
echo -e "${C}[2/5] Creating archive...${X}"
tar -czf "${TMPFILE}" \
    /etc \
    /root \
    /usr/local/fastpanel2 \
    --exclude='*/.git' \
    --exclude='*/session/*' \
    --exclude='*/cache/*' \
    --exclude='/var/www/*/data/www/*' \
    --exclude='/var/www/*/data/backups/*' \
    2>/dev/null
SIZE=$(du -sh "${TMPFILE}" 2>/dev/null | cut -f1)
echo -e "      ${G}OK — ${FILENAME} (${SIZE})${X}"

# --- [3] Save locally ---
echo -e "${C}[3/5] Saving locally → ${LOCAL_DIR}...${X}"
mkdir -p "${LOCAL_DIR}"
cp "${TMPFILE}" "${LOCAL_DIR}/"
# Keep last 10 local backups
ls -t "${LOCAL_DIR}"/BackUp_${SERVER_NAME}__*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm -f
echo -e "      ${G}OK${X}"

# --- [4] Transfer copy to 222 ---
echo -e "${C}[4/5] Sending copy to 222 (${REMOTE_IP})...${X}"
ssh -o StrictHostKeyChecking=no \
    ${REMOTE_USER}@${REMOTE_IP} "mkdir -p ${REMOTE_DIR}" 2>/dev/null
scp -o StrictHostKeyChecking=no \
    "${TMPFILE}" "${REMOTE_USER}@${REMOTE_IP}:${REMOTE_DIR}/"
STATUS=$?
if [ ${STATUS} -eq 0 ]; then
    ssh ${REMOTE_USER}@${REMOTE_IP} \
        "ls -t ${REMOTE_DIR}/BackUp_${SERVER_NAME}__*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm -f"
    echo -e "      ${G}OK${X}"
else
    echo -e "      ${R}FAILED — saved locally only${X}"
fi
rm -f "${TMPFILE}"

# --- [5] Telegram ---
echo -e "${C}[5/5] Telegram...${X}"
if [ ${STATUS} -eq 0 ]; then
    MSG="✅ *BACKUP OK* | ${SERVER_NAME}%0A📦 ${FILENAME}%0A📊 Size: ${SIZE}%0A💾 local + 222:${REMOTE_DIR}"
else
    MSG="⚠️ *BACKUP PARTIAL* | ${SERVER_NAME}%0A📦 ${FILENAME} — saved locally%0A❌ Copy to 222 FAILED"
fi
curl -s "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}&text=${MSG}&parse_mode=Markdown" >/dev/null
echo -e "      ${G}OK${X}"

echo
echo -e "$HR"
echo -e "$SIGN"
echo -e "$HR"
echo
