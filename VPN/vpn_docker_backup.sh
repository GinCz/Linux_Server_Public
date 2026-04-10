#!/bin/bash
clear
# =============================================================================
#  vpn_docker_backup.sh  -  AmneziaWG backup from 8 VPN servers via SSH
# =============================================================================
#  = Rooted by VladiMIR | AI =
# -----------------------------------------------------------------------------
#  Version    : v2026-04-10
#  Author     : Ing. VladiMIR Bulantsev
#  GitHub     : https://github.com/GinCz/Linux_Server_Public
#  License    : MIT
# =============================================================================
#
#  HOW IT WORKS:
#    - Connects to each VPN server via SSH
#    - Runs docker commit on amnezia-awg container
#    - Pulls the archive back to LOCAL /BACKUP/vpn/<server>/
#    - Rotates old archives (keep last N)
#
#  SETUP:
#    - SSH key auth must be configured for each server (no password prompt)
#    - SSH key: /root/.ssh/id_ed25519
#    - Alias on server 222: f5vpn='bash /root/vpn_docker_backup.sh'
#
#  RESULT (2026-04-10):
#    8/8 servers OK — 227M total — 53s
#    Each archive ~13MB @ 47-71 MB/s
#
#  VPN NODE LIST (IPs masked — last octet shown only):
#    ALEX_47    xxx.xxx.xx.47    AmneziaWG + Samba
#    4TON_237   xxx.xxx.xxx.237  AmneziaWG + Samba + Prometheus
#    TATRA_9    xxx.xxx.xxx.9    AmneziaWG + Samba + Kuma Monitoring
#    SHAHIN_227 xxx.xxx.xxx.227  AmneziaWG + Samba
#    STOLB_24   xxx.xxx.xxx.24   AmneziaWG + Samba + AdGuard Home
#    PILIK_178  xx.xx.xxx.178    AmneziaWG + Samba
#    ILYA_176   xxx.xxx.xxx.176  AmneziaWG + Samba
#    SO_38      xxx.xxx.xxx.38   AmneziaWG + Samba
# =============================================================================

# --- Colors ---
CY="\033[1;96m"; GN="\033[1;92m"; LG="\033[38;5;120m"
YL="\033[1;93m"; LY="\033[38;5;228m"; PK="\033[1;95m"
RD="\033[1;91m"; OR="\033[38;5;214m"; WH="\033[1;97m"; X="\033[0m"
HR="${CY}$(printf '\u2550%.0s' {1..95})${X}"

# =============================================================================
#  CONFIG
# =============================================================================
SSH_KEY="/root/.ssh/id_ed25519"
SSH_PORT=22
SSH_USER="root"
LOCAL_BACKUP_ROOT="/BACKUP/vpn"
KEEP=3
CONTAINER="amnezia-awg"
REMOTE_TMP="/tmp"
TELEGRAM_TOKEN=""
TELEGRAM_CHAT_ID=""

# =============================================================================
#  VPN SERVERS  (8 nodes)
#  !!! Replace xxx with real IPs before running !!!
# =============================================================================
declare -a SERVERS=(
    "ALEX_47|xxx.xxx.xx.47|0"
    "4TON_237|xxx.xxx.xxx.237|0"
    "TATRA_9|xxx.xxx.xxx.9|0"
    "SHAHIN_227|xxx.xxx.xxx.227|0"
    "STOLB_24|xxx.xxx.xxx.24|0"
    "PILIK_178|xx.xx.xxx.178|0"
    "ILYA_176|xxx.xxx.xxx.176|0"
    "SO_38|xxx.xxx.xxx.38|0"
)

# =============================================================================
#  INTERNAL VARIABLES
# =============================================================================
DATE=$(date +%Y-%m-%d_%H-%M)
START_TIME=$(date +%s)
ERRORS=0
SUCCESS=0
TOTAL=${#SERVERS[@]}
SUMMARY=""

# =============================================================================
#  HELPERS
# =============================================================================
log()    { echo -e "${CY}$(date +%H:%M:%S)${X} $1"; }
log_ok() { echo -e "${GN}$(date +%H:%M:%S) \u2714 $1${X}"; }
fail()   { echo -e "${RD}$(date +%H:%M:%S) \u2718 $1${X}"; ERRORS=$((ERRORS+1)); }

tg() {
    [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ] && return
    curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}&text=$1&parse_mode=Markdown" >/dev/null
}

rotate_local() {
    ls -t "$1"/*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f
}

# =============================================================================
#  BACKUP ONE SERVER
# =============================================================================
backup_server() {
    local idx="$1" label="$2" ip="$3" port_override="$4"
    local port="$SSH_PORT"
    [ "$port_override" != "0" ] && port="$port_override"

    local ssh_cmd="ssh -i ${SSH_KEY} -p ${port} -o StrictHostKeyChecking=no -o ConnectTimeout=15 -o BatchMode=yes"
    local scp_cmd="scp -i ${SSH_KEY} -P ${port} -o StrictHostKeyChecking=no -o ConnectTimeout=15 -o BatchMode=yes"
    local dest_dir="${LOCAL_BACKUP_ROOT}/${label}"
    local arch_name="${CONTAINER}_${DATE}.tar.gz"
    local remote_arch="${REMOTE_TMP}/${arch_name}"
    local local_arch="${dest_dir}/${arch_name}"

    echo -e "$HR"
    echo -e "  ${CY}[${idx}/${TOTAL}]${X} \U0001f310 ${YL}${label}${X}   ${WH}${ip}:${port}${X}"

    mkdir -p "$dest_dir"

    # --- SSH check ---
    if ! $ssh_cmd ${SSH_USER}@${ip} "exit" 2>/dev/null; then
        fail "${label} (${ip}): SSH connection FAILED \u2014 skipping"
        SUMMARY="${SUMMARY}[FAIL] ${label} (${ip}): SSH error%0A"
        return 1
    fi
    log "  ${GN}\u2713${X} SSH connected  ${WH}${ip}:${port}${X}"

    # --- Container check ---
    local running
    running=$($ssh_cmd ${SSH_USER}@${ip} "docker inspect -f '{{.State.Running}}' ${CONTAINER} 2>/dev/null")
    if [ "$running" != "true" ]; then
        fail "${label}: container '${CONTAINER}' not running \u2014 skipping"
        SUMMARY="${SUMMARY}[FAIL] ${label}: container not running%0A"
        return 1
    fi
    log "  ${GN}\u25cf${X} container ${YL}${CONTAINER}${X} running \u2714"

    # --- Cleanup inside container ---
    log "  ${PK}\u25bc${X} ${YL}${CONTAINER}${X} cleanup inside..."
    $ssh_cmd ${SSH_USER}@${ip} "
        docker exec ${CONTAINER} sh -c \
            'find /tmp -type f -delete 2>/dev/null; \
             find /var/log -type f \( -name \"*.log\" -o -name \"*.gz\" \) -delete 2>/dev/null' \
        2>/dev/null; exit 0
    " 2>/dev/null

    # --- Docker commit ---
    log "  ${CY}\u25cf${X} ${YL}${CONTAINER}${X} docker commit..."
    local commit_id
    commit_id=$($ssh_cmd ${SSH_USER}@${ip} \
        "docker commit ${CONTAINER} ${CONTAINER}-bak:${DATE} 2>/dev/null | cut -d: -f2 | cut -c1-12")

    if [ -z "$commit_id" ]; then
        fail "${label}: docker commit FAILED"
        SUMMARY="${SUMMARY}[FAIL] ${label}: commit error%0A"
        return 1
    fi
    log "     ${LG}\u2514\u2500 commit: ${YL}${commit_id}${X}"

    # --- Archive on remote ---
    log "  ${OR}\u25a3${X} ${YL}${CONTAINER}${X} archiving remotely..."
    local t_start t_end elapsed
    t_start=$(date +%s)
    $ssh_cmd ${SSH_USER}@${ip} "
        if command -v pigz &>/dev/null; then
            docker save ${CONTAINER}-bak:${DATE} | pigz > ${remote_arch}
        else
            docker save ${CONTAINER}-bak:${DATE} | gzip > ${remote_arch}
        fi
        docker rmi ${CONTAINER}-bak:${DATE} >/dev/null 2>&1
    " 2>/dev/null
    t_end=$(date +%s)
    elapsed=$((t_end - t_start))

    # --- Download archive ---
    log "  ${CY}\u2193${X} ${YL}${label}${X} downloading archive..."
    $scp_cmd ${SSH_USER}@${ip}:${remote_arch} "${local_arch}" 2>/dev/null
    $ssh_cmd ${SSH_USER}@${ip} "rm -f ${remote_arch}" 2>/dev/null

    if [ -s "$local_arch" ]; then
        local sz raw speed=""
        sz=$(du -sh "$local_arch" | cut -f1)
        raw=$(stat -c%s "$local_arch" 2>/dev/null || echo 0)
        [ "$elapsed" -gt 0 ] && speed=$(echo "scale=1; $raw / $elapsed / 1048576" | bc 2>/dev/null) \
            && speed="  ${CY}@ ${LG}${speed} MB/s${X}"
        log_ok "${YL}${label}${GN}: ${LY}$(basename "${local_arch}")${X}"
        echo -e "     ${WH}\u251c\u2500 Size   : ${GN}${sz}${X}"
        echo -e "     ${WH}\u251c\u2500 Time   : ${CY}${elapsed}s${speed}${X}"
        echo -e "     ${WH}\u2514\u2500 Status : ${GN}OK \u2713${X}"
        SUMMARY="${SUMMARY}[OK] ${label} (${ip}): ${sz} (${elapsed}s)%0A"
        SUCCESS=$((SUCCESS+1))
    else
        fail "${label}: downloaded archive empty or missing"
        SUMMARY="${SUMMARY}[FAIL] ${label}: download error%0A"
        return 1
    fi

    # --- Rotate old backups ---
    rotate_local "$dest_dir"
    local cnt
    cnt=$(ls "$dest_dir"/*.tar.gz 2>/dev/null | wc -l)
    echo -e "     ${PK}\u25a4 Archives: ${WH}${cnt}/${KEEP} kept${X}"
    ls -t "$dest_dir"/*.tar.gz 2>/dev/null | tail -n +2 | head -2 | while IFS= read -r f; do
        local f_sz f_date
        f_sz=$(du -sh "$f" 2>/dev/null | cut -f1)
        f_date=$(stat -c%y "$f" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
        echo -e "        ${CY}\u2514\u2500 ${OR}${f_sz}${X} ${WH}${f_date}${X} \u2014 $(basename "$f")"
    done
    echo
}

# =============================================================================
#  MAIN
# =============================================================================
DISK_FREE=$(df -h /BACKUP 2>/dev/null | awk 'NR==2{print $4}' || df -h / | awk 'NR==2{print $4}')
LOAD=$(uptime | awk -F'load average:' '{print $2}' | xargs)
SERVER_IP=$(hostname -I | awk '{print $1}')

echo -e "$HR"
echo -e "  \U0001f6e1  ${WH}VPN BACKUP${X}  \u00b7  ${YL}222-DE-NetCup${X}  \u00b7  ${CY}${SERVER_IP}${X}"
echo -e "  \U0001f4c5 ${CY}$(date '+%Y-%m-%d')${X}  ${WH}$(date '+%H:%M:%S')${X}   \U0001f4bf ${GN}${DISK_FREE} free${X}   \U0001f4ca ${WH}load: ${LY}${LOAD}${X}"
echo -e "  \U0001f310 ${WH}${TOTAL} VPN servers${X}   \U0001f504 ${WH}keep: ${CY}${KEEP}${X}   \U0001f4c2 ${YL}${LOCAL_BACKUP_ROOT}${X}"
echo -e "$HR"

if [ ! -f "$SSH_KEY" ]; then
    echo -e "${RD}ERROR: SSH key not found: ${SSH_KEY}${X}"
    echo -e "${YL}Generate: ssh-keygen -t ed25519 -f ${SSH_KEY}${X}"
    echo -e "${YL}Copy to servers: ssh-copy-id -i ${SSH_KEY} root@<ip>${X}"
    exit 1
fi

IDX=0
for entry in "${SERVERS[@]}"; do
    IDX=$((IDX+1))
    IFS='|' read -r label ip port_override <<< "$entry"
    backup_server "$IDX" "$label" "$ip" "$port_override"
done

# =============================================================================
#  SUMMARY
# =============================================================================
END_TIME=$(date +%s)
TOTAL_ELAPSED=$((END_TIME - START_TIME))
TOTAL_SZ=$(du -sh "${LOCAL_BACKUP_ROOT}/" 2>/dev/null | cut -f1)

echo -e "$HR"
if [ "$ERRORS" -eq 0 ]; then
    echo -e "  ${GN}\u2714  ALL DONE \u2014 NO ERRORS${X}"
    MSG="\u2705 *VPN BACKUP OK* | 222-DE-NetCup%0A%0A${SUMMARY}%0ATotal: ${TOTAL_SZ}%0ATime: ${TOTAL_ELAPSED}s%0A$(date '+%Y-%m-%d %H:%M')"
else
    echo -e "  ${RD}\u26a0  COMPLETED: ${SUCCESS}/${TOTAL} OK  |  ${ERRORS} ERROR(S)${X}"
    MSG="\u26a0 *VPN BACKUP ERRORS* | 222-DE-NetCup%0AErrors: ${ERRORS}/${TOTAL}%0A%0A${SUMMARY}%0A$(date '+%Y-%m-%d %H:%M')"
fi
echo -e "  ${WH}\u251c\u2500 Servers OK  : ${GN}${SUCCESS}/${TOTAL}${X}"
echo -e "  ${WH}\u251c\u2500 Total size  : ${GN}${TOTAL_SZ:-?}${X}"
echo -e "  ${WH}\u251c\u2500 Total time  : ${CY}${TOTAL_ELAPSED}s${X}"
echo -e "  ${WH}\u251c\u2500 Errors      : $([ $ERRORS -eq 0 ] && echo "${GN}0${X}" || echo "${RD}${ERRORS}${X}")${X}"
echo -e "  ${WH}\u2514\u2500 Finished at : ${YL}$(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "$HR"
echo -e "              ${YL}= Rooted by VladiMIR | AI =${X}"
echo

tg "$MSG"
