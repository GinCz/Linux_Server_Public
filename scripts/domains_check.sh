#!/usr/bin/env bash
# High-Speed Domain & SSL Checker
source /root/scripts/common.sh

lock_or_exit domains_check

ERROR_LOG="/tmp/domains_down.txt"
> $ERROR_LOG

echo -e "${CYAN}>>> Scanning for domains...${NC}"
SYSTEM_DOMAINS=$(find /var/www -maxdepth 4 -type d -name "*.*" | xargs -n1 basename | grep -v "_" | grep -E "^[a-zA-Z]" | sort -u)
DOMAINS=($SYSTEM_DOMAINS)

check_site() {
    DOMAIN=$1
    ERR_LOG="/tmp/domains_down.txt"
    
    # 1. Check HTTP Status
    STATUS=$(curl -o /dev/null -s -w "%{http_code}" --head --connect-timeout 5 "http://$DOMAIN")
    
    # 2. Check SSL Expiry (if port 443 is open)
    SSL_INFO="SSL OK"
    # Get expiration date in seconds
    EXPIRY_DATE=$(timeout 3s openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
    
    if [ -n "$EXPIRY_DATE" ]; then
        EXPIRY_SEC=$(date -d "$EXPIRY_DATE" +%s)
        NOW_SEC=$(date +%s)
        DIFF_DAYS=$(( (EXPIRY_SEC - NOW_SEC) / 86400 ))
        
        if [ "$DIFF_DAYS" -lt 0 ]; then
            SSL_INFO="SSL EXPIRED"
        elif [ "$DIFF_DAYS" -lt 14 ]; then
            SSL_INFO="SSL EXPIRING IN $DIFF_DAYS DAYS"
        fi
    else
        SSL_INFO="SSL CHECK FAILED"
    fi

    # Logging results
    if [[ "$STATUS" == "200" || "$STATUS" == "301" || "$STATUS" == "302" ]] && [[ "$SSL_INFO" == "SSL OK" ]]; then
        echo -e "\e[32m[OK]\e[0m $DOMAIN ($STATUS | $SSL_INFO)"
    else
        echo -e "\e[31m[FAIL]\e[0m $DOMAIN ($STATUS | $SSL_INFO)"
        echo "❌ $DOMAIN (HTTP: $STATUS | $SSL_INFO)" >> $ERR_LOG
    fi
}

export -f check_site
echo -e "${CYAN}>>> Checking ${#DOMAINS[@]} domains for HTTP and SSL...${NC}"

printf "%s\n" "${DOMAINS[@]}" | xargs -I {} -P 10 bash -c 'check_site "{}"'

if [ -s "$ERROR_LOG" ]; then
    DOWN_COUNT=$(wc -l < "$ERROR_LOG")
    ALERT_MSG="⚠️ DOMAIN ALERT! ($DOWN_COUNT Issues found):
$(cat $ERROR_LOG)"
    send_tg "$ALERT_MSG"
    echo -e "${RED}>>> Summary sent to Telegram.${NC}"
fi

rm -f "$ERROR_LOG"
echo -e "${GREEN}>>> Check completed at $(date +'%H:%M:%S')${NC}"
