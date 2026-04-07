#!/bin/bash
# =============================================================================
# deploy_vpn_node.sh — Deploy/update all configs on VPN node
# =============================================================================
# Version  : v2026-04-07
# Author   : Ing. VladiMIR Bulantsev
# Usage    : bash /root/Linux_Server_Public/VPN/deploy_vpn_node.sh
# Run once after git clone OR anytime after 'load' to apply updates
# = Rooted by VladiMIR | AI =
# =============================================================================

clear
echo "= Rooted by VladiMIR | AI = v2026-04-07"
echo "=== VPN Node Deploy ==="
echo ""

REPO="/root/Linux_Server_Public"

# -- 1. Pull latest from GitHub -----------------------------------------------
echo "[1/5] git pull..."
cd "$REPO" && git pull --rebase
echo ""

# -- 2. Copy .bashrc ----------------------------------------------------------
echo "[2/5] Copying .bashrc..."
cp "$REPO/VPN/.bashrc" /root/.bashrc
echo "  OK: /root/.bashrc updated"

# -- 3. Install MOTD (our script) ---------------------------------------------
echo "[3/5] Installing MOTD..."
cp "$REPO/VPN/motd_server.sh" /etc/profile.d/motd_server.sh
chmod +x /etc/profile.d/motd_server.sh
echo "  OK: /etc/profile.d/motd_server.sh installed"

# -- 4. Remove ALL old/duplicate MOTD scripts ---------------------------------
# IMPORTANT: Only motd_server.sh must exist on VPN nodes!
# Known old files that cause double-banner on SSH login:
#   /etc/profile.d/motd_vpn.sh    — created manually on 24.03.2026
#   /etc/profile.d/motd_banner.sh — created by scripts/setup_motd.sh
#   /etc/profile.d/ps1_color.sh   — conflicts with PS1 from .bashrc
echo "[4/5] Removing old/duplicate MOTD scripts..."

# Explicit removal of known old files
for OLD in \
    /etc/profile.d/motd_vpn.sh \
    /etc/profile.d/motd_banner.sh \
    /etc/profile.d/ps1_color.sh
do
    if [ -f "$OLD" ]; then
        rm -f "$OLD" && echo "  removed: $OLD"
    fi
done

# Disable /etc/update-motd.d/ scripts (Ubuntu default dynamic MOTD)
if [ -d /etc/update-motd.d ]; then
    for f in /etc/update-motd.d/*; do
        if [[ "$f" != *motd_server* ]]; then
            chmod -x "$f" 2>/dev/null
        fi
    done
    echo "  disabled: /etc/update-motd.d/*"
fi

# Wipe static /etc/motd (shows old text on login)
if [ -s /etc/motd ]; then
    echo "" > /etc/motd
    echo "  cleared: /etc/motd"
fi

# Safety net: disable any remaining profile.d duplicates (not motd_server.sh)
for f in /etc/profile.d/motd*.sh /etc/profile.d/*banner*.sh /etc/profile.d/*info*.sh; do
    [ -f "$f" ] || continue
    [ "$f" = "/etc/profile.d/motd_server.sh" ] && continue
    rm -f "$f" && echo "  removed duplicate: $f"
done

echo "  OK: old MOTD cleaned"

# -- 5. Check that all script files exist ------------------------------------
echo "[5/5] Checking script files..."
echo ""

check_file() {
    local label="$1"
    local path="$2"
    if [ -f "$path" ]; then
        echo "  OK  $label → $path"
    else
        echo "  !!  $label → MISSING: $path"
    fi
}

check_file "aw"        "$REPO/VPN/amnezia_stat.sh"
check_file "audit"     "$REPO/VPN/vpn_node_clean_audit.sh"
check_file "infooo"    "$REPO/VPN/infooo.sh"
check_file "backup"    "$REPO/VPN/system_backup.sh"
check_file "load/save" "$REPO/scripts/shared_aliases.sh"
check_file "MOTD"      "/etc/profile.d/motd_server.sh"

if command -v mc >/dev/null 2>&1; then
    echo "  OK  mc → $(command -v mc)"
else
    echo "  !!  mc → NOT INSTALLED  → run: apt install mc -y"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Deploy complete! Reconnect SSH to see new MOTD."
echo "  Run now:  source /root/.bashrc"
echo "  Then:     aw  |  load  |  mc  |  audit"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
