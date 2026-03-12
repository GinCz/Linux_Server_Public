#!/usr/bin/env bash
# High-Speed Dynamic Domain Checker with Telegram Alerts
source /root/scripts/common.sh

lock_or_exit domains_check

# Temporary file for errors
ERROR_LOG="/tmp/domains_down.txt"
> $ERROR_LOG

echo -e "${CYAN}>>> Scanning system for domains...${NC}"
SYSTEM_DOMAINS=$(find /var/www -maxdepth 4 -type d -name "*.*" | xargs -n1 basename | grep -v "_" | grep -E "^[a-zA-Z]" | sort -u)
DOMAINS=($SYSTEM_DOMAINS)

# Function to check site and log errors
check_site() {
    DOMAIN=$1
    ERR_LOG="/tmp/domains_down.txt"
    STATUS=$(curl -o /dev/null -s -w "%{http_code}" --head --connect-timeout 5 "http://$DOMAIN")
    
    if [[ "$STATUS" == "200" || "$STATUS" == "301" || "$STATUS" == "302" ]]; then
        echo -e "\e[32m[OK]\e[0m $DOMAIN ($STATUS)"
    else
        echo -e "\e[31m[DOWN]\e[0m $DOMAIN ($STATUS)"
        echo "❌ $DOMAIN ($STATUS)" >> $ERR_LOG
    fi
}

export -f check_site
echo -e "${CYAN}>>> Checking ${#DOMAINS[@]} domains in parallel...${NC}"

printf "%s\n" "${DOMAINS[@]}" | xargs -I {} -P 10 bash -c 'check_site "{}"'

# Check if there were any errors and send to TG
if [ -s "$ERROR_LOG" ]; then
    DOWN_COUNT=$(wc -l < "$ERROR_LOG")
    ALERT_MSG="⚠️ ALERT! $DOWN_COUNT domains are DOWN:\n$(cat $ERROR_LOG)"
    send_tg "$ALERT_MSG"
    echo -e "${RED}>>> Sent alert to Telegram!${NC}"
fi

rm -f "$ERROR_LOG"
echo -e "${GREEN}>>> Check completed at $(date +'%H:%M:%S')${NC}"
