#!/bin/bash
# = Rooted by VladiMIR | AI =
# set_php_fpm_limits_v2026-04-07.sh
# Universal PHP-FPM CPU + RAM limits for ALL pools on current server
# Works on BOTH servers: 222-DE-NetCup and 109-RU-FastVDS
# Version: v2026-04-07.3
#
# CHANGELOG:
#   v1 — initial, RAM limits only (pm.max_children), no CPU
#   v2 — added CPUQuota + MemoryMax via systemd; fixed FastPanel version '83'->'8.3';
#        fixed BLUE color invisible on black terminal
#   v3 — CRITICAL FIX: service detection.
#        FastPanel registers 'php84-fpm.service' / 'php56-fpm.service' in systemctl
#        BUT these units do NOT actually exist as real .service files.
#        The REAL running service on both servers is 'php8.3-fpm.service' (Ubuntu standard).
#        Fix: scan list-units output for pattern 'php[0-9]+\.[0-9]+-fpm\.service' (with dot)
#        which is the canonical Ubuntu/Debian naming. FastPanel phantom names are ignored.
#        Also: use 'systemctl restart' (not reload) to apply cgroup changes — reload
#        does NOT re-read the systemd override for CPUQuota/MemoryMax.

clear

# ─── CONFIG ────────────────────────────────────────────────────────────────────
VERSION="v2026-04-07.3"
SCRIPT_NAME="set_php_fpm_limits"
LOG_FILE="/var/log/${SCRIPT_NAME}.log"

# RAM reserves (MB) — OS + Nginx + MySQL + CrowdSec
RAM_RESERVE_MB=1500
# MB per PHP-FPM process (average WordPress site)
RAM_PER_PROCESS_MB=60
# Max % of available pool processes per pool (70% rule)
POOL_MAX_PERCENT=70
# CPU limit: 4 vCores = 400% total. 80% = always 1 core free for Nginx/MySQL/OS
CPU_MAX_PERCENT=80
# Hard floor / cap for pm.max_children per pool
MIN_CHILDREN=2
MAX_CHILDREN=8

# PHP-FPM pool config dirs — FastPanel structure (same on both servers)
PHP_POOL_DIRS=(
    "/etc/php/8.4/fpm/pool.d"
    "/etc/php/8.3/fpm/pool.d"
    "/etc/php/8.2/fpm/pool.d"
    "/etc/php/8.1/fpm/pool.d"
    "/etc/php/8.0/fpm/pool.d"
    "/etc/php/7.4/fpm/pool.d"
)

# ─── COLORS ────────────────────────────────────────────────────────────────────
# BLUE (\033[0;34m) is invisible on black terminal — use MAGENTA instead
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
echo "  │   PHP-FPM CPU + RAM Limits Manager ${VERSION}     │"
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
        || warn "cpulimit install failed — systemd cgroups will still work"
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

        # Skip www.conf (unused default pool — FastPanel never uses it)
        POOL_NAME=$(grep -m1 '^\[' "$CONF_FILE" | tr -d '[]')
        [[ "$POOL_NAME" == "www" ]] && continue

        POOLS_FOUND=$((POOLS_FOUND + 1))

        # Backup — one per version, won't overwrite if already exists
        cp -n "$CONF_FILE" "${CONF_FILE}.bak.${VERSION}" 2>/dev/null

        # pm = dynamic (workers scale up/down between min_spare and max_children)
        sed -i 's/^pm\s*=.*/pm = dynamic/' "$CONF_FILE"

        # pm.max_children — hard cap per pool
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

        # pm.max_requests = 500 — each worker auto-restarts after 500 requests
        # Prevents PHP memory leaks from accumulating over time
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

# ─── DETECT PHP-FPM SERVICE ────────────────────────────────────────────────────
# KEY LESSON LEARNED (v3):
#   FastPanel on both servers shows 'php84-fpm.service' / 'php56-fpm.service'
#   in systemctl list-units output, BUT these are phantom names that do NOT
#   correspond to real .service unit files.
#   The REAL service on both servers follows Ubuntu standard: 'php8.3-fpm.service'
#   Pattern with a dot in the version: php[MAJOR].[MINOR]-fpm.service
#
#   Detection order:
#   1. Look for 'php[digit].[digit]-fpm.service' (canonical Ubuntu format, with dot)
#   2. If not found, fall back to any php*-fpm.service that actually exists on disk
section "Applying CPU limits via systemd cgroups"

# Method 1: find canonical Ubuntu-named service (php8.3-fpm.service style)
PHP_SERVICE=$(systemctl list-units --type=service --state=running --no-pager 2>/dev/null \
    | grep -oE 'php[0-9]+\.[0-9]+-fpm\.service' | head -1)

# Method 2: fallback — find any php-fpm service with real unit file on disk
if [[ -z "$PHP_SERVICE" ]]; then
    for candidate in $(systemctl list-units --type=service --state=running --no-pager 2>/dev/null \
        | grep -oE 'php[0-9a-z.]*-fpm\.service'); do
        if systemctl cat "$candidate" &>/dev/null; then
            PHP_SERVICE="$candidate"
            break
        fi
    done
fi

GLOBAL_CPU_QUOTA=0

if [[ -z "$PHP_SERVICE" ]]; then
    warn "No running php-fpm service found — skipping systemd CPU limits"
    warn "Apply manually: create /etc/systemd/system/php8.X-fpm.service.d/cpu-memory-limit.conf"
else
    info "PHP-FPM service detected: $PHP_SERVICE"

    OVERRIDE_DIR="/etc/systemd/system/${PHP_SERVICE}.d"
    mkdir -p "$OVERRIDE_DIR"

    # CPU quota: cores × CPU_MAX_PERCENT
    # 4 cores × 80% = 320% — reserves ~1 core for Nginx + MySQL + OS at all times
    GLOBAL_CPU_QUOTA=$(( CPU_CORES * CPU_MAX_PERCENT ))
    MEM_HIGH=$(( AVAILABLE_RAM_MB * 85 / 100 ))

    cat > "${OVERRIDE_DIR}/cpu-memory-limit.conf" <<EOF
# = Rooted by VladiMIR | AI =
# systemd resource limits for ${PHP_SERVICE} — ${VERSION}
# Server: $(hostname) | Cores: ${CPU_CORES} | RAM: ${TOTAL_RAM_MB}MB
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
[Service]
# CPU: max ${GLOBAL_CPU_QUOTA}% total (${CPU_CORES} cores x ${CPU_MAX_PERCENT}%)
# Reserves ~1 core free for Nginx + MySQL + OS
CPUQuota=${GLOBAL_CPU_QUOTA}%
# RAM hard limit: kernel OOM-kills PHP workers first (not Nginx/MySQL)
MemoryMax=${AVAILABLE_RAM_MB}M
# RAM soft limit: kernel throttles PHP at 85% before hitting hard cap
MemoryHigh=${MEM_HIGH}M
# OOM priority: PHP workers die first (higher = killed sooner)
OOMScoreAdjust=300
EOF

    systemctl daemon-reload >> "$LOG_FILE" 2>&1
    ok "Override written: ${OVERRIDE_DIR}/cpu-memory-limit.conf"
    info "CPUQuota=${GLOBAL_CPU_QUOTA}% | MemoryMax=${AVAILABLE_RAM_MB}M | MemoryHigh=${MEM_HIGH}M"

    # IMPORTANT: 'reload' does NOT apply cgroup changes (CPUQuota/MemoryMax)
    # Only 'restart' forces systemd to re-read the override and apply cgroups.
    # Restart is safe — FastPanel pools reconnect in <1 second.
    info "Restarting ${PHP_SERVICE} to apply cgroup limits (reload is not enough)..."
    if systemctl restart "$PHP_SERVICE" >> "$LOG_FILE" 2>&1; then
        ok "${PHP_SERVICE} restarted — cgroup limits now active"
    else
        warn "Restart failed — try manually: systemctl restart ${PHP_SERVICE}"
        warn "Check: journalctl -u ${PHP_SERVICE} -n 20"
    fi

    # Verify limits actually applied
    APPLIED_QUOTA=$(systemctl show "$PHP_SERVICE" --property=CPUQuotaPerSecUSec 2>/dev/null | cut -d= -f2)
    if [[ "$APPLIED_QUOTA" != "infinity" && -n "$APPLIED_QUOTA" ]]; then
        ok "CPUQuota confirmed active: $APPLIED_QUOTA"
    else
        warn "CPUQuota still showing infinity — check: systemctl show ${PHP_SERVICE} | grep CPUQuota"
    fi
fi

# ─── FINAL REPORT ──────────────────────────────────────────────────────────────
section "Summary Report"
echo -e "${BOLD}"
printf "  %-26s %s\n" "Server:"           "$HOSTNAME"
printf "  %-26s %s\n" "Total RAM:"        "${TOTAL_RAM_MB} MB"
printf "  %-26s %s\n" "Available RAM:"    "${AVAILABLE_RAM_MB} MB (for PHP)"
printf "  %-26s %s\n" "CPU cores:"        "${CPU_CORES} cores"
printf "  %-26s %s\n" "systemd CPUQuota:" "${GLOBAL_CPU_QUOTA:-N/A}%"
printf "  %-26s %s\n" "pm.max_children:"  "${POOL_MAX_CHILDREN} per pool"
printf "  %-26s %s\n" "pm.max_requests:"  "500 (worker auto-restart)"
printf "  %-26s %s\n" "Pools updated:"    "${POOLS_UPDATED}/${POOLS_FOUND}"
printf "  %-26s %s\n" "PHP-FPM service:"  "${PHP_SERVICE:-not detected}"
printf "  %-26s %s\n" "Override dir:"     "${OVERRIDE_DIR:-N/A}"
printf "  %-26s %s\n" "Log file:"         "$LOG_FILE"
echo -e "${NC}"

echo -e "${CYAN}Verify limits:${NC}"
echo -e "  systemctl show ${PHP_SERVICE:-php8.X-fpm.service} | grep -E 'CPUQuota|MemoryMax|MemoryHigh'"
echo

log "=== ${SCRIPT_NAME} ${VERSION} complete: ${POOLS_UPDATED}/${POOLS_FOUND} pools ==="
echo -e "${GREEN}${BOLD}✔ Done! ${VERSION} | = Rooted by VladiMIR | AI =${NC}"
