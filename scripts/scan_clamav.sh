#!/usr/bin/env bash
# Script:  scan_clamav.sh
# Version: v2026-03-19
# Alias:   antivir
# Purpose: Install (if missing), update and run ClamAV deep scan in background.
#          Sends Telegram notification on completion.
#          Safe: read-only, never deletes or modifies files.
# Author:  Ing. VladiMIR Bulantsev

clear

C='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; X='\033[0m'
HOST=$(hostname)
DATE=$(date +%Y-%m-%d_%H-%M)
LOG="/var/log/clamav_scan_${HOST}_${DATE}.log"

# Load Telegram config
for CONF in /etc/server_alerts.conf ~/.server_alerts.conf; do
    [ -f "$CONF" ] && source "$CONF" && break
done

tg_send() {
    [ -z "${TG_TOKEN:-}" ] && return
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d chat_id="${TG_CHAT}" \
        -d parse_mode="HTML" \
        -d text="$1" > /dev/null
}

echo -e "${Y}========================================${X}"
echo -e "${Y} ClamAV Antivirus | ${HOST} | ${DATE}${X}"
echo -e "${Y}========================================${X}"

# Step 1: Install if missing
if ! command -v clamscan &>/dev/null; then
    echo -e "${Y}1. ClamAV not found — installing...${X}"
    apt-get update -qq && apt-get install -y clamav clamav-daemon -qq
    echo -e "${C}   Done!${X}"
else
    echo -e "${C}1. ClamAV is installed.${X}"
fi

# Step 2: Update virus databases
echo -e "${Y}2. Updating virus databases...${X}"
systemctl stop clamav-freshclam 2>/dev/null
freshclam --quiet 2>/dev/null
systemctl start clamav-freshclam 2>/dev/null
echo -e "${C}   Done!${X}"

# Step 3: Count files
echo -n "3. Counting files... "
TOTAL=$(find /var/www -type f 2>/dev/null | wc -l)
echo -e "${C}Found ${TOTAL} files.${X}"

# Step 4: Send start notification
tg_send "🔍 <b>ClamAV scan started</b>
🖥 Server: <b>${HOST}</b>
📁 Files: <b>${TOTAL}</b>
⏰ Started: $(date '+%Y-%m-%d %H:%M')

<i>You can close SSH — report will be sent on completion.</i>"

# Step 5: Run scan in background
echo -e "${Y}4. Starting deep scan in background...${X}"
echo -e "${C}   You can close SSH now — Telegram report will arrive on completion.${X}"
echo -e "   Log: ${LOG}"
echo ""

nohup bash -c "
    START=\$(date +%s)
    echo '=== ClamAV Scan | ${HOST} | $(date) ===' > '${LOG}'

    nice -n 19 ionice -c 3 clamscan -r /var/www \\
        --log='${LOG}' \\
        --infected \\
        --exclude-dir='^/var/www/.*/data/tmp' \\
        --exclude-dir='^/var/www/.*/data/cache' \\
        2>/dev/null

    END=\$(date +%s)
    ELAPSED=\$(( (END - START) / 60 ))
    INFECTED=\$(grep -c 'FOUND' '${LOG}' 2>/dev/null || echo 0)

    if [ \"\$INFECTED\" = '0' ]; then
        ICON='✅'
        STATUS='Clean — no threats found'
    else
        ICON='🚨'
        STATUS=\"INFECTED: \$INFECTED file(s)!\"
    fi

    curl -s -X POST 'https://api.telegram.org/bot${TG_TOKEN}/sendMessage' \\
        -d chat_id='${TG_CHAT}' \\
        -d parse_mode='HTML' \\
        -d text=\"\${ICON} <b>ClamAV scan DONE</b>
🖥 Server: <b>${HOST}</b>
📁 Scanned: <b>${TOTAL} files</b>
🦠 Result: <b>\${STATUS}</b>
⏱ Time: <b>\${ELAPSED} min</b>
📄 Log: ${LOG}\" > /dev/null
" >> "${LOG}" 2>&1 &

SCAN_PID=$!
echo -e "${C}✅ Scan running in background (PID: ${SCAN_PID})${X}"
echo -e "${C}📱 Telegram notification: @My_WWW_bot${X}"
echo -e "   Monitor: tail -f ${LOG}"
