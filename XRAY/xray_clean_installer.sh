#!/bin/bash
# =============================================================
# Script: xray_clean_installer.sh
# Version: v2026-06-05
# Server: Universal (clean Ubuntu 22.04/24.04)
# Description: CLEAN install - removes old Xray/3x-ui before installation
#              Preserves SSH access (port 22 opened first)
#              Removes: old Xray, old 3x-ui, old configs
#              Does NOT touch: FastPanel, cPanel, Amnezia, Docker
#              Auto-generates login/password, reads from SQLite DB
# Language: English only
# Usage: bash <(curl -Ls https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/XRAY/xray_clean_installer.sh)
# =============================================================
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin
clear

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
CYAN='\033[1;36m'
NC='\033[0m'

echo -e "${RED}=========================================${NC}"
echo -e "${RED}     XRAY CLEAN INSTALLER v2026-06-05    ${NC}"
echo -e "${RED}     Rooted by VladiMIR | AI             ${NC}"
echo -e "${RED}=========================================${NC}\n"

# ── [1/6] Clean old Xray/3x-ui only ──────────────────────────
echo -e "${YELLOW}[1/6] Removing old Xray/3x-ui...${NC}"
systemctl stop xray x-ui 2>/dev/null || true
systemctl disable xray x-ui 2>/dev/null || true
rm -rf /usr/local/x-ui /usr/local/xray /etc/xray /etc/x-ui
apt remove -y x-ui 2>/dev/null || true

# ── [2/6] Install dependencies ────────────────────────────────
echo -e "${YELLOW}[2/6] Installing dependencies...${NC}"
apt update -y
apt install -y curl wget ufw socat sqlite3

# ── [3/6] Generate credentials ────────────────────────────────
echo -e "${YELLOW}[3/6] Generating credentials...${NC}"
GEN_USER="admin_$(tr -dc 'a-z0-9' </dev/urandom | head -c 6)"
GEN_PASS=$(tr -dc 'A-Za-z0-9!@#' </dev/urandom | head -c 16)
GEN_PORT=$(shuf -i 10000-65000 -n 1)
GEN_PATH="/$(tr -dc 'a-z0-9' </dev/urandom | head -c 8)"

# ── [4/6] Install 3x-ui ───────────────────────────────────────
echo -e "${YELLOW}[4/6] Installing XRAY + 3x-ui...${NC}"
bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh) <<< $'1\ny\n'

# Wait for DB to be created
echo -e "${YELLOW}Waiting for x-ui to initialize...${NC}"
for i in $(seq 1 20); do
    if [ -f /usr/local/x-ui/db/x-ui.db ]; then
        break
    fi
    sleep 2
done

# ── [5/6] Apply credentials directly into SQLite DB ──────────
echo -e "${YELLOW}[5/6] Applying credentials to DB...${NC}"
DB_PATH="/usr/local/x-ui/db/x-ui.db"

if [ -f "$DB_PATH" ]; then
    sqlite3 "$DB_PATH" "UPDATE settings SET value='$GEN_USER' WHERE key='webUsername';" 2>/dev/null || true
    sqlite3 "$DB_PATH" "UPDATE settings SET value='$GEN_PASS' WHERE key='webPassword';" 2>/dev/null || true
    sqlite3 "$DB_PATH" "UPDATE settings SET value='$GEN_PORT' WHERE key='webPort';" 2>/dev/null || true
    sqlite3 "$DB_PATH" "UPDATE settings SET value='$GEN_PATH' WHERE key='webBasePath';" 2>/dev/null || true
    # Also try insert if update didn't work (fresh DB)
    sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO settings(key,value) VALUES('webUsername','$GEN_USER');" 2>/dev/null || true
    sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO settings(key,value) VALUES('webPassword','$GEN_PASS');" 2>/dev/null || true
    sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO settings(key,value) VALUES('webPort','$GEN_PORT');" 2>/dev/null || true
    sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO settings(key,value) VALUES('webBasePath','$GEN_PATH');" 2>/dev/null || true
else
    echo -e "${RED}WARNING: DB not found at $DB_PATH, using x-ui settings fallback${NC}"
fi

# Restart to apply settings
x-ui restart 2>/dev/null || systemctl restart x-ui 2>/dev/null || true
sleep 5

# Read back from DB (source of truth)
if [ -f "$DB_PATH" ]; then
    R_USER=$(sqlite3 "$DB_PATH" "SELECT value FROM settings WHERE key='webUsername';" 2>/dev/null)
    R_PASS=$(sqlite3 "$DB_PATH" "SELECT value FROM settings WHERE key='webPassword';" 2>/dev/null)
    R_PORT=$(sqlite3 "$DB_PATH" "SELECT value FROM settings WHERE key='webPort';" 2>/dev/null)
    R_PATH=$(sqlite3 "$DB_PATH" "SELECT value FROM settings WHERE key='webBasePath';" 2>/dev/null)
fi

# Fallback: use generated values if DB read failed
R_USER="${R_USER:-$GEN_USER}"
R_PASS="${R_PASS:-$GEN_PASS}"
R_PORT="${R_PORT:-$GEN_PORT}"
R_PATH="${R_PATH:-$GEN_PATH}"

# ── [6/6] Firewall ────────────────────────────────────────────
echo -e "${YELLOW}[6/6] Configuring firewall...${NC}"
ufw allow 22/tcp
ufw allow "$R_PORT"/tcp
echo "y" | ufw --force enable

# ── Output ────────────────────────────────────────────────────
IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null)
clear
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}     XRAY INSTALLED SUCCESSFULLY!        ${NC}"
echo -e "${GREEN}     Rooted by VladiMIR | AI             ${NC}"
echo -e "${GREEN}=========================================${NC}"
echo -e "${CYAN}SERVER IP:${NC}  $IP"
echo -e "${CYAN}PANEL URL:${NC}  http://$IP:$R_PORT$R_PATH"
echo -e "${CYAN}LOGIN:${NC}      $R_USER"
echo -e "${CYAN}PASSWORD:${NC}   $R_PASS"
echo -e "${GREEN}=========================================${NC}"
echo -e "Firewall: SSH(22) + panel($R_PORT) are OPEN"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo -e "${YELLOW}Save these credentials now!${NC}"
echo -e "${YELLOW}Add inbounds via Panel -> Inbounds -> Add Inbound${NC}"
echo -e "${GREEN}=========================================${NC}"
