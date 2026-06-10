#!/usr/bin/env bash
# =============================================================
# Script:      upd.sh
# Version:     v2026.06.10b
# Alias:       upd
# Location:    scripts/upd.sh
# Server:      ALL servers (VPN nodes, 222, 109, ...)
# Description: Full system update: apt upgrade, autoremove,
#              clean apt cache, clear old logs, clear tmp,
#              then optional reboot.
#              Safe: skips config file overwrites (keeps existing).
# Usage:       upd   (via alias)
#              bash /root/Linux_Server_Public/scripts/upd.sh
#              bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/upd.sh)
# = Rooted by VladiMIR + AI | v.2026.06.10b | github.com/GinCz =
# =============================================================
export DEBIAN_FRONTEND=noninteractive

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; RED='\033[1;31m'; NC='\033[0m'

clear
echo -e "${CYAN}==========================================${NC}"
echo -e "${CYAN}  UPD — System Update & Cleanup           ${NC}"
echo -e "${CYAN}  $(hostname) | $(date '+%Y-%m-%d %H:%M')   ${NC}"
echo -e "${CYAN}==========================================${NC}"
echo ""

# --- [1/6] apt update ---
echo -e "${YELLOW}[1/6] apt update...${NC}"
apt-get update -q 2>&1 | tail -3
echo -e "${GREEN}Done.${NC}"

# --- [2/6] apt upgrade (keep existing configs) ---
echo -e "${YELLOW}[2/6] apt upgrade...${NC}"
apt-get upgrade -y -q \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    2>&1 | tail -5
echo -e "${GREEN}Done.${NC}"

# --- [3/6] autoremove + autoclean ---
echo -e "${YELLOW}[3/6] autoremove + autoclean...${NC}"
apt-get autoremove -y -q 2>&1 | tail -3
apt-get autoclean -y -q 2>&1 | tail -3
apt-get clean -q
echo -e "${GREEN}Done.${NC}"

# --- [4/6] Clear old journal logs (keep last 7 days) ---
echo -e "${YELLOW}[4/6] Clearing old journal logs (keep 7d)...${NC}"
journalctl --vacuum-time=7d 2>&1 | tail -3
echo -e "${GREEN}Done.${NC}"

# --- [5/6] Clear tmp ---
echo -e "${YELLOW}[5/6] Clearing /tmp...${NC}"
find /tmp -mindepth 1 -mtime +1 -delete 2>/dev/null
find /var/tmp -mindepth 1 -mtime +7 -delete 2>/dev/null
echo -e "${GREEN}Done.${NC}"

# --- [6/6] Show disk before reboot ---
echo -e "${YELLOW}[6/6] Disk usage after cleanup:${NC}"
df -h / | awk 'NR==2{printf "  /  Size:%-6s  Used:%-6s  Free:%-6s  (%s)\n",$2,$3,$4,$5}'

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  Update & cleanup complete!              ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

# --- Cron setup prompt ---
CRON_JOB="0 2 * * * apt-get update -qq && apt-get upgrade -y -qq -o Dpkg::Options::=\"--force-confold\" && apt-get autoremove -y -qq && apt-get autoclean -qq && journalctl --vacuum-time=7d >> /var/log/auto-upgrade.log 2>&1 && /sbin/reboot"
CRON_EXISTS=$(crontab -l 2>/dev/null | grep -c 'auto-upgrade')

if [[ "$CRON_EXISTS" -gt 0 ]]; then
    echo -e "${GREEN}  ✓ Cron auto-update at 02:00 already configured.${NC}"
else
    echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  ⏰ Auto-update cron (daily 02:00)       ${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo -e "  ${CYAN}1${NC}) Yes — add cron (daily update + reboot at 02:00)"
    echo -e "  ${CYAN}2${NC}) No  — skip (Default)"
    echo ""
    read -rp "Select [1/2, default 2]: " CRON_CHOICE
    CRON_CHOICE="${CRON_CHOICE:-2}"

    if [[ "$CRON_CHOICE" == "1" ]]; then
        # Set timezone to Prague if not already set
        CURRENT_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null)
        if [[ "$CURRENT_TZ" != "Europe/Prague" ]]; then
            timedatectl set-timezone Europe/Prague 2>/dev/null && \
                echo -e "${GREEN}  Timezone set to Europe/Prague.${NC}"
        fi
        # Add cron job (remove old duplicates first)
        (crontab -l 2>/dev/null | grep -v 'auto-upgrade\|reboot\|apt.*update\|apt.*upgrade'; echo "$CRON_JOB") | crontab -
        echo -e "${GREEN}  ✓ Cron added: daily update + cleanup + reboot at 02:00 (Prague).${NC}"
        echo -e "${CYAN}  Log: /var/log/auto-upgrade.log${NC}"
    else
        echo -e "${GREEN}  Cron skipped.${NC}"
    fi
fi

echo ""

# --- Reboot prompt ---
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  ⚠ REBOOT REQUIRED                     ${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "  ${CYAN}1${NC}) Yes — reboot now"
echo -e "  ${CYAN}2${NC}) No  — stay (Default)"
echo ""
read -rp "Select [1/2, default 2]: " REBOOT_CHOICE
REBOOT_CHOICE="${REBOOT_CHOICE:-2}"

if [[ "$REBOOT_CHOICE" == "1" ]]; then
    echo -e "${RED}Rebooting in 3 seconds... Ctrl+C to cancel.${NC}"
    sleep 3
    reboot
else
    echo -e "${GREEN}Reboot skipped. Run 'reboot' manually when ready.${NC}"
fi
