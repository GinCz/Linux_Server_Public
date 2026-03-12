#!/usr/bin/env bash
cd /root/public_git
git pull

BAN_FILE="security/global_ban_list.txt"
WHITELIST="security/whitelist.txt"
OLD_COUNT=$(wc -l < $BAN_FILE 2>/dev/null || echo 0)

# Сборка списка
cat security/caught_by_*.txt 2>/dev/null | sort -u | grep -vFf $WHITELIST > $BAN_FILE
NEW_COUNT=$(wc -l < $BAN_FILE)

# Уведомляем только если прибавилось более 50 новых врагов за раз (сигнал атаки)
DIFF=$((NEW_COUNT - OLD_COUNT))
if [ "$DIFF" -gt 50 ]; then
    MESSAGE="🛡️ SECURITY ALERT: Massive attack detected! Added $DIFF new IPs to Global Ban List. Total: $NEW_COUNT"
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" -d "chat_id=${TG_CHAT_ID}&text=$MESSAGE" > /dev/null
fi

git add $BAN_FILE && git commit -m "Security: Global Ban List updated" && git push
