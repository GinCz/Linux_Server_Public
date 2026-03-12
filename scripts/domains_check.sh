#!/usr/bin/env bash
# High-Speed Dynamic Domain Checker (Clean & Fast)
source /root/scripts/common.sh

# Prevent multiple instances
lock_or_exit domains_check

echo -e "${CYAN}>>> Scanning system for real domains...${NC}"

# 1. Find directories with dots, but EXCLUDE backups (containing underscores or starting with numbers)
SYSTEM_DOMAINS=$(find /var/www -maxdepth 4 -type d -name "*.*" | xargs -n1 basename | grep -v "_" | grep -E "^[a-zA-Z]" | sort -u)

# 2. Hardcoded fallback list
BACKUP_DOMAINS=("gincz.com" "prodvig-saita.ru" "car-bus-autoservice.cz")

if [ -n "$SYSTEM_DOMAINS" ]; then
    DOMAINS=($SYSTEM_DOMAINS)
    echo -e "${GREEN}Found ${#DOMAINS[@]} clean domains (filtered out backups)${NC}"
else
    DOMAINS=("${BACKUP_DOMAINS[@]}")
    echo -e "${YELLOW}No clean domains found, using backup list${NC}"
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
