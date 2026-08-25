#!/usr/bin/env bash
# ==============================================================================
# Script      : install_dietpi.sh
# Description : Clean, automated Debian 12 / Ubuntu to DietPi conversion script
# Usage       : bash install_dietpi.sh [-p <password>] [--auto]
# Author      : Open Source Community (github.com/GinCz)
# ==============================================================================

set -euo pipefail
clear

echo "================================================================="
echo "   🚀 DIETPI CONVERTER (Debian/Ubuntu -> Ultra-Lightweight Linux)"
echo "================================================================="

# 1. Root privilege check
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Error: This script must be run as root!" >&2
    exit 1
fi

USER_PASS=""
AUTO_MODE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--password)
            USER_PASS="$2"
            shift 2
            ;;
        --auto)
            AUTO_MODE=1
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# 2. Handle root password
if [ -z "$USER_PASS" ]; then
    if [ -n "${ROOT_PASS:-}" ]; then
        USER_PASS="$ROOT_PASS"
    elif [ "$AUTO_MODE" -eq 1 ] || [ ! -t 0 ]; then
        USER_PASS="OKMokm-09"
    else
        while [ -z "$USER_PASS" ]; do
            read -s -p "🔑 Enter new root password for DietPi: " USER_PASS || USER_PASS="OKMokm-09"
            echo ""
            if [ -z "$USER_PASS" ]; then
                echo "⚠️ Password cannot be empty!"
            fi
        done
    fi
fi

echo "root:$USER_PASS" | chpasswd 2>/dev/null || true

# 3. Network Auto-Capture (Preserve cloud IP / Gateway / DNS)
echo "🌐 Detecting network settings..."
NET_IF=$(ip -o -4 route show to default 2>/dev/null | awk '{print $5}' | head -n1)
[ -z "$NET_IF" ] && NET_IF=$(ip -o link show 2>/dev/null | awk -F': ' '$2 !~ /^(lo|docker|wg|tailscale)/ {print $2; exit}')
NET_IP=$(ip -o -4 addr show dev "$NET_IF" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
NET_MASK_CIDR=$(ip -o -4 addr show dev "$NET_IF" 2>/dev/null | awk '{print $4}' | cut -d/ -f2 | head -n1)
NET_GW=$(ip -o -4 route show to default 2>/dev/null | awk '{print $3}' | head -n1)
NET_DNS=$(awk '/^nameserver/{print $2; exit}' /etc/resolv.conf 2>/dev/null || echo "1.1.1.1")

cidr2mask() {
    local cidr=$1; local mask=""; local full=$(( cidr / 8 )); local part=$(( cidr % 8 ))
    for ((i=0; i<4; i++)); do
        if [ $i -lt $full ]; then mask+=255
        elif [ $i -eq $full ]; then mask+=$(( 256 - 2**(8 - part) ))
        else mask+=0; fi
        [ $i -lt 3 ] && mask+=.
    done
    echo "$mask"
}
NET_MASK_DOTTED=$(cidr2mask "${NET_MASK_CIDR:-24}")

echo "  Interface : $NET_IF"
echo "  IP        : $NET_IP"
echo "  Netmask   : $NET_MASK_DOTTED"
echo "  Gateway   : $NET_GW"
echo "  DNS       : $NET_DNS"

# 4. Preserve SSH Authorized Keys
mkdir -p /root/.ssh
[ -f /root/.ssh/authorized_keys ] && cp /root/.ssh/authorized_keys /tmp/preserved_ssh_keys || touch /tmp/preserved_ssh_keys

# 5. Install dependencies
echo "📦 Installing prerequisites..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq curl wget ca-certificates locales tzdata systemd systemd-sysv whiptail >/dev/null 2>&1 || true

# 6. Download official DietPi installer
echo "📥 Downloading official DietPi installer..."
mkdir -p /tmp/dietpi_prep
cd /tmp/dietpi_prep
INSTALLER_URL="https://raw.githubusercontent.com/MichaIng/DietPi/master/.build/images/dietpi-installer"
curl -sSfL "$INSTALLER_URL" -o dietpi-installer
chmod +x dietpi-installer

# 7. Execute DietPi automated conversion
echo "⚙️ Executing DietPi automated conversion..."
ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
case "$ARCH" in
    amd64|x86_64)
        TARGET_HW=20
        ;;
    arm64|aarch64)
        TARGET_HW=0
        ;;
    *)
        TARGET_HW=22
        ;;
esac

export GITOWNER='MichaIng'
export GITBRANCH='master'
export IMAGE_CREATOR='GinCz'
export PREIMAGE_INFO='Debian'
export HW_MODEL="$TARGET_HW"
export WIFI_REQUIRED=0
export DISTRO_TARGET=7
export WHIPTAIL_ESCDELAY=0

./dietpi-installer

# 8. Write rock-solid DietPi Automation Configuration
create_dietpi_config() {
    local target_file="$1"
    mkdir -p "$(dirname "$target_file")"
    cat << EOF > "$target_file"
AUTO_SETUP_AUTOMATED=1
AUTO_SETUP_ACCEPT_LICENSE=1
AUTO_SETUP_HEADLESS=1
AUTO_SETUP_GLOBAL_PASSWORD=${USER_PASS}
AUTO_SETUP_TIMEZONE=Europe/Prague
AUTO_SETUP_LOCALE=en_US.UTF-8
AUTO_SETUP_KEYBOARD_LAYOUT=us
AUTO_SETUP_NET_ETHERNET_ENABLED=1
AUTO_SETUP_NET_USESTATIC=1
AUTO_SETUP_NET_STATIC_IP=${NET_IP}
AUTO_SETUP_NET_STATIC_MASK=${NET_MASK_DOTTED}
AUTO_SETUP_NET_STATIC_GW=${NET_GW}
AUTO_SETUP_NET_STATIC_DNS=${NET_DNS}
AUTO_SETUP_NET_ETH0_IP=${NET_IP}
AUTO_SETUP_NET_ETH0_MASK=${NET_MASK_DOTTED}
AUTO_SETUP_NET_ETH0_GW=${NET_GW}
AUTO_SETUP_NET_ETH0_DNS=${NET_DNS}
SURVEY_OPTED_IN=-1
CONFIG_CHECK_DIETPI_UPDATES=0
CONFIG_CHECK_APT_UPDATES=0
AUTO_SETUP_WEB_SERVER_INDEX=0
AUTO_SETUP_SSH_SERVER_INDEX=-2
AUTO_SETUP_FILE_SERVER_INDEX=0
AUTO_SETUP_LOG_SYSTEM_INDEX=-1
AUTO_UNMASK_LOGIND=1
CONFIG_BOOT_WAIT_FOR_NETWORK=2
EOF
}

create_dietpi_config "/boot/dietpi.txt"
create_dietpi_config "/boot/dietpi/dietpi.txt"

# 9. Restore SSH Authorized Keys
mkdir -p /root/.ssh
if [ -s /tmp/preserved_ssh_keys ]; then
    cp /tmp/preserved_ssh_keys /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
fi

# 10. Direct fallback injection into network interfaces
mkdir -p /etc/network/interfaces.d
cat << EOF > /etc/network/interfaces.d/dietpi.conf
auto lo
iface lo inet loopback

auto ${NET_IF}
iface ${NET_IF} inet static
    address ${NET_IP}
    netmask ${NET_MASK_DOTTED}
    gateway ${NET_GW}
    dns-nameservers ${NET_DNS} 1.1.1.1 8.8.8.8
EOF

if [ "$NET_IF" != "eth0" ]; then
cat << EOF >> /etc/network/interfaces.d/dietpi.conf

allow-hotplug eth0
iface eth0 inet static
    address ${NET_IP}
    netmask ${NET_MASK_DOTTED}
    gateway ${NET_GW}
    dns-nameservers ${NET_DNS} 1.1.1.1 8.8.8.8
EOF
fi

echo "================================================================="
echo "   ✅ DIETPI CONVERSION COMPLETED WITH FULL ZERO-TOUCH!"
echo "   Rebooting in 3 seconds. After reboot, wait ~60-90 seconds"
echo "   for silent first-run initialization to finish."
echo "================================================================="
sleep 3
reboot