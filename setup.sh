#!/usr/bin/env bash
source /root/.server_env

echo "--- Настройка единого хранилища /storage [FIXED] ---"
apt update && apt install samba -y

# 1. Создаем структуру
mkdir -p /storage/soft /storage/user

# 2. Права в Linux
chmod 755 /storage
chmod -R 777 /storage/soft
chmod -R 777 /storage/user
chown -R root:root /storage

# 3. Пользователи
useradd -M -s /sbin/nologin vlad 2>/dev/null
useradd -M -s /sbin/nologin usr 2>/dev/null
if [ ! -z "$SMB_PASS" ]; then
    (echo "$SMB_PASS"; echo "$SMB_PASS") | smbpasswd -a -s vlad
    (echo "$SMB_PASS"; echo "$SMB_PASS") | smbpasswd -a -s usr
    smbpasswd -e vlad
    smbpasswd -e usr
fi

# 4. Конфигурация Samba с жесткими правами
cat > /etc/samba/smb.conf << 'EOC'
[global]
   workgroup = WORKGROUP
   security = user
   map to guest = bad user
   server min protocol = SMB2

[soft]
   path = /storage/soft
   browseable = yes
   # По умолчанию только чтение для всех:
   read only = yes
   # Исключение (право записи) только для vlad:
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
echo "✅ Права исправлены: soft (usr: только чтение), user (usr: полные права)"
