#!/bin/bash
# =============================================================================
# deploy_vpn_node.sh — Deploy/update all configs on VPN node
# =============================================================================
# Version  : v2026-04-07
# Author   : Ing. VladiMIR Bulantsev
# Usage    : bash /root/Linux_Server_Public/VPN/deploy_vpn_node.sh
# Run once after git clone OR called automatically by 'load' alias
# = Rooted by VladiMIR | AI =
# =============================================================================

clear
echo "= Rooted by VladiMIR | AI = v2026-04-07"
echo "=== VPN Node Deploy ==="
echo ""

REPO="/root/Linux_Server_Public"

# -- 1. Copy .bashrc ----------------------------------------------------------
echo "[1/4] Copying .bashrc..."
cp "$REPO/VPN/.bashrc" /root/.bashrc
echo "  OK: /root/.bashrc updated"

# -- 2. Install MOTD ----------------------------------------------------------
echo "[2/4] Installing MOTD..."
cp "$REPO/VPN/motd_server.sh" /etc/profile.d/motd_server.sh
chmod +x /etc/profile.d/motd_server.sh
echo "  OK: /etc/profile.d/motd_server.sh installed"

# -- 3. Remove ALL old/duplicate MOTD and PS1 files --------------------------
# Only motd_server.sh must exist on VPN nodes.
# Known duplicates that cause double-banner on SSH login:
#   motd_vpn.sh    — created manually 24.03.2026
#   motd_banner.sh — created by scripts/setup_motd.sh
#   ps1_color.sh   — conflicts with PS1 from .bashrc
echo "[3/4] Removing old/duplicate MOTD files..."
for OLD in \
    /etc/profile.d/motd_vpn.sh \
    /etc/profile.d/motd_banner.sh \
    /etc/profile.d/ps1_color.sh
do
    if [ -f "$OLD" ]; then
        rm -f "$OLD" && echo "  removed: $OLD"
    fi
done
# Safety: remove any remaining banner duplicates (keep only motd_server.sh)
for f in /etc/profile.d/motd*.sh /etc/profile.d/*banner*.sh; do
    [ -f "$f" ] || continue
    [ "$f" = "/etc/profile.d/motd_server.sh" ] && continue
    rm -f "$f" && echo "  removed duplicate: $f"
done
# Disable Ubuntu default dynamic MOTD
if [ -d /etc/update-motd.d ]; then
    chmod -x /etc/update-motd.d/* 2>/dev/null
fi
# Clear static /etc/motd
[ -s /etc/motd ] && echo "" > /etc/motd && echo "  cleared: /etc/motd"
echo "  OK: cleanup done"

# -- 4. Check files -----------------------------------------------------------
echo "[4/4] Checking files..."
check() { [ -f "$2" ] && echo "  OK  $1" || echo "  !!  $1 MISSING: $2"; }
check "aw"        "$REPO/VPN/amnezia_stat.sh"
check "audit"     "$REPO/VPN/vpn_node_clean_audit.sh"
check "infooo"    "$REPO/VPN/infooo.sh"
check "backup"    "$REPO/VPN/system_backup.sh"
check "load/save" "$REPO/scripts/shared_aliases.sh"
check "MOTD"      "/etc/profile.d/motd_server.sh"
command -v mc >/dev/null 2>&1 && echo "  OK  mc" || echo "  !!  mc NOT INSTALLED: apt install mc -y"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  DONE! Reconnect SSH to see new MOTD."
echo "  load = git pull + this script (all-in-one)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
