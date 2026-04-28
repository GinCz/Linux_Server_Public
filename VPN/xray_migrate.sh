#!/bin/bash
# =============================================================
# Script:      xray_migrate_v2026-04-28.sh
# Version:     v2026-04-28
# Location:    VPN/xray_migrate_v2026-04-28.sh
# Run from:    xxx.xxx.xxx.222 (222-DE-NetCup) — connects to VPN nodes via SSH
# Description: Universal migration script for all 8 VPN nodes.
#              Removes AmneziaWG Docker containers and leftovers,
#              preserves special services (Uptime Kuma on TATRA_9,
#              AdGuard Home on STOLB_24), installs x-ui (3x-ui fork),
#              creates VLESS+Reality inbound on port 443,
#              and saves result (panel URL + VLESS link) to /root/xray_result.txt
#              on each node.
# Usage:
#   Single node:   bash xray_migrate_v2026-04-28.sh <NODE_IP> <NODE_NAME>
#   All 8 nodes:   bash xray_migrate_v2026-04-28.sh ALL
# Dependencies:   ssh, scp (on 222); docker, curl, ufw, uuid-runtime (on nodes)
# WARNING:        This script stops and removes AmneziaWG containers on target nodes.
#                 It will NOT remove Uptime Kuma (TATRA_9) or AdGuard Home (STOLB_24).
#                 Samba containers are also preserved.
#                 Run ONE node at a time for safety on first use.
# = Rooted by VladiMIR | AI =
# =============================================================
clear

# ─── Colours ────────────────────────────────────────────────
RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
CYN='\033[0;36m'
WHT='\033[1;37m'
NC='\033[0m'

VERSION="v2026-04-28"
SSH_KEY="/root/.ssh/id_ed25519"
SSH_OPTS="-o StrictHostKeyChecking=accept-new -o ConnectTimeout=15 -i ${SSH_KEY}"
RESULT_DIR="/root/xray_results"
mkdir -p "${RESULT_DIR}"

# ─── Node list (names and IPs loaded from environment or Secret repo) ──────
# Full IPs are NOT stored here — load them on server-222 from /root/.server_env
# Format in /root/.server_env:
#   NODE_ALEX_47="<FULL_IP>"
#   NODE_4TON_237="<FULL_IP>"
#   NODE_TATRA_9="<FULL_IP>"
#   NODE_SHAHIN_227="<FULL_IP>"
#   NODE_STOLB_24="<FULL_IP>"
#   NODE_PILIK_178="<FULL_IP>"
#   NODE_ILYA_176="<FULL_IP>"
#   NODE_SO_38="<FULL_IP>"

ENV_FILE="/root/.server_env"
if [[ ! -f "${ENV_FILE}" ]]; then
  echo -e "${RED}[FAIL]${NC} ${ENV_FILE} not found — create it with NODE_* variables (see script header)"
  exit 1
fi
# shellcheck source=/dev/null
source "${ENV_FILE}"

declare -A NODES=(
  ["ALEX_47"]="${NODE_ALEX_47:-}"
  ["4TON_237"]="${NODE_4TON_237:-}"
  ["TATRA_9"]="${NODE_TATRA_9:-}"
  ["SHAHIN_227"]="${NODE_SHAHIN_227:-}"
  ["STOLB_24"]="${NODE_STOLB_24:-}"
  ["PILIK_178"]="${NODE_PILIK_178:-}"
  ["ILYA_176"]="${NODE_ILYA_176:-}"
  ["SO_38"]="${NODE_SO_38:-}"
)

# Special services to PRESERVE on specific nodes (never removed)
declare -A PRESERVE=(
  ["TATRA_9"]="uptime-kuma"
  ["STOLB_24"]="adguardhome"
)

# ─── Remote payload (runs ON the VPN node via SSH) ──────────
REMOTE_SCRIPT='
set -euo pipefail
NODE_NAME="$1"
PRESERVE_EXTRA="${2:-}"

RED="\033[0;31m"; YEL="\033[1;33m"; GRN="\033[0;32m"; CYN="\033[0;36m"; NC="\033[0m"
info()  { echo -e "${CYN}[INFO]${NC} $*"; }
ok()    { echo -e "${GRN}[ OK ]${NC} $*"; }
warn()  { echo -e "${YEL}[WARN]${NC} $*"; }
fail()  { echo -e "${RED}[FAIL]${NC} $*"; exit 1; }

BACKUP_DIR="/root/backups/xray_migrate/$(date +%F_%H-%M-%S)"
mkdir -p "${BACKUP_DIR}"

# ── 1. Save current state ──────────────────────────────────
info "Saving current state to ${BACKUP_DIR}"
docker ps -a                    > "${BACKUP_DIR}/docker-ps.txt"    2>/dev/null || true
docker volume ls                > "${BACKUP_DIR}/docker-vol.txt"   2>/dev/null || true
cp /root/.bashrc                  "${BACKUP_DIR}/bashrc.bak"       2>/dev/null || true
cp /etc/profile.d/motd_server.sh  "${BACKUP_DIR}/motd.bak"         2>/dev/null || true

# ── 2. Remove AmneziaWG containers only ───────────────────
info "Removing AmneziaWG containers (preserving: ${PRESERVE_EXTRA:-none})"
AMNEZIA_PATTERNS="amnezia-awg amnezia-awg-old amneziawg amnezia-wg amnezia xray"
for C in ${AMNEZIA_PATTERNS}; do
  # Skip containers that must be preserved
  if [[ -n "${PRESERVE_EXTRA}" ]] && echo "${C}" | grep -qi "${PRESERVE_EXTRA}"; then
    warn "Skipping preserved container: ${C}"
    continue
  fi
  # Also skip samba always
  if echo "${C}" | grep -qi "samba\|smb"; then
    warn "Skipping Samba container: ${C}"
    continue
  fi
  if docker ps -a --format "{{.Names}}" | grep -Fxq "${C}" 2>/dev/null; then
    docker stop "${C}" 2>/dev/null || true
    docker rm -f "${C}" 2>/dev/null || true
    ok "Removed container: ${C}"
  fi
done

# ── 3. Remove AmneziaWG directories ───────────────────────
info "Cleaning AmneziaWG directories"
for D in /opt/amnezia* /etc/amnezia* /var/lib/amnezia* /root/amnezia* \
         /usr/local/amnezia* /srv/amnezia*; do
  [[ -e "${D}" ]] && rm -rf "${D}" && ok "Removed: ${D}" || true
done
find /etc/systemd/system /lib/systemd/system -maxdepth 1 -type f \
  \( -iname "*amnezia*" -o -iname "*awg*" \) -exec rm -f {} \; 2>/dev/null || true
systemctl daemon-reload 2>/dev/null || true

# ── 4. Stop old xray/x-ui services if present ─────────────
systemctl stop xray x-ui 2>/dev/null || true
systemctl disable xray   2>/dev/null || true

# ── 5. Clean apt locks ────────────────────────────────────
killall apt apt-get unattended-upgrade 2>/dev/null || true
rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock
dpkg --configure -a 2>/dev/null || true

# ── 6. Install dependencies ───────────────────────────────
info "Installing dependencies"
apt-get update -qq
apt-get install -y -qq curl wget ufw uuid-runtime jq ca-certificates

# ── 7. Install x-ui ──────────────────────────────────────
info "Installing x-ui (3x-ui fork)"
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) <<< $'"'"'y\n'"'"'
sleep 5
command -v x-ui >/dev/null 2>&1 || fail "x-ui not found after install"

# ── 8. Generate Reality keys and UUID ────────────────────
info "Generating Reality keys"
UUID="$(cat /proc/sys/kernel/random/uuid)"
XRAY_BIN=""
for B in /usr/local/x-ui/bin/xray-linux-amd64 /usr/local/bin/xray /usr/bin/xray; do
  [[ -x "${B}" ]] && XRAY_BIN="${B}" && break
done
[[ -n "${XRAY_BIN}" ]] || fail "Xray binary not found"
KEYS="$( "${XRAY_BIN}" x25519 )"
PRIVATE_KEY="$(echo "${KEYS}" | awk "/Private/{print \$3}")"
PUBLIC_KEY="$(echo "${KEYS}"  | awk "/Public/{print \$3}")"
[[ -n "${PRIVATE_KEY}" ]] || fail "Reality key generation failed"

# ── 9. Restart x-ui and add inbound ──────────────────────
info "Starting x-ui"
x-ui restart 2>/dev/null || systemctl restart x-ui || true
sleep 4

x-ui inbound add \
  --remark "${NODE_NAME}" \
  --protocol vless \
  --port 443 \
  --listen 0.0.0.0 \
  --settings "{\"clients\":[{\"id\":\"${UUID}\"}],\"decryption\":\"none\"}" \
  --streamSettings "{\"network\":\"tcp\",\"security\":\"reality\",\"realitySettings\":{\"dest\":\"www.github.com:443\",\"serverNames\":[\"www.github.com\"],\"privateKey\":\"${PRIVATE_KEY}\",\"shortIds\":[\"02\"]}}" \
  2>/dev/null || warn "inbound add via CLI failed — add manually in panel"

sleep 2

# ── 10. Get panel URL info ────────────────────────────────
PANEL_PORT="$(x-ui settings 2>/dev/null | grep -oP "port: \K\d+" | head -n1 || echo "2053")"
PANEL_PATH="$(x-ui settings 2>/dev/null | grep -oP "webBasePath: \K/\S+" | head -n1 || echo "/")"
PANEL_USER="$(x-ui settings 2>/dev/null | grep -oP "username: \K\S+" | head -n1 || echo "admin")"
PANEL_PASS="$(x-ui settings 2>/dev/null | grep -oP "password: \K\S+" | head -n1 || echo "admin")"
MY_IP="$(curl -4 -s --max-time 5 ifconfig.me || hostname -I | awk "{print \$1}")"

# ── 11. Firewall ──────────────────────────────────────────
info "Configuring UFW"
ufw allow 22/tcp   >/dev/null 2>&1
ufw allow 443/tcp  >/dev/null 2>&1
ufw allow "${PANEL_PORT}"/tcp >/dev/null 2>&1
ufw --force enable >/dev/null 2>&1
ok "UFW enabled"

# ── 12. Ensure preserved services still running ──────────
if [[ -n "${PRESERVE_EXTRA}" ]]; then
  docker start "${PRESERVE_EXTRA}" 2>/dev/null && ok "Preserved service started: ${PRESERVE_EXTRA}" || true
fi

# ── 13. Save result ───────────────────────────────────────
RESULT_FILE="/root/xray_result.txt"
cat > "${RESULT_FILE}" << RESULT
=======================================================
 XRAY MIGRATION RESULT — v2026-04-28
 = Rooted by VladiMIR | AI =
=======================================================
 Node:         ${NODE_NAME}
 Date:         $(date "+%Y-%m-%d %H:%M:%S")
 Backup:       ${BACKUP_DIR}
-------------------------------------------------------
 Panel URL:    http://${MY_IP}:${PANEL_PORT}${PANEL_PATH}
 Panel user:   ${PANEL_USER}
 Panel pass:   ${PANEL_PASS}
-------------------------------------------------------
 VLESS link:
 vless://${UUID}@${MY_IP}:443?type=tcp&encryption=none&security=reality&pbk=${PUBLIC_KEY}&fp=chrome&sni=www.github.com&sid=02&spx=%2F#${NODE_NAME}
=======================================================
RESULT

ok "Result saved to ${RESULT_FILE}"
cat "${RESULT_FILE}"
'

# ─── Functions ──────────────────────────────────────────────
header() {
  echo -e "${CYN}"
  echo "══════════════════════════════════════════════════════"
  echo "  🔄  XRAY MIGRATION  ${VERSION}"
  echo "  = Rooted by VladiMIR | AI ="
  echo "══════════════════════════════════════════════════════"
  echo -e "${NC}"
}

migrate_node() {
  local NAME="$1"
  local IP="$2"

  if [[ -z "${IP}" ]]; then
    echo -e "${RED}[SKIP]${NC} ${NAME} — IP not set in ${ENV_FILE}"
    return 1
  fi

  local PRESERVE_SVC="${PRESERVE[${NAME}]:-}"

  echo -e "\n${WHT}▶  Node: ${NAME}  (xxx.xxx.xxx.${IP##*.})${NC}"
  echo "────────────────────────────────────────────────────"

  # Refresh known_hosts silently
  ssh-keygen -f /root/.ssh/known_hosts -R "${IP}" >/dev/null 2>&1 || true

  # Test SSH
  if ! ssh ${SSH_OPTS} root@"${IP}" "echo ssh_ok" >/dev/null 2>&1; then
    echo -e "${RED}[FAIL]${NC} SSH connection failed — skipping ${NAME}"
    return 1
  fi
  echo -e "${GRN}[ OK ]${NC} SSH connected"

  # Run remote payload
  ssh ${SSH_OPTS} root@"${IP}" "bash -s -- '${NAME}' '${PRESERVE_SVC}'" <<< "${REMOTE_SCRIPT}"
  local RC=$?

  if [[ ${RC} -eq 0 ]]; then
    # Fetch result file
    scp ${SSH_OPTS} root@"${IP}":/root/xray_result.txt \
      "${RESULT_DIR}/${NAME}_xray_result.txt" 2>/dev/null || true
    echo -e "${GRN}[ OK ]${NC} ${NAME} migration complete — result saved to ${RESULT_DIR}/${NAME}_xray_result.txt"
  else
    echo -e "${RED}[FAIL]${NC} ${NAME} migration FAILED (exit code ${RC})"
  fi
}

print_results() {
  echo -e "\n${CYN}══════════════════════════════════════════════════════${NC}"
  echo -e "${CYN}  📋  MIGRATION RESULTS SUMMARY${NC}"
  echo -e "${CYN}══════════════════════════════════════════════════════${NC}"
  for F in "${RESULT_DIR}"/*_xray_result.txt; do
    [[ -f "${F}" ]] || continue
    echo -e "\n${WHT}── $(basename "${F}") ──${NC}"
    grep -E "Panel URL|Panel pass|vless://" "${F}" || true
  done
  echo ""
}

# ─── Main ───────────────────────────────────────────────────
header

MODE="${1:-}"
ARG_IP="${2:-}"

case "${MODE}" in
  ALL)
    echo -e "${YEL}[WARN]${NC} Running migration on ALL 8 nodes sequentially."
    echo -e "${YEL}[WARN]${NC} Each node will have AmneziaWG removed and x-ui installed."
    echo -ne "${YEL}Type YES to confirm: ${NC}"
    read -r CONFIRM
    [[ "${CONFIRM}" == "YES" ]] || { echo "Aborted."; exit 0; }
    for NAME in "${!NODES[@]}"; do
      migrate_node "${NAME}" "${NODES[${NAME}]}"
    done
    print_results
    ;;
  ALEX_47|4TON_237|TATRA_9|SHAHIN_227|STOLB_24|PILIK_178|ILYA_176|SO_38)
    # Single node by name
    migrate_node "${MODE}" "${NODES[${MODE}]}"
    ;;
  *)
    # Single node by IP (positional: NAME IP)
    if [[ -n "${MODE}" && -n "${ARG_IP}" ]]; then
      migrate_node "${MODE}" "${ARG_IP}"
    else
      echo -e "${CYN}Usage:${NC}"
      echo "  Single node by name:  bash xray_migrate_v2026-04-28.sh TATRA_9"
      echo "  Single node by IP:    bash xray_migrate_v2026-04-28.sh MYNODE 1.2.3.4"
      echo "  All 8 nodes:          bash xray_migrate_v2026-04-28.sh ALL"
      echo ""
      echo "Available node names:"
      for N in "${!NODES[@]}"; do
        echo "  ${N}"
      done | sort
      exit 0
    fi
    ;;
esac
