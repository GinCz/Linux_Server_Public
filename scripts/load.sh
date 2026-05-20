#!/usr/bin/env bash
clear
# =============================================================
# Script:      load.sh
# Version:     v2026.05.21
# Location:    scripts/load.sh
# Servers:     ALL (222-DE / 109-RU / VPN nodes)
# Description: Pull latest changes from GitHub and reload shell.
# Usage:       alias load='bash ~/Linux_Server_Public/scripts/load.sh'
# = Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =
# =============================================================

REPO="/root/Linux_Server_Public"

if [ ! -d "$REPO/.git" ]; then
    echo "ERROR: $REPO is not a git repo. Clone first:"
    echo "  git clone https://github.com/GinCz/Linux_Server_Public.git $REPO"
    exit 1
fi

cd "$REPO" || exit 1
echo "=== git pull origin main ==="
git pull origin main

echo ""
echo -e "\033[1;32m✅ LOADED OK — $(hostname) — $(date '+%Y-%m-%d %H:%M')\033[0m"
echo -e "\033[1;33mReloading shell (exec bash -l)...\033[0m"
echo ""

# Reload current shell session with fresh .bashrc (aliases, MOTD)
# exec bash -l replaces current process — aliases become active immediately
exec bash -l
