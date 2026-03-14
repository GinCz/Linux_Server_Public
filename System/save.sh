#!/usr/bin/env bash
# Description: Auto-save all changes to GitHub
# Author: Ing. VladiMIR Bulantsev | 2026

clear
echo -e "\033[1;33m>>> Saving changes to GitHub...\033[0m"
cd /root/scripts || exit

# Add all changes
git add .

# Commit with current server name and timestamp
git commit -m "Auto-save from $(hostname) at $(date +'%Y-%m-%d %H:%M:%S')"

# Push to origin main
git push origin main

# Clear bash cache
hash -r
echo -e "\033[0;32m>>> Successfully saved to GitHub!\033[0m"
