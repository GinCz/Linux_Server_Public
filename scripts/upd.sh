#!/usr/bin/env bash
# =============================================================
# Script:      upd.sh
# Version:     v2026.06.09
# Alias:       upd
# Location:    scripts/upd.sh
# Server:      ALL servers (VPN nodes, 222, 109, ...)
# Description: Full system update: apt upgrade, autoremove,
#              clean apt cache, clear old logs, clear tmp,
#              then reboot.
#              Safe: skips config file overwrites (keeps existing).
# Usage:       upd   (via alias)
#              bash /root/Linux_Server_Public/scripts/upd.sh
#              curl -Ls https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/upd.sh | bash
# = Rooted by VladiMIR + AI | v.2026.06.09 | github.com/GinCz =
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
echo -e "${GREEN}  Rebooting in 5 seconds...               ${NC}"
echo -e "${GREEN}  Ctrl+C to cancel reboot.                ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
sleep 5
reboot
