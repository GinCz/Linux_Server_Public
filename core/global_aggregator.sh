#!/usr/bin/env bash
# English comments: Central Aggregator (on 222)
source /root/.server_env
cd /root/public_git
git pull

# Список всех твоих серверов, где работает сбор IP
SERVERS=("xxx.xxx.xxx.109" "xxx.xxx.xxx.222") 

for S_IP in "${SERVERS[@]}"; do
    if [ "$S_IP" == "xxx.xxx.xxx.222" ]; then
        # Если это сам 222-й, просто копируем локально
        cp /tmp/current_bans.txt security/caught_by_${S_IP}.txt 2>/dev/null
    else
        # Забираем файл с удаленного сервера (109 и др.)
        scp -o ConnectTimeout=5 root@$S_IP:/tmp/current_bans.txt security/caught_by_${S_IP}.txt 2>/dev/null
    fi
done

# Объединяем, убираем белый список и дубликаты
cat security/caught_by_*.txt 2>/dev/null | sort -u | grep -vFf security/whitelist.txt > security/global_ban_list.txt

# Отправляем в GitHub (у 222-го есть доступ)
git add security/*.txt
git commit -m "Security: Global Sync [$(date +%T)]"
git push
