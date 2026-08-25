#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  cleanup_all_servers.sh | [v2026-08-25]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Запуск глубокой безопасной очистки диска на всех серверах кластера
# Run from    : Server 222 (DE Master) или локально по SSH
# Usage       : bash /root/Linux_Server_Public/scripts/cleanup_all_servers.sh
# ==========================================================================================

clear
C='\033[38;5;81m'; G='\033[0;92m'; Y='\033[0;93m'; W='\033[1;37m'; R='\033[1;31m'; X='\033[0m'
HR="${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"

echo -e "$HR"
echo -e "  ${W}🚀 МАССОВАЯ ГЛУБОКАЯ ОЧИСТКА ВСЕХ СЕРВЕРОВ КЛАСТЕРА${X}"
echo -e "  ${Y}Защита: Xray, Samba, FastPanel, Nginx, MariaDB, AdGuard Home, Uptime Kuma, SSH${X}"
echo -e "$HR"
echo

# 1. Сначала чистим локальный сервер (DE-222)
echo -e "  ${W}[0/11] Очистка локального мастера (${G}$(hostname)${W} / 152.53.182.222)...${X}"
if [ -f /root/Linux_Server_Public/scripts/server_cleanup.sh ]; then
    bash /root/Linux_Server_Public/scripts/server_cleanup.sh
fi

echo -e "\n$HR"
echo -e "  ${W}🚀 ЗАПУСК ОЧИСТКИ НА УДАЛЕННЫХ СЕРВЕРАХ...${X}"
echo -e "$HR\n"

SERVERS=(
  "212.109.223.109:RU-109"
  "109.234.38.47:Alex-47"
  "144.124.228.237:4Ton-237"
  "144.124.232.9:Tatra-9"
  "144.124.228.227:Shahin-227"
  "144.124.239.24:Stolb-24"
  "195.63.138.33:Pilik-33"
  "146.103.110.176:Ilya-176"
  "144.124.233.38:So-38"
  "18.195.117.12:AWS-12"
  "82.223.116.38:Ionos-38"
)

TOTAL=${#SERVERS[@]}
for i in "${!SERVERS[@]}"; do
  entry="${SERVERS[$i]}"
  IP="${entry%%:*}"
  NAME="${entry##*:}"
  INDEX=$((i + 1))

  echo -e "\n$HR"
  echo -e "  [${INDEX}/${TOTAL}] Подключение к ${W}${NAME}${X} (${C}${IP}${X})..."
  echo -e "$HR"

  if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@${IP} "true" 2>/dev/null; then
    echo -e "  ${R}✗ SSH FAILED (Недоступен или отклонен ключ)${X}"
    continue
  fi

  ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@${IP} 'bash -s' << 'REMOTE_PAYLOAD'
    # 1. Подтягиваем свежие скрипты
    if [ -d "/root/Linux_Server_Public/.git" ]; then
        cd /root/Linux_Server_Public && git fetch origin main --quiet 2>/dev/null && git reset --hard origin/main --quiet 2>/dev/null
    fi
    # 2. Копируем в /usr/local/bin
    if [ -f /root/Linux_Server_Public/scripts/server_cleanup.sh ]; then
        cp -f /root/Linux_Server_Public/scripts/server_cleanup.sh /usr/local/bin/server_cleanup.sh 2>/dev/null || true
        chmod +x /usr/local/bin/server_cleanup.sh 2>/dev/null || true
        bash /usr/local/bin/server_cleanup.sh
    else
        bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/server_cleanup.sh)
    fi
REMOTE_PAYLOAD

done

echo -e "\n$HR"
echo -e "  ${G}✅ МАССОВАЯ ОЧИСТКА ВСЕХ СЕРВЕРОВ КЛАСТЕРА ЗАВЕРШЕНА!${X}"
echo -e "$HR\n"
