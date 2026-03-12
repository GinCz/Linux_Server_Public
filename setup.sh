#!/usr/bin/env bash
# VladiMIR Infrastructure Setup - Fixed Permissions
source /root/.server_env

echo "--- Configuring Samba Storage [/storage] ---"
apt update && apt install samba -y

# 1. Create directory structure
mkdir -p /storage/soft /storage/user

# 2. Set Linux File System Permissions (The First Lock)
# Only 'vlad' will own the 'soft' folder to prevent others from deleting files
chown -R vlad:root /storage/soft
chmod 755 /storage/soft
# 'user' folder remains open for both
chmod 777 /storage/user

# 3. Handle Samba Users
useradd -M -s /sbin/nologin vlad 2>/dev/null
useradd -M -s /sbin/nologin usr 2>/dev/null

if [ ! -z "$SMB_PASS" ]; then
    (echo "$SMB_PASS"; echo "$SMB_PASS") | smbpasswd -a -s vlad
    (echo "$SMB_PASS"; echo "$SMB_PASS") | smbpasswd -a -s usr
    smbpasswd -e vlad
    smbpasswd -e usr
fi

# 4. Generate Samba Config (The Second Lock)
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
   # Force delete to fail for anyone not in write list
   printable = no

[user]
   path = /storage/user
   browseable = yes
   read only = no
   valid users = vlad, usr
   write list = vlad, usr
EOC

systemctl restart smbd nmbd
echo "✅ Done! 'soft' is now strictly Read-Only for 'usr' at both OS and Samba levels."
