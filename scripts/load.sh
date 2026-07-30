#!/usr/bin/env bash
clear
# =============================================================
# Script:      load.sh
# Version:     v2026.07.30
# Location:    scripts/load.sh
# Servers:     ALL (222-DE / 109-RU / VPN nodes)
# Description: Pull latest changes from GitHub and reload shell.
#              Auto-reinstalls /usr/local/bin/sos after pull.
# Usage:       alias load='bash ~/Linux_Server_Public/scripts/load.sh'
# = Rooted by VladiMIR + AI | v.2026.07.30 | github.com/GinCz =
# =============================================================

REPO="/root/Linux_Server_Public"
SOS_SRC="$REPO/scripts/sos.sh"
SOS_BIN="/usr/local/bin/sos"

if [ ! -d "$REPO/.git" ]; then
    echo "ERROR: $REPO is not a git repo. Clone first:"
    echo "  git clone https://github.com/GinCz/Linux_Server_Public.git $REPO"
    exit 1
fi

cd "$REPO" || exit 1
echo "=== git pull origin main ==="
git pull origin main --no-rebase --no-edit

# Auto-reinstall sos binary after pull
if [ -f "$SOS_SRC" ]; then
    cp "$SOS_SRC" "$SOS_BIN"
    chmod +x "$SOS_BIN"
    SOS_VER=$(grep -oP 'v\.\K[0-9.]+' "$SOS_SRC" | head -1)
    echo -e "\033[1;36m   /usr/local/bin/sos updated (v${SOS_VER:-?})\033[0m"
else
    echo -e "\033[1;33m   WARNING: $SOS_SRC not found, sos not updated\033[0m"
fi

echo ""
echo -e "\033[1;32m✅ LOADED OK — $(hostname) — $(date '+%Y-%m-%d %H:%M')\033[0m"
echo -e "\033[1;33mReloading shell (exec bash -l)...\033[0m"
echo ""

exec bash -l
