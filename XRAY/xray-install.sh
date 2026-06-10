#!/bin/bash
# =============================================================
# Script:      xray-install.sh
# Version:     v2026.06.10
# Description: Clean install of 3x-ui (MHSanaei) on Ubuntu 24.
#              - Full wipe of old xray/x-ui
#              - Auto-generates login, password, panel port, path
#              - Sets credentials via x-ui CLI (proper bcrypt hash)
#              - Disables 2FA
#              - Opens 22, 443/tcp+udp, panel port in UFW
#              - Auto-detects AWS, shows SG reminder
#              - Shows final URL + credentials
# Usage:
#   bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/XRAY/xray-install.sh)
# = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =
# =============================================================
clear
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin

R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; W='\033[1;37m'; X='\033[0m'
SEP="${C}$(printf '═%.0s' {1..60})${X}"

echo -e "$SEP"
echo -e "  ${W}3x-ui INSTALLER  v2026.06.10${X}"
echo -e "  ${Y}= Rooted by VladiMIR + AI | github.com/GinCz =${X}"
echo -e "$SEP"
echo

# ── [1/7] CHECK ROOT ─────────────────────────────────────────
[[ $EUID -ne 0 ]] && echo -e "${R}ERROR: Run as root!${X}" && exit 1

# ── [2/7] FULL WIPE ──────────────────────────────────────────
echo -e "${Y}[2/7] Wiping old xray / x-ui...${X}"
systemctl stop xray x-ui 2>/dev/null
systemctl disable xray x-ui 2>/dev/null
killall xray x-ui 2>/dev/null
rm -rf /usr/local/x-ui /usr/local/xray /etc/xray /etc/x-ui
rm -f  /usr/bin/x-ui /etc/systemd/system/x-ui.service
systemctl daemon-reload
echo -e "${G}OK${X}"

# ── [3/7] DEPENDENCIES ───────────────────────────────────────
echo -e "${Y}[3/7] Dependencies...${X}"
apt-get update -y -q
apt-get install -y -q curl wget ufw socat sqlite3
echo -e "${G}OK${X}"

# ── [4/7] GENERATE CREDENTIALS ───────────────────────────────
echo -e "${Y}[4/7] Generating credentials...${X}"
NEW_USER="admin$(tr -dc 'a-z0-9' </dev/urandom | head -c5)"
NEW_PASS="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c10)-$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c8)"
NEW_PORT=$(shuf -i 10000-62000 -n1)
NEW_PATH="/$(tr -dc 'a-z0-9' </dev/urandom | head -c8)"
echo -e "  user=${W}${NEW_USER}${X}  port=${W}${NEW_PORT}${X}  path=${W}${NEW_PATH}${X}"
echo -e "${G}OK${X}"

# ── [5/7] INSTALL 3x-ui ──────────────────────────────────────
# Input: 1=SQLite, 4=Skip SSL
echo -e "${Y}[5/7] Installing 3x-ui...${X}"
bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh) <<< $'1\n4\n'
echo -e "${G}OK${X}"

# ── [6/7] CONFIGURE DB + CREDENTIALS ────────────────────────
echo -e "${Y}[6/7] Configuring credentials...${X}"
DB="/etc/x-ui/x-ui.db"

# Wait up to 40s for DB
for i in $(seq 1 20); do
    [ -f "$DB" ] && break
    echo -e "  waiting for DB... (${i}/20)"
    sleep 2
done
[ ! -f "$DB" ] && echo -e "${R}ERROR: DB not found!${X}" && exit 1

# Stop before writing
systemctl stop x-ui 2>/dev/null
sleep 2

# Port and path (plain values — not bcrypt)
sqlite3 "$DB" "DELETE FROM settings WHERE key IN ('webPort','webBasePath','twoFactorEnable');"
sqlite3 "$DB" "INSERT INTO settings(key,value) VALUES('webPort','${NEW_PORT}'),('webBasePath','${NEW_PATH}'),('twoFactorEnable','false');"

# Disable 2FA on user row if column exists
sqlite3 "$DB" "UPDATE users SET twoFactorEnable=0, twoFactorSecret='' WHERE id=1;" 2>/dev/null || true

# Start so x-ui CLI is available
systemctl start x-ui 2>/dev/null
sleep 4

! systemctl is-active --quiet x-ui && echo -e "${R}ERROR: x-ui failed to start!${X}" && exit 1

# Set credentials via CLI — this creates a proper bcrypt hash
/usr/local/x-ui/x-ui setting -username "${NEW_USER}" -password "${NEW_PASS}" \
  && echo -e "  ${G}Credentials set via CLI (bcrypt)${X}" \
  || echo -e "  ${Y}WARNING: CLI setting failed — login may not work${X}"

# Full restart to apply everything
systemctl restart x-ui
sleep 3

! systemctl is-active --quiet x-ui && echo -e "${R}ERROR: x-ui failed to restart!${X}" && exit 1
echo -e "${G}OK${X}"

# ── [7/7] FIREWALL ───────────────────────────────────────────
echo -e "${Y}[7/7] Configuring UFW...${X}"
ufw allow 22/tcp    comment 'SSH'
ufw allow 443/tcp   comment 'HTTPS/VPN'
ufw allow 443/udp   comment 'HTTPS/VPN UDP'
ufw allow "${NEW_PORT}"/tcp comment 'x-ui panel'
echo y | ufw --force enable
ufw reload
echo -e "${G}OK${X}"

# ── DETECT AWS ───────────────────────────────────────────────
IS_AWS=false
curl -s --max-time 2 http://169.254.169.254/latest/meta-data/instance-id >/dev/null 2>&1 && IS_AWS=true

# ── GET SERVER IP ─────────────────────────────────────────────
SERVER_IP=$(curl -s --max-time 5 ifconfig.me \
    || curl -s --max-time 5 icanhazip.com \
    || curl -s --max-time 5 api.ipify.org \
    || hostname -I | awk '{print $1}')

# ── FINAL OUTPUT ─────────────────────────────────────────────
clear
echo -e "$SEP"
echo -e "  ${G}✓ 3x-ui INSTALLED SUCCESSFULLY!${X}"
echo -e "$SEP"
echo
printf "  ${Y}%-14s${X} ${W}%s${X}\n" "SERVER IP:"  "${SERVER_IP}"
printf "  ${Y}%-14s${X} ${W}%s${X}\n" "PANEL URL:"  "http://${SERVER_IP}:${NEW_PORT}${NEW_PATH}"
printf "  ${Y}%-14s${X} ${W}%s${X}\n" "LOGIN:"      "${NEW_USER}"
printf "  ${Y}%-14s${X} ${W}%s${X}\n" "PASSWORD:"   "${NEW_PASS}"
printf "  ${Y}%-14s${X} ${W}%s${X}\n" "PORT:"       "${NEW_PORT}"
printf "  ${Y}%-14s${X} ${W}%s${X}\n" "PATH:"       "${NEW_PATH}"
echo
echo -e "  ${C}UFW: 22/tcp  443/tcp+udp  ${NEW_PORT}/tcp${X}"
echo -e "  ${C}2FA: disabled${X}"
echo -e "  ${C}x-ui: $(systemctl is-active x-ui 2>/dev/null)${X}"
echo
echo -e "  ${R}!! SAVE THESE CREDENTIALS NOW !!${X}"
echo -e "$SEP"

if $IS_AWS; then
    echo
    echo -e "  ${R}!! AWS: open port ${NEW_PORT}/tcp in Security Group !!${X}"
    echo -e "  ${C}https://console.aws.amazon.com/ec2/home#SecurityGroups${X}"
elif curl -s --max-time 2 http://169.254.169.254/hetzner 2>/dev/null | grep -qi hetzner; then
    echo -e "  ${Y}NOTE: Hetzner — open port ${NEW_PORT}/tcp in Firewall console${X}"
else
    echo -e "  ${Y}NOTE: If behind cloud firewall (IONOS, Hetzner, VScale...)${X}"
    echo -e "  ${Y}open port ${NEW_PORT}/tcp in provider firewall console.${X}"
fi

echo
echo -e "  ${W}= Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =${X}"
echo
