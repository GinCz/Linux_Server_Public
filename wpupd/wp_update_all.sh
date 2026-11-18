#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  wp_update_all.sh | [v2026-11-18]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Batch WordPress updater (Core, Plugins, Translations & WP-Cron)
#               Themes are intentionally excluded (manual update only).
#               Optimized with --skip-themes flag for maximum execution speed.
#               Email reporting to gin.vladimir@gmail.com (Telegram disabled per user preference).
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
TOTAL_CORE_UPDATED=0
TOTAL_LANG_UPDATED=0

UPDATED_SITES=()
FAILED_SITES=()

# Email notification configuration (Telegram disabled per user preference)
EMAIL_TO="${EMAIL_TO:-gin.vladimir@gmail.com}"

send_email_report() {
    local subject="$1"
    local body="$2"

    # 1. Direct Gmail CLI (preferred)
    if [ -x /usr/local/bin/gmail ]; then
        if /usr/local/bin/gmail send --to "$EMAIL_TO" --subject "$subject" --body "$body" >/dev/null 2>&1; then
            return 0
        fi
    fi

    # 2. Fallback bridge via Master Node DE-222 (for remote nodes if local delivery fails)
    if [ -f "/root/.ssh/id_ed25519" ] || [ -f "/root/.ssh/id_rsa" ]; then
        if ssh -o BatchMode=yes -o ConnectTimeout=6 root@152.53.182.222 \
            "/usr/local/bin/gmail send --to '$EMAIL_TO' --subject '$subject' --body '$body'" >/dev/null 2>&1; then
            return 0
        fi
    fi

    # 3. Fallback to local mail binary
    if command -v mail >/dev/null 2>&1; then
        if echo "$body" | mail -s "$subject" "$EMAIL_TO" >/dev/null 2>&1; then
            return 0
        fi
    fi

    return 1
}

echo -e "$HR"
echo -e "${Y}  🔄  WP UPDATE ALL  —  $(hostname)  —  $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "${G}  Updates: translations + plugins + core (themes excluded) | runs as site owner${X}"
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
    [ -d "$USER_DIR" ] || continue
    SITE_USER=$(basename "$USER_DIR")

    # Skip system accounts
    [[ "$SITE_USER" == "fastuser" || "$SITE_USER" == "lost+found" ]] && continue
    id "$SITE_USER" &>/dev/null || continue

    DATA_DIR="${USER_DIR}data/www"
    [ -d "$DATA_DIR" ] || continue

    # Iterate through all domain directories of this user
    for DOMAIN_DIR in "$DATA_DIR"/*/; do
        [ -d "$DOMAIN_DIR" ] || continue

        # Verify it's a WordPress installation
        [ -f "${DOMAIN_DIR}wp-config.php" ] || continue

        DOMAIN=$(basename "$DOMAIN_DIR")
        TOTAL=$((TOTAL+1))
        SITE_UPD_ITEMS=()
        SITE_ERR_ITEMS=()

        echo -e "${C}▶ [${TOTAL}] Site: ${W}${DOMAIN}${C} (Owner: ${SITE_USER})${X}"

        # 1. Translations: Core
        LANG_CORE=$(sudo -u "$SITE_USER" "$WP" language core update --path="$DOMAIN_DIR" --skip-themes --no-color 2>&1)
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
        LANG_PLUGIN=$(sudo -u "$SITE_USER" "$WP" language plugin update --all --path="$DOMAIN_DIR" --skip-themes --no-color 2>&1)
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

        # 3. Plugins
        PLUGIN_OUT=$(sudo -u "$SITE_USER" "$WP" plugin update --all --path="$DOMAIN_DIR" --skip-themes --no-color 2>&1)
        if [ $? -eq 0 ]; then
            UPDATED_P=$(echo "$PLUGIN_OUT" | grep 'Updated' | wc -l)
            if [ "$UPDATED_P" -gt 0 ]; then
                TOTAL_PLUGINS_UPDATED=$((TOTAL_PLUGINS_UPDATED + UPDATED_P))
                SITE_UPD_ITEMS+=("🔌 +${UPDATED_P} plugins")
                echo -e "  ${G}✔  plugins      : ${UPDATED_P} updated${X}"
            else
                echo -e "  ${G}✔  plugins      : up to date${X}"
            fi
        else
            echo -e "  ${R}❌  plugins      : UPDATE FAILED${X}"
            FAIL=$((FAIL+1))
            ERR_MSG=$(echo "$PLUGIN_OUT" | grep -iE 'Error:|Warning:|failed' | head -1 | sed -E 's/^[[:space:]]*//; s/Error: //;')
            [ -z "$ERR_MSG" ] && ERR_MSG="plugin update failed"
            SITE_ERR_ITEMS+=("🔌 ${ERR_MSG}")
        fi

        # 4. WP Core Engine
        CORE_CHECK=$(sudo -u "$SITE_USER" "$WP" core check-update --path="$DOMAIN_DIR" --skip-themes --no-color 2>&1)
        if echo "$CORE_CHECK" | grep -q 'Success: WordPress is at the latest version.'; then
            echo -e "  ${G}✔  core         : up to date${X}"
        else
            OLD_VER=$(echo "$CORE_CHECK" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
            [ -z "$OLD_VER" ] && OLD_VER=$(sudo -u "$SITE_USER" "$WP" core version --path="$DOMAIN_DIR" --no-color 2>/dev/null)
            echo -e "  ${Y}⬆  core         : updating from ${OLD_VER}...${X}"
            CORE_UPDATE_OUT=$(sudo -u "$SITE_USER" "$WP" core update --path="$DOMAIN_DIR" --skip-themes --no-color 2>&1)
            if [ $? -eq 0 ]; then
                sudo -u "$SITE_USER" "$WP" core update-db --path="$DOMAIN_DIR" --skip-themes --no-color >/dev/null 2>&1
                NEW_VER=$(echo "$CORE_UPDATE_OUT" | grep -oE 'updated to version [0-9]+\.[0-9]+(\.[0-9]+)?' | awk '{print $NF}')
                [ -z "$NEW_VER" ] && NEW_VER=$(sudo -u "$SITE_USER" "$WP" core version --path="$DOMAIN_DIR" --no-color 2>/dev/null)
                TOTAL_CORE_UPDATED=$((TOTAL_CORE_UPDATED+1))
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

        # 5. Run scheduled due WP-Crons
        timeout 30s sudo -u "$SITE_USER" "$WP" cron event run --due-now --path="$DOMAIN_DIR" --skip-themes --no-color >/dev/null 2>&1 || true

        # Record site status for summary
        if [ ${#SITE_ERR_ITEMS[@]} -gt 0 ]; then
            COMBINED_ERR=$(IFS=" | "; echo "${SITE_ERR_ITEMS[*]}")
            FAILED_SITES+=("• ${DOMAIN}: ${COMBINED_ERR}")
        else
            OK=$((OK+1))
            if [ ${#SITE_UPD_ITEMS[@]} -gt 0 ]; then
                COMBINED_UPD=$(IFS=" | "; echo "${SITE_UPD_ITEMS[*]}")
                UPDATED_SITES+=("• ${DOMAIN}: ${COMBINED_UPD}")
            fi
        fi

        echo ""
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
echo -e "${C}  Lang upd    : ${TOTAL_LANG_UPDATED}${X}"
echo -e "${C}  Finished    : $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "$HR"

# Email Report (Always sent after execution to gin.vladimir@gmail.com; Telegram disabled per user preference)
HOST_NAME=$(hostname)
IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}')
[ -z "$IP_ADDR" ] && IP_ADDR="unknown"
NOW_DATE=$(date '+%Y-%m-%d %H:%M')

if [ "$FAIL" -gt 0 ] && [ ${#FAILED_SITES[@]} -gt 0 ]; then
    EMAIL_SUBJECT="⚠️ WP Update Report — ${HOST_NAME} (${IP_ADDR})"
    EMAIL_BODY="⚠️ WP Update Report — ${HOST_NAME} (${IP_ADDR})
📅 ${NOW_DATE}
📊 Сайтов: ${TOTAL} | Успешно: ${OK} | Ошибок: ${FAIL}
🔄 Обновлено: 🔌 Плагинов: ${TOTAL_PLUGINS_UPDATED} | ⚙️ WP Core: ${TOTAL_CORE_UPDATED}

❌ Ошибки обновления:
"
    for F_LINE in "${FAILED_SITES[@]}"; do
        CLEAN_LINE=$(echo "$F_LINE" | sed -r 's/<[^>]*>//g')
        EMAIL_BODY+="${CLEAN_LINE}"$'\n'
    done
else
    EMAIL_SUBJECT="✅ WP Update Complete — ${HOST_NAME} (${IP_ADDR})"
    EMAIL_BODY="✅ WP Update Complete — ${HOST_NAME} (${IP_ADDR})
📅 ${NOW_DATE}
📊 Сайтов: ${TOTAL} | Успешно: ${OK} | Ошибок: 0
🔄 Обновлено: 🔌 Плагинов: ${TOTAL_PLUGINS_UPDATED} | ⚙️ WP Core: ${TOTAL_CORE_UPDATED}"
fi

if send_email_report "$EMAIL_SUBJECT" "$EMAIL_BODY"; then
    echo -e "${G}📧 Email summary sent to ${EMAIL_TO}.${X}"
else
    echo -e "${R}❌ Failed to send email summary to ${EMAIL_TO}.${X}"
fi
