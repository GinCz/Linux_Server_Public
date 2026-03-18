#!/bin/bash
# Description: Full System Config Backup (Transfer to Remote Storage)
# Author: Ing. VladiMIR Bulantsev | 13/03/2026
# Target: Transfer archive from DE_222 to 109_RU

# --- CONFIGURATION ---
PASS="${BACKUP_REMOTE_PASS:-}"
TOKEN="${TG_TOKEN:-}"
CHAT_ID="${TG_CHAT_ID:-}"
SERVER_NAME="DE_222"
REMOTE_IP="212.109.223.109"
BACKUP_DIR="/BACKUP"
TIMESTAMP=$(date +%d-%m-%Y)
FILENAME="BackUp_${SERVER_NAME}__${TIMESTAMP}.tar.gz"

# --- [1] PRE-CLEANUP (Save space before archiving) ---
# Clean system journals, apt cache and benchmark leftovers
journalctl --vacuum-time=1s >/dev/null 2>&1
apt-get clean
rm -f /root/*.0.0 /root/test_file ~/temp_vps_test

# --- [2] CREATING ARCHIVE ---
# We back up critical configs and root files only
tar -czf /tmp/$FILENAME /etc /root /usr/local/fastpanel \
--exclude='/root/scripts' \
--exclude='/var/www/*/data/www/*' \
--exclude='/var/www/*/data/backups/*' \
--exclude='/home/samba/*' 2>/dev/null

# --- [3] TRANSFER & ROTATION ---
# Create remote directory if missing and transfer file
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$REMOTE_IP "mkdir -p $BACKUP_DIR"
sshpass -p "$PASS" rsync -az /tmp/$FILENAME root@$REMOTE_IP:$BACKUP_DIR/
STATUS=$?

# Keep only the last 50 backups on the remote server
sshpass -p "$PASS" ssh root@$REMOTE_IP "ls -t $BACKUP_DIR/BackUp_${SERVER_NAME}__*.tar.gz | tail -n +51 | xargs -r rm -f"

# --- [4] NOTIFICATION LOGIC ---
if [ $STATUS -ne 0 ]; then
    # Only notify Telegram on failure
    MESSAGE="🚨 *BACKUP ERROR!* 🚨%0A🌐 Server: $SERVER_NAME%0A❌ Failed to transfer backup to $REMOTE_IP"
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESSAGE&parse_mode=Markdown"
else
    # Success: cleanup local temp file
    rm -f /tmp/$FILENAME
fi
