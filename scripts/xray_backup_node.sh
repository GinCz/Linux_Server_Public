#!/usr/bin/env bash
clear
# =============================================================================
#  xray_backup_node.sh  -  Weekly backup of x-ui / Xray config from VPN node
# =============================================================================
#  = Rooted by VladiMIR | AI =
# -----------------------------------------------------------------------------
#  Version    : v2026-04-28
#  Author     : Ing. VladiMIR Bulantsev
#  GitHub     : https://github.com/GinCz/Linux_Server_Public
#  License    : MIT
# =============================================================================
#
#  DESCRIPTION:
#    Backup script for x-ui panel and Xray VPN configuration files.
#    Designed to run on the main archive server (server ***.***.***.**2)
#    and pull configs from a remote VPN node via SSH.
#
#    Previously VPN nodes ran AmneziaWG (Docker-based) — backed up via
#    docker commit/save. After migration to x-ui/Xray, this script replaces
#    that approach: instead of Docker image snapshots, it archives
#    x-ui database and Xray config directories directly.
#
#  HOW IT WORKS:
#    1. SSH into the VPN node
#    2. Detect all x-ui / Xray config directories
#    3. Create tar.gz archive on the remote node (/tmp)
#    4. Download archive to LOCAL /BACKUP/vpn/<NODE_LABEL>/xray/
#    5. Delete remote temp archive
#    6. Rotate old archives (keep last KEEP)
#    7. Send Telegram notification (success or failure)
#
#  WHAT IS BACKED UP (auto-detected, skipped if not present):
#    /usr/local/x-ui/        - x-ui binary + SQLite database (x-ui.db)
#    /etc/x-ui/              - x-ui settings / alternate config location
#    /usr/local/share/xray/  - Xray certificate files
#    /root/cert/             - SSL/TLS certificates (if present)
#    /etc/xray/              - Xray config.json (alternate location)
#
#  SCHEDULE (cron on main server ***.***.***.**2):
#    Sunday 03:00
#    0 3 * * 0  bash /root/xray_backup_node.sh >> /var/log/xray_backup_node.log 2>&1
#
#  SETUP REQUIREMENTS:
#    1. SSH key auth configured for the VPN node (no password prompt)
#       ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519
#       ssh-copy-id -i /root/.ssh/id_ed25519 root@<NODE_IP>
#    2. /root/.server_env must exist on main server with TG_TOKEN and TG_CHAT_ID
#       Example:
#         TG_TOKEN="123456789:AAxxxxxx"
#         TG_CHAT_ID="-100xxxxxxxxxx"
#
#  ALIAS (add to /root/.bashrc on main server):
#    alias f5xray='bash /root/xray_backup_node.sh'
#
#  VPN NODE EXAMPLE (this script is for a single node):
#    NODE_*9     ***.***.***..*9     x-ui + Xray + Uptime Kuma
#
#  RESULT (2026-04-28):
#    Archive ~2-5MB  |  Transfer ~30s  |  KEEP=8 (2 months history)
#
# =============================================================================

# --- Colors ---
CY="\033[1;96m"; GN="\033[1;92m"; LG="\033[38;5;120m"
YL="\033[1;93m"; LY="\033[38;5;228m"; PK="\033[1;95m"
RD="\033[1;91m"; OR="\033[38;5;214m"; WH="\033[1;97m"; X="\033[0m"
HR="${CY}$(printf '\u2550%.0s' {1..90})${X}"

# =============================================================================
#  CONFIG  — fill in your values before running
# =============================================================================
NODE_LABEL="NODE_*9"          # Human-readable name, last IP digit shown
NODE_IP="144.124.232.9"       # Replace *** with actual IP octets (keep last digit)
SSH_KEY="/root/.ssh/id_ed25519"
SSH_PORT=22
SSH_USER="root"
REMOTE_TMP="/tmp"
LOCAL_BACKUP_ROOT="/BACKUP/vpn/${NODE_LABEL}/xray"
KEEP=8                        # Weekly backups: 8 = ~2 months of history

# Telegram — loaded from /root/.server_env (TG_TOKEN, TG_CHAT_ID)
[ -f /root/.server_env ] && source /root/.server_env
TELEGRAM_TOKEN="${TG_TOKEN:-}"
TELEGRAM_CHAT_ID="${TG_CHAT_ID:-}"

# =============================================================================
#  HELPERS
# =============================================================================
log()    { echo -e "${CY}$(date +%H:%M:%S)${X} $1"; }
log_ok() { echo -e "${GN}$(date +%H:%M:%S) \u2714 $1${X}"; }
fail()   { echo -e "${RD}$(date +%H:%M:%S) \u2718 ERROR: $1${X}"; tg "\u274c *XRAY BACKUP FAILED* | ${NODE_LABEL}%0A${1}%0A$(date '+%Y-%m-%d %H:%M')"; exit 1; }

tg() {
    [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ] && return
    curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}&text=$1&parse_mode=Markdown" >/dev/null
}

rotate_local() {
    ls -t "${LOCAL_BACKUP_ROOT}"/*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f
}

SSH_CMD="ssh -i ${SSH_KEY} -p ${SSH_PORT} -o StrictHostKeyChecking=no -o ConnectTimeout=15 -o BatchMode=yes ${SSH_USER}@${NODE_IP}"
SCP_CMD="scp -i ${SSH_KEY} -P ${SSH_PORT} -o StrictHostKeyChecking=no -o ConnectTimeout=15 -o BatchMode=yes"

DATE=$(date +%Y-%m-%d_%H-%M)
ARCH_NAME="xray_${NODE_LABEL}_${DATE}.tar.gz"
REMOTE_ARCH="${REMOTE_TMP}/${ARCH_NAME}"
LOCAL_ARCH="${LOCAL_BACKUP_ROOT}/${ARCH_NAME}"
START_TIME=$(date +%s)

# =============================================================================
#  HEADER
# =============================================================================
echo -e "$HR"
echo -e "  \U0001f6e1  ${WH}XRAY BACKUP${X}  \u00b7  ${YL}${NODE_LABEL}${X}  \u00b7  ${CY}${NODE_IP}${X}"
echo -e "  \U0001f4c5 ${CY}$(date '+%Y-%m-%d')${X}  ${WH}$(date '+%H:%M:%S')${X}"
echo -e "  \U0001f4c2 ${YL}${LOCAL_BACKUP_ROOT}${X}   \U0001f504 keep: ${CY}${KEEP}${X} archives"
echo -e "$HR"

mkdir -p "$LOCAL_BACKUP_ROOT"

# =============================================================================
#  STEP 1 — SSH check
# =============================================================================
log "Checking SSH connection \u2192 ${NODE_LABEL} (${NODE_IP})..."
if ! $SSH_CMD "exit" 2>/dev/null; then
    fail "SSH connection FAILED to ${NODE_IP} — check key and connectivity"
fi
log_ok "SSH OK \u2192 ${NODE_IP}"

# =============================================================================
#  STEP 2 — Verify x-ui installation
# =============================================================================
log "Checking x-ui installation on ${NODE_LABEL}..."
XUI_EXISTS=$($SSH_CMD "[ -d /usr/local/x-ui ] && echo yes || echo no" 2>/dev/null)
if [ "$XUI_EXISTS" != "yes" ]; then
    fail "x-ui not found at /usr/local/x-ui on ${NODE_IP} — is x-ui installed?"
fi
XUI_VER=$($SSH_CMD "x-ui version 2>/dev/null | head -1 || echo unknown" 2>/dev/null)
log_ok "x-ui found on ${NODE_LABEL}  (${XUI_VER})"

# =============================================================================
#  STEP 3 — Check remote disk space (need at least 200MB in /tmp)
# =============================================================================
log "Checking remote /tmp disk space..."
REMOTE_FREE=$($SSH_CMD "df -m /tmp | awk 'NR==2{print \$4}'" 2>/dev/null || echo 0)
if [ "${REMOTE_FREE:-0}" -lt 200 ]; then
    fail "Not enough space on remote /tmp: ${REMOTE_FREE}MB free (need 200MB)"
fi
log_ok "Remote /tmp free: ${REMOTE_FREE}MB"

# =============================================================================
#  STEP 4 — Create archive on remote node
# =============================================================================
log "Creating archive on ${NODE_LABEL}..."
T_START=$(date +%s)

REMOTE_RESULT=$($SSH_CMD "
    DIRS=''
    [ -d /usr/local/x-ui ]           && DIRS=\"\$DIRS /usr/local/x-ui\"
    [ -d /etc/x-ui ]                 && DIRS=\"\$DIRS /etc/x-ui\"
    [ -d /usr/local/share/xray ]     && DIRS=\"\$DIRS /usr/local/share/xray\"
    [ -d /root/cert ]                && DIRS=\"\$DIRS /root/cert\"
    [ -d /etc/xray ]                 && DIRS=\"\$DIRS /etc/xray\"
    if [ -z \"\$DIRS\" ]; then
        echo 'NO_DIRS'
        exit 1
    fi
    tar czf ${REMOTE_ARCH} \$DIRS 2>/dev/null && echo \"OK:\$(du -sh ${REMOTE_ARCH} | cut -f1)\" || echo 'TAR_FAIL'
" 2>/dev/null)

T_END=$(date +%s)
ARCHIVE_ELAPSED=$((T_END - T_START))

if [[ "$REMOTE_RESULT" == "NO_DIRS" ]]; then
    fail "No x-ui/Xray directories found on ${NODE_IP}"
fi
if [[ "$REMOTE_RESULT" == "TAR_FAIL" ]] || [[ -z "$REMOTE_RESULT" ]]; then
    fail "tar archive creation FAILED on ${NODE_IP}"
fi

REMOTE_SZ=$(echo "$REMOTE_RESULT" | grep -oP 'OK:\K.*' || echo "?")
log_ok "Archive created on remote: ${REMOTE_SZ}  (${ARCHIVE_ELAPSED}s)"

# =============================================================================
#  STEP 5 — Download archive to main server
# =============================================================================
log "Downloading archive from ${NODE_LABEL}..."
T_START=$(date +%s)
$SCP_CMD "${SSH_USER}@${NODE_IP}:${REMOTE_ARCH}" "${LOCAL_ARCH}" 2>/dev/null
T_END=$(date +%s)
DOWNLOAD_ELAPSED=$((T_END - T_START))

# Cleanup remote temp
$SSH_CMD "rm -f ${REMOTE_ARCH}" 2>/dev/null

# =============================================================================
#  STEP 6 — Verify download
# =============================================================================
if [ ! -s "$LOCAL_ARCH" ]; then
    fail "Downloaded archive is empty or missing: ${LOCAL_ARCH}"
fi

LOCAL_SZ=$(du -sh "$LOCAL_ARCH" | cut -f1)
RAW=$(stat -c%s "$LOCAL_ARCH" 2>/dev/null || echo 0)
SPEED=""
[ "$DOWNLOAD_ELAPSED" -gt 0 ] && \
    SPEED=$(echo "scale=1; $RAW / $DOWNLOAD_ELAPSED / 1048576" | bc 2>/dev/null) && \
    SPEED="  ${CY}@ ${LG}${SPEED} MB/s${X}"

log_ok "${ARCH_NAME}"
echo -e "     ${WH}\u251c\u2500 Size     : ${GN}${LOCAL_SZ}${X}"
echo -e "     ${WH}\u251c\u2500 Archive  : ${CY}${ARCHIVE_ELAPSED}s${X}  |  Download: ${CY}${DOWNLOAD_ELAPSED}s${SPEED}${X}"
echo -e "     ${WH}\u2514\u2500 Path     : ${YL}${LOCAL_ARCH}${X}"

# =============================================================================
#  STEP 7 — Rotate old archives
# =============================================================================
rotate_local
CNT=$(ls "${LOCAL_BACKUP_ROOT}"/*.tar.gz 2>/dev/null | wc -l)
echo -e "     ${PK}\u25a4 Archives : ${WH}${CNT}/${KEEP} kept${X}"
ls -t "${LOCAL_BACKUP_ROOT}"/*.tar.gz 2>/dev/null | head -5 | while IFS= read -r f; do
    F_SZ=$(du -sh "$f" 2>/dev/null | cut -f1)
    F_DATE=$(stat -c%y "$f" 2>/dev/null | cut -d' ' -f1)
    echo -e "       ${CY}\u2514\u2500 ${OR}${F_SZ}${X}  ${WH}${F_DATE}${X}  $(basename "$f")"
done

# =============================================================================
#  SUMMARY
# =============================================================================
END_TIME=$(date +%s)
TOTAL_ELAPSED=$((END_TIME - START_TIME))

echo -e "$HR"
echo -e "  ${GN}\u2714  BACKUP COMPLETE \u2014 NO ERRORS${X}"
echo -e "  ${WH}\u251c\u2500 Node      : ${YL}${NODE_LABEL} (${NODE_IP})${X}"
echo -e "  ${WH}\u251c\u2500 Archive   : ${GN}${LOCAL_SZ}${X}"
echo -e "  ${WH}\u251c\u2500 Archives  : ${CY}${CNT}/${KEEP} kept${X}"
echo -e "  ${WH}\u251c\u2500 Duration  : ${CY}${TOTAL_ELAPSED}s${X}"
echo -e "  ${WH}\u2514\u2500 Finished  : ${YL}$(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "$HR"
echo -e "              ${YL}= Rooted by VladiMIR | AI =${X}"
echo

tg "\u2705 *XRAY BACKUP OK* | ${NODE_LABEL}%0A%0ASize: ${LOCAL_SZ}%0AArchives: ${CNT}/${KEEP}%0ATime: ${TOTAL_ELAPSED}s%0A$(date '+%Y-%m-%d %H:%M')"
