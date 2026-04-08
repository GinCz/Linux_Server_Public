#!/bin/bash
clear
# =============================================================================
#  f9_restore.sh
# =============================================================================
#  Version    : v2026-04-08
#  Author     : Ing. VladiMIR Bulantsev
#  GitHub     : https://github.com/GinCz/Linux_Server_Public
#  Server     : 222-DE-NetCup | IP: ...222
#  Alias      : f9
# =============================================================================
#
#  DESCRIPTION
#  -----------
#  Universal Docker restore menu for server .222
#  Step 1: choose container (crypto-bot / amnezia-awg / semaphore)
#  Step 2: choose backup file (newest -> oldest, all available)
#  Step 3: confirm and restore
#
#  USAGE
#  -----
#  bash /root/Linux_Server_Public/222/Dockers/f9_restore.sh
#  Alias: f9
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
HR="${C}$(printf '%.0s=' {1..72})${X}"

log()  { echo -e "${C}$(date +%H:%M:%S)${X} $1"; }
ok()   { echo -e "${G}$(date +%H:%M:%S) ✅ $1${X}"; }
fail() { echo -e "${R}$(date +%H:%M:%S) ❌ $1${X}"; exit 1; }
warn() { echo -e "${Y}$(date +%H:%M:%S) ⚠️  $1${X}"; }
ask()  { echo -en "${Y}  ➤ $1${X} "; }

BACKUP_BASE="/BACKUP/222/docker"

# =============================================================================
# STEP 1 — Choose container
# =============================================================================
echo -e "$HR"
echo -e "${C}   🔄 DOCKER RESTORE MENU — 222-DE-NetCup${X}"
echo -e "${C}   📅 $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "$HR"
echo
echo -e "  ${Y}[1]${X}  ${W}crypto-bot${X}       — crypto trading bot"
echo -e "  ${Y}[2]${X}  ${W}amnezia-awg${X}      — VPN (AmneziaWG)"
echo -e "  ${Y}[3]${X}  ${W}semaphore${X}        — Semaphore CI/CD"
echo
ask "Select container [1-3]:"
read -r C_CHOICE

case "$C_CHOICE" in
  1)
    CONTAINER="crypto-bot"
    BACKUP_DIR="${BACKUP_BASE}/crypto"
    STRATEGY="volumes"    # tar + docker-compose
    COMPOSE_DIR="/root/crypto-docker"
    ;;
  2)
    CONTAINER="amnezia-awg"
    BACKUP_DIR="${BACKUP_BASE}/amnezia"
    STRATEGY="commit"     # docker commit image
    AWG_PORT="123"
    ;;
  3)
    CONTAINER="semaphore"
    BACKUP_DIR="${BACKUP_BASE}/semaphore"
    STRATEGY="volumes"
    COMPOSE_DIR="/root/semaphore-data"
    ;;
  *)
    fail "Invalid selection."
    ;;
esac

echo
log "Selected: ${Y}${CONTAINER}${X}  |  Backup dir: ${Y}${BACKUP_DIR}${X}  |  Strategy: ${Y}${STRATEGY}${X}"
echo

# =============================================================================
# STEP 2 — Choose backup file
# =============================================================================
[ -d "$BACKUP_DIR" ] || fail "Backup directory not found: ${BACKUP_DIR}"

mapfile -t BACKUPS < <(ls -t "${BACKUP_DIR}"/*.tar.gz 2>/dev/null)
[ ${#BACKUPS[@]} -eq 0 ] && fail "No backup files found in ${BACKUP_DIR}"

echo -e "$HR"
echo -e "  ${C}Available backups (newest → oldest):${X}"
echo -e "$HR"

for i in "${!BACKUPS[@]}"; do
    NUM=$((i + 1))
    FILE=$(basename "${BACKUPS[$i]}")
    SIZE=$(du -sh "${BACKUPS[$i]}" 2>/dev/null | cut -f1)
    MDATE=$(stat -c '%y' "${BACKUPS[$i]}" 2>/dev/null | cut -d'.' -f1)
    MARKER=""
    [ $i -eq 0 ] && MARKER=" ${G}[NEWEST]${X}"
    [ $i -eq $((${#BACKUPS[@]} - 1)) ] && MARKER=" ${Y}[OLDEST]${X}"
    echo -e "  ${Y}[${NUM}]${X} ${W}${FILE}${X}  ${G}${SIZE}${X}  ${C}${MDATE}${X}${MARKER}"
done

echo -e "$HR"
echo
ask "Select backup [1-${#BACKUPS[@]}]:"
read -r B_CHOICE

if ! [[ "$B_CHOICE" =~ ^[0-9]+$ ]] || \
   [ "$B_CHOICE" -lt 1 ] || \
   [ "$B_CHOICE" -gt "${#BACKUPS[@]}" ]; then
    fail "Invalid selection."
fi

SELECTED="${BACKUPS[$((B_CHOICE - 1))]}"
echo
ok "Selected: $(basename "$SELECTED")"

# =============================================================================
# STEP 3 — Confirmation
# =============================================================================
echo
echo -e "$HR"
echo -e "  ${R}⚠⚠  WARNING  ⚠⚠${X}"
echo -e "  Container ${Y}${CONTAINER}${X} will be ${R}STOPPED and replaced${X}."
if [ "$STRATEGY" = "commit" ]; then
    echo -e "  ${G}✔ Users/keys are PRESERVED inside the backup image.${X}"
fi
echo -e "$HR"
ask "Are you sure? [Y/N]:"
read -r CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo -e "\n  ${Y}[CANCELLED]${X} Nothing changed."; exit 0; }
echo

# =============================================================================
# RESTORE — Strategy: VOLUMES (crypto-bot, semaphore)
# =============================================================================
if [ "$STRATEGY" = "volumes" ]; then

    log "[1/5] Stopping container ${CONTAINER}..."
    docker stop "$CONTAINER" 2>/dev/null && ok "Stopped" || warn "Was not running"
    docker rm   "$CONTAINER" 2>/dev/null && ok "Removed" || warn "Did not exist"
    echo

    STAMP=$(date +%Y-%m-%d_%H-%M)
    log "[2/5] Backing up current data to ${COMPOSE_DIR}.bak_${STAMP}..."
    [ -d "$COMPOSE_DIR" ] && cp -a "$COMPOSE_DIR" "${COMPOSE_DIR}.bak_${STAMP}"
    ok "Current data backed up"
    echo

    log "[3/5] Extracting $(basename "$SELECTED")..."
    tar -xzf "$SELECTED" -C /
    ok "Extracted"
    echo

    DOCKER_IMAGE="/tmp/${CONTAINER}-image.tar.gz"
    if [ -f "$DOCKER_IMAGE" ]; then
        log "[4/5] Loading Docker image..."
        docker load -i "$DOCKER_IMAGE"
        ok "Image loaded"
    else
        log "[4/5] No Docker image in archive — skipping"
    fi
    echo

    log "[5/5] Starting via docker-compose..."
    cd "$COMPOSE_DIR" && docker-compose up -d
    echo

fi

# =============================================================================
# RESTORE — Strategy: COMMIT (amnezia-awg)
# =============================================================================
if [ "$STRATEGY" = "commit" ]; then

    log "[1/6] Loading backup image..."
    docker load -i "$SELECTED" 2>&1 | tail -3
    echo

    BACKUP_DATE=$(basename "$SELECTED" | grep -oP '\d{4}-\d{2}-\d{2}')
    BACKUP_IMAGE="amnezia-awg-backup:${BACKUP_DATE}"
    log "[2/6] Loaded image tag: ${Y}${BACKUP_IMAGE}${X}"

    # Verify keys inside the image without starting wg0
    echo
    log "[3/6] Verifying backup contents (safe read-only check)..."
    echo -e "  ${Y}--- /opt/amnezia/awg/ ---${X}"
    docker run --rm --entrypoint="" "$BACKUP_IMAGE" ls -lah /opt/amnezia/awg/ 2>/dev/null
    echo
    echo -e "  ${Y}--- Server public key ---${X}"
    docker run --rm --entrypoint="" "$BACKUP_IMAGE" \
        cat /opt/amnezia/awg/wireguard_server_public_key.key 2>/dev/null
    echo
    echo -e "  ${Y}--- Number of peers in wg0.conf ---${X}"
    docker run --rm --entrypoint="" "$BACKUP_IMAGE" \
        grep -c '\[Peer\]' /opt/amnezia/awg/wg0.conf 2>/dev/null \
        && echo " peer(s)" || echo "  (could not read wg0.conf)"
    echo

    ask "Contents look correct? Continue? [Y/N]:"
    read -r CONT
    [[ "$CONT" =~ ^[Yy]$ ]] || { echo -e "  ${Y}[CANCELLED]${X} Nothing changed."; exit 0; }
    echo

    log "[4/6] Stopping old container..."
    docker stop "$CONTAINER" 2>/dev/null && ok "Stopped" || warn "Was not running"
    docker rm   "$CONTAINER" 2>/dev/null && ok "Removed" || warn "Did not exist"
    echo

    log "[5/6] Tagging image and starting container on port ${AWG_PORT}/udp..."
    docker tag "$BACKUP_IMAGE" "${CONTAINER}:latest"
    docker run -d \
        --name "$CONTAINER" \
        --privileged \
        --cap-add CAP_NET_ADMIN \
        --cap-add CAP_SYS_MODULE \
        --sysctl net.ipv4.ip_forward=1 \
        --sysctl net.ipv4.conf.all.src_valid_mark=1 \
        -p ${AWG_PORT}:${AWG_PORT}/udp \
        -v /lib/modules:/lib/modules \
        --restart always \
        "${CONTAINER}"
    echo
    log "Waiting 10 seconds for wg0 to initialize..."
    sleep 10
    echo

    log "[6/6] Verify..."
    echo -e "  ${Y}--- WireGuard interface ---${X}"
    docker exec "$CONTAINER" wg show 2>/dev/null | head -12
    echo
    echo -e "  ${Y}--- Port ${AWG_PORT}/udp ---${X}"
    ss -ulnp | grep ":${AWG_PORT}"

    # UFW auto-fix
    if command -v ufw &>/dev/null; then
        UFW_OK=$(ufw status | grep "${AWG_PORT}/udp" 2>/dev/null)
        if [ -z "$UFW_OK" ]; then
            warn "UFW rule missing — adding ${AWG_PORT}/udp..."
            ufw allow ${AWG_PORT}/udp
            ok "UFW: ${AWG_PORT}/udp ALLOW added"
        else
            ok "UFW rule OK: ${AWG_PORT}/udp"
        fi
    fi
    echo

fi

# =============================================================================
# DONE
# =============================================================================
echo -e "$HR"
ok "RESTORE COMPLETE — ${CONTAINER} is running"
echo -e "$HR"
echo -e "  ${C}Container:${X} $(docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep $CONTAINER)"
echo -e "$HR"
echo -e "${C}              = Rooted by VladiMIR | AI =${X}"
echo -e "$HR"
echo
