#!/bin/bash
clear
# =============================================================================
# system_backup.sh — Server 109 (RU Russia, FastVDS)
# =============================================================================
# Version     : v2026-03-26
# Author      : Ing. VladiMIR Bulantsev
# GitHub      : https://github.com/GinCz/Linux_Server_Public
# -----------------------------------------------------------------------------
# Backup destinations:
#   PRIMARY   : local  /BACKUP/109/   (on this server)
#   SECONDARY : remote /BACKUP/109/   on 222 (xxx.xxx.xxx.222) via user vlad
# -----------------------------------------------------------------------------
# Archive includes:
#   /etc                        — all system configs
#   /root (selective)           — scripts, keys, configs (NO logs, NO git, NO backups)
#   /usr/local/fastpanel2       — FastPanel config
# Excludes: .git  session  cache  www  backups  /tmp  logs
# =============================================================================
# = Rooted by VladiMIR | AI =
# =============================================================================

C="\033[1;36m"; G="\033[1;32m"; Y="\033[1;33m"; R="\033[1;31m"; X="\033[0m"
HR="${Y}\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b${X}"
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
# Archive is created directly in LOCAL_DIR, NOT in /tmp
TMPFILE="${LOCAL_DIR}/${FILENAME}"

echo -e "$HR"
echo -e "${Y}   BACKUP — ${SERVER_NAME}  \u2192  local + 222${X}"
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
mkdir -p "${LOCAL_DIR}"
tar -czf "${TMPFILE}" \
    /etc \
    /root/Linux_Server_Public \
    /root/*.sh \
    /root/.ssh \
    /usr/local/fastpanel2 \
    --exclude='*/.git' \
    --exclude='*/session/*' \
    --exclude='*/sessions/*' \
    --exclude='*/cache/*' \
    --exclude='*/logs/*' \
    --exclude='*/log/*' \
    --exclude='*/tmp/*' \
    --exclude='*/data/www/*' \
    --exclude='/var/www/*/data/backups/*' \
    --exclude='/root/BACKUP/*' \
    --exclude='/BACKUP/*' \
    2>/dev/null
SIZE=$(du -sh "${TMPFILE}" 2>/dev/null | cut -f1)
echo -e "      ${G}OK — ${FILENAME} (${SIZE})${X}"

# --- [3] Keep last 10 local backups ---
echo -e "${C}[3/5] Rotating local backups (keep 10)...${X}"
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

# --- [5] Telegram ---
echo -e "${C}[5/5] Telegram notification...${X}"
if [ ${STATUS} -eq 0 ]; then
    MSG="\u2705 *BACKUP OK* | ${SERVER_NAME}%0A\ud83d\udce6 ${FILENAME}%0A\ud83d\udcca Size: ${SIZE}%0A\ud83d\udcbe local + 222:${REMOTE_DIR}"
else
    MSG="\u26a0\ufe0f *BACKUP PARTIAL* | ${SERVER_NAME}%0A\ud83d\udce6 ${FILENAME} — saved locally%0A\u274c Copy to 222 FAILED"
fi
curl -s "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}&text=${MSG}&parse_mode=Markdown" >/dev/null
echo -e "      ${G}OK${X}"

echo
echo -e "$HR"
echo -e "$SIGN"
echo -e "$HR"
echo
