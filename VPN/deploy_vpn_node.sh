#!/bin/bash
# =============================================================================
# deploy_vpn_node.sh — Deploy/update all configs on VPN node
# Version  : v2026-04-07
# Usage    : bash /root/Linux_Server_Public/VPN/deploy_vpn_node.sh
# Run this once after git clone OR after 'load' to apply all updates
# = Rooted by VladiMIR | AI =
# =============================================================================

clear
echo "= Rooted by VladiMIR | AI = v2026-04-07"
echo "=== VPN Node Deploy ==="
echo ""

REPO="/root/Linux_Server_Public"

# 1. Pull latest from GitHub
echo "[1/4] git pull..."
cd "$REPO" && git pull --rebase

# 2. Copy .bashrc
echo "[2/4] Copying .bashrc..."
cp "$REPO/VPN/.bashrc" /root/.bashrc
echo "  OK: /root/.bashrc updated"

# 3. Install MOTD
echo "[3/4] Installing MOTD..."
cp "$REPO/VPN/motd_server.sh" /etc/profile.d/motd_server.sh
chmod +x /etc/profile.d/motd_server.sh
echo "  OK: /etc/profile.d/motd_server.sh installed"

# 4. Reload aliases
echo "[4/4] Reloading .bashrc..."
source /root/.bashrc

echo ""
echo "=== Done! Testing aliases ==="
type aw     2>/dev/null && echo "  aw:     OK" || echo "  aw:     MISSING"
type audit  2>/dev/null && echo "  audit:  OK" || echo "  audit:  MISSING"
type infooo 2>/dev/null && echo "  infooo: OK" || echo "  infooo: MISSING"
type backup 2>/dev/null && echo "  backup: OK" || echo "  backup: MISSING"
type load   2>/dev/null && echo "  load:   OK" || echo "  load:   MISSING"
type save   2>/dev/null && echo "  save:   OK" || echo "  save:   MISSING"
type mc     2>/dev/null && echo "  mc:     OK" || echo "  mc:     MISSING"
type banlog 2>/dev/null && echo "  banlog: OK" || echo "  banlog: MISSING"
echo ""
echo "  Reconnect SSH or run: source /root/.bashrc"
echo ""
