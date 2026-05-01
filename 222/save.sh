#!/bin/bash
clear
# save.sh v2026-05-01
# Sync all *.sh from /root/scripts/ → GitHub repo (server folder)
# = Rooted by VladiMIR | AI =

SERVER_ID="222"   # Change to: 109 | VPN on other servers

SCRIPTS_DIR="/root/scripts"
REPO="/root/Linux_Server_Public/$SERVER_ID"

echo "╔══════════════════════════════════════╗"
echo "║  SAVE  →  GitHub [$SERVER_ID]        "
echo "╚══════════════════════════════════════╝"
echo ""

# Copy all .sh scripts to repo folder
COUNT=0
for f in "$SCRIPTS_DIR"/*.sh; do
    [ -f "$f" ] || continue
    cp "$f" "$REPO/"
    echo "  ✅ $(basename $f)"
    ((COUNT++))
done

echo ""
echo "  Total: $COUNT scripts copied to $REPO"
echo ""

# Push to GitHub
cd /root/Linux_Server_Public
git add "$SERVER_ID/"
git diff --cached --quiet "$SERVER_ID/" && {
    echo "  ℹ️  Nothing changed — skip commit."
    exit 0
}
git commit -m "save [$SERVER_ID]: $(date '+%Y-%m-%d %H:%M')"
git pull origin main --no-rebase --no-edit -q
git push origin main
echo ""
echo "  ✅ Pushed to GitHub → $SERVER_ID/"
