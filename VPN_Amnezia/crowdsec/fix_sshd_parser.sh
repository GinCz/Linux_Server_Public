#!/bin/bash
clear
# =============================================================
# Script:      fix_sshd_parser.sh
# Version:     v2026-05-26
# Location:    VPN/crowdsec/fix_sshd_parser.sh
# Server:      ALL VPN nodes (Ubuntu 24)
# Alias:       none
# Run from repo (curl one-liner):
#   bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/VPN/crowdsec/fix_sshd_parser.sh)
# Description: Fixes CrowdSec SSH parser on Ubuntu 24 VPN nodes.
#              Ubuntu 24 writes SSH lines to /var/log/syslog in ISO format
#              which the sshd-logs parser cannot parse.
#              Fix: use SYSLOG_IDENTIFIER=sshd journalctl filter instead.
# Dependencies: crowdsec, cscli
# WARNING:     Restarts crowdsec service
# = Rooted by VladiMIR + AI | v2026.05.26 | github.com/GinCz =
# =============================================================

RED='\033[0;31m'
GRN='\033[0;32m'
CYN='\033[0;36m'
YEL='\033[1;33m'
NC='\033[0m'

echo -e "${CYN}=== Fix CrowdSec SSH parser (Ubuntu 24) ===${NC}"
echo ""

# Fix sshd.yaml - use SYSLOG_IDENTIFIER=sshd
echo -e "${YEL}[1/3] Fixing sshd.yaml...${NC}"
cat > /etc/crowdsec/acquis.d/sshd.yaml << 'EOF'
source: journalctl
journalctl_filter:
  - SYSLOG_IDENTIFIER=sshd
labels:
  type: syslog
EOF

# Remove duplicate setup.sshd.yaml if exists
if [ -f /etc/crowdsec/acquis.d/setup.sshd.yaml ]; then
    echo -e "${YEL}[2/3] Removing duplicate setup.sshd.yaml...${NC}"
    rm /etc/crowdsec/acquis.d/setup.sshd.yaml
else
    echo -e "${GRN}[2/3] No duplicate setup.sshd.yaml found — OK${NC}"
fi

# Fix setup.linux.yaml - remove /var/log/syslog (ISO format breaks parser)
echo -e "${YEL}[3/3] Fixing setup.linux.yaml (removing syslog)...${NC}"
cat > /etc/crowdsec/acquis.d/setup.linux.yaml << 'EOF'
filenames:
  - /var/log/messages
  - /var/log/kern.log
labels:
  type: syslog
source: file
EOF

# Restart CrowdSec
echo ""
echo -e "${CYN}Restarting CrowdSec...${NC}"
systemctl restart crowdsec
sleep 10

# Verify
echo ""
echo -e "${CYN}=== Metrics ===${NC}"
cscli metrics | grep -A 15 "Parsers"

echo ""
STATUS=$(systemctl is-active crowdsec)
if [ "$STATUS" = "active" ]; then
    echo -e "${GRN}✅ CrowdSec is active — SSH parser fix applied${NC}"
else
    echo -e "${RED}❌ CrowdSec is not active — check: journalctl -u crowdsec -n 20${NC}"
fi

echo ""
echo -e "= Rooted by VladiMIR + AI | v2026.05.26 | github.com/GinCz ="
