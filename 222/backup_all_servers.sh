#!/usr/bin/env bash
clear
# =============================================================================
#  backup_all_servers.sh  —  Universal weekly config + Docker backup
#                             for ALL 10 servers → stored on 222-DE-NetCup
#  Location: 222/backup_all_servers.sh
#  Run ONLY on server 222-DE-NetCup
# =============================================================================
#  = Rooted by VladiMIR + AI | v2026.05.20 | github.com/GinCz =
# -----------------------------------------------------------------------------
#  Version    : v2026.05.20
#  GitHub     : https://github.com/GinCz/Linux_Server_Public
# =============================================================================
#
#  DESCRIPTION:
#    Backs up every server in the infrastructure:
#      • 222-DE-NetCup  (local, no SSH)
#      • 109-RU-FastVDS (remote via SSH)
#      • 8 VPN nodes    (remote via SSH)
#
#  SCHEDULE (cron on 222-DE-NetCup):
#    0 3 * * 3  bash /root/Linux_Server_Public/222/backup_all_servers.sh >> /var/log/backup_all_servers.log 2>&1
#    0 3 * * 6  bash /root/Linux_Server_Public/222/backup_all_servers.sh >> /var/log/backup_all_servers.log 2>&1
#
#  ALIAS on server 222:
#    alias backup='bash /root/Linux_Server_Public/222/backup_all_servers.sh'
# =============================================================================

# --- Colors ---
CY="\033[1;96m"; GN="\033[1;92m"; LG="\033[38;5;120m"
YL="\033[1;93m"; PK="\033[1;95m"; RD="\033[1;91m"
OR="\033[38;5;214m"; WH="\033[1;97m"; X="\033[0m"
HR="${CY}$(printf '\u2550%.0s' {1..93})${X}"

# =============================================================================
#  CONFIG
# =============================================================================
SSH_KEY="/root/.ssh/id_ed25519"
SSH_PORT=22
SSH_USER="root"
BACKUP_ROOT="/BACKUP"
KEEP=10
DATE=$(date +%Y-%m-%d)
MAIN_HOST="222-DE-NetCup"
MAIN_IP="152.53.182.222"
START_ALL=$(date +%s)

[ -f /root/.server_env ] && source /root/.server_env
TG_TOKEN="${TG_TOKEN:-}"
TG_CHAT_ID="${TG_CHAT_ID:-}"

CONFIG_DIRS="/etc/nginx /etc/php /etc/mysql /etc/my.cnf /etc/my.cnf.d \
/etc/crowdsec /etc/fail2ban /etc/ufw \
/etc/systemd/system /etc/cron.d /etc/cron.daily /etc/cron.weekly /etc/crontab \
/etc/hosts /etc/hostname /etc/fstab /etc/environment /etc/profile.d \
/root/.bashrc /root/.bash_profile /root/.ssh/authorized_keys"

XRAY_DIRS="/usr/local/x-ui /etc/x-ui /usr/local/share/xray /root/cert /etc/xray"

SERVERS=(
    "222-DE-NetCup|${MAIN_IP}|local"
    "109-RU-FastVDS|212.109.223.109|ssh_server"
    "ALEX_47|109.234.38.47|ssh_xui"
    "4TON_237|144.124.228.237|ssh_xui"
    "TATRA_9|144.124.232.9|ssh_xui"
    "SHAHIN_227|144.124.228.227|ssh_amnezia"
    "STOLB_24|144.124.239.24|ssh_xui"
    "PILIK_33|195.63.138.33|ssh_amnezia"
    "ILYA_176|146.103.110.176|ssh_amnezia"
    "SO_38|144.124.233.38|ssh_xui"
    "AWS_12|18.195.117.12|ssh_xui"
    "IONOS_38|82.223.116.38|ssh_xui"
)

TOTAL=${#SERVERS[@]}
COUNT_OK=0
COUNT_ERR=0
TOTAL_SIZE=0
SUMMARY_LINES=""
ERRORS=""

log()    { echo -e "${CY}$(date +%H:%M:%S)${X}   $1"; }
log_ok() { echo -e "${GN}$(date +%H:%M:%S) ✔${X} $1"; }
log_er() { echo -e "${RD}$(date +%H:%M:%S) ✘${X} $1"; }

tg() {
    [ -z "$TG_TOKEN" ] || [ -z "$TG_CHAT_ID" ] && return
    local MSG; MSG=$(printf "%b" "$1")
    curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        --data-urlencode "chat_id=${TG_CHAT_ID}" \
        --data-urlencode "text=${MSG}" \
        --data-urlencode "parse_mode=Markdown" >/dev/null 2>&1
}

rotate_keep() {
    local dir="$1"
    ls -dt "${dir}"/????-??-?? 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -rf
}

add_size() {
    local f="$1"
    [ -f "$f" ] && TOTAL_SIZE=$((TOTAL_SIZE + $(stat -c%s "$f" 2>/dev/null || echo 0)))
}

ssh_run() { ssh -i "${SSH_KEY}" -p "${SSH_PORT}" -o StrictHostKeyChecking=no \
                -o ConnectTimeout=10 -o BatchMode=yes "${SSH_USER}@$1" "$2" 2>/dev/null; }
scp_get() { scp -i "${SSH_KEY}" -P "${SSH_PORT}" -o StrictHostKeyChecking=no \
                -o ConnectTimeout=10 -o BatchMode=yes \
                "${SSH_USER}@$1:$2" "$3" 2>/dev/null; }

backup_configs() {
    local LABEL="$1" IP="$2" IS_LOCAL="$3" OUT_DIR="$4"
    local ARCH="${OUT_DIR}/configs.tar.gz"
    local REMOTE_TMP="/tmp/configs_${LABEL}_${DATE}.tar.gz"
    log "  Backing up configs → ${LABEL}..."
    if [ "$IS_LOCAL" = "1" ]; then
        local DIRS=""
        for D in $CONFIG_DIRS; do [ -e "$D" ] && DIRS="$DIRS $D"; done
        crontab -l > /tmp/crontab_${LABEL}.txt 2>/dev/null
        dpkg --get-selections > /tmp/packages_${LABEL}.txt 2>/dev/null
        DIRS="$DIRS /tmp/crontab_${LABEL}.txt /tmp/packages_${LABEL}.txt"
        tar czf "$ARCH" $DIRS 2>/dev/null
        rm -f /tmp/crontab_${LABEL}.txt /tmp/packages_${LABEL}.txt
    else
        local RESULT
        RESULT=$(ssh_run "$IP" "
            DIRS=''
            for D in $CONFIG_DIRS; do
                [ -e \"\$D\" ] && DIRS=\"\$DIRS \$D\"
            done
            crontab -l > /tmp/crontab_bk.txt 2>/dev/null
            dpkg --get-selections > /tmp/packages_bk.txt 2>/dev/null
            DIRS=\"\$DIRS /tmp/crontab_bk.txt /tmp/packages_bk.txt\"
            tar czf ${REMOTE_TMP} \$DIRS 2>/dev/null \
                && echo \"OK:\$(du -sh ${REMOTE_TMP} | cut -f1)\" \
                || echo 'TAR_FAIL'
            rm -f /tmp/crontab_bk.txt /tmp/packages_bk.txt
        ")
        if [[ "$RESULT" != OK:* ]]; then
            log_er "${LABEL}: configs tar FAILED (${RESULT:-empty})"; return 1
        fi
        scp_get "$IP" "$REMOTE_TMP" "$ARCH"
        ssh_run "$IP" "rm -f ${REMOTE_TMP}" >/dev/null
        if [ ! -s "$ARCH" ]; then
            log_er "${LABEL}: configs download empty"; return 1
        fi
    fi
    local SZ; SZ=$(du -sh "$ARCH" 2>/dev/null | cut -f1)
    log_ok "  configs.tar.gz  ${GN}${SZ}${X}"
    add_size "$ARCH"
    return 0
}

backup_docker() {
    local LABEL="$1" IP="$2" IS_LOCAL="$3" OUT_DIR="$4"
    local DOCKER_DIR="${OUT_DIR}/docker"
    mkdir -p "$DOCKER_DIR"
    log "  Backing up Docker → ${LABEL}..."
    local CONTAINERS
    if [ "$IS_LOCAL" = "1" ]; then
        CONTAINERS=$(docker ps --format "{{.Names}}" 2>/dev/null)
    else
        CONTAINERS=$(ssh_run "$IP" "docker ps --format '{{.Names}}' 2>/dev/null")
    fi
    if [ -z "$CONTAINERS" ]; then
        log "  No running Docker containers on ${LABEL} — skipping"; return 0
    fi
    while IFS= read -r CNAME; do
        [ -z "$CNAME" ] && continue
        local ARCH="${DOCKER_DIR}/${CNAME}.tar.gz"
        local REMOTE_IMG="/tmp/docker_${CNAME}_${DATE}.tar.gz"
        log "    🐳 ${CNAME}..."
        if [ "$IS_LOCAL" = "1" ]; then
            docker commit "$CNAME" "${CNAME}_backup_${DATE}" >/dev/null 2>&1
            docker save "${CNAME}_backup_${DATE}" | gzip > "$ARCH" 2>/dev/null
            docker rmi "${CNAME}_backup_${DATE}" >/dev/null 2>&1
        else
            ssh_run "$IP" "docker commit ${CNAME} ${CNAME}_backup_${DATE} >/dev/null 2>&1
                docker save ${CNAME}_backup_${DATE} | gzip > ${REMOTE_IMG}
                docker rmi ${CNAME}_backup_${DATE} >/dev/null 2>&1
                echo DONE" >/dev/null
            scp_get "$IP" "$REMOTE_IMG" "$ARCH"
            ssh_run "$IP" "rm -f ${REMOTE_IMG}" >/dev/null
        fi
        if [ -s "$ARCH" ]; then
            local SZ; SZ=$(du -sh "$ARCH" 2>/dev/null | cut -f1)
            log_ok "    ${CNAME}.tar.gz  ${GN}${SZ}${X}"
            add_size "$ARCH"
        else
            log_er "    ${CNAME}: Docker archive empty or failed"
        fi
    done <<< "$CONTAINERS"
    return 0
}

backup_xui() {
    local LABEL="$1" IP="$2" OUT_DIR="$3"
    local ARCH="${OUT_DIR}/xray.tar.gz"
    local REMOTE_TMP="/tmp/xray_${LABEL}_${DATE}.tar.gz"
    local XUI_EXISTS
    XUI_EXISTS=$(ssh_run "$IP" "[ -d /usr/local/x-ui ] && echo yes || echo no")
    if [ "$XUI_EXISTS" != "yes" ]; then
        log "  x-ui not found on ${LABEL} — skipping"; return 0
    fi
    log "  Backing up x-ui / Xray → ${LABEL}..."
    local RESULT
    RESULT=$(ssh_run "$IP" "
        DIRS=''
        for D in $XRAY_DIRS; do
            [ -d \"\$D\" ] && DIRS=\"\$DIRS \$D\"
        done
        [ -z \"\$DIRS\" ] && echo 'NO_DIRS' && exit 1
        tar czf ${REMOTE_TMP} \$DIRS 2>/dev/null \
            && echo \"OK:\$(du -sh ${REMOTE_TMP} | cut -f1)\" \
            || echo 'TAR_FAIL'
    ")
    if [[ "$RESULT" != OK:* ]]; then
        log_er "${LABEL}: xray FAILED (${RESULT:-empty})"; return 1
    fi
    scp_get "$IP" "$REMOTE_TMP" "$ARCH"
    ssh_run "$IP" "rm -f ${REMOTE_TMP}" >/dev/null
    if [ ! -s "$ARCH" ]; then
        log_er "${LABEL}: xray download empty"; return 1
    fi
    local SZ; SZ=$(du -sh "$ARCH" 2>/dev/null | cut -f1)
    log_ok "  xray.tar.gz  ${GN}${SZ}${X}"
    add_size "$ARCH"
    return 0
}

# --- HEADER ---
DISK_FREE=$(df -BG /BACKUP 2>/dev/null | awk 'NR==2{print $4}' | tr -d 'G' || echo "?")
echo -e "$HR"
echo -e "  💾  ${WH}BACKUP ALL SERVERS${X}  ·  ${YL}${MAIN_HOST}${X}  ·  ${CY}${MAIN_IP}${X}"
echo -e "  📅 ${CY}$(date '+%Y-%m-%d')${X}  ${WH}$(date '+%H:%M:%S')${X}   💿 ${GN}${DISK_FREE}G free${X}"
echo -e "  🌐 ${WH}${TOTAL} servers${X}   🔄 keep: ${CY}${KEEP}${X}   📂 ${YL}${BACKUP_ROOT}${X}"
echo -e "$HR"

# --- MAIN LOOP ---
IDX=0
for ENTRY in "${SERVERS[@]}"; do
    IDX=$((IDX + 1))
    LABEL=$(echo "$ENTRY" | cut -d'|' -f1)
    IP=$(echo "$ENTRY" | cut -d'|' -f2)
    TYPE=$(echo "$ENTRY" | cut -d'|' -f3)
    OUT_DIR="${BACKUP_ROOT}/${LABEL}/${DATE}"
    mkdir -p "$OUT_DIR"
    echo -e "$HR"
    echo -e "  [${IDX}/${TOTAL}] 🖥  ${WH}${LABEL}${X}   ${CY}${IP}${X}   ${YL}${TYPE}${X}"
    T_START=$(date +%s)
    NODE_OK=1
    if [ "$TYPE" != "local" ]; then
        if ! ssh_run "$IP" "exit" >/dev/null 2>&1; then
            log_er "${LABEL}: SSH FAILED — skipping"
            COUNT_ERR=$((COUNT_ERR + 1))
            ERRORS="${ERRORS}\n❌ ${LABEL} — SSH FAILED"
            SUMMARY_LINES="${SUMMARY_LINES}\n❌ ${LABEL} — SSH FAILED"
            rmdir "$OUT_DIR" 2>/dev/null
            continue
        fi
        log_ok "SSH OK  ${IP}"
    else
        log_ok "Local — no SSH"
    fi
    IS_LOCAL=0; [ "$TYPE" = "local" ] && IS_LOCAL=1
    backup_configs "$LABEL" "$IP" "$IS_LOCAL" "$OUT_DIR" || NODE_OK=0
    if [[ "$TYPE" == "local" || "$TYPE" == "ssh_server" || "$TYPE" == "ssh_amnezia" ]]; then
        backup_docker "$LABEL" "$IP" "$IS_LOCAL" "$OUT_DIR"
    fi
    if [ "$TYPE" = "ssh_xui" ]; then
        backup_xui "$LABEL" "$IP" "$OUT_DIR" || NODE_OK=0
    fi
    T_END=$(date +%s); ELAPSED=$((T_END - T_START))
    FOLDER_SZ=$(du -sh "$OUT_DIR" 2>/dev/null | cut -f1)
    echo -e "     ${WH}├─ Folder : ${YL}${OUT_DIR}${X}"
    find "$OUT_DIR" -type f -name "*.tar.gz" | sort | while read -r F; do
        FSZ=$(du -sh "$F" 2>/dev/null | cut -f1)
        echo -e "     ${WH}│   ${OR}${FSZ}${X}  $(basename "$F")"
    done
    echo -e "     ${WH}└─ Total  : ${GN}${FOLDER_SZ}${X}   ⏱ ${CY}${ELAPSED}s${X}"
    rotate_keep "${BACKUP_ROOT}/${LABEL}"
    KEPT=$(ls -d "${BACKUP_ROOT}/${LABEL}"/????-??-?? 2>/dev/null | wc -l)
    echo -e "     ${PK}▤ History: ${WH}${KEPT}/${KEEP} kept${X}"
    if [ "$NODE_OK" = "1" ]; then
        COUNT_OK=$((COUNT_OK + 1))
        SUMMARY_LINES="${SUMMARY_LINES}\n✅ ${LABEL} — ${FOLDER_SZ} (${ELAPSED}s)"
    else
        COUNT_ERR=$((COUNT_ERR + 1))
        SUMMARY_LINES="${SUMMARY_LINES}\n⚠️ ${LABEL} — partial (${ELAPSED}s)"
    fi
done

# --- FINAL SUMMARY ---
END_ALL=$(date +%s); TOTAL_ELAPSED=$((END_ALL - START_ALL))
TOTAL_MB=$(echo "scale=1; ${TOTAL_SIZE} / 1048576" | bc 2>/dev/null || echo "?")
DISK_USED=$(du -sh "${BACKUP_ROOT}" 2>/dev/null | cut -f1)
echo -e "$HR"
if [ "$COUNT_ERR" -eq 0 ]; then
    STATUS="${GN}✔  COMPLETED: ${COUNT_OK}/${TOTAL} OK${X}"
else
    STATUS="${YL}⚠  COMPLETED: ${COUNT_OK}/${TOTAL} OK  |  ${COUNT_ERR} ERROR(S)${X}"
fi
echo -e "  ${STATUS}"
echo -e "  ${WH}├─ Servers OK : ${GN}${COUNT_OK}/${TOTAL}${X}"
echo -e "  ${WH}├─ Errors     : ${RD}${COUNT_ERR}${X}"
echo -e "  ${WH}├─ Total size : ${GN}${TOTAL_MB} MB${X}   (${YL}${DISK_USED}${X} /BACKUP total)"
echo -e "  ${WH}├─ Total time : ${CY}${TOTAL_ELAPSED}s${X}"
echo -e "  ${WH}└─ Finished   : ${YL}$(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "$HR"
echo
tg "${TG_ICON:-✅} *BACKUP ALL SERVERS*\n\nOK: ${COUNT_OK}/${TOTAL}  |  Err: ${COUNT_ERR}\nSize: ${TOTAL_MB} MB  |  Time: ${TOTAL_ELAPSED}s\n$(date '+%Y-%m-%d %H:%M')\n${SUMMARY_LINES}"
