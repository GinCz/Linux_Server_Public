#!/bin/bash
# = Rooted by VladiMIR | AI =
# v2026-04-10
# Install CrowdSec on a fresh VPN/monitoring node (Ubuntu 22/24)
#
# Tested on: VPN-EU-Tatra-9 (144.124.232.9, Ubuntu 22 Jammy)
# Run as: root
# Usage: bash install-tatra9.sh

clear

set -e

echo "================================================================"
echo " CrowdSec Install Script for VPN/monitoring nodes"
echo " = Rooted by VladiMIR | AI = | v2026-04-10"
echo "================================================================"

# --- Step 1: Add repository and install ---
echo "[1/4] Installing CrowdSec + firewall bouncer..."
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | bash
apt-get install -y crowdsec crowdsec-firewall-bouncer-iptables

# --- Step 2: Install collections ---
echo "[2/4] Installing SSH + HTTP + CVE collections..."
cscli collections install crowdsecurity/linux
cscli collections install crowdsecurity/nginx
cscli hub update

# --- Step 3: Deploy whitelist ---
echo "[3/4] Deploying trusted IP whitelist..."
cat > /etc/crowdsec/parsers/s02-enrich/my_whitelist.yaml << 'WHITELIST'
name: my_whitelist
description: "Whitelist - all VladiMIR servers and home IPs"
whitelist:
  reason: "VladiMIR trusted IPs: servers, VPN nodes, home"
  ip:
    - "152.53.182.222"
    - "212.109.223.109"
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
    - "5.101.114.114"
    - "152.53.138.228"
    - "109.199.112.156"
    - "80.94.95.221"
WHITELIST

# --- Step 4: Deploy custom scenarios ---
echo "[4/4] Deploying custom scenarios..."

cat > /etc/crowdsec/scenarios/custom-wp-login-bf-any.yaml << 'SCENARIO1'
type: leaky
name: custom/wp-login-bf-any
description: "WP-login brute force - any HTTP status - auto ban"
filter: "evt.Meta.log_type == 'http_access-log' && evt.Parsed.file_name == 'wp-login.php' && evt.Parsed.verb == 'POST'"
groupby: evt.Meta.source_ip
capacity: 5
leakspeed: 60s
blackhole: 24h
labels:
  remediation: true
  service: http
  behavior: "http:bruteforce"
  label: "WP-login BF any status"
  confidence: 3
SCENARIO1

cat > /etc/crowdsec/scenarios/custom-slow-scanner.yaml << 'SCENARIO2'
type: leaky
name: custom/slow-scanner
description: "Slow scan of backup/config/sensitive files - auto ban 48h"
filter: >
  evt.Meta.log_type in ["http_access-log", "http_error-log"] &&
  (
    evt.Parsed.request contains ".zip" ||
    evt.Parsed.request contains ".git" ||
    evt.Parsed.request contains ".aws" ||
    evt.Parsed.request contains "wp-config" ||
    evt.Parsed.request contains "phpmyadmin" ||
    evt.Parsed.request contains "credentials" ||
    evt.Parsed.request contains "secrets" ||
    evt.Parsed.request contains "backup" ||
    evt.Parsed.request contains "wwwroot" ||
    evt.Parsed.request contains "htdocs"
  )
groupby: evt.Meta.source_ip
capacity: 3
leakspeed: 120s
blackhole: 48h
labels:
  remediation: true
  service: http
  behavior: "http:scan"
  label: "Slow backup/config scanner"
  confidence: 3
SCENARIO2

# --- Start services ---
systemctl enable --now crowdsec
systemctl enable --now crowdsec-firewall-bouncer
sleep 5

echo ""
echo "================================================================"
echo " Installation complete!"
echo "================================================================"
systemctl status crowdsec --no-pager | grep -E "Active|running"
systemctl status crowdsec-firewall-bouncer --no-pager | grep -E "Active|running"
echo ""
echo "Active bans (first 60 sec):"
sleep 10
cscli decisions list --limit 10

echo "========================================="

