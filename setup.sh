#!/usr/bin/env bash
source /root/.server_env

echo "--- Configuring Unified Samba Storage [/storage] ---"
apt update && apt install samba -y

# Создаем папки
mkdir -p /storage/soft /storage/user
chmod -R 777 /storage

# Создаем системных пользователей (если их нет)
useradd -M -s /sbin/nologin vlad 2>/dev/null
useradd -M -s /sbin/nologin usr 2>/dev/null

# Устанавливаем пароль Samba из нашей секретной переменной
if [ ! -z "$SMB_PASS" ]; then
    (echo "$SMB_PASS"; echo "$SMB_PASS") | smbpasswd -a -s vlad
    (echo "$SMB_PASS"; echo "$SMB_PASS") | smbpasswd -a -s usr
    echo "✅ Samba passwords set for 'vlad' and 'usr'"
else
    echo "⚠️ WARNING: SMB_PASS not found in .server_env! Samba users have no passwords."
fi

# Генерируем чистый конфиг
cat > /etc/samba/smb.conf << 'EOC'
[global]
   workgroup = WORKGROUP
   security = user
   map to guest = bad user

[soft]
   path = /storage/soft
   browseable = yes
   read only = no
   valid users = vlad, usr
   write list = vlad

[user]
   path = /storage/user
   browseable = yes
   read only = no
   valid users = vlad, usr
   write list = vlad, usr
EOC

systemctl restart smbd
echo "✅ Samba setup complete."
