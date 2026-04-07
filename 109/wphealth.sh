#!/bin/bash
clear
# =============================================================================
# wphealth.sh — WordPress health check for all sites on 109-RU-FastVDS
# Version     : v2026-04-08
# Server      : 109-RU-FastVDS (212.109.223.109) / FASTPANEL
# Usage       : wphealth  (alias)
# FASTPANEL real path: /var/www/<site>/data/www/<domain.ext>/wp-config.php
# = Rooted by VladiMIR | AI =
# =============================================================================

C="\033[1;36m"; G="\033[1;32m"; Y="\033[1;33m"; R="\033[1;31m"; X="\033[0m"
HR="${C}$(printf '═%.0s' {1..70})${X}"

echo -e "$HR"
echo -e "${Y}   WordPress Health Check — 109-RU-FastVDS${X}"
echo -e "$HR"
echo

OK=0; WARN=0; FAIL=0; SKIP=0

for SITE_DIR in /var/www/*/; do
    SITE=$(basename "$SITE_DIR")
    WP=""
    WP_ROOT=""

    # FASTPANEL: /var/www/<site>/data/www/<domain.*>/wp-config.php
    for TRY_ROOT in "${SITE_DIR}data/www/"/*/; do
        if [ -f "${TRY_ROOT}wp-config.php" ]; then
            WP="${TRY_ROOT}wp-config.php"
            WP_ROOT="$TRY_ROOT"
            break
        fi
    done

    # Fallback: flat paths
    if [ -z "$WP" ]; then
        for TRY in \
            "${SITE_DIR}wp-config.php" \
            "${SITE_DIR}public_html/wp-config.php" \
            "${SITE_DIR}www/wp-config.php"
        do
            if [ -f "$TRY" ]; then
                WP="$TRY"
                WP_ROOT=$(dirname "$TRY")/
                break
            fi
        done
    fi

    if [ -z "$WP" ]; then
        SKIP=$((SKIP+1))
        continue
    fi

    DOMAIN=$(basename "$WP_ROOT")

    CRON_OFF=$(grep -c 'DISABLE_WP_CRON.*true' "$WP" 2>/dev/null || echo 0)
    HT_OK=$([ -f "${WP_ROOT}.htaccess" ] && echo "ok" || echo "missing")
    IDX_OK=$([ -f "${WP_ROOT}index.php" ] && echo "ok" || echo "missing")
    LOGIN_OK=$([ -f "${WP_ROOT}wp-login.php" ] && echo "ok" || echo "missing")

    if [ "$IDX_OK" = "missing" ] || [ "$LOGIN_OK" = "missing" ]; then
        echo -e "  ${R}✘${X} ${Y}${DOMAIN}${X} — wp-login.php or index.php missing!"
        FAIL=$((FAIL+1))
    elif [ "$HT_OK" = "missing" ]; then
        echo -e "  ${Y}⚠${X} ${DOMAIN} — .htaccess missing"
        WARN=$((WARN+1))
    elif [ "$CRON_OFF" -eq 0 ]; then
        echo -e "  ${Y}⚠${X} ${DOMAIN} — DISABLE_WP_CRON not set"
        WARN=$((WARN+1))
    else
        echo -e "  ${G}✔${X} ${DOMAIN}"
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
