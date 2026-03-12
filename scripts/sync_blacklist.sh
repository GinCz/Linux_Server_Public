#!/usr/bin/env bash
# VladiMIR Global Blacklist Sync
cd /root/scripts

# 1. Получаем свежий список с GitHub
git pull origin main > /dev/null 2>&1

# 2. Если глобальный файл существует, вливаем его в локальный
if [ -f "/root/scripts/global_blacklist.txt" ]; then
    cat /root/scripts/global_blacklist.txt >> /root/fight_blacklist.txt
    # Удаляем дубликаты
    sort -u -o /root/fight_blacklist.txt /root/fight_blacklist.txt
fi
