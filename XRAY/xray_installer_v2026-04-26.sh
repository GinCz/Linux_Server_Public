#!/bin/bash
# =============================================================
# Script: xray_installer_v2026-04-26.sh
# Version: v2026-04-26-FINAL
# Server: Universal (clean Ubuntu 22.04/24.04)
# Description: FULL CLEAN + XRAY + 3x-ui + Samba (vlad/usr)
# Language: English only (public repo rule)
# =============================================================
clear

# BRIGHT COLORS (good on black background)
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${RED}=========================================================${NC}"
echo -e "${RED}     ⚠️  DESTRUCTIVE CLEAN INSTALLER  ⚠️                 ${NC}"
echo -e "${RED}=========================================================${NC}"
echo -e "${YELLOW}"
echo -e "This script will COMPLETELY CLEAN your server and install:"
echo -e "  - XRAY + 3x-ui panel (port 54321, path /admin)"
echo -e "  - Samba with users: vlad (RW), usr (RO for /storage/soft)"
echo -e "  - Firewall rules (UFW)"
echo -e "  - MOTD menu and aliases"
echo -e ""
echo -e "${RED}IT WILL REMOVE:${NC}"
echo -e "  - AmneziaWG and Amnezia Docker containers"
echo -e "  - WireGuard (if installed)"
echo -e "  - Any existing Xray or 3x-ui installation"
echo -e "  - All Docker containers with 'amnezia' in name"
echo -e "  - Old firewall rules"
echo -e ""
echo -e "${YELLOW}Press ENTER to continue or Ctrl+C to cancel...${NC}"
read -r

# --- Get credentials from user ---
echo -e "\n${CYAN}=========================================================${NC}"
echo -e "${CYAN}     XRAY + 3x-ui INTERACTIVE INSTALLER                 ${NC}"
echo -e "${CYAN}=========================================================${NC}\n"

echo -e "${YELLOW}Please enter credentials for the 3x-ui admin panel:${NC}"
read -p "Username (default: admin): " INPUT_USERNAME
INPUT_USERNAME=${INPUT_USERNAME:-admin}

read -sp "Password (default: auto-generated): " INPUT_PASSWORD
echo ""
if [ -z "$INPUT_PASSWORD" ]; then
    INPUT_PASSWORD=$(tr -dc 'A-Za-z0-9!?%=' < /dev/urandom | head -c 16)
    echo -e "${YELLOW}Auto-generated password: ${GREEN}$INPUT_PASSWORD${NC}"
fi

# ============================================================
# STEP 0: COMPLETE CLEANUP
# ============================================================
echo -e "\n${RED}>>> STEP 0: COMPLETE SYSTEM CLEANUP...${NC}"

# Stop all Amnezia/WireGuard services
echo -e "${YELLOW}Stopping AmneziaWG and WireGuard services...${NC}"
systemctl stop amneziawg 2>/dev/null
systemctl stop wg-quick@* 2>/dev/null
systemctl stop awg 2>/dev/null
systemctl stop docker 2>/dev/null

# Kill all Docker containers with Amnezia in name
echo -e "${YELLOW}Removing Amnezia Docker containers...${NC}"
docker ps -a | grep -i amnezia | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null

# Remove AmneziaWG packages
echo -e "${YELLOW}Removing AmneziaWG packages...${NC}"
apt remove -y amneziawg awg wireguard wireguard-tools 2>/dev/null
apt purge -y amneziawg awg 2>/dev/null

# Remove old Xray and 3x-ui
echo -e "${YELLOW}Removing old Xray and 3x-ui...${NC}"
x-ui uninstall 2>/dev/null
systemctl stop xray 2>/dev/null
systemctl stop x-ui 2>/dev/null
rm -rf /usr/local/x-ui
rm -rf /usr/local/xray
rm -rf /etc/xray
rm -f /etc/systemd/system/xray.service
rm -f /etc/systemd/system/x-ui.service

# Remove Amnezia configuration files
echo -e "${YELLOW}Removing Amnezia config files...${NC}"
rm -rf /opt/amnezia
rm -rf /etc/amnezia
rm -rf /root/amnezia-*

# Remove old Samba config (will be recreated)
echo -e "${YELLOW}Cleaning old Samba config...${NC}"
rm -f /etc/samba/smb.conf
rm -rf /storage 2>/dev/null

# Clean Docker if exists
if command -v docker &>/dev/null; then
    echo -e "${YELLOW}Cleaning Docker...${NC}"
    docker system prune -af 2>/dev/null
fi

# Clean package cache
apt autoremove -y
apt autoclean -y

echo -e "${GREEN}✅ Cleanup complete!${NC}"

# ============================================================
# STEP 1: Dependencies and Firewall (INCLUDING SAMBA)
# ============================================================
echo -e "\n${CYAN}>>> STEP 1: Installing dependencies...${NC}"
apt update -y && apt upgrade -y
apt install -y curl wget ufw nano socat tar unzip jq git mc htop net-tools sqlite3 acl samba samba-common

# ============================================================
# STEP 2: Firewall configuration
# ============================================================
echo -e "\n${CYAN}>>> STEP 2: Configuring firewall...${NC}"
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
for PORT in 80 443 2096 8443 8080 8888 54321 30000 30001 30002 30003 30004 30005 40000 45000 50000 60000; do
    ufw allow $PORT/tcp 2>/dev/null
done
echo "y" | ufw --force enable
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F

# ============================================================
# STEP 3: Samba setup (per your repository specification)
# ============================================================
echo -e "\n${CYAN}>>> STEP 3: Setting up Samba with users vlad and usr...${NC}"

# Create users with standard password (sa4434 from your spec)
DEFAULT_PASS="sa4434"
for u in vlad usr; do
    id -u $u &>/dev/null || useradd -m -s /bin/bash $u
    echo "$u:$DEFAULT_PASS" | chpasswd
done

# Create directory structure
mkdir -p /storage/user /storage/soft
chown -R vlad:vlad /storage
chmod -R 770 /storage

# Setup ACLs per your specification
setfacl -bR /storage 2>/dev/null
setfacl -m u:usr:x /storage
setfacl -R -m u:usr:rx /storage/soft
setfacl -R -d -m u:usr:rx /storage/soft
setfacl -R -m u:usr:rwx /storage/user
setfacl -R -d -m u:usr:rwx /storage/user

# Configure Samba
cat > /etc/samba/smb.conf << SMBCFG
[global]
   workgroup = WORKGROUP
   security = user
   map to guest = bad user
   server string = %h server (Samba, Ubuntu)
   dns proxy = no

[storage]
   path = /storage
   browsable = yes
   writable = yes
   guest ok = no
   valid users = vlad, usr
   vfs objects = acl_xattr
   map acl inherit = yes
   store dos attributes = yes
   create mask = 0664
   directory mask = 0775
SMBCFG

# Set Samba passwords
(echo "$DEFAULT_PASS"; echo "$DEFAULT_PASS") | smbpasswd -a -s vlad
(echo "$DEFAULT_PASS"; echo "$DEFAULT_PASS") | smbpasswd -a -s usr

systemctl restart smbd nmbd
systemctl enable smbd nmbd
echo -e "${GREEN}✅ Samba configured with vlad and usr (password: $DEFAULT_PASS)${NC}"

# ============================================================
# STEP 4: Install XRAY + 3x-ui (SKIP DOMAIN QUESTION)
# ============================================================
echo -e "\n${CYAN}>>> STEP 4: Installing XRAY + 3x-ui panel...${NC}"

# Download installer
wget -q -O /tmp/xui-install.sh https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh
chmod +x /tmp/xui-install.sh

# Run with answers to ALL questions (domain left empty to skip)
# This avoids the infinite domain prompt loop
bash /tmp/xui-install.sh << EOF
1
y
1

EOF

# ============================================================
# STEP 5: Force config (0.0.0.0 + credentials)
# ============================================================
echo -e "\n${CYAN}>>> STEP 5: Applying custom settings...${NC}"
systemctl stop x-ui
sleep 2

PORT=54321
WEB_BASE_PATH="/admin"
x-ui setting -port ${PORT}
x-ui setting -webBasePath ${WEB_BASE_PATH}
x-ui setting -username ${INPUT_USERNAME}
x-ui setting -password ${INPUT_PASSWORD}

# Wait for Xray config to be created
sleep 3

# Patch Xray config if exists
XRAY_CONFIG="/usr/local/x-ui/bin/config.json"
if [ -f "$XRAY_CONFIG" ]; then
    sed -i 's/"listen": "127.0.0.1"/"listen": "0.0.0.0"/g' "$XRAY_CONFIG"
    echo -e "${GREEN}✅ Xray config patched to listen on 0.0.0.0${NC}"
else
    echo -e "${YELLOW}⚠️ Xray config not found, will be created on first start${NC}"
fi

# ============================================================
# STEP 6: Start services
# ============================================================
systemctl daemon-reload
systemctl restart x-ui
sleep 5

# Force Xray start if needed
if ! systemctl is-active --quiet xray 2>/dev/null; then
    echo -e "${YELLOW}Starting Xray manually...${NC}"
    systemctl start xray 2>/dev/null || {
        [ -f "$XRAY_CONFIG" ] && /usr/local/x-ui/bin/xray run -c "$XRAY_CONFIG" > /dev/null 2>&1 &
    }
fi

systemctl enable x-ui
sleep 2

# ============================================================
# STEP 7: Get actual panel data
# ============================================================
SERVER_IP=$(curl -s ifconfig.me)
FINAL_PORT=$(x-ui settings 2>/dev/null | grep -oP 'port: \K\d+' | head -1)
FINAL_PATH=$(x-ui settings 2>/dev/null | grep -oP 'webBasePath: \K/\S+' | head -1)
FINAL_USER=$(x-ui settings 2>/dev/null | grep -oP 'username: \K\S+' | head -1)

# ============================================================
# STEP 8: MOTD menu (bright colors)
# ============================================================
cat > /etc/profile.d/motd_xray.sh << 'MOTD'
#!/bin/bash
if [ "$EUID" -ne 0 ]; then return 0; fi

# BRIGHT COLORS
BOLD='\033[1m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

IP=$(hostname -I | awk '{print $1}')
RAM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
RAM_USED=$(free -m | awk '/^Mem:/{print $3}')
CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
XRAY_STATUS=$(systemctl is-active xray 2>/dev/null || echo "inactive")
PANEL_STATUS=$(systemctl is-active x-ui 2>/dev/null || echo "inactive")
PANEL_PORT=$(x-ui settings 2>/dev/null | grep -oP 'port: \K\d+' | head -1)
PANEL_PATH=$(x-ui settings 2>/dev/null | grep -oP 'webBasePath: \K/\S+' | head -1)
PANEL_USER=$(x-ui settings 2>/dev/null | grep -oP 'username: \K\S+' | head -1)

clear
echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${WHITE}  🖥  XRAY VPN SERVER${NC}          ${IP}          ${WHITE}RAM:${NC} ${RAM_USED}/${RAM_TOTAL}MB  ${WHITE}CPU:${NC} ${CPU_LOAD}"
echo -e "${WHITE}  XRAY: ${NC}${XRAY_STATUS}     ${WHITE}PANEL:${NC} ${PANEL_STATUS}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  xray-url${NC}      ${GREEN}xui-settings${NC}    ${GREEN}xray-status${NC}     ${GREEN}vstat${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Panel: https://${IP}:${PANEL_PORT}${PANEL_PATH:-/}${NC}"
echo -e "${GREEN}  Login: ${PANEL_USER}${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Samba: //${IP}/storage (vlad/usr, pass: sa4434)${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
MOTD
chmod +x /etc/profile.d/motd_xray.sh

# ============================================================
# STEP 9: Aliases
# ============================================================
cat >> /root/.bashrc << 'ALIASES'
alias xray-url='echo "https://$(curl -s ifconfig.me):$(x-ui settings 2>/dev/null | grep -oP "port: \K\d+" | head -1)$(x-ui settings 2>/dev/null | grep -oP "webBasePath: \K/\S+" | head -1)"'
alias xui-settings='x-ui settings'
alias xray-status='systemctl status xray --no-pager'
alias xray-restart='systemctl restart xray'
alias vstat='systemctl status xray x-ui --no-pager | grep -E "Active|Loaded"'
alias sambastatus='systemctl status smbd nmbd --no-pager'
alias 00='clear'
ALIASES
source /root/.bashrc

# ============================================================
# STEP 10: Final output (bright colors)
# ============================================================
clear
echo -e "${GREEN}=========================================================${NC}"
echo -e "${GREEN}              INSTALLATION COMPLETE!                     ${NC}"
echo -e "${GREEN}=========================================================${NC}\n"

echo -e "${CYAN}🔗 PANEL ACCESS URL:${NC}"
echo -e "   ${GREEN}https://$SERVER_IP:$FINAL_PORT$FINAL_PATH${NC}\n"

echo -e "${CYAN}👤 PANEL LOGIN:${NC}    ${GREEN}$FINAL_USER${NC}"
echo -e "${CYAN}🔑 PANEL PASSWORD:${NC} ${GREEN}$INPUT_PASSWORD${NC}\n"

echo -e "${CYAN}📁 SAMBA SHARES:${NC}"
echo -e "   ${GREEN}//$SERVER_IP/storage${NC}"
echo -e "   ${CYAN}Users:${NC} vlad / usr"
echo -e "   ${CYAN}Password:${NC} sa4434\n"

echo -e "${CYAN}📋 USEFUL COMMANDS:${NC}"
echo -e "   ${GREEN}xray-url${NC}      - show panel link"
echo -e "   ${GREEN}xui-settings${NC}  - panel settings"
echo -e "   ${GREEN}xray-status${NC}   - XRAY status"
echo -e "   ${GREEN}vstat${NC}         - quick check"
echo -e "   ${GREEN}sambastatus${NC}   - Samba status\n"

echo -e "${GREEN}✅ Logout and login again to see the MOTD menu${NC}\n"

cat > /root/xray_panel_info.txt << EOF
=========================================
XRAY PANEL INFO - $(date)
=========================================
URL: https://$SERVER_IP:$FINAL_PORT$FINAL_PATH
Login: $FINAL_USER
Password: $INPUT_PASSWORD
=========================================
SAMBA SHARE:
  //$SERVER_IP/storage
  Users: vlad / usr
  Password: sa4434
=========================================
EOF
echo -e "${GREEN}✅ Credentials saved to /root/xray_panel_info.txt${NC}"

echo "========================================="
echo "📘 HOW TO ADD USERS (READ THIS):"
echo "https://github.com/GinCz/Linux_Server_Public/tree/main/xray"
echo "========================================="

