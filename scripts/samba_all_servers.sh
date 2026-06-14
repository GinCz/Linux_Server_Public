#!/bin/bash
# =============================================================================
# samba_all_servers.sh — Audit + fix Samba on ALL servers via SSH
# Version     : v2026.06.14b
# Description : Connects via SSH key to every server listed in
#               /root/.server_alliances.conf (format: NAME IP [port])
#               and to the two main servers (109 + 222).
#
#               On each server performs:
#               1. CHECK  — smbd running? shares exist? permissions correct?
#               2. FIX    — if anything is wrong, applies fixes automatically
#
#               Expected structure (same on ALL servers):
#               /storage/soft        — vlad (RW), usr (RO)   [share: soft]
#               /storage/soft/user   — vlad (RW), usr (RW)   [share: user]
#
# Usage       : bash /root/Linux_Server_Public/scripts/samba_all_servers.sh
# Requirements: SSH key auth configured on all servers (no password prompt)
# = Rooted by VladiMIR + AI | v2026.06.14b | github.com/GinCz =
# =============================================================================
clear

G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; R='\033[1;31m'; M='\033[1;35m'; X='\033[0m'

echo -e "${Y}============================================================${X}"
echo -e "${Y}   SAMBA ALL-SERVERS AUDIT + FIX  v2026.06.14b${X}"
echo -e "${Y}   = Rooted by VladiMIR + AI | github.com/GinCz =${X}"
echo -e "${Y}============================================================${X}"
echo -e "  Target structure on every server:"
echo -e "    ${C}/storage/soft${X}       — vlad (RW), usr (RO)  → share [soft]"
echo -e "    ${C}/storage/soft/user${X}  — vlad (RW), usr (RW)  → share [user]"
echo

# =============================================================================
# REMOTE PAYLOAD — written to a temp file, then sent via SSH
# Avoids ALL heredoc-inside-heredoc quoting issues
# =============================================================================

REMOTE_FILE=$(mktemp /tmp/samba_audit_XXXXXX.sh)
chmod +x "$REMOTE_FILE"

cat > "$REMOTE_FILE" << 'REMOTE_SCRIPT_EOF'
#!/bin/bash
set -uo pipefail
G="\033[1;32m"; Y="\033[1;33m"; C="\033[1;36m"; R="\033[1;31m"; X="\033[0m"
ISSUES=0
FIXES=0

ok()  { echo -e "  ${G}OK${X}  $*"; }
bad() { echo -e "  ${R}BAD${X} $*"; ISSUES=$((ISSUES+1)); }
fix() { echo -e "  ${Y}FIX${X} $*"; FIXES=$((FIXES+1)); }
sep() { echo -e "${C}--- $* ---${X}"; }

sep "System"
echo "  Host: $(hostname)  IP: $(hostname -I | awk '{print $1}')"
echo "  OS: $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')"

# ---------- [1] Samba installed -----------------------------------------------
sep "1. Samba installed"
if ! command -v smbpasswd >/dev/null 2>&1; then
    bad "Samba NOT installed — installing..."
    apt-get install -y samba python3 fail2ban >/dev/null 2>&1
    fix "Samba installed"
else
    ok "Samba installed: $(smbd --version 2>/dev/null | head -1)"
fi

# ---------- [2] smbd running --------------------------------------------------
sep "2. smbd service"
if systemctl is-active --quiet smbd 2>/dev/null; then
    ok "smbd is running"
else
    bad "smbd is NOT running"
    systemctl start smbd nmbd 2>/dev/null || true
    systemctl enable smbd nmbd 2>/dev/null || true
    fix "smbd started"
fi

# ---------- [3] Linux users ---------------------------------------------------
sep "3. Linux users: vlad, usr"
for U in vlad usr; do
    if id "$U" &>/dev/null; then
        ok "user $U exists"
    else
        bad "user $U missing"
        useradd -M -s /sbin/nologin "$U" 2>/dev/null || true
        fix "created user $U"
    fi
done

if id usr &>/dev/null && id vlad &>/dev/null; then
    if id usr | grep -qw vlad; then
        ok "usr is in group vlad"
    else
        bad "usr NOT in group vlad"
        usermod -aG vlad usr 2>/dev/null || true
        fix "added usr to group vlad"
    fi
fi

# ---------- [4] Samba users ---------------------------------------------------
sep "4. Samba users (pdbedit)"
for U in vlad usr; do
    if pdbedit -L 2>/dev/null | grep -q "^${U}:"; then
        ok "samba user $U exists"
    else
        bad "samba user $U missing from pdbedit"
        echo -e "  ${Y}  Run on this server: smbpasswd -a $U${X}"
    fi
done

# ---------- [5] Folders -------------------------------------------------------
sep "5. Folder structure"
for DIR in /storage/soft /storage/soft/user; do
    if [ -d "$DIR" ]; then
        ok "exists: $DIR"
    else
        bad "MISSING: $DIR"
        mkdir -p "$DIR"
        fix "created $DIR"
    fi
done

# ---------- [6] Ownership /storage/soft --------------------------------------
sep "6. Permissions on /storage/soft"
OWNER=$(stat -c "%U:%G" /storage/soft 2>/dev/null)
PERMS=$(stat -c "%a" /storage/soft 2>/dev/null)
if [ "$OWNER" = "vlad:vlad" ]; then
    ok "owner: $OWNER"
else
    bad "owner: $OWNER (expected vlad:vlad)"
    chown vlad:vlad /storage/soft
    fix "chown vlad:vlad /storage/soft"
fi
if [ "$PERMS" = "2770" ]; then
    ok "perms: $PERMS"
else
    bad "perms: $PERMS (expected 2770)"
    chmod 2770 /storage/soft
    fix "chmod 2770 /storage/soft"
fi

# ---------- [7] Ownership /storage/soft/user ---------------------------------
sep "7. Permissions on /storage/soft/user"
OWNER2=$(stat -c "%U:%G" /storage/soft/user 2>/dev/null)
PERMS2=$(stat -c "%a" /storage/soft/user 2>/dev/null)
if [ "$OWNER2" = "vlad:vlad" ]; then
    ok "owner: $OWNER2"
else
    bad "owner: $OWNER2 (expected vlad:vlad)"
    chown vlad:vlad /storage/soft/user
    fix "chown vlad:vlad /storage/soft/user"
fi
if [ "$PERMS2" = "2770" ]; then
    ok "perms: $PERMS2"
else
    bad "perms: $PERMS2 (expected 2770)"
    chmod 2770 /storage/soft/user
    fix "chmod 2770 /storage/soft/user"
fi

# ---------- [8] Write test: vlad → /storage/soft ----------------------------
sep "8. Write test: vlad → /storage/soft"
if sudo -u vlad touch /storage/soft/.samba_writetest 2>/dev/null; then
    ok "vlad can WRITE to /storage/soft"
    rm -f /storage/soft/.samba_writetest
else
    bad "vlad CANNOT write to /storage/soft"
    chown vlad:vlad /storage/soft
    chmod 2770 /storage/soft
    fix "fixed perms on /storage/soft"
fi

# ---------- [9] Write restriction: usr → /storage/soft ----------------------
sep "9. Write restriction: usr → /storage/soft (must be DENIED)"
if sudo -u usr touch /storage/soft/.samba_usr_test 2>/dev/null; then
    bad "usr CAN write to /storage/soft — should be READ-ONLY!"
    setfacl -m u:usr:r-x /storage/soft 2>/dev/null || true
    fix "applied ACL: usr r-x on /storage/soft"
    rm -f /storage/soft/.samba_usr_test 2>/dev/null || true
else
    ok "usr correctly DENIED write on /storage/soft"
fi

# ---------- [10] Write test: usr → /storage/soft/user ----------------------
sep "10. Write test: usr → /storage/soft/user"
if sudo -u usr touch /storage/soft/user/.samba_usr_writetest 2>/dev/null; then
    ok "usr can WRITE to /storage/soft/user"
    rm -f /storage/soft/user/.samba_usr_writetest 2>/dev/null || true
else
    bad "usr CANNOT write to /storage/soft/user"
    chmod 2770 /storage/soft/user
    setfacl -m u:usr:rwx /storage/soft/user 2>/dev/null || true
    fix "fixed perms on /storage/soft/user"
fi

# ---------- [11] smb.conf shares ---------------------------------------------
sep "11. smb.conf shares"
SMB=/etc/samba/smb.conf
CONF_OK=true

check_share() {
    local SHARE=$1
    if grep -q "^\[${SHARE}\]" "$SMB" 2>/dev/null; then
        ok "[${SHARE}] exists in smb.conf"
    else
        bad "[${SHARE}] MISSING from smb.conf"
        CONF_OK=false
    fi
}

check_share "soft"
check_share "user"

if grep -A10 "^\[soft\]" "$SMB" 2>/dev/null | grep -q "write list.*vlad"; then
    ok "[soft] write list = vlad (usr is RO)"
else
    bad "[soft] write list missing or wrong"
    CONF_OK=false
fi

if grep -A10 "^\[user\]" "$SMB" 2>/dev/null | grep -q "writable.*yes"; then
    ok "[user] writable = yes (vlad+usr RW)"
else
    bad "[user] writable = yes missing"
    CONF_OK=false
fi

if [ "$CONF_OK" = "false" ]; then
    echo -e "  ${Y}Rewriting smb.conf shares...${X}"

    python3 -c "
import re, sys
try:
    content = open('$SMB').read()
except:
    content = ''
for s in ['user','soft']:
    content = re.sub(r'(?m)^\\[' + s + r'\\].*?(?=^\\[|\Z)', '', content, flags=re.DOTALL|re.MULTILINE)
content = re.sub(r'\n{3,}', '\n\n', content).rstrip() + '\n'
open('$SMB','w').write(content)
print('sections removed')
"

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
        && fix "smb.conf rewritten and validated" \
        || echo -e "  ${R}WARNING: testparm errors — run testparm manually${X}"

    systemctl restart smbd nmbd 2>/dev/null || true
fi

# ---------- [12] fail2ban -----------------------------------------------------
sep "12. fail2ban samba jail"
if fail2ban-client status samba >/dev/null 2>&1; then
    BANNED=$(fail2ban-client status samba 2>/dev/null | awk '/Currently banned/{print $NF}')
    ok "fail2ban samba jail ACTIVE (banned now: ${BANNED})"
else
    bad "fail2ban samba jail NOT active"
    echo -e "  ${Y}  Run: bash /root/Linux_Server_Public/scripts/samba_setup.sh${X}"
fi

# ---------- SUMMARY -----------------------------------------------------------
echo
echo -e "${Y}============================================================${X}"
if [ "$ISSUES" -eq 0 ]; then
    echo -e "${G}   ALL OK — no issues found${X}"
else
    echo -e "${Y}   Issues found: ${ISSUES} / Fixes applied: ${FIXES}${X}"
    if [ "$FIXES" -lt "$ISSUES" ]; then
        echo -e "${R}   WARNING: $((ISSUES - FIXES)) issue(s) could NOT be auto-fixed${X}"
        echo -e "${Y}   Run manually: bash /root/Linux_Server_Public/scripts/samba_setup.sh${X}"
    else
        echo -e "${G}   All issues fixed automatically${X}"
    fi
fi
echo -e "${Y}============================================================${X}"
REMOTE_SCRIPT_EOF

# =============================================================================
# BUILD SERVER LIST
# =============================================================================
declare -A SERVERS

# Main servers (hardcoded)
SERVERS["RU-109"]="212.109.223.109:22"
SERVERS["EU-222"]="152.53.182.222:22"

# Read VPN nodes from .server_alliances.conf if it exists
CONF="/root/.server_alliances.conf"
if [ -f "$CONF" ]; then
    echo -e "${C}Reading server list from $CONF ...${X}"
    while IFS= read -r LINE; do
        [[ "$LINE" =~ ^#.*$ ]] && continue
        [[ -z "$LINE" ]] && continue
        # Format: export VARNAME="IP"
        if [[ "$LINE" =~ export[[:space:]]+([A-Za-z0-9_]+)[[:space:]]*=[[:space:]]*\"?([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\"? ]]; then
            NAME="${BASH_REMATCH[1]}"
            IP="${BASH_REMATCH[2]}"
            SERVERS["$NAME"]="${IP}:22"
            continue
        fi
        # Format: NAME IP [port]
        read -r NAME IP PORT_OPT <<< "$LINE"
        if [[ "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            PORT="${PORT_OPT:-22}"
            SERVERS["$NAME"]="${IP}:${PORT}"
        fi
    done < "$CONF"
fi

TOTAL=${#SERVERS[@]}
echo -e "${C}Found ${TOTAL} server(s) to check:${X}"
for NAME in "${!SERVERS[@]}"; do
    ADDR="${SERVERS[$NAME]}"
    IP="${ADDR%%:*}"
    PORT="${ADDR##*:}"
    echo -e "  ${M}${NAME}${X} \u2192 ${IP}:${PORT}"
done
echo

# =============================================================================
# PROCESS EACH SERVER
# =============================================================================
PASS=0; FAIL=0; WARN=0; SKIP=0
declare -A RESULTS
MY_IP=$(hostname -I | awk '{print $1}')

for NAME in "${!SERVERS[@]}"; do
    ADDR="${SERVERS[$NAME]}"
    IP="${ADDR%%:*}"
    PORT="${ADDR##*:}"

    echo -e "${Y}\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501${X}"
    echo -e "${M}\u25b6 SERVER: ${NAME}  (${IP}:${PORT})${X}"
    echo -e "${Y}\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501${X}"

    # Skip self
    if [[ "$IP" == "$MY_IP" ]]; then
        echo -e "  ${C}Skipping self (this is the current server)${X}"
        SKIP=$((SKIP+1))
        RESULTS["$NAME"]="SKIP (self)"
        echo
        continue
    fi

    # Test SSH connectivity
    if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
            -p "$PORT" "root@${IP}" "echo ok" >/dev/null 2>&1; then
        echo -e "  ${R}CANNOT CONNECT via SSH — skipping${X}"
        echo -e "  ${Y}Check: ssh -p ${PORT} root@${IP}${X}"
        FAIL=$((FAIL+1))
        RESULTS["$NAME"]="FAIL (SSH unreachable)"
        echo
        continue
    fi

    # Copy script and run on remote
    RTMP="/tmp/samba_audit_remote.sh"
    scp -q -o BatchMode=yes -o StrictHostKeyChecking=no \
        -P "$PORT" "$REMOTE_FILE" "root@${IP}:${RTMP}" 2>/dev/null

    OUTPUT=$(ssh -o BatchMode=yes -o ConnectTimeout=30 -o StrictHostKeyChecking=no \
        -p "$PORT" "root@${IP}" "bash ${RTMP}; rm -f ${RTMP}" 2>&1)
    EXIT_CODE=$?

    echo "$OUTPUT"

    if [ $EXIT_CODE -eq 0 ]; then
        if echo "$OUTPUT" | grep -q "ALL OK"; then
            PASS=$((PASS+1))
            RESULTS["$NAME"]="OK"
        elif echo "$OUTPUT" | grep -q "All issues fixed automatically"; then
            WARN=$((WARN+1))
            RESULTS["$NAME"]="FIXED"
        elif echo "$OUTPUT" | grep -q "could NOT be auto-fixed"; then
            WARN=$((WARN+1))
            RESULTS["$NAME"]="PARTIAL FIX — manual needed"
        else
            WARN=$((WARN+1))
            RESULTS["$NAME"]="WARN (check output)"
        fi
    else
        FAIL=$((FAIL+1))
        RESULTS["$NAME"]="FAIL (exit code $EXIT_CODE)"
    fi
    echo
done

# Cleanup temp file
rm -f "$REMOTE_FILE"

# =============================================================================
# FINAL REPORT
# =============================================================================
echo -e "${Y}\u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557${X}"
echo -e "${Y}\u2551              SAMBA ALL-SERVERS AUDIT REPORT                 \u2551${X}"
echo -e "${Y}\u255a\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255d${X}"
echo
printf "  %-22s  %s\n" "SERVER" "STATUS"
printf "  %-22s  %s\n" "----------------------" "------------------------------"
for NAME in "${!RESULTS[@]}"; do
    STATUS="${RESULTS[$NAME]}"
    case "$STATUS" in
        OK)            COLOR="$G" ;;
        FIXED)         COLOR="$Y" ;;
        "SKIP (self)") COLOR="$C" ;;
        *)             COLOR="$R" ;;
    esac
    printf "  %-22s  ${COLOR}%s${X}\n" "$NAME" "$STATUS"
done
echo
echo -e "  ${G}OK: ${PASS}${X}  |  ${Y}FIXED/WARN: ${WARN}${X}  |  ${R}FAIL: ${FAIL}${X}  |  ${C}SKIP: ${SKIP}${X}"
echo
[ "$FAIL"  -gt 0 ] && echo -e "  ${R}Some servers unreachable. Check SSH keys.${X}"
[ "$WARN"  -gt 0 ] && echo -e "  ${Y}Some fixes applied or manual smbpasswd needed.${X}"
[ "$WARN"  -gt 0 ] && echo -e "  ${Y}For passwords: smbpasswd -a vlad && smbpasswd -a usr${X}"
echo -e "${Y}============================================================${X}"
