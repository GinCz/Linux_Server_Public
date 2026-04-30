#!/usr/bin/env bash
# =============================================================================
# scan_clamav.sh — ClamAV universal scanner + Telegram report
# Version     : v2026-04-30
# Usage       : bash /root/Linux_Server_Public/222/scan_clamav.sh
# Auto-detect : FastPanel (/var/www/) or VPN/generic (/root /home /usr/local)
# NOTE        : Read-only, never deletes files.
# = Rooted by VladiMIR | AI =
# =============================================================================
clear

C='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; X='\033[0m'
SERVER_NAME=$(hostname)
LOG_FILE="/tmp/clamav_scan_${SERVER_NAME}.log"
source /root/.server_alliances.conf 2>/dev/null || true
> "$LOG_FILE"

echo -e "${Y}>>> Запуск антивируса ClamAV на ${SERVER_NAME}...${X}"

echo "1. Обновление антивирусных баз..."
systemctl stop clamav-freshclam 2>/dev/null
freshclam 2>&1 | head -3
systemctl start clamav-freshclam 2>/dev/null
echo -e "${C}Готово!${X}"

# Auto-detect: FastPanel sites OR system directories
if [ -d /var/www ] && [ "$(ls /var/www/ 2>/dev/null | wc -l)" -gt 0 ]; then
  SCAN_DIRS="/var/www/*/data/www/"
  SCAN_MODE="FastPanel sites"
else
  SCAN_DIRS="/root /home /usr/local/bin /usr/local/x-ui /etc/x-ui"
  SCAN_MODE="system files (VPN/generic)"
fi

echo -n "2. Подсчет файлов для проверки... "
TOTAL_FILES=$(find $SCAN_DIRS -type f 2>/dev/null | wc -l)
echo -e "${C}Найдено ${TOTAL_FILES} файлов [${SCAN_MODE}].${X}"

echo -e "3. Начинаю глубокое сканирование (работает в фоне для дисков, не мешает сайтам)...\n"

( nice -n 19 ionice -c 3 clamscan -r --no-summary $SCAN_DIRS 2>/dev/null | awk -v total="$TOTAL_FILES" -v logfile="$LOG_FILE" '
{
    count++
    if (total > 0 && (count % 100 == 0 || count == total)) {
        pct = (count/total)*100
        printf "\r\u23f3 Progress: [%.1f%%] (%d / %d files) \033[K", pct, count, total
        fflush()
    }
    if ($0 ~ / FOUND$/) {
        printf "\n\033[0;31m\u26a0\ufe0f  THREAT: %s\033[0m\n", $0
        print $0 >> logfile
        fflush()
    }
}' ) &
CLAM_PID=$!
wait $CLAM_PID

echo -e "\n\n${C}>>> Сканирование завершено! Обработка результатов...${X}"

INFECTED_COUNT=0
[ -f "$LOG_FILE" ] && INFECTED_COUNT=$(wc -l < "$LOG_FILE")

if [ "$INFECTED_COUNT" -gt 0 ]; then
  REPORT_MSG="\u26a0\ufe0f SERVER: ${SERVER_NAME}%0A\ud83e\uddab ClamAV: Found ${INFECTED_COUNT} threat(s)!%0AMode: ${SCAN_MODE}%0A%0ATop 10:%0A"
  BAD_FILES=$(head -n 10 "$LOG_FILE" | awk -F: '{print $1}')
  REPORT_MSG="${REPORT_MSG}${BAD_FILES}"
  echo -e "${R}\u26a0\ufe0f  Найдены угрозы! Отправляю алерт в Telegram.${X}"
  [ -n "${TG_TOKEN:-}" ] && curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -d "chat_id=${TG_CHAT_ID}&text=${REPORT_MSG}" > /dev/null
else
  SUCCESS_MSG="\u2705 SERVER: ${SERVER_NAME}%0AClamAV done.%0AMode: ${SCAN_MODE}%0AFiles: ${TOTAL_FILES}.%0ANo threats!"
  echo -e "${C}\u2705 Вирусов нет! Отправляю зеленый отчет в Telegram.${X}"
  [ -n "${TG_TOKEN:-}" ] && curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -d "chat_id=${TG_CHAT_ID}&text=${SUCCESS_MSG}" > /dev/null
fi
