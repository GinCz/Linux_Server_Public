#!/bin/bash
# = Rooted by VladiMIR + AI | v2026.07.04 | github.com/GinCz =
# =============================================================================
# samba_fix_remote.sh — Push Samba execute-bit fix to ALL servers via SSH
# Run on   : SERVER 222 (152.53.182.222) — it connects to all others
# Version  : v2026.07.04
# Purpose  : Fix create mask 0664→0775 + force create mode + zlat user
#            on all Linux servers where Samba is installed.
# Usage    : bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_fix_remote.sh)
#            OR: bash samba_fix_remote.sh
# =============================================================================
clear

G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; R='\033[1;31m'; W='\033[1;37m'; X='\033[0m'
SEP="${Y}$(printf '=%.0s' {1..62})${X}"

# --- Target servers (all except 222 which is the source) ---
# Format: "label:IP:SSH_PORT:SSH_USER"
SERVERS=(
    "109-RU-FastVDS:212.109.223.109:22:root"
    "ALEX-47:109.234.38.47:22:root"
    "4TON-237:144.124.228.237:22:root"
    "TATRA-9:144.124.232.9:22:root"
    "SHAHIN-227:144.124.228.227:22:root"
    "STOLB-24:144.124.239.24:22:root"
    "PILIK-33:195.63.138.33:22:root"
    "ILYA-176:146.103.110.176:22:root"
    "SO-38:144.124.233.38:22:root"
    "IONOS:82.223.116.38:22:root"
)

# --- Fix payload (executed on each remote server) ---
FIX_PAYLOAD='#!/bin/bash
G="\033[1;32m"; Y="\033[1;33m"; R="\033[1;31m"; X="\033[0m"

# Check if Samba is installed
if ! command -v smbd &>/dev/null && ! dpkg -l 2>/dev/null | grep -q "^ii.*samba"; then
    echo -e "  ${Y}Samba NOT installed on $(hostname) — skipping${X}"
    exit 0
fi

SMB=/etc/samba/smb.conf
echo -e "  Samba found on $(hostname) | $(hostname -I | awk "{print \$1}")"

# Backup
cp "$SMB" "${SMB}.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null

# Fix 1: create mask 0664 → 0775
if grep -q "create mask = 0664" "$SMB"; then
    sed -i "s/create mask = 0664/create mask = 0775/g" "$SMB"
    echo -e "  ${G}FIXED: create mask 0664 → 0775${X}"
fi

# Fix 2: directory mask 0664 → 0775
if grep -q "directory mask = 0664" "$SMB"; then
    sed -i "s/directory mask = 0664/directory mask = 0775/g" "$SMB"
    echo -e "  ${G}FIXED: directory mask 0664 → 0775${X}"
fi

# Fix 3: add force create mode to shares that dont have it
for SHARE in soft user storage; do
    if grep -q "\[$SHARE\]" "$SMB"; then
        SHARE_BLOCK=$(awk "/^\[$SHARE\]/,/^\[/" "$SMB")
        if ! echo "$SHARE_BLOCK" | grep -q "force create mode"; then
            sed -i "/^\[$SHARE\]/,/^\[/{/directory mask/a\\   force create mode = 0775\n   force directory mode = 0775"}" "$SMB" 2>/dev/null
            echo -e "  ${G}ADDED: force create mode to [$SHARE]${X}"
        else
            echo -e "  OK: force create mode already in [$SHARE]"
        fi
    fi
done

# Fix 4: remove deprecated acl allow execute always (replaced by force create mode)
sed -i "/acl allow execute always/d" "$SMB" 2>/dev/null

# Fix 5: /storage folder permissions
if [ -d /storage ]; then
    chmod 0775 /storage 2>/dev/null && echo -e "  ${G}FIXED: /storage chmod 0775${X}"
fi
if [ -d /storage/soft ]; then
    chmod 2775 /storage/soft 2>/dev/null && echo -e "  ${G}FIXED: /storage/soft chmod 2775${X}"
fi
if [ -d /storage/user ]; then
    chmod 2775 /storage/user 2>/dev/null && echo -e "  ${G}FIXED: /storage/user chmod 2775${X}"
fi

# Fix 6: zlat user
if ! id zlat &>/dev/null; then
    useradd -M -s /sbin/nologin zlat
    echo -e "  ${G}CREATED: zlat Linux user${X}"
fi
usermod -aG vlad zlat 2>/dev/null && echo -e "  ${G}OK: zlat in group vlad${X}"

# Fix 7: add zlat to smb.conf valid users and write list (if not present)
if ! grep -q "zlat" "$SMB"; then
    sed -i "s/valid users = vlad usr/valid users = vlad usr zlat/g" "$SMB"
    sed -i "s/write list = vlad$/write list = vlad zlat/g" "$SMB"
    echo -e "  ${G}ADDED: zlat to smb.conf valid users + write list${X}"
else
    echo -e "  OK: zlat already in smb.conf"
fi

# Validate and restart
if testparm -s >/dev/null 2>&1; then
    systemctl restart smbd nmbd 2>/dev/null
    echo -e "  ${G}OK: smb.conf valid — smbd restarted${X}"
else
    echo -e "  ${R}WARNING: testparm failed — check smb.conf manually!${X}"
fi

# Show result
echo
echo "  === RESULT on $(hostname) ==="
grep "create mask\|directory mask\|force create mode\|force directory mode\|valid users" "$SMB" | head -20
echo "  Folders:"
ls -lad /storage /storage/soft /storage/user 2>/dev/null
echo "  zlat: $(id zlat 2>/dev/null || echo NOT FOUND)"
echo
'

# ==============================================================================
echo -e "$SEP"
echo -e "  ${W}SAMBA REMOTE FIX — ALL SERVERS${X}"
echo -e "  ${C}Source: $(hostname) (222-DE)${X}"
echo -e "  ${C}Targets: ${#SERVERS[@]} servers${X}"
echo -e "$SEP"
echo
echo -e "  This script will SSH into each server and:"
echo -e "  ${G}1.${X} Fix create mask 0664 → 0775 (execute bit)"
echo -e "  ${G}2.${X} Add force create mode = 0775"
echo -e "  ${G}3.${X} Fix /storage folder permissions (chmod 2775)"
echo -e "  ${G}4.${X} Create zlat user + add to smb.conf"
echo -e "  ${G}5.${X} Restart smbd on each server"
echo
read -rp "  Type YES to run on all ${#SERVERS[@]} servers: " CONFIRM
[[ "${CONFIRM}" == "YES" ]] || { echo "Aborted"; exit 1; }
echo

# --- Track results ---
OK_LIST=()
FAIL_LIST=()
SKIP_LIST=()

for ENTRY in "${SERVERS[@]}"; do
    LABEL=$(echo "$ENTRY" | cut -d: -f1)
    IP=$(echo "$ENTRY"    | cut -d: -f2)
    PORT=$(echo "$ENTRY"  | cut -d: -f3)
    USER=$(echo "$ENTRY"  | cut -d: -f4)

    echo -e "$SEP"
    echo -e "  ${W}[${LABEL}]${X}  ${C}${USER}@${IP}:${PORT}${X}"
    echo -e "$SEP"

    # Test connectivity first (3 sec timeout)
    if ! ssh -o ConnectTimeout=5 \
             -o StrictHostKeyChecking=no \
             -o BatchMode=yes \
             -p "$PORT" "${USER}@${IP}" 'echo PING' &>/dev/null; then
        echo -e "  ${R}UNREACHABLE — skipping${X}"
        SKIP_LIST+=("$LABEL ($IP)")
        continue
    fi

    # Run fix payload
    if ssh -o ConnectTimeout=10 \
           -o StrictHostKeyChecking=no \
           -p "$PORT" "${USER}@${IP}" "bash -s" <<< "$FIX_PAYLOAD"; then
        OK_LIST+=("$LABEL ($IP)")
        echo -e "  ${G}DONE: $LABEL${X}"
    else
        FAIL_LIST+=("$LABEL ($IP)")
        echo -e "  ${R}FAILED: $LABEL${X}"
    fi
    echo
done

# --- Final summary ---
echo -e "$SEP"
echo -e "  ${W}SUMMARY${X}"
echo -e "$SEP"
if [ ${#OK_LIST[@]} -gt 0 ]; then
    echo -e "  ${G}SUCCESS (${#OK_LIST[@]}):${X}"
    for S in "${OK_LIST[@]}"; do echo -e "    ${G}✓${X} $S"; done
fi
if [ ${#SKIP_LIST[@]} -gt 0 ]; then
    echo -e "  ${Y}UNREACHABLE (${#SKIP_LIST[@]}):${X}"
    for S in "${SKIP_LIST[@]}"; do echo -e "    ${Y}?${X} $S"; done
fi
if [ ${#FAIL_LIST[@]} -gt 0 ]; then
    echo -e "  ${R}FAILED (${#FAIL_LIST[@]}):${X}"
    for S in "${FAIL_LIST[@]}"; do echo -e "    ${R}✗${X} $S"; done
fi
echo
echo -e "  ${C}Server 222 (this server) — already fixed manually.${X}"
echo -e "  ${C}For servers without Samba — script auto-skipped them.${X}"
echo
echo -e "$SEP"
echo -e "  ${W}= Rooted by VladiMIR + AI | v2026.07.04 | github.com/GinCz =${X}"
echo -e "$SEP"
