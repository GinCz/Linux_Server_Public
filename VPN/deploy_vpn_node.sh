#!/bin/bash
# =============================================================================
# deploy_vpn_node.sh — Deploy/update all configs on VPN node
# Version  : v2026-04-07
# Usage    : bash /root/Linux_Server_Public/VPN/deploy_vpn_node.sh
# Run once after git clone OR anytime after 'load' to apply updates
# NOTE: aliases are NOT inherited in subshell — this script checks FILE paths,
#       not aliases. After deploy: reconnect SSH or run: source /root/.bashrc
# = Rooted by VladiMIR | AI =
# =============================================================================

clear
echo "= Rooted by VladiMIR | AI = v2026-04-07"
echo "=== VPN Node Deploy ==="
echo ""

REPO="/root/Linux_Server_Public"

# ── 1. Pull latest from GitHub ────────────────────────────────────────────────
echo "[1/4] git pull..."
cd "$REPO" && git pull --rebase
echo ""

# ── 2. Copy .bashrc ───────────────────────────────────────────────────────────
echo "[2/4] Copying .bashrc..."
cp "$REPO/VPN/.bashrc" /root/.bashrc
echo "  OK: /root/.bashrc updated"

# ── 3. Install MOTD ───────────────────────────────────────────────────────────
echo "[3/4] Installing MOTD..."
cp "$REPO/VPN/motd_server.sh" /etc/profile.d/motd_server.sh
chmod +x /etc/profile.d/motd_server.sh
echo "  OK: /etc/profile.d/motd_server.sh installed"

# ── 4. Check that all script FILES exist (aliases work only in live shell) ────
echo "[4/4] Checking script files..."
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

check_file "aw"      "$REPO/VPN/amnezia_stat.sh"
check_file "audit"   "$REPO/VPN/vpn_node_clean_audit.sh"
check_file "infooo"  "$REPO/VPN/infooo.sh"
check_file "backup"  "$REPO/VPN/system_backup.sh"
check_file "load/save" "$REPO/scripts/shared_aliases.sh"

# Check mc binary
if command -v mc >/dev/null 2>&1; then
  echo "  OK  mc → $(command -v mc)"
else
  echo "  !!  mc → NOT INSTALLED (run: apt install mc -y)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Deploy complete!"
echo "  Aliases (aw/audit/infooo/load/save/00/la) activate in a NEW shell."
echo "  Run now:  source /root/.bashrc"
echo "  Then check:  type aw  |  aw  |  load  |  mc"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
