#!/usr/bin/env bash
# ClamAV Database Sync (Donor/Receiver) for Ing. VladiMIR Bulantsev | 2026

SERVER_ROLE=$1 # --donor or --receiver
DB_DIR="/var/lib/clamav"
# Путь на 222 сервере, доступный извне
EXPORT_PATH="/var/www/dmitry-vary/data/www/czechtoday.eu/clam_db.tar.gz"
DONOR_IP="xxx.xxx.xxx.222"

clear
if [ "$SERVER_ROLE" == "--donor" ]; then
    echo ">>> Role: DONOR. Updating and packing databases..."
    systemctl stop clamav-freshclam 2>/dev/null
    freshclam --quiet
    tar -czf "$EXPORT_PATH" -C "$DB_DIR" .
    chmod 644 "$EXPORT_PATH"
    systemctl start clamav-freshclam 2>/dev/null
    echo "✅ Database archive created at $EXPORT_PATH"

elif [ "$SERVER_ROLE" == "--receiver" ]; then
    echo ">>> Role: RECEIVER. Downloading databases from $DONOR_IP..."
    cd "$DB_DIR" || exit
    wget -q --header="Host: czechtoday.eu" http://"$DONOR_IP"/clam_db.tar.gz -O clam_db.tar.gz
    if [ $? -eq 0 ]; then
        tar -xzf clam_db.tar.gz
        rm clam_db.tar.gz
        chown -R clamav:clamav "$DB_DIR"
        echo "✅ Database successfully updated from donor."
    else
        echo "❌ Error: Could not download database from donor!"
        exit 1
    fi
else
    echo "Usage: $0 --donor | --receiver"
    exit 1
fi
