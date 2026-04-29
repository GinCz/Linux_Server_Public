#!/bin/bash
# =============================================================================
# samba_setup.sh — Install Samba + users + shares on any Ubuntu 24 server
# Version     : v2026-04-30
# Server      : Any Ubuntu 24 server
# Description : Creates Samba shares with 2 system users:
#               vlad — RW on /storage/user and /storage/soft
#               usr  — RW on /storage/user, RO on /storage/soft
# Usage       : bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_setup.sh)
# Dependencies: samba
# WARNING     : Overwrites [user] and [soft] sections in smb.conf
# = Rooted by VladiMIR | AI =
# =============================================================================
clear

G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; R='\033[1;31m'; X='\033[0m'

echo -e "${Y}=========================================${X}"
echo -e "${Y}   SAMBA SETUP v2026-04-30${X}"
echo -e "${Y}   = Rooted by VladiMIR | AI =${X}"
echo -e "${Y}=========================================${X}"
echo -e "  Shares:"
echo -e "    ${C}/storage/user${X}  — vlad (RW), usr (RW)"
echo -e "    ${C}/storage/soft${X}  — vlad (RW), usr (RO)"
echo -e "  Users:"
echo -e "    ${C}vlad${X} — Samba RW both shares"
echo -e "    ${C}usr${X}  — Samba RW user / RO soft"
echo
read -rp "Type YES to continue: " CONFIRM
[[ "${CONFIRM}" == "YES" ]] || { echo "Aborted"; exit 1; }

# ---- Install Samba ----------------------------------------------------------
echo -e "\n${C}[1/5] Installing Samba...${X}"
apt update -y && apt install -y samba
echo -e "${G}OK${X}"

# ---- Create folders ---------------------------------------------------------
echo -e "\n${C}[2/5] Creating share folders...${X}"
mkdir -p /storage/user /storage/soft
chown vlad:vlad /storage/user /storage/soft 2>/dev/null || true
chmod 0770 /storage/user /storage/soft
echo -e "${G}OK: /storage/user + /storage/soft${X}"

# ---- Create system users ----------------------------------------------------
echo -e "\n${C}[3/5] Creating system users...${X}"
for U in vlad usr; do
    id "$U" &>/dev/null && echo "  $U already exists" || {
        useradd -M -s /sbin/nologin "$U"
        echo -e "  ${G}created: $U${X}"
    }
done
chown vlad:vlad /storage/user /storage/soft
echo -e "${G}OK${X}"

# ---- Set Samba passwords ----------------------------------------------------
echo -e "\n${C}[4/5] Set Samba passwords...${X}"
for U in vlad usr; do
    read -rsp "  Password for ${U}: " PASS; echo
    (echo "${PASS}"; echo "${PASS}") | smbpasswd -s -a "$U"
done
echo -e "${G}OK: passwords set${X}"

# ---- Configure smb.conf -----------------------------------------------------
echo -e "\n${C}[5/5] Writing smb.conf...${X}"

for SECTION in user soft; do
    sed -i "/^\\[${SECTION}\\]/,/^\\[/{/^\\[${SECTION}\\]/!{/^\\[/!d}};/^\\[${SECTION}\\]/d" /etc/samba/smb.conf 2>/dev/null || true
done

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

cat >> /etc/samba/smb.conf << 'SHAREEOF'

[user]
   comment = User storage (vlad RW, usr RW)
   path = /storage/user
   browsable = yes
   writable = yes
   valid users = vlad, usr
   create mask = 0664
   directory mask = 0775

[soft]
   comment = Software storage (vlad RW, usr RO)
   path = /storage/soft
   browsable = yes
   writable = yes
   write list = vlad
   valid users = vlad, usr
   create mask = 0664
   directory mask = 0775
SHAREEOF

testparm -s >/dev/null 2>&1 \
    && echo -e "${G}OK: smb.conf valid${X}" \
    || echo -e "${R}WARNING: testparm errors — run: testparm${X}"

systemctl restart smbd nmbd
systemctl enable smbd nmbd

echo
echo -e "${Y}=========================================${X}"
echo -e "${G}   SAMBA SETUP COMPLETE${X}"
echo -e "${Y}=========================================${X}"
IP=$(hostname -I | awk '{print $1}')
echo -e "  ${C}\\\\\\\\${IP}\\\\user${X}  — vlad (RW), usr (RW)"
echo -e "  ${C}\\\\\\\\${IP}\\\\soft${X}  — vlad (RW), usr (RO)"
echo
echo -e "Run ${Y}testparm${X} to verify config"
echo -e "${Y}=========================================${X}"
