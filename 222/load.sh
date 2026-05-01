#!/bin/bash
clear
# load.sh v2026-05-01
# Sync all *.sh from GitHub repo (server folder) → /root/scripts/
# = Rooted by VladiMIR | AI =

SERVER_ID="222"   # Change to: 109 | VPN on other servers

SCRIPTS_DIR="/root/scripts"
REPO="/root/Linux_Server_Public/$SERVER_ID"

echo "╔══════════════════════════════════════╗"
echo "║  LOAD  ←  GitHub [$SERVER_ID]        "
echo "╚══════════════════════════════════════╝"
echo ""

# Pull latest from GitHub first
cd /root/Linux_Server_Public
echo "  🔄 git pull..."
git pull origin main --no-rebase --no-edit -q
echo ""

# Copy all .sh from repo folder to scripts
COUNT=0
for f in "$REPO"/*.sh; do
    [ -f "$f" ] || continue
    cp "$f" "$SCRIPTS_DIR/"
    chmod +x "$SCRIPTS_DIR/$(basename $f)"
    echo "  ✅ $(basename $f)"
    ((COUNT++))
done

echo ""
echo "  Total: $COUNT scripts loaded to $SCRIPTS_DIR"
echo "  All scripts are executable (chmod +x)"
