#!/bin/bash
clear
# =============================================================================
# wphealth.sh — WordPress health check for all sites on 222-DE-NetCup
# Version     : v2026-04-08
# Server      : 222-DE-NetCup (152.53.182.222) / FASTPANEL
# Usage       : wphealth  (alias)
# FASTPANEL site root: /var/www/<site>/data/www/<site>/
#              or      /var/www/<site>/  (flat)
# = Rooted by VladiMIR | AI =
# =============================================================================

C="\033[1;36m"; G="\033[1;32m"; Y="\033[1;33m"; R="\033[1;31m"; X="\033[0m"
HR="${C}$(printf '═%.0s' {1..70})${X}"

echo -e "$HR"
echo -e "${Y}   WordPress Health Check — 222-DE-NetCup${X}"
echo -e "$HR"
echo

OK=0; WARN=0; FAIL=0; SKIP=0

for SITE_DIR in /var/www/*/; do
    SITE=$(basename "$SITE_DIR")

    # Try multiple FASTPANEL path variants
    WP=""
    for TRY in \
        "${SITE_DIR}data/www/${SITE}/wp-config.php" \
        "${SITE_DIR}wp-config.php" \
        "${SITE_DIR}public_html/wp-config.php" \
        "${SITE_DIR}www/wp-config.php"
    do
        if [ -f "$TRY" ]; then
            WP="$TRY"
            WP_ROOT=$(dirname "$TRY")
            break
        fi
    done

    # Skip non-WordPress dirs
    [ -z "$WP" ] && SKIP=$((SKIP+1)) && continue

    # Check DISABLE_WP_CRON
    CRON_OFF=$(grep -c 'DISABLE_WP_CRON.*true' "$WP" 2>/dev/null || echo 0)

    # Check .htaccess
    HT_OK=$([ -f "${WP_ROOT}/.htaccess" ] && echo "ok" || echo "missing")

    # Check index.php
    IDX_OK=$([ -f "${WP_ROOT}/index.php" ] && echo "ok" || echo "missing")

    # Check wp-login.php (confirms it's WP)
    LOGIN_OK=$([ -f "${WP_ROOT}/wp-login.php" ] && echo "ok" || echo "missing")

    # Status
    if [ "$IDX_OK" = "missing" ] || [ "$LOGIN_OK" = "missing" ]; then
        echo -e "  ${R}✘${X} ${Y}${SITE}${X} — wp-login.php or index.php missing!"
        FAIL=$((FAIL+1))
    elif [ "$HT_OK" = "missing" ]; then
        echo -e "  ${Y}⚠${X} ${SITE} — .htaccess missing"
        WARN=$((WARN+1))
    elif [ "$CRON_OFF" -eq 0 ]; then
        echo -e "  ${Y}⚠${X} ${SITE} — DISABLE_WP_CRON not set (WP-Cron runs on every page load)"
        WARN=$((WARN+1))
    else
        echo -e "  ${G}✔${X} ${SITE}"
        OK=$((OK+1))
    fi
done

echo
echo -e "${G}OK: ${OK}${X}  ${Y}WARN: ${WARN}${X}  ${R}FAIL: ${FAIL}${X}  (skipped non-WP: ${SKIP})"
echo
echo -e "$HR"
echo -e "${Y}              = Rooted by VladiMIR | AI =${X}"
echo -e "$HR"
echo
