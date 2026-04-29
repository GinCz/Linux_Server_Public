#!/bin/bash
# =============================================================================
# xray_install.sh — Universal x-ui + Xray VLESS Reality installer
# Version     : v2026-04-30
# Safe        : Does NOT reset UFW. Only ADDS port rules. Does NOT touch
#               FastPanel, nginx, mysql, AdGuard, Semaphore or other services.
# Usage       : bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/XRAY/xray_install.sh)
# README      : https://github.com/GinCz/Linux_Server_Public/blob/main/XRAY/README.md
# = Rooted by VladiMIR | AI =
# =============================================================================
clear
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin

sysctl -w fs.inotify.max_user_watches=524288 >/dev/null 2>&1 || true
sysctl -w fs.inotify.max_user_instances=8192 >/dev/null 2>&1 || true
printf 'fs.inotify.max_user_watches=524288\nfs.inotify.max_user_instances=8192\n' > /etc/sysctl.d/99-inotify-limits.conf
sysctl --system >/dev/null 2>&1 || true

rm -f /etc/apt/sources.list.d/*amnezia* 2>/dev/null || true
sed -i '/packages\.amnezia\.org/d' /etc/apt/sources.list 2>/dev/null || true

read -rp "Enter server name: " NEWNAME
[[ -n "${NEWNAME:-}" ]] || { echo "Server name cannot be empty"; exit 1; }

while true; do
  read -rp "x-ui PANEL port [default 54321]: " PANEL_PORT
  PANEL_PORT="${PANEL_PORT:-54321}"
  [[ "${PANEL_PORT}" =~ ^[0-9]+$ ]] && ((PANEL_PORT>=1 && PANEL_PORT<=65535)) && break
  echo "Invalid port"
done

while true; do
  read -rp "XRAY/VLESS port [default 443]: " XRAY_PORT
  XRAY_PORT="${XRAY_PORT:-443}"
  [[ "${XRAY_PORT}" =~ ^[0-9]+$ ]] && ((XRAY_PORT>=1 && XRAY_PORT<=65535)) && break
  echo "Invalid port"
done

clear
echo "========================================="
echo " XRAY PANEL INSTALL v2026-04-30"
echo " = Rooted by VladiMIR | AI ="
echo "========================================="
echo "SERVER:     ${NEWNAME}"
echo "PANEL PORT: ${PANEL_PORT}"
echo "XRAY PORT:  ${XRAY_PORT}"
echo "EXTRA UFW:  443/tcp  8443/tcp"
echo "========================================="
read -rp "Type YES to continue: " CONFIRM
[[ "${CONFIRM}" == "YES" ]] || { echo "Aborted"; exit 1; }

hostnamectl set-hostname "${NEWNAME}"
grep -q '^127.0.1.1' /etc/hosts \
  && sed -i "s/^127.0.1.1.*/127.0.1.1 ${NEWNAME}/" /etc/hosts \
  || echo "127.0.1.1 ${NEWNAME}" >> /etc/hosts
echo "${NEWNAME}" > /etc/hostname
timedatectl set-timezone Europe/Prague
update-locale LANG=en_US.UTF-8 >/dev/null 2>&1 || true

# Remove Amnezia/AWG/WireGuard (safe: all errors suppressed)
for C in $(docker ps -a --format '{{.Names}}' 2>/dev/null | grep -Ei 'amnezia|awg|wireguard' || true); do
  docker stop "$C" 2>/dev/null || true; docker rm -f "$C" 2>/dev/null || true
done
for IMG in $(docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -Ei 'amnezia|awg|wireguard' || true); do
  docker rmi -f "$IMG" 2>/dev/null || true
done
for SVC in amnezia-awg amneziawg awg wg-quick@wg0 wg-quick@awg0 wireguard; do
  systemctl stop "$SVC" 2>/dev/null || true; systemctl disable "$SVC" 2>/dev/null || true
done
for IFACE in $(ip link show 2>/dev/null | grep -oP '(?<=\d: )(wg\S+|awg\S+)' || true); do
  ip link delete "$IFACE" 2>/dev/null || true
done
rm -rf /opt/amnezia* /etc/amnezia* /var/lib/amnezia* /root/amnezia* 2>/dev/null || true
rm -rf /etc/wireguard /var/lib/wireguard 2>/dev/null || true
find /etc/systemd/system /lib/systemd/system -maxdepth 1 -type f \
  \( -iname '*amnezia*' -o -iname '*awg*' -o -iname '*wireguard*' \) \
  -exec rm -f {} \; 2>/dev/null || true
systemctl daemon-reload || true
apt-get purge -y wireguard wireguard-tools wireguard-dkms 2>/dev/null || true
apt-get autoremove -y 2>/dev/null || true

# Install dependencies
killall apt apt-get unattended-upgrade 2>/dev/null || true
rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock
dpkg --configure -a >/dev/null 2>&1 || true
apt update -y
apt install -y curl wget ufw socat uuid-runtime jq ca-certificates

# Remove old x-ui
systemctl stop x-ui xray 2>/dev/null || true
systemctl disable x-ui xray 2>/dev/null || true
x-ui uninstall 2>/dev/null || true
rm -rf /usr/local/x-ui /usr/local/xray /etc/x-ui /etc/xray
rm -f /usr/bin/x-ui /etc/systemd/system/x-ui.service /etc/systemd/system/xray.service
systemctl daemon-reload || true

# Install x-ui
bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh) <<< $'1\ny\n'
sleep 5
command -v x-ui >/dev/null 2>&1 || { echo "[FAIL] x-ui not found after install"; exit 1; }

# Configure panel port
x-ui setting -p "${PANEL_PORT}" 2>/dev/null || echo "[WARN] x-ui setting -p failed"
x-ui restart >/dev/null 2>&1 || systemctl restart x-ui || true
sleep 4

# Read actual settings
SETTINGS_RAW="$(x-ui settings 2>/dev/null || true)"
REAL_PORT="$(echo "${SETTINGS_RAW}" | grep -oP 'port: \K\d+' | head -1)"
PATH_URL="$(echo "${SETTINGS_RAW}" | grep -oP 'webBasePath: \K/\S+' | head -1)"
USER_NAME="$(echo "${SETTINGS_RAW}" | grep -oP 'username: \K\S+' | head -1)"
PASS_WORD="$(echo "${SETTINGS_RAW}" | grep -oP 'password: \K\S+' | head -1)"
IP="$(curl -4 -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
TZ_NOW="$(timedatectl | grep 'Time zone' | awk '{print $3}')"
[[ -n "${REAL_PORT:-}" ]] || REAL_PORT="${PANEL_PORT}"

# UFW: only ADD rules, do NOT reset (safe for FastPanel/AdGuard/other services)
ufw allow 22/tcp
ufw allow 443/tcp
ufw allow 8443/tcp
ufw allow "${REAL_PORT}"/tcp
ufw allow "${XRAY_PORT}"/tcp
ufw --force enable

clear
echo "========================================="
echo " XRAY PANEL INSTALL v2026-04-30"
echo " = Rooted by VladiMIR | AI ="
echo "========================================="
echo "SERVER:   ${NEWNAME}"
echo "TIMEZONE: ${TZ_NOW}"
echo "=========================================" 
echo "PANEL URL:"
echo "http://${IP}:${REAL_PORT}${PATH_URL:-/}"
echo "LOGIN:    ${USER_NAME:-unknown}"
echo "PASS:     ${PASS_WORD:-unknown}"
echo "========================================="
echo "UFW RULES ADDED: 22 443 8443 ${REAL_PORT} ${XRAY_PORT}"
echo "========================================="
echo "README: https://github.com/GinCz/Linux_Server_Public/blob/main/XRAY/README.md"
echo "========================================="
echo
ufw status numbered
