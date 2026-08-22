#!/usr/bin/env bash
# ==============================================================================
#  AWS EC2 Linux Desktop (XFCE4 + XRDP + Brave + Telegram) Automated Installer
#  Optimized for 100% AWS Free Tier (t3.micro, 1GB RAM) over pure IPv6
#  Author: GinCz (Vladimir Bulancev) | github.com/GinCz
# ==============================================================================

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
echo -e "${CYAN}==================================================================${NC}"
echo -e "${CYAN}   🚀 AWS EC2 Linux Desktop + XRDP Setup (100% Free Tier)        ${NC}"
echo -e "${CYAN}   = Rooted by VladiMIR | AI = github.com/GinCz                  ${NC}"
echo -e "${CYAN}==================================================================${NC}"
echo ""

# 1. Swap creation
echo -e "${YELLOW}⚙️ [1/6] Configuring 2GB Swap for 1GB RAM instance...${NC}"
if ! grep -q '/swapfile' /etc/fstab; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    sysctl -w vm.swappiness=15
    echo 'vm.swappiness=15' >> /etc/sysctl.conf
    echo -e "${GREEN}✔ 2GB Swap activated!${NC}"
else
    echo -e "${GREEN}✔ Swap already exists.${NC}"
fi

# 2. Package updates and XFCE + XRDP installation
echo -e "${YELLOW}📦 [2/6] Installing XFCE4 Desktop and XRDP Server...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y xfce4 xfce4-goodies xrdp dbus-x11 x11-xserver-utils curl wget

# 3. Modern Themes & Customization
echo -e "${YELLOW}🎨 [3/6] Installing Arc-Dark Theme, Papirus Icons, and Whisker Menu...${NC}"
apt-get install -y arc-theme papirus-icon-theme xfce4-whiskermenu-plugin 2>/dev/null || true

# 4. Configure XRDP
echo -e "${YELLOW}🔌 [4/6] Configuring XRDP Session Manager...${NC}"
TARGET_USER="ubuntu"
if ! id "$TARGET_USER" &>/dev/null; then
    TARGET_USER="${SUDO_USER:-root}"
fi
USER_HOME=$(eval echo "~$TARGET_USER")

echo "startxfce4" > "${USER_HOME}/.xsession"
chown "$TARGET_USER:$TARGET_USER" "${USER_HOME}/.xsession"
adduser xrdp ssl-cert 2>/dev/null || true
adduser "$TARGET_USER" xrdp 2>/dev/null || true
adduser "$TARGET_USER" ssl-cert 2>/dev/null || true
systemctl enable xrdp
systemctl restart xrdp
echo -e "${GREEN}✔ XRDP service running on port 3389!${NC}"

# 5. Brave Browser
echo -e "${YELLOW}🦁 [5/6] Installing Brave Browser...${NC}"
curl -fsS https://dl.brave.com/install.sh | sh || true

# 6. Telegram Desktop
echo -e "${YELLOW}✈️ [6/6] Installing Telegram Desktop...${NC}"
wget -qO /tmp/tsetup.tar.xz "https://telegram.org/dl/desktop/linux"
tar -xf /tmp/tsetup.tar.xz -C /tmp/
mv /tmp/Telegram/Telegram /usr/local/bin/telegram-desktop
chmod +x /usr/local/bin/telegram-desktop
rm -rf /tmp/tsetup.tar.xz /tmp/Telegram

# Desktop Shortcuts
mkdir -p "${USER_HOME}/Desktop"
cat << 'EOF' > "${USER_HOME}/Desktop/brave.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Brave Browser
Comment=Access the Internet
Exec=/usr/bin/brave-browser %U
Icon=brave-browser
Terminal=false
EOF

cat << 'EOF' > "${USER_HOME}/Desktop/telegram.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Telegram Desktop
Comment=Official Telegram Messenger
Exec=/usr/local/bin/telegram-desktop -- %u
Icon=telegram
Terminal=false
EOF

chmod +x "${USER_HOME}/Desktop/"*.desktop
chown -R "$TARGET_USER:$TARGET_USER" "${USER_HOME}/Desktop"

echo ""
echo -e "${GREEN}==================================================================${NC}"
echo -e "${GREEN}   🎉 Setup Complete! Your AWS Linux Desktop is Ready!            ${NC}"
echo -e "${GREEN}==================================================================${NC}"
echo -e "Connect using RDP client (mRemoteNG, MS Remote Desktop):"
echo -e "  Host     : [YOUR_IPV6_ADDRESS]"
echo -e "  Port     : 3389"
echo -e "  User     : $TARGET_USER"
echo -e "=================================================================="
