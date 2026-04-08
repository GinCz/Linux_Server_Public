#!/bin/bash
clear
# =============================================================================
#  awg_restore.sh
# =============================================================================
#  Version    : v2026-04-08
#  Author     : Ing. VladiMIR Bulantsev
#  GitHub     : https://github.com/GinCz/Linux_Server_Public
#  Server     : 222-DE-NetCup | IP: 152.53.182.222
#  Alias      : awgrestore
# =============================================================================
#
#  DESCRIPTION
#  -----------
#  Restores amnezia-awg Docker container from the latest backup.
#  Uses "docker commit" backup strategy (Strategy B).
#
#  The backup contains EVERYTHING:
#    - WireGuard server private/public/psk keys
#    - wg0.conf (port 123, junk params S1/S2/H1-H4)
#    - clientsTable (all user peers — NO need to recreate keys!)
#    - AmneziaWG binaries and config
#
#  USAGE
#  -----
#  bash /root/Linux_Server_Public/222/Dockers/awg_restore.sh
#  Alias: awgrestore
#
#  IMPORTANT
#  ---------
#  Port: 123/udp (disguised as NTP traffic)
#  DO NOT change to 34337 — clients use port 123!
#
# =============================================================================
#  = Rooted by VladiMIR | AI =
# =============================================================================

# --- Colors ---
C="\033[1;36m"; G="\033[1;32m"; Y="\033[1;33m"; R="\033[1;31m"; X="\033[0m"
HR="${C}═══════════════════════════════════════════════════════════════════════════════${X}"

BACKUP_DIR="/BACKUP/222/docker/amnezia"
CONTAINER="amnezia-awg"
PORT="123"

log()  { echo -e "${C}$(date +%H:%M:%S)${X} $1"; }
ok()   { echo -e "${G}$(date +%H:%M:%S) ✅ $1${X}"; }
fail() { echo -e "${R}$(date +%H:%M:%S) ❌ $1${X}"; exit 1; }
warn() { echo -e "${Y}$(date +%H:%M:%S) ⚠️  $1${X}"; }

echo -e "$HR"
echo -e "${C}   🔄 AMNEZIA-AWG RESTORE — 222-DE-NetCup${X}"
echo -e "${C}   📅 $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "$HR"
echo

# --- Step 1: Find latest backup ---
log "[1/7] Looking for latest backup in ${BACKUP_DIR}..."
LATEST=$(ls -t "${BACKUP_DIR}"/amnezia-awg_*.tar.gz 2>/dev/null | head -1)
[ -z "$LATEST" ] && fail "No backup files found in ${BACKUP_DIR}!"
ok "Found: ${LATEST}"
echo

# --- Step 2: Load backup image ---
log "[2/7] Loading Docker image from backup..."
docker load -i "$LATEST" 2>&1 | tail -2
echo

# --- Step 3: Detect loaded image tag ---
log "[3/7] Detecting loaded image..."
BACKUP_DATE=$(basename "$LATEST" | sed 's/amnezia-awg_//;s/.tar.gz//')
BACKUP_IMAGE="amnezia-awg-backup:${BACKUP_DATE}"
log "Image tag: ${Y}${BACKUP_IMAGE}${X}"
echo

# --- Step 4: Verify contents ---
log "[4/7] Verifying backup contents..."
echo -e "${Y}--- Files in /opt/amnezia/awg/ ---${X}"
docker run --rm --entrypoint="" "$BACKUP_IMAGE" ls -lah /opt/amnezia/awg/ 2>/dev/null
echo
echo -e "${Y}--- Server public key ---${X}"
docker run --rm --entrypoint="" "$BACKUP_IMAGE" cat /opt/amnezia/awg/wireguard_server_public_key.key 2>/dev/null
echo
echo -e "${Y}--- Users (clientsTable) ---${X}"
docker run --rm --entrypoint="" "$BACKUP_IMAGE" cat /opt/amnezia/awg/clientsTable 2>/dev/null | grep -o '"clientName": "[^"]*"' | sed 's/"clientName": //g'
echo

# --- Step 5: Stop and remove old container ---
log "[5/7] Stopping old container (if running)..."
docker stop "$CONTAINER" 2>/dev/null && ok "Stopped: $CONTAINER" || warn "Container was not running"
docker rm "$CONTAINER" 2>/dev/null && ok "Removed: $CONTAINER" || warn "Container did not exist"
echo

# --- Step 6: Tag and run ---
log "[6/7] Tagging image and starting container on port ${PORT}/udp..."
docker tag "$BACKUP_IMAGE" "${CONTAINER}:latest"

docker run -d \
  --name "$CONTAINER" \
  --privileged \
  --cap-add CAP_NET_ADMIN \
  --cap-add CAP_SYS_MODULE \
  --sysctl net.ipv4.ip_forward=1 \
  --sysctl net.ipv4.conf.all.src_valid_mark=1 \
  -p ${PORT}:${PORT}/udp \
  -v /lib/modules:/lib/modules \
  --restart always \
  "${CONTAINER}"

echo
log "Waiting 10 seconds for wg0 to initialize..."
sleep 10

# --- Step 7: Verify ---
log "[7/7] Verification..."
echo -e "${Y}--- Container status ---${X}"
docker ps | grep "$CONTAINER"
echo
echo -e "${Y}--- WireGuard interface ---${X}"
docker exec "$CONTAINER" wg show 2>/dev/null | head -12
echo
echo -e "${Y}--- Port ${PORT}/udp ---${X}"
ss -ulnp | grep ":${PORT}"
echo

# --- UFW check ---
if command -v ufw &>/dev/null; then
    UFW_STATUS=$(ufw status | grep "${PORT}/udp" 2>/dev/null)
    if [ -z "$UFW_STATUS" ]; then
        warn "UFW rule for ${PORT}/udp not found! Adding..."
        ufw allow ${PORT}/udp
        ok "UFW rule added: ${PORT}/udp ALLOW"
    else
        ok "UFW rule exists: ${UFW_STATUS}"
    fi
fi

echo
echo -e "$HR"
ok "RESTORE COMPLETE — amnezia-awg is running on port ${PORT}/udp"
warn "Users DO NOT need to reconfigure — their keys are preserved in the backup!"
echo -e "$HR"
echo -e "${C}              = Rooted by VladiMIR | AI =${X}"
echo -e "$HR"
echo
