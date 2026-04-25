#!/bin/bash
# =============================================================================
# XRAY/install.sh — Universal 3X-UI installer for any fresh Ubuntu 24 VPS
# =============================================================================
# Version  : v2026-04-24
# Author   : Ing. VladiMIR Bulantsev
# GitHub   : https://github.com/GinCz/Linux_Server_Public
# Usage    : bash <(curl -s https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/XRAY/install.sh)
# = Rooted by VladiMIR | AI =
# =============================================================================

clear
G='\033[1;32m'; C='\033[1;36m'; Y='\033[1;33m'; R='\033[1;31m'; M='\033[1;35m'; X='\033[0m'

echo -e "${Y}========================================${X}"
echo -e "${C} Xray 3X-UI Installer v2026-04-24      ${X}"
echo -e "${C} = Rooted by VladiMIR | AI =           ${X}"
echo -e "${Y}========================================${X}"
echo ""

[ "$(id -u)" != "0" ] && echo -e "${R}[ERROR] Run as root!${X}" && exit 1

SERVER_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
REPO_DIR="/root/Linux_Server_Public"
BACKUP_DIR="/root/backups/xray"
CERT_DIR="/root/certs"
DB="/etc/x-ui/x-ui.db"

echo -e "${C}Detected IP : ${G}$SERVER_IP${X}"
echo ""

# ==========================================================================
# STEP 0: Interactive credentials
# ==========================================================================
echo -e "${Y}--- Enter server details ---${X}"
read -rp  "Hostname   (e.g. vpn-eu-myserver) : " NEW_HOSTNAME
NEW_HOSTNAME=${NEW_HOSTNAME:-xray-server}

read -rp  "Panel port (default 54321)        : " XUI_PORT
XUI_PORT=${XUI_PORT:-54321}

read -rp  "Username                          : " XUI_USER
while [ -z "$XUI_USER" ]; do
  echo -e "${R}Username cannot be empty!${X}"
  read -rp "Username                          : " XUI_USER
done

read -rsp "Password                          : " XUI_PASS; echo ""
while [ -z "$XUI_PASS" ]; do
  echo -e "${R}Password cannot be empty!${X}"
  read -rsp "Password                         : " XUI_PASS; echo ""
done

BASE_PATH="/$(openssl rand -hex 8)/"

echo ""
echo -e "${G}[OK] Hostname  : $NEW_HOSTNAME${X}"
echo -e "${G}[OK] Port      : $XUI_PORT${X}"
echo -e "${G}[OK] User      : $XUI_USER${X}"
echo -e "${G}[OK] Base path : $BASE_PATH${X}"
echo ""

# ==========================================================================
# STEP 1: System
# ==========================================================================
echo -e "${Y}[1/8] System update & packages...${X}"
hostnamectl set-hostname "$NEW_HOSTNAME" 2>/dev/null || true
timedatectl set-timezone Europe/Prague 2>/dev/null || true
apt-get update -qq && apt-get upgrade -y -qq
apt-get install -y -qq curl wget nano ufw mc htop git sqlite3 openssl cron jq net-tools
echo -e "${G}[OK] System ready | TZ: Europe/Prague | Hostname: $NEW_HOSTNAME${X}"

# ==========================================================================
# STEP 2: UFW
# ==========================================================================
echo -e "${Y}[2/8] Firewall setup...${X}"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow "${XUI_PORT}/tcp"
ufw --force enable
echo -e "${G}[OK] UFW: 22, 80, 443, $XUI_PORT${X}"

# ==========================================================================
# STEP 3: Clone repo
# ==========================================================================
echo -e "${Y}[3/8] GitHub repo...${X}"
if [ -d "$REPO_DIR/.git" ]; then
  cd "$REPO_DIR" && git pull --rebase
  echo -e "${G}[OK] Repo updated${X}"
else
  git clone https://github.com/GinCz/Linux_Server_Public.git "$REPO_DIR"
  echo -e "${G}[OK] Repo cloned${X}"
fi

# ==========================================================================
# STEP 4: .bashrc + x-ui aliases + MOTD
# ==========================================================================
echo -e "${Y}[4/8] Deploying .bashrc + aliases + MOTD...${X}"
cp /root/.bashrc /root/.bashrc.bak.$(date +%Y%m%d) 2>/dev/null || true
cp "$REPO_DIR/VPN/.bashrc" /root/.bashrc

cat >> /root/.bashrc << 'ALIASES'

# =============================================================================
# X-UI / XRAY ALIASES — v2026-04-24 | = Rooted by VladiMIR | AI =
# =============================================================================
alias xui='x-ui'
alias xuistart='x-ui start'
alias xuistop='x-ui stop'
alias xuirestart='x-ui restart'
alias xuistatus='x-ui status'
alias xuilog='journalctl -u x-ui -f'
alias xuibackup='mkdir -p /root/backups/xray && cp /etc/x-ui/x-ui.db /root/backups/xray/x-ui_$(date +%Y-%m-%d_%H%M).db && echo "[OK] Backup saved"'
alias xuiusers='sqlite3 /etc/x-ui/x-ui.db "SELECT id,remark,protocol,port,enable FROM inbounds;"'
alias xuiconfig='sqlite3 /etc/x-ui/x-ui.db "SELECT key,value FROM settings;"'
alias xuifix='x-ui stop && x-ui start && x-ui status'
ALIASES

cp "$REPO_DIR/VPN/motd_server.sh" /etc/profile.d/motd_server.sh
chmod +x /etc/profile.d/motd_server.sh
for OLD in /etc/profile.d/motd_vpn.sh /etc/profile.d/motd_banner.sh /etc/profile.d/ps1_color.sh; do
  [ -f "$OLD" ] && rm -f "$OLD"
done
[ -d /etc/update-motd.d ] && chmod -x /etc/update-motd.d/* 2>/dev/null || true
echo "" > /etc/motd
source /root/.bashrc 2>/dev/null || true
echo -e "${G}[OK] .bashrc + aliases + MOTD deployed${X}"

# ==========================================================================
# STEP 5: Install 3X-UI
# ==========================================================================
echo -e "${Y}[5/8] Installing 3X-UI (latest)...${X}"
echo "n" | bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
sleep 5
echo -e "${G}[OK] 3X-UI installed${X}"

# ==========================================================================
# STEP 6: Clean DB — set credentials (no duplicates!)
# ==========================================================================
echo -e "${Y}[6/8] Setting panel credentials (clean DB)...${X}"
x-ui stop
sleep 2

sqlite3 "$DB" "DELETE FROM settings;"
sqlite3 "$DB" "INSERT INTO settings (key,value) VALUES ('webPort','$XUI_PORT');"
sqlite3 "$DB" "INSERT INTO settings (key,value) VALUES ('webBasePath','$BASE_PATH');"
sqlite3 "$DB" "INSERT INTO settings (key,value) VALUES ('webUsername','$XUI_USER');"
sqlite3 "$DB" "INSERT INTO settings (key,value) VALUES ('webPassword','$XUI_PASS');"
sqlite3 "$DB" "INSERT INTO settings (key,value) VALUES ('secret','$(openssl rand -hex 16)');"
sqlite3 "$DB" "INSERT INTO settings (key,value) VALUES ('webCertFile','$CERT_DIR/xui.crt');"
sqlite3 "$DB" "INSERT INTO settings (key,value) VALUES ('webKeyFile','$CERT_DIR/xui.key');"
sqlite3 "$DB" "INSERT INTO settings (key,value) VALUES ('subCertFile','$CERT_DIR/xui.crt');"
sqlite3 "$DB" "INSERT INTO settings (key,value) VALUES ('subKeyFile','$CERT_DIR/xui.key');"
echo -e "${G}[OK] DB clean — no duplicates${X}"

# ==========================================================================
# STEP 7: SSL cert 10 years self-signed
# ==========================================================================
echo -e "${Y}[7/8] SSL certificate (10 years)...${X}"
mkdir -p "$CERT_DIR"
openssl req -x509 -newkey rsa:4096 \
  -keyout "$CERT_DIR/xui.key" \
  -out "$CERT_DIR/xui.crt" \
  -days 3650 -nodes \
  -subj "/CN=$SERVER_IP" \
  -addext "subjectAltName=IP:$SERVER_IP" 2>/dev/null
chmod 600 "$CERT_DIR/xui.key"
chmod 644 "$CERT_DIR/xui.crt"
echo -e "${G}[OK] SSL: $CERT_DIR/xui.crt${X}"

# ==========================================================================
# STEP 8: Backup cron daily 03:00
# ==========================================================================
echo -e "${Y}[8/8] Auto backup cron...${X}"
mkdir -p "$BACKUP_DIR"
cat > /root/xray_backup.sh << 'BKEOF'
#!/bin/bash
# Xray daily backup v2026-04-24 | = Rooted by VladiMIR | AI =
DATE=$(date +%Y-%m-%d_%H%M)
DIR="/root/backups/xray"
mkdir -p $DIR
cp /etc/x-ui/x-ui.db $DIR/x-ui_$DATE.db
find $DIR -name "*.db" -mtime +30 -delete
echo "[OK] Backup: $DIR/x-ui_$DATE.db"
BKEOF
chmod +x /root/xray_backup.sh
(crontab -l 2>/dev/null | grep -v xray_backup; echo "0 3 * * * /root/xray_backup.sh") | crontab -
echo -e "${G}[OK] Backup cron: daily 03:00 → $BACKUP_DIR${X}"

# ==========================================================================
# Start & result
# ==========================================================================
x-ui start
sleep 4

echo ""
echo -e "${Y}======================================================${X}"
echo -e "${G} INSTALLATION COMPLETE! v2026-04-24${X}"
echo -e "${C} = Rooted by VladiMIR | AI =${X}"
echo -e "${Y}======================================================${X}"
echo -e "${C} Server IP : ${G}$SERVER_IP${X}"
echo -e "${C} Hostname  : ${G}$NEW_HOSTNAME${X}"
echo -e "${C} Panel URL : ${G}https://$SERVER_IP:$XUI_PORT$BASE_PATH${X}"
echo -e "${C} Username  : ${G}$XUI_USER${X}"
echo -e "${C} Password  : ${G}$XUI_PASS${X}"
echo -e "${C} SSL       : ${G}Self-signed 10 years${X}"
echo -e "${C} Backup    : ${G}$BACKUP_DIR (daily 03:00)${X}"
echo -e "${Y}======================================================${X}"
echo -e "${M} ALIASES:${X}"
echo -e "  ${C}sos/sos3/sos24/sos120${X}  monitoring"
echo -e "  ${C}infooo${X}    server info + benchmark"
echo -e "  ${C}audit${X}     security audit"
echo -e "  ${C}backup${X}    backup configs"
echo -e "  ${C}banlog${X}    CrowdSec ban list"
echo -e "  ${C}load${X}      git pull + deploy"
echo -e "  ${C}save${X}      git push"
echo -e "  ${C}xuistatus${X} x-ui status"
echo -e "  ${C}xuirestart${X} restart x-ui"
echo -e "  ${C}xuibackup${X} manual backup"
echo -e "  ${C}xuiusers${X}  list inbounds"
echo -e "  ${C}xuiurl${X}    show panel URL"
echo -e "  ${C}xuiconfig${X} all settings"
echo -e "  ${C}xuifix${X}    stop+start x-ui"
echo -e "  ${C}00${X}        clear"
echo -e "${Y}======================================================${X}"
echo -e "${Y} Browser: Advanced → Proceed (self-signed cert)${X}"
echo -e "${Y} Next: create VLESS+Reality inbound in panel${X}"
echo -e "${Y}======================================================${X}"
echo ""
x-ui status

echo "========================================="
echo "📘 HOW TO ADD USERS (READ THIS):"
echo "https://github.com/GinCz/Linux_Server_Public/tree/main/xray"
echo "========================================="

