#!/bin/bash
# =============================================================
# Script:      xray-install.sh
# Version:     v2026.06.09
# Description: Clean install of 3x-ui (MHSanaei) on Ubuntu 24.
#              - Full wipe of old xray/x-ui
#              - Auto-generates login, password, panel port, path
#              - Writes credentials directly into SQLite DB
#              - Opens 22, 443/tcp+udp, 8443, panel port in UFW
#              - Auto-detects AWS and shows SG reminder
#              - Shows final URL + credentials
# Usage:
#   bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/XRAY/xray-install.sh)
# = Rooted by VladiMIR + AI | v.2026.06.09 | github.com/GinCz =
# =============================================================
clear
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin

R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; W='\033[1;37m'; X='\033[0m'
SEP="${C}$(printf '═%.0s' {1..60})${X}"

echo -e "$SEP"
echo -e "  ${W}3x-ui INSTALLER  v2026.06.09${X}"
echo -e "  ${Y}= Rooted by VladiMIR + AI | github.com/GinCz =${X}"
echo -e "$SEP"
echo

# ── [1/7] CHECK ROOT ─────────────────────────────────────────
[[ $EUID -ne 0 ]] && echo -e "${R}ERROR: Run as root!${X}" && exit 1

# ── [2/7] FULL WIPE OF OLD XRAY/X-UI ────────────────────────
echo -e "${Y}[2/7] Wiping old xray / x-ui...${X}"
systemctl stop xray x-ui 2>/dev/null
systemctl disable xray x-ui 2>/dev/null
killall xray x-ui 2>/dev/null
rm -rf /usr/local/x-ui /usr/local/xray /etc/xray /etc/x-ui
rm -f  /usr/bin/x-ui /etc/systemd/system/x-ui.service
systemctl daemon-reload 2>/dev/null
echo -e "${G}OK${X}"

# ── [3/7] DEPENDENCIES ───────────────────────────────────────
echo -e "${Y}[3/7] Installing dependencies...${X}"
apt-get update -y -q
apt-get install -y -q curl wget ufw socat sqlite3
echo -e "${G}OK${X}"

# ── [4/7] GENERATE CREDENTIALS ───────────────────────────────
echo -e "${Y}[4/7] Generating credentials...${X}"
NEW_USER="admin$(tr -dc 'a-z0-9' </dev/urandom | head -c6)"
NEW_PASS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c18)
NEW_PORT=$(shuf -i 10000-62000 -n1)
NEW_PATH="/$(tr -dc 'a-z0-9' </dev/urandom | head -c8)"
echo -e "  user=${W}${NEW_USER}${X}  port=${W}${NEW_PORT}${X}  path=${W}${NEW_PATH}${X}"
echo -e "${G}OK${X}"

# ── [5/7] INSTALL 3x-ui ──────────────────────────────────────
# Answers: 1=SQLite, 4=Skip SSL cert setup
echo -e "${Y}[5/7] Installing 3x-ui (MHSanaei)...${X}"
bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh) <<< $'1\n4\n'
echo -e "${G}OK${X}"

# ── [6/7] WRITE CREDENTIALS INTO DB ─────────────────────────
echo -e "${Y}[6/7] Writing credentials into DB...${X}"
DB="/etc/x-ui/x-ui.db"

# Wait up to 40s for DB to appear
for i in $(seq 1 20); do
    [ -f "$DB" ] && break
    echo -e "  waiting for DB... (${i}/20)"
    sleep 2
done

if [ ! -f "$DB" ]; then
    echo -e "${R}ERROR: DB not found at ${DB}${X}"
    echo -e "${R}Possible cause: 3x-ui installer failed or DB path changed.${X}"
    echo -e "${Y}Check: ls /etc/x-ui/ and x-ui status${X}"
    exit 1
fi

systemctl stop x-ui 2>/dev/null
sleep 2

sqlite3 "$DB" "UPDATE users SET username='${NEW_USER}', password='${NEW_PASS}' WHERE id=1;"
sqlite3 "$DB" "DELETE FROM settings WHERE key='webPort';"
sqlite3 "$DB" "DELETE FROM settings WHERE key='webBasePath';"
sqlite3 "$DB" "INSERT INTO settings(key,value) VALUES('webPort','${NEW_PORT}');"
sqlite3 "$DB" "INSERT INTO settings(key,value) VALUES('webBasePath','${NEW_PATH}');"

# Verify
SAVED_PORT=$(sqlite3 "$DB" "SELECT value FROM settings WHERE key='webPort' LIMIT 1;")
SAVED_PATH=$(sqlite3 "$DB" "SELECT value FROM settings WHERE key='webBasePath' LIMIT 1;")
SAVED_USER=$(sqlite3 "$DB" "SELECT username FROM users WHERE id=1 LIMIT 1;")

if [[ "$SAVED_PORT" != "$NEW_PORT" ]] || [[ "$SAVED_PATH" != "$NEW_PATH" ]] || [[ "$SAVED_USER" != "$NEW_USER" ]]; then
    echo -e "${R}ERROR: DB verify failed!${X}"
    echo -e "  expected port=${NEW_PORT} got=${SAVED_PORT}"
    echo -e "  expected path=${NEW_PATH} got=${SAVED_PATH}"
    echo -e "  expected user=${NEW_USER} got=${SAVED_USER}"
    exit 1
fi

systemctl start x-ui 2>/dev/null
sleep 3

# Check service started
if ! systemctl is-active --quiet x-ui; then
    echo -e "${R}ERROR: x-ui failed to start!${X}"
    echo -e "${Y}Check logs: journalctl -u x-ui -n 50${X}"
    exit 1
fi

echo -e "  DB verified: port=${W}${SAVED_PORT}${X}  path=${W}${SAVED_PATH}${X}  user=${W}${SAVED_USER}${X}"
echo -e "${G}OK${X}"

# ── [7/7] FIREWALL (UFW) ─────────────────────────────────────
echo -e "${Y}[7/7] Configuring UFW...${X}"
ufw allow 22/tcp
ufw allow 443/tcp
ufw allow 443/udp
ufw allow 8443/tcp
ufw allow "${NEW_PORT}"/tcp
echo y | ufw --force enable
ufw reload
echo -e "${G}OK${X}"

# ── DETECT AWS ───────────────────────────────────────────────
IS_AWS=false
curl -s --max-time 2 http://169.254.169.254/latest/meta-data/instance-id >/dev/null 2>&1 && IS_AWS=true

# ── GET SERVER IP ─────────────────────────────────────────────
SERVER_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null \
    || curl -s --max-time 5 icanhazip.com 2>/dev/null \
    || curl -s --max-time 5 api.ipify.org 2>/dev/null \
    || hostname -I | awk '{print $1}')

# ── FINAL OUTPUT ─────────────────────────────────────────────
clear
echo -e "$SEP"
echo -e "  ${G}✓ 3x-ui INSTALLED SUCCESSFULLY!${X}"
echo -e "$SEP"
echo
printf "  ${Y}%-14s${X} ${W}%s${X}\n" "SERVER IP:"  "$SERVER_IP"
printf "  ${Y}%-14s${X} ${W}%s${X}\n" "PANEL URL:"  "http://${SERVER_IP}:${NEW_PORT}${NEW_PATH}"
printf "  ${Y}%-14s${X} ${W}%s${X}\n" "LOGIN:"      "$NEW_USER"
printf "  ${Y}%-14s${X} ${W}%s${X}\n" "PASSWORD:"   "$NEW_PASS"
printf "  ${Y}%-14s${X} ${W}%s${X}\n" "PORT:"       "$NEW_PORT"
printf "  ${Y}%-14s${X} ${W}%s${X}\n" "PATH:"       "$NEW_PATH"
echo
echo -e "  ${R}!! SAVE THESE CREDENTIALS NOW !!${X}"
echo
echo -e "  ${G}UFW ports open:  22, 443/tcp+udp, 8443, ${NEW_PORT}/tcp${X}"
echo -e "  ${G}x-ui status:     $(systemctl is-active x-ui 2>/dev/null || echo unknown)${X}"
echo -e "$SEP"

if $IS_AWS; then
    echo
    echo -e "  ${R}!! AWS SECURITY GROUP — MANUAL STEP REQUIRED !!${X}"
    echo -e "  ${Y}UFW is open on the OS, but AWS Security Group is${X}"
    echo -e "  ${Y}an EXTERNAL firewall — must be opened manually.${X}"
    echo
    printf "  ${Y}%-14s${X} ${W}%s${X}\n" "Port to open:" "${NEW_PORT} (TCP)"
    printf "  ${Y}%-14s${X} ${W}%s${X}\n" "Source:"       "0.0.0.0/0"
    echo
    echo -e "  ${C}https://console.aws.amazon.com/ec2/home#SecurityGroups${X}"
else
    echo
    echo -e "  ${Y}NOTE: If behind cloud firewall (Hetzner, VScale, etc.)${X}"
    echo -e "  ${Y}open port ${NEW_PORT}/tcp in provider's firewall console.${X}"
fi

echo
echo -e "  ${W}= Rooted by VladiMIR + AI | v.2026.06.09 | github.com/GinCz =${X}"
echo
