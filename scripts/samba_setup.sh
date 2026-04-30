#!/bin/bash
# =============================================================================
# samba_setup.sh — Install Samba + users + shares on any Ubuntu 24 server
# Version     : v2026-04-30d
# Description : Creates Samba shares with 2 system users:
#               /storage/soft        — vlad (RW), usr (RO)  [soft]
#               /storage/soft/user   — vlad (RW), usr (RW)  [user]
#
#               Windows access:
#               \\<IP>\soft          → /storage/soft         vlad RW, usr RO
#               \\<IP>\user          → /storage/soft/user    vlad RW, usr RW
#               \\<IP>\soft\user     → /storage/soft/user    (same files)
#
#               NOTE: [user] share is a direct shortcut to the folder
#               inside [soft]. Both paths lead to the same directory.
#               This is by design — no need to fix.
#
#               IDEMPOTENT: safe to run multiple times
#               Migrates /storage/user → /storage/soft/user if needed
#
# Usage       : bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_setup.sh)
# = Rooted by VladiMIR | AI =
# =============================================================================
clear

G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; R='\033[1;31m'; X='\033[0m'

echo -e "${Y}=========================================${X}"
echo -e "${Y}   SAMBA SETUP v2026-04-30d${X}"
echo -e "${Y}   = Rooted by VladiMIR | AI =${X}"
echo -e "${Y}=========================================${X}"
echo -e "  Structure:"
echo -e "    ${C}/storage/soft${X}           — vlad (RW), usr (RO)"
echo -e "    ${C}/storage/soft/user${X}      — vlad (RW), usr (RW)"
echo -e "  Windows:"
echo -e "    ${C}\\\\\\\\<IP>\\\\soft${X}          → /storage/soft"
echo -e "    ${C}\\\\\\\\<IP>\\\\user${X}          → /storage/soft/user  (shortcut)"
echo -e "    ${C}\\\\\\\\<IP>\\\\soft\\\\user${X}     → /storage/soft/user  (same)"
echo -e "  Users:"
echo -e "    ${C}vlad${X} — owner / admin"
echo -e "    ${C}usr${X}  — limited user"
echo
read -rp "Type YES to continue: " CONFIRM
[[ "${CONFIRM}" == "YES" ]] || { echo "Aborted"; exit 1; }

# ---- [1/6] Install Samba ----------------------------------------------------
echo -e "\n${C}[1/6] Installing Samba...${X}"
apt-get install -y samba python3 >/dev/null 2>&1
echo -e "${G}OK${X}"

# ---- [2/6] Migrate /storage/user → /storage/soft/user ----------------------
echo -e "\n${C}[2/6] Migrating folder structure...${X}"

mkdir -p /storage/soft/user

if [ -d /storage/user ] && [ ! -L /storage/user ]; then
    if [ "$(ls -A /storage/user 2>/dev/null)" ]; then
        echo -e "  ${Y}Found /storage/user with files — moving to /storage/soft/user...${X}"
        cp -a /storage/user/. /storage/soft/user/
        echo -e "  ${G}Files moved${X}"
    else
        echo -e "  ${C}/storage/user is empty — removing${X}"
    fi
    rm -rf /storage/user
    echo -e "  ${G}Removed /storage/user${X}"
else
    [ -d /storage/user ] || echo -e "  ${G}/storage/user does not exist — nothing to migrate${X}"
fi

echo -e "${G}OK: /storage/soft + /storage/soft/user${X}"

# ---- [3/6] Create system users ----------------------------------------------
echo -e "\n${C}[3/6] Creating system users...${X}"
for U in vlad usr; do
    if id "$U" &>/dev/null; then
        echo -e "  ${C}$U already exists${X}"
    else
        useradd -M -s /sbin/nologin "$U"
        echo -e "  ${G}created: $U${X}"
    fi
done
echo -e "${G}OK${X}"

# ---- [4/6] Fix permissions --------------------------------------------------
echo -e "\n${C}[4/6] Setting folder permissions...${X}"

usermod -aG vlad usr 2>/dev/null || true

chown vlad:vlad /storage/soft
chmod 2770 /storage/soft

chown vlad:vlad /storage/soft/user
chmod 2770 /storage/soft/user

echo -e "${G}OK:${X}"
ls -lad /storage/soft /storage/soft/user

# ---- [5/6] Set Samba passwords ----------------------------------------------
echo -e "\n${C}[5/6] Set Samba passwords...${X}"
echo -e "  ${Y}(Press Enter to skip user if password already set)${X}"
for U in vlad usr; do
    read -rsp "  Password for ${U} (Enter to skip): " PASS; echo
    if [ -n "${PASS}" ]; then
        (echo "${PASS}"; echo "${PASS}") | smbpasswd -s -a "$U" 2>/dev/null
        smbpasswd -e "$U" 2>/dev/null
        echo -e "  ${G}Password set for $U${X}"
    else
        smbpasswd -e "$U" 2>/dev/null || true
        echo -e "  ${C}Skipped $U (activating existing password)${X}"
    fi
done
echo -e "${G}OK${X}"

# ---- [6/6] Configure smb.conf -----------------------------------------------
echo -e "\n${C}[6/6] Writing smb.conf...${X}"

SMB=/etc/samba/smb.conf

# Use python3 to reliably remove [user] and [soft] sections (handles multi-line)
python3 << PYEOF
import re
try:
    with open('${SMB}', 'r') as f:
        content = f.read()
except FileNotFoundError:
    content = ''

for section in ['user', 'soft']:
    content = re.sub(
        r'^\[' + section + r'\].*?(?=^\[|\Z)',
        '',
        content,
        flags=re.MULTILINE | re.DOTALL
    )

content = re.sub(r'\n{3,}', '\n\n', content).rstrip() + '\n'

with open('${SMB}', 'w') as f:
    f.write(content)
print('  sections removed OK')
PYEOF

# Ensure [global] section exists with required settings
if grep -q '^\[global\]' "$SMB" 2>/dev/null; then
    for PARAM in \
        'workgroup = WORKGROUP' \
        'server min protocol = SMB2' \
        'ntlm auth = yes'; do
        KEY=$(echo "$PARAM" | cut -d= -f1 | xargs)
        if grep -qi "^[[:space:]]*${KEY}[[:space:]]*=" "$SMB"; then
            sed -i "s|^[[:space:]]*${KEY}[[:space:]]*=.*|   ${PARAM}|I" "$SMB"
        else
            sed -i "/^\[global\]/a\\   ${PARAM}" "$SMB"
        fi
    done
    echo -e "  ${G}Updated [global] section${X}"
else
    cat > "$SMB" << 'GLOBALEOF'
[global]
   workgroup = WORKGROUP
   server string = %h server (Samba, Ubuntu)
   security = user
   map to guest = bad user
   server min protocol = SMB2
   ntlm auth = yes
   log file = /var/log/samba/log.%m
   max log size = 1000
GLOBALEOF
    echo -e "  ${G}Written new [global] section${X}"
fi

cat >> "$SMB" << 'SHAREEOF'

[soft]
   comment = Software storage (vlad RW, usr RO)
   path = /storage/soft
   browsable = yes
   writable = yes
   write list = vlad
   valid users = vlad usr
   create mask = 0664
   directory mask = 0775

[user]
   comment = User storage inside soft (vlad RW, usr RW)
   path = /storage/soft/user
   browsable = yes
   writable = yes
   valid users = vlad usr
   create mask = 0664
   directory mask = 0775
SHAREEOF

testparm -s >/dev/null 2>&1 \
    && echo -e "${G}OK: smb.conf valid${X}" \
    || echo -e "${R}WARNING: testparm errors — run: testparm${X}"

systemctl restart smbd nmbd
systemctl enable smbd nmbd 2>/dev/null

# ---- [UFW] Open Samba ports -------------------------------------------------
echo -e "\n${C}[UFW] Opening Samba ports (445, 139)...${X}"
if command -v ufw &>/dev/null; then
    ufw allow 445/tcp >/dev/null 2>&1
    ufw allow 139/tcp >/dev/null 2>&1
    ufw reload >/dev/null 2>&1
    echo -e "${G}OK: ports 445 + 139 opened${X}"
    ufw status | grep -E '445|139'
else
    echo -e "${Y}UFW not found — skip (open ports manually if needed)${X}"
fi

echo
echo -e "${Y}=========================================${X}"
echo -e "${G}   SAMBA SETUP COMPLETE${X}"
echo -e "${Y}=========================================${X}"
IP=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1)
echo -e "  ${C}\\\\\\\\${IP}\\\\soft${X}       → /storage/soft        vlad RW, usr RO"
echo -e "  ${C}\\\\\\\\${IP}\\\\user${X}       → /storage/soft/user   vlad RW, usr RW"
echo -e "  ${C}\\\\\\\\${IP}\\\\soft\\\\user${X}  → /storage/soft/user   (same files)"
echo
echo -e "  ${Y}NOTE: [user] is visible both as a share and inside [soft] — this is by design${X}"
echo -e "  Run ${C}testparm${X} to verify"
echo -e "${Y}=========================================${X}"
