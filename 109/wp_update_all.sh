#!/bin/bash
clear
# =============================================================================
#  wp_update_all.sh
# =============================================================================
#  Version    : v2026-04-01
#  Author     : Ing. VladiMIR Bulantsev
#  GitHub     : https://github.com/GinCz/Linux_Server_Public
#  Server     : 109-RU-FastVDS (212.109.223.109)
#  License    : MIT
# =============================================================================
#
#  DESCRIPTION
#  -----------
#  Updates WordPress plugins and themes for ALL sites on FastPanel.
#  Runs wp-cli as the correct site owner (not root) to avoid permission issues.
#  FastPanel structure: /var/www/USER/data/www/DOMAIN/
#
#  USAGE
#  -----
#  Manual run:   bash /root/wp_update_all.sh
#  Alias:        wpupd
#  Cron (04:00): 0 4 * * 0  bash /root/wp_update_all.sh >> /var/log/wp_update.log 2>&1
#
# =============================================================================
#  = Rooted by VladiMIR | AI =
# =============================================================================

# --- Colors ---
C="\033[1;36m"; G="\033[1;32m"; Y="\033[1;33m"; R="\033[1;31m"; W="\033[1;37m"; X="\033[0m"
HR="${Y}\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b\u254b${X}"

WP=/usr/local/bin/wp
OK=0; SKIP=0; FAIL=0; TOTAL=0
SUMMARY=""

echo -e "$HR"
echo -e "${Y}   🔄 WP UPDATE ALL — 109-RU-FastVDS — $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "${C}   Updates: plugins + themes | runs as site owner user${X}"
echo -e "$HR"
echo

# Check wp-cli exists
if [ ! -x "$WP" ]; then
    echo -e "${R}\u274c wp-cli not found at $WP${X}"
    echo -e "${Y}Install: curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar${X}"
    echo -e "${Y}         chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp${X}"
    exit 1
fi

# Loop through all users in /var/www/
for USER_DIR in /var/www/*/; do
    SITE_USER=$(basename "$USER_DIR")

    # Skip system/service users
    [[ "$SITE_USER" == "fastuser" || "$SITE_USER" == "lost+found" ]] && continue
    # Skip if user doesn't exist on system
    id "$SITE_USER" &>/dev/null || continue

    # Loop through all domains of this user
    for DOMAIN_DIR in "${USER_DIR}data/www/"/*/; do
        [ -d "$DOMAIN_DIR" ] || continue
        DOMAIN=$(basename "$DOMAIN_DIR")
        WP_CONFIG="${DOMAIN_DIR}wp-config.php"

        # Skip non-WordPress directories
        [ -f "$WP_CONFIG" ] || continue

        TOTAL=$((TOTAL+1))
        echo -e "${C}[•] ${W}${SITE_USER}${X} / ${Y}${DOMAIN}${X}"

        # --- Update plugins ---
        PLUGIN_OUT=$(sudo -u "$SITE_USER" "$WP" plugin update --all \
            --path="$DOMAIN_DIR" \
            --no-color 2>&1)
        PLUGIN_STATUS=$?

        if [ $PLUGIN_STATUS -eq 0 ]; then
            # Count updated plugins
            UPDATED=$(echo "$PLUGIN_OUT" | grep -c 'Updated' 2>/dev/null || echo 0)
            if echo "$PLUGIN_OUT" | grep -q 'No plugin updates available'; then
                echo -e "  ${G}\u2714${X} plugins: up to date"
            else
                echo -e "  ${G}\u2714${X} plugins: ${G}${UPDATED} updated${X}"
            fi
        else
            echo -e "  ${R}\u274c${X} plugins: FAILED"
            echo -e "  ${R}$(echo "$PLUGIN_OUT" | tail -3)${X}"
            FAIL=$((FAIL+1))
        fi

        # --- Update themes ---
        THEME_OUT=$(sudo -u "$SITE_USER" "$WP" theme update --all \
            --path="$DOMAIN_DIR" \
            --no-color 2>&1)
        THEME_STATUS=$?

        if [ $THEME_STATUS -eq 0 ]; then
            if echo "$THEME_OUT" | grep -q 'No theme updates available'; then
                echo -e "  ${G}\u2714${X} themes:  up to date"
            else
                TUPDATED=$(echo "$THEME_OUT" | grep -c 'Updated' 2>/dev/null || echo 0)
                echo -e "  ${G}\u2714${X} themes:  ${G}${TUPDATED} updated${X}"
            fi
        else
            echo -e "  ${Y}\u26a0${X}  themes:  FAILED (non-critical)"
        fi

        # --- WordPress core check (no auto-update, just info) ---
        CORE_OUT=$(sudo -u "$SITE_USER" "$WP" core check-update \
            --path="$DOMAIN_DIR" \
            --no-color 2>&1)
        if echo "$CORE_OUT" | grep -q 'WordPress is at the latest version'; then
            echo -e "  ${G}\u2714${X} core:    latest"
        else
            WP_VER=$(echo "$CORE_OUT" | grep -oP '[0-9]+\.[0-9]+\.?[0-9]*' | head -1)
            echo -e "  ${Y}\u26a0${X}  core:    update available ${Y}${WP_VER}${X}"
        fi

        SUMMARY="${SUMMARY}  ${SITE_USER}/${DOMAIN}\n"
        OK=$((OK+1))
        echo
    done
done

# =============================================================================
#  SUMMARY
# =============================================================================

echo -e "$HR"
echo -e "${Y}   SUMMARY${X}"
echo -e "${G}   Total sites processed : ${TOTAL}${X}"
echo -e "${G}   OK                    : ${OK}${X}"
echo -e "${R}   Failed                : ${FAIL}${X}"
echo -e "${C}   Date                  : $(date '+%Y-%m-%d %H:%M')${X}"
echo -e "$HR"
echo -e "${Y}              = Rooted by VladiMIR | AI =${X}"
echo -e "$HR"
echo
