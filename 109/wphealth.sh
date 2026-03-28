#!/bin/bash
clear
# =============================================================================
# wphealth.sh — WordPress health check for all sites
# =============================================================================
# Version     : v2026-03-28
# Author      : Ing. VladiMIR Bulantsev
# GitHub      : https://github.com/GinCz/Linux_Server_Public
# Server      : 109-RU-FastVDS (xxx.xxx.xxx.109)
# Checks      : index.php, .htaccess, DISABLE_WP_CRON, FS_METHOD, WP_AUTO_UPDATE_CORE
# =============================================================================
# = Rooted by VladiMIR | AI =
# =============================================================================

C="\033[1;36m"; G="\033[1;32m"; Y="\033[1;33m"; R="\033[1;31m"; W="\033[1;37m"; X="\033[0m"
HR="${Y}\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b${X}"

echo -e "$HR"
echo -e "${Y}   WordPress Health Check — 109-RU-FastVDS${X}"
echo -e "${C}   Checks: index.php | .htaccess | DISABLE_WP_CRON | FS_METHOD | WP_AUTO_UPDATE${X}"
echo -e "$HR"
echo

OK=0; WARN=0; FAIL=0

for SITE_DIR in /var/www/*/; do
    SITE=$(basename "$SITE_DIR")
    WP="${SITE_DIR}data/www/${SITE}/wp-config.php"
    [ ! -f "$WP" ] && continue

    # --- Checks ---
    CRON_OFF=$(grep -c 'DISABLE_WP_CRON.*true' "$WP" 2>/dev/null)
    FS_OK=$(grep -c 'FS_METHOD' "$WP" 2>/dev/null)
    AUTO_UPDATE=$(grep "WP_AUTO_UPDATE_CORE" "$WP" 2>/dev/null | grep -v '^#' | head -1)
    HT="${SITE_DIR}data/www/${SITE}/.htaccess"
    HT_OK=$([ -f "$HT" ] && echo "ok" || echo "missing")
    IDX="${SITE_DIR}data/www/${SITE}/index.php"
    IDX_OK=$([ -f "$IDX" ] && echo "ok" || echo "missing")

    # --- Determine status ---
    ISSUES=""
    [ "$IDX_OK" = "missing" ]  && ISSUES="${ISSUES} ${R}[NO index.php]${X}"
    [ "$HT_OK" = "missing" ]   && ISSUES="${ISSUES} ${Y}[NO .htaccess]${X}"
    [ "$CRON_OFF" -eq 0 ]      && ISSUES="${ISSUES} ${Y}[WP_CRON active!]${X}"
    [ "$FS_OK" -eq 0 ]         && ISSUES="${ISSUES} ${R}[NO FS_METHOD]${X}"

    # WP_AUTO_UPDATE_CORE info
    if echo "$AUTO_UPDATE" | grep -q "''\|false"; then
        ISSUES="${ISSUES} ${Y}[AUTO_UPDATE off]${X}"
        AU_LABEL="${R}off${X}"
    elif echo "$AUTO_UPDATE" | grep -q "minor"; then
        AU_LABEL="${G}minor${X}"
    elif echo "$AUTO_UPDATE" | grep -q "true"; then
        AU_LABEL="${G}all${X}"
    else
        AU_LABEL="${W}default${X}"
    fi

    if [ -z "$ISSUES" ]; then
        echo -e "  ${G}\u2714${X} ${W}${SITE}${X}  upd:${AU_LABEL}"
        OK=$((OK+1))
    elif echo "$ISSUES" | grep -q "\\[NO index"; then
        echo -e "  ${R}\u2718${X} ${W}${SITE}${X}${ISSUES}"
        FAIL=$((FAIL+1))
    else
        echo -e "  ${Y}\u26a0${X} ${W}${SITE}${X}${ISSUES}  upd:${AU_LABEL}"
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
