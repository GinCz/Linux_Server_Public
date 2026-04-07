#!/bin/bash
# =============================================================================
# deploy_vpn_node.sh — Deploy/update all configs on VPN node
# Version  : v2026-04-07
# Usage    : bash /root/Linux_Server_Public/VPN/deploy_vpn_node.sh
# Run once after git clone OR anytime after 'load' to apply updates
# = Rooted by VladiMIR | AI =
# =============================================================================

clear
echo "= Rooted by VladiMIR | AI = v2026-04-07"
echo "=== VPN Node Deploy ==="
echo ""

REPO="/root/Linux_Server_Public"

# ── 1. Pull latest from GitHub ────────────────────────────────────────────────
echo "[1/5] git pull..."
cd "$REPO" && git pull --rebase
echo ""

# ── 2. Copy .bashrc ───────────────────────────────────────────────────────────
echo "[2/5] Copying .bashrc..."
cp "$REPO/VPN/.bashrc" /root/.bashrc
echo "  OK: /root/.bashrc updated"

# ── 3. Install MOTD (our script) ───────────────────────────────────────────────
echo "[3/5] Installing MOTD..."
cp "$REPO/VPN/motd_server.sh" /etc/profile.d/motd_server.sh
chmod +x /etc/profile.d/motd_server.sh
echo "  OK: /etc/profile.d/motd_server.sh installed"

# ── 4. Disable old system MOTD scripts that show a second banner ───────────────
echo "[4/5] Removing old MOTD scripts..."

# Disable /etc/update-motd.d/ scripts (Ubuntu default dynamic MOTD)
if [ -d /etc/update-motd.d ]; then
  for f in /etc/update-motd.d/*; do
    # Keep only our own script if copied there
    if [[ "$f" != *motd_server* ]]; then
      chmod -x "$f" 2>/dev/null && echo "  disabled: $f"
    fi
  done
fi

# Wipe static /etc/motd (shows old text on login)
if [ -s /etc/motd ]; then
  echo "" > /etc/motd
  echo "  cleared: /etc/motd"
fi

# Remove any old profile.d banners (check for duplicates)
for f in /etc/profile.d/motd*.sh /etc/profile.d/*banner* /etc/profile.d/*info*; do
  [ -f "$f" ] || continue
  [ "$f" = "/etc/profile.d/motd_server.sh" ] && continue
  chmod -x "$f" 2>/dev/null && echo "  disabled duplicate: $f"
done

echo "  OK: old MOTD cleaned"

# ── 5. Check that all script FILES exist ───────────────────────────────────────
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

if command -v mc >/dev/null 2>&1; then
  echo "  OK  mc → $(command -v mc)"
else
  echo "  !!  mc → NOT INSTALLED  → run: apt install mc -y"
fi

echo ""
echo "\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501"
echo "  Deploy complete! Reconnect SSH to see new MOTD."
echo "  Run now:  source /root/.bashrc"
echo "  Then:     aw  |  load  |  mc  |  audit"
echo "\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501"
echo ""
