#!/usr/bin/env bash
# Description: Force load all changes from GitHub
# Author: Ing. VladiMIR Bulantsev | 2026

clear
echo -e "\033[1;33m>>> Force pulling changes from GitHub...\033[0m"
cd /root/scripts || exit

# Fetch and force reset to origin/main (ignores local conflicts)
git fetch --all
git reset --hard origin/main

# Update execution permissions for all scripts
find /root/scripts -type f -name "*.sh" -exec chmod +x {} \;

# Clear bash cache
hash -r
echo -e "\033[0;32m>>> Successfully loaded from GitHub! Cache cleared.\033[0m"
