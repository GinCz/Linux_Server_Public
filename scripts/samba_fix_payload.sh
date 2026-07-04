#!/bin/bash
# = Rooted by VladiMIR + AI | v2026.07.04 | github.com/GinCz =
# samba_fix_payload.sh -- executed on each remote server by samba_fix_remote.sh
clear
G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; X='\033[0m'

if ! command -v smbd &>/dev/null && ! dpkg -l 2>/dev/null | grep -q '^ii.*samba'; then
    echo -e "  ${Y}Samba NOT installed on $(hostname) -- skipping${X}"
    exit 0
fi

SMB=/etc/samba/smb.conf
echo -e "  ${G}Samba found on $(hostname) | $(hostname -I | awk '{print $1}')${X}"
cp "$SMB" "${SMB}.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null

# Fix 1: create mask
if grep -q 'create mask = 0664' "$SMB"; then
    sed -i 's/create mask = 0664/create mask = 0775/g' "$SMB"
    echo -e "  ${G}FIXED: create mask 0664 -> 0775${X}"
else
    echo -e "  OK: create mask already correct"
fi

# Fix 2: directory mask
if grep -q 'directory mask = 0664' "$SMB"; then
    sed -i 's/directory mask = 0664/directory mask = 0775/g' "$SMB"
    echo -e "  ${G}FIXED: directory mask 0664 -> 0775${X}"
else
    echo -e "  OK: directory mask already correct"
fi

# Fix 3: remove deprecated acl allow execute always
if grep -q 'acl allow execute always' "$SMB"; then
    sed -i '/acl allow execute always/d' "$SMB"
    echo -e "  ${G}REMOVED: acl allow execute always (deprecated)${X}"
fi

# Fix 4: add force create mode + force directory mode after each directory mask line (if missing)
for SHARE in storage soft user; do
    if grep -q "^\[$SHARE\]" "$SMB"; then
        if ! awk "/^\[$SHARE\]/,/^\[/" "$SMB" | grep -q 'force create mode'; then
            sed -i "/^\[$SHARE\]/,/^\[/{/directory mask = 0775/a\\   force create mode = 0775\n   force directory mode = 0775"}" "$SMB"
            echo -e "  ${G}ADDED: force create/directory mode to [$SHARE]${X}"
        else
            echo -e "  OK: force create mode already in [$SHARE]"
        fi
    fi
done

# Fix 5: folder permissions
[ -d /storage ]      && chmod 0775 /storage      && echo -e "  ${G}FIXED: /storage chmod 0775${X}"
[ -d /storage/soft ] && chmod 2775 /storage/soft  && echo -e "  ${G}FIXED: /storage/soft chmod 2775${X}"
[ -d /storage/user ] && chmod 2775 /storage/user  && echo -e "  ${G}FIXED: /storage/user chmod 2775${X}"

# Validate + restart
if testparm -s >/dev/null 2>&1; then
    systemctl restart smbd nmbd 2>/dev/null
    echo -e "  ${G}OK: smb.conf valid -- smbd restarted${X}"
else
    echo -e "  ${R}WARNING: testparm failed -- check smb.conf manually!${X}"
    testparm -s 2>&1 | tail -5
fi

echo
echo "  === RESULT on $(hostname) ==="
grep 'create mask\|directory mask\|force create mode\|force directory mode' "$SMB"
echo "  Folders:"
ls -lad /storage /storage/soft /storage/user 2>/dev/null
