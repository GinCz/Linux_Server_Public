#!/usr/bin/env bash
# High-Speed Dynamic Domain Checker
source /root/scripts/common.sh

# Prevent multiple instances
lock_or_exit domains_check

echo -e "${CYAN}>>> Scanning system for domains...${NC}"

# 1. Try to find domains in /var/www (FastPanel standard)
# We look for directories with a dot in the name, 3-4 levels deep
SYSTEM_DOMAINS=$(find /var/www -maxdepth 4 -type d -name "*.*" | xargs -n1 basename | sort -u | grep "\.")

# 2. Hardcoded fallback list (if no domains found in /var/www)
BACKUP_DOMAINS=("gincz.com" "prodvig-saita.ru" "car-bus-autoservice.cz")

# Combine and use unique list
if [ -n "$SYSTEM_DOMAINS" ]; then
    DOMAINS=($SYSTEM_DOMAINS)
    echo -e "${GREEN}Found ${#DOMAINS[@]} domains in /var/www${NC}"
else
    DOMAINS=("${BACKUP_DOMAINS[@]}")
    echo -e "${YELLOW}No domains found in /var/www, using backup list (${#DOMAINS[@]})${NC}"
fi

# Function for a single check
check_site() {
    DOMAIN=$1
    # Check via curl (header only, 5s timeout)
    STATUS=$(curl -o /dev/null -s -w "%{http_code}" --head --connect-timeout 5 "http://$DOMAIN")
    
    if [[ "$STATUS" == "200" || "$STATUS" == "301" || "$STATUS" == "302" ]]; then
        echo -e "\e[32m[OK]\e[0m $DOMAIN ($STATUS)"
    elif [[ "$STATUS" == "000" ]]; then
        echo -e "\e[31m[DOWN]\e[0m $DOMAIN (No Response)"
    else
        echo -e "\e[33m[WARN]\e[0m $DOMAIN ($STATUS)"
    fi
}

export -f check_site
echo -e "${CYAN}>>> Starting parallel check (10 threads)...${NC}"

# Run checks in parallel
printf "%s\n" "${DOMAINS[@]}" | xargs -I {} -P 10 bash -c 'check_site "{}"'

echo -e "${GREEN}>>> Check completed at $(date +'%H:%M:%S')${NC}"
