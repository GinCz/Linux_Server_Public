#!/usr/bin/env bash
# Domains Checker for Ing. VladiMIR Bulantsev | 2026
# Filters out www. aliases to keep report clean

clear
C='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; X='\033[0m'
SERVER_NAME=$(hostname)

echo -e "${Y}📊 SERVER: ${SERVER_NAME}${X}"
echo "---------------------------"

# Находим все уникальные домены в конфигах Nginx, исключая те, что начинаются на www.
DOMAINS=$(grep -r "server_name" /etc/nginx/sites-enabled/ | awk '{print $3}' | sed 's/;//' | grep "\." | grep -v "^www\." | sort -u)

for domain in $DOMAINS; do
    # Проверка статус-кода (таймаут 5 сек)
    STATUS=$(curl -o /dev/null -s -w "%{http_code}" --max-time 5 "http://$domain")
    
    if [ "$STATUS" == "200" ] || [ "$STATUS" == "301" ] || [ "$STATUS" == "302" ]; then
        echo -e "✅ ${domain} | ${C}${STATUS}${X}"
    else
        echo -e "❌ ${domain} | ${R}${STATUS}${X}"
    fi
done
