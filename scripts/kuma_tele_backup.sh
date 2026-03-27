#!/bin/bash
# Script:  kuma_tele_backup.sh
# Purpose: Monthly backup of Uptime Kuma DB -> server 222 + Telegram report
# Server:  VPN-EU (VDSina) — выполнять на VPN-сервере
# Path:    /root/scripts/kuma_tele_backup.sh
# Cron:    0 3 1 * * /bin/bash /root/scripts/kuma_tele_backup.sh > /dev/null 2>&1
# = Rooted by VladiMIR | AI =
# v2026-03-27

source /root/.server_alliances.conf 2>/dev/null

TG_TOKEN="${TG_TOKEN}"
TG_CHAT="${TG_CHAT_ID}"
SERVER_TAG="${SERVER_TAG:-VPN-EU-Tatra-9}"
REMOTE_USER="root"
REMOTE_HOST="${PAIR_222_IP}"
REMOTE_DIR="/BACKUP/kuma"
KEEP=3
BACKUP_FILE="/tmp/kuma_$(date +%F).db"

tg_send() {
  curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -d chat_id="${TG_CHAT}" \
    -d parse_mode="HTML" \
    -d "text=$1" > /dev/null
}

# Step 1: Export DB from Docker container
if docker cp uptime-kuma:/app/data/kuma.db "${BACKUP_FILE}"; then
  SIZE=$(du -sh "${BACKUP_FILE}" | cut -f1)
else
  tg_send "$(printf '<b>\u274c Kuma Backup FAILED</b>\n\ud83d\udda5 %s\n\u26a0\ufe0f docker cp завершился с ошибкой' "${SERVER_TAG}")"
  exit 1
fi

# Step 2: rsync to server 222
if rsync -avz "${BACKUP_FILE}" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"; then
  RSYNC_OK=1
else
  tg_send "$(printf '<b>\u274c Kuma Backup FAILED (rsync)</b>\n\ud83d\udda5 %s\n\u26a0\ufe0f Не удалось отправить на сервер 222' "${SERVER_TAG}")"
  rm -f "${BACKUP_FILE}"
  exit 1
fi

# Step 3: Keep only last 3 backups on remote
ssh "${REMOTE_USER}@${REMOTE_HOST}" \
  "ls -t ${REMOTE_DIR}/kuma_*.db 2>/dev/null | tail -n +$((KEEP+1)) | xargs rm -f"

COUNT=$(ssh "${REMOTE_USER}@${REMOTE_HOST}" "ls ${REMOTE_DIR}/kuma_*.db 2>/dev/null | wc -l")

# Step 4: Cleanup local tmp
rm -f "${BACKUP_FILE}"

# Step 5: Send success report to Telegram
tg_send "$(printf '<b>\u2705 Kuma Backup OK</b>\n\ud83d\udce6 Файл: <code>kuma_%s.db</code>\n\ud83d\udcd0 Размер: %s\n\ud83d\udda5 Сервер: %s\n\ud83d\udce4 Отправлен на сервер 222: %s\n\ud83d\uddc2 Бэкапов на 222: %s (макс. %s)\n\ud83d\udcc5 %s CET' \
  "$(date +%F)" "${SIZE}" "${SERVER_TAG}" "${REMOTE_DIR}" "${COUNT}" "${KEEP}" "$(date '+%d.%m.%Y %H:%M')")"
