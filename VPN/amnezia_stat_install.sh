#!/bin/bash
# AmneziaWG Stats — Install Script v2026-04-13j
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/VPN/amnezia_stat_install.sh)
set -e

echo "=== AmneziaWG Stats Installer v2026-04-13j ==="
echo "Server: $(hostname)"

# 1. Установить jq (несколько методов)
if ! command -v jq &>/dev/null; then
    echo "[+] Installing jq..."
    # Метод 1: apt
    apt-get install -y jq --no-install-recommends 2>/dev/null && jq --version && JQ_OK=1 || JQ_OK=0
    # Метод 2: wget бинарник
    if [[ $JQ_OK -ne 1 ]]; then
        echo "[!] apt failed, trying wget..."
        wget -qO /usr/local/bin/jq \
          https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64
        chmod +x /usr/local/bin/jq
        jq --version && echo "[ok] jq installed via wget"
    fi
else
    echo "[ok] jq already installed: $(jq --version)"
fi

# 2. Скачать основной скрипт
echo "[+] Downloading amnezia_stat.sh..."
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/VPN/amnezia_stat.sh \
  -o /root/amnezia_stat.sh
chmod +x /root/amnezia_stat.sh
echo "[ok] Script saved to /root/amnezia_stat.sh"

# 3. Алиас aw
if ! grep -qxF "alias aw='bash /root/amnezia_stat.sh'" /root/.bashrc; then
    echo "alias aw='bash /root/amnezia_stat.sh'" >> /root/.bashrc
    echo "[ok] Alias 'aw' added to .bashrc"
else
    echo "[ok] Alias 'aw' already exists"
fi

# 4. source .bashrc в .bash_profile
if ! grep -qxF "source /root/.bashrc" /root/.bash_profile 2>/dev/null; then
    echo "source /root/.bashrc" >> /root/.bash_profile
fi

# 5. Автозапуск контейнера
if docker inspect amnezia-awg &>/dev/null; then
    docker update --restart=unless-stopped amnezia-awg >/dev/null
    echo "[ok] amnezia-awg restart policy: unless-stopped"
fi

echo ""
echo "=== Done! Run: source /root/.bashrc && aw ==="
