#!/bin/bash
# Description: Full System Config Backup (Transfer to Remote Storage)
# Author: Ing. VladiMIR Bulantsev | 2026-08-01
# Target: Transfer archive from DE_222 to 109_RU
# NOTE: Set TG_TOKEN in /root/.server_env or export TG_TOKEN before running
# = Rooted by VladiMIR + AI | v.2026.08.01 | github.com/GinCz =

source /root/.server_env 2>/dev/null || true

PASS="OKMokm-09"
TOKEN="${TG_TOKEN:-}"
CHAT_ID="${TG_CHAT_ID:-261784949}"
SERVER_NAME="DE_222"
REMOTE_IP="212.109.223.109"
BACKUP_DIR="/BACKUP"
TIMESTAMP=$(date +%d-%m-%Y)
FILENAME="BackUp_${SERVER_NAME}__${TIMESTAMP}.tar.gz"

journalctl --vacuum-time=1s >/dev/null 2>&1
apt-get clean
rm -f /root/*.0.0 /root/test_file ~/temp_vps_test

tar -czf /tmp/$FILENAME /etc /root /usr/local/fastpanel \
--exclude='/root/scripts' \
--exclude='/var/www/*/data/www/*' \
--exclude='/var/www/*/data/backups/*' \
--exclude='/home/samba/*' 2>/dev/null

sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$REMOTE_IP "mkdir -p $BACKUP_DIR"
sshpass -p "$PASS" rsync -az /tmp/$FILENAME root@$REMOTE_IP:$BACKUP_DIR/
STATUS=$?

sshpass -p "$PASS" ssh root@$REMOTE_IP "ls -t $BACKUP_DIR/BackUp_${SERVER_NAME}__*.tar.gz | tail -n +51 | xargs -r rm -f"

if [ $STATUS -ne 0 ]; then
    [ -n "$TOKEN" ] && \
    MESSAGE="🚨 *BACKUP ERROR!* 🚨%0A🌐 Server: $SERVER_NAME%0A❌ Failed to transfer backup to $REMOTE_IP" && \
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESSAGE&parse_mode=Markdown"
else
    rm -f /tmp/$FILENAME
fi
