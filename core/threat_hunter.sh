#!/usr/bin/env bash
# English comments: Integration bridge between FIGHT script and Global Ban System
source /root/.server_env
MY_NAME=$(hostname)
TEMP_FILE="/tmp/current_bans.txt"
GIT_FILE="/root/scripts/security/caught_by_${MY_NAME}.txt"

# 1. Достаем все IP, которые уже забанены в iptables (включая те, что поймал FIGHT)
iptables -L INPUT -n | grep DROP | awk '{print $4}' | grep -E '^[0-9.]+$' | sort -u > $TEMP_FILE

# 2. Если нашли забаненные IP, обновляем файл для синхронизации
if [ -s $TEMP_FILE ]; then
    mkdir -p /root/scripts/security
    cp $TEMP_FILE $GIT_FILE
    
    cd /root/scripts
    git pull
    git add security/caught_by_${MY_NAME}.txt
    # Коммитим только если есть реальные изменения
    git commit -m "Security Sync: $MY_NAME shared $(wc -l < $TEMP_FILE) bans" && git push
fi
