#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  sync_clamav_db.sh | [v2026-05-30]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : ClamAV database sync between donor (222) and receiver nodes
# Servers     : All Linux Nodes
# Usage       : bash scripts/sync_clamav_db.sh
# ==========================================================================================
SERVER_ROLE=$1
DB_DIR="/var/lib/clamav"
# gincz.com — not included in czechtoday.eu backups
EXPORT_PATH="/var/www/gincz/data/www/gincz.com/clam_db.tar.gz"
DONOR_IP="152.53.182.222"

if [ "$SERVER_ROLE" == "--donor" ]; then
    systemctl stop clamav-freshclam 2>/dev/null
    freshclam --quiet 2>/dev/null
    tar -czf "$EXPORT_PATH" -C "$DB_DIR" .
    chmod 644 "$EXPORT_PATH"
    systemctl start clamav-freshclam 2>/dev/null
    # Cleanup temp files
    find "$DB_DIR" -name "*.tmp" -delete 2>/dev/null
    find /tmp -name "clamav-*" -mtime +1 -delete 2>/dev/null

elif [ "$SERVER_ROLE" == "--receiver" ]; then
    cd "$DB_DIR" || exit 1
    wget -q --header="Host: gincz.com" \
        "http://${DONOR_IP}/clam_db.tar.gz" -O clam_db.tar.gz
    if [ $? -eq 0 ]; then
        tar -xzf clam_db.tar.gz
        rm -f clam_db.tar.gz
        chown -R clamav:clamav "$DB_DIR"
        # Cleanup temp files
        find "$DB_DIR" -name "*.tmp" -delete 2>/dev/null
        find /tmp -name "clamav-*" -mtime +1 -delete 2>/dev/null
    else
        exit 1
    fi
else
    echo "Usage: $0 --donor | --receiver"
    exit 1
fi

# = Rooted by VladiMIR | AI = v2026-05-30 = github.com/GinCz/Linux_Server_Public
