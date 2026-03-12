#!/usr/bin/env bash
# Runs on 222 to merge all threat reports
cd /root/public_git
git pull

BAN_FILE="security/global_ban_list.txt"
WHITELIST="security/whitelist.txt"

# Объединяем все файлы caught_by_*.txt в один, исключая whitelist
cat security/caught_by_*.txt 2>/dev/null | sort -u | grep -vFf $WHITELIST > $BAN_FILE

git add $BAN_FILE
git commit -m "Security: Global Ban List updated [$(date +%d-%m-%Y)]"
git push
