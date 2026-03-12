#!/usr/bin/env bash
# VladiMIR Master Setup 2026 - Bulletproof Version
source /root/scripts/common.sh

echo -e "${CYAN}>>> [1/7] Настройка Hostname (OpenVZ Friendly)...${NC}"
if [ -f /root/.server_env ]; then
    source /root/.server_env
    # Заменяем подчеркивания на тире (обязательно для Linux)
    CLEAN_TAG=$(echo "$SERVER_TAG" | tr '_' '-')
    hostname "$CLEAN_TAG"
    echo "$CLEAN_TAG" > /etc/hostname
    sed -i "s/127.0.1.1.*/127.0.1.1 $CLEAN_TAG/" /etc/hosts
    echo -e "${G}Имя сервера установлено: $CLEAN_TAG${X}"
fi

echo -e "${CYAN}>>> [2/7] Базовые пакеты и Настройка Git...${NC}"
apt update && apt install -y ufw mc ncdu htop acl samba samba-common git curl sysbench > /dev/null
git config --global credential.helper store
git config --global pull.rebase false

echo -e "${CYAN}>>> [3/7] Создание пользователей и Samba (vlad/usr)...${NC}"
id -u usr &>/dev/null || useradd -m -s /bin/bash usr && echo "usr:sa4434" | chpasswd
id -u vlad &>/dev/null || useradd -m -s /bin/bash vlad && echo "vlad:sa4434" | chpasswd
(echo "sa4434"; echo "sa4434") | smbpasswd -a -s vlad
(echo "sa4434"; echo "sa4434") | smbpasswd -a -s usr

echo -e "${CYAN}>>> [4/7] Настройка Storage и ACL...${NC}"
mkdir -p /storage/user /storage/soft
chown -R vlad:vlad /storage
chmod -R 770 /storage
setfacl -bR /storage
setfacl -m u:usr:x /storage
setfacl -R -m u:usr:rx /storage/soft 2>/dev/null
setfacl -R -m u:usr:rwx /storage/user 2>/dev/null

echo -e "${CYAN}>>> [5/7] Тюнинг Midnight Commander (F2 Menu)...${NC}"
mkdir -p ~/.config/mc/
cat > ~/.config/mc/menu << EOM
+ t t
i  Info & Benchmark
	bash /root/scripts/scripts/infooo.sh
a  Deep Audit
	bash /root/scripts/scripts/server_audit.sh
s  Samba Status
	systemctl status smbd
EOM

echo -e "${CYAN}>>> [6/7] Алиасы (00, inf, infooo)...${NC}"
sed -i '/alias 00=/d' ~/.bashrc
sed -i '/alias inf=/d' ~/.bashrc
sed -i '/alias infooo=/d' ~/.bashrc
echo "alias 00='clear'" >> ~/.bashrc
echo "alias inf='bash /root/scripts/scripts/server_audit.sh'" >> ~/.bashrc
echo "alias infooo='bash /root/scripts/scripts/infooo.sh'" >> ~/.bashrc

echo -e "${CYAN}>>> [7/7] Настройка Cron...${NC}"
chmod +x /root/scripts/scripts/*.sh
ln -sf /root/scripts/scripts/infooo.sh /usr/local/bin/infooo
ln -sf /root/scripts/scripts/server_audit.sh /usr/local/bin/audit
(crontab -l 2>/dev/null | grep -vE "audit|git pull"; 
 echo "0 2 * * * /usr/local/bin/audit > /dev/null 2>&1";
 echo "0 4 * * * cd /root/scripts && git pull > /dev/null 2>&1") | crontab -

echo -e "${GREEN}--- СЕРВЕР ГОТОВ К РАБОТЕ ---${NC}"
echo -e "${Y}Введите 'exec bash' для активации всех настроек.${X}"
