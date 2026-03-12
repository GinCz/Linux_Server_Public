#!/usr/bin/env bash
# Downloads and applies global bans via iptables
BAN_URL="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/security/global_ban_list.txt"
BAD_IPS=$(curl -s $BAN_URL)

for ip in $BAD_IPS; do
    # Если IP не в белом списке и не забанен — баним
    iptables -C INPUT -s "$ip" -j DROP >/dev/null 2>&1 || {
        iptables -I INPUT -s "$ip" -j DROP
        # Уведомляем ТОЛЬКО о факте нового бана, если нужно (но лучше молчать)
    }
done
