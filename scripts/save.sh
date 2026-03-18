#!/usr/bin/env bash
# Script:  save.sh
# Version: v2026-03-18
# Purpose: Nuclear save - force push local state to GitHub
# Alias:   save

cd /opt/server_tools
echo "--- YADERNOE SOHRANENIE ---"
git add .
git commit -m "Save: $(hostname) - $(date +'%Y-%m-%d %H:%M')" || true
git push origin main || git push --force origin main
echo "OK: ZHELEZNO ZALITO NA GITHUB!"
