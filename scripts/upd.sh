#!/usr/bin/env bash
# =============================================================
# Script:      upd.sh
# Version:     v2026.06.10c
# Alias:       upd
# Location:    scripts/upd.sh
# Server:      ALL servers (VPN nodes, 222, 109, ...)
# Description: Full system update: apt upgrade, autoremove,
#              clean apt cache, clear old logs, clear tmp.
#              Menu: Run (update now) or Install (alias +/- cron).
# Usage:       upd   (via alias)
#              bash /root/Linux_Server_Public/scripts/upd.sh
#              bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/upd.sh)
# = Rooted by VladiMIR + AI | v.2026.06.10c | github.com/GinCz =
# =============================================================
export DEBIAN_FRONTEND=noninteractive

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; RED='\033[1;31m'; BOLD='\033[1m'; NC='\033[0m'

CRON_JOB='0 2 * * * apt-get update -qq && apt-get upgrade -y -qq -o Dpkg::Options::="--force-confold" && apt-get autoremove -y -qq && apt-get autoclean -qq && journalctl --vacuum-time=7d >> /var/log/auto-upgrade.log 2>&1 && /sbin/reboot'

# =============================================================
# FUNCTIONS
# =============================================================

do_update() {
    clear
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${CYAN}  UPD — System Update & Cleanup           ${NC}"
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
    SCRIPT_PATH="/root/Linux_Server_Public/scripts/upd.sh"
    BASHRC="/root/.bashrc"
    if grep -q "alias upd=" "$BASHRC" 2>/dev/null; then
        echo -e "${GREEN}  ✓ Alias 'upd' already exists in $BASHRC${NC}"
    else
        echo "alias upd='bash $SCRIPT_PATH'" >> "$BASHRC"
        echo -e "${GREEN}  ✓ Alias 'upd' added to $BASHRC${NC}"
    fi
    source "$BASHRC" 2>/dev/null || true
}

do_install_cron() {
    CURRENT_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null)
    if [[ "$CURRENT_TZ" != "Europe/Prague" ]]; then
        timedatectl set-timezone Europe/Prague 2>/dev/null && \
            echo -e "${GREEN}  ✓ Timezone set to Europe/Prague.${NC}"
    else
        echo -e "${GREEN}  ✓ Timezone already Europe/Prague.${NC}"
    fi
    (crontab -l 2>/dev/null | grep -v 'auto-upgrade\|apt.*update\|apt.*upgrade'; echo "$CRON_JOB") | crontab -
    echo -e "${GREEN}  ✓ Cron added: daily update + cleanup + reboot at 02:00 (Prague).${NC}"
    echo -e "${CYAN}  Log: /var/log/auto-upgrade.log${NC}"
}

# =============================================================
# MAIN MENU
# =============================================================

clear
echo -e "${CYAN}${BOLD}==========================================${NC}"
echo -e "${CYAN}${BOLD}  UPD — System Update & Cleanup           ${NC}"
echo -e "${CYAN}  $(hostname) | $(date '+%Y-%m-%d %H:%M')   ${NC}"
echo -e "${CYAN}${BOLD}==========================================${NC}"
echo ""
echo -e "  ${BOLD}What do you want to do?${NC}"
echo ""
echo -e "  ${CYAN}1${NC}) ${BOLD}Run${NC}     — update + clean (choose reboot after)"
echo -e "  ${CYAN}2${NC}) ${BOLD}Install${NC} — setup alias upd (+/- cron at 02:00)"
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
        echo -e "${RED}Rebooting in 3 seconds... Ctrl+C to cancel.${NC}"
        sleep 3
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

    if [[ "$INSTALL_CHOICE" == "2" ]]; then
        CRON_EXISTS=$(crontab -l 2>/dev/null | grep -c 'auto-upgrade')
        if [[ "$CRON_EXISTS" -gt 0 ]]; then
            echo -e "${GREEN}  ✓ Cron auto-update at 02:00 already configured.${NC}"
        else
            do_install_cron
        fi
    fi

    echo ""
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}  Install complete!                       ${NC}"
    echo -e "${GREEN}==========================================${NC}"

else
    echo -e "${RED}Invalid choice. Exiting.${NC}"
    exit 1
fi
