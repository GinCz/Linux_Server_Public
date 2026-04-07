#!/bin/bash
# = Rooted by VladiMIR | AI =
# set_php_fpm_limits_v2026-04-07.sh
# Universal PHP-FPM CPU + RAM limits for ALL pools on current server
# Servers: 222-DE-NetCup (4 vCore / 8GB) | 109-RU-FastVDS (4 vCore / 8GB)
# Version: v2026-04-07

clear

# ─── CONFIG ────────────────────────────────────────────────────────────────────
VERSION="v2026-04-07"
SCRIPT_NAME="set_php_fpm_limits"
LOG_FILE="/var/log/${SCRIPT_NAME}.log"

# RAM reserves (MB) — OS + Nginx + MySQL + CrowdSec
RAM_RESERVE_MB=1500
# MB per PHP-FPM process (average WP site)
RAM_PER_PROCESS_MB=60
# Max % of available processes per pool (70% rule)
POOL_MAX_PERCENT=70
# CPU limit per pool in % (from total vCores*100)
# 4 vCores = 400% total. Limit each pool to max 80% (1 full core + buffer)
CPU_MAX_PERCENT=80
# Minimum pm.max_children per pool (safety floor)
MIN_CHILDREN=2
# Maximum pm.max_children per pool (hard cap — prevents any site from going wild)
MAX_CHILDREN=8

# PHP-FPM pool config dirs (FastPanel structure)
PHP_POOL_DIRS=(
    "/etc/php/8.3/fpm/pool.d"
    "/etc/php/8.2/fpm/pool.d"
    "/etc/php/8.1/fpm/pool.d"
    "/etc/php/8.0/fpm/pool.d"
    "/etc/php/7.4/fpm/pool.d"
)

# ─── COLORS ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

# ─── LOGGING ───────────────────────────────────────────────────────────────────
log()     { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }
info()    { echo -e "${CYAN}[INFO]${NC}  $1"; log "INFO: $1"; }
ok()      { echo -e "${GREEN}[OK]${NC}    $1"; log "OK: $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; log "WARN: $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; log "ERROR: $1"; }
section() {
    echo -e "\n${BOLD}${BLUE}══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  $1${NC}"
    echo -e "${BOLD}${BLUE}══════════════════════════════════════════${NC}"
}

# ─── HEADER ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}${BLUE}"
echo "  ┌─────────────────────────────────────────────────┐"
echo "  │   PHP-FPM CPU + RAM Limits Manager ${VERSION}   │"
echo "  │   = Rooted by VladiMIR | AI =                   │"
echo "  └─────────────────────────────────────────────────┘"
echo -e "${NC}"

# ─── ROOT CHECK ────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    error "Run as root: sudo $0"
    exit 1
fi

# ─── DETECT SERVER ─────────────────────────────────────────────────────────────
section "Detecting server environment"
HOSTNAME=$(hostname)
TOTAL_RAM_MB=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo)
CPU_CORES=$(nproc)
TOTAL_CPU_PERCENT=$((CPU_CORES * 100))
AVAILABLE_RAM_MB=$((TOTAL_RAM_MB - RAM_RESERVE_MB))
MAX_TOTAL_PROCESSES=$((AVAILABLE_RAM_MB / RAM_PER_PROCESS_MB))
POOL_MAX_CHILDREN=$(( (MAX_TOTAL_PROCESSES * POOL_MAX_PERCENT / 100) ))
[[ $POOL_MAX_CHILDREN -lt $MIN_CHILDREN ]] && POOL_MAX_CHILDREN=$MIN_CHILDREN
[[ $POOL_MAX_CHILDREN -gt $MAX_CHILDREN ]] && POOL_MAX_CHILDREN=$MAX_CHILDREN

info "Hostname:          $HOSTNAME"
info "Total RAM:         ${TOTAL_RAM_MB} MB"
info "Reserved RAM:      ${RAM_RESERVE_MB} MB (OS + services)"
info "Available RAM:     ${AVAILABLE_RAM_MB} MB"
info "CPU cores:         ${CPU_CORES} (total ${TOTAL_CPU_PERCENT}%)"
info "CPU per pool:      max ${CPU_MAX_PERCENT}%"
info "Max total PHP:     ${MAX_TOTAL_PROCESSES} processes"
info "pm.max_children:   ${POOL_MAX_CHILDREN} per pool (${POOL_MAX_PERCENT}% rule)"

# ─── INSTALL cpulimit IF NEEDED ────────────────────────────────────────────────
section "Checking cpulimit"
if ! command -v cpulimit &>/dev/null; then
    info "Installing cpulimit..."
    apt-get install -y cpulimit >> "$LOG_FILE" 2>&1 \
        && ok "cpulimit installed" \
        || warn "cpulimit install failed — using systemd cgroups only"
else
    ok "cpulimit already installed"
fi

# ─── APPLY PM LIMITS TO ALL POOLS ──────────────────────────────────────────────
section "Applying PHP-FPM pool limits"
POOLS_FOUND=0
POOLS_UPDATED=0

for POOL_DIR in "${PHP_POOL_DIRS[@]}"; do
    [[ ! -d "$POOL_DIR" ]] && continue
    info "Scanning: $POOL_DIR"

    for CONF_FILE in "$POOL_DIR"/*.conf; do
        [[ ! -f "$CONF_FILE" ]] && continue

        # Skip www.conf (default unused pool)
        POOL_NAME=$(grep -m1 '^\[' "$CONF_FILE" | tr -d '[]')
        [[ "$POOL_NAME" == "www" ]] && continue
        POOLS_FOUND=$((POOLS_FOUND + 1))

        # Backup original (keep only one per version)
        cp "$CONF_FILE" "${CONF_FILE}.bak.${VERSION}" 2>/dev/null

        # Set pm = dynamic
        sed -i 's/^pm\s*=.*/pm = dynamic/' "$CONF_FILE"

        # pm.max_children — hard cap per pool
        if grep -q "^pm.max_children" "$CONF_FILE"; then
            sed -i "s/^pm.max_children\s*=.*/pm.max_children = ${POOL_MAX_CHILDREN}/" "$CONF_FILE"
        else
            echo "pm.max_children = ${POOL_MAX_CHILDREN}" >> "$CONF_FILE"
        fi

        # pm.start_servers = 25% of max (min 1)
        START=$(( POOL_MAX_CHILDREN / 4 ))
        [[ $START -lt 1 ]] && START=1
        if grep -q "^pm.start_servers" "$CONF_FILE"; then
            sed -i "s/^pm.start_servers\s*=.*/pm.start_servers = ${START}/" "$CONF_FILE"
        else
            echo "pm.start_servers = ${START}" >> "$CONF_FILE"
        fi

        # pm.min_spare_servers = 20% of max (min 1)
        MIN_SPARE=$(( POOL_MAX_CHILDREN / 5 ))
        [[ $MIN_SPARE -lt 1 ]] && MIN_SPARE=1
        if grep -q "^pm.min_spare_servers" "$CONF_FILE"; then
            sed -i "s/^pm.min_spare_servers\s*=.*/pm.min_spare_servers = ${MIN_SPARE}/" "$CONF_FILE"
        else
            echo "pm.min_spare_servers = ${MIN_SPARE}" >> "$CONF_FILE"
        fi

        # pm.max_spare_servers = 50% of max (min 1)
        MAX_SPARE=$(( POOL_MAX_CHILDREN / 2 ))
        [[ $MAX_SPARE -lt 1 ]] && MAX_SPARE=1
        if grep -q "^pm.max_spare_servers" "$CONF_FILE"; then
            sed -i "s/^pm.max_spare_servers\s*=.*/pm.max_spare_servers = ${MAX_SPARE}/" "$CONF_FILE"
        else
            echo "pm.max_spare_servers = ${MAX_SPARE}" >> "$CONF_FILE"
        fi

        # pm.max_requests = 500 (auto-restart workers, prevent memory leaks)
        if grep -q "^pm.max_requests" "$CONF_FILE"; then
            sed -i "s/^pm.max_requests\s*=.*/pm.max_requests = 500/" "$CONF_FILE"
        else
            echo "pm.max_requests = 500" >> "$CONF_FILE"
        fi

        POOLS_UPDATED=$((POOLS_UPDATED + 1))
        ok "Pool [$POOL_NAME]: max_children=${POOL_MAX_CHILDREN} start=${START} min_spare=${MIN_SPARE} max_spare=${MAX_SPARE} max_req=500"
    done
done

info "Pools found: ${POOLS_FOUND} | Updated: ${POOLS_UPDATED}"

# ─── SYSTEMD CPU CGROUP LIMITS ─────────────────────────────────────────────────
section "Applying CPU limits via systemd cgroups"

# Find running php-fpm service
PHP_SERVICE=$(systemctl list-units --type=service --state=running \
    | grep -o 'php[0-9.]*-fpm.service' | head -1)

GLOBAL_CPU_QUOTA=0

if [[ -z "$PHP_SERVICE" ]]; then
    warn "No running php-fpm service found — skipping systemd CPU limits"
else
    info "PHP-FPM service: $PHP_SERVICE"
    OVERRIDE_DIR="/etc/systemd/system/${PHP_SERVICE}.d"
    mkdir -p "$OVERRIDE_DIR"

    # Global quota: allow up to (cores * CPU_MAX_PERCENT)% total PHP CPU usage
    # Example: 4 cores × 80% = 320% — one core always free for OS/Nginx
    GLOBAL_CPU_QUOTA=$(( CPU_CORES * CPU_MAX_PERCENT ))

    cat > "${OVERRIDE_DIR}/cpu-memory-limit.conf" <<EOF
# = Rooted by VladiMIR | AI =
# systemd resource limits for PHP-FPM service — ${VERSION}
# Server: $(hostname) | Cores: ${CPU_CORES} | RAM: ${TOTAL_RAM_MB}MB
[Service]
# CPU: allow max ${GLOBAL_CPU_QUOTA}% (${CPU_CORES} cores × ${CPU_MAX_PERCENT}%)
# This leaves at least 1 full core free for Nginx + MySQL + OS
CPUQuota=${GLOBAL_CPU_QUOTA}%
# RAM: hard limit — kernel kills PHP workers if exceeded (not Nginx/MySQL)
MemoryMax=${AVAILABLE_RAM_MB}M
# RAM: soft limit — start throttling at 85% of max
MemoryHigh=$(( AVAILABLE_RAM_MB * 85 / 100 ))M
# OOM priority: PHP workers die first, not other services
OOMScoreAdjust=300
EOF

    systemctl daemon-reload >> "$LOG_FILE" 2>&1
    ok "Override: ${OVERRIDE_DIR}/cpu-memory-limit.conf"
    info "CPUQuota=${GLOBAL_CPU_QUOTA}% | MemoryMax=${AVAILABLE_RAM_MB}M | MemoryHigh=$(( AVAILABLE_RAM_MB * 85 / 100 ))M"
fi

# ─── RELOAD PHP-FPM ────────────────────────────────────────────────────────────
section "Reloading PHP-FPM"
if [[ -n "$PHP_SERVICE" ]]; then
    # Test config validity before reload
    PHP_VERSION=$(echo "$PHP_SERVICE" | grep -o '[0-9.]*')
    if php-fpm${PHP_VERSION} -t >> "$LOG_FILE" 2>&1; then
        systemctl reload "$PHP_SERVICE" >> "$LOG_FILE" 2>&1 \
            && ok "PHP-FPM reloaded successfully" \
            || warn "Reload failed — check: journalctl -u $PHP_SERVICE"
    else
        warn "PHP-FPM config test FAILED — NOT reloading! Check config manually."
        warn "Run: php-fpm${PHP_VERSION} -t"
    fi
fi

# ─── FINAL REPORT ──────────────────────────────────────────────────────────────
section "Summary Report"
echo -e "${BOLD}"
printf "  %-22s %s\n" "Server:"         "$HOSTNAME"
printf "  %-22s %s\n" "Total RAM:"      "${TOTAL_RAM_MB} MB"
printf "  %-22s %s\n" "Available RAM:"  "${AVAILABLE_RAM_MB} MB (for PHP)"
printf "  %-22s %s\n" "CPU cores:"      "${CPU_CORES} cores"
printf "  %-22s %s\n" "CPU quota:"      "${GLOBAL_CPU_QUOTA:-N/A}% global (systemd)"
printf "  %-22s %s\n" "pm.max_children:" "${POOL_MAX_CHILDREN} per pool"
printf "  %-22s %s\n" "pm.max_requests:" "500 (worker auto-restart)"
printf "  %-22s %s\n" "Pools updated:"  "${POOLS_UPDATED}/${POOLS_FOUND}"
printf "  %-22s %s\n" "Log file:"       "$LOG_FILE"
echo -e "${NC}"

log "=== ${SCRIPT_NAME} ${VERSION} complete: ${POOLS_UPDATED}/${POOLS_FOUND} pools ==="
echo -e "${GREEN}${BOLD}✔ Done! ${VERSION} | = Rooted by VladiMIR | AI =${NC}"
