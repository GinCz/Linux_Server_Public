#!/usr/bin/env bash
# Script:  install_crowdsec.sh
# Version: v2026-03-17
# Purpose: Install and configure CrowdSec IPS on FastPanel servers (222 and 109).
#          Installs engine, firewall bouncer, collections, log acquisition,
#          and whitelists trusted IPs.
# Usage:   /opt/server_tools/scripts/install_crowdsec.sh
# Alias:   antivir (shows bans after install: cscli decisions list)

clear
C='\033[0;32m'; Y='\033[1;33m'; X='\033[0m'

echo -e "${Y}>>> Installing CrowdSec Security Stack...${X}"

# 1. Install CrowdSec repository and engine
curl -s https://install.crowdsec.net | bash
apt update && apt install crowdsec -y

# 2. Install firewall bouncer (applies bans to iptables automatically)
apt install crowdsec-firewall-bouncer-iptables -y

# 3. Install collections
echo -e "${Y}>>> Installing collections...${X}"
cscli collections install crowdsecurity/nginx
cscli collections install crowdsecurity/wordpress
cscli collections install crowdsecurity/http-cve
cscli collections install crowdsecurity/base-http-scenarios
cscli collections install crowdsecurity/sshd

# 4. Configure log acquisition for FastPanel
echo -e "${Y}>>> Configuring log acquisition...${X}"
cat > /etc/crowdsec/acquis.yaml << 'EOC'
filenames:
  - /var/log/nginx/*.log
  - /var/www/*/data/logs/*.log
labels:
  type: nginx
---
filenames:
  - /var/log/auth.log
  - /var/log/syslog
labels:
  type: syslog
EOC

# 5. Whitelist trusted IPs
echo -e "${Y}>>> Adding trusted IP whitelist...${X}"
mkdir -p /etc/crowdsec/parsers/s02-enrich
cat > /etc/crowdsec/parsers/s02-enrich/my_whitelist.yaml << 'EOW'
name: my_whitelist
description: Trusted servers and VPN nodes
whitelist:
  reason: trusted infrastructure
  ip:
    - "152.53.182.222"
    - "212.109.223.109"
    - "5.101.114.114"
    - "109.234.38.47"
    - "144.124.228.237"
    - "144.124.232.9"
    - "144.124.228.227"
    - "144.124.239.24"
    - "91.84.118.178"
    - "146.103.110.176"
    - "144.124.233.38"
    - "185.100.197.16"
    - "90.181.133.10"
    - "185.14.233.235"
    - "185.14.232.0"
EOW

# 6. Restart services
systemctl restart crowdsec
systemctl restart crowdsec-firewall-bouncer-iptables

echo -e "\n${C}SUCCESS! CrowdSec is now active.${X}"
echo "Active bans:  cscli decisions list"
echo "Alerts:       cscli alerts list"
