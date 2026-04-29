#!/bin/bash
# =============================================================================
# samba_setup.sh — Install and configure Samba shared folder
# Version     : v2026-04-30
# Server      : Any Ubuntu 24 server
# Description : Creates /storage share with 2 users:
#               vlad — full read/write access
#               usr  — read-only access
# Usage       : bash /root/Linux_Server_Public/scripts/samba_setup.sh
# Dependencies: samba
# WARNING     : Overwrites [storage] section in smb.conf if exists
# = Rooted by VladiMIR | AI =
# =============================================================================
clear

G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; R='\033[1;31m'; X='\033[0m'

echo -e "${Y}=========================================${X}"
echo -e "${Y}   SAMBA SETUP v2026-04-30${X}"
echo -e "${Y}   = Rooted by VladiMIR | AI =${X}"
echo -e "${Y}=========================================${X}"
echo -e "Share path : ${C}/storage${X}"
echo -e "User RW    : ${C}vlad${X}"
echo -e "User RO    : ${C}usr${X}"
echo
read -rp "Type YES to continue: " CONFIRM
[[ "${CONFIRM}" == "YES" ]] || { echo "Aborted"; exit 1; }

# Install Samba
echo -e "\n${C}[1/5] Installing Samba...${X}"
apt update -y && apt install -y samba
echo -e "${G}OK${X}"

# Create share folder
echo -e "\n${C}[2/5] Creating /storage...${X}"
mkdir -p /storage
chmod 0770 /storage
echo -e "${G}OK: /storage created${X}"

# Create system users (no login shell)
echo -e "\n${C}[3/5] Creating system users...${X}"
id vlad &>/dev/null || useradd -M -s /sbin/nologin vlad
id usr  &>/dev/null || useradd -M -s /sbin/nologin usr
chown vlad:vlad /storage
echo -e "${G}OK: users vlad + usr exist${X}"

# Set Samba passwords
echo -e "\n${C}[4/5] Set Samba passwords...${X}"
read -rsp "Password for vlad: " PASS_VLAD; echo
read -rsp "Password for usr:  " PASS_USR;  echo
(echo "${PASS_VLAD}"; echo "${PASS_VLAD}") | smbpasswd -s -a vlad
(echo "${PASS_USR}";  echo "${PASS_USR}")  | smbpasswd -s -a usr
echo -e "${G}OK: Samba passwords set${X}"

# Configure smb.conf
echo -e "\n${C}[5/5] Writing smb.conf...${X}"

# Remove old [storage] block if exists
sed -i '/^\[storage\]/,/^\[/{/^\[storage\]/!{/^\[/!d}}' /etc/samba/smb.conf 2>/dev/null || true
sed -i '/^\[storage\]/d' /etc/samba/smb.conf 2>/dev/null || true

# Write global section if missing
if ! grep -q '\[global\]' /etc/samba/smb.conf 2>/dev/null; then
cat > /etc/samba/smb.conf << 'GLOBALEOF'
[global]
   workgroup = WORKGROUP
   security = user
   map to guest = bad user
   server string = %h server
   vfs objects = acl_xattr
   map acl inherit = yes
   store dos attributes = yes
GLOBALEOF
fi

# Append storage share
cat >> /etc/samba/smb.conf << 'SHAREEOF'

[storage]
   path = /storage
   browsable = yes
   writable = yes
   valid users = vlad
   read list = usr
   create mask = 0664
   directory mask = 0775
SHAREEOF

testparm -s >/dev/null 2>&1 && echo -e "${G}OK: smb.conf valid${X}" || echo -e "${R}WARNING: smb.conf has errors — check testparm${X}"

# Restart Samba
systemctl restart smbd nmbd
systemctl enable smbd nmbd
echo
echo -e "${Y}=========================================${X}"
echo -e "${G}  SAMBA SETUP COMPLETE${X}"
echo -e "${Y}=========================================${X}"
echo -e "  Share  : ${C}\\\\\$(hostname)\\storage${X}  or  ${C}\\\\\$(hostname -I | awk '{print \$1}')\\storage${X}"
echo -e "  ${G}vlad${X} : read + write"
echo -e "  ${C}usr${X}  : read only"
echo -e "  Folder : /storage"
echo -e "${Y}=========================================${X}"
echo
smbstatus --shares 2>/dev/null | head -20 || true
