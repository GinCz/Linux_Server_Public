#!/bin/bash
# =============================================================
# Script: set_php_fpm_limits_v2026-04-07.sh
# Version: v2026-04-07
# Server: 109-RU-FastVDS (212.109.223.109) | FastVDS.ru
#         Ubuntu 24 LTS / FASTPANEL (no Cloudflare)
#         4 vCore AMD EPYC 7763 / 8GB RAM / 80GB NVMe
#
# Description:
#   Universal PHP-FPM resource limiter for ALL domains on this server.
#   Sets per-pool limits in two layers:
#     1. PHP-FPM pool config  — pm.max_children, pm.max_requests
#     2. systemd cgroup (v2)  — CPUQuota, MemoryMax, MemoryHigh,
#                               OOMScoreAdjust
#
#   The script auto-detects total RAM and CPU count, then
#   calculates safe per-process limits so no single site can
#   starve the whole server.
#
# Usage:
#   bash set_php_fpm_limits_v2026-04-07.sh
#
# WARNING: Restarts php8.x-fpm and reloads systemd daemon.
#          Run during low-traffic hours if possible.
#
# = Rooted by VladiMIR | AI =
# =============================================================

clear

# ── Colour helpers ──────────────────────────────────────────
RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'
CYN='\033[0;36m'; NC='\033[0m'

echo -e "${CYN}========================================================${NC}"
echo -e "${CYN} PHP-FPM Universal Limits — 109-RU-FastVDS             ${NC}"
echo -e "${CYN} v2026-04-07  |  = Rooted by VladiMIR | AI =          ${NC}"
echo -e "${CYN}========================================================${NC}"
echo ""

# ── Safety check: must run as root ──────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}ERROR: This script must be run as root.${NC}"
  exit 1
fi

# ── Auto-detect server resources ────────────────────────────
# Total RAM in MB
TOTAL_RAM_MB=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo)
# Number of logical CPU cores
CPU_CORES=$(nproc)

echo -e "${YEL}Detected: ${TOTAL_RAM_MB} MB RAM | ${CPU_CORES} CPU cores${NC}"
echo ""

# ── Resource limits (tuned for 8 GB / 4 cores) ─────────────
# Each PHP-FPM worker uses ~80-120 MB in WordPress environments.
# Max children = floor(RAM * 0.75 / 120), hard cap at 8.
CALC_CHILDREN=$(( TOTAL_RAM_MB * 75 / 100 / 120 ))
MAX_CHILDREN=$(( CALC_CHILDREN < 8 ? CALC_CHILDREN : 8 ))
[[ $MAX_CHILDREN -lt 2 ]] && MAX_CHILDREN=2

# Max requests per child before recycling (prevents memory leaks)
MAX_REQUESTS=500

# systemd CPUQuota: 80% of all cores (e.g. 4 cores → 320%)
CPU_QUOTA=$(( CPU_CORES * 80 ))

# systemd MemoryMax: 85% of total RAM (hard OOM kill threshold)
MEMORY_MAX_MB=$(( TOTAL_RAM_MB * 85 / 100 ))

# systemd MemoryHigh: 75% of total RAM (soft throttle threshold)
MEMORY_HIGH_MB=$(( TOTAL_RAM_MB * 75 / 100 ))

# OOM score: 300 = PHP-FPM is killed before Nginx/MySQL under pressure
OOM_SCORE=300

echo -e "${GRN}Calculated limits:${NC}"
echo "  pm.max_children : ${MAX_CHILDREN}"
echo "  pm.max_requests : ${MAX_REQUESTS}"
echo "  CPUQuota        : ${CPU_QUOTA}%"
echo "  MemoryMax       : ${MEMORY_MAX_MB}M"
echo "  MemoryHigh      : ${MEMORY_HIGH_MB}M"
echo "  OOMScoreAdjust  : ${OOM_SCORE}"
echo ""

# ── Find all PHP-FPM pool config directories ────────────────
POOL_DIRS=(
  /etc/php/*/fpm/pool.d
  /etc/php-fpm.d
)

POOLS_UPDATED=0

for POOL_DIR in "${POOL_DIRS[@]}"; do
  [[ -d "$POOL_DIR" ]] || continue

  for CONF in "$POOL_DIR"/*.conf; do
    [[ -f "$CONF" ]] || continue
    [[ "$(basename $CONF)" == "www.conf" ]] && continue  # skip default pool

    POOL_NAME=$(basename "$CONF" .conf)
    echo -e "  ${CYN}Updating pool:${NC} ${POOL_NAME} (${CONF})"

    # Backup original if no backup exists yet
    [[ ! -f "${CONF}.bak" ]] && cp "$CONF" "${CONF}.bak"

    # Apply pm.max_children
    if grep -q '^pm.max_children' "$CONF"; then
      sed -i "s/^pm.max_children.*/pm.max_children = ${MAX_CHILDREN}/" "$CONF"
    else
      echo "pm.max_children = ${MAX_CHILDREN}" >> "$CONF"
    fi

    # Apply pm.max_requests
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

# ── Apply systemd cgroup limits to php-fpm service ──────────
# Detect which PHP version's FPM is active
FPM_SERVICE=$(systemctl list-units 'php*fpm*' --no-pager --plain 2>/dev/null \
  | awk '/running/{print $1}' | head -1)

if [[ -z "$FPM_SERVICE" ]]; then
  echo -e "${YEL}WARNING: No running php-fpm service found via systemd.${NC}"
  echo -e "${YEL}         Skipping systemd cgroup limits.${NC}"
else
  echo -e "${CYN}Applying systemd limits to: ${FPM_SERVICE}${NC}"

  # Create override directory
  OVERRIDE_DIR="/etc/systemd/system/${FPM_SERVICE}.d"
  mkdir -p "$OVERRIDE_DIR"

  # Write the override file
  cat > "${OVERRIDE_DIR}/limits-vladimir.conf" << EOF
# =============================================================
# systemd cgroup resource limits for ${FPM_SERVICE}
# Generated by set_php_fpm_limits_v2026-04-07.sh
# Server: 109-RU-FastVDS (212.109.223.109)
# = Rooted by VladiMIR | AI =
# =============================================================
[Service]
# Hard CPU cap: ${CPU_QUOTA}% (${CPU_CORES} cores × 80%)
CPUQuota=${CPU_QUOTA}%

# Soft RAM limit — kernel starts throttling at this point
MemoryHigh=${MEMORY_HIGH_MB}M

# Hard RAM limit — processes are OOM-killed above this
MemoryMax=${MEMORY_MAX_MB}M

# OOM priority: PHP-FPM (300) is killed before Nginx/MySQL
OOMScoreAdjust=${OOM_SCORE}
EOF

  echo -e "${GRN}Override written: ${OVERRIDE_DIR}/limits-vladimir.conf${NC}"

  # Reload systemd and restart php-fpm
  systemctl daemon-reload
  systemctl restart "$FPM_SERVICE"

  echo -e "${GRN}${FPM_SERVICE} restarted successfully.${NC}"
fi

echo ""
echo -e "${CYN}========================================================${NC}"
echo -e "${GRN} Done! Verify with:${NC}"
echo -e "   systemctl status ${FPM_SERVICE:-php8.x-fpm}"
echo -e "   systemctl show ${FPM_SERVICE:-php8.x-fpm} | grep -E 'CPU|Memory|OOM'"
echo -e "${CYN}========================================================${NC}"
echo ""
