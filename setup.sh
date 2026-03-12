#!/usr/bin/env bash
source /root/.server_env

echo "--- Настройка Samba (/storage) ---"
apt update && apt install samba -y

mkdir -p /storage/soft /storage/user
chmod 755 /storage
chmod -R 777 /storage/soft /storage/user
chown -R root:root /storage

useradd -M -s /sbin/nologin vlad 2>/dev/null
useradd -M -s /sbin/nologin usr 2>/dev/null

if [ ! -z "$SMB_PASS" ]; then
    (echo "$SMB_PASS"; echo "$SMB_PASS") | smbpasswd -a -s vlad
    (echo "$SMB_PASS"; echo "$SMB_PASS") | smbpasswd -a -s usr
    smbpasswd -e vlad
    smbpasswd -e usr
fi

cat > /etc/samba/smb.conf << 'EOC'
[global]
   workgroup = WORKGROUP
   security = user
   map to guest = bad user
   server min protocol = SMB2

[soft]
   path = /storage/soft
   browseable = yes
   read only = yes
   write list = vlad
   valid users = vlad, usr

[user]
   path = /storage/user
   browseable = yes
   read only = no
   valid users = vlad, usr
   write list = vlad, usr
EOC

systemctl restart smbd nmbd
echo "✅ Samba настроена локально."
