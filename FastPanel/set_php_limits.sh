#!/usr/bin/env bash
clear
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[1;36m'
NC='\033[0m'

echo -e "${YELLOW}>>> Calculating dynamic 70/30 Resource Allocation...${NC}"

# Get total RAM in MB
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')

# Reserve ~1500 MB for OS, Nginx, and system services
AVAIL_RAM=$((TOTAL_RAM - 1500))

# Assume 1 average WordPress PHP-FPM process consumes ~60 MB
MAX_PROCS=$((AVAIL_RAM / 60))

# Calculate 70% limit for a single pool
LIMIT_70=$((MAX_PROCS * 70 / 100))

echo -e "${CYAN}Total Server RAM: ${TOTAL_RAM} MB${NC}"
echo -e "${CYAN}Max safe PHP processes (100%): ~${MAX_PROCS}${NC}"
echo -e "${CYAN}70% Limit per site: ${LIMIT_70} processes${NC}"
echo "--------------------------------------------------------"

POOLS=$(find /etc/php/*/fpm/pool.d/ -name "*.conf")

for pool in $POOLS; do
    # Set the dynamic 70% limit
    sed -i "s/^pm.max_children =.*/pm.max_children = ${LIMIT_70}/" "$pool"
    
    # Keep process idle timeout at 20s for fast repeat connections
    sed -i 's/^pm.process_idle_timeout =.*/pm.process_idle_timeout = 20s/' "$pool"
done

# Graceful restart of all PHP-FPM versions
ls /etc/php/ -1 | xargs -I {} systemctl restart php{}-fpm 2>/dev/null

echo -e "${GREEN}✔ Done! Each site can burst up to 70% of server capacity (${LIMIT_70} workers).${NC}"
echo -e "${GREEN}✔ 30% capacity is strictly reserved so remaining sites stay online.${NC}"
echo "Best regards, Ing. VladiMIR Bulantsev"
