#!/bin/bash
# =============================================================================
#  backup_gin_chat.sh - Automated Backup for GIN-Chat (CloudCore-191 -> DE-222)
#  = Rooted by VladiMIR + AI | github.com/GinCz =
# =============================================================================
set -e

DATE=$(date +%Y-%m-%d_%H-%M)
REMOTE_IP="31.59.126.191"
SSH_KEY="/root/.ssh/id_ed25519"
SSH_USER="root"
SSH_PORT=22
DEST_DIR="/BACKUP/gin-chat"
DEST_ROOT_DIR="/root/backups/gin-chat"
KEEP=7
REMOTE_TMP="/tmp"
ARCH_NAME="gin_chat_backup_${DATE}.tar.gz"
REMOTE_ARCH="${REMOTE_TMP}/${ARCH_NAME}"
LOCAL_ARCH="${DEST_DIR}/${ARCH_NAME}"

mkdir -p "$DEST_DIR" "$DEST_ROOT_DIR"

echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] Starting GIN-Chat Backup from CloudCore-191 ($REMOTE_IP) ==="

# 1. Safely checkpoint SQLite on CloudCore-191 & create archive
ssh -i "$SSH_KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=no "$SSH_USER@$REMOTE_IP" "
  if [ -f /opt/gin-chat/data/chat.db ]; then
    sqlite3 /opt/gin-chat/data/chat.db 'PRAGMA wal_checkpoint(TRUNCATE);' 2>/dev/null || true
  fi
  tar --exclude='node_modules' --exclude='.git' -czf '${REMOTE_ARCH}' -C /opt gin-chat
"

# 2. Download archive to DE-222
scp -i "$SSH_KEY" -P "$SSH_PORT" -o StrictHostKeyChecking=no "$SSH_USER@$REMOTE_IP:${REMOTE_ARCH}" "$LOCAL_ARCH"
ssh -i "$SSH_KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=no "$SSH_USER@$REMOTE_IP" "rm -f ${REMOTE_ARCH}"

# 3. Mirror to /root/backups/gin-chat
cp -f "$LOCAL_ARCH" "$DEST_ROOT_DIR/"

# 4. Rotate old backups (keep last $KEEP)
ls -1t "$DEST_DIR"/gin_chat_backup_*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f
ls -1t "$DEST_ROOT_DIR"/gin_chat_backup_*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f

SZ=$(du -sh "$LOCAL_ARCH" | cut -f1)
echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] GIN-Chat Backup Complete from CloudCore-191: ${LOCAL_ARCH} (${SZ}) ==="
