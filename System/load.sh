#!/usr/bin/env bash
# Description: Force load from GitHub + Config Importer
# Author: Ing. VladiMIR Bulantsev | 2026

clear
echo -e "\033[1;33m>>> Force pulling changes from GitHub...\033[0m"

cd /root/scripts || exit
git fetch --all
git reset --hard origin/main
find /root/scripts -type f -name "*.sh" -exec chmod +x {} \;

# Import configs from repository back into the system
echo ">>> Applying synced Bash Aliases and MC Menu..."
if [ -f /root/scripts/System/Configs/bash_aliases ]; then
    cp /root/scripts/System/Configs/bash_aliases ~/.bash_aliases
    # Make sure bash reads the aliases
    grep -q "bash_aliases" ~/.bashrc || echo "if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi" >> ~/.bashrc
fi

if [ -f /root/scripts/System/Configs/mc_menu ]; then
    mkdir -p ~/.config/mc
    cp /root/scripts/System/Configs/mc_menu ~/.config/mc/menu
fi

# Run legacy setup scripts if you still use them
[ -f "/root/scripts/System/apply_aliases.sh" ] && bash /root/scripts/System/apply_aliases.sh
[ -f "/root/scripts/System/setup_mc_menu.sh" ] && bash /root/scripts/System/setup_mc_menu.sh

hash -r
echo -e "\033[0;32m>>> Successfully loaded! System completely synchronized.\033[0m"
echo -e "\033[0;36mℹ️  Note: Type 'source ~/.bashrc' or restart terminal to apply new aliases right now.\033[0m"
