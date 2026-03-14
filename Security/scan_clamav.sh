#!/usr/bin/env bash
# ClamAV Low-Priority Scanner (Live % Progress) for Ing. VladiMIR Bulantsev
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
# Считаем точное количество файлов сайтов
TOTAL_FILES=$(find /var/www/*/data/www/ -type f 2>/dev/null | wc -l)
echo -e "${C}Найдено ${TOTAL_FILES} файлов.${X}"

echo -e "3. Начинаю глубокое сканирование (работает в фоне для дисков, не мешает сайтам)...\n"

# Магия: запускаем clamscan, скрываем итоги (--no-summary) и фильтруем вывод через awk
nice -n 19 ionice -c 3 clamscan -r --no-summary /var/www/*/data/www/ 2>/dev/null | awk -v total="$TOTAL_FILES" -v log="$LOG_FILE" '
{
    count++
    # Обновляем прогресс-бар каждые 50 файлов, чтобы терминал не "мерцал"
    if (count % 50 == 0 || count == total) {
        pct = (count/total)*100
        # \r возвращает каретку в начало, \033[K стирает остаток строки
        printf "\r⏳ Прогресс: [%.1f%%] (%d / %d файлов) \033[K", pct, count, total
        fflush()
    }
    # Если найден вирус - печатаем его красным на новой строке и пишем в лог
    if ($0 ~ / FOUND$/) {
        printf "\n\033[0;31m⚠️ УГРОЗА: %s\033[0m\n", $0
        print $0 >> log
        fflush()
    }
}'

echo -e "\n\n${C}>>> Сканирование завершено! Обработка результатов...${X}"

# Проверяем, есть ли что-то в логе заражений
INFECTED_COUNT=0
[ -f "$LOG_FILE" ] && INFECTED_COUNT=$(wc -l < "$LOG_FILE")

if [ "$INFECTED_COUNT" -gt 0 ]; then
    REPORT_MSG="⚠️ SERVER: ${SERVER_NAME}\n🦠 ClamAV Alert: Найдены угрозы (${INFECTED_COUNT} шт.)!\n\nТоп 10:\n"
    BAD_FILES=$(head -n 10 "$LOG_FILE" | awk -F: '{print $1}')
    REPORT_MSG="${REPORT_MSG}${BAD_FILES}"
    
    echo -e "${R}⚠️ Отправляю алерт в Telegram!${X}"
    if [[ $(type -t send_tg) == function ]]; then
        send_tg "$REPORT_MSG"
    fi
else
    SUCCESS_MSG="✅ SERVER: ${SERVER_NAME}\nClamAV завершил проверку.\nПроверено файлов: ${TOTAL_FILES}.\nУгроз не обнаружено!"
    echo -e "${C}✅ Вирусов нет! Отправляю зеленый отчет в Telegram.${X}"
    if [[ $(type -t send_tg) == function ]]; then
        send_tg "$SUCCESS_MSG"
    fi
fi
