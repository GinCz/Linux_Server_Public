#!/bin/bash
# =============================================================
# Script: xray_clean_installer.sh
# Version: v2026-06-05c
# Description: Full wipe of old Xray/x-ui, clean reinstall via
#              MHSanaei/3x-ui (alireza0 is banned on GitHub).
#              Auto-generates credentials, reads from SQLite DB,
#              guaranteed output of URL/LOGIN/PASSWORD.
# Usage: curl -Ls https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/XRAY/xray_clean_installer.sh | bash
# =============================================================
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

clear
echo -e "${RED}==========================================${NC}"
echo -e "${RED}  XRAY CLEAN INSTALLER v2026-06-05c      ${NC}"
echo -e "${RED}  Rooted by VladiMIR | AI                ${NC}"
echo -e "${RED}==========================================${NC}"
echo ""

# ── [1/7] FULL WIPE ────────────────────────────────────────────
echo -e "${YELLOW}[1/7] Full wipe of old Xray/x-ui...${NC}"
systemctl stop xray x-ui 2>/dev/null || true
systemctl disable xray x-ui 2>/dev/null || true
killall xray x-ui 2>/dev/null || true
rm -rf /usr/local/x-ui
rm -rf /usr/local/xray
rm -rf /etc/xray
rm -rf /etc/x-ui
rm -f  /usr/bin/x-ui
rm -f  /etc/systemd/system/x-ui.service
systemctl daemon-reload 2>/dev/null || true
echo -e "${GREEN}Done.${NC}"

# ── [2/7] DEPENDENCIES ─────────────────────────────────────────
echo -e "${YELLOW}[2/7] Installing dependencies...${NC}"
apt-get update -y -q
apt-get install -y -q curl wget ufw socat sqlite3
echo -e "${GREEN}Done.${NC}"

# ── [3/7] GENERATE CREDENTIALS ─────────────────────────────────
echo -e "${YELLOW}[3/7] Generating credentials...${NC}"
NEW_USER="admin$(tr -dc 'a-z0-9' </dev/urandom 2>/dev/null | head -c 5)"
NEW_PASS=$(tr -dc 'A-Za-z0-9' </dev/urandom 2>/dev/null | head -c 16)
NEW_PORT=$(shuf -i 10000-62000 -n 1)
NEW_PATH="/$(tr -dc 'a-z0-9' </dev/urandom 2>/dev/null | head -c 8)"
echo -e "  user=$NEW_USER  port=$NEW_PORT  path=$NEW_PATH"
echo -e "${GREEN}Done.${NC}"

# ── [4/7] INSTALL MHSanaei/3x-ui ────────────────────────────────
echo -e "${YELLOW}[4/7] Installing XRAY + 3x-ui (MHSanaei)...${NC}"
bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh) <<< $'\n'
echo -e "${GREEN}Done.${NC}"

# ── [5/7] WAIT FOR DB ──────────────────────────────────────────
echo -e "${YELLOW}[5/7] Waiting for x-ui database...${NC}"
DB_PATH=""
for i in $(seq 1 30); do
    for candidate in \
        /etc/x-ui/x-ui.db \
        /usr/local/x-ui/db/x-ui.db \
        /usr/local/x-ui/x-ui.db; do
        if [ -f "$candidate" ]; then
            DB_PATH="$candidate"
            break 2
        fi
    done
    sleep 2
done

if [ -z "$DB_PATH" ]; then
    echo -e "${RED}ERROR: x-ui database not found after 60s!${NC}"
    echo -e "${RED}Check: systemctl status x-ui${NC}"
    # Still print generated credentials so they're not lost
    SERVER_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "UNKNOWN")
    echo ""
    echo -e "${YELLOW}Generated credentials (panel settings may differ):${NC}"
    printf "  %-12s %s\n" "SERVER IP:" "$SERVER_IP"
    printf "  %-12s %s\n" "PANEL URL:" "http://$SERVER_IP:$NEW_PORT$NEW_PATH"
    printf "  %-12s %s\n" "LOGIN:"     "$NEW_USER"
    printf "  %-12s %s\n" "PASSWORD:"  "$NEW_PASS"
    exit 1
fi
echo -e "  DB found: $DB_PATH"
echo -e "${GREEN}Done.${NC}"

# ── [6/7] WRITE CREDENTIALS TO DB ──────────────────────────────
echo -e "${YELLOW}[6/7] Writing credentials to DB...${NC}"

# Stop panel before writing
systemctl stop x-ui 2>/dev/null || true
sleep 1

sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO settings(key,value) VALUES('webUsername','$NEW_USER');"
sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO settings(key,value) VALUES('webPassword','$NEW_PASS');"
sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO settings(key,value) VALUES('webPort','$NEW_PORT');"
sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO settings(key,value) VALUES('webBasePath','$NEW_PATH');"

# Restart panel
systemctl start x-ui 2>/dev/null || true
sleep 4

# Read back to verify
R_USER=$(sqlite3 "$DB_PATH" "SELECT value FROM settings WHERE key='webUsername';" 2>/dev/null)
R_PASS=$(sqlite3 "$DB_PATH" "SELECT value FROM settings WHERE key='webPassword';" 2>/dev/null)
R_PORT=$(sqlite3 "$DB_PATH" "SELECT value FROM settings WHERE key='webPort';" 2>/dev/null)
R_PATH=$(sqlite3 "$DB_PATH" "SELECT value FROM settings WHERE key='webBasePath';" 2>/dev/null)

# Fallback to generated if DB read empty
R_USER="${R_USER:-$NEW_USER}"
R_PASS="${R_PASS:-$NEW_PASS}"
R_PORT="${R_PORT:-$NEW_PORT}"
R_PATH="${R_PATH:-$NEW_PATH}"

echo -e "${GREEN}Done.${NC}"

# ── [7/7] FIREWALL ─────────────────────────────────────────────
echo -e "${YELLOW}[7/7] Configuring firewall...${NC}"
ufw allow 22/tcp
ufw allow "$R_PORT"/tcp
echo y | ufw --force enable
echo -e "${GREEN}Done.${NC}"

# ── OUTPUT ─────────────────────────────────────────────────────
SERVER_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null \
    || curl -s --max-time 5 icanhazip.com 2>/dev/null \
    || curl -s --max-time 5 api.ipify.org 2>/dev/null \
    || echo "UNKNOWN")

clear
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  XRAY INSTALLED SUCCESSFULLY!           ${NC}"
echo -e "${GREEN}  Rooted by VladiMIR | AI                ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
printf "  %-12s %s\n" "SERVER IP:"  "$SERVER_IP"
printf "  %-12s %s\n" "PANEL URL:"  "http://$SERVER_IP:$R_PORT$R_PATH"
printf "  %-12s %s\n" "LOGIN:"      "$R_USER"
printf "  %-12s %s\n" "PASSWORD:"   "$R_PASS"
echo ""
echo -e "${YELLOW}  !! Save these credentials NOW !!${NC}"
echo ""
echo -e "${GREEN}  Firewall: SSH(22) + panel($R_PORT) OPEN${NC}"
echo -e "${GREEN}  x-ui status: $(systemctl is-active x-ui 2>/dev/null)${NC}"
echo -e "${GREEN}==========================================${NC}"
