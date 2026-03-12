#!/usr/bin/env bash
# VladiMIR Master Setup 2026 - Bulletproof Standard
source /root/scripts/common.sh

echo -e "${CYAN}>>> [1/7] Настройка Hostname...${NC}"
if [ -f /root/.server_env ]; then
    source /root/.server_env
    CLEAN_TAG=$(echo "$SERVER_TAG" | tr '_' '-')
    hostname "$CLEAN_TAG"
    echo "$CLEAN_TAG" > /etc/hostname
    sed -i "s/127.0.1.1.*/127.0.1.1 $CLEAN_TAG/" /etc/hosts
fi

echo -e "${CYAN}>>> [2/7] Установка пакетов...${NC}"
apt update && apt install -y ufw mc ncdu htop acl samba samba-common git curl sysbench > /dev/null
git config --global credential.helper store
git config --global pull.rebase false
git config --global user.email "gin.vladimir@gmail.com"
git config --global user.name "Vladimir"

echo -e "${CYAN}>>> [3/7] Пользователи (vlad/usr)...${NC}"
id -u usr &>/dev/null || useradd -m -s /bin/bash usr && echo "usr:sa4434" | chpasswd
id -u vlad &>/dev/null || useradd -m -s /bin/bash vlad && echo "vlad:sa4434" | chpasswd
(echo "sa4434"; echo "sa4434") | smbpasswd -a -s vlad
(echo "sa4434"; echo "sa4434") | smbpasswd -a -s usr

echo -e "${CYAN}>>> [4/7] Storage & ACL...${NC}"
mkdir -p /storage/soft /storage/user
chown -R vlad:vlad /storage
chmod -R 770 /storage
setfacl -bR /storage
setfacl -m u:usr:x /storage
setfacl -R -m u:usr:rx /storage/soft 2>/dev/null
setfacl -R -m u:usr:rwx /storage/user 2>/dev/null

echo -e "${CYAN}>>> [5/7] Samba Config...${NC}"
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

echo -e "${CYAN}>>> [6/7] Алиасы и MC Menu...${NC}"
sed -i '/alias 00=/d' ~/.bashrc
sed -i '/alias inf=/d' ~/.bashrc
sed -i '/alias infooo=/d' ~/.bashrc
echo "alias 00='clear'" >> ~/.bashrc
echo "alias inf='bash /root/scripts/scripts/server_audit.sh'" >> ~/.bashrc
echo "alias infooo='bash /root/scripts/scripts/infooo.sh'" >> ~/.bashrc

mkdir -p ~/.config/mc/
cat > ~/.config/mc/menu << EOM
+ t t
i  Benchmark & Info
	bash /root/scripts/scripts/infooo.sh
a  Deep Audit
	bash /root/scripts/scripts/server_audit.sh
EOM

echo -e "${CYAN}>>> [7/7] Автоматизация...${NC}"
chmod +x /root/scripts/scripts/*.sh
ln -sf /root/scripts/scripts/infooo.sh /usr/local/bin/infooo 2>/dev/null
ln -sf /root/scripts/scripts/server_audit.sh /usr/local/bin/audit 2>/dev/null
(crontab -l 2>/dev/null | grep -vE "audit|git pull"; 
 echo "0 2 * * * /usr/local/bin/audit > /dev/null 2>&1";
 echo "0 4 * * * cd /root/scripts && git pull > /dev/null 2>&1") | crontab -

echo -e "${GREEN}--- СИСТЕМА ОБНОВЛЕНА ---${NC}"
