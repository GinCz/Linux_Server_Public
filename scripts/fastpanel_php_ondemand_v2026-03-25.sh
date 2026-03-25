#!/usr/bin/env bash
# = Rooted by VladiMIR | AI =
# FASTPANEL PHP-FPM ondemand optimizer v2026-03-25
# Switches idle/low-traffic site pools from dynamic to ondemand
# to free RAM on servers with 30+ WordPress sites.
# SAFE: only modifies pool conf files, does NOT touch FASTPANEL DB.
# Run as root on 222-DE-NetCup or 109-RU-FastVDS

clear

C='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; B='\033[1;34m'; X='\033[0m'

echo -e "${Y}=== FASTPANEL PHP-FPM ondemand optimizer v2026-03-25 ===${X}"
echo -e "${Y}= Rooted by VladiMIR | AI =${X}\n"

# ---------------------------------------------------------------
# Sites that must stay DYNAMIC (high traffic, WooCommerce, etc.)
# ---------------------------------------------------------------
KEEP_DYNAMIC=(
    "svetaform.eu"
    "wowflow.cz"
    "gadanie-tel.eu"
    "czechtoday.eu"
    "bio-zahrada.eu"
)

# ---------------------------------------------------------------
# ALL pool directories: system + FASTPANEL /opt/php* locations
# ---------------------------------------------------------------
POOL_DIRS=(
    /etc/php/8.3/fpm/pool.d
    /opt/php84/etc/php-fpm.d
    /opt/fphp/etc/php-fpm.d
    /opt/php74/etc/php-fpm.d
    /opt/php56/etc/php-fpm.d
)

# FASTPANEL service names for reload
declare -A FPM_SERVICES=(
    ["/etc/php/8.3/fpm/pool.d"]="php8.3-fpm"
    ["/opt/php84/etc/php-fpm.d"]="fpm84"
    ["/opt/fphp/etc/php-fpm.d"]="fphp"
    ["/opt/php74/etc/php-fpm.d"]="fpm74"
    ["/opt/php56/etc/php-fpm.d"]="fpm56"
)

CHANGED=0
SKIPPED=0
ALREADY=0
RELOAD_SERVICES=()

for POOL_DIR in "${POOL_DIRS[@]}"; do
    [ -d "$POOL_DIR" ] || continue
    echo -e "${B}--- Pools in ${POOL_DIR} ---${X}"

    for CONF in "$POOL_DIR"/*.conf; do
        [ -f "$CONF" ] || continue
        POOL_NAME=$(basename "$CONF" .conf)

        # Skip www and default pools
        [[ "$POOL_NAME" =~ ^(www|default|pool)$ ]] && continue

        # Check if this pool should stay dynamic
        KEEP=0
        for SITE in "${KEEP_DYNAMIC[@]}"; do
            if [[ "$POOL_NAME" == *"$SITE"* ]]; then
                KEEP=1
                break
            fi
        done

        CURRENT_PM=$(grep -E "^pm\s*=" "$CONF" | awk '{print $3}')

        if [ "$KEEP" -eq 1 ]; then
            echo -e "  ${C}[KEEP dynamic]${X} $POOL_NAME (pm = $CURRENT_PM)"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi

        if [ "$CURRENT_PM" = "ondemand" ]; then
            echo -e "  [already ondemand] $POOL_NAME"
            ALREADY=$((ALREADY + 1))
            continue
        fi

        # Backup original
        cp "$CONF" "${CONF}.bak.$(date +%Y%m%d_%H%M%S)"

        # Switch to ondemand
        sed -i "s/^pm\s*=.*/pm = ondemand/" "$CONF"

        # Set process idle timeout to 10 seconds
        if grep -q "^pm.process_idle_timeout" "$CONF"; then
            sed -i "s/^pm.process_idle_timeout.*/pm.process_idle_timeout = 10s/" "$CONF"
        else
            echo "pm.process_idle_timeout = 10s" >> "$CONF"
        fi

        # Ensure max_children is at least 4
        MAX=$(grep -E "^pm.max_children" "$CONF" | awk '{print $3}')
        if [ -z "$MAX" ] || [ "$MAX" -lt 4 ]; then
            if grep -q "^pm.max_children" "$CONF"; then
                sed -i "s/^pm.max_children.*/pm.max_children = 4/" "$CONF"
            else
                echo "pm.max_children = 4" >> "$CONF"
            fi
        fi

        echo -e "  ${Y}[CHANGED]${X} $POOL_NAME: $CURRENT_PM -> ondemand"
        CHANGED=$((CHANGED + 1))

        # Mark service for reload
        SVC="${FPM_SERVICES[$POOL_DIR]}"
        [[ ! " ${RELOAD_SERVICES[*]} " =~ " ${SVC} " ]] && RELOAD_SERVICES+=("$SVC")
    done
done

echo ""
echo -e "${B}=== Summary ===${X}"
echo -e "  Changed to ondemand : ${Y}$CHANGED${X}"
echo -e "  Kept dynamic        : ${C}$SKIPPED${X}"
echo -e "  Already ondemand    : $ALREADY"

if [ "$CHANGED" -gt 0 ]; then
    echo ""
    echo -e "${Y}Reloading PHP-FPM services...${X}"
    for SVC in "${RELOAD_SERVICES[@]}"; do
        if systemctl is-active --quiet "$SVC" 2>/dev/null; then
            systemctl reload "$SVC" && \
                echo -e "  ${C}[OK]${X} $SVC reloaded" || \
                echo -e "  ${R}[FAIL]${X} $SVC reload failed"
        else
            echo -e "  ${Y}[SKIP]${X} $SVC not running"
        fi
    done
    echo ""
    echo -e "${C}Done! Check RAM in 30 seconds:${X}"
    echo "  free -h"
    echo "  ps aux | grep php-fpm | grep -v grep | wc -l"
else
    echo -e "${C}Nothing to change.${X}"
fi
