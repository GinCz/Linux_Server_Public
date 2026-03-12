#!/usr/bin/env bash
# VladiMIR Attack Monitor 2026
source /root/.server_env
source /root/scripts/common.sh

THRESHOLD=50000  # Порог запросов за 3 часа
LOG_DIR="/var/www"
TMP_REPORT="/tmp/attack_report.txt"

# 1. Поиск самого нагруженного сайта
VICTIM_LOG=$(find $LOG_DIR -name "*.access.log" -mmin -180 -exec du -b {} + | sort -nr | head -n1 | awk '{print $2}')
[ -z "$VICTIM_LOG" ] && exit 0

DOMAIN=$(basename "$VICTIM_LOG" | cut -d'-' -f1 | cut -d'.' -f1,2)
REQ_COUNT=$(tail -c 50M "$VICTIM_LOG" | wc -l)

# 2. Если превышен порог — анализируем тип атаки
if [ "$REQ_COUNT" -gt "$THRESHOLD" ]; then
    
    # Определяем тип (Bruteforce, Scan или Crawl)
    ATTACK_TYPE="Unknown High Traffic"
    if grep -qiE "wp-login|xmlrpc|admin" "$VICTIM_LOG"; then
        ATTACK_TYPE="Bruteforce / WP-Scan"
    elif grep -qiE "select|union|etc/passwd" "$VICTIM_LOG"; then
        ATTACK_TYPE="SQL Injection / Exploit Scan"
    elif tail -n 1000 "$VICTIM_LOG" | awk '{print $1}' | sort | uniq -c | sort -nr | head -n1 | awk '$1 > 500 {print "Yes"}' | grep -q "Yes"; then
        ATTACK_TYPE="DDoS / Single IP Flood"
    else
        ATTACK_TYPE="Heavy Crawling / Botnet"
    fi

    TOP_IPS=$(tail -n 10000 "$VICTIM_LOG" | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 3)

    # 3. Формируем сообщение
    MESSAGE="🚨 *ATTACK ALERT: $SERVER_TAG*
🌐 *Domain:* $DOMAIN
📈 *Requests (3h):* $REQ_COUNT
🛡 *Attack Type:* $ATTACK_TYPE

🔝 *Top Attacking IPs:*
$TOP_IPS"

    # 4. Отправка в Telegram
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d "chat_id=$TG_CHAT_ID" \
        -d "parse_mode=Markdown" \
        -d "text=$MESSAGE" > /dev/null
fi
