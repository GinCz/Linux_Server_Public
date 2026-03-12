#!/usr/bin/env bash
# Fast Parallel Domain Checker
source /root/scripts/common.sh

# Prevent multiple instances
lock_or_exit domains_check

# Domain list (Define your domains here or point to a file)
DOMAINS=(
    "gincz.com"
    "prodvig-saita.ru"
    "car-bus-autoservice.cz"
)

# Function for a single check (exported for xargs)
check_site() {
    DOMAIN=$1
    # Use curl with 5s timeout, only headers
    STATUS=$(curl -o /dev/null -s -w "%{http_code}" --head --connect-timeout 5 "http://$DOMAIN")
    
    if [[ "$STATUS" == "200" || "$STATUS" == "301" || "$STATUS" == "302" ]]; then
        echo -e "\e[32m[OK]\e[0m $DOMAIN ($STATUS)"
    else
        echo -e "\e[31m[DOWN]\e[0m $DOMAIN ($STATUS)"
        # Use the send_tg function from common.sh (needs to be redefined for subshell or called directly)
        # For simplicity in parallel, we just log and you can add notification logic below
    fi
}

export -f check_site
echo -e "${CYAN}>>> Starting parallel check for ${#DOMAINS[@]} domains...${NC}"

# Run 10 checks in parallel
printf "%s\n" "${DOMAINS[@]}" | xargs -I {} -P 10 bash -c 'check_site "{}"'

echo -e "${GREEN}>>> Check completed.${NC}"
