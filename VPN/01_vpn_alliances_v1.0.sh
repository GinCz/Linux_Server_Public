#!/bin/bash
clear
# =============================================================================
# 01_vpn_alliances_v1.0.sh
# VPN Server Initial Setup: Aliases + MC Menu + SSH MOTD Banner
# =============================================================================
# Version  : v2026-03-24
# Author   : Ing. VladiMIR Bulantsev
# GitHub   : https://github.com/GinCz/Linux_Server_Public
# Usage    : bash /root/Linux_Server_Public/VPN/01_vpn_alliances_v1.0.sh
# -----------------------------------------------------------------------------
# What this script does:
#   1. Clones or updates the Linux_Server_Public repository
#   2. Installs VPN/.bashrc  →  /root/.bashrc
#   3. Installs VPN/mc.menu  →  /root/.config/mc/menu  (MC F2 menu)
#   4. Installs MOTD banner  →  /etc/profile.d/motd_vpn.sh
#   5. Sources .bashrc immediately — no re-login needed
#   6. Runs 'aw' to verify AmneziaWG stats work
# =============================================================================

C="\033[1;36m"; Y="\033[1;33m"; G="\033[1;32m"; X="\033[0m"

echo -e "${Y}"
echo "  ============================================================"
echo "   VPN SERVER SETUP — Linux_Server_Public"
echo "   Author: Ing. VladiMIR Bulantsev | Version: v2026-03-24"
echo "  ============================================================"
echo -e "${X}"

# -----------------------------------------------------------------------------
# STEP 1: Clone or update repository
# -----------------------------------------------------------------------------
echo -e "${C}[1/5] Repository...${X}"
if [ ! -d /root/Linux_Server_Public ]; then
    echo "      Cloning from GitHub (SSH)..."
    cd /root && git clone git@github.com:GinCz/Linux_Server_Public.git
else
    echo "      Repository found — pulling latest changes..."
    cd /root/Linux_Server_Public && git pull --rebase
fi
echo -e "      ${G}OK${X}"
echo

# -----------------------------------------------------------------------------
# STEP 2: Install .bashrc
# -----------------------------------------------------------------------------
echo -e "${C}[2/5] Installing .bashrc...${X}"
cp /root/Linux_Server_Public/VPN/.bashrc /root/.bashrc
echo -e "      ${G}OK → /root/.bashrc${X}"
echo

# -----------------------------------------------------------------------------
# STEP 3: Install Midnight Commander F2 menu
# -----------------------------------------------------------------------------
echo -e "${C}[3/5] Installing MC menu (F2)...${X}"
mkdir -p /root/.config/mc
cp /root/Linux_Server_Public/VPN/mc.menu /root/.config/mc/menu
echo -e "      ${G}OK → /root/.config/mc/menu${X}"
echo

# -----------------------------------------------------------------------------
# STEP 4: Install SSH MOTD banner
# Compact layout:
#   Line 1: 🖥  HOSTNAME (center)   IP: x.x.x.x   RAM: x/xG   CPU: x cores
#   Line 2: separator
#   Lines 3-4: aliases in 3 columns with short descriptions
#   Line 5: separator
#   Line 6: OS name | Uptime: ...
# -----------------------------------------------------------------------------
echo -e "${C}[4/5] Installing SSH MOTD banner...${X}"
cat > /etc/profile.d/motd_vpn.sh << 'MOTD'
#!/bin/bash
# =============================================================================
# motd_vpn.sh — SSH Login Banner for VPN Servers (compact)
# Version  : v2026-03-24
# Installed: by 01_vpn_alliances_v1.0.sh
# =============================================================================
[[ $- == *i* ]] || return

C="\033[1;36m"; Y="\033[1;33m"; G="\033[1;32m"; X="\033[0m"
L="${Y}────────────────────────────────────────────────────────────────${X}"

HN=$(hostname)
IP=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1)
RAM=$(free -h | awk '/^Mem:/{print $3"/"$2}')
CPU=$(nproc)" cores"
OS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
UP=$(uptime -p 2>/dev/null | sed 's/up //')
WG=$(docker exec amnezia-awg awg show 2>/dev/null | grep -c 'peer:' || echo 0)

echo
echo -e "$L"
printf "  ${Y}🖥  %-24s${X}  ${C}IP:${X} ${G}%-18s${X}  ${C}RAM:${X} ${G}%-10s${X}  ${C}CPU:${X} ${G}%s${X}\n" \
    "$HN" "$IP" "$RAM" "$CPU"
echo -e "$L"
echo -e "  ${C}aw${X}     (vpn stats)      ${C}sos${X}    (audit 1h)       ${C}sos3${X}   (audit 3h)"
echo -e "  ${C}sos24${X}  (audit 24h)      ${C}sos120${X} (audit 5 days)   ${C}infooo${X} (server info)"
echo -e "  ${C}backup${X} (system backup)  ${C}load${X}   (git pull)       ${C}save${X}   (git push)"
echo -e "  ${C}m${X}      (midnight cmd)   ${C}00${X}     (clear screen)   ${C}banlog${X} (cs alerts)"
echo -e "$L"
printf "  🔹 ${G}%s${X}  |  Uptime: ${G}%s${X}  |  WG peers: ${G}%s${X}\n" "$OS" "$UP" "$WG"
echo -e "$L"
echo
MOTD
chmod +x /etc/profile.d/motd_vpn.sh
echo -e "      ${G}OK → /etc/profile.d/motd_vpn.sh${X}"
echo

# -----------------------------------------------------------------------------
# STEP 5: Apply aliases to current session
# -----------------------------------------------------------------------------
echo -e "${C}[5/5] Applying aliases to current session...${X}"
source /root/.bashrc
echo -e "      ${G}OK${X}"
echo

# -----------------------------------------------------------------------------
# SUMMARY
# -----------------------------------------------------------------------------
echo -e "${Y}  ============================================================${X}"
echo -e "${Y}   SETUP COMPLETE — $(hostname)${X}"
echo -e "${Y}  ============================================================${X}"
echo -e "  ${C}Installed:${X}"
echo -e "    ✓  /root/.bashrc"
echo -e "    ✓  /root/.config/mc/menu  (F2 in mc)"
echo -e "    ✓  /etc/profile.d/motd_vpn.sh"
echo -e "  ${C}Aliases:${X}"
echo -e "    ${G}aw${X}     (vpn stats)     ${G}sos${X}    (audit 1h)      ${G}sos3${X}   (audit 3h)"
echo -e "    ${G}sos24${X}  (audit 24h)     ${G}sos120${X} (audit 5 days)  ${G}infooo${X} (server info)"
echo -e "    ${G}backup${X} (system backup) ${G}load${X}   (git pull)      ${G}save${X}   (git push)"
echo -e "    ${G}m${X}      (midnight cmd)  ${G}00${X}     (clear screen)  ${G}banlog${X} (cs alerts)"
echo -e "${Y}  ============================================================${X}"
echo
echo -e "${C}Running 'aw' to verify AmneziaWG...${X}"
echo
bash /root/Linux_Server_Public/scripts/amnezia_stat.sh
