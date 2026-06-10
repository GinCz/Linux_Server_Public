#!/usr/bin/env bash
# =============================================================
# Script:      upd.sh
# Version:     v2026.06.10f
# Alias:       upd
# Location:    scripts/upd.sh
# Server:      ALL servers (VPN nodes, 222, 109, ...)
# Description: Full system update: apt upgrade, autoremove,
#              clean apt cache, clear old logs, clear tmp.
#              Menu: Run (update now) or Install (alias +/- cron).
# Usage:       upd   (via alias)
#              bash /root/Linux_Server_Public/scripts/upd.sh
#              bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/upd.sh)
# = Rooted by VladiMIR + AI | v.2026.06.10f | github.com/GinCz =
# =============================================================
export DEBIAN_FRONTEND=noninteractive

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; RED='\033[1;31m'; BOLD='\033[1m'; NC='\033[0m'

NIGHT_SCRIPT="/root/night_update.sh"
NIGHT_URL="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/night_update.sh"
CRON_JOB='0 2 * * * apt-get update -qq && apt-get upgrade -y -qq -o Dpkg::Options::="--force-confold" && apt-get autoremove -y -qq && apt-get autoclean -qq && journalctl --vacuum-time=7d >> /var/log/auto-upgrade.log 2>&1 && /sbin/reboot'

# =============================================================
# FUNCTIONS
# =============================================================

do_update() {
    clear
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${CYAN}  UPD \u2014 System Update & Cleanup           ${NC}"
    echo -e "${CYAN}  $(hostname) | $(date '+%Y-%m-%d %H:%M')   ${NC}"
    echo -e "${CYAN}==========================================${NC}"
    echo ""

    echo -e "${YELLOW}[1/6] apt update...${NC}"
    apt-get update -q 2>&1 | tail -3
    echo -e "${GREEN}Done.${NC}"

    echo -e "${YELLOW}[2/6] apt upgrade...${NC}"
    apt-get upgrade -y -q \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
        2>&1 | tail -5
    echo -e "${GREEN}Done.${NC}"

    echo -e "${YELLOW}[3/6] autoremove + autoclean...${NC}"
    apt-get autoremove -y -q 2>&1 | tail -3
    apt-get autoclean -y -q 2>&1 | tail -3
    apt-get clean -q
    echo -e "${GREEN}Done.${NC}"

    echo -e "${YELLOW}[4/6] Clearing old journal logs (keep 7d)...${NC}"
    journalctl --vacuum-time=7d 2>&1 | tail -3
    echo -e "${GREEN}Done.${NC}"

    echo -e "${YELLOW}[5/6] Clearing /tmp...${NC}"
    find /tmp -mindepth 1 -mtime +1 -delete 2>/dev/null
    find /var/tmp -mindepth 1 -mtime +7 -delete 2>/dev/null
    echo -e "${GREEN}Done.${NC}"

    echo -e "${YELLOW}[6/6] Disk usage after cleanup:${NC}"
    df -h / | awk 'NR==2{printf "  /  Size:%-6s  Used:%-6s  Free:%-6s  (%s)\n",$2,$3,$4,$5}'

    echo ""
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}  Update & cleanup complete!              ${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo ""
}

do_install_alias() {
    local SCRIPT_PATH="/root/Linux_Server_Public/scripts/upd.sh"
    local BASHRC="/root/.bashrc"
    if grep -q "alias upd=" "$BASHRC" 2>/dev/null; then
        echo -e "${GREEN}  \u2713 Alias 'upd' already exists in $BASHRC${NC}"
    else
        echo "alias upd='bash $SCRIPT_PATH'" >> "$BASHRC"
        echo -e "${GREEN}  \u2713 Alias 'upd' added to $BASHRC${NC}"
    fi
    source "$BASHRC" 2>/dev/null || true
}

do_deploy_night_update() {
    echo -e "${YELLOW}  Deploying night_update.sh...${NC}"
    curl -sL "$NIGHT_URL" -o "$NIGHT_SCRIPT"
    chmod +x "$NIGHT_SCRIPT"
    echo -e "${GREEN}  \u2713 night_update.sh deployed to $NIGHT_SCRIPT${NC}"

    local REBOOT_JOB="@reboot sleep 30 && bash $NIGHT_SCRIPT --audit >> /var/log/night_update.log 2>&1"
    if crontab -l 2>/dev/null | grep -q 'night_update.*--audit'; then
        echo -e "${GREEN}  \u2713 @reboot audit cron already configured.${NC}"
    else
        (crontab -l 2>/dev/null | grep -v 'night_update'; echo "$REBOOT_JOB") | crontab -
        echo -e "${GREEN}  \u2713 @reboot cron added: post-boot audit.${NC}"
    fi
}

do_install_cron() {
    local CURRENT_TZ
    CURRENT_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null)
    if [[ "$CURRENT_TZ" != "Europe/Prague" ]]; then
        timedatectl set-timezone Europe/Prague 2>/dev/null && \
            echo -e "${GREEN}  \u2713 Timezone set to Europe/Prague.${NC}"
    else
        echo -e "${GREEN}  \u2713 Timezone already Europe/Prague.${NC}"
    fi
    if crontab -l 2>/dev/null | grep -q 'auto-upgrade'; then
        echo -e "${GREEN}  \u2713 Cron auto-update at 02:00 already configured.${NC}"
    else
        (crontab -l 2>/dev/null | grep -v 'auto-upgrade\|apt.*update\|apt.*upgrade'; echo "$CRON_JOB") | crontab -
        echo -e "${GREEN}  \u2713 Cron added: daily update + cleanup + reboot at 02:00 (Prague).${NC}"
        echo -e "${CYAN}  Log: /var/log/auto-upgrade.log${NC}"
    fi
}

show_crontab() {
    echo -e "${CYAN}${BOLD}  \u23f0 Active cron jobs:${NC}"
    echo -e "${CYAN}  ----------------------------------------${NC}"
    local HAS_JOBS=0
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        HAS_JOBS=1
        local SCHEDULE COMMAND LABEL
        if [[ "$line" == @reboot* ]]; then
            COMMAND=$(echo "$line" | sed 's/@reboot //')
            LABEL=$(echo "$COMMAND" | grep -oP '(night_update|telegram_alert|iptables|ipset|[a-zA-Z0-9_/.-]+\.sh)' | head -1)
            [[ -z "$LABEL" ]] && LABEL="$COMMAND"
            echo -e "  ${YELLOW}@reboot${NC}    \u2192 ${LABEL}"
        else
            local M H DOM MON DOW
            read -r M H DOM MON DOW COMMAND <<< "$line"
            if [[ "$M" == "*/"* ]]; then
                SCHEDULE="every ${M#*/} min"
            elif [[ "$H" == "*" ]]; then
                SCHEDULE="daily at ${H}:$(printf '%02d' $M)"
            else
                SCHEDULE=$(printf "%02d:%02d" "$H" "$M")
            fi
            LABEL=$(echo "$COMMAND" | grep -oP '(night_update|telegram_alert|auto-upgrade|[a-zA-Z0-9_/.-]+\.sh|apt-get [a-z]+)' | head -1)
            [[ -z "$LABEL" ]] && LABEL=$(echo "$COMMAND" | cut -c1-60)
            echo -e "  ${YELLOW}${SCHEDULE}${NC}   \u2192 ${LABEL}"
        fi
    done < <(crontab -l 2>/dev/null)
    [[ $HAS_JOBS -eq 0 ]] && echo -e "  ${RED}  (no cron jobs found)${NC}"
    echo -e "${CYAN}  ----------------------------------------${NC}"
}

# =============================================================
# MAIN MENU
# =============================================================

clear
echo -e "${CYAN}${BOLD}==========================================${NC}"
echo -e "${CYAN}${BOLD}  UPD \u2014 System Update & Cleanup           ${NC}"
echo -e "${CYAN}  $(hostname) | $(date '+%Y-%m-%d %H:%M')   ${NC}"
echo -e "${CYAN}${BOLD}==========================================${NC}"
echo ""
echo -e "  ${BOLD}What do you want to do?${NC}"
echo ""
echo -e "  ${CYAN}1${NC}) ${BOLD}Run${NC}     \u2014 update + clean (choose reboot after)"
echo -e "  ${CYAN}2${NC}) ${BOLD}Install${NC} \u2014 setup alias upd (+/- cron at 02:00)"
echo ""
read -rp "Select [1/2, default 1]: " MAIN_CHOICE
MODE="${MAIN_CHOICE:-1}"

# =============================================================
# MODE: RUN
# =============================================================

if [[ "$MODE" == "1" ]]; then

    echo ""
    echo -e "  ${BOLD}Run mode:${NC}"
    echo ""
    echo -e "  ${CYAN}1${NC}) Update + clean"
    echo -e "  ${CYAN}2${NC}) Update + clean + reboot"
    echo ""
    read -rp "Select [1/2, default 1]: " RUN_CHOICE
    RUN_CHOICE="${RUN_CHOICE:-1}"

    do_update

    if [[ "$RUN_CHOICE" == "2" ]]; then
        echo -e "${RED}Rebooting in 30 seconds... Ctrl+C to cancel.${NC}"
        sleep 30
        reboot
    else
        echo -e "${GREEN}Done. Run 'reboot' manually when ready.${NC}"
    fi

# =============================================================
# MODE: INSTALL
# =============================================================

elif [[ "$MODE" == "2" ]]; then

    echo ""
    echo -e "  ${BOLD}Install mode:${NC}"
    echo ""
    echo -e "  ${CYAN}1${NC}) Install alias ${BOLD}upd${NC} only"
    echo -e "  ${CYAN}2${NC}) Install alias ${BOLD}upd${NC} + cron (auto-update + reboot at 02:00)"
    echo ""
    read -rp "Select [1/2, default 1]: " INSTALL_CHOICE
    INSTALL_CHOICE="${INSTALL_CHOICE:-1}"

    echo ""
    do_install_alias
    do_deploy_night_update

    if [[ "$INSTALL_CHOICE" == "2" ]]; then
        do_install_cron
    fi

    echo ""
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}  Install complete!                       ${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo ""
    show_crontab

else
    echo -e "${RED}Invalid choice. Exiting.${NC}"
    exit 1
fi
