#!/bin/bash
clear
# = Rooted by VladiMIR | AI =
# v2026-04-05
# Server: 222-DE-NetCup | IP: 152.53.182.222
# Fix: Add combined_crowdsec log format to nginx so CrowdSec can parse real IPs.
# Problem: FastPanel log_format starts with [$time_local], not $remote_addr.
#          CrowdSec nginx parser can't extract IPs → zero automatic local bans.
# Solution: Add second access_log in standard combined format for CrowdSec.
#
# ⚠️ WARNING: This script modifies /etc/nginx/nginx.conf and reloads nginx.
#             There are many live sites on this server.
#             Always backup first (done automatically below).

set -e

NGINX_CONF="/etc/nginx/nginx.conf"
BACKUP="/etc/nginx/nginx.conf.bak.20260405"
ACQUIS="/etc/crowdsec/acquis.yaml"
CROWDSEC_LOG="/var/log/nginx/crowdsec-access.log"

echo "========================================"
echo " CrowdSec nginx fix — 222-DE-NetCup"
echo " v2026-04-05"
echo "========================================"

# Step 1: Backup nginx.conf
echo "[1/5] Backing up nginx.conf..."
cp "$NGINX_CONF" "$BACKUP"
echo "      Backup saved: $BACKUP"

# Step 2: Add combined_crowdsec log format
# Insert after the existing log_format fastpanel line
echo "[2/5] Adding combined_crowdsec log_format..."
if grep -q 'log_format combined_crowdsec' "$NGINX_CONF"; then
    echo "      SKIP: combined_crowdsec already exists in nginx.conf"
else
    sed -i "/log_format fastpanel/a\    log_format combined_crowdsec '\$remote_addr - \$remote_user [\$time_local] \"\$request\" \$status \$body_bytes_sent \"\$http_referer\" \"\$http_user_agent\";'" "$NGINX_CONF"
    echo "      Done: log_format combined_crowdsec added"
fi

# Step 3: Add second access_log line for CrowdSec
echo "[3/5] Adding access_log for CrowdSec..."
if grep -q 'crowdsec-access.log' "$NGINX_CONF"; then
    echo "      SKIP: crowdsec-access.log already in nginx.conf"
else
    sed -i "/access_log.*fastpanel;/a\    access_log  $CROWDSEC_LOG combined_crowdsec;" "$NGINX_CONF"
    echo "      Done: access_log $CROWDSEC_LOG added"
fi

# Step 4: Test and reload nginx
echo "[4/5] Testing nginx config..."
nginx -t
echo "      Reloading nginx..."
systemctl reload nginx
echo "      ✅ nginx reloaded — dual logging active"

# Step 5: Update CrowdSec acquis.yaml to read the combined log
echo "[5/5] Updating CrowdSec acquis.yaml..."
# Check if crowdsec-access.log is already in acquis
if grep -r 'crowdsec-access.log' /etc/crowdsec/acquis.yaml /etc/crowdsec/acquis.d/ 2>/dev/null | grep -q 'crowdsec-access.log'; then
    echo "      SKIP: crowdsec-access.log already in acquis config"
else
    # Add a dedicated acquis entry for the crowdsec nginx log
    cat >> /etc/crowdsec/acquis.yaml << 'EOF'
---
filenames:
  - /var/log/nginx/crowdsec-access.log
labels:
  type: nginx
EOF
    echo "      Done: crowdsec-access.log added to acquis.yaml"
fi

# Restart CrowdSec to pick up new log source
echo "      Restarting CrowdSec..."
systemctl restart crowdsec
sleep 3
systemctl status crowdsec --no-pager | head -5

echo ""
echo "========================================"
echo " Waiting 60s for first bans..."
echo "========================================"
sleep 60

echo ""
echo "--- Decisions after fix ---"
cscli decisions list

echo ""
echo "--- CrowdSec metrics (lines parsed) ---"
cscli metrics | head -60

echo ""
echo "✅ DONE. CrowdSec should now generate local bans automatically."
echo "   FastPanel log:       /var/log/nginx/access.log (unchanged)"
echo "   CrowdSec log:        /var/log/nginx/crowdsec-access.log (new)"
