#!/usr/bin/env bash
# Description: Next-Gen IPS CrowdSec Installation & Configuration
# Target: FastPanel servers (109-ru and 222-de)
# Author: Ing. VladiMIR Bulantsev | 2026
clear; C='\033[0;32m'; Y='\033[1;33m'; X='\033[0m'

echo -e "${Y}>>> Installing CrowdSec Security Stack...${X}"

# 1. Install CrowdSec Repository and Engine
curl -s https://install.crowdsec.net | sudo sh
apt update && apt install crowdsec -y

# 2. Install Firewall Bouncer (The Executioner)
# This component applies bans to iptables automatically
apt install crowdsec-firewall-bouncer-iptables -y

# 3. Install Smart Collections
echo -e "${Y}>>> Installing Scenarios & Collections...${X}"
cscli collections install crowdsecurity/nginx
cscli collections install crowdsecurity/wordpress
cscli collections install crowdsecurity/http-cve
cscli collections install crowdsecurity/base-http-scenarios
cscli collections install crowdsecurity/sshd  # Added: Protection for your SSH port

# 4. Configure Log Acquisition (FastPanel Paths)
echo -e "${Y}>>> Configuring Log Acquisition...${X}"
cat > /etc/crowdsec/acquis.yaml <<EOC
# Monitor Nginx global and site logs
filenames:
  - /var/log/nginx/*.log
  - /var/www/*/data/logs/*.log
labels:
  type: nginx
---
# Monitor System Auth logs (SSH protection)
filenames:
  - /var/log/auth.log
  - /var/log/syslog
labels:
  type: syslog
EOC

# 5. Restart Services
systemctl restart crowdsec
systemctl restart crowdsec-firewall-bouncer-iptables

echo -e "\n${C}SUCCESS! CrowdSec is now active.${X}"
echo "To see active bans: cscli decisions list"
echo "To see alerts: cscli alerts list"
