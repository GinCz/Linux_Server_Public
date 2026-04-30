#!/bin/bash
# =============================================================================
# samba_setup.sh — Install Samba + users + shares on any Ubuntu 24 server
# Version     : v2026-04-30b
# Description : Creates Samba shares with 2 system users:
#               /storage/soft        — vlad (RW), usr (RO)  [soft]
#               /storage/soft/user   — vlad (RW), usr (RW)  [user]
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
echo -e "${Y}   SAMBA SETUP v2026-04-30b${X}"
echo -e "${Y}   = Rooted by VladiMIR | AI =${X}"
echo -e "${Y}=========================================${X}"
echo -e "  Structure:"
echo -e "    ${C}/storage/soft${X}           — vlad (RW), usr (RO)"
echo -e "    ${C}/storage/soft/user${X}      — vlad (RW), usr (RW)"
echo -e "  Users:"
echo -e "    ${C}vlad${X} — owner / admin"
echo -e "    ${C}usr${X}  — limited user"
echo
read -rp "Type YES to continue: " CONFIRM
[[ "${CONFIRM}" == "YES" ]] || { echo "Aborted"; exit 1; }

# ---- [1/6] Install Samba ----------------------------------------------------
echo -e "\n${C}[1/6] Installing Samba...${X}"
apt-get install -y samba >/dev/null 2>&1
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
    echo -e "  ${G}/storage/user does not exist — nothing to migrate${X}"
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

# /storage/soft — vlad owns, group vlad, 0770 (vlad RW, group RW, others nothing)
chown vlad:vlad /storage/soft
chmod 2770 /storage/soft

# /storage/soft/user — vlad owns, group = special group for both users
# Add both users to group vlad so both can write
usermod -aG vlad usr 2>/dev/null || true

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
        echo -e "  ${C}Skipped $U (keeping existing password, activating)${X}"
    fi
done
echo -e "${G}OK${X}"

# ---- [6/6] Configure smb.conf -----------------------------------------------
echo -e "\n${C}[6/6] Writing smb.conf...${X}"

SMB=/etc/samba/smb.conf

# Remove existing [user] and [soft] sections (idempotent clean)
for SECTION in user soft; do
    # Delete from [section] to (but not including) the next [section]
    sed -i "/^\[${SECTION}\]/,/^\[/{/^\[${SECTION}\]/d;/^\[/!d}" "$SMB" 2>/dev/null || true
done

# Ensure [global] has required settings
if grep -q '^\[global\]' "$SMB" 2>/dev/null; then
    # Inject / update key global params (idempotent)
    for PARAM in \
        'workgroup = WORKGROUP' \
        'server min protocol = SMB2' \
        'ntlm auth = yes'; do
        KEY=$(echo "$PARAM" | cut -d= -f1 | xargs)
        if grep -qi "^[[:space:]]*${KEY}[[:space:]]*=" "$SMB"; then
            # Update existing line
            sed -i "s|^[[:space:]]*${KEY}[[:space:]]*=.*|   ${PARAM}|I" "$SMB"
        else
            # Insert after [global]
            sed -i "/^\[global\]/a\\   ${PARAM}" "$SMB"
        fi
    done
    echo -e "  ${G}Updated [global] section${X}"
else
    # No [global] at all — write from scratch
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

# Append share definitions
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

echo
echo -e "${Y}=========================================${X}"
echo -e "${G}   SAMBA SETUP COMPLETE${X}"
echo -e "${Y}=========================================${X}"
IP=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1)
echo -e "  Windows: ${C}\\\\\\\\${IP}${X}"
echo -e "  Share ${C}[soft]${X} → ${C}/storage/soft${X}        vlad RW, usr RO"
echo -e "  Share ${C}[user]${X} → ${C}/storage/soft/user${X}   vlad RW, usr RW"
echo
echo -e "  ${Y}Users: vlad / usr — log in with Samba password${X}"
echo -e "  Run ${C}testparm${X} to verify"
echo -e "${Y}=========================================${X}"
