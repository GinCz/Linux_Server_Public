#!/usr/bin/env bash
# Script:  block_bots.sh
# Version: v2026-03-17
# Purpose: Block WordPress bot IPs (xmlrpc, wp-login, wp-admin) via iptables.
#          Sends Telegram alert on new bans.
#          Works on type 1 (222) and type 2 (109) servers.
# Usage:   /opt/server_tools/scripts/block_bots.sh
# Alias:   fight
# Cron:    0 21 * * * /opt/server_tools/scripts/block_bots.sh

clear
source /root/.server_alliances.conf 2>/dev/null || true

LIMIT=800
LOG_GLOB="/var/www/*/data/logs/*access.log"
BAN_DB="/opt/server_tools/state/fight_bans.txt"
SSH_IP="$(echo "${SSH_CLIENT:-}" | awk '{print $1}')"

TRUSTED_IPS=(
    "127.0.0.1"
    "8.8.8.8"
    "1.1.1.1"
    "152.53.182.222"
    "212.109.223.109"
    "5.101.114.114"
    "109.172.90.168"
    "109.234.38.47"
    "144.124.228.237"
    "144.124.232.9"
    "144.124.228.227"
    "144.124.239.24"
    "91.84.118.178"
    "146.103.110.176"
    "144.124.233.38"
    "${REMOTE_IP:-}"
)

mkdir -p "$(dirname "$BAN_DB")"
touch "$BAN_DB"

trusted() {
    local ip="$1"
    [[ -z "$ip" || "$ip" == "$SSH_IP" ]] && return 0
    for t in "${TRUSTED_IPS[@]}"; do
        [[ "$ip" == "$t" ]] && return 0
    done
    return 1
}

chain() {
    iptables -S FIGHT_BOTS >/dev/null 2>&1 || iptables -N FIGHT_BOTS
    iptables -C INPUT -j FIGHT_BOTS >/dev/null 2>&1 || iptables -I INPUT 1 -j FIGHT_BOTS
}

has() {
    iptables -C FIGHT_BOTS -s "$1" -j DROP >/dev/null 2>&1
}

ban() {
    iptables -I FIGHT_BOTS -s "$1" -j DROP
    echo "$(date -u '+%F %T') $1" >> "$BAN_DB"
}

collect() {
    awk '{ip=$1;l=$0
        if(l~/ (GET|POST) (\/\/)?\/?(xmlrpc|wp-login)\.php/ || \
           l~/ (GET|POST) (\/\/)?\/wp-admin\//)
            c[ip]++
    } END{for(i in c) print c[i],i}' $LOG_GLOB 2>/dev/null | sort -nr
}

main() {
    chain
    local out bad n=0 list=""
    out="$(collect || true)"
    bad="$(echo "$out" | awk -v limit="$LIMIT" '$1>limit{print $2}')"

    for ip in $bad; do
        trusted "$ip" && continue
        has "$ip" && continue
        ban "$ip"
        n=$((n+1))
        list="${list} ${ip}"
    done

    if [ "$n" -gt 0 ] && [ -n "${TG_TOKEN:-}" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
            -d "chat_id=${TG_CHAT_ID}" \
            -d "text=🛡️ FIGHT ($SERVER_TAG): blocked ${n} IP(s):${list}" \
            -d "disable_notification=true" >/dev/null 2>&1 || true
    fi

    echo "FIGHT done. New bans: $n"
    [ "$n" -gt 0 ] && echo "Banned:$list"
}

main
