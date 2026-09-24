#!/bin/bash
unalias -a 2>/dev/null
# =============================================================================
#  vpn_infrastructure_backup.sh - Master Compact Backup for VPN Nodes, RU-109 & DE-222
# =============================================================================
#  = Rooted by VladiMIR + AI | v.2026.09.22 | github.com/GinCz =
# -----------------------------------------------------------------------------
#  Version    : v2026-09-22.1
#  Author     : Ing. VladiMIR Bulantsev
#  GitHub     : https://github.com/GinCz/Secret_Privat
#  License    : MIT
# =============================================================================

# --- Colors ---
CY="\033[1;96m"; GN="\033[1;92m"; LG="\033[38;5;120m"
YL="\033[1;93m"; LY="\033[38;5;228m"; PK="\033[1;95m"
RD="\033[1;91m"; OR="\033[38;5;214m"; WH="\033[1;97m"; X="\033[0m"
HR="${CY}$(printf '═%.0s' {1..95})${X}"

# =============================================================================
#  CONFIG
# =============================================================================
SSH_KEY="/root/.ssh/id_ed25519"
SSH_PORT=22
SSH_USER="root"
LOCAL_BACKUP_ROOT="/BACKUP"
KEEP=60
REMOTE_TMP="/tmp"
TELEGRAM_TOKEN="1226649515:AAF_jIP6ol767vCh9Ur__rEI5onTmIz2z2g"
TELEGRAM_CHAT_ID="261784949"

# Remote replica server (RU-109)
REPLICA_IP="212.109.223.109"
REPLICA_DEST="/BACKUP/"

# =============================================================================
#  SERVERS LIST (11 Active Remote VPN Nodes)
#  Note: AWS_Axians_Win10_82 (3.67.43.82) is Windows 10 LTSC (No VPN).
#  It is intentionally excluded from VPN backup to prevent connection errors.
# =============================================================================
declare -a VPN_NODES=(
    "ALEX_39|89.110.121.39"
    "4TON_237|144.124.228.237"
    "TATRA_9|144.124.232.9"
    "SHAHIN_227|144.124.228.227"
    "STOLB_24|144.124.239.24"
    "PILIK_33|195.63.138.33"
    "ILYA_221|89.110.69.221"
    "SO_38|144.124.233.38"
    "ORACLE_118|130.61.21.118"
    "ORACLE_157|130.61.101.157"
    "IONOS_38|82.223.116.38"
)

# =============================================================================
#  INTERNAL VARIABLES
# =============================================================================
DATE=$(date +%Y-%m-%d_%H-%M)
START_TIME=$(date +%s)
ERRORS=0
SUCCESS=0
TOTAL=$((${#VPN_NODES[@]} + 2)) # 11 Remote + RU-109 + DE-222 = 13
SUMMARY=""
SESSION_BYTES=0

# =============================================================================
#  HELPERS
# =============================================================================
log()    { echo -e "${CY}$(date +%H:%M:%S)${X} $1"; }
log_ok() { echo -e "${GN}$(date +%H:%M:%S) ✔ $1${X}"; }
fail()   { echo -e "${RD}$(date +%H:%M:%S) ✘ $1${X}"; ERRORS=$((ERRORS+1)); }

tg() {
    [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ] && return
    local msg="$1"
    local response
    response=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        --data-urlencode "text=${msg}" \
        -d "parse_mode=HTML" 2>&1)
    if echo "$response" | grep -q '"ok":true'; then
        log_ok "Telegram notification sent successfully"
    else
        response=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
            -d "chat_id=${TELEGRAM_CHAT_ID}" \
            --data-urlencode "text=${msg}" 2>&1)
        if echo "$response" | grep -q '"ok":true'; then
            log_ok "Telegram notification sent (plain text fallback)"
        else
            log "⚠️ Telegram notification failed: $response"
        fi
    fi
}

rotate_local() {
    local target_dir="$1"
    local count
    count=$(ls -1t "$target_dir"/*.tar.gz 2>/dev/null | wc -l)
    if [ "$count" -gt "$KEEP" ]; then
        ls -1t "$target_dir"/*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f
    fi
}

# =============================================================================
#  BACKUP REMOTE VPN NODE (COMPACT CONFIG & DATABASE)
# =============================================================================
backup_vpn_node() {
    local idx="$1" label="$2" ip="$3"
    local dest_dir="${LOCAL_BACKUP_ROOT}/vpn/${label}"
    local arch_name="${label}_xray_${DATE}.tar.gz"
    local remote_arch="${REMOTE_TMP}/${arch_name}"
    local local_arch="${dest_dir}/${arch_name}"

    echo -e "$HR"
    echo -e "  ${CY}[${idx}/${TOTAL}]${X} 🌐 ${YL}${label}${X}   ${WH}${ip}:${SSH_PORT}${X}"

    mkdir -p "$dest_dir"

    local ssh_cmd="ssh -i ${SSH_KEY} -p ${SSH_PORT} -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes ${SSH_USER}@${ip}"
    local scp_cmd="scp -i ${SSH_KEY} -P ${SSH_PORT} -o StrictHostKeyChecking=no -o ConnectTimeout=15 -o BatchMode=yes"

    if ! $ssh_cmd "exit 0" 2>/dev/null; then
        fail "${label} (${ip}): SSH connection FAILED — skipping"
        SUMMARY="${SUMMARY}✘ <b>${label}</b> (${ip}) = SSH unreachable\n"
        return 1
    fi
    log "  ${GN}✓${X} SSH connected ${WH}${ip}${X}"

    log "  ${PK}▼${X} Collecting Xray DB, keys, SSL certs on ${label}..."
    local create_status
    create_status=$($ssh_cmd "shopt -u expand_aliases; unalias -a 2>/dev/null;
        TARGETS=(
            /etc/x-ui
            /usr/local/x-ui/bin/config.json
            /usr/local/x-ui/x-ui.db
            /etc/xray
            /root/cert
            /.acme.sh
            /root/.acme.sh
            /etc/letsencrypt
            /etc/samba/smb.conf
            /etc/systemd/system/x-ui.service
            /etc/systemd/system/3x-ui.service
            /etc/systemd/system/xray.service
            /opt/AdGuardHome/AdGuardHome.yaml
            /root/.ssh
            /etc/iptables
            /etc/wireguard
            /etc/amnezia
            /etc/network
            /etc/netplan
        )
        EXISTING=()
        for t in \"\${TARGETS[@]}\"; do
            [ -e \"\$t\" ] && EXISTING+=(\"\$t\")
        done
        if [ \${#EXISTING[@]} -eq 0 ]; then
            [ -d /root/.ssh ] && EXISTING+=(/root/.ssh)
        fi
        tar -czf '${remote_arch}' \"\${EXISTING[@]}\" /root/*.sh 2>/dev/null
        [ -s '${remote_arch}' ] && echo 'STATUS_OK' || echo 'STATUS_TAR_FAILED'
    " 2>/dev/null)

    if [[ "$create_status" != *"STATUS_OK"* ]]; then
        fail "${label}: Failed to create archive on remote host"
        SUMMARY="${SUMMARY}✘ <b>${label}</b> (${ip}) = Archiving failed\n"
        return 1
    fi

    log "  ${CY}↓${X} Downloading archive to ${LOCAL_BACKUP_ROOT}/vpn/${label}/..."
    $scp_cmd "${SSH_USER}@${ip}:${remote_arch}" "${local_arch}" 2>/dev/null
    $ssh_cmd "rm -f ${remote_arch}" 2>/dev/null

    if [ -s "$local_arch" ]; then
        local sz
        sz=$(du -sh "$local_arch" | cut -f1)
        local bsz
        bsz=$(/usr/bin/stat -c%s "$local_arch" 2>/dev/null || echo 0)
        SESSION_BYTES=$((SESSION_BYTES + bsz))
        log_ok "${YL}${label}${GN}: ${LY}$(basename "${local_arch}")${X} (${GN}${sz}${X})"
        SUMMARY="${SUMMARY}✔ <b>${label}</b> (${ip}) = ${sz}\n"
        SUCCESS=$((SUCCESS+1))
    else
        fail "${label}: Downloaded file empty or missing"
        SUMMARY="${SUMMARY}✘ <b>${label}</b> (${ip}) = Download error\n"
        return 1
    fi

    rotate_local "$dest_dir"
    local cnt
    cnt=$(ls -1 "$dest_dir"/*.tar.gz 2>/dev/null | wc -l)
    echo -e "     ${PK}▤ Local archives kept:${X} ${WH}${cnt}/${KEEP}${X}"
}

# =============================================================================
#  BACKUP RU-109 (FastVDS - Compact Configs & DBs)
# =============================================================================
backup_ru_109() {
    local idx="$1"
    local label="109-RU-FastVDS"
    local ip="212.109.223.109"
    local dest_dir="${LOCAL_BACKUP_ROOT}/109"
    local arch_name="RU_109_full_${DATE}.tar.gz"
    local remote_arch="${REMOTE_TMP}/${arch_name}"
    local local_arch="${dest_dir}/${arch_name}"

    echo -e "$HR"
    echo -e "  ${CY}[${idx}/${TOTAL}]${X} 🌐 ${YL}${label}${X}   ${WH}${ip}:${SSH_PORT}${X}"

    mkdir -p "$dest_dir"

    local ssh_cmd="ssh -i ${SSH_KEY} -p ${SSH_PORT} -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes ${SSH_USER}@${ip}"
    local scp_cmd="scp -i ${SSH_KEY} -P ${SSH_PORT} -o StrictHostKeyChecking=no -o ConnectTimeout=15 -o BatchMode=yes"

    if ! $ssh_cmd "exit 0" 2>/dev/null; then
        fail "${label} (${ip}): SSH connection FAILED — skipping"
        SUMMARY="${SUMMARY}✘ <b>RU-109</b> (${ip}) = SSH unreachable\n"
        return 1
    fi
    log "  ${GN}✓${X} SSH connected ${WH}${ip}${X}"

    log "  ${PK}▼${X} Collecting X-UI, FastPanel DB, Nginx, Samba and scripts on RU-109..."
    local create_status
    create_status=$($ssh_cmd "shopt -u expand_aliases; unalias -a 2>/dev/null;
        TARGETS=(
            /etc/x-ui
            /usr/local/fastpanel2/app/db
            /usr/local/fastpanel2/app/certs
            /usr/local/fastpanel2/app/templates
            /etc/fastpanel
            /etc/nginx
            /etc/apache2
            /etc/samba
            /root/cert
            /root/.ssh
            /opt/rustdesk-server
            /var/www/remote-support
        )
        EXISTING=()
        for t in \"\${TARGETS[@]}\"; do
            [ -e \"\$t\" ] && EXISTING+=(\"\$t\")
        done
        tar -czf '${remote_arch}' \"\${EXISTING[@]}\" /root/*.sh 2>/dev/null
        [ -s '${remote_arch}' ] && echo 'STATUS_OK' || echo 'STATUS_TAR_FAILED'
    " 2>/dev/null)

    if [[ "$create_status" != *"STATUS_OK"* ]]; then
        fail "${label}: Failed to archive RU-109"
        SUMMARY="${SUMMARY}✘ <b>RU-109</b> (${ip}) = Archiving error\n"
        return 1
    fi

    log "  ${CY}↓${X} Downloading RU-109 archive..."
    $scp_cmd "${SSH_USER}@${ip}:${remote_arch}" "${local_arch}" 2>/dev/null
    $ssh_cmd "rm -f ${remote_arch}" 2>/dev/null

    if [ -s "$local_arch" ]; then
        local sz
        sz=$(du -sh "$local_arch" | cut -f1)
        local bsz
        bsz=$(/usr/bin/stat -c%s "$local_arch" 2>/dev/null || echo 0)
        SESSION_BYTES=$((SESSION_BYTES + bsz))
        log_ok "${YL}${label}${GN}: ${LY}$(basename "${local_arch}")${X} (${GN}${sz}${X})"
        SUMMARY="${SUMMARY}✔ <b>RU-109</b> (${ip}) = ${sz}\n"
        SUCCESS=$((SUCCESS+1))
    else
        fail "${label}: Downloaded file empty or missing"
        SUMMARY="${SUMMARY}✘ <b>RU-109</b> (${ip}) = Download error\n"
        return 1
    fi

    rotate_local "$dest_dir"
    local cnt
    cnt=$(ls -1 "$dest_dir"/*.tar.gz 2>/dev/null | wc -l)
    echo -e "     ${PK}▤ Local archives kept:${X} ${WH}${cnt}/${KEEP}${X}"
}

# =============================================================================
#  BACKUP LOCAL DE-222 (NetCup Master - Compact Configs & DBs)
# =============================================================================
backup_local_222() {
    local idx="$1"
    local label="222-DE-NetCup"
    local dest_dir="${LOCAL_BACKUP_ROOT}/222"
    local arch_name="222_master_${DATE}.tar.gz"
    local local_arch="${dest_dir}/${arch_name}"

    echo -e "$HR"
    echo -e "  ${CY}[${idx}/${TOTAL}]${X} 🏠 ${YL}${label}${X}   ${WH}Local Master Host${X}"

    mkdir -p "$dest_dir"

    log "  ${PK}▼${X} Archiving local configs on DE-222..."
    TARGETS=(
        /etc/x-ui
        /usr/local/fastpanel2/app/db
        /usr/local/fastpanel2/app/certs
        /usr/local/fastpanel2/app/templates
        /etc/fastpanel
        /etc/nginx
        /etc/apache2
        /etc/samba
        /root/cert
        /.acme.sh
        /root/.ssh
        /root/scripts
    )
    EXISTING=()
    for t in "${TARGETS[@]}"; do
        [ -e "$t" ] && EXISTING+=("$t")
    done

    tar -czf "${local_arch}" "${EXISTING[@]}" /root/*.sh 2>/dev/null

    if [ -s "$local_arch" ]; then
        local sz
        sz=$(du -sh "$local_arch" | cut -f1)
        local bsz
        bsz=$(/usr/bin/stat -c%s "$local_arch" 2>/dev/null || echo 0)
        SESSION_BYTES=$((SESSION_BYTES + bsz))
        log_ok "${YL}${label}${GN}: ${LY}$(basename "${local_arch}")${X} (${GN}${sz}${X})"
        SUMMARY="${SUMMARY}✔ <b>DE-222</b> (Local Master) = ${sz}\n"
        SUCCESS=$((SUCCESS+1))
    else
        fail "${label}: Failed to create local archive"
        SUMMARY="${SUMMARY}✘ <b>DE-222</b> (Local Master) = Archiving error\n"
        return 1
    fi

    rotate_local "$dest_dir"
    local cnt
    cnt=$(ls -1 "$dest_dir"/*.tar.gz 2>/dev/null | wc -l)
    echo -e "     ${PK}▤ Local archives kept:${X} ${WH}${cnt}/${KEEP}${X}"
}

# =============================================================================
#  SYNC TO REPLICA (RU-109)
# =============================================================================
sync_to_replica() {
    echo -e "$HR"
    echo -e "  🔄 ${YL}REPLICATING ALL BACKUPS TO RU-109 (${REPLICA_IP})...${X}"

    if rsync -avz --delete -e "ssh -i ${SSH_KEY} -p ${SSH_PORT} -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=10" "${LOCAL_BACKUP_ROOT}/" "${SSH_USER}@${REPLICA_IP}:${REPLICA_DEST}" >/dev/null 2>&1; then
        log_ok "Full replica synchronized to RU-109 (${REPLICA_IP}:${REPLICA_DEST})"
        SUMMARY="${SUMMARY}\n🔄 <b>Copy to RU-109:</b> OK ✔\n"
    else
        log "⚠️ Replicating to RU-109 skipped or offline (${REPLICA_IP})"
        SUMMARY="${SUMMARY}\n⚠️ <b>Copy to RU-109:</b> OFFLINE / SKIPPED ✘\n"
    fi
}

# =============================================================================
#  MAIN EXECUTION
# =============================================================================
DISK_FREE=$(df -h "${LOCAL_BACKUP_ROOT}" 2>/dev/null | awk 'NR==2{print $4}' || df -h / | awk 'NR==2{print $4}')
LOAD=$(uptime | awk -F'load average:' '{print $2}' | xargs)
SERVER_IP=$(hostname -I | awk '{print $1}')

echo -e "$HR"
echo -e "  🛡  ${WH}MASTER INFRASTRUCTURE & VPN BACKUP (COMPACT)${X}  ·  ${YL}DE-222${X}  ·  ${CY}${SERVER_IP}${X}"
echo -e "  📅 ${CY}$(date '+%Y-%m-%d')${X}  ${WH}$(date '+%H:%M:%S')${X}   💿 ${GN}${DISK_FREE} free${X}   📊 ${WH}load: ${LY}${LOAD}${X}"
echo -e "  🌐 ${WH}${TOTAL} targets (${#VPN_NODES[@]} Remote + RU-109 + DE-222)${X}   🔄 ${WH}keep: ${CY}${KEEP} copies${X}"
echo -e "$HR"

# 1. Backup all Remote VPN/Cloud Nodes
IDX=0
for entry in "${VPN_NODES[@]}"; do
    IDX=$((IDX+1))
    IFS='|' read -r label ip <<< "$entry"
    backup_vpn_node "$IDX" "$label" "$ip"
done

# 2. Backup RU-109
IDX=$((IDX+1))
backup_ru_109 "$IDX"

# 3. Backup Local DE-222
IDX=$((IDX+1))
backup_local_222 "$IDX"

# 4. Sync /BACKUP to RU-109
sync_to_replica

# =============================================================================
#  SUMMARY & TELEGRAM
# =============================================================================
END_TIME=$(date +%s)
TOTAL_ELAPSED=$((END_TIME - START_TIME))
TOTAL_STORAGE_SZ=$(du -sh "${LOCAL_BACKUP_ROOT}" 2>/dev/null | cut -f1)
SESSION_MB=$(awk "BEGIN {printf \"%.1f MB\", ${SESSION_BYTES}/1048576}")
DISK_FREE_NOW=$(df -h "${LOCAL_BACKUP_ROOT}" 2>/dev/null | awk 'NR==2{print $4}')
DATE_STR=$(date '+%Y-%m-%d')
TIME_STR=$(date '+%H:%M:%S')

echo -e "$HR"
if [ "$ERRORS" -eq 0 ]; then
    echo -e "  ${GN}✔  ALL BACKUPS COMPLETED SUCCESSFULLY — NO ERRORS${X}"
    MSG="🛡️ <b>MASTER BACKUP SUCCESS</b> | <b>DE-222</b>

$(echo -e "$SUMMARY")

📊 <b>Status:</b> ${SUCCESS}/${TOTAL} OK (All active nodes backed up)
📦 <b>Current Backup:</b> ${SESSION_MB}  |  ⏱ <b>Duration:</b> ${TOTAL_ELAPSED}s
💾 <b>Storage /BACKUP:</b> ${TOTAL_STORAGE_SZ} (Free: ${DISK_FREE_NOW})
🔄 <b>Kept:</b> Last ${KEEP} copies
📅 <b>Date:</b> ${DATE_STR} ${TIME_STR}"
else
    echo -e "  ${RD}⚠  BACKUP COMPLETED WITH ISSUES: ${SUCCESS}/${TOTAL} OK | ${ERRORS} OFFLINE/ERRORS${X}"
    MSG="🚨 <b>MASTER BACKUP: NODES STATUS REPORT</b> | <b>DE-222</b>

$(echo -e "$SUMMARY")

⚠️ <b>Success:</b> ${SUCCESS}/${TOTAL}  |  <b>Errors/Offline:</b> ${ERRORS}
📦 <b>Current Backup:</b> ${SESSION_MB}  |  ⏱ <b>Duration:</b> ${TOTAL_ELAPSED}s
💾 <b>Storage /BACKUP:</b> ${TOTAL_STORAGE_SZ} (Free: ${DISK_FREE_NOW})
🔄 <b>Kept:</b> Last ${KEEP} copies
📅 <b>Date:</b> ${DATE_STR} ${TIME_STR}"
fi

echo -e "  ${WH}├─ Backups OK    : ${GN}${SUCCESS}/${TOTAL}${X}"
echo -e "  ${WH}├─ Current backup: ${GN}${SESSION_MB}${X}"
echo -e "  ${WH}├─ Total storage : ${GN}${TOTAL_STORAGE_SZ:-?} (Free: ${DISK_FREE_NOW})${X}"
echo -e "  ${WH}├─ Time taken    : ${CY}${TOTAL_ELAPSED}s${X}"
echo -e "  ${WH}├─ Errors        : $([ $ERRORS -eq 0 ] && echo "${GN}0${X}" || echo "${RD}${ERRORS}${X}")${X}"
echo -e "  ${WH}└─ Finished at   : ${YL}${DATE_STR} ${TIME_STR}${X}"
echo -e "$HR"
echo -e "              ${YL}= Rooted by VladiMIR + AI =${X}"
echo

tg "$MSG"
