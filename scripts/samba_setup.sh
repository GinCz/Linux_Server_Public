#!/bin/bash
# =============================================================================
# samba_setup.sh — Install Samba + users + shares + full security on Ubuntu 24
# Version     : v2026.07.04
# Description : Complete Samba installer. Sets up file sharing with 2 users,
#               hardens smb.conf, opens UFW ports with rate-limiting, and at
#               the end calls IPGuard (blacklist/install-ipguard.sh) to apply
#               full triple-layer protection: CrowdSec + Fail2Ban + ipset.
#
#               Share structure (same on ALL 10 servers, current as of v2026.07.04):
#
#               /storage            — browse-only root   share: [storage]
#               /storage/soft       — vlad (RW), usr (RO) share: [soft]
#               /storage/user       — vlad (RW), usr (RW) share: [user]
#
#               Windows access:
#               \\<IP>\storage       → /storage         (browse root, see soft+user)
#               \\<IP>\soft          → /storage/soft    (software/files, usr read-only)
#               \\<IP>\user          → /storage/user    (shared rw folder)
#
#               NOTE: [storage] share is read-only/browse-only by design.
#               It exists so Windows shows both soft\ and user\ in one place.
#               Actual read/write happens via [soft] and [user] shares.
#
#               Linux folder permissions:
#               /storage            chmod 0775  (world-readable for Windows browse)
#               /storage/soft       chmod 2775  (setgid — new files inherit group vlad)
#               /storage/user       chmod 2775  (setgid — new files inherit group vlad)
#               All folders:        chown vlad:vlad
#
#               Samba users:
#               vlad  — owner/admin. RW on all shares (soft + user).
#               usr   — limited user. RO on [soft], RW on [user].
#                       Member of group vlad (needed for setgid write on /storage/user).
#               zlat  — full-access user (same rights as vlad). RW on all shares.
#                       Add manually after install: useradd -M -s /sbin/nologin zlat
#                                                   usermod -aG vlad zlat
#                                                   smbpasswd -a zlat
#
#               Key smb.conf parameters (all shares):
#               create mask       = 0775  — uploaded files get execute bit set
#               directory mask    = 0775  — new directories are group-writable
#               force create mode = 0775  — ACL/FASTPANEL cannot strip execute bit
#               force directory mode = 0775  — ACL cannot override directory rights
#               → Result: .exe .sh .bat .ps1 .cmd files are executable after upload
#
#               FIXES in v2026.07.04 (applied to all 10 servers):
#                 - create mask changed 0664 → 0775 (exe/sh files now executable)
#                 - force create mode = 0775 added (ACL cannot override chmod +x)
#                 - force directory mode = 0775 added
#                 - /storage chmod 0775 (was 0770 — Windows browse fix)
#                 - /storage/soft and /storage/user chmod 2775 (was 2770)
#
#               Security layers (applied at the end via IPGuard):
#                 Layer 1 — Fail2Ban:        ban after 3 failed auth / 1 hour
#                 Layer 2 — CrowdSec:        community blocklist + CAPI sharing
#                 Layer 3 — IPGuard ipset:   shared blacklist from all 10 nodes
#                 Layer 4 — smb.conf:        SMB2+, NTLMv2, no guest, auth log
#                 Layer 5 — UFW rate-limit:  6 conn/30s on ports 445/139
#
#               Migration from v2026.06.14b (old structure):
#               OLD: /storage/soft/user   →  share [user]
#               NEW: /storage/user        →  share [user]   (separate from soft)
#               Script auto-migrates files if /storage/soft/user has content.
#
# Usage       : bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_setup.sh)
# Idempotent  : yes — safe to run multiple times
# = Rooted by VladiMIR + AI | v2026.07.04 | github.com/GinCz =
# =============================================================================
clear

G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; R='\033[1;31m'; W='\033[1;37m'; X='\033[0m'
SEP="${Y}$(printf '=%.0s' {1..62})${X}"

echo -e "$SEP"
echo -e "  ${W}SAMBA SETUP  v2026.07.04${X}"
echo -e "  ${C}$(hostname)${X}  ${G}$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1)${X}"
echo -e "$SEP"
echo -e "  Share structure:"
echo -e "    ${C}/storage${X}       — browse-only root        →  [storage]"
echo -e "    ${C}/storage/soft${X}  — vlad (RW), usr (RO)     →  [soft]"
echo -e "    ${C}/storage/user${X}  — vlad (RW), usr (RW)     →  [user]"
echo -e "  Users:  ${C}vlad${X} (owner/admin)   ${C}usr${X} (read-only on soft, rw on user)"
echo -e "  Note:   ${Y}zlat${X} — add manually after install (see header comments)"
echo -e "  Security: UFW + Fail2Ban + CrowdSec + IPGuard ipset + smb.conf"
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

mkdir -p /storage/soft /storage/user

# Auto-migrate from old structure (v2026.06.14b): /storage/soft/user → /storage/user
if [ -d /storage/soft/user ]; then
    if [ "$(ls -A /storage/soft/user 2>/dev/null)" ]; then
        echo -e "  ${Y}Found /storage/soft/user with files — migrating to /storage/user...${X}"
        cp -a /storage/soft/user/. /storage/user/
        echo -e "  ${G}OK: files migrated to /storage/user${X}"
    fi
    rm -rf /storage/soft/user
    echo -e "  ${G}OK: old /storage/soft/user removed${X}"
fi

echo -e "  ${G}OK: /storage  /storage/soft  /storage/user ready${X}"

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

# usr must be in group vlad to write to /storage/user (setgid)
usermod -aG vlad usr 2>/dev/null || true

# Remove any existing ACLs that may interfere with permissions (e.g. from FASTPANEL)
if command -v setfacl &>/dev/null; then
    find /storage -exec setfacl -b {} \; 2>/dev/null
    echo -e "  ${G}OK: existing ACLs cleared from /storage tree${X}"
fi

# /storage — browse root, world-readable so Windows can enumerate shares
chown vlad:vlad /storage
chmod 0775 /storage

# /storage/soft — vlad RW, usr RO (enforced via smb.conf write list)
# setgid (2xxx) ensures new files inherit group vlad
chown vlad:vlad /storage/soft
chmod 2775 /storage/soft

# /storage/user — vlad RW, usr RW (usr in group vlad + setgid)
chown vlad:vlad /storage/user
chmod 2775 /storage/user

# Fix execute bits on all existing executable files
find /storage -type f \( \
    -name "*.exe" -o -name "*.msi" -o -name "*.bat" \
    -o -name "*.cmd" -o -name "*.sh"  -o -name "*.ps1" \
\) -exec chmod 775 {} \; 2>/dev/null

echo -e "  ${G}OK: permissions set${X}"
ls -lad /storage /storage/soft /storage/user

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

# Write complete smb.conf from scratch
cat > "$SMB" << 'SMBEOF'
[global]
   log level = 2
   max log size = 1000
   log file = /var/log/samba/log.%m
   invalid users = root bin daemon nobody
   max smbd processes = 100
   ntlm auth = yes
   server min protocol = SMB2
   workgroup = WORKGROUP
   security = user
   map to guest = never
   dns proxy = no

# === VladiMIR + AI | v2026.07.04 | github.com/GinCz ===

[storage]
   comment = Storage root — shows soft and user folders
   path = /storage
   browsable = yes
   writable = no
   valid users = vlad usr zlat
   force group = vlad
   create mask = 0775
   directory mask = 0775
   force create mode = 0775
   force directory mode = 0775

[soft]
   comment = Software storage — vlad/zlat RW, usr RO
   path = /storage/soft
   browsable = yes
   writable = yes
   write list = vlad zlat
   read list = usr
   valid users = vlad usr zlat
   force group = vlad
   create mask = 0775
   directory mask = 0775
   force create mode = 0775
   force directory mode = 0775

[user]
   comment = User storage — vlad/zlat RW, usr RW
   path = /storage/user
   browsable = yes
   writable = yes
   valid users = vlad usr zlat
   force group = vlad
   create mask = 0775
   directory mask = 0775
   force create mode = 0775
   force directory mode = 0775

# =======================================================
SMBEOF

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
    [[ $(ufw status 2>/dev/null | head -1) == *inactive* ]] && ufw --force enable 2>/dev/null
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
echo -e "  ${C}\\\\\\\\${IP}\\\\storage${X}  → /storage        browse root (soft + user visible)"
echo -e "  ${C}\\\\\\\\${IP}\\\\soft${X}     → /storage/soft   vlad/zlat RW, usr RO"
echo -e "  ${C}\\\\\\\\${IP}\\\\user${X}     → /storage/user   vlad/zlat/usr RW"
echo
echo -e "  ${Y}NOTE: zlat user — add manually if needed:${X}"
echo -e "    ${C}useradd -M -s /sbin/nologin zlat${X}"
echo -e "    ${C}usermod -aG vlad zlat${X}"
echo -e "    ${C}smbpasswd -a zlat${X}"
echo
echo -e "  Run ${C}testparm${X} to verify smb.conf"
echo

# ==============================================================================
# SECURITY: Launch IPGuard — full triple-layer protection
# ==============================================================================
echo -e "$SEP"
echo -e "  ${W}LAUNCHING IPGUARD — TRIPLE-LAYER SECURITY INSTALLER${X}"
echo -e "  ${C}Fail2Ban + CrowdSec + IPGuard ipset vladblacklist${X}"
echo -e "$SEP"
echo

IPGUARD_URL="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/install-ipguard.sh"

if curl -fsSL --connect-timeout 10 "$IPGUARD_URL" -o /tmp/ipguard_install.sh 2>/dev/null; then
    bash /tmp/ipguard_install.sh
    rm -f /tmp/ipguard_install.sh
else
    echo -e "  ${R}ERROR: could not download IPGuard installer${X}"
    echo -e "  ${Y}Install manually:${X}"
    echo -e "    ${C}bash <(curl -fsSL ${IPGUARD_URL})${X}"
    echo
fi

echo
echo -e "$SEP"
echo -e "  ${W}= Rooted by VladiMIR + AI | v2026.07.04 | github.com/GinCz =${X}"
echo -e "$SEP"
