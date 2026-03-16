#!/usr/bin/env bash
REPO="/root/Linux_Server_Public"
IP=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)

echo "--- СТАРТ ЯДЕРНОЙ ЗАГРУЗКИ ---"
# Срываем все замки
chattr -i /root/.bashrc /root/.config/mc/ini /root/.config/mc/menu 2>/dev/null

# Выжигаем кэш и локальные изменения, принудительно ставим эталон
cd $REPO
git fetch --all
git reset --hard origin/main
git clean -e VPN_servers -fd

# Пишем чистый .bashrc с нуля (универсальная база)
cat <<EOT > /root/.bashrc
alias 00='clear'
alias infooo='$REPO/System/infooo.sh'
alias load='$REPO/System/load.sh'
alias save='$REPO/System/save.sh'
alias m='mc'
EOT

# Определяем сервер и добиваем специфичными алиасами
if [[ "$HOSTNAME" == *"222"* ]] || [[ "$HOSTNAME" == *"109"* ]]; then
    # Это для будущих 222 и 109, пока просто прописываем логику
    echo "alias sos='$REPO/System/quick_status.sh'" >> /root/.bashrc
    echo "alias fight='$REPO/Security/block_bots.sh'" >> /root/.bashrc
    echo "alias domains='$REPO/System/domain_monitor.sh'" >> /root/.bashrc
    echo "alias antivir='cscli decisions list'" >> /root/.bashrc
    echo "alias banlog='cscli alerts list -l 20'" >> /root/.bashrc
    echo "alias backup='$REPO/System/system_backup.sh'" >> /root/.bashrc
    echo ">> Профиль: Основной сервер (222/109)"
else
    # ЭТО VPN! Добавляем только stat и создаем папку для отчетов
    echo "alias stat='$REPO/System/amnezia_stat.sh'" >> /root/.bashrc
    mkdir -p $REPO/VPN_servers/${IP}_${HOSTNAME}
    echo ">> Профиль: VPN Узел"
fi

# Цементируем
source /root/.bashrc
chattr +i /root/.bashrc
echo -e "\033[1;32m✅ ПОРЯДОК УСТАНОВЛЕН. Введите: source ~/.bashrc\033[0m"
