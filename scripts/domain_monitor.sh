#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  domain_monitor.sh | [v2026-03-14]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Turbo Domain Monitor with 3 retry attempts and Telegram alerts
# Servers     : 222-DE / 109-RU / Any FastPanel node
# Usage       : bash scripts/domain_monitor.sh
# ==========================================================================================

source /root/.server_env

# Collect unique list of hosted domains
DOMAINS=$(grep -roP 'server_name \K[^; ]+' /etc/nginx/fastpanel2-sites/ /etc/nginx/fastpanel2-available/ 2>/dev/null | awk -F: '{print $2}' | tr ' ' '\n' | sed 's/^www\.//' | grep "\." | sort -u)

for DOMAIN in $DOMAINS; do
    SUCCESS=false
    
    # Retry loop (3 attempts)
    for ATTEMPT in {1..3}; do
        STATUS=$(curl -4 -Ls -o /dev/null -w "%{http_code}" --connect-timeout 5 "https://$DOMAIN" 2>/dev/null || echo "000")
        
        if [ "$STATUS" -eq 200 ]; then
            SUCCESS=true
            break # Exit retry loop if status OK
        fi
        
        # If not the last attempt, wait 15 seconds before retry
        if [ $ATTEMPT -lt 3 ]; then
            sleep 15
        fi
    done

    # If domain remains down after 3 attempts, send alert to Telegram
    if [ "$SUCCESS" = false ]; then
        MESSAGE="🚨 CRITICAL: $DOMAIN is DOWN!%0A📊 Status: $STATUS (after 3 attempts)%0A🌐 Server: ${SERVER_TAG:-$(hostname)}"
        curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
             -d "chat_id=${TG_CHAT_ID}" -d "text=$MESSAGE" > /dev/null
    fi
done

# = Rooted by VladiMIR | AI = v2026-03-14 = github.com/GinCz/Linux_Server_Public

