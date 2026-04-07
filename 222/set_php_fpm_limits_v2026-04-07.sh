#!/bin/bash
# = Rooted by VladiMIR | AI =
# set_php_fpm_limits_v2026-04-07.sh
# Universal PHP-FPM CPU + RAM limits for ALL pools on current server
# Works on BOTH servers: 222-DE-NetCup and 109-RU-FastVDS
# Version: v2026-04-07.2 (bugfix: FastPanel service names, colors)
#
# BUGFIXES vs v1:
#   - FastPanel names services as php83-fpm / php84-fpm (no dot, digits slammed together)
#     Old grep 'php[0-9.]*-fpm.service' caught the name correctly,
#     but then PHP_VERSION extraction gave '83' or '84' instead of '8.3'/'8.4'
#     so 'php-fpm83 -t' failed. Fix: convert '83' -> '8.3' via sed insert-dot.
#   - BLUE color (\033[0;34m) invisible on black terminal. Replaced with MAGENTA (\033[1;35m).

clear

# ─── CONFIG ────────────────────────────────────────────────────────────────────
VERSION="v2026-04-07.2"
SCRIPT_NAME="set_php_fpm_limits"
LOG_FILE="/var/log/${SCRIPT_NAME}.log"

# RAM reserves (MB) — OS + Nginx + MySQL + CrowdSec
RAM_RESERVE_MB=1500
# MB per PHP-FPM process (average WordPress site)
RAM_PER_PROCESS_MB=60
# Max % of available pool processes per pool (70% rule)
POOL_MAX_PERCENT=70
# CPU limit per pool: 4 vCores = 400% total. Each pool max 80% = 1 full core + buffer.
CPU_MAX_PERCENT=80
# Hard floor / cap for pm.max_children
MIN_CHILDREN=2
MAX_CHILDREN=8

# PHP-FPM pool config dirs (FastPanel structure — same on both servers)
PHP_POOL_DIRS=(
    "/etc/php/8.4/fpm/pool.d"
    "/etc/php/8.3/fpm/pool.d"
    "/etc/php/8.2/fpm/pool.d"
    "/etc/php/8.1/fpm/pool.d"
    "/etc/php/8.0/fpm/pool.d"
    "/etc/php/7.4/fpm/pool.d"
)

# ─── COLORS ────────────────────────────────────────────────────────────────────
# NOTE: BLUE (\033[0;34m) is invisible on black terminal background!
# Use MAGENTA (\033[1;35m) for section headers — bright, visible everywhere.
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# ─── LOGGING ───────────────────────────────────────────────────────────────────
log()     { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }
info()    { echo -e "${CYAN}[INFO]${NC}  $1"; log "INFO: $1"; }
ok()      { echo -e "${GREEN}[OK]${NC}    $1"; log "OK: $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; log "WARN: $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; log "ERROR: $1"; }
section() {
    echo -e "\n${BOLD}${MAGENTA}══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  $1${NC}"
    echo -e "${BOLD}${MAGENTA}══════════════════════════════════════════${NC}"
}

# ─── HEADER ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}${MAGENTA}"
echo "  ┌─────────────────────────────────────────────────────┐"
echo "  │   PHP-FPM CPU + RAM Limits Manager ${VERSION}   │"
echo "  │   = Rooted by VladiMIR | AI =                       │"
echo "  └─────────────────────────────────────────────────────┘"
echo -e "${NC}"

# ─── ROOT CHECK ────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    error "Run as root: sudo $0"
    exit 1
fi

# ─── DETECT SERVER & RESOURCES ─────────────────────────────────────────────────
section "Detecting server environment"
HOSTNAME=$(hostname)
TOTAL_RAM_MB=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo)
CPU_CORES=$(nproc)
TOTAL_CPU_PERCENT=$((CPU_CORES * 100))
AVAILABLE_RAM_MB=$((TOTAL_RAM_MB - RAM_RESERVE_MB))
MAX_TOTAL_PROCESSES=$((AVAILABLE_RAM_MB / RAM_PER_PROCESS_MB))
POOL_MAX_CHILDREN=$(( MAX_TOTAL_PROCESSES * POOL_MAX_PERCENT / 100 ))
[[ $POOL_MAX_CHILDREN -lt $MIN_CHILDREN ]] && POOL_MAX_CHILDREN=$MIN_CHILDREN
[[ $POOL_MAX_CHILDREN -gt $MAX_CHILDREN ]] && POOL_MAX_CHILDREN=$MAX_CHILDREN

info "Hostname:          $HOSTNAME"
info "Total RAM:         ${TOTAL_RAM_MB} MB"
info "Reserved RAM:      ${RAM_RESERVE_MB} MB (OS + Nginx + MySQL + CrowdSec)"
info "Available RAM:     ${AVAILABLE_RAM_MB} MB"
info "CPU cores:         ${CPU_CORES} (total ${TOTAL_CPU_PERCENT}%)"
info "CPU per pool cap:  max ${CPU_MAX_PERCENT}%"
info "Max total PHP:     ${MAX_TOTAL_PROCESSES} processes"
info "pm.max_children:   ${POOL_MAX_CHILDREN} per pool (${POOL_MAX_PERCENT}% rule, hard cap ${MAX_CHILDREN})"

# ─── INSTALL cpulimit ──────────────────────────────────────────────────────────
section "Checking cpulimit"
if ! command -v cpulimit &>/dev/null; then
    info "Installing cpulimit..."
    apt-get install -y cpulimit >> "$LOG_FILE" 2>&1 \
        && ok "cpulimit installed" \
        || warn "cpulimit install failed — using systemd cgroups only"
else
    ok "cpulimit already installed: $(cpulimit --version 2>&1 | head -1)"
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

        # Skip www.conf (unused default pool)
        POOL_NAME=$(grep -m1 '^\[' "$CONF_FILE" | tr -d '[]')
        [[ "$POOL_NAME" == "www" ]] && continue

        POOLS_FOUND=$((POOLS_FOUND + 1))

        # Backup (one per version, no duplicates)
        cp "$CONF_FILE" "${CONF_FILE}.bak.${VERSION}" 2>/dev/null

        # pm = dynamic (allows scaling up/down within limits)
        sed -i 's/^pm\s*=.*/pm = dynamic/' "$CONF_FILE"

        # pm.max_children — absolute hard cap per pool
        if grep -q "^pm.max_children" "$CONF_FILE"; then
            sed -i "s/^pm.max_children\s*=.*/pm.max_children = ${POOL_MAX_CHILDREN}/" "$CONF_FILE"
        else
            echo "pm.max_children = ${POOL_MAX_CHILDREN}" >> "$CONF_FILE"
        fi

        # pm.start_servers = 25% of max_children (min 1)
        START=$(( POOL_MAX_CHILDREN / 4 ))
        [[ $START -lt 1 ]] && START=1
        if grep -q "^pm.start_servers" "$CONF_FILE"; then
            sed -i "s/^pm.start_servers\s*=.*/pm.start_servers = ${START}/" "$CONF_FILE"
        else
            echo "pm.start_servers = ${START}" >> "$CONF_FILE"
        fi

        # pm.min_spare_servers = 20% of max_children (min 1)
        MIN_SPARE=$(( POOL_MAX_CHILDREN / 5 ))
        [[ $MIN_SPARE -lt 1 ]] && MIN_SPARE=1
        if grep -q "^pm.min_spare_servers" "$CONF_FILE"; then
            sed -i "s/^pm.min_spare_servers\s*=.*/pm.min_spare_servers = ${MIN_SPARE}/" "$CONF_FILE"
        else
            echo "pm.min_spare_servers = ${MIN_SPARE}" >> "$CONF_FILE"
        fi

        # pm.max_spare_servers = 50% of max_children (min 1)
        MAX_SPARE=$(( POOL_MAX_CHILDREN / 2 ))
        [[ $MAX_SPARE -lt 1 ]] && MAX_SPARE=1
        if grep -q "^pm.max_spare_servers" "$CONF_FILE"; then
            sed -i "s/^pm.max_spare_servers\s*=.*/pm.max_spare_servers = ${MAX_SPARE}/" "$CONF_FILE"
        else
            echo "pm.max_spare_servers = ${MAX_SPARE}" >> "$CONF_FILE"
        fi

        # pm.max_requests = 500 — worker auto-restart prevents memory leaks
        if grep -q "^pm.max_requests" "$CONF_FILE"; then
            sed -i "s/^pm.max_requests\s*=.*/pm.max_requests = 500/" "$CONF_FILE"
        else
            echo "pm.max_requests = 500" >> "$CONF_FILE"
        fi

        POOLS_UPDATED=$((POOLS_UPDATED + 1))
        ok "Pool [$POOL_NAME] max=${POOL_MAX_CHILDREN} start=${START} min_spare=${MIN_SPARE} max_spare=${MAX_SPARE} max_req=500"
    done
done

info "Pools found: ${POOLS_FOUND} | Updated: ${POOLS_UPDATED}"

# ─── DETECT PHP-FPM SERVICE (FASTPANEL NAMES) ─────────────────────────────────
# FastPanel names services WITHOUT a dot: php83-fpm, php84-fpm, php56-fpm etc.
# Standard Ubuntu names them: php8.3-fpm, php8.2-fpm etc.
# We detect whatever is running and handle both formats.
section "Applying CPU limits via systemd cgroups"

PHP_SERVICE=$(systemctl list-units --type=service --state=running \
    | grep -oE 'php[0-9.]*-fpm\.service' | head -1)

GLOBAL_CPU_QUOTA=0

if [[ -z "$PHP_SERVICE" ]]; then
    warn "No running php-fpm service found — skipping systemd CPU limits"
else
    info "PHP-FPM service detected: $PHP_SERVICE"

    # Extract version digits from service name (e.g. '83' from 'php83-fpm.service')
    RAW_VER=$(echo "$PHP_SERVICE" | grep -oE '[0-9]+')

    # Convert FastPanel compact format to dotted: '83' -> '8.3', '84' -> '8.4', '56' -> '5.6'
    # Standard format '8.3' stays '8.3' (already has a dot)
    if echo "$RAW_VER" | grep -q '\.'; then
        PHP_VERSION="$RAW_VER"
    else
        # Insert dot after first digit: '83' -> '8.3'
        PHP_VERSION=$(echo "$RAW_VER" | sed 's/^\(.\.\?\)\(.*\)/\1.\2/' | sed 's/\.//')
        # Simpler: just insert dot after char 1
        PHP_VERSION=$(echo "$RAW_VER" | sed 's/^\(\d\)/\1./')
        # Fallback with pure bash
        PHP_VERSION="${RAW_VER:0:1}.${RAW_VER:1}"
    fi
    info "PHP version (dotted): ${PHP_VERSION}"

    OVERRIDE_DIR="/etc/systemd/system/${PHP_SERVICE}.d"
    mkdir -p "$OVERRIDE_DIR"

    # Global CPU quota: cores × CPU_MAX_PERCENT
    # Example: 4 cores × 80% = 320% — always leaves 1 core free for Nginx/MySQL/OS
    GLOBAL_CPU_QUOTA=$(( CPU_CORES * CPU_MAX_PERCENT ))

    cat > "${OVERRIDE_DIR}/cpu-memory-limit.conf" <<EOF
# = Rooted by VladiMIR | AI =
# systemd resource limits for ${PHP_SERVICE} — ${VERSION}
# Server: $(hostname) | Cores: ${CPU_CORES} | RAM: ${TOTAL_RAM_MB}MB
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
[Service]
# CPU: allow max ${GLOBAL_CPU_QUOTA}% total (${CPU_CORES} cores × ${CPU_MAX_PERCENT}%)
# Always leaves ~1 core free for Nginx + MySQL + OS
CPUQuota=${GLOBAL_CPU_QUOTA}%
# RAM hard limit — kernel OOM-kills PHP workers first, not Nginx/MySQL
MemoryMax=${AVAILABLE_RAM_MB}M
# RAM soft limit — kernel starts throttling at 85% before hitting hard limit
MemoryHigh=$(( AVAILABLE_RAM_MB * 85 / 100 ))M
# OOM score: PHP workers die first (300 = higher priority to kill)
OOMScoreAdjust=300
EOF

    systemctl daemon-reload >> "$LOG_FILE" 2>&1
    ok "Override written: ${OVERRIDE_DIR}/cpu-memory-limit.conf"
    info "CPUQuota=${GLOBAL_CPU_QUOTA}% | MemoryMax=${AVAILABLE_RAM_MB}M | MemoryHigh=$(( AVAILABLE_RAM_MB * 85 / 100 ))M"
fi

# ─── RELOAD PHP-FPM ────────────────────────────────────────────────────────────
section "Reloading PHP-FPM"
if [[ -n "$PHP_SERVICE" && -n "$PHP_VERSION" ]]; then
    # Try both FastPanel (php83-fpm) and standard (php-fpm8.3) binary names
    FPM_BIN=""
    for candidate in \
        "php-fpm${PHP_VERSION}" \
        "php${PHP_VERSION}-fpm" \
        "/usr/sbin/php-fpm${PHP_VERSION}" \
        "/usr/sbin/php${PHP_VERSION}-fpm"; do
        if command -v "$candidate" &>/dev/null; then
            FPM_BIN="$candidate"
            break
        fi
    done

    if [[ -z "$FPM_BIN" ]]; then
        warn "Cannot find php-fpm binary for version ${PHP_VERSION} — skipping config test"
        warn "Manual reload: systemctl reload $PHP_SERVICE"
    else
        info "Testing config with: $FPM_BIN -t"
        if "$FPM_BIN" -t >> "$LOG_FILE" 2>&1; then
            systemctl reload "$PHP_SERVICE" >> "$LOG_FILE" 2>&1 \
                && ok "PHP-FPM reloaded: $PHP_SERVICE" \
                || warn "Reload failed — check: journalctl -u $PHP_SERVICE"
        else
            warn "PHP-FPM config test FAILED — NOT reloading!"
            warn "Fix config manually, then run: systemctl reload $PHP_SERVICE"
            warn "Test command: $FPM_BIN -t"
        fi
    fi
fi

# ─── FINAL REPORT ──────────────────────────────────────────────────────────────
section "Summary Report"
echo -e "${BOLD}"
printf "  %-24s %s\n" "Server:"          "$HOSTNAME"
printf "  %-24s %s\n" "Total RAM:"       "${TOTAL_RAM_MB} MB"
printf "  %-24s %s\n" "Available RAM:"   "${AVAILABLE_RAM_MB} MB (for PHP)"
printf "  %-24s %s\n" "CPU cores:"       "${CPU_CORES} cores"
printf "  %-24s %s\n" "systemd CPUQuota:" "${GLOBAL_CPU_QUOTA:-N/A}%"
printf "  %-24s %s\n" "pm.max_children:" "${POOL_MAX_CHILDREN} per pool"
printf "  %-24s %s\n" "pm.max_requests:" "500 (worker auto-restart)"
printf "  %-24s %s\n" "Pools updated:"   "${POOLS_UPDATED}/${POOLS_FOUND}"
printf "  %-24s %s\n" "PHP-FPM service:" "${PHP_SERVICE:-not detected}"
printf "  %-24s %s\n" "Log file:"        "$LOG_FILE"
echo -e "${NC}"

log "=== ${SCRIPT_NAME} ${VERSION} complete: ${POOLS_UPDATED}/${POOLS_FOUND} pools ==="
echo -e "${GREEN}${BOLD}✔ Done! ${VERSION} | = Rooted by VladiMIR | AI =${NC}"
