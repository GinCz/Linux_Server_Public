#!/bin/bash
# fix_crowdsec_hub_v2026-04-12.sh
# Restores CrowdSec hub parsers, scenarios and collections after hub corruption
# Server: 222-DE-NetCup | Ubuntu 24 | FASTPANEL
# Version: v2026-04-12
#
# PROBLEM: After cscli hub update, all hub files missing from /etc/crowdsec/hub/
# SYMPTOM: Hundreds of WARNING "no such file or directory" on every cscli command
# RESULT:  Only local parsers active, no nginx/ssh/geoip parsing → no real protection
#
# ⚠️  WARNING: This script stops CrowdSec temporarily (~10 sec).
#     Sites remain online. CrowdSec protection paused during stop→start.
#
# ⛔  SSH PORT NOTE: SSH port 22 must NOT be changed.
#     A previous attempt to move SSH to port 2222 broke multiple services.
#     CrowdSec ssh-bf/ssh-slow-bf scenarios handle SSH brute-force protection.
#
# Usage: sudo bash fix_crowdsec_hub_v2026-04-12.sh

set -e

clear
echo "======================================="
echo " CrowdSec Hub Restore v2026-04-12"
echo " Server: 222-DE-NetCup"
echo "======================================="
echo ""

echo "=== [1/5] Stopping CrowdSec ==="
systemctl stop crowdsec

echo "=== [2/5] Clearing broken hub cache ==="
rm -rf /etc/crowdsec/hub/
mkdir -p /etc/crowdsec/hub/

echo "=== [3/5] Re-downloading hub index ==="
cscli hub update

echo "=== [4/5] Reinstalling all required collections ==="

# Base Linux + SSH
cscli collections install crowdsecurity/linux
cscli collections install crowdsecurity/sshd

# Web server
cscli collections install crowdsecurity/nginx

# CMS
cscli collections install crowdsecurity/wordpress

# HTTP attack scenarios
cscli collections install crowdsecurity/base-http-scenarios
cscli collections install crowdsecurity/http-cve

# Whitelists (CDN, SEO bots)
cscli collections install crowdsecurity/whitelist-good-actors

# Databases
cscli collections install crowdsecurity/mysql
cscli collections install crowdsecurity/mariadb

echo ""
echo "=== [5/5] Starting CrowdSec ==="
systemctl start crowdsec
sleep 3

echo ""
echo "=== Status ==="
systemctl status crowdsec --no-pager | head -15

echo ""
echo "=== Applying new config ==="
systemctl reload crowdsec
echo "Config reloaded OK"

echo ""
echo "=== Parsers (hub items only) ==="
cscli parsers list 2>/dev/null | grep -v '^level='

echo ""
echo "=== Services ==="
systemctl is-active crowdsec nginx

echo ""
echo "======================================="
echo " Done! CrowdSec hub restored."
echo "======================================="
