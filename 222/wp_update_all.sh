#!/bin/bash

# =============================================================================
#  INSTALL MENU (interactive, skipped if run non-interactively via cron)
# =============================================================================
if [ -t 0 ] && [ -t 1 ]; then
    SELF_URL="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/222/wp_update_all.sh"
    ALIAS_NAME="wpupdate"
    INSTALL_PATH="/usr/local/bin/wp_update_all.sh"

    echo "============================================================"
    echo "  WP Update All — выбери режим запуска:"
    echo "    1) Разовый запуск (не сохраняется, без cron)"
    echo "    2) Установить (алиас '${ALIAS_NAME}' + cron: каждое воскресенье 03:00)"
    echo "============================================================"
    read -rp "Введите 1 или 2 [1]: " CHOICE
    CHOICE=${CHOICE:-1}

    if [ "$CHOICE" = "2" ]; then
        curl -fsSL "$SELF_URL" -o "$INSTALL_PATH"
        chmod +x "$INSTALL_PATH"

        if ! grep -q "alias ${ALIAS_NAME}=" /root/.bashrc 2>/dev/null; then
            echo "alias ${ALIAS_NAME}='${INSTALL_PATH}'" >> /root/.bashrc
        fi

        CRON_LINE="0 3 * * 0 root ${INSTALL_PATH} >> /var/log/wp_update_all.log 2>&1"
        CRON_FILE="/etc/cron.d/wp_update_all"
        echo "$CRON_LINE" > "$CRON_FILE"
        chmod 644 "$CRON_FILE"

        echo "✔ Установлено: $INSTALL_PATH"
        echo "✔ Алиас добавлен в /root/.bashrc: ${ALIAS_NAME} (выполни: source /root/.bashrc)"
        echo "✔ Cron задание создано: $CRON_FILE (каждое воскресенье, 03:00)"
        echo
        echo "Скрипт запустится прямо сейчас (разово):"
        echo
    fi
fi


clear
# =============================================================================
#  wp_update_all.sh
# =============================================================================
#  Version    : v2026.05.21
#  Author     : Ing. VladiMIR Bulantsev
#  GitHub     : https://github.com/GinCz/Linux_Server_Public
#  Server     : 222-EU-NetCup (152.53.182.222)
#  License    : MIT
# =============================================================================
#
#  DESCRIPTION
#  -----------
#  Updates WordPress plugins, themes, translations AND core (engine) for
#  ALL sites on FastPanel. Runs wp-cli as the correct site owner (not root)
#  to avoid permission issues with wp-content/languages/ and wp-content/plugins/.
#  FastPanel structure: /var/www/USER/data/www/DOMAIN/
#
#  CHANGELOG (2026-07-16)
#  -----------------------
#  - Core engine now actually updates via 'wp core update' + 'wp core update-db'
#    (previously it only ran 'wp core check-update' and never updated WP itself)
#  - No DB backup is taken before core update (removed by design, per request)
#  - Added interactive install menu on TTY run:
#      1) One-off run (no install, no cron)
#      2) Install: creates alias 'wpupdate', copies script to
#         /usr/local/bin/wp_update_all.sh, and registers cron job
#         (/etc/cron.d/wp_update_all) running every Sunday at 03:00
#  - Menu is automatically skipped when run non-interactively (e.g. via cron)
#
# =============================================================================
#  ALIAS
# =============================================================================
#  Alias name : wpupd
#  Run script : wpupd
#
# =============================================================================
#  INSTALL ON ANY NEW SERVER (one-liner from GitHub)
# =============================================================================
#
#  1) Download script:
#     curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/222/wp_update_all.sh \
#          -o /root/wp_update_all.sh && chmod +x /root/wp_update_all.sh
#
#  2) Add alias to ~/.bashrc:
#     echo "alias wpupd='bash /root/wp_update_all.sh'" >> ~/.bashrc && source ~/.bashrc
#
#  3) Test run:
#     wpupd
#
#  4) Setup nightly cron (alternative to systemd timer):
#     (crontab -l 2>/dev/null; echo "0 2 * * 3,6 bash /root/wp_update_all.sh >> /var/log/wp_update.log 2>&1") | crontab -
#
#  NOTE: For systemd timer setup see: 222/systemd/wp-update.service + wp-update.timer
#        Timer runs nightly at 02:00 (Wed + Sat), logs to /var/log/wp_update.log
#
# =============================================================================
#  DAEMON (systemd timer)
# =============================================================================
#  Files  : /etc/systemd/system/wp-update.service
#           /etc/systemd/system/wp-update.timer
#  Enable : systemctl daemon-reload
#           systemctl enable --now wp-update.timer
#  Status : systemctl status wp-update.timer
#  Log    : tail -f /var/log/wp_update.log
#
#  Schedule: 02:00 every Wednesday and Saturday (server 222)
#
# =============================================================================
#  = Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =
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
            UPDATED_LC=$(echo "$LANG_CORE" | grep -i 'updated' | wc -l)
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
            UPDATED_LP=$(echo "$LANG_PLUGIN" | grep -i 'updated' | wc -l)
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
            UPDATED_LT=$(echo "$LANG_THEME" | grep -i 'updated' | wc -l)
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
            UPDATED_P=$(echo "$PLUGIN_OUT" | grep 'Updated' | wc -l)
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
            UPDATED_T=$(echo "$THEME_OUT" | grep 'Updated' | wc -l)
            [ "$UPDATED_T" -gt 0 ] \
                && echo -e "  ${G}✔  themes       : ${UPDATED_T} updated${X}" \
                || echo -e "  ${G}✔  themes       : up to date${X}"
        else
            echo -e "  ${Y}⚠   themes       : FAILED (non-critical)${X}"
        fi

        # --- 6. WP Core: actually update the engine (no DB backup) ---
        CORE_CHECK=$(sudo -u "$SITE_USER" "$WP" core check-update \
            --path="$DOMAIN_DIR" --no-color 2>&1)
        if echo "$CORE_CHECK" | grep -q 'WordPress is at the latest version'; then
            echo -e "  ${G}✔  core         : latest${X}"
        else
            OLD_VER=$(sudo -u "$SITE_USER" "$WP" core version --path="$DOMAIN_DIR" --no-color 2>/dev/null)
            echo -e "  ${Y}⚠   core         : update available (current: ${OLD_VER})${X}"
            CORE_UPDATE_OUT=$(sudo -u "$SITE_USER" "$WP" core update \
                --path="$DOMAIN_DIR" --no-color 2>&1)
            CORE_UPDATE_STATUS=$?
            if [ $CORE_UPDATE_STATUS -eq 0 ]; then
                sudo -u "$SITE_USER" "$WP" core update-db --path="$DOMAIN_DIR" --no-color >/dev/null 2>&1
                NEW_VER=$(sudo -u "$SITE_USER" "$WP" core version --path="$DOMAIN_DIR" --no-color 2>/dev/null)
                echo -e "  ${G}✔  core         : updated ${OLD_VER} → ${NEW_VER}${X}"
            else
                echo -e "  ${R}❌  core         : UPDATE FAILED${X}"
                echo -e "  ${R}$(echo "$CORE_UPDATE_OUT" | tail -3)${X}"
                FAIL=$((FAIL+1))
            fi
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
echo -e "${Y}              = Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =${X}"
echo -e "$HR"
echo
