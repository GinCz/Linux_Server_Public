#!/usr/bin/env bash
# ClamAV Nightly Scanner — ALL servers
# Author: Ing. VladiMIR Bulantsev | v.2026.05.30
# — Syncs DB before scan (donor on 222, receiver on all others)
# — Scans /var/www/*/data/www/ with low priority (no impact on sites)
# — Silent Telegram alert ONLY if threats found. No alert = all clean.
# — Cleans temp files after scan
# Cron DE-222: 0 3 * * * /root/scripts/scan_clamav.sh > /dev/null 2>&1
# Cron others: 0 3 * * * /root/scripts/scan_clamav.sh > /dev/null 2>&1
# = Rooted by VladiMIR + AI | v.2026.05.30 | github.com/GinCz =

source /root/.server_alliances.conf 2>/dev/null || true

SERVER_NAME=$(hostname)
LOG_FILE="/tmp/clamav_scan_${SERVER_NAME}.log"
> "$LOG_FILE"

# Detect role: DE-222 = donor, all others = receiver
MY_IP=$(hostname -I | awk '{print $1}')
if [ "$MY_IP" = "152.53.182.222" ]; then
    SYNC_ROLE="--donor"
else
    SYNC_ROLE="--receiver"
fi

# Step 1: Sync DB (donor freshclam, receiver download from 222)
if [ -f /root/scripts/sync_clamav_db.sh ]; then
    bash /root/scripts/sync_clamav_db.sh "$SYNC_ROLE" 2>/dev/null
fi

# Step 2: Count files
TOTAL_FILES=$(find /var/www/*/data/www/ -type f 2>/dev/null | wc -l)

# Step 3: Scan with low priority
nice -n 19 ionice -c 3 clamscan -r --no-summary /var/www/*/data/www/ 2>/dev/null \
    | awk -v logfile="$LOG_FILE" '
        { if ($0 ~ / FOUND$/) { print $0 >> logfile } }
    '

# Step 4: Alert only if threats found
INFECTED_COUNT=0
[ -f "$LOG_FILE" ] && INFECTED_COUNT=$(wc -l < "$LOG_FILE")

if [ "$INFECTED_COUNT" -gt 0 ]; then
    BAD_FILES=$(head -n 15 "$LOG_FILE" | sed 's/:/\n/g' | awk 'NR%2==1' | head -n 15)
    MSG="%F0%9F%A6%A0 ClamAV ALERT%0A%F0%9F%96%A5 Server: ${SERVER_NAME}%0A%E2%9A%A0%EF%B8%8F Threats found: ${INFECTED_COUNT}%0A%F0%9F%93%81 Files checked: ${TOTAL_FILES}%0A%0A${BAD_FILES}"
    [ -n "${TG_TOKEN:-}" ] && curl -s -X POST \
        "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d "chat_id=${TG_CHAT_ID}" \
        -d "text=${MSG}" \
        -d "disable_notification=true" > /dev/null
fi

# Step 5: Cleanup
rm -f "$LOG_FILE"
find /tmp -name "clamav-*" -mtime +1 -delete 2>/dev/null
