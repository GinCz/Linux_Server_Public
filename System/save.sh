#!/usr/bin/env bash
# Description: Auto-save to GitHub + Config Exporter
# Author: Ing. VladiMIR Bulantsev | 2026

clear
echo -e "\033[1;33m>>> Preparing to save changes...\033[0m"

# Export active system configs into the repository
echo ">>> Backing up Bash Aliases and MC Menu to repository..."
mkdir -p /root/scripts/System/Configs
[ -f ~/.bash_aliases ] && cp ~/.bash_aliases /root/scripts/System/Configs/bash_aliases
[ -f ~/.config/mc/menu ] && cp ~/.config/mc/menu /root/scripts/System/Configs/mc_menu

cd /root/scripts || exit
git add .
git commit -m "Auto-save + Config sync from $(hostname) at $(date +'%Y-%m-%d %H:%M:%S')"
git pull --rebase origin main
git push origin main

hash -r
echo -e "\033[0;32m>>> Successfully saved everything to GitHub!\033[0m"
