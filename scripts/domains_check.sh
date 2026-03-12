#!/usr/bin/env bash
# Production Domain & SSL Checker
source /root/scripts/common.sh

lock_or_exit domains_check

ERROR_LOG="/tmp/domains_down.txt"
> $ERROR_LOG

echo -e "${CYAN}>>> Scanning for domains...${NC}"
# Discovery: find real domains, skip backups and numeric folders
DOMAINS=($(find /var/www -maxdepth 4 -type d -name "*.*" | xargs -n1 basename | grep -v "_" | grep -E "^[a-zA-Z]" | sort -u))

echo -e "${GREEN}Found ${#DOMAINS[@]} domains.${NC}"

check_site() {
    DOMAIN=$1
    ERR_LOG="/tmp/domains_down.txt"
    
    # 1. Check HTTP Status
    STATUS=$(curl -o /dev/null -s -w "%{http_code}" --head --connect-timeout 5 "http://$DOMAIN")
    
    # 2. Check SSL Expiry (Silent Mode)
    SSL_INFO="SSL OK"
    IS_CRITICAL=false
    EXPIRY_DATE=$(echo | timeout 5s openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
    
    if [ -n "$EXPIRY_DATE" ]; then
        EXPIRY_SEC=$(date -d "$EXPIRY_DATE" +%s 2>/dev/null)
        if [ -n "$EXPIRY_SEC" ]; then
            DIFF_DAYS=$(( (EXPIRY_SEC - $(date +%s)) / 86400 ))
            if [ "$DIFF_DAYS" -lt 0 ]; then
                SSL_INFO="SSL EXPIRED"
                IS_CRITICAL=true
            elif [ "$DIFF_DAYS" -lt 14 ]; then
                SSL_INFO="SSL EXPIRING IN $DIFF_DAYS DAYS"
                IS_CRITICAL=true
            fi
        fi
    else
        # If site works but SSL port is dead
        if [[ "$STATUS" != "000" ]]; then
            SSL_INFO="NO SSL"
        else
            SSL_INFO="SSL CHECK FAILED"
            IS_CRITICAL=true
        fi
    fi

    # 3. Decision & Logging
    if [[ "$STATUS" == "000" ]] || [ "$IS_CRITICAL" = true ]; then
        echo -e "\e[31m[FAIL]\e[0m $DOMAIN ($STATUS | $SSL_INFO)"
        echo "❌ $DOMAIN (HTTP: $STATUS | $SSL_INFO)" >> $ERR_LOG
    elif [[ "$SSL_INFO" == "NO SSL" ]]; then
        echo -e "\e[33m[WARN]\e[0m $DOMAIN ($STATUS | $SSL_INFO)"
    else
        echo -e "\e[32m[OK]\e[0m $DOMAIN ($STATUS | $SSL_INFO)"
    fi
}

export -f check_site
echo -e "${CYAN}>>> Parallel check started...${NC}"

printf "%s\n" "${DOMAINS[@]}" | xargs -I {} -P 10 bash -c 'check_site "{}"'

# --- THE TELEGRAM BLOCK YOU ASKED FOR ---
if [ -s "$ERROR_LOG" ]; then
    DOWN_COUNT=$(wc -l < "$ERROR_LOG")
    ALERT_MSG="⚠️ DOMAIN ALERT! ($DOWN_COUNT Issues found):
$(cat $ERROR_LOG)"
    send_tg "$ALERT_MSG"
    echo -e "${RED}>>> Alert sent to Telegram.${NC}"
fi

rm -f "$ERROR_LOG"
echo -e "${GREEN}>>> Done at $(date +'%H:%M:%S')${NC}"
