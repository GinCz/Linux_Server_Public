#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  system_backup.sh | [v2026-08-21]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Full system configuration backup with local rotation and remote cross-sync
# Servers     : All Linux Nodes (222-DE ⇄ 109-RU ⇄ VPN Nodes)
# Usage       : bash scripts/system_backup.sh
# ==========================================================================================

C="\033[1;36m"; G="\033[1;32m"; Y="\033[1;33m"; R="\033[1;31m"; X="\033[0m"
HR="${Y}================================================================${X}"

[ -f /root/.server_env ] && source /root/.server_env
TOKEN="${TG_TOKEN:-}"
CHAT_ID="${TG_CHAT_ID:-261784949}"

MY_HOSTNAME=$(hostname)
MY_IP=$(hostname -I 2>/dev/null | awk '{print $1}')

# Detect server, remote destination and SSH port
if [[ "$MY_IP" =~ "212.109.223.109" ]] || [[ "$MY_HOSTNAME" =~ "109" ]]; then
    SERVER_NAME="109-RU"
    REMOTE_IP="152.53.182.222"
    REMOTE_PORT="2222"
    REMOTE_USER="vlad"
    LOCAL_DIR="/BACKUP/109"
    REMOTE_DIR="/BACKUP/109"
elif [[ "$MY_IP" =~ "152.53.182.222" ]] || [[ "$MY_HOSTNAME" =~ "222" ]]; then
    SERVER_NAME="222-DE"
    REMOTE_IP="212.109.223.109"
    REMOTE_PORT="22"
    REMOTE_USER="vlad"
    LOCAL_DIR="/BACKUP/222"
    REMOTE_DIR="/BACKUP/222"
else
    SERVER_NAME="VPN-${MY_HOSTNAME}"
    REMOTE_IP="152.53.182.222"
    REMOTE_PORT="2222"
    REMOTE_USER="vlad"
    LOCAL_DIR="/BACKUP/${MY_HOSTNAME}"
    REMOTE_DIR="/BACKUP/VPN_${MY_HOSTNAME}"
fi

TIMESTAMP=$(date +%Y-%m-%d_%H-%M)
FILENAME="BackUp_${SERVER_NAME}__${TIMESTAMP}.tar.gz"
TMPFILE="${LOCAL_DIR}/${FILENAME}"

echo -e "$HR"
echo -e "${Y}   BACKUP — ${SERVER_NAME}  →  local + ${REMOTE_IP}:${REMOTE_PORT}${X}"
echo -e "$HR"
echo ""

# [1] Pre-cleanup
echo -e "${C}[1/5] Pre-cleanup temporary cache...${X}"
journalctl --vacuum-time=1s >/dev/null 2>&1
apt-get clean -qq 2>/dev/null
rm -f /tmp/disk_test_file.* 2>/dev/null
echo -e "      ${G}OK${X}"

# [2] Create archive
echo -e "${C}[2/5] Creating archive...${X}"
mkdir -p "${LOCAL_DIR}"
tar -czf "${TMPFILE}" \
    /etc \
    /root/Linux_Server_Public \
    /root/*.sh \
    /root/.ssh \
    /usr/local/fastpanel2 \
    /usr/local/x-ui \
    /etc/x-ui \
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

# [3] Rotate local backups (keep 10)
echo -e "${C}[3/5] Rotating local backups (keep 10)...${X}"
ls -t "${LOCAL_DIR}"/BackUp_${SERVER_NAME}__*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm -f
echo -e "      ${G}OK${X}"

# [4] Transfer copy to partner server
echo -e "${C}[4/5] Sending copy to remote (${REMOTE_IP}:${REMOTE_PORT})...${X}"
ssh -p ${REMOTE_PORT} -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
    ${REMOTE_USER}@${REMOTE_IP} "mkdir -p ${REMOTE_DIR}" 2>/dev/null
scp -P ${REMOTE_PORT} -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
    "${TMPFILE}" "${REMOTE_USER}@${REMOTE_IP}:${REMOTE_DIR}/" 2>/dev/null
STATUS=$?

if [ ${STATUS} -eq 0 ]; then
    ssh -p ${REMOTE_PORT} -o BatchMode=yes -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_IP} \
        "ls -t ${REMOTE_DIR}/BackUp_${SERVER_NAME}__*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm -f" 2>/dev/null
    echo -e "      ${G}OK — Remote transfer complete${X}"
else
    echo -e "      ${R}WARNING: Remote transfer failed — saved locally only${X}"
fi

# [5] Telegram Notification
echo -e "${C}[5/5] Telegram notification...${X}"
if [ -n "$TOKEN" ]; then
    if [ ${STATUS} -eq 0 ]; then
        MSG="✅ *BACKUP OK* | ${SERVER_NAME}%0A📦 ${FILENAME}%0A📊 Size: ${SIZE}%0A💾 local + ${REMOTE_IP}:${REMOTE_PORT}:${REMOTE_DIR}"
    else
        MSG="⚠️ *BACKUP PARTIAL* | ${SERVER_NAME}%0A📦 ${FILENAME} — saved locally%0A❌ Copy to ${REMOTE_IP}:${REMOTE_PORT} FAILED"
    fi
    curl -s "https://api.telegram.org/bot${TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}&text=${MSG}&parse_mode=Markdown" >/dev/null
fi
echo -e "      ${G}OK${X}"

echo ""
echo -e "$HR"
echo -e "${G}Backup procedure finished.${X}"
echo -e "$HR"
