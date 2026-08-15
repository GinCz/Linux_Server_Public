#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  save.sh | [v2026-05-20]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Git commit and push helper for server repo sync
# Servers     : All Linux Nodes
# Usage       : bash scripts/save.sh
# ==========================================================================================
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

# = Rooted by VladiMIR | AI = v2026-05-20 = github.com/GinCz/Linux_Server_Public
