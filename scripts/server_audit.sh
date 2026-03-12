#!/usr/bin/env bash
# Deep Server Audit Tool for VladiMIR Infrastructure

echo "--- STARTING DEEP AUDIT: $(hostname) ---"

echo "[1] Checking for hidden SSH triggers..."
grep -r "curl" /etc/profile /etc/bash.bashrc ~/.bashrc ~/.profile /etc/pam.d/ /etc/ssh/ 2>/dev/null

echo "[2] Checking for non-standard Cron jobs..."
crontab -l | grep -v "^#"

echo "[3] Checking for active Monitoring/Scripts..."
ls -l /usr/local/bin/ | grep ".sh"

echo "[4] System Resources..."
df -h | grep '^/dev/'
free -h

echo "[5] Active VPN/Network ports..."
ss -tulpn | grep -E '51820|1194|445'

echo "--- AUDIT COMPLETED ---"
