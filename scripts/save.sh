#!/usr/bin/env bash
clear
# =============================================================
# Script:      save.sh
# Version:     v2026.05.20
# Location:    scripts/save.sh
# Servers:     ALL (222-DE / 109-RU / VPN nodes)
# Description: git add + commit + push (force if needed).
#              Iron-clad — never fails silently.
# Usage:       alias save='bash ~/Linux_Server_Public/scripts/save.sh'
# = Rooted by VladiMIR + AI | v2026.05.20 | github.com/GinCz =
# =============================================================

REPO="/root/Linux_Server_Public"

if [ ! -d "$REPO/.git" ]; then
    echo "ERROR: $REPO is not a git repo."
    exit 1
fi

cd "$REPO" || exit 1

echo "--- IRON SAVE START ---"
git add .
git commit -m "Sync from $(hostname) - $(date +'%Y-%m-%d %H:%M')" || true
git push origin main || git push --force origin main

echo -e "\033[1;32m✅ SAVED TO GITHUB!\033[0m"
