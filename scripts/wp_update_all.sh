#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  wp_update_all.sh | [v2026-08-28]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Batch WordPress updater (Core, Plugins, Themes, Translations & WP-Cron)
#               with Telegram Alerting on failures (1 line per site with plugin/reason)
# Servers     : All FastPanel Web Nodes (222-DE / 109-RU)
# Usage       : bash scripts/wp_update_all.sh
# ==========================================================================================

# Interactive mode menu (skipped in cron)
if [ -t 0 ] && [ -t 1 ]; then
    ALIAS_NAME="wpupd"
    INSTALL_PATH="/usr/local/bin/wp_update_all.sh"

    echo "============================================================"
    echo "  WP Update All — Select Execution Mode:"
    echo "    1) One-off run (execute now without cron installation)"
    echo "    2) Install (alias '${ALIAS_NAME}' + Cron: Wed & Sat 02:00)"
    echo "============================================================"
    read -rp "Enter choice [1]: " CHOICE
    CHOICE=${CHOICE:-1}

    if [ "$CHOICE" = "2" ]; then
        cp "$0" "$INSTALL_PATH" 2>/dev/null || curl -fsSL "https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/wp_update_all.sh" -o "$INSTALL_PATH"
        chmod +x "$INSTALL_PATH"

        if ! grep -q "alias ${ALIAS_NAME}=" /root/.bashrc 2>/dev/null; then
            echo "alias ${ALIAS_NAME}='${INSTALL_PATH}'" >> /root/.bashrc
        fi

        CRON_LINE="0 2 * * 3,6 root ${INSTALL_PATH} >> /var/log/wp_update_all.log 2>&1"
        CRON_FILE="/etc/cron.d/wp_update_all"
        echo "$CRON_LINE" > "$CRON_FILE"
        chmod 644 "$CRON_FILE"

        echo "✔ Installed to: $INSTALL_PATH"
        echo "✔ Alias added to /root/.bashrc: ${ALIAS_NAME}"
        echo "✔ Cron scheduled: $CRON_FILE (Wed & Sat 02:00)"
        echo ""
        echo "Starting update process now..."
        echo ""
    fi
fi

# Colors
C='\033[1;36m'   # cyan
G='\033[0;92m'   # green
Y='\033[0;93m'   # yellow
R='\033[1;31m'   # red
W='\033[1;37m'   # white
X='\033[0m'      # reset

HR="${C}================================================================${X}"
WP=/usr/local/bin/wp
OK=0; FAIL=0; TOTAL=0
FAILED_SITES=()

# Telegram integration
TG_CONFIG="/root/.tg_config"
[ -f "$TG_CONFIG" ] && source "$TG_CONFIG"
TG_TOKEN="${TG_TOKEN:-1226649515:AAEVdcIptwV2n6z2hkMVB3i9sDnnt1laKN0}"
TG_CHAT="${TG_CHAT:-261784949}"

tg() {
    local text="$1"
    [[ -n "$TG_TOKEN" && -n "$TG_CHAT" ]] || return 0
    if ! curl -fsS -m 5 -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
      -d chat_id="$TG_CHAT" \
      -d parse_mode="HTML" \
      --data-urlencode text="$text" >/dev/null 2>&1; then
        curl -fsS -m 10 -X POST "http://152.53.182.222:8899/bot${TG_TOKEN}/sendMessage" \
          -d chat_id="$TG_CHAT" \
          -d parse_mode="HTML" \
          --data-urlencode text="$text" >/dev/null 2>&1 || true
    fi
}

echo -e "$HR"
echo -e "${Y}  🔄  WP UPDATE ALL  —  $(hostname)  —  $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "${G}  Updates: translations + plugins + themes + core | runs as site owner${X}"
echo -e "$HR"
echo ""

# Check wp-cli
if [ ! -x "$WP" ]; then
    echo -e "${R}❌ wp-cli not found at $WP. Installing...${X}"
    curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp
fi

# Iterate through all FastPanel users
for USER_DIR in /var/www/*/; do
    SITE_USER=$(basename "$USER_DIR")

    # Skip system accounts
    [[ "$SITE_USER" == "fastuser" || "$SITE_USER" == "lost+found" ]] && continue
    id "$SITE_USER" &>/dev/null || continue

    # Iterate through all domains of user
    for DOMAIN_DIR in "${USER_DIR}data/www/"/*/; do
        [ -d "$DOMAIN_DIR" ] || continue
        DOMAIN=$(basename "$DOMAIN_DIR")
        WP_CONFIG="${DOMAIN_DIR}wp-config.php"
        [ -f "$WP_CONFIG" ] || continue

        TOTAL=$((TOTAL+1))
        SITE_ERR_ITEMS=()

        echo -e "$HR"
        echo -e "${Y}  ▶  ${W}${SITE_USER}${X}  ${G}→  ${Y}${DOMAIN}${X}"
        echo -e "$HR"

        # 1. Translations: WP Core
        LANG_CORE=$(sudo -u "$SITE_USER" "$WP" language core update --path="$DOMAIN_DIR" --no-color 2>&1)
        if echo "$LANG_CORE" | grep -qi 'success\|updated\|already'; then
            UPDATED_LC=$(echo "$LANG_CORE" | grep -i 'updated' | wc -l)
            [ "$UPDATED_LC" -gt 0 ] && echo -e "  ${G}✔  lang/core    : ${UPDATED_LC} updated${X}" || echo -e "  ${G}✔  lang/core    : up to date${X}"
        else
            echo -e "  ${Y}⚠  lang/core    : $(echo "$LANG_CORE" | tail -1)${X}"
        fi

        # 2. Translations: Plugins
        LANG_PLUGIN=$(sudo -u "$SITE_USER" "$WP" language plugin update --all --path="$DOMAIN_DIR" --no-color 2>&1)
        if echo "$LANG_PLUGIN" | grep -qi 'success\|updated\|already'; then
            UPDATED_LP=$(echo "$LANG_PLUGIN" | grep -i 'updated' | wc -l)
            [ "$UPDATED_LP" -gt 0 ] && echo -e "  ${G}✔  lang/plugins : ${UPDATED_LP} updated${X}" || echo -e "  ${G}✔  lang/plugins : up to date${X}"
        else
            echo -e "  ${Y}⚠  lang/plugins : $(echo "$LANG_PLUGIN" | tail -1)${X}"
        fi

        # 3. Translations: Themes
        LANG_THEME=$(sudo -u "$SITE_USER" "$WP" language theme update --all --path="$DOMAIN_DIR" --no-color 2>&1)
        if echo "$LANG_THEME" | grep -qi 'success\|updated\|already'; then
            UPDATED_LT=$(echo "$LANG_THEME" | grep -i 'updated' | wc -l)
            [ "$UPDATED_LT" -gt 0 ] && echo -e "  ${G}✔  lang/themes  : ${UPDATED_LT} updated${X}" || echo -e "  ${G}✔  lang/themes  : up to date${X}"
        else
            echo -e "  ${Y}⚠  lang/themes  : $(echo "$LANG_THEME" | tail -1)${X}"
        fi

        # 4. Plugins
        PLUGIN_OUT=$(sudo -u "$SITE_USER" "$WP" plugin update --all --path="$DOMAIN_DIR" --no-color 2>&1)
        if [ $? -eq 0 ]; then
            UPDATED_P=$(echo "$PLUGIN_OUT" | grep 'Updated' | wc -l)
            [ "$UPDATED_P" -gt 0 ] && echo -e "  ${G}✔  plugins      : ${UPDATED_P} updated${X}" || echo -e "  ${G}✔  plugins      : up to date${X}"
        else
            echo -e "  ${R}❌  plugins      : FAILED${X}"
            FAIL=$((FAIL+1))
            FAIL_MSG=$(echo "$PLUGIN_OUT" | grep -iE 'Warning:|Error:|failed' | grep -iv 'No plugins updated' | sed -E 's/^[[:space:]]*//; s/Warning: //; s/Error: //;' | head -2 | tr '\n' '; ' | sed 's/; $//')
            [ -z "$FAIL_MSG" ] && FAIL_MSG="plugin update failed"
            SITE_ERR_ITEMS+=("🔌 ${FAIL_MSG}")
        fi

        # 5. Themes
        THEME_OUT=$(sudo -u "$SITE_USER" "$WP" theme update --all --path="$DOMAIN_DIR" --no-color 2>&1)
        if [ $? -eq 0 ]; then
            UPDATED_T=$(echo "$THEME_OUT" | grep 'Updated' | wc -l)
            [ "$UPDATED_T" -gt 0 ] && echo -e "  ${G}✔  themes       : ${UPDATED_T} updated${X}" || echo -e "  ${G}✔  themes       : up to date${X}"
        else
            echo -e "  ${Y}⚠  themes       : FAILED (non-critical)${X}"
        fi

        # 6. WP Core Engine
        CORE_CHECK=$(sudo -u "$SITE_USER" "$WP" core check-update --path="$DOMAIN_DIR" --no-color 2>&1)
        if echo "$CORE_CHECK" | grep -q 'WordPress is at the latest version'; then
            echo -e "  ${G}✔  core         : latest${X}"
        else
            OLD_VER=$(sudo -u "$SITE_USER" "$WP" core version --path="$DOMAIN_DIR" --no-color 2>/dev/null)
            echo -e "  ${Y}⚠  core         : update available (current: ${OLD_VER})${X}"
            CORE_UPDATE_OUT=$(sudo -u "$SITE_USER" "$WP" core update --path="$DOMAIN_DIR" --no-color 2>&1)
            if [ $? -eq 0 ]; then
                sudo -u "$SITE_USER" "$WP" core update-db --path="$DOMAIN_DIR" --no-color >/dev/null 2>&1
                NEW_VER=$(sudo -u "$SITE_USER" "$WP" core version --path="$DOMAIN_DIR" --no-color 2>/dev/null)
                echo -e "  ${G}✔  core         : updated ${OLD_VER} → ${NEW_VER}${X}"
            else
                echo -e "  ${R}❌  core         : UPDATE FAILED${X}"
                FAIL=$((FAIL+1))
                CORE_ERR=$(echo "$CORE_UPDATE_OUT" | grep -iE 'Error:|Warning:|failed' | head -1 | sed -E 's/^[[:space:]]*//; s/Error: //;')
                [ -z "$CORE_ERR" ] && CORE_ERR="core update failed"
                SITE_ERR_ITEMS+=("⚙️ ${CORE_ERR}")
            fi
        fi

        # 7. Run scheduled due WP-Crons
        sudo -u "$SITE_USER" "$WP" cron event run --due-now --path="$DOMAIN_DIR" --no-color >/dev/null 2>&1 || true

        # Track failed sites for single-line Telegram output
        if [ ${#SITE_ERR_ITEMS[@]} -gt 0 ]; then
            COMBINED_ERR=$(IFS=" | "; echo "${SITE_ERR_ITEMS[*]}")
            FAILED_SITES+=("• <b>${DOMAIN}</b>: ${COMBINED_ERR}")
        else
            OK=$((OK+1))
        fi

        echo ""

        # Gentle pause between sites to reduce CPU & disk IO spikes
        sleep 2
    done
done

# Summary
echo -e "$HR"
echo -e "${Y}  SUMMARY${X}"
echo -e "${G}  Total sites : ${TOTAL}${X}"
echo -e "${G}  Success     : ${OK}${X}"
[ "$FAIL" -gt 0 ] && echo -e "  ${R}Failed      : ${FAIL}${X}" || echo -e "  ${G}Failed      : 0${X}"
echo -e "${C}  Finished    : $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "$HR"

# Telegram Alert on Failures (1 line per site: domain, plugin/error, reason)
if [ "$FAIL" -gt 0 ] && [ ${#FAILED_SITES[@]} -gt 0 ]; then
    HOST_NAME=$(hostname)
    IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}')
    [ -z "$IP_ADDR" ] && IP_ADDR="unknown"
    NOW_DATE=$(date '+%Y-%m-%d %H:%M')

    TG_TEXT="⚠️ <b>WP Update Alert</b> — <b>${HOST_NAME}</b> (${IP_ADDR})
📅 ${NOW_DATE} | Ошибок: ${FAIL} (всего сайтов: ${TOTAL})

"
    for F_LINE in "${FAILED_SITES[@]}"; do
        TG_TEXT+="${F_LINE}"$'\n'
    done

    tg "$TG_TEXT"
    echo -e "${Y}📨 Telegram alert sent (${#FAILED_SITES[@]} sites with errors).${X}"
fi

# = Rooted by VladiMIR | AI = v2026-08-28 = github.com/GinCz/Linux_Server_Public
