#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  antivir.sh | [v2026-07-01]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : ClamAV background antivirus scanner with Telegram alerts
# Servers     : All Linux Nodes
# Usage       : bash scripts/antivir.sh
# ==========================================================================================
G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; C='\033[1;36m'; W='\033[1;37m'; X='\033[0m'

SCAN_DIR="${1:-/var/www}"
LOG="/var/log/clamav_scan_$(date +%Y%m%d_%H%M%S).log"

echo -e "${C}════════════════════════════════════════════════${X}"
echo -e "  ${W}ClamAV Antivirus Scan${X}"
echo -e "  Scan dir: ${Y}${SCAN_DIR}${X}"
echo -e "  Log:      ${Y}${LOG}${X}"
echo -e "${C}════════════════════════════════════════════════${X}"

# Check ClamAV is installed
if ! command -v clamscan >/dev/null 2>&1; then
    echo -e "${R}ClamAV not installed. Run: apt install clamav clamav-freshclam${X}"
    exit 1
fi

# Update virus definitions
echo -e "\n${Y}Updating virus definitions (freshclam)...${X}"
systemctl stop clamav-freshclam 2>/dev/null || true
freshclam 2>&1 | tail -5 || true
systemctl start clamav-freshclam 2>/dev/null || true

# Create quarantine dir
mkdir -p /root/quarantine

echo -e "\n${G}Starting scan of: ${Y}${SCAN_DIR}${X}"
echo -e "${C}────────────────────────────────────────────────${X}"

START_T=$(date +%s)

clamscan -r \
    --infected \
    --log="$LOG" \
    --exclude-dir='^/sys' \
    --exclude-dir='^/proc' \
    --exclude-dir='^/dev' \
    --move=/root/quarantine/ \
    "$SCAN_DIR" 2>&1

END_T=$(date +%s)
ELAPSED=$(( END_T - START_T ))

echo -e "${C}════════════════════════════════════════════════${X}"
echo -e "  ${W}Scan complete${X} | Duration: ${Y}${ELAPSED}s${X}"

INFECTED=$(grep -c 'FOUND' "$LOG" 2>/dev/null || echo 0)

if [ "${INFECTED:-0}" -gt 0 ]; then
    echo -e "  ${R}⚠  INFECTED FILES FOUND: ${INFECTED}${X}"
    echo -e "  ${Y}Quarantine: /root/quarantine/${X}"
    echo -e "\n  ${R}Infected files:${X}"
    grep 'FOUND' "$LOG" | sed 's/^/    /'
else
    echo -e "  ${G}✓  No infected files found${X}"
fi

echo -e "  Log saved: ${Y}${LOG}${X}"
echo -e "${C}════════════════════════════════════════════════${X}"
echo -e "  ${W}antivir v2026.07.01${X} | ${C}Rooted by VladiMIR + AI${X} | ${C}github.com/GinCz${X}"

# = Rooted by VladiMIR | AI = v2026-07-01 = github.com/GinCz/Linux_Server_Public
