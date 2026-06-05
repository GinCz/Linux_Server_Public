#!/bin/bash
# =============================================================================
# 3x-ui Clean Install Script for AWS EC2 (Ubuntu 24 LTS)
# Version: 1.1.0
# Date: 2026-06-05
# Author: VladiMIR Bulantsev (GinCz)
# Repo: https://github.com/GinCz/Linux_Server_Public
#
# DESCRIPTION:
#   Full clean reinstall of 3x-ui (mhsanaei/3x-ui) panel.
#   - Removes previous installation completely
#   - Resets UFW firewall (keeps SSH port 22)
#   - Installs 3x-ui with random port, no SSL (HTTP only)
#   - Automatically opens the panel port in UFW
#   - Automatically opens VPN traffic port 443 in UFW
#   - Prints Access URL, login and password at the end
#
# AFTER INSTALL:
#   Manually add the printed panel port + port 443 to AWS Security Group.
#
# KNOWN BUGS / LIMITATIONS:
#   v1.0.0:
#   - If installer selects SSL option by default (Let's Encrypt for IP),
#     it fails silently when port 80 is not open in AWS Security Group.
#     Result: panel starts on HTTPS but cert is invalid -> ERR_SSL_PROTOCOL_ERROR.
#     Fix: script forces option 4 (Skip SSL) via heredoc stdin.
#
#   - 3x-ui installer reads credentials from internal config, NOT from
#     sqlite3 users table directly. Manual DB edits (username/password)
#     do NOT take effect without a proper x-ui settings reset.
#     Fix: always use credentials printed by installer at the end.
#
#   - UFW is reset completely (except port 22). All previous rules are lost.
#     This is intentional for a clean install.
#
#   - AWS Security Group rules are NOT managed by this script.
#     You must manually add ports in AWS Console.
#
#   v1.1.0:
#   - VPN traffic port 443 was not opened in UFW after install.
#     Fix: ufw allow 443/tcp added automatically.
# =============================================================================

set -e

echo "========================================"
echo " 3x-ui Clean Install for AWS EC2"
echo " Version: 1.1.0 | 2026-06-05"
echo "========================================"
echo ""

# Stop and remove old installation
echo "[1/4] Removing old x-ui installation..."
systemctl stop x-ui 2>/dev/null || true
rm -rf /etc/x-ui /usr/local/x-ui

# Reset UFW, allow only SSH
echo "[2/4] Resetting UFW firewall..."
ufw --force reset
ufw allow 22/tcp
ufw --force enable

# Run official installer with predefined answers:
#   1     -> SQLite database
#   n     -> random port (no custom port)
#   4     -> Skip SSL (HTTP only, no Let's Encrypt)
#   N     -> listen on all interfaces (not localhost only)
echo "[3/4] Running 3x-ui installer..."
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) << 'EOF'
1
n
4
N
EOF

# Open panel port and VPN traffic port in UFW
echo "[4/4] Opening ports in UFW..."
PORT=$(sqlite3 /etc/x-ui/x-ui.db "SELECT value FROM settings WHERE key='webPort';")
BASE=$(sqlite3 /etc/x-ui/x-ui.db "SELECT value FROM settings WHERE key='webBasePath';")
ufw allow ${PORT}/tcp
ufw allow 443/tcp
ufw allow 443/udp

# Print final summary
IP=$(curl -s ifconfig.me)
echo ""
echo "========================================"
echo " INSTALLATION COMPLETE"
echo "========================================"
echo ""
echo "  Panel URL  : http://${IP}:${PORT}${BASE}"
echo "  Panel Port : ${PORT}"
echo "  VPN Port   : 443 (tcp+udp)"
echo ""
echo "  Login and Password were printed above"
echo "  by the installer (see 'Panel Installation Complete' block)."
echo ""
echo "  !! ACTION REQUIRED — AWS Security Group !!"
echo "  Add these inbound rules in AWS Console:"
echo "  1. Custom TCP | Port: ${PORT} | Source: 0.0.0.0/0  (panel)"
echo "  2. Custom TCP | Port: 443     | Source: 0.0.0.0/0  (VPN)"
echo "  3. Custom UDP | Port: 443     | Source: 0.0.0.0/0  (VPN)"
echo "========================================"
