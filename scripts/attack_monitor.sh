#!/usr/bin/env bash
# VladiMIR Attack Monitor 2026 - GLOBAL EDITION
source /root/.server_env
source /root/scripts/common.sh

THRESHOLD=50000
LOG_DIR="/var/www"

VICTIM_LOG=$(find $LOG_DIR -name "*.access.log" -mmin -180 -exec du -b {} + | sort -nr | head -n1 | awk '{print $2}')
[ -z "$VICTIM_LOG" ] && exit 0

DOMAIN=$(basename "$VICTIM_LOG" | cut -d'-' -f1 | cut -d'.' -f1,2)
REQ_COUNT=$(tail -c 50M "$VICTIM_LOG" | wc -l)

if [ "$REQ_COUNT" -gt "$THRESHOLD" ]; then
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
    BAD_IPS=$(echo "$TOP_IPS" | awk '{print $2}')

    # 1. Локальная блокировка
    echo "$BAD_IPS" >> /root/fight_blacklist.txt
    sort -u -o /root/fight_blacklist.txt /root/fight_blacklist.txt

    # 2. Глобальная синхронизация (Отправка на GitHub)
    cd /root/scripts
    git pull --rebase origin main > /dev/null 2>&1
    echo "$BAD_IPS" >> global_blacklist.txt
    sort -u -o global_blacklist.txt global_blacklist.txt
    git add global_blacklist.txt
    git commit -m "Auto-Ban: IPs added from $SERVER_TAG ($DOMAIN)"
    git push origin main > /dev/null 2>&1

    # 3. Уведомление в Telegram
    MESSAGE="🚨 *GLOBAL ATTACK ALERT: $SERVER_TAG*
🌐 *Domain:* $DOMAIN
📈 *Requests (3h):* $REQ_COUNT
🛡 *Type:* $ATTACK_TYPE

☠️ *Banned & Synced IPs:*
$TOP_IPS"

    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d "chat_id=$TG_CHAT_ID" \
        -d "parse_mode=Markdown" \
        -d "text=$MESSAGE" > /dev/null
fi
