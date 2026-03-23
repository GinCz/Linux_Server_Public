#!/usr/bin/env bash
cd /root/Linux_Server_Public
echo "--- СТАРТ ЯДЕРНОГО СОХРАНЕНИЯ ---"
# Принудительно добавляем всё
git add . 
# Коммитим, игнорируя ошибку, если изменений нет
git commit -m "Global Sync from $(hostname) - $(date +'%Y-%m-%d %H:%M')" || true
# Пушим в наглую. Если конфликт — затираем GitHub локальной версией
git push origin main || git push --force origin main
echo -e "\033[1;32m✅ ЖЕЛЕЗНО ЗАЛИТО НА GITHUB!\033[0m"
