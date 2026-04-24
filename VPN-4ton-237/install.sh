#!/bin/bash
# =============================================================================
# install.sh — Full Xray 3X-UI installer for VPN-4ton-237
# =============================================================================
# Version  : v2026-04-24
# Author   : Ing. VladiMIR Bulantsev
# GitHub   : https://github.com/GinCz/Linux_Server_Public
# Server   : 144.124.228.237 / vpn-4ton-237 / FastVDS.ru
# Usage    : bash install.sh
#            OR: bash <(curl -s https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/VPN-4ton-237/install.sh)
# = Rooted by VladiMIR | AI =
# =============================================================================

clear

G='\033[1;32m'; C='\033[1;36m'; Y='\033[1;33m'; R='\033[1;31m'; M='\033[1;35m'; X='\033[0m'

echo -e "${Y}========================================${X}"
echo -e "${C} Xray 3X-UI Full Installer v2026-04-24${X}"
echo -e "${C} = Rooted by VladiMIR | AI =          ${X}"
echo -e "${Y}========================================${X}"
echo ""

# --- Guard: must be root ---
if [ "$(id -u)" != "0" ]; then
  echo -e "${R}[ERROR] Run as root!${X}"; exit 1
fi

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
TZ="Europe/Prague"
HOSTNAME_NEW="vpn-4ton-237"
GITHUB_REPO="https://github.com/GinCz/Linux_Server_Public.git"
REPO_DIR="/root/Linux_Server_Public"
BACKUP_DIR="/root/backups/xray"
DB="/etc/x-ui/x-ui.db"

echo -e "${C}Server IP  : ${G}$SERVER_IP${X}"
echo -e "${C}Hostname   : ${G}$HOSTNAME_NEW${X}"
echo ""

# =============================================================================
# STEP 0: Ask credentials interactively
# =============================================================================
echo -e "${Y}--- Panel credentials (leave empty = use defaults) ---${X}"
read -rp "Panel username  [default: vlad]   : " XUI_USER
XUI_USER=${XUI_USER:-vlad}

read -rsp "Panel password  [default: Gin-79513] : " XUI_PASS
echo ""
XUI_PASS=${XUI_PASS:-Gin-79513}

read -rp "Panel port      [default: 54321]  : " XUI_PORT
XUI_PORT=${XUI_PORT:-54321}

echo ""
echo -e "${G}[OK] Using: $XUI_USER / [hidden] / port $XUI_PORT${X}"
echo ""

# =============================================================================
# STEP 1: System
# =============================================================================
echo -e "${Y}[1/8] System update & packages...${X}"
apt update -qq && apt upgrade -y -qq
apt install -y curl wget nano ufw mc htop git sqlite3 openssl cron jq net-tools
timedatectl set-timezone $TZ
hostnamectl set-hostname $HOSTNAME_NEW
echo -e "${G}[OK] System ready | TZ: $TZ | Hostname: $HOSTNAME_NEW${X}"

# =============================================================================
# STEP 2: UFW Firewall
# =============================================================================
echo -e "${Y}[2/8] Firewall setup...${X}"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow "${XUI_PORT}/tcp"
ufw --force enable
echo -e "${G}[OK] UFW active: 22, 80, 443, $XUI_PORT${X}"

# =============================================================================
# STEP 3: Clone GitHub repo
# =============================================================================
echo -e "${Y}[3/8] Cloning GitHub repo...${X}"
if [ -d "$REPO_DIR/.git" ]; then
  cd "$REPO_DIR" && git pull --rebase
  echo -e "${G}[OK] Repo updated${X}"
else
  git clone "$GITHUB_REPO" "$REPO_DIR"
  echo -e "${G}[OK] Repo cloned to $REPO_DIR${X}"
fi

# =============================================================================
# STEP 4: Deploy .bashrc with all VPN aliases + x-ui aliases
# =============================================================================
echo -e "${Y}[4/8] Deploying .bashrc...${X}"
cp /root/.bashrc /root/.bashrc.bak.$(date +%Y%m%d) 2>/dev/null || true
cp "$REPO_DIR/VPN/.bashrc" /root/.bashrc

cat >> /root/.bashrc << 'XUITAIL'

# =============================================================================
# X-UI / XRAY ALIASES — v2026-04-24
# = Rooted by VladiMIR | AI =
# =============================================================================
alias xui='x-ui'
alias xuistart='x-ui start'
alias xuistop='x-ui stop'
alias xuirestart='x-ui restart'
alias xuistatus='x-ui status'
alias xuibackup='cp /etc/x-ui/x-ui.db /root/backups/xray/x-ui_$(date +%Y-%m-%d_%H%M).db && echo "[OK] Backup saved"'
alias xuiusers='sqlite3 /etc/x-ui/x-ui.db "SELECT id,remark,protocol,port,enable FROM inbounds;"'
alias xuiurl='echo "Panel: https://$(curl -s ifconfig.me):$(sqlite3 /etc/x-ui/x-ui.db \"SELECT value FROM settings WHERE key=\"\"port\"\";\")/$(sqlite3 /etc/x-ui/x-ui.db \"SELECT value FROM settings WHERE key=\"\"webBasePath\"\";\")"'
alias xuiconfig='sqlite3 /etc/x-ui/x-ui.db "SELECT key,value FROM settings;"'
XUITAIL

# Install MOTD
cp "$REPO_DIR/VPN/motd_server.sh" /etc/profile.d/motd_server.sh
chmod +x /etc/profile.d/motd_server.sh
# Disable Ubuntu default MOTD
[ -d /etc/update-motd.d ] && chmod -x /etc/update-motd.d/* 2>/dev/null || true
echo "" > /etc/motd

# shellcheck disable=SC1090
source /root/.bashrc 2>/dev/null || true
echo -e "${G}[OK] .bashrc deployed with all aliases + MOTD installed${X}"

# =============================================================================
# STEP 5: Install 3X-UI
# =============================================================================
echo -e "${Y}[5/8] Installing 3X-UI...${X}"
export TERM=xterm
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) << 'XUI_INPUT'
n
XUI_INPUT
sleep 5
echo -e "${G}[OK] 3X-UI installed${X}"

# =============================================================================
# STEP 6: Set credentials & port
# =============================================================================
echo -e "${Y}[6/8] Setting panel credentials...${X}"
sleep 2

/usr/local/x-ui/x-ui setting -username "$XUI_USER" -password "$XUI_PASS" 2>/dev/null || true
sqlite3 "$DB" "INSERT OR REPLACE INTO settings (key,value) VALUES ('webUsername','$XUI_USER');" 2>/dev/null || true
sqlite3 "$DB" "INSERT OR REPLACE INTO settings (key,value) VALUES ('webPassword','$XUI_PASS');" 2>/dev/null || true
sqlite3 "$DB" "INSERT OR REPLACE INTO settings (key,value) VALUES ('port','$XUI_PORT');" 2>/dev/null || true

BASE_PATH=$(sqlite3 "$DB" "SELECT value FROM settings WHERE key='webBasePath';" 2>/dev/null)
echo -e "${G}[OK] Credentials set: $XUI_USER / [hidden] | Port: $XUI_PORT${X}"

# =============================================================================
# STEP 7: Self-signed SSL certificate (10 years, by IP)
# =============================================================================
echo -e "${Y}[7/8] Generating SSL certificate...${X}"
mkdir -p /root/certs
openssl req -x509 -newkey rsa:4096 \
  -keyout /root/certs/xui.key \
  -out /root/certs/xui.crt \
  -days 3650 -nodes \
  -subj "/CN=$SERVER_IP" \
  -addext "subjectAltName=IP:$SERVER_IP" 2>/dev/null
chmod 600 /root/certs/xui.key
chmod 644 /root/certs/xui.crt
sqlite3 "$DB" "INSERT OR REPLACE INTO settings (key,value) VALUES ('certFile','/root/certs/xui.crt');" 2>/dev/null || true
sqlite3 "$DB" "INSERT OR REPLACE INTO settings (key,value) VALUES ('keyFile','/root/certs/xui.key');" 2>/dev/null || true
sqlite3 "$DB" "INSERT OR REPLACE INTO settings (key,value) VALUES ('webCertFile','/root/certs/xui.crt');" 2>/dev/null || true
sqlite3 "$DB" "INSERT OR REPLACE INTO settings (key,value) VALUES ('webKeyFile','/root/certs/xui.key');" 2>/dev/null || true
echo -e "${G}[OK] SSL cert created (10 years, no domain needed)${X}"

# =============================================================================
# STEP 8: Auto backup cron (daily 03:00)
# =============================================================================
echo -e "${Y}[8/8] Setting up auto backup...${X}"
mkdir -p "$BACKUP_DIR"
cat > /root/xray_backup.sh << 'BKEOF'
#!/bin/bash
# Xray 3X-UI daily backup — v2026-04-24
# = Rooted by VladiMIR | AI =
DATE=$(date +%Y-%m-%d_%H%M)
DIR="/root/backups/xray"
mkdir -p $DIR
cp /etc/x-ui/x-ui.db $DIR/x-ui_$DATE.db
find $DIR -name "*.db" -mtime +30 -delete
echo "[OK] Backup: $DIR/x-ui_$DATE.db"
BKEOF
chmod +x /root/xray_backup.sh
(crontab -l 2>/dev/null | grep -v xray_backup; echo "0 3 * * * /root/xray_backup.sh") | crontab -
echo -e "${G}[OK] Auto backup: daily 03:00 → $BACKUP_DIR${X}"

# =============================================================================
# Restart & show result
# =============================================================================
x-ui restart
sleep 4

ACTUAL_PORT=$(sqlite3 "$DB" "SELECT value FROM settings WHERE key='port';" 2>/dev/null)
ACTUAL_PATH=$(sqlite3 "$DB" "SELECT value FROM settings WHERE key='webBasePath';" 2>/dev/null)

echo ""
echo -e "${Y}========================================================${X}"
echo -e "${G} INSTALLATION COMPLETE! v2026-04-24${X}"
echo -e "${C} = Rooted by VladiMIR | AI =${X}"
echo -e "${Y}========================================================${X}"
echo -e "${C} Server IP  : ${G}$SERVER_IP${X}"
echo -e "${C} Hostname   : ${G}$HOSTNAME_NEW${X}"
echo -e "${C} Panel URL  : ${G}https://$SERVER_IP:$ACTUAL_PORT$ACTUAL_PATH${X}"
echo -e "${C} Username   : ${G}$XUI_USER${X}"
echo -e "${C} SSL        : ${G}Self-signed, 10 years${X}"
echo -e "${C} Repo       : ${G}$REPO_DIR${X}"
echo -e "${C} Backup     : ${G}$BACKUP_DIR (daily 03:00)${X}"
echo -e "${Y}========================================================${X}"
echo -e "${M} ALIASES ACTIVE:${X}"
echo -e "  ${C}00${X}          — clear"
echo -e "  ${C}infooo${X}      — server info + benchmark"
echo -e "  ${C}audit${X}       — security audit"
echo -e "  ${C}sos / sos3 / sos24 / sos120${X} — monitoring"
echo -e "  ${C}xuistatus${X}   — x-ui status"
echo -e "  ${C}xuirestart${X}  — restart x-ui"
echo -e "  ${C}xuibackup${X}   — manual backup"
echo -e "  ${C}xuiusers${X}    — list inbounds"
echo -e "  ${C}xuiurl${X}      — show panel URL"
echo -e "  ${C}load${X}        — git pull + deploy"
echo -e "  ${C}save${X}        — git push"
echo -e "  ${C}backup${X}      — backup VPN configs"
echo -e "  ${C}banlog${X}      — CrowdSec ban list"
echo -e "${Y}========================================================${X}"
echo -e "${Y} Browser: Advanced → Proceed (self-signed cert)${X}"
echo -e "${Y} Next: create VLESS+Reality inbound in panel${X}"
echo -e "${Y}========================================================${X}"
echo ""
x-ui status
