#!/bin/bash
clear
# = Rooted by VladiMIR + AI | v.2026.05.26 | github.com/GinCz =
# Script:  remove_samba.sh
# Purpose: Remove Samba completely and close ports 139/445 via UFW
# Usage:   bash remove_samba.sh
# Safe:    idempotent — can run multiple times, skips if already removed

G=$'\033[1;32m'
R=$'\033[1;31m'
Y=$'\033[1;33m'
C=$'\033[1;36m'
X=$'\033[0m'

echo -e "${C}======================================${X}"
echo -e "${C}  SAMBA REMOVAL + PORT CLOSE${X}"
echo -e "${C}  $(hostname)  $(hostname -I | awk '{print $1}')${X}"
echo -e "${C}======================================${X}"
echo ""

# --- Step 1: Check if Samba is installed ---
if ! dpkg -l 2>/dev/null | grep -qE '^ii\s+(samba|smbd)'; then
    echo -e "${G}OK: Samba is not installed — nothing to remove${X}"
    SAMBA_INSTALLED=0
else
    SAMBA_INSTALLED=1
fi

# --- Step 2: Stop and disable services ---
if [ "$SAMBA_INSTALLED" -eq 1 ]; then
    echo -e "${C}[1/4] Stopping Samba services...${X}"
    for SVC in smbd nmbd winbind samba-ad-dc; do
        systemctl stop    "$SVC" 2>/dev/null && echo "  stopped: $SVC"
        systemctl disable "$SVC" 2>/dev/null && echo "  disabled: $SVC"
    done
    echo -e "${G}OK${X}"

    # --- Step 3: Remove packages ---
    echo -e "${C}[2/4] Removing Samba packages...${X}"
    apt-get purge -y samba samba-common samba-common-bin samba-libs \
        samba-vfs-modules libsmbclient smbclient winbind 2>/dev/null
    apt-get autoremove -y 2>/dev/null
    apt-get autoclean -y 2>/dev/null

    # Remove leftover config/logs
    rm -rf /etc/samba /var/lib/samba /var/log/samba /run/samba 2>/dev/null
    echo -e "${G}OK: packages removed, config/logs cleaned${X}"
else
    echo -e "${Y}[1-2/4] SKIP: Samba not installed${X}"
fi

# --- Step 4: Close ports in UFW ---
echo -e "${C}[3/4] Closing ports 139/445 in UFW...${X}"
if command -v ufw >/dev/null 2>&1; then
    UFW_ST=$(ufw status 2>/dev/null | head -1)
    if [[ "$UFW_ST" == *inactive* ]]; then
        echo -e "${Y}  UFW is inactive — enabling first${X}"
        ufw --force enable 2>/dev/null
    fi

    # Block both IPv4 and IPv6, TCP and UDP
    ufw deny 139/tcp  comment 'Block Samba NetBIOS' 2>/dev/null
    ufw deny 139/udp  comment 'Block Samba NetBIOS' 2>/dev/null
    ufw deny 445/tcp  comment 'Block Samba SMB'     2>/dev/null
    ufw deny 445/udp  comment 'Block Samba SMB'     2>/dev/null
    ufw reload 2>/dev/null
    echo -e "${G}OK: ports 139/445 blocked in UFW${X}"
else
    echo -e "${Y}  UFW not installed — using iptables directly${X}"
    iptables -I INPUT -p tcp --dport 445 -j DROP 2>/dev/null
    iptables -I INPUT -p tcp --dport 139 -j DROP 2>/dev/null
    iptables -I INPUT -p udp --dport 445 -j DROP 2>/dev/null
    iptables -I INPUT -p udp --dport 139 -j DROP 2>/dev/null
    echo -e "${G}OK: ports 139/445 blocked via iptables${X}"
fi

# --- Step 5: Remove CrowdSec SMB rules (optional cleanup) ---
echo -e "${C}[4/4] Removing CrowdSec SMB scenarios (optional)...${X}"
if command -v cscli >/dev/null 2>&1; then
    cscli collections remove crowdsecurity/smb 2>/dev/null \
        && echo -e "  ${G}OK: crowdsecurity/smb removed${X}" \
        || echo -e "  ${Y}SKIP: smb collection not installed${X}"
    rm -f /etc/crowdsec/acquis.d/setup.smb.yaml \
          /etc/crowdsec/acquis.d/smb.yaml 2>/dev/null \
        && echo -e "  ${G}OK: smb acquis files removed${X}"
    systemctl restart crowdsec 2>/dev/null \
        && echo -e "  ${G}OK: CrowdSec restarted${X}"
else
    echo -e "${Y}  SKIP: CrowdSec not installed${X}"
fi

# --- Final check ---
echo ""
echo -e "${C}======================================${X}"
echo -e "${C}  VERIFICATION${X}"
echo -e "${C}======================================${X}"

echo -e "${C}Samba processes:${X}"
if pgrep -x smbd >/dev/null 2>&1 || pgrep -x nmbd >/dev/null 2>&1; then
    echo -e "  ${R}WARNING: smbd/nmbd still running!${X}"
else
    echo -e "  ${G}OK: no smbd/nmbd processes${X}"
fi

echo -e "${C}Ports 139/445:${X}"
if ss -tlnp 2>/dev/null | grep -qE ':139|:445'; then
    echo -e "  ${R}WARNING: ports still open:${X}"
    ss -tlnp | grep -E ':139|:445' | sed 's/^/    /'
else
    echo -e "  ${G}OK: ports 139 and 445 are closed${X}"
fi

echo ""
echo -e "${C}UFW status:${X}"
ufw status numbered 2>/dev/null | grep -E '139|445|Status' | sed 's/^/  /'

echo ""
echo -e "${G}======================================${X}"
echo -e "${G}  DONE — Samba removed, ports closed${X}"
echo -e "${G}  = Rooted by VladiMIR + AI | v.2026.05.26 | github.com/GinCz =${X}"
echo -e "${G}======================================${X}"
