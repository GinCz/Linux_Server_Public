#!/usr/bin/env bash
# English comments: Adds custom Git & Sync commands to MC User Menu (F2)

MC_MENU="$HOME/.config/mc/menu"
mkdir -p $(dirname $MC_MENU)

# Проверяем, нет ли уже наших команд, чтобы не дублировать
if ! grep -q "GIT SYNC" "$MC_MENU" 2>/dev/null; then
    cat >> "$MC_MENU" << 'MENU'

+ ! t t
G       GIT SYNC (Scripts_Backup)
        clear
        echo "Starting Git Sync..."
        cd /var/www/gincz/data/www/gincz.com/server-set/Scripts_Backup && git add . && git commit -m "MC Update: $(date +%D_%T)" && git push
        echo "Done! Press any key..."
        read -n 1

P       GIT PULL (Public Repo)
        clear
        echo "Pulling latest scripts from GitHub..."
        cd /root/scripts && git pull
        echo "Done! Press any key..."
        read -n 1
MENU
    echo "✅ MC User Menu updated (F2)."
else
    echo "ℹ️ MC User Menu already has Git commands."
fi
