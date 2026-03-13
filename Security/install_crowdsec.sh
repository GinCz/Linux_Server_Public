#!/usr/bin/env bash
# Description: Install & Configure CrowdSec for FastPanel logs
clear; echo "Installing CrowdSec Intelligence..."
curl -s https://install.crowdsec.net | sudo sh
apt update && apt install crowdsec crowdsec-firewall-bouncer-iptables -y
cscli collections install crowdsecurity/nginx crowdsecurity/wordpress crowdsecurity/http-cve

cat > /etc/crowdsec/acquis.yaml <<EOC
filenames:
  - /var/log/nginx/*.log
  - /var/www/*/data/logs/*.log
labels:
  type: nginx
---
filenames:
  - /var/log/auth.log
labels:
  type: syslog
EOC

systemctl restart crowdsec
echo "SUCCESS. CrowdSec is hunting. Use 'cscli decisions list' to see results."
