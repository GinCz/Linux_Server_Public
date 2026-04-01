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
#  Cron (03:00): 0 3 * * *  bash /root/wp_update_all.sh >> /var/log/wp_update.log 2>&1
#
# =============================================================================
#  = Rooted by VladiMIR | AI =
# =============================================================================

# --- Colors ---
# C = cyan (headers/labels)  G = light green (OK)  Y = light yellow (info/warn)
# R = red (errors)           W = white (domain/user) X = reset
C="\033[1;36m"
G="\033[0;92m"
Y="\033[0;93m"
R="\033[1;31m"
W="\033[1;37m"
X="\033[0m"

# Horizontal rule: cyan === line
HR="${C}================================================================${X}"

WP=/usr/local/bin/wp
OK=0; SKIP=0; FAIL=0; TOTAL=0

echo -e "$HR"
echo -e "${Y}  🔄  WP UPDATE ALL  —  109-RU-FastVDS  —  $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "${G}  Updates: plugins + themes | runs as site owner user${X}"
echo -e "$HR"
echo

# --- Check wp-cli ---
if [ ! -x "$WP" ]; then
    echo -e "${R}\u274c wp-cli not found at $WP${X}"
    echo -e "${Y}Install: curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar${X}"
    echo -e "${Y}         chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp${X}"
    exit 1
fi

# --- Loop all users ---
for USER_DIR in /var/www/*/; do
    SITE_USER=$(basename "$USER_DIR")

    # Skip service/system accounts
    [[ "$SITE_USER" == "fastuser" || "$SITE_USER" == "lost+found" ]] && continue
    id "$SITE_USER" &>/dev/null || continue

    # --- Loop all domains of this user ---
    for DOMAIN_DIR in "${USER_DIR}data/www/"/*/; do
        [ -d "$DOMAIN_DIR" ] || continue
        DOMAIN=$(basename "$DOMAIN_DIR")
        WP_CONFIG="${DOMAIN_DIR}wp-config.php"
        [ -f "$WP_CONFIG" ] || continue

        TOTAL=$((TOTAL+1))
        echo -e "${C}================================================================${X}"
        echo -e "${Y}  ►  ${W}${SITE_USER}${X}  ${G}→  ${Y}${DOMAIN}${X}"
        echo -e "${C}================================================================${X}"

        # --- Plugins ---
        PLUGIN_OUT=$(sudo -u "$SITE_USER" "$WP" plugin update --all \
            --path="$DOMAIN_DIR" --no-color 2>&1)
        PLUGIN_STATUS=$?

        if [ $PLUGIN_STATUS -eq 0 ]; then
            if echo "$PLUGIN_OUT" | grep -q 'No plugin updates available'; then
                echo -e "  ${G}\u2714  plugins : up to date${X}"
            else
                UPDATED=$(echo "$PLUGIN_OUT" | grep -c 'Updated' 2>/dev/null || echo 0)
                echo -e "  ${G}\u2714  plugins : ${UPDATED} updated${X}"
            fi
        else
            echo -e "  ${R}\u274c  plugins : FAILED${X}"
            echo -e "  ${R}$(echo "$PLUGIN_OUT" | tail -3)${X}"
            FAIL=$((FAIL+1))
        fi

        # --- Themes ---
        THEME_OUT=$(sudo -u "$SITE_USER" "$WP" theme update --all \
            --path="$DOMAIN_DIR" --no-color 2>&1)
        THEME_STATUS=$?

        if [ $THEME_STATUS -eq 0 ]; then
            if echo "$THEME_OUT" | grep -q 'No theme updates available'; then
                echo -e "  ${G}\u2714  themes  : up to date${X}"
            else
                TUPDATED=$(echo "$THEME_OUT" | grep -c 'Updated' 2>/dev/null || echo 0)
                echo -e "  ${G}\u2714  themes  : ${TUPDATED} updated${X}"
            fi
        else
            echo -e "  ${Y}\u26a0   themes  : FAILED (non-critical)${X}"
        fi

        # --- WP Core check ---
        CORE_OUT=$(sudo -u "$SITE_USER" "$WP" core check-update \
            --path="$DOMAIN_DIR" --no-color 2>&1)
        if echo "$CORE_OUT" | grep -q 'WordPress is at the latest version'; then
            echo -e "  ${G}\u2714  core    : latest${X}"
        else
            WP_VER=$(echo "$CORE_OUT" | grep -oP '[0-9]+\.[0-9]+\.?[0-9]*' | head -1)
            echo -e "  ${Y}\u26a0   core    : update available ${WP_VER}${X}"
        fi

        OK=$((OK+1))
        echo
    done
done

# =============================================================================
#  SUMMARY
# =============================================================================

echo -e "$HR"
echo -e "${Y}  SUMMARY${X}"
echo -e "${G}  Total sites : ${TOTAL}${X}"
echo -e "${G}  OK          : ${OK}${X}"
echo -e "${R}  Failed      : ${FAIL}${X}"
echo -e "${C}  Finished    : $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "$HR"
echo -e "${Y}              = Rooted by VladiMIR | AI =${X}"
echo -e "$HR"
echo
