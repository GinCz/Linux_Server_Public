#!/usr/bin/env bash
# Daily sync: Code -> Whitelist -> Firewall rules
SCRIPTS_DIR="/root/scripts"
cd "$SCRIPTS_DIR"

git fetch --all > /dev/null 2>&1
git reset --hard origin/main > /dev/null 2>&1

# После обновления кода — сразу обновляем белый список в файерволе
bash /root/scripts/core/apply_whitelist.sh

echo "✅ System updated and Whitelist applied: $(date)"
