#!/usr/bin/env bash
# ClamAV Low-Priority Scanner for Ing. VladiMIR Bulantsev | 2026
# Strict Read-Only Mode: reports only, never deletes or modifies files.

source /root/scripts/System/common.sh 2>/dev/null

SERVER_NAME=$(hostname)
LOG_FILE="/tmp/clamav_scan_${SERVER_NAME}.log"
# Сканируем только папки с сайтами FastPanel
SCAN_DIR="/var/www/"

clear
echo -e "\033[1;33m>>> Starting ClamAV update on ${SERVER_NAME}...\033[0m"

# Обновляем антивирусные базы (останавливаем службу, если она блокирует базу)
systemctl stop clamav-freshclam 2>/dev/null
freshclam --quiet
systemctl start clamav-freshclam 2>/dev/null

echo -e "\033[1;33m>>> Starting deep scan with lowest priority (nice 19, ionice 3)...\033[0m"
echo "This may take a while. It runs safely in the background."

# Запускаем проверку с самым низким приоритетом CPU (nice -n 19) и Диска (ionice -c 3)
# -i : выводить только зараженные файлы
# -r : рекурсивно по всем папкам
nice -n 19 ionice -c 3 clamscan -i -r /var/www/*/data/www/ > "$LOG_FILE"

# Считаем количество угроз
INFECTED_COUNT=$(grep -c "FOUND" "$LOG_FILE")

if [ "$INFECTED_COUNT" -gt 0 ]; then
    REPORT_MSG="⚠️ SERVER: ${SERVER_NAME}\n🦠 ClamAV Alert: Found ${INFECTED_COUNT} infected files!\n\nTop 10 detections:\n"
    # Достаем первые 10 путей зараженных файлов для Телеграм
    BAD_FILES=$(grep "FOUND" "$LOG_FILE" | head -n 10 | awk -F: '{print $1}')
    REPORT_MSG="${REPORT_MSG}${BAD_FILES}\n\nFull log: cat $LOG_FILE"
    
    echo -e "\033[0;31m$REPORT_MSG\033[0m"
    if [[ $(type -t send_tg) == function ]]; then
        send_tg "$REPORT_MSG"
    fi
else
    SUCCESS_MSG="✅ SERVER: ${SERVER_NAME}\nClamAV scan complete. No threats found in websites."
    echo -e "\033[0;32m$SUCCESS_MSG\033[0m"
    if [[ $(type -t send_tg) == function ]]; then
        send_tg "$SUCCESS_MSG"
    fi
fi
