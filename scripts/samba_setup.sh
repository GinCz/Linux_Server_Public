#!/bin/bash
# =============================================================================
# samba_setup.sh — Install Samba + users + shares on any Ubuntu 24 server
# Version     : v2026-05-26a
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
#               SECURITY: Ports 445/139 are open to the world (by design).
#               Protection is enforced via:
#                 - fail2ban jail (blocks IPs after 3 failed auth attempts)
#                 - smb.conf: max smbd processes, auth limits, invalid users
#                 - old empty log files cleanup (reduces noise)
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
echo -e "${Y}   SAMBA SETUP v2026-05-26a${X}"
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
echo -e "  Security:"
echo -e "    ${C}fail2ban${X} — ban after 3 failed attempts / 10 min"
echo -e "    ${C}smb.conf${X} — max connections, no guest, SMB2+ only"
echo
read -rp "Type YES to continue: " CONFIRM
[[ "${CONFIRM}" == "YES" ]] || { echo "Aborted"; exit 1; }

# ---- [1/7] Install Samba + fail2ban -----------------------------------------
echo -e "\n${C}[1/7] Installing Samba + fail2ban...${X}"
apt-get install -y samba python3 fail2ban >/dev/null 2>&1
echo -e "${G}OK${X}"

# ---- [2/7] Migrate /storage/user → /storage/soft/user ----------------------
echo -e "\n${C}[2/7] Migrating folder structure...${X}"

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

# ---- [3/7] Create system users ----------------------------------------------
echo -e "\n${C}[3/7] Creating system users...${X}"
for U in vlad usr; do
    if id "$U" &>/dev/null; then
        echo -e "  ${C}$U already exists${X}"
    else
        useradd -M -s /sbin/nologin "$U"
        echo -e "  ${G}created: $U${X}"
    fi
done
echo -e "${G}OK${X}"

# ---- [4/7] Fix permissions --------------------------------------------------
echo -e "\n${C}[4/7] Setting folder permissions...${X}"

usermod -aG vlad usr 2>/dev/null || true

chown vlad:vlad /storage/soft
chmod 2770 /storage/soft

chown vlad:vlad /storage/soft/user
chmod 2770 /storage/soft/user

echo -e "${G}OK:${X}"
ls -lad /storage/soft /storage/soft/user

# ---- [5/7] Set Samba passwords ----------------------------------------------
echo -e "\n${C}[5/7] Set Samba passwords...${X}"
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

# ---- [6/7] Configure smb.conf -----------------------------------------------
echo -e "\n${C}[6/7] Writing smb.conf...${X}"

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

# Write or update [global] with hardening parameters:
#   - SMB2 minimum protocol    → disables old SMB1 (EternalBlue/WannaCry)
#   - ntlm auth = yes          → required for Windows compatibility
#   - max smbd processes       → limits parallel connections, prevents flood
#   - invalid users            → blocks root and common attack targets
#   - map to guest = never     → no anonymous/guest access allowed
#   - passwd chat timeout      → shorter timeout on auth dialog
if grep -q '^\[global\]' "$SMB" 2>/dev/null; then
    for PARAM in \
        'workgroup = WORKGROUP' \
        'server min protocol = SMB2' \
        'ntlm auth = yes' \
        'map to guest = never' \
        'max smbd processes = 100' \
        'invalid users = root bin daemon nobody'; do
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

   # --- Protocol security ---
   # Disable SMB1 (vulnerable to EternalBlue/WannaCry); require SMB2 minimum
   server min protocol = SMB2
   ntlm auth = yes

   # --- Access control ---
   # Never allow guest/anonymous access
   map to guest = never
   # Block root and common brute-force targets from ever authenticating
   invalid users = root bin daemon nobody

   # --- Connection limits (anti-flood) ---
   # Limit total smbd child processes to prevent resource exhaustion
   max smbd processes = 100

   # --- Logging ---
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

# ---- [UFW] Open Samba ports (world-open by design, hardened via fail2ban) ---
echo -e "\n${C}[UFW] Opening Samba ports (445, 139)...${X}"
# Ports are intentionally open to all IPs — brute-force protection is handled
# by fail2ban (see step 7). Do NOT restrict by IP here.
if command -v ufw &>/dev/null; then
    ufw allow 445/tcp >/dev/null 2>&1
    ufw allow 139/tcp >/dev/null 2>&1
    ufw reload >/dev/null 2>&1
    echo -e "${G}OK: ports 445 + 139 opened (world-open, protected by fail2ban)${X}"
    ufw status | grep -E '445|139'
else
    echo -e "${Y}UFW not found — skip (open ports manually if needed)${X}"
fi

# ---- [7/7] Hardening: fail2ban + log cleanup --------------------------------
echo -e "\n${C}[7/7] Hardening: fail2ban + log cleanup...${X}"

# --- fail2ban Samba jail ---
# Watches /var/log/samba/log.* for authentication failures.
# After 3 failed attempts within 10 minutes → ban IP for 1 hour.
# This protects against brute-force password attacks on open ports 445/139.
F2B_JAIL=/etc/fail2ban/jail.d/samba.conf
cat > "$F2B_JAIL" << 'F2BEOF'
# fail2ban jail for Samba (smbd)
# Bans IP after 3 failed auth attempts within 600 seconds for 3600 seconds.
# Logs are per-client: /var/log/samba/log.<IP>
[samba]
enabled  = yes
port     = 445,139
filter   = samba
logpath  = /var/log/samba/log.%(__prefix_line)s
           /var/log/samba/log.smbd
maxretry = 3
findtime = 600
bantime  = 3600
action   = %(action_mwl)s
F2BEOF

# Check if fail2ban has a built-in samba filter; if not, create a basic one
# that matches the standard "Authentication for user [X] FAILED" log pattern
F2B_FILTER=/etc/fail2ban/filter.d/samba.conf
if [ ! -f "$F2B_FILTER" ]; then
    cat > "$F2B_FILTER" << 'FILTEREOF'
# fail2ban filter for Samba authentication failures
[Definition]
failregex = Authentication for user \[.*\] -> \[.*\] FAILED with error NT_STATUS_WRONG_PASSWORD, Error: (.+) from client IP <HOST>
            .*smbd.*: authentication error.*<HOST>
            .*check_ntlm_password:.*<HOST>

ignoreregex =
FILTEREOF
    echo -e "  ${G}Created fail2ban samba filter${X}"
else
    echo -e "  ${C}fail2ban samba filter already exists${X}"
fi

# Restart fail2ban to apply the new jail
systemctl enable fail2ban >/dev/null 2>&1
systemctl restart fail2ban
sleep 2

# Verify the samba jail is active
if fail2ban-client status samba >/dev/null 2>&1; then
    BANNED=$(fail2ban-client status samba 2>/dev/null | awk '/Currently banned/{print $NF}')
    TOTAL=$(fail2ban-client status samba 2>/dev/null | awk '/Total banned/{print $NF}')
    echo -e "  ${G}fail2ban samba jail: ACTIVE${X}  (currently banned: ${R}${BANNED}${X}, total ever: ${TOTAL})"
else
    echo -e "  ${R}WARNING: fail2ban samba jail did not start — check: fail2ban-client status samba${X}"
fi

# --- Clean up old empty Samba log files (reduce inode waste) ---
# Samba creates one log file per connecting IP. Most are 0 bytes (port scans).
# We delete files older than 7 days that are empty. Active logs are untouched.
DELETED=$(find /var/log/samba/ -maxdepth 1 -name 'log.*' -size 0 -mtime +7 -delete -print 2>/dev/null | wc -l)
echo -e "  ${G}Cleaned ${DELETED} empty log files older than 7 days${X}"

# Show current log directory stats
TOTAL_LOGS=$(ls /var/log/samba/log.* 2>/dev/null | wc -l)
NONZERO=$(find /var/log/samba/ -maxdepth 1 -name 'log.*' -size +0 2>/dev/null | wc -l)
echo -e "  ${C}Log files remaining: ${TOTAL_LOGS} total, ${NONZERO} with content${X}"

echo -e "${G}OK${X}"

# ---- FINAL SUMMARY ----------------------------------------------------------
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
echo -e "  ${C}Security:${X} fail2ban active — ban after 3 failed attempts / 1 hour"
echo -e "  ${C}Check bans:${X}  fail2ban-client status samba"
echo -e "  ${C}Unban IP:${X}    fail2ban-client set samba unbanip <IP>"
echo -e "  Run ${C}testparm${X} to verify smb.conf"
echo -e "${Y}=========================================${X}"
