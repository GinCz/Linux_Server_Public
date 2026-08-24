#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  block_bots.sh | [v2026-08-15]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Universal malicious bot & aggressive attacker shield (Grey & Orange Cloud aware)
# Servers     : All Linux Web Nodes (109-RU direct iptables / 222-DE Cloudflare aware)
# Usage       : bash scripts/block_bots.sh
# ==========================================================================================

LIMIT=800
LOG_GLOB="/var/www/*/data/logs/*access.log"
MY_IP=$(hostname -I 2>/dev/null | awk '{print $1}')

# Detect server architecture
IS_DIRECT_IP_NODE=false
if [[ "$MY_IP" =~ "212.109.223.109" ]] || [[ "$(hostname)" =~ "109" ]] || [[ -f /etc/nginx/conf.d/00-wp-limit-zones.conf ]]; then
    IS_DIRECT_IP_NODE=true
fi

echo "--- Malicious Bot Filter ---"
echo "Mode: $( [ "$IS_DIRECT_IP_NODE" = true ] && echo "Direct Client IP (iptables shield)" || echo "Proxy / Cloudflare aware" )"

BAD_IPS=$(awk '{if($0~/xmlrpc\.php|wp-login\.php/) print $1}' $LOG_GLOB 2>/dev/null | sort | uniq -c | sort -nr | awk -v limit="$LIMIT" '$1>limit{print $2}')

if [ -z "$BAD_IPS" ]; then
    echo "✅ No aggressive attackers exceeding limit ($LIMIT requests)."
    exit 0
fi

for ip in $BAD_IPS; do
    # Skip private / loopback / Cloudflare IP ranges if present
    if [[ "$ip" =~ ^(127\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.) ]]; then
        continue
    fi

    if [ "$IS_DIRECT_IP_NODE" = true ]; then
        iptables -C INPUT -s "$ip" -j DROP >/dev/null 2>&1 || {
            iptables -I INPUT -s "$ip" -j DROP
            echo "🚫 Banned via iptables: $ip"
        }
    else
        # On Cloudflare proxied nodes, ban via CrowdSec or iptables if not a Cloudflare IP
        if command -v cscli >/dev/null 2>&1; then
            cscli decisions add --ip "$ip" --reason "Aggressive XMLRPC/wp-login flood" --duration 24h >/dev/null 2>&1
            echo "🚫 Banned via CrowdSec: $ip"
        else
            iptables -C INPUT -s "$ip" -j DROP >/dev/null 2>&1 || {
                iptables -I INPUT -s "$ip" -j DROP
                echo "🚫 Banned via iptables: $ip"
            }
        fi
    fi
done

echo "Shield execution complete."

# = Rooted by VladiMIR | AI = v2026-08-15 = github.com/GinCz/Linux_Server_Public
