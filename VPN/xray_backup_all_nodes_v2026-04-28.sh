#!/usr/bin/env bash
clear
# =============================================================================
#  xray_backup_all_nodes.sh  -  Backup x-ui / Xray config from ALL VPN nodes
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
#    Iterates over all VPN nodes, detects x-ui installation,
#    archives x-ui/Xray config directories remotely, downloads
#    to /BACKUP/vpn/<NODE>/xray/ on the main server, rotates old archives.
#    Skips nodes where x-ui is not installed (no error).
#    Sends Telegram summary on completion.
#
#  WHAT IS BACKED UP (auto-detected, skipped if absent):
#    /usr/local/x-ui/        - x-ui binary + SQLite database (x-ui.db)
#    /etc/x-ui/              - x-ui alternate config location
#    /usr/local/share/xray/  - Xray certificate files
#    /root/cert/             - SSL/TLS certificates
#    /etc/xray/              - Xray config.json alternate location
#
#  SCHEDULE (cron on main server 152.53.182.222):
#    Sunday 03:30  (30 min after vpn_docker_backup.sh)
#    30 3 * * 0  bash /root/Linux_Server_Public/VPN/xray_backup_all_nodes_v2026-04-28.sh >> /var/log/xray_backup_all.log 2>&1
#
#  ALIAS (add to /root/.bashrc):
#    alias f5xray='bash /root/Linux_Server_Public/VPN/xray_backup_all_nodes_v2026-04-28.sh'
#
#  SETUP:
#    SSH key auth must be configured for all nodes:
#      ssh-copy-id -i /root/.ssh/id_ed25519 root@<NODE_IP>
#    /root/.server_env must contain TG_TOKEN and TG_CHAT_ID
#
# =============================================================================

# --- Colors ---
CY="\033[1;96m"; GN="\033[1;92m"; LG="\033[38;5;120m"
YL="\033[1;93m"; LY="\033[38;5;228m"; PK="\033[1;95m"
RD="\033[1;91m"; OR="\033[38;5;214m"; WH="\033[1;97m"; X="\033[0m"
HR="${CY}$(printf '\u2550%.0s' {1..93})${X}"

# =============================================================================
#  CONFIG
# =============================================================================
SSH_KEY="/root/.ssh/id_ed25519"
SSH_PORT=22
SSH_USER="root"
REMOTE_TMP="/tmp"
LOCAL_BACKUP_ROOT="/BACKUP/vpn"
KEEP=8          # Weekly: 8 = ~2 months history
DATE=$(date +%Y-%m-%d_%H-%M)
MAIN_HOST="222-DE-NetCup"
MAIN_IP="152.53.182.222"

# Telegram
[ -f /root/.server_env ] && source /root/.server_env
TG_TOKEN="${TG_TOKEN:-}"
TG_CHAT_ID="${TG_CHAT_ID:-}"

# Node list: "LABEL|IP"
NODES=(
    "ALEX_47|109.234.38.47"
    "4TON_237|144.124.228.237"
    "TATRA_9|144.124.232.9"
    "SHAHIN_227|144.124.228.227"
    "STOLB_24|144.124.239.24"
    "PILIK_178|91.84.118.178"
    "ILYA_176|146.103.110.176"
    "SO_38|144.124.233.38"
)

TOTAL=${#NODES[@]}
COUNT_OK=0
COUNT_SKIP=0
COUNT_ERR=0
ERRORS=""
SUMMARY_LINES=""
TOTAL_SIZE=0
START_ALL=$(date +%s)
DISK_FREE=$(df -BG /BACKUP 2>/dev/null | awk 'NR==2{print $4}' | tr -d 'G' || echo "?")

# =============================================================================
#  HELPERS
# =============================================================================
log()    { echo -e "${CY}$(date +%H:%M:%S)${X}   $1"; }
log_ok() { echo -e "${GN}$(date +%H:%M:%S) \u2714${X} $1"; }
log_sk() { echo -e "${YL}$(date +%H:%M:%S) \u23ed${X} $1"; }
log_er() { echo -e "${RD}$(date +%H:%M:%S) \u2718${X} $1"; }

tg() {
    [ -z "$TG_TOKEN" ] || [ -z "$TG_CHAT_ID" ] && return
    curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d "chat_id=${TG_CHAT_ID}&text=$1&parse_mode=Markdown" >/dev/null 2>&1
}

rotate_local() {
    local dir="$1"
    ls -t "${dir}"/*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f
}

bytes_to_mb() {
    echo "scale=1; $1 / 1048576" | bc 2>/dev/null || echo "?"
}

# =============================================================================
#  HEADER
# =============================================================================
echo -e "$HR"
echo -e "  \U0001f6e1  ${WH}XRAY BACKUP ALL NODES${X}  \u00b7  ${YL}${MAIN_HOST}${X}  \u00b7  ${CY}${MAIN_IP}${X}"
echo -e "  \U0001f4c5 ${CY}$(date '+%Y-%m-%d')${X}  ${WH}$(date '+%H:%M:%S')${X}   \U0001f4bf ${GN}${DISK_FREE}G free${X}"
echo -e "  \U0001f310 ${WH}${TOTAL} VPN nodes${X}   \U0001f504 keep: ${CY}${KEEP}${X}   \U0001f4c2 ${YL}${LOCAL_BACKUP_ROOT}${X}"
echo -e "$HR"

# =============================================================================
#  MAIN LOOP
# =============================================================================
IDX=0
for ENTRY in "${NODES[@]}"; do
    IDX=$((IDX + 1))
    LABEL=$(echo "$ENTRY" | cut -d'|' -f1)
    IP=$(echo "$ENTRY" | cut -d'|' -f2)

    SSH_CMD="ssh -i ${SSH_KEY} -p ${SSH_PORT} -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes ${SSH_USER}@${IP}"
    SCP_CMD="scp -i ${SSH_KEY} -P ${SSH_PORT} -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes"
    LOCAL_DIR="${LOCAL_BACKUP_ROOT}/${LABEL}/xray"
    ARCH_NAME="xray_${LABEL}_${DATE}.tar.gz"
    REMOTE_ARCH="${REMOTE_TMP}/${ARCH_NAME}"
    LOCAL_ARCH="${LOCAL_DIR}/${ARCH_NAME}"

    echo -e "$HR"
    echo -e "  [${IDX}/${TOTAL}] \U0001f310 ${WH}${LABEL}${X}   ${CY}${IP}:${SSH_PORT}${X}"

    # --- SSH check ---
    if ! $SSH_CMD "exit" 2>/dev/null; then
        log_er "${LABEL} (${IP}): SSH connection FAILED — skipping"
        COUNT_ERR=$((COUNT_ERR + 1))
        ERRORS="${ERRORS}\n  \u274c ${LABEL} (${IP}): SSH FAILED"
        SUMMARY_LINES="${SUMMARY_LINES}\n\u274c ${LABEL} — SSH FAILED"
        continue
    fi
    log_ok "SSH connected  ${IP}:${SSH_PORT}"

    # --- Check x-ui ---
    XUI_EXISTS=$($SSH_CMD "[ -d /usr/local/x-ui ] && echo yes || echo no" 2>/dev/null)
    if [ "$XUI_EXISTS" != "yes" ]; then
        log_sk "${LABEL}: x-ui not found — skipping"
        COUNT_SKIP=$((COUNT_SKIP + 1))
        SUMMARY_LINES="${SUMMARY_LINES}\n\u23ed ${LABEL} — x-ui not installed"
        continue
    fi

    XUI_VER=$($SSH_CMD "x-ui version 2>/dev/null | head -1 || echo unknown" 2>/dev/null)
    log_ok "x-ui found  (${XUI_VER})"

    # --- Remote disk check ---
    REMOTE_FREE=$($SSH_CMD "df -m /tmp | awk 'NR==2{print \$4}'" 2>/dev/null || echo 0)
    if [ "${REMOTE_FREE:-0}" -lt 200 ]; then
        log_er "${LABEL}: not enough space on /tmp: ${REMOTE_FREE}MB — skipping"
        COUNT_ERR=$((COUNT_ERR + 1))
        ERRORS="${ERRORS}\n  \u274c ${LABEL}: /tmp only ${REMOTE_FREE}MB free"
        SUMMARY_LINES="${SUMMARY_LINES}\n\u274c ${LABEL} — /tmp too small (${REMOTE_FREE}MB)"
        continue
    fi

    # --- Create archive on remote ---
    log "Creating archive on ${LABEL}..."
    T_START=$(date +%s)

    REMOTE_RESULT=$($SSH_CMD "
        DIRS=''
        [ -d /usr/local/x-ui ]           && DIRS=\"\$DIRS /usr/local/x-ui\"
        [ -d /etc/x-ui ]                 && DIRS=\"\$DIRS /etc/x-ui\"
        [ -d /usr/local/share/xray ]     && DIRS=\"\$DIRS /usr/local/share/xray\"
        [ -d /root/cert ]                && DIRS=\"\$DIRS /root/cert\"
        [ -d /etc/xray ]                 && DIRS=\"\$DIRS /etc/xray\"
        if [ -z \"\$DIRS\" ]; then echo 'NO_DIRS'; exit 1; fi
        tar czf ${REMOTE_ARCH} \$DIRS 2>/dev/null \
            && echo \"OK:\$(du -sh ${REMOTE_ARCH} | cut -f1)\" \
            || echo 'TAR_FAIL'
    " 2>/dev/null)

    T_END=$(date +%s)
    ARCH_ELAPSED=$((T_END - T_START))

    if [[ "$REMOTE_RESULT" == "NO_DIRS" ]] || [[ "$REMOTE_RESULT" == "TAR_FAIL" ]] || [[ -z "$REMOTE_RESULT" ]]; then
        log_er "${LABEL}: archive creation FAILED (${REMOTE_RESULT:-empty})"
        COUNT_ERR=$((COUNT_ERR + 1))
        ERRORS="${ERRORS}\n  \u274c ${LABEL}: tar FAILED"
        SUMMARY_LINES="${SUMMARY_LINES}\n\u274c ${LABEL} — tar FAILED"
        $SSH_CMD "rm -f ${REMOTE_ARCH}" 2>/dev/null
        continue
    fi

    REMOTE_SZ=$(echo "$REMOTE_RESULT" | grep -oP 'OK:\K.*' || echo "?")
    log_ok "Archive ready on remote: ${REMOTE_SZ}  (${ARCH_ELAPSED}s)"

    # --- Download ---
    mkdir -p "$LOCAL_DIR"
    log "Downloading from ${LABEL}..."
    T_START=$(date +%s)
    $SCP_CMD "${SSH_USER}@${IP}:${REMOTE_ARCH}" "${LOCAL_ARCH}" 2>/dev/null
    T_END=$(date +%s)
    DL_ELAPSED=$((T_END - T_START))

    # Cleanup remote
    $SSH_CMD "rm -f ${REMOTE_ARCH}" 2>/dev/null

    # --- Verify ---
    if [ ! -s "$LOCAL_ARCH" ]; then
        log_er "${LABEL}: downloaded archive empty or missing"
        COUNT_ERR=$((COUNT_ERR + 1))
        ERRORS="${ERRORS}\n  \u274c ${LABEL}: empty archive after download"
        SUMMARY_LINES="${SUMMARY_LINES}\n\u274c ${LABEL} — download empty"
        continue
    fi

    LOCAL_SZ=$(du -sh "$LOCAL_ARCH" | cut -f1)
    RAW=$(stat -c%s "$LOCAL_ARCH" 2>/dev/null || echo 0)
    TOTAL_SIZE=$((TOTAL_SIZE + RAW))
    SPEED=""
    [ "$DL_ELAPSED" -gt 0 ] && \
        SPEED=$(echo "scale=1; $RAW / $DL_ELAPSED / 1048576" | bc 2>/dev/null) && \
        SPEED="  ${CY}@ ${LG}${SPEED} MB/s${X}"

    log_ok "${LABEL}: ${ARCH_NAME}"
    echo -e "     ${WH}\u251c\u2500 Size     : ${GN}${LOCAL_SZ}${X}"
    echo -e "     ${WH}\u251c\u2500 Archive  : ${CY}${ARCH_ELAPSED}s${X}  |  Download: ${CY}${DL_ELAPSED}s${SPEED}${X}"
    echo -e "     ${WH}\u2514\u2500 Path     : ${YL}${LOCAL_ARCH}${X}"

    # --- Rotate ---
    rotate_local "$LOCAL_DIR"
    CNT=$(ls "${LOCAL_DIR}"/*.tar.gz 2>/dev/null | wc -l)
    echo -e "     ${PK}\u25a4 Archives : ${WH}${CNT}/${KEEP} kept${X}"
    ls -t "${LOCAL_DIR}"/*.tar.gz 2>/dev/null | head -3 | while IFS= read -r f; do
        F_SZ=$(du -sh "$f" 2>/dev/null | cut -f1)
        F_DATE=$(stat -c%y "$f" 2>/dev/null | cut -d'.' -f1)
        echo -e "       ${CY}\u2514\u2500 ${OR}${F_SZ}${X}  ${WH}${F_DATE}${X}  $(basename "$f")"
    done

    COUNT_OK=$((COUNT_OK + 1))
    SUMMARY_LINES="${SUMMARY_LINES}\n\u2705 ${LABEL} — ${LOCAL_SZ} (${DL_ELAPSED}s)"
done

# =============================================================================
#  FINAL SUMMARY
# =============================================================================
END_ALL=$(date +%s)
TOTAL_ELAPSED=$((END_ALL - START_ALL))
TOTAL_MB=$(bytes_to_mb "$TOTAL_SIZE")

echo -e "$HR"
if [ "$COUNT_ERR" -eq 0 ] && [ "$COUNT_OK" -gt 0 ]; then
    STATUS_LINE="${GN}\u2714  COMPLETED: ${COUNT_OK}/${TOTAL} OK${X}"
elif [ "$COUNT_OK" -gt 0 ]; then
    STATUS_LINE="${YL}\u26a0  COMPLETED: ${COUNT_OK}/${TOTAL} OK  |  ${COUNT_ERR} ERROR(S)${X}"
else
    STATUS_LINE="${RD}\u2718  COMPLETED: 0/${TOTAL} — ALL FAILED OR SKIPPED${X}"
fi

echo -e "  ${STATUS_LINE}"
echo -e "  ${WH}\u251c\u2500 Nodes OK   : ${GN}${COUNT_OK}/${TOTAL}${X}"
echo -e "  ${WH}\u251c\u2500 Skipped    : ${YL}${COUNT_SKIP}${X} (x-ui not installed)"
echo -e "  ${WH}\u251c\u2500 Errors     : ${RD}${COUNT_ERR}${X}"
echo -e "  ${WH}\u251c\u2500 Total size : ${GN}${TOTAL_MB} MB${X}"
echo -e "  ${WH}\u251c\u2500 Total time : ${CY}${TOTAL_ELAPSED}s${X}"
echo -e "  ${WH}\u2514\u2500 Finished   : ${YL}$(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "$HR"
echo -e "              ${YL}= Rooted by VladiMIR | AI =${X}"
echo

if [ -n "$ERRORS" ]; then
    echo -e "${RD}ERRORS:${X}"
    echo -e "$ERRORS"
    echo
fi

# Telegram summary
TG_ICON="\u2705"
[ "$COUNT_ERR" -gt 0 ] && TG_ICON="\u26a0\ufe0f"
[ "$COUNT_OK" -eq 0 ]  && TG_ICON="\u274c"

tg "${TG_ICON} *XRAY BACKUP ALL NODES*%0A%0A\
OK: ${COUNT_OK}/${TOTAL}  |  Skip: ${COUNT_SKIP}  |  Err: ${COUNT_ERR}%0A\
Size: ${TOTAL_MB} MB  |  Time: ${TOTAL_ELAPSED}s%0A\
$(date '+%Y-%m-%d %H:%M')%0A%0A${SUMMARY_LINES}"
