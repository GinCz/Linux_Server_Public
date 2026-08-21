#!/usr/bin/env bash
# =============================================================================
# crowdsec_install_vpn.sh — CrowdSec install for VPN nodes (no web server)
# Version     : v2026-04-30
# Protects    : SSH brute-force, port scanning, DDoS
# Bans via    : iptables (crowdsec-firewall-bouncer-iptables)
# Usage       : bash /root/Linux_Server_Public/VPN/crowdsec_install_vpn.sh
# = Rooted by VladiMIR | AI =
# =============================================================================
clear

G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; W='\033[1;37m'; X='\033[0m'

echo -e "${Y}=== CrowdSec VPN Node Installer ===${X}"
echo -e "${W}Server: $(hostname) | $(hostname -I | awk '{print $1}')${X}\n"

# 1. Install CrowdSec repo + packages
echo -e "${G}[1/6] Adding CrowdSec repository...${X}"
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | bash

echo -e "${G}[2/6] Installing CrowdSec + firewall bouncer...${X}"
apt-get install -y crowdsec crowdsec-firewall-bouncer-iptables

# 2. Install SSH protection collection
echo -e "${G}[3/6] Installing SSH brute-force + port scan collections...${X}"
cscli collections install crowdsecurity/linux
cscli collections install crowdsecurity/sshd
cscli scenarios install crowdsecurity/portscan
cscli scenarios install crowdsecurity/ssh-bf
cscli scenarios install crowdsecurity/ssh-slow-bf

# 3. Configure acquis.yaml for SSH log source
echo -e "${G}[4/6] Configuring log acquisition (SSH)...${X}"
cat > /etc/crowdsec/acquis.d/sshd.yaml << 'EOF'
filenames:
  - /var/log/auth.log
  - /var/log/syslog
labels:
  type: syslog
EOF

# 4. Enable and start services
echo -e "${G}[5/6] Enabling services...${X}"
systemctl enable crowdsec --now
systemctl enable crowdsec-firewall-bouncer --now

# 5. Status check
echo -e "\n${G}[6/6] Status check:${X}"
CS_STATUS=$(systemctl is-active crowdsec 2>/dev/null)
BN_STATUS=$(systemctl is-active crowdsec-firewall-bouncer 2>/dev/null)

if [ "$CS_STATUS" = "active" ]; then
  echo -e "  CrowdSec Engine:  ${G}\u25cf active${X}"
else
  echo -e "  CrowdSec Engine:  ${R}\u2717 ${CS_STATUS}${X}"
fi

if [ "$BN_STATUS" = "active" ]; then
  echo -e "  Firewall Bouncer: ${G}\u25cf active${X} (iptables bans enforced)"
else
  echo -e "  Firewall Bouncer: ${R}\u2717 ${BN_STATUS}${X}"
  echo -e "  ${Y}Fix: systemctl start crowdsec-firewall-bouncer${X}"
fi

echo -e "\n${W}Collections installed:${X}"
cscli collections list 2>/dev/null | grep -E 'crowdsecurity/(linux|sshd)'
cscli scenarios list 2>/dev/null | grep -E 'crowdsecurity/(portscan|ssh)'

echo -e "\n${Y}Run 'cscli decisions list' to see active bans.${X}"
echo -e "${Y}Run 'cscli alerts list' to see attack history.${X}"
echo -e "\n${G}=== Done! CrowdSec is protecting this VPN node ===${X}\n"
