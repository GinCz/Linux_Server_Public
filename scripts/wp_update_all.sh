#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  wp_update_all.sh | [v2026-09-25]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Batch WordPress updater (Core, Plugins, Themes, Translations & WP-Cron)
#               with comprehensive Telegram reporting on every execution (Success & Alerts)
# Servers     : All FastPanel Web Nodes (222-DE / 109-RU)
# Usage       : bash /usr/local/bin/wp_update_all.sh [--install]
# ==========================================================================================

# Support --install argument
if [[ "${1:-}" == "--install" ]]; then
    ALIAS_NAME="wpupd"
    INSTALL_PATH="/usr/local/bin/wp_update_all.sh"

    cp "$0" "$INSTALL_PATH" 2>/dev/null || true
    chmod +x "$INSTALL_PATH"

    if ! grep -q "alias ${ALIAS_NAME}=" /root/.bashrc 2>/dev/null; then
        echo "alias ${ALIAS_NAME}='${INSTALL_PATH}'" >> /root/.bashrc
    fi

    CRON_LINE="0 2 * * 3,6 root ${INSTALL_PATH} >> /var/log/wp_update_all.log 2>&1"
    CRON_FILE="/etc/cron.d/wp_update_all"
    echo "$CRON_LINE" > "$CRON_FILE"
    chmod 644 "$CRON_FILE"
fi

# Ensure cron file is always valid
CRON_FILE="/etc/cron.d/wp_update_all"
if [ ! -f "$CRON_FILE" ]; then
    echo "0 2 * * 3,6 root /usr/local/bin/wp_update_all.sh >> /var/log/wp_update_all.log 2>&1" > "$CRON_FILE"
    chmod 644 "$CRON_FILE"
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
TOTAL_PLUGINS_UPDATED=0
TOTAL_THEMES_UPDATED=0
TOTAL_CORE_UPDATED=0
TOTAL_LANG_UPDATED=0

UPDATED_SITES=()
FAILED_SITES=()

# Telegram integration
TG_CONFIG="/root/.tg_config"
[ -f "$TG_CONFIG" ] && source "$TG_CONFIG"
TG_TOKEN="${TG_TOKEN:-}"
TG_CHAT="${TG_CHAT:-}"

tg() {
    local text="$1"
    [[ -n "$TG_TOKEN" && -n "$TG_CHAT" ]] || return 0

    # 1. Direct Telegram API call
    if curl -fsS -m 8 -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
      -d chat_id="$TG_CHAT" \
      -d parse_mode="HTML" \
      --data-urlencode text="$text" >/dev/null 2>&1; then
        return 0
    fi

    # 2. Fallback bridge via Master Node DE-222 (for Russian nodes where Telegram API is blocked)
    if [ -f "/root/.ssh/id_ed25519" ] || [ -f "/root/.ssh/id_rsa" ]; then
        ssh -o BatchMode=yes -o ConnectTimeout=6 root@152.53.182.222 python3 - <<PY_EOF >/dev/null 2>&1 || true
import urllib.request, urllib.parse
data = urllib.parse.urlencode({
    "chat_id": "$TG_CHAT",
    "parse_mode": "HTML",
    "text": """$text"""
}).encode()
req = urllib.request.Request("https://api.telegram.org/bot$TG_TOKEN/sendMessage", data=data)
urllib.request.urlopen(req, timeout=10)
PY_EOF
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
        SITE_UPD_ITEMS=()

        echo -e "$HR"
        echo -e "${Y}  ▶  ${W}${SITE_USER}${X}  ${G}→  ${Y}${DOMAIN}${X}"
        echo -e "$HR"

        # 1. Translations: WP Core
        LANG_CORE=$(sudo -u "$SITE_USER" "$WP" language core update --path="$DOMAIN_DIR" --no-color 2>&1)
        if echo "$LANG_CORE" | grep -qi 'success\|updated\|already'; then
            UPDATED_LC=$(echo "$LANG_CORE" | grep -i 'updated' | wc -l)
            if [ "$UPDATED_LC" -gt 0 ]; then
                TOTAL_LANG_UPDATED=$((TOTAL_LANG_UPDATED + UPDATED_LC))
                echo -e "  ${G}✔  lang/core    : ${UPDATED_LC} updated${X}"
            else
                echo -e "  ${G}✔  lang/core    : up to date${X}"
            fi
        else
            echo -e "  ${Y}⚠  lang/core    : $(echo "$LANG_CORE" | tail -1)${X}"
        fi

        # 2. Translations: Plugins
        LANG_PLUGIN=$(sudo -u "$SITE_USER" "$WP" language plugin update --all --path="$DOMAIN_DIR" --no-color 2>&1)
        if echo "$LANG_PLUGIN" | grep -qi 'success\|updated\|already'; then
            UPDATED_LP=$(echo "$LANG_PLUGIN" | grep -i 'updated' | wc -l)
            if [ "$UPDATED_LP" -gt 0 ]; then
                TOTAL_LANG_UPDATED=$((TOTAL_LANG_UPDATED + UPDATED_LP))
                echo -e "  ${G}✔  lang/plugins : ${UPDATED_LP} updated${X}"
            else
                echo -e "  ${G}✔  lang/plugins : up to date${X}"
            fi
        else
            echo -e "  ${Y}⚠  lang/plugins : $(echo "$LANG_PLUGIN" | tail -1)${X}"
        fi

        # 3. Translations: Themes
        LANG_THEME=$(sudo -u "$SITE_USER" "$WP" language theme update --all --path="$DOMAIN_DIR" --no-color 2>&1)
        if echo "$LANG_THEME" | grep -qi 'success\|updated\|already'; then
            UPDATED_LT=$(echo "$LANG_THEME" | grep -i 'updated' | wc -l)
            if [ "$UPDATED_LT" -gt 0 ]; then
                TOTAL_LANG_UPDATED=$((TOTAL_LANG_UPDATED + UPDATED_LT))
                echo -e "  ${G}✔  lang/themes  : ${UPDATED_LT} updated${X}"
            else
                echo -e "  ${G}✔  lang/themes  : up to date${X}"
            fi
        else
            echo -e "  ${Y}⚠  lang/themes  : $(echo "$LANG_THEME" | tail -1)${X}"
        fi

        # 4. Plugins
        PLUGIN_OUT=$(sudo -u "$SITE_USER" "$WP" plugin update --all --path="$DOMAIN_DIR" --no-color 2>&1)
        PLUGIN_EXIT=$?
        UPDATED_P=$(echo "$PLUGIN_OUT" | grep 'Updated' | grep -iv 'No plugins updated' | wc -l)

        if [ $PLUGIN_EXIT -eq 0 ] || echo "$PLUGIN_OUT" | grep -qi "No plugins updated\|already at latest version\|version higher than expected\|Success: Plugin already updated"; then
            if [ "$UPDATED_P" -gt 0 ]; then
                TOTAL_PLUGINS_UPDATED=$((TOTAL_PLUGINS_UPDATED + UPDATED_P))
                SITE_UPD_ITEMS+=("🔌 +${UPDATED_P} plugins")
                echo -e "  ${G}✔  plugins      : ${UPDATED_P} updated${X}"
            else
                echo -e "  ${G}✔  plugins      : up to date${X}"
            fi
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
            if [ "$UPDATED_T" -gt 0 ]; then
                TOTAL_THEMES_UPDATED=$((TOTAL_THEMES_UPDATED + UPDATED_T))
                SITE_UPD_ITEMS+=("🎨 +${UPDATED_T} themes")
                echo -e "  ${G}✔  themes       : ${UPDATED_T} updated${X}"
            else
                echo -e "  ${G}✔  themes       : up to date${X}"
            fi
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
                TOTAL_CORE_UPDATED=$((TOTAL_CORE_UPDATED + 1))
                SITE_UPD_ITEMS+=("⚙️ Core ${OLD_VER} → ${NEW_VER}")
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

        # Record site status for summary
        if [ ${#SITE_ERR_ITEMS[@]} -gt 0 ]; then
            COMBINED_ERR=$(IFS=" | "; echo "${SITE_ERR_ITEMS[*]}")
            FAILED_SITES+=("• <b>${DOMAIN}</b>: ${COMBINED_ERR}")
        else
            OK=$((OK+1))
            if [ ${#SITE_UPD_ITEMS[@]} -gt 0 ]; then
                COMBINED_UPD=$(IFS=" | "; echo "${SITE_UPD_ITEMS[*]}")
                UPDATED_SITES+=("• <b>${DOMAIN}</b>: ${COMBINED_UPD}")
            fi
        fi

        echo ""
        sleep 1
    done
done

# Summary CLI
echo -e "$HR"
echo -e "${Y}  SUMMARY${X}"
echo -e "${G}  Total sites : ${TOTAL}${X}"
echo -e "${G}  Success     : ${OK}${X}"
[ "$FAIL" -gt 0 ] && echo -e "  ${R}Failed      : ${FAIL}${X}" || echo -e "  ${G}Failed      : 0${X}"
echo -e "${C}  Plugins upd : ${TOTAL_PLUGINS_UPDATED}${X}"
echo -e "${C}  Core upd    : ${TOTAL_CORE_UPDATED}${X}"
echo -e "${C}  Themes upd  : ${TOTAL_THEMES_UPDATED}${X}"
echo -e "${C}  Finished    : $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "$HR"

# Telegram Report (Always sent after execution)
HOST_NAME=$(hostname)
IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}')
[ -z "$IP_ADDR" ] && IP_ADDR="unknown"
NOW_DATE=$(date '+%Y-%m-%d %H:%M')

if [ "$FAIL" -gt 0 ] && [ ${#FAILED_SITES[@]} -gt 0 ]; then
    TG_TEXT="⚠️ <b>WP Update Report</b> — <b>${HOST_NAME}</b> (${IP_ADDR})
📅 <b>${NOW_DATE}</b>
📊 Сайтов: <b>${TOTAL}</b> | Успешно: <b>${OK}</b> | Ошибок: <b>${FAIL}</b>
🔄 Обновлено: 🔌 Плагинов: <b>${TOTAL_PLUGINS_UPDATED}</b> | ⚙️ WP Core: <b>${TOTAL_CORE_UPDATED}</b> | 🎨 Тем: <b>${TOTAL_THEMES_UPDATED}</b>

❌ <b>Ошибки обновления:</b>
"
    for F_LINE in "${FAILED_SITES[@]}"; do
        TG_TEXT+="${F_LINE}"$'\n'
    done
else
    TG_TEXT="✅ <b>WP Update Complete</b> — <b>${HOST_NAME}</b> (${IP_ADDR})
📅 <b>${NOW_DATE}</b>
📊 Сайтов: <b>${TOTAL}</b> | Успешно: <b>${OK}</b> | Ошибок: <b>0</b>
🔄 Обновлено: 🔌 Плагинов: <b>${TOTAL_PLUGINS_UPDATED}</b> | ⚙️ WP Core: <b>${TOTAL_CORE_UPDATED}</b> | 🎨 Тем: <b>${TOTAL_THEMES_UPDATED}</b>
"
    if [ ${#UPDATED_SITES[@]} -gt 0 ]; then
        TG_TEXT+=$'\n'
        TG_TEXT+="📦 <b>Обновленные сайты:</b>"$'\n'
        LIMIT_COUNT=0
        for U_LINE in "${UPDATED_SITES[@]}"; do
            LIMIT_COUNT=$((LIMIT_COUNT + 1))
            if [ $LIMIT_COUNT -le 25 ]; then
                TG_TEXT+="${U_LINE}"$'\n'
            fi
        done
        if [ $LIMIT_COUNT -gt 25 ]; then
            TG_TEXT+="<i>...и еще $((LIMIT_COUNT - 25)) сайтов</i>"$'\n'
        fi
    else
        TG_TEXT+=$'\n'"✨ Все плагины, темы и ядро WordPress уже актуальны."
    fi
fi

tg "$TG_TEXT"
echo -e "${Y}📨 Telegram summary sent to @My_WWW_bot.${X}"

