#!/usr/bin/env bash
# Integration: FIGHT + CrowdSec + Global System
source /root/.server_env
MY_NAME=$(hostname)
TEMP_FILE="/tmp/current_bans.txt"
GIT_FILE="/root/scripts/security/caught_by_${MY_NAME}.txt"
WHITELIST="/root/scripts/security/whitelist.txt"

# 1. Собираем IP из IPTABLES
iptables -L INPUT -n | grep DROP | awk '{print $4}' | grep -E '^[0-9.]+$' > /tmp/raw_bans.txt

# 2. Добавляем IP из CROWDSEC (если он установлен)
if command -v cscli &> /dev/null; then
    cscli decisions list -o raw | awk -F',' '{print $3}' | grep -E '^[0-9.]+$' >> /tmp/raw_bans.txt
fi

# 3. Фильтруем через Белый список
grep -vFf <(grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' $WHITELIST 2>/dev/null || echo "127.0.0.1") /tmp/raw_bans.txt | sort -u > $TEMP_FILE

# 4. Пушим, если есть результат
if [ -s $TEMP_FILE ]; then
    mkdir -p /root/scripts/security
    cp $TEMP_FILE $GIT_FILE
    cd /root/scripts
    git pull
    git add security/caught_by_${MY_NAME}.txt
    git commit -m "Security Sync: $MY_NAME shared $(wc -l < $TEMP_FILE) bans" && git push
fi
