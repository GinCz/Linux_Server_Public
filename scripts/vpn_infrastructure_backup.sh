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
KEEP=3
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
    "STOLB_24|144.124.239.24"
    "ILYA_221|89.110.69.221"
    "SO_38|144.124.233.38"
    "ORACLE_118|130.61.21.118"
    "ORACLE_157|130.61.101.157"
    "IONOS_38|82.223.116.38"
    "AWS_67|52.57.7.67"
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
#  PREPARE FASTPANEL SITES (1 LATEST BACKUP COPY OF EACH SITE)
# =============================================================================

# =============================================================================
#  BACKUP GIN-CHAT PROJECT (ORACLE-157 -> /BACKUP/gin-chat)
# =============================================================================
backup_gin_chat_project() {
    local label="GIN-Chat (Oracle-157)"
    local ip="130.61.101.157"
    local dest_dir="${LOCAL_BACKUP_ROOT}/gin-chat"
    local dest_root_dir="/root/backups/gin-chat"
    local arch_name="gin_chat_backup_${DATE}.tar.gz"
    local remote_arch="${REMOTE_TMP}/${arch_name}"
    local local_arch="${dest_dir}/${arch_name}"

    echo -e "$HR"
    echo -e "  💬 ${YL}PROJECT: ${label}${X}   ${WH}${ip}:${SSH_PORT}${X}"

    mkdir -p "$dest_dir" "$dest_root_dir"

    local ssh_cmd="ssh -i ${SSH_KEY} -p ${SSH_PORT} -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes ${SSH_USER}@${ip}"
    local scp_cmd="scp -i ${SSH_KEY} -P ${SSH_PORT} -o StrictHostKeyChecking=no -o ConnectTimeout=30 -o BatchMode=yes"

    log "  ${PK}▼${X} Checkpointing SQLite WAL & archiving GIN-Chat on Oracle-157..."
    local create_status
    create_status=$($ssh_cmd "shopt -u expand_aliases; unalias -a 2>/dev/null;
        if [ -f /opt/gin-chat/data/chat.db ]; then
            sqlite3 /opt/gin-chat/data/chat.db 'PRAGMA wal_checkpoint(TRUNCATE);' 2>/dev/null || true
        fi
        tar --exclude='node_modules' --exclude='.git' -czf '${remote_arch}' -C /opt gin-chat 2>/dev/null
        [ -s '${remote_arch}' ] && echo 'STATUS_OK' || echo 'STATUS_TAR_FAILED'
    " 2>/dev/null)

    if [[ "$create_status" != *"STATUS_OK"* ]]; then
        fail "${label}: Failed to create archive on Oracle-157"
        SUMMARY="${SUMMARY}✘ <b>${label}</b> = Archiving failed\n"
        return 1
    fi

    log "  ${CY}↓${X} Downloading GIN-Chat archive to ${dest_dir}/..."
    $scp_cmd "${SSH_USER}@${ip}:${remote_arch}" "${local_arch}" 2>/dev/null
    $ssh_cmd "rm -f ${remote_arch}" 2>/dev/null

    if [ -s "$local_arch" ]; then
        cp -f "$local_arch" "$dest_root_dir/" 2>/dev/null || true
        local sz
        sz=$(du -sh "$local_arch" | cut -f1)
        local bsz
        bsz=$(/usr/bin/stat -c%s "$local_arch" 2>/dev/null || echo 0)
        SESSION_BYTES=$((SESSION_BYTES + bsz))
        log_ok "${YL}${label}${GN}: ${LY}$(basename "${local_arch}")${X} (${GN}${sz}${X})"
        SUMMARY="${SUMMARY}✔ <b>${label}</b> = ${sz}\n"
    else
        fail "${label}: Downloaded GIN-Chat file empty or missing"
        SUMMARY="${SUMMARY}✘ <b>${label}</b> = Download error\n"
        return 1
    fi

    # Rotate keeping last 7 copies
    ls -1t "$dest_dir"/gin_chat_backup_*.tar.gz 2>/dev/null | tail -n +8 | xargs -r rm -f
    ls -1t "$dest_root_dir"/gin_chat_backup_*.tar.gz 2>/dev/null | tail -n +8 | xargs -r rm -f
}

prepare_sites_backup() {
    echo -e "$HR"
    echo -e "  🌐 ${YL}COLLECTING LATEST FASTPANEL SITES BACKUPS (1 COPY EACH)...${X}"
    mkdir -p "${LOCAL_BACKUP_ROOT}/sites"

    python3 - << 'EOF'
import os
import glob
import shutil
import re

backup_sites_root = "/BACKUP/sites"
os.makedirs(backup_sites_root, exist_ok=True)

FP_RE = re.compile(r"^(\d{4}\.\d{2}\.\d{2})_(\d{2}-\d{2}-\d{2})_(.+)_(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$")

# Find all backup folders from FastPanel users
backups = [b for b in glob.glob("/var/www/*/data/backups/*_*_*") if os.path.isdir(b)]
domains = {}

for b in backups:
    name = os.path.basename(b)
    m = FP_RE.match(name)
    if m:
        dt = f"{m.group(1)}_{m.group(2)}"
        domain = m.group(3)
        if domain not in domains or dt > domains[domain][0]:
            domains[domain] = (dt, b)

current_domains = set(domains.keys())
existing_dirs = set(os.listdir(backup_sites_root))

# Remove dirs that no longer exist or old timestamped dirs
for d in existing_dirs:
    if d not in current_domains:
        shutil.rmtree(os.path.join(backup_sites_root, d), ignore_errors=True)

# Link newest backup files
for domain, (dt, path) in domains.items():
    dest_dir = os.path.join(backup_sites_root, domain)
    os.makedirs(dest_dir, exist_ok=True)
    source_files = {f: os.path.join(path, f) for f in os.listdir(path) if os.path.isfile(os.path.join(path, f))}
    for existing_file in os.listdir(dest_dir):
        if existing_file not in source_files:
            try:
                os.remove(os.path.join(dest_dir, existing_file))
            except:
                pass
    for f, src in source_files.items():
        dst = os.path.join(dest_dir, f)
        if not os.path.exists(dst):
            try:
                os.link(src, dst)
            except:
                shutil.copy2(src, dst)
EOF

    local count
    count=$(find "${LOCAL_BACKUP_ROOT}/sites" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    local sz
    sz=$(du -sh "${LOCAL_BACKUP_ROOT}/sites" 2>/dev/null | cut -f1)
    log_ok "FastPanel sites ready: ${WH}${count} sites${GN} (latest copy: ${WH}${sz}${GN})"
}

# =============================================================================
#  PULL SITES BACKUP FROM RU-109 (1 LATEST COPY EACH)
# =============================================================================
backup_ru_109_sites() {
    local label="RU-109 Sites Replica"
    local ip="212.109.223.109"
    local dest_dir="${LOCAL_BACKUP_ROOT}/sites_109"
    mkdir -p "$dest_dir"

    echo -e "$HR"
    echo -e "  🌐 ${YL}COLLECTING LATEST SITES BACKUPS FROM RU-109...${X}"

    local ssh_cmd="ssh -i ${SSH_KEY} -p ${SSH_PORT} -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes ${SSH_USER}@${ip}"

    $ssh_cmd "python3 - << 'EOF'
import os, glob, shutil, re
backup_sites_root = '/BACKUP/sites_109'
os.makedirs(backup_sites_root, exist_ok=True)
FP_RE = re.compile(r'^(\d{4}\.\d{2}\.\d{2})_(\d{2}-\d{2}-\d{2})_(.+)_(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$')
backups = [b for b in glob.glob('/var/www/*/data/backups/*_*_*') if os.path.isdir(b)]
domains = {}
for b in backups:
    m = FP_RE.match(os.path.basename(b))
    if m:
        dt = f'{m.group(1)}_{m.group(2)}'
        domain = m.group(3)
        if domain not in domains or dt > domains[domain][0]:
            domains[domain] = (dt, b)
for d in os.listdir(backup_sites_root):
    if d not in domains:
        shutil.rmtree(os.path.join(backup_sites_root, d), ignore_errors=True)
for domain, (dt, path) in domains.items():
    dest = os.path.join(backup_sites_root, domain)
    os.makedirs(dest, exist_ok=True)
    src_files = {f: os.path.join(path, f) for f in os.listdir(path) if os.path.isfile(os.path.join(path, f))}
    for existing in os.listdir(dest):
        if existing not in src_files:
            try: os.remove(os.path.join(dest, existing))
            except: pass
    for f, src in src_files.items():
        dst = os.path.join(dest, f)
        if not os.path.exists(dst):
            try: os.link(src, dst)
            except: shutil.copy2(src, dst)
EOF" 2>/dev/null

    if rsync -avz --delete -e "ssh -i ${SSH_KEY} -p ${SSH_PORT} -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=10" "${SSH_USER}@${ip}:/BACKUP/sites_109/" "${dest_dir}/" >/dev/null 2>&1; then
        local count
        count=$(find "${dest_dir}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
        local sz
        sz=$(du -sh "${dest_dir}" 2>/dev/null | cut -f1)
        log_ok "RU-109 Sites Replica ready: ${WH}${count} sites${GN} (${WH}${sz}${GN})"
        SUMMARY="${SUMMARY}✔ <b>RU-109 Sites (1 copy each)</b> = ${sz}\n"
    else
        log "⚠️ Pulling RU-109 sites replica failed or skipped"
        SUMMARY="${SUMMARY}⚠️ <b>RU-109 Sites</b> = Sync error\n"
    fi
}

# =============================================================================
#  SYNC TO REPLICA (RU-109)
# =============================================================================
sync_to_replica() {
    echo -e "$HR"
    echo -e "  🔄 ${YL}REPLICATING ALL BACKUPS TO RU-109 (${REPLICA_IP})...${X}"

    if rsync -avz --delete --exclude="aws/" --exclude="sync_staging/" --exclude="sites_109/" -e "ssh -i ${SSH_KEY} -p ${SSH_PORT} -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=10" "${LOCAL_BACKUP_ROOT}/" "${SSH_USER}@${REPLICA_IP}:${REPLICA_DEST}" >/dev/null 2>&1; then
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

# 2. Backup RU-109 System
IDX=$((IDX+1))
backup_ru_109 "$IDX"

# 2.5. Pull RU-109 Sites (1 latest copy each)
backup_ru_109_sites

# 3. Backup Local DE-222 System
IDX=$((IDX+1))
backup_local_222 "$IDX"

# 3.5. Backup GIN-Chat Project (Oracle-157 -> /BACKUP/gin-chat)
backup_gin_chat_project

# 4. Prepare FastPanel Sites for DE-222 (1 latest copy each)
prepare_sites_backup

# 5. Sync /BACKUP to RU-109 (mirroring DE-222 sites to 109)
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
