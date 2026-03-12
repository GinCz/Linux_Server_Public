#!/usr/bin/env bash
# VladiMIR Master Setup 2026 - Standard Node
source /root/scripts/common.sh

echo -e "${CYAN}>>> [1/7] Базовые пакеты и Firewall...${NC}"
apt update && apt install -y ufw mc ncdu htop acl samba samba-common git curl
ufw allow ssh && ufw allow 137,138/udp && ufw allow 139,445/tcp
ufw --force enable

echo -e "${CYAN}>>> [2/7] Создание пользователей (vlad & usr)...${NC}"
# Очистка и создание
deluser user --remove-home 2>/dev/null
id -u usr &>/dev/null || useradd -m -s /bin/bash usr && echo "usr:sa4434" | chpasswd
id -u vlad &>/dev/null || useradd -m -s /bin/bash vlad && echo "vlad:sa4434" | chpasswd
(echo "sa4434"; echo "sa4434") | smbpasswd -a -s vlad
(echo "sa4434"; echo "sa4434") | smbpasswd -a -s usr

echo -e "${CYAN}>>> [3/7] Настройка Storage и ACL...${NC}"
rm -rf /SOFT
mkdir -p /storage/user /storage/soft
chown -R vlad:vlad /storage
chmod -R 770 /storage
setfacl -bR /storage
setfacl -m u:usr:x /storage
setfacl -R -m u:usr:rx /storage/soft
setfacl -R -d -m u:usr:rx /storage/soft
setfacl -R -m u:usr:rwx /storage/user
setfacl -R -d -m u:usr:rwx /storage/user

echo -e "${CYAN}>>> [4/7] Конфигурация Samba...${NC}"
cat > /etc/samba/smb.conf << EOL
[global]
   workgroup = WORKGROUP
   security = user
   map to guest = bad user
[storage]
   path = /storage
   browsable = yes
   writable = yes
   valid users = vlad, usr
   vfs objects = acl_xattr
   map acl inherit = yes
EOL
systemctl restart smbd nmbd

echo -e "${CYAN}>>> [5/7] Тюнинг Midnight Commander (Меню)...${NC}"
mkdir -p ~/.config/mc/
cat > ~/.config/mc/menu << EOL
+ t t
a  Audit System
i  Info & Benchmark
	infooo
	audit
d  Check Domains
	domains
s  Service Status (Samba)
	systemctl status smbd
EOL

echo -e "${CYAN}>>> [6/7] Алиасы и Окружение...${NC}"
# Добавляем алиасы в .bashrc для root
for alias_line in "alias 00='clear'" "alias inf='audit'" "alias audit='bash /root/scripts/scripts/server_audit.sh'" "alias domains='bash /root/scripts/scripts/domains_check.sh'"; do
alias infooo='bash /root/scripts/scripts/infooo.sh'
    grep -q "$alias_line" ~/.bashrc || echo "$alias_line" >> ~/.bashrc
done

echo -e "${CYAN}>>> [7/7] Настройка Cron (Аудит 02:00, Синхр 04:00)...${NC}"
ln -sf /root/scripts/scripts/server_audit.sh /usr/local/bin/audit
ln -sf /root/scripts/scripts/domains_check.sh /usr/local/bin/domains
(crontab -l 2>/dev/null | grep -vE "audit|git pull|domains"; 
 echo "0 2 * * * /usr/local/bin/audit > /dev/null 2>&1";
 echo "0 4 * * * cd /root/scripts && git pull > /dev/null 2>&1";
 echo "0 9 * * * /usr/local/bin/domains > /dev/null 2>&1") | crontab -

echo -e "${GREEN}--- СЕРВЕР ПОДКЛЮЧЕН К АЛЬЯНСУ ---${NC}"
