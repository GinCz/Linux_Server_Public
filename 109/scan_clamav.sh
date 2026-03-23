#!/usr/bin/env bash
# ClamAV Low-Priority Scanner (Live % Progress) for Ing. VladiMIR Bulantsev | 2026
# Strict Read-Only Mode: reports only, never deletes or modifies files.

source /root/scripts/System/common.sh 2>/dev/null

clear
C='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; X='\033[0m'
SERVER_NAME=$(hostname)
LOG_FILE="/tmp/clamav_scan_${SERVER_NAME}.log"
> "$LOG_FILE" # Очищаем старый лог перед стартом

echo -e "${Y}>>> Запуск антивируса ClamAV на ${SERVER_NAME}...${X}"

echo -n "1. Обновление антивирусных баз... "
systemctl stop clamav-freshclam 2>/dev/null
freshclam --quiet
systemctl start clamav-freshclam 2>/dev/null
echo -e "${C}Готово!${X}"

echo -n "2. Подсчет файлов для проверки... "
TOTAL_FILES=$(find /var/www/*/data/www/ -type f 2>/dev/null | wc -l)
echo -e "${C}Найдено ${TOTAL_FILES} файлов.${X}"

echo -e "3. Начинаю глубокое сканирование (работает в фоне для дисков, не мешает сайтам)...\n"

# Исправленный AWK (переменная теперь называется logfile)
nice -n 19 ionice -c 3 clamscan -r --no-summary /var/www/*/data/www/ 2>/dev/null | awk -v total="$TOTAL_FILES" -v logfile="$LOG_FILE" '
{
    count++
    # Обновляем прогресс-бар каждые 50 файлов, чтобы терминал не "мерцал"
    if (count % 50 == 0 || count == total) {
        pct = (count/total)*100
        printf "\r⏳ Прогресс: [%.1f%%] (%d / %d файлов) \033[K", pct, count, total
        fflush()
    }
    # Если найден вирус - печатаем его красным на новой строке и пишем в лог
    if ($0 ~ / FOUND$/) {
        printf "\n\033[0;31m⚠️ УГРОЗА: %s\033[0m\n", $0
        print $0 >> logfile
        fflush()
    }
}'

echo -e "\n\n${C}>>> Сканирование завершено! Обработка результатов...${X}"

# Проверяем, есть ли что-то в логе заражений
INFECTED_COUNT=0
[ -f "$LOG_FILE" ] && INFECTED_COUNT=$(wc -l < "$LOG_FILE")

if [ "$INFECTED_COUNT" -gt 0 ]; then
    REPORT_MSG="⚠️ SERVER: ${SERVER_NAME}%0A🦠 ClamAV Alert: Найдены угрозы (${INFECTED_COUNT} шт.)!%0A%0AТоп 10:%0A"
    BAD_FILES=$(head -n 10 "$LOG_FILE" | awk -F: '{print $1}')
    REPORT_MSG="${REPORT_MSG}${BAD_FILES}"
    
    echo -e "${R}⚠️ Отправляю алерт в Telegram!${X}"
    # Прямая надежная отправка через curl с форматированием %0A
    [ -n "$TG_TOKEN" ] && curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" -d "chat_id=${TG_CHAT_ID}&text=${REPORT_MSG}" > /dev/null
else
    SUCCESS_MSG="✅ SERVER: ${SERVER_NAME}%0AClamAV завершил проверку.%0AПроверено файлов: ${TOTAL_FILES}.%0AУгроз не обнаружено!"
    echo -e "${C}✅ Вирусов нет! Отправляю зеленый отчет в Telegram.${X}"
    [ -n "$TG_TOKEN" ] && curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" -d "chat_id=${TG_CHAT_ID}&text=${SUCCESS_MSG}" > /dev/null
fi
