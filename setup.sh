#!/usr/bin/env bash
# VladiMIR Infrastructure Setup - Strict Samba Permissions
source /root/.server_env

echo "--- Configuring Samba Storage [/storage] ---"
apt update && apt install samba -y

# Create users first (so we can assign folder ownership)
useradd -M -s /sbin/nologin vlad 2>/dev/null
useradd -M -s /sbin/nologin usr 2>/dev/null

if [ ! -z "$SMB_PASS" ]; then
    (echo "$SMB_PASS"; echo "$SMB_PASS") | smbpasswd -a -s vlad
    (echo "$SMB_PASS"; echo "$SMB_PASS") | smbpasswd -a -s usr
    smbpasswd -e vlad
    smbpasswd -e usr
fi

# Create directory structure
mkdir -p /storage/soft /storage/user

# Set Linux Permissions (Lock 1: OS Level)
# vlad owns 'soft', usr can only read
chown -R vlad:root /storage/soft
chmod 755 /storage/soft
# both can work in 'user'
chmod 777 /storage/user

# Generate Samba Config (Lock 2: Service Level)
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
echo "✅ Setup Finished! /storage/soft is now strictly protected."
