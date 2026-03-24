#!/bin/bash
clear
# =============================================================================
# system_backup.sh — VPN Servers (AmneziaWG nodes)
# =============================================================================
# Version     : v2026-03-24
# Author      : Ing. VladiMIR Bulantsev
# GitHub      : https://github.com/GinCz/Linux_Server_Public
# -----------------------------------------------------------------------------
# Backup destination:
#   REMOTE : /BackUP/VPN/  on 222 (xxx.xxx.xxx.222) via user vlad
# Archive includes: /etc  /root/Linux_Server_Public
# =============================================================================
# = Rooted by VladiMIR | AI =
# =============================================================================

C="\033[1;36m"; G="\033[1;32m"; Y="\033[1;33m"; R="\033[1;31m"; X="\033[0m"
HR="${Y}╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋${X}"
SIGN="${Y}              = Rooted by VladiMIR | AI =${X}"

TOKEN="1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ"
CHAT_ID="261784949"
SERVER_NAME=$(hostname)
REMOTE_USER="vlad"
REMOTE_PASS="sa4434"
REMOTE_IP="xxx.xxx.xxx.222"
REMOTE_DIR="/BackUP/VPN"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M)
FILENAME="BackUp_${SERVER_NAME}__${TIMESTAMP}.tar.gz"
TMPFILE="/tmp/${FILENAME}"

echo -e "$HR"
echo -e "${Y}   BACKUP — ${SERVER_NAME}  →  222 (${REMOTE_IP})${X}"
echo -e "$HR"
echo

echo -e "${C}[1/4] Pre-cleanup...${X}"
journalctl --vacuum-time=1s >/dev/null 2>&1
rm -f /tmp/disk_test_file.* 2>/dev/null
echo -e "      ${G}OK${X}"

echo -e "${C}[2/4] Creating archive...${X}"
tar -czf "${TMPFILE}" \
    /etc \
    /root/Linux_Server_Public \
    --exclude='*/.git' \
    2>/dev/null
SIZE=$(du -sh "${TMPFILE}" 2>/dev/null | cut -f1)
echo -e "      ${G}OK — ${FILENAME} (${SIZE})${X}"

echo -e "${C}[3/4] Transferring to 222...${X}"
sshpass -p "${REMOTE_PASS}" ssh -o StrictHostKeyChecking=no \
    ${REMOTE_USER}@${REMOTE_IP} "mkdir -p ${REMOTE_DIR}" 2>/dev/null
sshpass -p "${REMOTE_PASS}" scp -o StrictHostKeyChecking=no \
    "${TMPFILE}" "${REMOTE_USER}@${REMOTE_IP}:${REMOTE_DIR}/"
STATUS=$?
if [ ${STATUS} -eq 0 ]; then
    sshpass -p "${REMOTE_PASS}" ssh ${REMOTE_USER}@${REMOTE_IP} \
        "ls -t ${REMOTE_DIR}/BackUp_${SERVER_NAME}__*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm -f"
    rm -f "${TMPFILE}"
    echo -e "      ${G}OK${X}"
else
    echo -e "      ${R}FAILED${X}"
fi

echo -e "${C}[4/4] Telegram...${X}"
if [ ${STATUS} -eq 0 ]; then
    MSG="✅ *BACKUP OK* | ${SERVER_NAME}%0A📦 ${FILENAME}%0A📊 Size: ${SIZE}%0A🎯 222:${REMOTE_DIR}"
else
    MSG="🚨 *BACKUP FAILED!* | ${SERVER_NAME}%0A❌ Transfer to 222 failed"
fi
curl -s "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}&text=${MSG}&parse_mode=Markdown" >/dev/null
echo -e "      ${G}OK${X}"

echo
echo -e "$HR"
echo -e "$SIGN"
echo -e "$HR"
echo
