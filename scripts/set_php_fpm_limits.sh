#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  set_php_fpm_limits.sh | [v2026-08-15]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Universal dynamic PHP-FPM pool & systemd cgroup memory allocator
# Servers     : All FastPanel Web Nodes (222-DE / 109-RU)
# Usage       : bash scripts/set_php_fpm_limits.sh
# ==========================================================================================
clear

RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; CYN='\033[0;36m'; NC='\033[0m'

echo -e "${CYN}========================================================${NC}"
echo -e "${CYN} PHP-FPM Universal Limits Allocator                     ${NC}"
echo -e "${CYN} $(hostname) | = Rooted by VladiMIR | AI =              ${NC}"
echo -e "${CYN}========================================================${NC}"
echo ""

if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}ERROR: This script must be run as root.${NC}"
  exit 1
fi

TOTAL_RAM_MB=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo)
CPU_CORES=$(nproc)

echo -e "${YEL}Detected Resources: ${TOTAL_RAM_MB} MB RAM | ${CPU_CORES} CPU cores${NC}"
echo ""

# Dynamic memory sizing (75% for PHP pools, 25% for System/MySQL)
CALC_CHILDREN=$(( TOTAL_RAM_MB * 75 / 100 / 120 ))
MAX_CHILDREN=$(( CALC_CHILDREN < 8 ? CALC_CHILDREN : 8 ))
[[ $MAX_CHILDREN -lt 2 ]] && MAX_CHILDREN=2

MAX_REQUESTS=500
CPU_QUOTA=$(( CPU_CORES * 80 ))
MEMORY_MAX_MB=$(( TOTAL_RAM_MB * 85 / 100 ))
MEMORY_HIGH_MB=$(( TOTAL_RAM_MB * 75 / 100 ))
OOM_SCORE=300

echo -e "${GRN}Calculated Parameters:${NC}"
echo "  pm.max_children : ${MAX_CHILDREN}"
echo "  pm.max_requests : ${MAX_REQUESTS}"
echo "  CPUQuota        : ${CPU_QUOTA}%"
echo "  MemoryMax       : ${MEMORY_MAX_MB}M"
echo "  MemoryHigh      : ${MEMORY_HIGH_MB}M"
echo "  OOMScoreAdjust  : ${OOM_SCORE}"
echo ""

POOL_DIRS=(
  /etc/php/*/fpm/pool.d
  /etc/php-fpm.d
)

POOLS_UPDATED=0

for POOL_DIR in "${POOL_DIRS[@]}"; do
  [[ -d "$POOL_DIR" ]] || continue

  for CONF in "$POOL_DIR"/*.conf; do
    [[ -f "$CONF" ]] || continue
    [[ "$(basename $CONF)" == "www.conf" ]] && continue

    POOL_NAME=$(basename "$CONF" .conf)
    echo -e "  ${CYN}Updating pool:${NC} ${POOL_NAME} (${CONF})"

    [[ ! -f "${CONF}.bak" ]] && cp "$CONF" "${CONF}.bak"

    if grep -q '^pm.max_children' "$CONF"; then
      sed -i "s/^pm.max_children.*/pm.max_children = ${MAX_CHILDREN}/" "$CONF"
    else
      echo "pm.max_children = ${MAX_CHILDREN}" >> "$CONF"
    fi

    if grep -q '^pm.max_requests' "$CONF"; then
      sed -i "s/^pm.max_requests.*/pm.max_requests = ${MAX_REQUESTS}/" "$CONF"
    else
      echo "pm.max_requests = ${MAX_REQUESTS}" >> "$CONF"
    fi

    (( POOLS_UPDATED++ ))
  done
done

echo ""
echo -e "${GRN}PHP-FPM pool configs updated: ${POOLS_UPDATED} pool(s)${NC}"
echo ""

# Restart all installed PHP-FPM versions
ls /etc/php/ -1 2>/dev/null | xargs -I {} systemctl restart php{}-fpm 2>/dev/null
nginx -t 2>/dev/null && systemctl reload nginx 2>/dev/null

echo -e "${GRN}✅ ALL PHP-FPM services restarted and reloaded successfully.${NC}"

# = Rooted by VladiMIR | AI = v2026-08-15 = github.com/GinCz/Linux_Server_Public
