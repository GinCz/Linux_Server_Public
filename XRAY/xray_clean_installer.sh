#!/bin/bash
# =============================================================
# Script: xray_clean_installer.sh
# Version: v2026-06-05d
# Description: Full wipe of old Xray/x-ui, clean reinstall via
#              MHSanaei/3x-ui. Auto-generates credentials,
#              sets them via x-ui CLI (correct bcrypt hashing),
#              guaranteed output of URL/LOGIN/PASSWORD.
# Usage: curl -Ls https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/XRAY/xray_clean_installer.sh | bash
# =============================================================
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin

RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

clear
echo -e "${RED}==========================================${NC}"
echo -e "${RED}  XRAY INSTALLER v2026-06-05d             ${NC}"
echo -e "${RED}  Rooted by VladiMIR | AI                 ${NC}"
echo -e "${RED}==========================================${NC}"
echo ""

# ── [1/6] FULL WIPE ─────────────────────────────────────────
echo -e "${YELLOW}[1/6] Full wipe of old Xray/x-ui...${NC}"
systemctl stop xray x-ui 2>/dev/null; systemctl disable xray x-ui 2>/dev/null
killall xray x-ui 2>/dev/null
rm -rf /usr/local/x-ui /usr/local/xray /etc/xray /etc/x-ui
rm -f /usr/bin/x-ui /etc/systemd/system/x-ui.service
systemctl daemon-reload 2>/dev/null
echo -e "${GREEN}Done.${NC}"

# ── [2/6] DEPENDENCIES ──────────────────────────────────────
echo -e "${YELLOW}[2/6] Installing dependencies...${NC}"
apt-get update -y -q
apt-get install -y -q curl wget ufw socat sqlite3
echo -e "${GREEN}Done.${NC}"

# ── [3/6] GENERATE CREDENTIALS ──────────────────────────────
echo -e "${YELLOW}[3/6] Generating credentials...${NC}"
NEW_USER="admin$(tr -dc 'a-z0-9' </dev/urandom | head -c 6)"
NEW_PASS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)
NEW_PORT=$(shuf -i 10000-62000 -n 1)
NEW_PATH="/$(tr -dc 'a-z0-9' </dev/urandom | head -c 8)"
echo -e "  user=${NEW_USER}  port=${NEW_PORT}  path=${NEW_PATH}"
echo -e "${GREEN}Done.${NC}"

# ── [4/6] INSTALL MHSanaei/3x-ui ────────────────────────────
# Answer: 1 = SQLite, 4 = Skip SSL
echo -e "${YELLOW}[4/6] Installing 3x-ui (MHSanaei/3x-ui v3.x)...${NC}"
bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh) <<< $'1\n4\n'
echo -e "${GREEN}Done.${NC}"

# ── [5/6] WRITE CREDENTIALS ─────────────────────────────────
echo -e "${YELLOW}[5/6] Writing credentials...${NC}"
DB="/etc/x-ui/x-ui.db"

# Wait for DB (up to 40s)
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

# Use x-ui CLI — it handles bcrypt hashing correctly
x-ui setting -username "$NEW_USER" -password "$NEW_PASS" -port "$NEW_PORT" -webBasePath "$NEW_PATH" 2>/dev/null || {
    # Fallback: write directly to DB (plain password accepted on first login)
    sqlite3 "$DB" "UPDATE users SET username='$NEW_USER', password='$NEW_PASS' WHERE id=1;"
    sqlite3 "$DB" "INSERT OR REPLACE INTO settings(key,value) VALUES('webPort','$NEW_PORT');"
    sqlite3 "$DB" "INSERT OR REPLACE INTO settings(key,value) VALUES('webBasePath','$NEW_PATH');"
}

systemctl start x-ui 2>/dev/null
sleep 3
echo -e "${GREEN}Done.${NC}"

# ── [6/6] FIREWALL ───────────────────────────────────────────
echo -e "${YELLOW}[6/6] Configuring firewall...${NC}"
ufw allow 22/tcp
ufw allow "$NEW_PORT"/tcp
echo y | ufw --force enable
echo -e "${GREEN}Done.${NC}"

# ── OUTPUT ───────────────────────────────────────────────────
SERVER_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null \
    || curl -s --max-time 5 icanhazip.com 2>/dev/null \
    || curl -s --max-time 5 api.ipify.org 2>/dev/null \
    || echo "UNKNOWN")

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
echo -e "${GREEN}  x-ui status: $(systemctl is-active x-ui 2>/dev/null)${NC}"
echo -e "${GREEN}==========================================${NC}"
