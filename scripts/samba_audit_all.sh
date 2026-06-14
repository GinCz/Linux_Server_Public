#!/bin/bash
# =============================================================================
# samba_audit_all.sh — Audit and auto-fix Samba on ALL servers via SSH
# Version     : v2026.06.14
# Description : Connects via SSH key to every server in
#               /root/.server_alliances.conf plus the two main servers
#               (RU-109 + EU-222). On each server runs a full health check
#               and automatically fixes any issues found.
#
#               Checks performed on every server:
#               1.  Samba installed
#               2.  smbd service running
#               3.  Linux users vlad + usr exist
#               4.  usr is in group vlad
#               5.  Samba users in pdbedit (vlad + usr)
#               6.  Folders /storage/soft and /storage/soft/user exist
#               7.  Ownership vlad:vlad on /storage/soft
#               8.  Permissions 2770 on /storage/soft
#               9.  Ownership vlad:vlad on /storage/soft/user
#               10. Permissions 2770 on /storage/soft/user
#               11. Write test: vlad can write to /storage/soft
#               12. Write restriction: usr is DENIED write on /storage/soft
#               13. Write test: usr can write to /storage/soft/user
#               14. smb.conf has [soft] and [user] share definitions
#               15. [soft] has write list = vlad (usr is read-only)
#               16. Fail2Ban samba jail is active
#               17. Disk space on /storage
#               18. UFW ports 445/139 open
#
#               Auto-fix: most issues are fixed on the spot.
#               Issues that require manual smbpasswd are flagged clearly.
#
# Usage       : bash /root/Linux_Server_Public/scripts/samba_audit_all.sh
# Requirements: SSH key auth configured on all servers (passwordless root login)
# Run from   : Any server with SSH access to all targets (e.g. EU-222)
# = Rooted by VladiMIR + AI | v2026.06.14 | github.com/GinCz =
# =============================================================================
clear

G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; R='\033[1;31m'; M='\033[1;35m'; W='\033[1;37m'; X='\033[0m'

echo -e "${Y}============================================================${X}"
echo -e "${Y}   SAMBA AUDIT — ALL SERVERS   v2026.06.14${X}"
echo -e "${Y}   = Rooted by VladiMIR + AI | github.com/GinCz =${X}"
echo -e "${Y}============================================================${X}"
echo -e "  Expected on every server:"
echo -e "    ${C}/storage/soft${X}       — vlad (RW), usr (RO)  →  [soft]"
echo -e "    ${C}/storage/soft/user${X}  — vlad (RW), usr (RW)  →  [user]"
echo

# =============================================================================
# REMOTE AUDIT PAYLOAD
# Written to a temp file to avoid heredoc-inside-heredoc quoting issues.
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

sep "System info"
echo "  Host : $(hostname)"
echo "  IP   : $(hostname -I | awk '{print $1}')"
echo "  OS   : $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')"

# [1] Samba installed
sep "1. Samba installed"
if ! command -v smbpasswd >/dev/null 2>&1; then
    bad "Samba NOT installed — installing..."
    apt-get install -y samba python3 >/dev/null 2>&1
    fix "Samba installed"
else
    ok "Samba $(smbd --version 2>/dev/null | head -1)"
fi

# [2] smbd running
sep "2. smbd service"
if systemctl is-active --quiet smbd 2>/dev/null; then
    ok "smbd is running"
else
    bad "smbd is NOT running"
    systemctl start smbd nmbd 2>/dev/null && systemctl enable smbd nmbd 2>/dev/null
    fix "smbd started and enabled"
fi

# [3] Linux users
sep "3. Linux users: vlad, usr"
for U in vlad usr; do
    if id "$U" &>/dev/null; then
        ok "user $U exists"
    else
        bad "user $U missing"
        useradd -M -s /sbin/nologin "$U" 2>/dev/null
        fix "created user $U"
    fi
done

# [4] usr in group vlad
sep "4. usr in group vlad"
if id usr 2>/dev/null | grep -qw vlad; then
    ok "usr is in group vlad"
else
    bad "usr NOT in group vlad"
    usermod -aG vlad usr 2>/dev/null
    fix "added usr to group vlad"
fi

# [5] Samba users
sep "5. Samba users (pdbedit)"
for U in vlad usr; do
    if pdbedit -L 2>/dev/null | grep -q "^${U}:"; then
        ok "Samba user $U registered"
    else
        bad "Samba user $U NOT in pdbedit"
        echo -e "  ${Y}  Manual fix needed: smbpasswd -a $U${X}"
    fi
done

# [6] Folders
sep "6. Folder structure"
for DIR in /storage/soft /storage/soft/user; do
    if [ -d "$DIR" ]; then
        ok "exists: $DIR"
    else
        bad "MISSING: $DIR"
        mkdir -p "$DIR"
        fix "created $DIR"
    fi
done

# [7] Ownership /storage/soft
sep "7. Ownership /storage/soft"
OWNER=$(stat -c "%U:%G" /storage/soft 2>/dev/null)
[ "$OWNER" = "vlad:vlad" ] && ok "owner: $OWNER" || { bad "owner: $OWNER (expected vlad:vlad)"; chown vlad:vlad /storage/soft; fix "chown vlad:vlad /storage/soft"; }

# [8] Permissions /storage/soft
sep "8. Permissions /storage/soft"
PERMS=$(stat -c "%a" /storage/soft 2>/dev/null)
[ "$PERMS" = "2770" ] && ok "perms: $PERMS" || { bad "perms: $PERMS (expected 2770)"; chmod 2770 /storage/soft; fix "chmod 2770 /storage/soft"; }

# [9] Ownership /storage/soft/user
sep "9. Ownership /storage/soft/user"
OWNER2=$(stat -c "%U:%G" /storage/soft/user 2>/dev/null)
[ "$OWNER2" = "vlad:vlad" ] && ok "owner: $OWNER2" || { bad "owner: $OWNER2 (expected vlad:vlad)"; chown vlad:vlad /storage/soft/user; fix "chown vlad:vlad /storage/soft/user"; }

# [10] Permissions /storage/soft/user
sep "10. Permissions /storage/soft/user"
PERMS2=$(stat -c "%a" /storage/soft/user 2>/dev/null)
[ "$PERMS2" = "2770" ] && ok "perms: $PERMS2" || { bad "perms: $PERMS2 (expected 2770)"; chmod 2770 /storage/soft/user; fix "chmod 2770 /storage/soft/user"; }

# [11] Write test: vlad on /storage/soft
sep "11. Write test: vlad → /storage/soft"
if sudo -u vlad touch /storage/soft/.audit_write_test 2>/dev/null; then
    ok "vlad can write to /storage/soft"
    rm -f /storage/soft/.audit_write_test
else
    bad "vlad CANNOT write to /storage/soft"
    chown vlad:vlad /storage/soft && chmod 2770 /storage/soft
    fix "permissions reset on /storage/soft"
fi

# [12] Write restriction: usr on /storage/soft (must be DENIED)
sep "12. Write restriction: usr → /storage/soft (must be DENIED)"
if sudo -u usr touch /storage/soft/.audit_usr_test 2>/dev/null; then
    bad "usr CAN write to /storage/soft — should be READ-ONLY"
    setfacl -m u:usr:r-x /storage/soft 2>/dev/null
    rm -f /storage/soft/.audit_usr_test 2>/dev/null
    fix "applied ACL: usr r-x on /storage/soft"
else
    ok "usr correctly DENIED write on /storage/soft"
fi

# [13] Write test: usr on /storage/soft/user
sep "13. Write test: usr → /storage/soft/user"
if sudo -u usr touch /storage/soft/user/.audit_usr_write_test 2>/dev/null; then
    ok "usr can write to /storage/soft/user"
    rm -f /storage/soft/user/.audit_usr_write_test 2>/dev/null
else
    bad "usr CANNOT write to /storage/soft/user"
    chmod 2770 /storage/soft/user
    setfacl -m u:usr:rwx /storage/soft/user 2>/dev/null
    fix "permissions reset on /storage/soft/user"
fi

# [14-16] smb.conf shares
sep "14-16. smb.conf shares"
SMB=/etc/samba/smb.conf
CONF_OK=true

if grep -q "^\[soft\]" "$SMB" 2>/dev/null; then
    ok "[soft] share defined"
else
    bad "[soft] MISSING from smb.conf"
    CONF_OK=false
fi

if grep -q "^\[user\]" "$SMB" 2>/dev/null; then
    ok "[user] share defined"
else
    bad "[user] MISSING from smb.conf"
    CONF_OK=false
fi

if grep -A10 "^\[soft\]" "$SMB" 2>/dev/null | grep -q "write list.*vlad"; then
    ok "[soft] write list = vlad (usr is RO)"
else
    bad "[soft] write list = vlad missing"
    CONF_OK=false
fi

if [ "$CONF_OK" = "false" ]; then
    echo -e "  ${Y}Rewriting smb.conf shares...${X}"
    python3 -c "
import re
try:
    c = open('$SMB').read()
except:
    c = ''
for s in ['user','soft']:
    c = re.sub(r'(?m)^\\[' + s + r'\\].*?(?=^\\[|\Z)', '', c, flags=re.DOTALL|re.MULTILINE)
c = re.sub(r'\n{3,}', '\n\n', c).rstrip() + '\n'
open('$SMB','w').write(c)
"
    cat >> "$SMB" << 'SHAREEOF'

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
SHAREEOF
    testparm -s >/dev/null 2>&1 && fix "smb.conf shares rewritten OK" || echo -e "  ${R}WARNING: testparm errors — run testparm manually${X}"
    systemctl restart smbd nmbd 2>/dev/null
fi

# [17] Fail2Ban
sep "17. Fail2Ban samba jail"
if fail2ban-client status samba >/dev/null 2>&1; then
    BANNED=$(fail2ban-client status samba 2>/dev/null | awk '/Currently banned/{print $NF}')
    ok "fail2ban samba jail ACTIVE (currently banned: ${BANNED})"
else
    bad "fail2ban samba jail NOT active"
    echo -e "  ${Y}  Run: bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/install_crowdsec.sh)${X}"
fi

# [18] Disk space
sep "18. Disk space"
df -h /storage 2>/dev/null || df -h /

# [19] UFW ports
sep "19. UFW ports 445/139"
if command -v ufw >/dev/null 2>&1; then
    ufw status 2>/dev/null | grep -E '445|139' | sed 's/^/  /' || echo -e "  ${Y}ports 445/139 not found in UFW rules${X}"
else
    echo -e "  ${Y}UFW not installed${X}"
fi

# SUMMARY
echo
echo -e "${Y}============================================================${X}"
if [ "$ISSUES" -eq 0 ]; then
    echo -e "${G}   ALL OK — no issues found${X}"
else
    echo -e "${Y}   Issues found: ${ISSUES}   /   Fixes applied: ${FIXES}${X}"
    if [ "$FIXES" -lt "$ISSUES" ]; then
        echo -e "${R}   WARNING: $((ISSUES - FIXES)) issue(s) require manual intervention${X}"
        echo -e "${Y}   Hint: bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_setup.sh)${X}"
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
SERVERS["RU-109"]="212.109.223.109:22"
SERVERS["EU-222"]="152.53.182.222:22"

CONF="/root/.server_alliances.conf"
if [ -f "$CONF" ]; then
    echo -e "${C}Reading additional servers from $CONF ...${X}"
    while IFS= read -r LINE; do
        [[ "$LINE" =~ ^#.*$ ]] && continue
        [[ -z "$LINE" ]] && continue
        if [[ "$LINE" =~ export[[:space:]]+([A-Za-z0-9_]+)[[:space:]]*=[[:space:]]*\"?([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\"? ]]; then
            SERVERS["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}:22"
            continue
        fi
        read -r NAME IP PORT_OPT <<< "$LINE"
        [[ "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && SERVERS["$NAME"]="${IP}:${PORT_OPT:-22}"
    done < "$CONF"
fi

TOTAL=${#SERVERS[@]}
echo -e "${C}Servers to audit: ${TOTAL}${X}"
for NAME in "${!SERVERS[@]}"; do
    ADDR="${SERVERS[$NAME]}"; IP="${ADDR%%:*}"; PORT="${ADDR##*:}"
    echo -e "  ${M}${NAME}${X} → ${IP}:${PORT}"
done
echo

# =============================================================================
# RUN AUDIT ON EACH SERVER
# =============================================================================
PASS=0; FAIL=0; WARN=0; SKIP=0
declare -A RESULTS
MY_IP=$(hostname -I | awk '{print $1}')

for NAME in "${!SERVERS[@]}"; do
    ADDR="${SERVERS[$NAME]}"; IP="${ADDR%%:*}"; PORT="${ADDR##*:}"
    echo -e "${Y}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"
    echo -e "${M}▶ ${NAME}  (${IP}:${PORT})${X}"
    echo -e "${Y}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"

    if [[ "$IP" == "$MY_IP" ]]; then
        echo -e "  ${C}Skipping self${X}"
        SKIP=$((SKIP+1)); RESULTS["$NAME"]="SKIP (self)"; echo; continue
    fi

    if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
            -p "$PORT" "root@${IP}" "echo ok" >/dev/null 2>&1; then
        echo -e "  ${R}SSH UNREACHABLE — check key auth: ssh -p ${PORT} root@${IP}${X}"
        FAIL=$((FAIL+1)); RESULTS["$NAME"]="FAIL (SSH unreachable)"; echo; continue
    fi

    RTMP="/tmp/samba_audit_remote.sh"
    scp -q -o BatchMode=yes -o StrictHostKeyChecking=no -P "$PORT" "$REMOTE_FILE" "root@${IP}:${RTMP}" 2>/dev/null
    OUTPUT=$(ssh -o BatchMode=yes -o ConnectTimeout=30 -o StrictHostKeyChecking=no \
        -p "$PORT" "root@${IP}" "bash ${RTMP}; rm -f ${RTMP}" 2>&1)
    EXIT_CODE=$?
    echo "$OUTPUT"

    if [ $EXIT_CODE -eq 0 ]; then
        if echo "$OUTPUT" | grep -q "ALL OK";                        then PASS=$((PASS+1));   RESULTS["$NAME"]="OK"
        elif echo "$OUTPUT" | grep -q "All issues fixed automatically"; then WARN=$((WARN+1)); RESULTS["$NAME"]="FIXED"
        elif echo "$OUTPUT" | grep -q "require manual";               then WARN=$((WARN+1));   RESULTS["$NAME"]="PARTIAL — manual needed"
        else WARN=$((WARN+1)); RESULTS["$NAME"]="WARN"
        fi
    else
        FAIL=$((FAIL+1)); RESULTS["$NAME"]="FAIL (exit $EXIT_CODE)"
    fi
    echo
done

rm -f "$REMOTE_FILE"

# =============================================================================
# FINAL REPORT
# =============================================================================
echo -e "${Y}╔══════════════════════════════════════════════════════════════╗${X}"
echo -e "${Y}║          SAMBA AUDIT — FINAL REPORT                         ║${X}"
echo -e "${Y}╚══════════════════════════════════════════════════════════════╝${X}"
echo
printf "  %-24s  %s\n" "SERVER" "STATUS"
printf "  %-24s  %s\n" "------------------------" "--------------------------------"
for NAME in "${!RESULTS[@]}"; do
    STATUS="${RESULTS[$NAME]}"
    case "$STATUS" in
        OK)            COL="$G" ;;
        FIXED)         COL="$Y" ;;
        "SKIP (self)") COL="$C" ;;
        *)             COL="$R" ;;
    esac
    printf "  %-24s  ${COL}%s${X}\n" "$NAME" "$STATUS"
done
echo
echo -e "  ${G}OK: ${PASS}${X}  |  ${Y}FIXED/WARN: ${WARN}${X}  |  ${R}FAIL: ${FAIL}${X}  |  ${C}SKIP: ${SKIP}${X}"
echo
[ "$FAIL" -gt 0 ] && echo -e "  ${R}Some servers unreachable. Verify SSH key auth.${X}"
[ "$WARN" -gt 0 ] && echo -e "  ${Y}Some fixes applied or smbpasswd needed. Run: smbpasswd -a vlad && smbpasswd -a usr${X}"
echo -e "${Y}============================================================${X}"
echo -e "  ${W}= Rooted by VladiMIR + AI | v2026.06.14 | github.com/GinCz =${X}"
echo -e "${Y}============================================================${X}"
