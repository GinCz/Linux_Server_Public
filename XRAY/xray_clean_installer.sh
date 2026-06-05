#!/bin/bash
# =============================================================
# Script: xray_clean_installer.sh
# Version: v2026-06-05g
# Description: Full wipe of old Xray/x-ui, clean reinstall via
#              MHSanaei/3x-ui. Auto-generates credentials,
#              sets them via DELETE+INSERT into SQLite DB.
#              Auto-opens 443/tcp+udp, 8443, panel port in UFW.
#              Prints AWS Security Group reminder at the end.
# Usage: curl -Ls https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/XRAY/xray_clean_installer.sh | bash
# =============================================================
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin

RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'

clear
echo -e "${RED}==========================================${NC}"
echo -e "${RED}  XRAY INSTALLER v2026-06-05g             ${NC}"
echo -e "${RED}  Rooted by VladiMIR | AI                 ${NC}"
echo -e "${RED}==========================================${NC}"
echo ""

# ── [1/6] FULL WIPE ──────────────────────────────────────────
echo -e "${YELLOW}[1/6] Full wipe of old Xray/x-ui...${NC}"
systemctl stop xray x-ui 2>/dev/null; systemctl disable xray x-ui 2>/dev/null
killall xray x-ui 2>/dev/null
rm -rf /usr/local/x-ui /usr/local/xray /etc/xray /etc/x-ui
rm -f /usr/bin/x-ui /etc/systemd/system/x-ui.service
systemctl daemon-reload 2>/dev/null
echo -e "${GREEN}Done.${NC}"

# ── [2/6] DEPENDENCIES ───────────────────────────────────────
echo -e "${YELLOW}[2/6] Installing dependencies...${NC}"
apt-get update -y -q
apt-get install -y -q curl wget ufw socat sqlite3
echo -e "${GREEN}Done.${NC}"

# ── [3/6] GENERATE CREDENTIALS ───────────────────────────────
echo -e "${YELLOW}[3/6] Generating credentials...${NC}"
NEW_USER="admin$(tr -dc 'a-z0-9' </dev/urandom | head -c 6)"
NEW_PASS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)
NEW_PORT=$(shuf -i 10000-62000 -n 1)
NEW_PATH="/$(tr -dc 'a-z0-9' </dev/urandom | head -c 8)"
echo -e "  user=${NEW_USER}  port=${NEW_PORT}  path=${NEW_PATH}"
echo -e "${GREEN}Done.${NC}"

# ── [4/6] INSTALL MHSanaei/3x-ui ─────────────────────────────
# Answer: 1 = SQLite, 4 = Skip SSL
echo -e "${YELLOW}[4/6] Installing 3x-ui (MHSanaei/3x-ui v3.x)...${NC}"
bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh) <<< $'1\n4\n'
echo -e "${GREEN}Done.${NC}"

# ── [5/6] WRITE CREDENTIALS ──────────────────────────────────
echo -e "${YELLOW}[5/6] Writing credentials...${NC}"
DB="/etc/x-ui/x-ui.db"

for i in $(seq 1 20); do
    [ -f "$DB" ] && break
    sleep 2
done

if [ ! -f "$DB" ]; then
    echo -e "${RED}ERROR: DB not found at $DB${NC}"
    exit 1
fi

systemctl stop x-ui 2>/dev/null
sleep 1

# DELETE + INSERT — avoids duplicate rows (INSERT OR REPLACE creates
# new rows if key is not a true PRIMARY KEY in the settings table)
sqlite3 "$DB" "UPDATE users SET username='$NEW_USER', password='$NEW_PASS' WHERE id=1;"
sqlite3 "$DB" "DELETE FROM settings WHERE key='webPort';"
sqlite3 "$DB" "DELETE FROM settings WHERE key='webBasePath';"
sqlite3 "$DB" "INSERT INTO settings(key,value) VALUES('webPort','$NEW_PORT');"
sqlite3 "$DB" "INSERT INTO settings(key,value) VALUES('webBasePath','$NEW_PATH');"

SAVED_PORT=$(sqlite3 "$DB" "SELECT value FROM settings WHERE key='webPort' LIMIT 1;")
SAVED_PATH=$(sqlite3 "$DB" "SELECT value FROM settings WHERE key='webBasePath' LIMIT 1;")
echo -e "  DB verified: port=${SAVED_PORT}  path=${SAVED_PATH}"

systemctl start x-ui 2>/dev/null
sleep 3
echo -e "${GREEN}Done.${NC}"

# ── [6/6] FIREWALL ───────────────────────────────────────────
echo -e "${YELLOW}[6/6] Configuring UFW firewall...${NC}"
ufw allow 22/tcp
ufw allow 443/tcp
ufw allow 443/udp
ufw allow 8443/tcp
ufw allow "$NEW_PORT"/tcp
echo y | ufw --force enable
ufw reload
echo -e "${GREEN}Done.${NC}"

# ── OUTPUT ───────────────────────────────────────────────────
SERVER_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null \
    || curl -s --max-time 5 icanhazip.com 2>/dev/null \
    || curl -s --max-time 5 api.ipify.org 2>/dev/null \
    || echo "UNKNOWN")

# Detect if running on AWS (check instance metadata)
IS_AWS=false
if curl -s --max-time 2 http://169.254.169.254/latest/meta-data/instance-id >/dev/null 2>&1; then
    IS_AWS=true
fi

clear
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  XRAY INSTALLED SUCCESSFULLY!            ${NC}"
echo -e "${GREEN}  Rooted by VladiMIR | AI                 ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
printf "  %-12s %s\n" "SERVER IP:"  "$SERVER_IP"
printf "  %-12s %s\n" "PANEL URL:"  "http://$SERVER_IP:$NEW_PORT$NEW_PATH"
printf "  %-12s %s\n" "LOGIN:"      "$NEW_USER"
printf "  %-12s %s\n" "PASSWORD:"   "$NEW_PASS"
echo ""
echo -e "${YELLOW}  !! Save these credentials NOW !!${NC}"
echo ""
echo -e "${GREEN}  UFW ports open: 22, 443/tcp+udp, 8443, $NEW_PORT${NC}"
echo -e "${GREEN}  x-ui status:    $(systemctl is-active x-ui 2>/dev/null)${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

if $IS_AWS; then
    echo -e "${RED}  !! AWS SECURITY GROUP — MANUAL STEP REQUIRED !!${NC}"
    echo ""
    echo -e "${YELLOW}  UFW is open on the server, but AWS Security Group${NC}"
    echo -e "${YELLOW}  is an external firewall — it CANNOT be changed${NC}"
    echo -e "${YELLOW}  from inside the server. You must open the port${NC}"
    echo -e "${YELLOW}  manually in the AWS Console:${NC}"
    echo ""
    printf "  %-14s %s\n" "Port to open:" "$NEW_PORT (TCP)"
    printf "  %-14s %s\n" "Source:"       "0.0.0.0/0"
    echo ""
    echo -e "  ${CYAN}Direct link to EC2 Security Groups:${NC}"
    echo -e "  ${CYAN}https://console.aws.amazon.com/ec2/home#SecurityGroups${NC}"
    echo ""
    echo -e "  Steps:"
    echo -e "  1. Open the link above"
    echo -e "  2. Select your Security Group → Edit inbound rules"
    echo -e "  3. Add Rule → Custom TCP → Port ${NEW_PORT} → Source 0.0.0.0/0"
    echo -e "  4. Save rules"
    echo -e "  5. Open: http://${SERVER_IP}:${NEW_PORT}${NEW_PATH}"
else
    echo -e "${YELLOW}  NOTE: If behind a cloud firewall (Hetzner, AWS, etc.)${NC}"
    echo -e "${YELLOW}  open port ${NEW_PORT}/tcp in your provider's firewall console.${NC}"
fi

echo ""
echo -e "${GREEN}==========================================${NC}"
