#!/bin/bash
clear
# =============================================================================
# wphealth.sh — WordPress health check for all sites
# =============================================================================
# Version     : v2026-03-25
# Author      : Ing. VladiMIR Bulantsev
# GitHub      : https://github.com/GinCz/Linux_Server_Public
# Server      : 222-DE-NetCup (xxx.xxx.xxx.222)
# =============================================================================
# = Rooted by VladiMIR | AI =
# =============================================================================

C="\033[1;36m"; G="\033[1;32m"; Y="\033[1;33m"; R="\033[1;31m"; X="\033[0m"
HR="${Y}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"

echo -e "$HR"
echo -e "${Y}   WordPress Health Check — 222-DE-NetCup${X}"
echo -e "$HR"
echo

OK=0; WARN=0; FAIL=0

for SITE_DIR in /var/www/*/; do
    SITE=$(basename "$SITE_DIR")
    WP="${SITE_DIR}data/www/${SITE}/wp-config.php"
    [ ! -f "$WP" ] && continue

    # Check wp-cron
    CRON_OFF=$(grep -c 'DISABLE_WP_CRON.*true' "$WP" 2>/dev/null)
    # Check .htaccess
    HT="${SITE_DIR}data/www/${SITE}/.htaccess"
    HT_OK=$([ -f "$HT" ] && echo "ok" || echo "missing")
    # Check index.php reachable
    IDX="${SITE_DIR}data/www/${SITE}/index.php"
    IDX_OK=$([ -f "$IDX" ] && echo "ok" || echo "missing")

    if [ "$CRON_OFF" -gt 0 ] && [ "$HT_OK" = "ok" ] && [ "$IDX_OK" = "ok" ]; then
        echo -e "  ${G}✔${X} ${SITE}"
        OK=$((OK+1))
    elif [ "$IDX_OK" = "missing" ]; then
        echo -e "  ${R}✘${X} ${SITE} — index.php missing!"
        FAIL=$((FAIL+1))
    else
        echo -e "  ${Y}⚠${X} ${SITE} — htaccess:${HT_OK} cron_disabled:${CRON_OFF}"
        WARN=$((WARN+1))
    fi
done

echo
echo -e "${G}OK: ${OK}${X}  ${Y}WARN: ${WARN}${X}  ${R}FAIL: ${FAIL}${X}"
echo
echo -e "$HR"
echo -e "${Y}              = Rooted by VladiMIR | AI =${X}"
echo -e "$HR"
echo
