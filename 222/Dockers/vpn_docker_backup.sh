#!/bin/bash
clear
# =============================================================================
#  vpn_docker_backup.sh
# =============================================================================
#  Version    : v2026-04-08
#  Author     : Ing. VladiMIR Bulantsev
#  GitHub     : https://github.com/GinCz/Linux_Server_Public
#  Server     : 222-DE-NetCup | IP: ...222  (MASTER — run only here!)
#  Alias      : f5vpn
# =============================================================================
#
#  DESCRIPTION
#  -----------
#  Connects via SSH (MASTER key /root/.ssh/id_ed25519) to ALL VPN servers,
#  detects running Docker containers on each, makes backups using
#  "docker commit" strategy (works for any container without compose),
#  saves archives locally to /BACKUP/vpn/<server>/<container>_DATE.tar.gz
#
#  Uses same SSH architecture as allinfo (all_servers_info.sh):
#  server-222 → all VPN nodes via /root/.ssh/id_ed25519
#
#  CRON (run from server .222 at 04:00 daily):
#  0 4 * * * /root/Linux_Server_Public/222/Dockers/vpn_docker_backup.sh >> /var/log/vpn_docker_backup.log 2>&1
#
#  BACKUP LOCATION:
#  /BACKUP/vpn/<server-name>/<container>_YYYY-MM-DD_HH-MM.tar.gz
#
#  ROTATION:
#  Keeps last 3 archives per container per server.
#
# =============================================================================
#  = Rooted by VladiMIR | AI =
# =============================================================================

# --- Colors ---
C="\033[1;36m"
G="\033[1;32m"
Y="\033[1;33m"
R="\033[1;31m"
W="\033[1;37m"
X="\033[0m"
HR="${C}$(printf '%.0s=' {1..80})${X}"

log()  { echo -e "${C}$(date +%H:%M:%S)${X} $1"; }
ok()   { echo -e "${G}$(date +%H:%M:%S) ✅ $1${X}"; }
fail() { echo -e "${R}$(date +%H:%M:%S) ❌ $1${X}"; ERRORS=$((ERRORS+1)); }
warn() { echo -e "${Y}$(date +%H:%M:%S) ⚠️  $1${X}"; }

# =============================================================================
#  CONFIG
# =============================================================================

# SSH master key (from server .222 to all VPN nodes)
SSH_KEY="/root/.ssh/id_ed25519"
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=8 -o BatchMode=yes"
SSH_USER="root"

# Local backup destination
BACKUP_BASE="/BACKUP/vpn"

# How many archives to keep per container per server
KEEP=3

# Telegram (optional, set on server — never commit tokens)
TOKEN=""
CHAT_ID=""

# =============================================================================
#  VPN SERVERS LIST
#  Format: "label:ip"
#  Add/remove servers here. server-109 is NOT a VPN node — skip it.
# =============================================================================
VPN_SERVERS=(
    "alex47:109.234.38.47"
    "4ton237:144.124.228.237"
    "tatra9:144.124.232.9"
    "shahin227:144.124.228.227"
    "stolb24:144.124.239.24"
    "pilik178:91.84.118.178"
    "ilya176:146.103.110.176"
    "so38:144.124.233.38"
)

# =============================================================================
#  FUNCTIONS
# =============================================================================

tg() {
    [ -z "$TOKEN" ] || [ -z "$CHAT_ID" ] && return
    curl -s "https://api.telegram.org/bot${TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}&text=$1&parse_mode=Markdown" >/dev/null
}

rotate() {
    local dir="$1"
    ls -t "${dir}"/*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f
}

# backup_container_via_ssh LABEL IP CONTAINER_NAME DEST_DIR
backup_container_via_ssh() {
    local server_label="$1"
    local ip="$2"
    local cname="$3"
    local dest_dir="$4"
    local date_stamp
    date_stamp=$(date +%Y-%m-%d_%H-%M)
    local arch="${dest_dir}/${cname}_${date_stamp}.tar.gz"

    mkdir -p "$dest_dir"

    log "    📸 commit ${Y}${cname}${X} on ${C}${server_label}${X}..."

    # Step 1: docker commit on remote server -> image saved to /tmp
    local remote_image="${cname}-bak-${date_stamp}"
    local remote_file="/tmp/${cname}_${date_stamp}.tar.gz"

    ssh $SSH_OPTS -i "$SSH_KEY" ${SSH_USER}@${ip} \
        "docker commit ${cname} ${remote_image} > /dev/null 2>&1 && \
         docker save ${remote_image} | gzip > ${remote_file} && \
         docker rmi ${remote_image} > /dev/null 2>&1 && \
         echo OK" 2>/dev/null

    # Step 2: download archive from remote to local
    scp $SSH_OPTS -i "$SSH_KEY" \
        ${SSH_USER}@${ip}:${remote_file} \
        "${arch}" 2>/dev/null

    # Step 3: cleanup remote /tmp
    ssh $SSH_OPTS -i "$SSH_KEY" ${SSH_USER}@${ip} \
        "rm -f ${remote_file}" 2>/dev/null

    # Step 4: verify
    if [ -s "$arch" ]; then
        local sz
        sz=$(du -sh "$arch" | cut -f1)
        ok "    ${cname} → ${arch} (${Y}${sz}${X})"
        SUMMARY="${SUMMARY}  📦 ${server_label}/${cname}: ${sz}%0A"
    else
        fail "    ${cname} on ${server_label}: archive EMPTY or transfer FAILED"
        rm -f "$arch" 2>/dev/null
    fi

    rotate "$dest_dir"
}

# =============================================================================
#  MAIN
# =============================================================================

DATE=$(date +%Y-%m-%d_%H-%M)
ERRORS=0
SUMMARY=""
SERVERS_OK=0
SERVERS_SKIP=0

echo -e "$HR"
echo -e "${C}   🐳 VPN DOCKER BACKUP — from 222-DE-NetCup${X}"
echo -e "${C}   📅 $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "${C}   📂 Destination: ${BACKUP_BASE}/<server>/<container>_DATE.tar.gz${X}"
echo -e "$HR"
echo

for ENTRY in "${VPN_SERVERS[@]}"; do
    SERVER_LABEL="${ENTRY%%:*}"
    SERVER_IP="${ENTRY##*:}"

    echo -e "$HR"
    log "💻 ${Y}${SERVER_LABEL}${X} (${C}${SERVER_IP}${X})"

    # --- Check SSH connectivity ---
    if ! ssh $SSH_OPTS -i "$SSH_KEY" ${SSH_USER}@${SERVER_IP} "echo ok" &>/dev/null; then
        warn "  SSH UNREACHABLE — skipping ${SERVER_LABEL}"
        SUMMARY="${SUMMARY}❌ ${SERVER_LABEL}: UNREACHABLE%0A"
        SERVERS_SKIP=$((SERVERS_SKIP+1))
        echo
        continue
    fi

    # --- Get list of running Docker containers ---
    CONTAINERS=$(ssh $SSH_OPTS -i "$SSH_KEY" ${SSH_USER}@${SERVER_IP} \
        "docker ps --format '{{.Names}}' 2>/dev/null" 2>/dev/null)

    if [ -z "$CONTAINERS" ]; then
        warn "  No running containers on ${SERVER_LABEL}"
        SUMMARY="${SUMMARY}⚠️ ${SERVER_LABEL}: no containers%0A"
        SERVERS_SKIP=$((SERVERS_SKIP+1))
        echo
        continue
    fi

    log "  Found containers: ${G}$(echo $CONTAINERS | tr '\n' ' ')${X}"
    DEST_BASE="${BACKUP_BASE}/${SERVER_LABEL}"
    SERVERS_OK=$((SERVERS_OK+1))
    SUMMARY="${SUMMARY}%0A💻 ${SERVER_LABEL}:%0A"

    # --- Backup each container ---
    while IFS= read -r CNAME; do
        [ -z "$CNAME" ] && continue
        DEST_DIR="${DEST_BASE}/${CNAME}"
        backup_container_via_ssh "$SERVER_LABEL" "$SERVER_IP" "$CNAME" "$DEST_DIR"
    done <<< "$CONTAINERS"

    echo
done

# =============================================================================
#  SUMMARY
# =============================================================================
echo -e "$HR"
TOTAL=$(du -sh "${BACKUP_BASE}/" 2>/dev/null | cut -f1)

echo -e "  ${C}Servers backed up:${X}  ${G}${SERVERS_OK}${X}"
echo -e "  ${C}Servers skipped:${X}   ${Y}${SERVERS_SKIP}${X}"
echo -e "  ${C}Errors:${X}            ${R}${ERRORS}${X}"
echo -e "  ${C}Total backup size:${X} ${Y}${TOTAL}${X}"
echo

if [ "$ERRORS" -eq 0 ]; then
    ok "VPN DOCKER BACKUP COMPLETE"
    MSG="✅ *VPN DOCKER BACKUP OK* | 222-DE-NetCup%0AServers: ${SERVERS_OK} OK, ${SERVERS_SKIP} skipped%0A%0A${SUMMARY}%0A💾 Total: ${TOTAL}%0A🕐 $(date '+%Y-%m-%d %H:%M')"
else
    fail "COMPLETED WITH ${ERRORS} ERROR(S)"
    MSG="⚠️ *VPN DOCKER BACKUP ERRORS* | 222-DE-NetCup%0AErrors: ${ERRORS}%0AServers: ${SERVERS_OK} OK, ${SERVERS_SKIP} skipped%0A%0A${SUMMARY}%0A🕐 $(date '+%Y-%m-%d %H:%M')"
fi

echo -e "$HR"
echo -e "${C}              = Rooted by VladiMIR | AI =${X}"
echo -e "$HR"
echo

tg "$MSG"
