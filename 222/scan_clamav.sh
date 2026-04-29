#!/usr/bin/env bash
# =============================================================================
# scan_clamav.sh — ClamAV low-priority scanner with progress bar + Telegram
# Version     : v2026-04-30
# Server      : 222-DE-NetCup (152.53.182.222)
# Usage       : bash /root/Linux_Server_Public/222/scan_clamav.sh
# NOTE        : Read-only scan, never deletes files. High CPU/IO — run at night.
# = Rooted by VladiMIR | AI =
# =============================================================================
clear

C='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; X='\033[0m'
SERVER_NAME=$(hostname)
LOG_FILE="/tmp/clamav_scan_${SERVER_NAME}.log"
source /root/.server_alliances.conf 2>/dev/null || true
> "$LOG_FILE"

echo -e "${Y}>>> Starting ClamAV scan on ${SERVER_NAME}...${X}"

echo -n "1. Updating virus definitions... "
systemctl stop clamav-freshclam 2>/dev/null
freshclam --quiet
systemctl start clamav-freshclam 2>/dev/null
echo -e "${C}Done!${X}"

echo -n "2. Counting files... "
TOTAL_FILES=$(find /var/www/*/data/www/ -type f 2>/dev/null | wc -l)
echo -e "${C}Found ${TOTAL_FILES} files.${X}"

echo -e "3. Scanning (low priority, safe for live sites)...\n"

nice -n 19 ionice -c 3 clamscan -r --no-summary /var/www/*/data/www/ 2>/dev/null | awk -v total="$TOTAL_FILES" -v logfile="$LOG_FILE" '
{
    count++
    if (count % 50 == 0 || count == total) {
        pct = (count/total)*100
        printf "\r\u23f3 Progress: [%.1f%%] (%d / %d files) \033[K", pct, count, total
        fflush()
    }
    if ($0 ~ / FOUND$/) {
        printf "\n\033[0;31m\u26a0\ufe0f  THREAT: %s\033[0m\n", $0
        print $0 >> logfile
        fflush()
    }
}'

echo -e "\n\n${C}>>> Scan complete!${X}"

INFECTED_COUNT=0
[ -f "$LOG_FILE" ] && INFECTED_COUNT=$(wc -l < "$LOG_FILE")

if [ "$INFECTED_COUNT" -gt 0 ]; then
    REPORT_MSG="\u26a0\ufe0f SERVER: ${SERVER_NAME}%0A\ud83e\uddab ClamAV: Found ${INFECTED_COUNT} threat(s)!%0A%0ATop 10:%0A"
    BAD_FILES=$(head -n 10 "$LOG_FILE" | awk -F: '{print $1}')
    REPORT_MSG="${REPORT_MSG}${BAD_FILES}"
    echo -e "${R}\u26a0\ufe0f  Threats found! Sending Telegram alert!${X}"
    [ -n "${TG_TOKEN:-}" ] && curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
      -d "chat_id=${TG_CHAT_ID}&text=${REPORT_MSG}" > /dev/null
else
    SUCCESS_MSG="\u2705 SERVER: ${SERVER_NAME}%0AClamAV done.%0AFiles scanned: ${TOTAL_FILES}.%0ANo threats found!"
    echo -e "${C}\u2705 No viruses found!${X}"
    [ -n "${TG_TOKEN:-}" ] && curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
      -d "chat_id=${TG_CHAT_ID}&text=${SUCCESS_MSG}" > /dev/null
fi
