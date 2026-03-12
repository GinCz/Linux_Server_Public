#!/usr/bin/env bash
# English comments: Synchronize local firewall with Global Whitelist
WHITELIST="/root/scripts/security/whitelist.txt"

if [ -f "$WHITELIST" ]; then
    # Извлекаем все строки, которые похожи на IP или подсети (пропуская комментарии)
    IPS=$(grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]+)?' "$WHITELIST")
    
    for IP in $IPS; do
        # Вставляем в самое начало (позиция 1), если правила еще нет
        iptables -C INPUT -s "$IP" -j ACCEPT >/dev/null 2>&1 || iptables -I INPUT 1 -s "$IP" -j ACCEPT
    done
    echo "✅ Whitelist applied to iptables"
fi
