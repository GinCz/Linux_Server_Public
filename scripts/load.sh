#!/usr/bin/env bash
# Script:  load.sh
# Version: v2026-03-18
# Purpose: Nuclear load - hard reset to origin/main, clean all untracked
# Alias:   load

cd /opt/server_tools
echo "--- BRONEYBOINAYA ZAGRUZKA ---"
git fetch origin
git branch --set-upstream-to=origin/main main 2>/dev/null || true
git reset --hard origin/main
git clean -fd
chmod +x scripts/*.sh 2>/dev/null
source /opt/server_tools/shared_aliases.sh
echo "OK: SINKHRONIZATSIYA ZAVERSHENA!"
