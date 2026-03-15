#!/usr/bin/env bash
clear
source /root/scripts/common.sh
lock_or_exit system_backup

NODE="$(detect_node)"
REMOTE_IP="$(pair_ip "$NODE")"
STAMP="$(date +%d-%m-%Y)"
HOST="$(hostname 2>/dev/null || echo unknown)"
TAG="${SERVER_TAG:-$HOST}"

if [ "$NODE" = "unknown" ] || [ -z "$REMOTE_IP" ]; then
  msg="🚨 *Backup error* %0A🌐 Server: ${TAG} %0A❌ Cannot detect node role (222/109)."
  is_interactive && notify_error_once "backup_detect_${HOST}" "$msg"
  echo "Cannot detect node role"
  exit 1
fi

FILE="BackUp_${NODE}__${TAG}__${STAMP}.tar.gz"
TMP="/tmp/${FILE}"
LOCAL_DIR="${BACKUP_DIR}/${NODE}"
LOCAL_COPY="${LOCAL_DIR}/${FILE}"

mkdir -p "$LOCAL_DIR"

if ! tar -czf "$TMP" /etc /root /usr/local/fastpanel /usr/local/bin \
  --exclude='/root/*.tar.gz' \
  --exclude='/root/*.0.0' \
  --exclude='/var/www/*/data/www/*' \
  --exclude='/var/www/*/data/backups/*' \
  --exclude='/home/samba/*' 2>/dev/null; then
  msg="🚨 *Backup error* %0A🌐 Server: ${TAG} %0A❌ Local archive creation failed."
  is_interactive && notify_error_once "backup_tar_${HOST}" "$msg"
  echo "Archive creation failed"
  exit 1
fi

cp -f "$TMP" "$LOCAL_COPY"
find "$LOCAL_DIR" -maxdepth 1 -type f -name "BackUp_${NODE}__*.tar.gz" | sort | head -n -50 2>/dev/null | xargs -r rm -f || true

if ! sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@"$REMOTE_IP" "mkdir -p ${BACKUP_DIR}/${NODE}" >/dev/null 2>&1; then
  msg="🚨 *Backup error* %0A🌐 Server: ${TAG} %0A❌ Remote mkdir failed on ${REMOTE_IP}."
  is_interactive && notify_error_once "backup_mkdir_${HOST}_${REMOTE_IP}" "$msg"
  echo "Remote mkdir failed"
  exit 1
fi

if ! sshpass -p "$REMOTE_PASS" rsync -az -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" "$TMP" root@"$REMOTE_IP":"${BACKUP_DIR}/${NODE}/" >/dev/null 2>&1; then
  msg="🚨 *Backup error* %0A🌐 Server: ${TAG} %0A❌ Transfer to ${REMOTE_IP} failed."
  is_interactive && notify_error_once "backup_rsync_${HOST}_${REMOTE_IP}" "$msg"
  echo "Transfer failed"
  exit 1
fi

sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@"$REMOTE_IP" \
  "find ${BACKUP_DIR}/${NODE} -maxdepth 1 -type f -name 'BackUp_${NODE}__*.tar.gz' | sort | head -n -50 2>/dev/null | xargs -r rm -f" >/dev/null 2>&1 || true

rm -f "$TMP"
echo "Backup complete: $LOCAL_COPY and root@${REMOTE_IP}:${BACKUP_DIR}/${NODE}/${FILE}"
