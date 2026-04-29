#!/bin/bash
# mc_menu_setup.sh — deploy mc.menu from repo to ~/.config/mc/menu
# Version: v2026-04-30
# = Rooted by VladiMIR | AI =
# NOTE: Do NOT write menu inline here.
#       Always edit: /root/Linux_Server_Public/222/mc.menu
#       Then run this script to deploy.

REPO_MENU="/root/Linux_Server_Public/222/mc.menu"
DEST_MENU="$HOME/.config/mc/menu"

mkdir -p "$HOME/.config/mc"

# Remove immutable flag if set
chattr -i "$DEST_MENU" 2>/dev/null || true

cp "$REPO_MENU" "$DEST_MENU"
chown root:root "$DEST_MENU"
chmod 644 "$DEST_MENU"

echo "=== mc.menu deployed ==="
echo "Source : $REPO_MENU"
echo "Target : $DEST_MENU"
grep -c 'read -n' "$DEST_MENU" && echo "WARNING: read -n found!" || echo "OK: no read -n (dash-safe)"
