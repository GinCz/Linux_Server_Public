#!/bin/bash
# =============================================================================
# xray_install_109.sh — Install x-ui + XRay on 109-RU-FastVDS (NO cleanup)
# Version     : v2026-04-30
# Server      : 109-RU-FastVDS (212.109.223.109) — FastPanel, live sites!
# Panel port  : 54321 (default)
# XRAY port   : 8443
# WARNING     : Server has live websites. No UFW reset. No service removal.
# = Rooted by VladiMIR | AI =
# =============================================================================
clear
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin

read -rp "Enter server name [default: 109-RU-FastVDS]: " NEWNAME
NEWNAME="${NEWNAME:-109-RU-FastVDS}"

while true; do
    read -rp "Enter x-ui PANEL port [default 54321]: " PANEL_PORT
    PANEL_PORT="${PANEL_PORT:-54321}"
    [[ "${PANEL_PORT}" =~ ^[0-9]+$ ]] && [ "${PANEL_PORT}" -ge 1 ] && [ "${PANEL_PORT}" -le 65535 ] && break
    echo "Invalid port"
done

while true; do
    read -rp "Enter XRAY/VLESS port [default 8443]: " XRAY_PORT
    XRAY_PORT="${XRAY_PORT:-8443}"
    [[ "${XRAY_PORT}" =~ ^[0-9]+$ ]] && [ "${XRAY_PORT}" -ge 1 ] && [ "${XRAY_PORT}" -le 65535 ] && break
    echo "Invalid port"
done

clear
echo "========================================="
echo " XRAY PANEL INSTALL v2026-04-30"
echo " Server: ${NEWNAME}"
echo " Panel : ${PANEL_PORT}"
echo " XRAY  : ${XRAY_PORT}"
echo " NOTE  : NO cleanup — live sites preserved"
echo " = Rooted by VladiMIR | AI ="
echo "========================================="
read -rp "Type YES to continue: " CONFIRM
[[ "${CONFIRM}" == "YES" ]] || { echo "Aborted"; exit 1; }

# Hostname
hostnamectl set-hostname "${NEWNAME}"
grep -q '^127.0.1.1' /etc/hosts \
    && sed -i "s/^127.0.1.1.*/127.0.1.1 ${NEWNAME}/" /etc/hosts \
    || echo "127.0.1.1 ${NEWNAME}" >> /etc/hosts
echo "${NEWNAME}" > /etc/hostname
timedatectl set-timezone Europe/Prague
update-locale LANG=en_US.UTF-8 >/dev/null 2>&1 || true
echo "[OK] Hostname and locale set"

# Dependencies (no full apt upgrade, just install what's needed)
apt update -y
apt install -y curl wget socat uuid-runtime jq ca-certificates
echo "[OK] Dependencies installed"

# Install x-ui fresh (no uninstall step)
bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh) <<< $'1\ny\n'
sleep 5
command -v x-ui >/dev/null 2>&1 || { echo "[FAIL] x-ui not found after install"; exit 1; }

# Set panel port
echo "[INFO] Setting panel port to ${PANEL_PORT}"
x-ui setting -p "${PANEL_PORT}" 2>/dev/null || echo "[WARN] x-ui setting -p failed"
x-ui restart >/dev/null 2>&1 || systemctl restart x-ui || true
sleep 4

# Get panel credentials
SETTINGS_RAW="$(x-ui settings 2>/dev/null || true)"
REAL_PORT="$(echo "${SETTINGS_RAW}" | grep -oP 'port: \K\d+' | head -n1 || true)"
PATH_URL="$(echo "${SETTINGS_RAW}" | grep -oP 'webBasePath: \K/\S+' | head -n1 || true)"
USER_NAME="$(echo "${SETTINGS_RAW}" | grep -oP 'username: \K\S+' | head -n1 || true)"
PASS_WORD="$(echo "${SETTINGS_RAW}" | grep -oP 'password: \K\S+' | head -n1 || true)"
IP="$(curl -4 -s ifconfig.me || hostname -I | awk '{print $1}')"
[[ -n "${REAL_PORT:-}" ]] || REAL_PORT="${PANEL_PORT}"

# Firewall — only ADD rules, do NOT reset UFW
echo "[INFO] Adding firewall rules (no reset — live sites protected)"
ufw allow "${REAL_PORT}"/tcp
ufw allow "${XRAY_PORT}"/tcp
ufw status verbose

clear
echo "========================================="
echo " XRAY PANEL INSTALL v2026-04-30"
echo " = Rooted by VladiMIR | AI ="
echo "========================================="
echo "SERVER:     ${NEWNAME}"
echo "PANEL PORT: ${REAL_PORT}"
echo "XRAY PORT:  ${XRAY_PORT}"
echo "-----------------------------------------"
echo "PANEL:"
echo "http://${IP}:${REAL_PORT}${PATH_URL:-/}"
echo "LOGIN: ${USER_NAME:-unknown}"
echo "PASS:  ${PASS_WORD:-unknown}"
echo "-----------------------------------------"
echo "README: https://github.com/GinCz/Linux_Server_Public/blob/main/XRAY/README.md"
echo "========================================="
echo
ufw status numbered
echo "========================================="
