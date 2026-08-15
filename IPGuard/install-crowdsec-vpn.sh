#!/bin/bash
clear
# ==========================================================
# install-crowdsec-vpn.sh — Install CrowdSec on VPN/remote node
# Run ON THE TARGET SERVER (not on 222)
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/install-crowdsec-vpn.sh)
# = Rooted by VladiMIR + AI | v.2026.05.27 | github.com/GinCz =
# ==========================================================

set -euo pipefail

HOSTNAME=$(hostname)
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')

echo "================================================"
echo " CrowdSec Installer — VladiMIR Infrastructure"
echo " Server : $HOSTNAME"
echo " Date   : $DATETIME"
echo "================================================"
echo ""

# Check if already installed
if command -v cscli &>/dev/null; then
  echo "ℹ️  CrowdSec already installed:"
  cscli version 2>/dev/null | head -3
  echo ""
  echo "Checking running decisions..."
  cscli decisions list 2>/dev/null | tail -5
  echo ""
  echo "Nothing to do. Exiting."
  exit 0
fi

echo "[1/5] Installing CrowdSec repository..."
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | bash
echo "      Done."

echo "[2/5] Installing CrowdSec..."
apt-get install -y crowdsec
echo "      Done."

echo "[3/5] Installing essential bouncers (iptables)..."
apt-get install -y crowdsec-firewall-bouncer-iptables
echo "      Done."

echo "[4/5] Installing detection scenarios..."
# SSH brute force
cscli collections install crowdsecurity/sshd 2>/dev/null || true
# Linux base scenarios (port scan, etc)
cscli collections install crowdsecurity/linux 2>/dev/null || true
# Web attacks (if nginx/apache present)
if command -v nginx &>/dev/null; then
  cscli collections install crowdsecurity/nginx 2>/dev/null || true
  echo "      + nginx collection installed."
fi
if command -v apache2 &>/dev/null; then
  cscli collections install crowdsecurity/apache2 2>/dev/null || true
  echo "      + apache2 collection installed."
fi
echo "      Scenarios installed."

echo "[5/5] Starting and enabling services..."
systemctl enable crowdsec --now
systemctl enable crowdsec-firewall-bouncer --now
echo "      Done."

echo ""
echo "================================================"
echo " CrowdSec installed successfully! ✅"
echo " Server : $HOSTNAME"
echo ""
echo " Verify:"
echo "   cscli decisions list"
echo "   systemctl status crowdsec"
echo "   systemctl status crowdsec-firewall-bouncer"
echo "================================================"
