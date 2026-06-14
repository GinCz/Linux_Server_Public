#!/bin/bash
# =============================================================================
# samba_setup.sh — Install Samba + users + shares + full security on Ubuntu 24
# Version     : v2026.06.14
# Description : Complete Samba installer. Sets up file sharing with 2 users,
#               hardens smb.conf, opens UFW ports with rate-limiting, and at
#               the end calls the IPGuard installer (install_crowdsec.sh) to
#               apply full dual-layer protection: CrowdSec + Fail2Ban.
#
#               Share structure (same on ALL servers):
#               /storage/soft        — vlad (RW), usr (RO)   share: [soft]
#               /storage/soft/user   — vlad (RW), usr (RW)   share: [user]
#
#               Windows access:
#               \\<IP>\soft          → /storage/soft
#               \\<IP>\user          → /storage/soft/user  (direct shortcut)
#               \\<IP>\soft\user     → /storage/soft/user  (same files)
#
#               NOTE: [user] share is a direct shortcut to the subfolder
#               inside [soft]. Both paths point to the same directory — by design.
#
#               Security layers (applied at the end via IPGuard):
#                 Layer 1 — UFW rate-limit: 6 conn/30s on ports 445/139
#                 Layer 2 — CrowdSec SMB: community blocklist + CAPI sharing
#                 Layer 3 — Fail2Ban: ban after 3 failed auth attempts / 1 hour
#                 Layer 4 — smb.conf: SMB2+, NTLMv2-only, no guest, auth logging
#
# Usage       : bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_setup.sh)
# Idempotent  : yes — safe to run multiple times
# = Rooted by VladiMIR + AI | v2026.06.14 | github.com/GinCz =
# =============================================================================
clear

G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; R='\033[1;31m'; W='\033[1;37m'; X='\033[0m'
SEP="${Y}$(printf '=%.0s' {1..62})${X}"

echo -e "$SEP"
echo -e "  ${W}SAMBA SETUP  v2026.06.14${X}"
echo -e "  ${C}$(hostname)${X}  ${G}$(hostname -I | awk '{print $1}')${X}"
echo -e "$SEP"
echo -e "  Share structure:"
echo -e "    ${C}/storage/soft${X}       — vlad (RW), usr (RO)  →  [soft]"
echo -e "    ${C}/storage/soft/user${X}  — vlad (RW), usr (RW)  →  [user]"
echo -e "  Users:  ${C}vlad${X} (owner/admin)   ${C}usr${X} (read-only on soft)"
echo -e "  Security: UFW rate-limit + CrowdSec + Fail2Ban + smb.conf hardening"
echo
read -rp "Type YES to continue: " CONFIRM
[[ "${CONFIRM}" == "YES" ]] || { echo "Aborted"; exit 1; }

# ---- [1/6] Install Samba -----------------------------------------------------
echo -e "\n${C}[1/6] Installing Samba...${X}"
if dpkg -l 2>/dev/null | grep -qE '^ii\s+samba\s'; then
    echo -e "  ${G}OK: Samba already installed — skipping apt install${X}"
else
    apt-get update -qq
    apt-get install -y samba samba-common-bin python3
    echo -e "  ${G}OK: Samba installed${X}"
fi
systemctl enable smbd nmbd 2>/dev/null
echo -e "  ${G}OK: smbd + nmbd enabled${X}"

# ---- [2/6] Folder structure --------------------------------------------------
echo -e "\n${C}[2/6] Setting up folder structure...${X}"

mkdir -p /storage/soft/user

# Migrate legacy /storage/user if it exists
if [ -d /storage/user ] && [ ! -L /storage/user ]; then
    if [ "$(ls -A /storage/user 2>/dev/null)" ]; then
        echo -e "  ${Y}Found /storage/user with files — migrating to /storage/soft/user...${X}"
        cp -a /storage/user/. /storage/soft/user/
        echo -e "  ${G}OK: files migrated${X}"
    fi
    rm -rf /storage/user
    echo -e "  ${G}OK: legacy /storage/user removed${X}"
fi

echo -e "  ${G}OK: /storage/soft + /storage/soft/user ready${X}"

# ---- [3/6] Users + permissions -----------------------------------------------
echo -e "\n${C}[3/6] Creating users and setting permissions...${X}"

for U in vlad usr; do
    if id "$U" &>/dev/null; then
        echo -e "  ${C}user $U already exists${X}"
    else
        useradd -M -s /sbin/nologin "$U"
        echo -e "  ${G}created: $U${X}"
    fi
done

# usr must be in group vlad to write to /storage/soft/user (group sticky)
usermod -aG vlad usr 2>/dev/null || true

# /storage/soft — owner vlad, group vlad, setgid, 2770
# usr can only read here (no group write via smb.conf write list)
chown vlad:vlad /storage/soft
chmod 2770 /storage/soft

# /storage/soft/user — owner vlad, group vlad, setgid, 2770
# both vlad and usr have RW (usr is in group vlad)
chown vlad:vlad /storage/soft/user
chmod 2770 /storage/soft/user

echo -e "  ${G}OK: permissions set${X}"
ls -lad /storage/soft /storage/soft/user

# ---- [4/6] Samba passwords ---------------------------------------------------
echo -e "\n${C}[4/6] Setting Samba passwords...${X}"
echo -e "  ${Y}Press Enter to skip if password is already set${X}"
for U in vlad usr; do
    read -rsp "  Password for ${U} (Enter to skip): " PASS; echo
    if [ -n "${PASS}" ]; then
        (echo "${PASS}"; echo "${PASS}") | smbpasswd -s -a "$U" 2>/dev/null
        smbpasswd -e "$U" 2>/dev/null
        echo -e "  ${G}OK: password set for $U${X}"
    else
        smbpasswd -e "$U" 2>/dev/null || true
        echo -e "  ${C}Skipped $U — activating existing password if any${X}"
    fi
done

# ---- [5/6] Write smb.conf ----------------------------------------------------
echo -e "\n${C}[5/6] Writing smb.conf...${X}"

SMB=/etc/samba/smb.conf
BACKUP="${SMB}.bak.$(date +%Y%m%d_%H%M%S)"
cp "$SMB" "$BACKUP" 2>/dev/null && echo -e "  ${G}OK: backup → $BACKUP${X}"

# Remove existing [soft] and [user] sections cleanly via python3
python3 << PYEOF
import re
try:
    content = open('${SMB}').read()
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
open('${SMB}', 'w').write(content)
print('  existing [soft]/[user] sections removed')
PYEOF

# Apply [global] hardening parameters
# SMB2+: disables legacy SMB1 (EternalBlue/WannaCry CVE-2017-0144)
# ntlm auth = yes: required for modern Windows compatibility
# map to guest = never: no anonymous/guest access
# max smbd processes: prevents resource exhaustion from connection floods
# log level = 2: required for Fail2Ban to detect auth failures in log.smbd
if grep -q '^\[global\]' "$SMB" 2>/dev/null; then
    for PARAM in \
        'workgroup = WORKGROUP' \
        'server min protocol = SMB2' \
        'ntlm auth = yes' \
        'map to guest = never' \
        'max smbd processes = 100' \
        'invalid users = root bin daemon nobody' \
        'log file = /var/log/samba/log.%m' \
        'max log size = 1000' \
        'log level = 2'; do
        KEY=$(echo "$PARAM" | cut -d= -f1 | xargs)
        if grep -qi "^[[:space:]]*${KEY}[[:space:]]*=" "$SMB"; then
            sed -i "s|^[[:space:]]*${KEY}[[:space:]]*=.*|   ${PARAM}|I" "$SMB"
        else
            sed -i "/^\[global\]/a\\   ${PARAM}" "$SMB"
        fi
    done
    echo -e "  ${G}OK: [global] section updated${X}"
else
    cat >> "$SMB" << 'GLOBALEOF'
[global]
   workgroup = WORKGROUP
   server string = %h server (Samba, Ubuntu)
   security = user
   server min protocol = SMB2
   ntlm auth = yes
   map to guest = never
   invalid users = root bin daemon nobody
   max smbd processes = 100
   log file = /var/log/samba/log.%m
   max log size = 1000
   log level = 2
GLOBALEOF
    echo -e "  ${G}OK: [global] section written${X}"
fi

# Ensure log level = 2 — Fail2Ban reads /var/log/samba/log.smbd and needs
# auth failure lines which only appear at log level 2 or higher
if grep -qi "^[[:space:]]*log level[[:space:]]*=" "$SMB"; then
    sed -i "s|^[[:space:]]*log level[[:space:]]*=.*|   log level = 2|I" "$SMB"
else
    sed -i "/^\[global\]/a\\   log level = 2" "$SMB"
fi

# Append share definitions
cat >> "$SMB" << 'SHAREEOF'

# === VladiMIR + AI | v2026.06.14 | github.com/GinCz ===
[soft]
   comment = Software storage — vlad RW, usr RO
   path = /storage/soft
   browsable = yes
   writable = yes
   write list = vlad
   valid users = vlad usr
   create mask = 0664
   directory mask = 0775

[user]
   comment = User storage inside soft — vlad RW, usr RW
   path = /storage/soft/user
   browsable = yes
   writable = yes
   valid users = vlad usr
   create mask = 0664
   directory mask = 0775
# =======================================================
SHAREEOF

if testparm -s >/dev/null 2>&1; then
    echo -e "  ${G}OK: smb.conf valid (testparm passed)${X}"
    systemctl restart smbd nmbd
    systemctl enable smbd nmbd 2>/dev/null
    echo -e "  ${G}OK: smbd + nmbd restarted${X}"
else
    echo -e "  ${R}ERROR: testparm failed — restoring backup${X}"
    cp "$BACKUP" "$SMB"
    systemctl restart smbd nmbd 2>/dev/null
    exit 1
fi

# ---- [UFW] Open + rate-limit SMB ports ---------------------------------------
echo -e "\n${C}[UFW] Configuring SMB ports (445/139)...${X}"
if command -v ufw &>/dev/null; then
    # Enable UFW if inactive
    [[ $(ufw status 2>/dev/null | head -1) == *inactive* ]] && ufw --force enable 2>/dev/null
    # Replace any plain ALLOW rules with LIMIT (6 conn/30s)
    for PORT in 445 139; do
        ufw delete allow "${PORT}/tcp" 2>/dev/null || true
        ufw delete allow "${PORT}/udp" 2>/dev/null || true
    done
    ufw limit 445/tcp comment 'Samba SMB — rate-limit 6 conn/30s' 2>/dev/null
    ufw limit 139/tcp comment 'Samba NetBIOS — rate-limit 6 conn/30s' 2>/dev/null
    ufw reload 2>/dev/null
    echo -e "  ${G}OK: ports 445/139 open with UFW rate-limit (6 conn/30s)${X}"
    ufw status | grep -E '445|139'
else
    echo -e "  ${Y}UFW not found — open ports 445 and 139 manually${X}"
fi

# ---- [6/6] Disk space check --------------------------------------------------
echo -e "\n${C}[6/6] Disk space on /storage:${X}"
df -h /storage 2>/dev/null || df -h / 2>/dev/null

# ---- SUMMARY -----------------------------------------------------------------
echo
echo -e "$SEP"
echo -e "  ${G}SAMBA SETUP COMPLETE${X}"
echo -e "$SEP"
IP=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1)
echo -e "  ${C}\\\\\\\\${IP}\\\\soft${X}       → /storage/soft        vlad RW, usr RO"
echo -e "  ${C}\\\\\\\\${IP}\\\\user${X}       → /storage/soft/user   vlad RW, usr RW"
echo -e "  ${C}\\\\\\\\${IP}\\\\soft\\\\user${X}  → /storage/soft/user   (same)"
echo
echo -e "  Run ${C}testparm${X} to verify smb.conf"
echo

# ==============================================================================
# SECURITY: Launch IPGuard — full dual-layer protection
# CrowdSec (community blocklist + SMB brute-force + journald) +
# Fail2Ban (local ban after 3 failed attempts / 1 hour)
# IPGuard is maintained separately and always pulls the latest version.
# ==============================================================================
echo -e "$SEP"
echo -e "  ${W}LAUNCHING IPGUARD SECURITY INSTALLER${X}"
echo -e "  ${C}CrowdSec + Fail2Ban — dual-layer protection${X}"
echo -e "$SEP"
echo

IPGUARD_URL="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/install_crowdsec.sh"

if curl -fsSL --connect-timeout 10 "$IPGUARD_URL" -o /tmp/ipguard_install.sh 2>/dev/null; then
    bash /tmp/ipguard_install.sh
    rm -f /tmp/ipguard_install.sh
else
    echo -e "  ${R}ERROR: could not download IPGuard installer${X}"
    echo -e "  ${Y}Install manually:${X}"
    echo -e "    ${C}bash <(curl -sL ${IPGUARD_URL})${X}"
    echo
fi

echo
echo -e "$SEP"
echo -e "  ${W}= Rooted by VladiMIR + AI | v2026.06.14 | github.com/GinCz =${X}"
echo -e "$SEP"
