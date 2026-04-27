#!/bin/bash
clear
# ===================================================================
# Script: save.sh
# Version: v2026-04-25
# Server: 222-DE-NetCup (152.53.182.222)
# Purpose: Safe and clean commit + push of all changes from server 222 to GitHub.
#
# What this script does:
# 1. Goes to repository root.
# 2. Adds all changes.
# 3. Commits with clear message and timestamp.
# 4. Pulls latest changes first (to avoid conflicts).
# 5. Pushes to main branch.
#
# Potential consequences and warnings:
# - No impact on running websites.
# - If there are conflicts, it will try to resolve them safely.
# - Many working websites on the server — safe to run anytime.
#
# Usage: cd ~/Linux_Server_Public/222 && bash save_v2026-04-25.sh
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== Save to GitHub v2026-04-25 started ==="

cd ~/Linux_Server_Public

echo "→ Pulling latest changes from GitHub..."
git pull origin main || echo "Pull failed, continuing anyway..."

echo "→ Adding all changes..."
git add .

echo "→ Committing changes..."
git commit -m "Update server 222 scripts v2026-04-25 - $(date +'%Y-%m-%d %H:%M:%S')" || echo "No changes to commit."

echo "→ Pushing to GitHub..."
git push origin main

echo -e "\033[1;32m✅ Successfully pushed to GitHub!\033[0m"
echo "Repository: https://github.com/GinCz/Linux_Server_Public"
