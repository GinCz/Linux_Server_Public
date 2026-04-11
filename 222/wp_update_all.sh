#!/bin/bash
clear
# =============================================================================
#  wp_update_all.sh
# =============================================================================
#  Version    : v2026-04-12
#  Author     : Ing. VladiMIR Bulantsev
#  GitHub     : https://github.com/GinCz/Linux_Server_Public
#  Server     : 109-RU-FastVDS (xxx.xxx.xxx.109)
#               222-DE-NetCup  (xxx.xxx.xxx.222)
#  License    : MIT
# =============================================================================
#
#  DESCRIPTION
#  -----------
#  Updates WordPress plugins, themes, translations and core for ALL sites
#  on FastPanel. Runs wp-cli as the correct site owner (not root) to avoid
#  permission issues with wp-content/languages/ and wp-content/plugins/.
#  FastPanel structure: /var/www/USER/data/www/DOMAIN/
#
#  USAGE
#  -----
#  Manual run : bash /root/wp_update_all.sh
#  Alias      : wpupd
#  Cron 222   : 0 2 * * 3,6  bash /root/wp_update_all.sh >> /var/log/wp_update.log 2>&1
#  Cron 109   : 0 2 * * 3,6  bash /root/wp_update_all.sh >> /var/log/wp_update.log 2>&1
#
#  WHAT IT DOES (per site, runs as site owner via sudo -u):
#  1. language core update    — WP core translations
#  2. language plugin update  — all plugin translations
#  3. language theme update   — all theme translations
#  4. plugin update --all     — all plugins
#  5. theme update --all      — all themes
#  6. core check-update       — check if WP core update available (info only)
#
# =============================================================================
#  = Rooted by VladiMIR | AI =
# =============================================================================

# --- Colors ---
C='\033[1;36m'   # cyan
G='\033[0;92m'   # light green
Y='\033[0;93m'   # light yellow
R='\033[1;31m'   # red
W='\033[1;37m'   # white
X='\033[0m'      # reset

HR="${C}================================================================${X}"

WP=/usr/local/bin/wp
OK=0; FAIL=0; TOTAL=0

echo -e "$HR"
echo -e "${Y}  🔄  WP UPDATE ALL  —  $(hostname)  —  $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "${G}  Updates: translations + plugins + themes | runs as site owner${X}"
echo -e "$HR"
echo

# --- Check wp-cli ---
if [ ! -x "$WP" ]; then
    echo -e "${R}❌ wp-cli not found at $WP${X}"
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
        echo -e "$HR"
        echo -e "${Y}  ▶  ${W}${SITE_USER}${X}  ${G}→  ${Y}${DOMAIN}${X}"
        echo -e "$HR"

        # --- 1. Translations: WP core ---
        LANG_CORE=$(sudo -u "$SITE_USER" "$WP" language core update \
            --path="$DOMAIN_DIR" --no-color 2>&1)
        if echo "$LANG_CORE" | grep -qi 'success\|updated\|already'; then
            UPDATED_LC=$(echo "$LANG_CORE" | grep -ci 'updated' || echo 0)
            [ "$UPDATED_LC" -gt 0 ] \
                && echo -e "  ${G}✔  lang/core    : ${UPDATED_LC} updated${X}" \
                || echo -e "  ${G}✔  lang/core    : up to date${X}"
        else
            echo -e "  ${Y}⚠   lang/core    : $(echo "$LANG_CORE" | tail -1)${X}"
        fi

        # --- 2. Translations: plugins ---
        LANG_PLUGIN=$(sudo -u "$SITE_USER" "$WP" language plugin update --all \
            --path="$DOMAIN_DIR" --no-color 2>&1)
        if echo "$LANG_PLUGIN" | grep -qi 'success\|updated\|already'; then
            UPDATED_LP=$(echo "$LANG_PLUGIN" | grep -ci 'updated' || echo 0)
            [ "$UPDATED_LP" -gt 0 ] \
                && echo -e "  ${G}✔  lang/plugins : ${UPDATED_LP} updated${X}" \
                || echo -e "  ${G}✔  lang/plugins : up to date${X}"
        else
            echo -e "  ${Y}⚠   lang/plugins : $(echo "$LANG_PLUGIN" | tail -1)${X}"
        fi

        # --- 3. Translations: themes ---
        LANG_THEME=$(sudo -u "$SITE_USER" "$WP" language theme update --all \
            --path="$DOMAIN_DIR" --no-color 2>&1)
        if echo "$LANG_THEME" | grep -qi 'success\|updated\|already'; then
            UPDATED_LT=$(echo "$LANG_THEME" | grep -ci 'updated' || echo 0)
            [ "$UPDATED_LT" -gt 0 ] \
                && echo -e "  ${G}✔  lang/themes  : ${UPDATED_LT} updated${X}" \
                || echo -e "  ${G}✔  lang/themes  : up to date${X}"
        else
            echo -e "  ${Y}⚠   lang/themes  : $(echo "$LANG_THEME" | tail -1)${X}"
        fi

        # --- 4. Plugins ---
        PLUGIN_OUT=$(sudo -u "$SITE_USER" "$WP" plugin update --all \
            --path="$DOMAIN_DIR" --no-color 2>&1)
        PLUGIN_STATUS=$?
        if [ $PLUGIN_STATUS -eq 0 ]; then
            UPDATED_P=$(echo "$PLUGIN_OUT" | grep -c 'Updated' || echo 0)
            [ "$UPDATED_P" -gt 0 ] \
                && echo -e "  ${G}✔  plugins      : ${UPDATED_P} updated${X}" \
                || echo -e "  ${G}✔  plugins      : up to date${X}"
        else
            echo -e "  ${R}❌  plugins      : FAILED${X}"
            echo -e "  ${R}$(echo "$PLUGIN_OUT" | tail -3)${X}"
            FAIL=$((FAIL+1))
        fi

        # --- 5. Themes ---
        THEME_OUT=$(sudo -u "$SITE_USER" "$WP" theme update --all \
            --path="$DOMAIN_DIR" --no-color 2>&1)
        THEME_STATUS=$?
        if [ $THEME_STATUS -eq 0 ]; then
            UPDATED_T=$(echo "$THEME_OUT" | grep -c 'Updated' || echo 0)
            [ "$UPDATED_T" -gt 0 ] \
                && echo -e "  ${G}✔  themes       : ${UPDATED_T} updated${X}" \
                || echo -e "  ${G}✔  themes       : up to date${X}"
        else
            echo -e "  ${Y}⚠   themes       : FAILED (non-critical)${X}"
        fi

        # --- 6. WP Core check (info only, no auto-update) ---
        CORE_OUT=$(sudo -u "$SITE_USER" "$WP" core check-update \
            --path="$DOMAIN_DIR" --no-color 2>&1)
        if echo "$CORE_OUT" | grep -q 'WordPress is at the latest version'; then
            echo -e "  ${G}✔  core         : latest${X}"
        else
            WP_VER=$(echo "$CORE_OUT" | grep -oP '[0-9]+\.[0-9]+\.?[0-9]*' | head -1)
            echo -e "  ${Y}⚠   core         : update available → ${WP_VER}${X}"
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
[ "$FAIL" -gt 0 ] \
    && echo -e "  ${R}Failed      : ${FAIL}${X}" \
    || echo -e "  ${G}Failed      : 0${X}"
echo -e "${C}  Finished    : $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "$HR"
echo -e "${Y}              = Rooted by VladiMIR | AI =${X}"
echo -e "$HR"
echo
