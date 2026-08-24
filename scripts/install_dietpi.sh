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
    elif [ "$AUTO_MODE" -eq 1 ]; then
        USER_PASS="dietpi"
    else
        while [ -z "$USER_PASS" ]; do
            read -s -p "🔑 Enter new root password for DietPi: " USER_PASS
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

# 4. Install dependencies
echo "📦 Installing prerequisites..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq curl wget ca-certificates locales tzdata systemd systemd-sysv >/dev/null 2>&1 || true

# 5. Download official DietPi PREP installer
echo "📥 Downloading official DietPi installer..."
INSTALLER_URL="https://raw.githubusercontent.com/MichaIng/DietPi/master/.build/images/dietpi-installer"
curl -sSfL "$INSTALLER_URL" -o /tmp/dietpi-installer
chmod +x /tmp/dietpi-installer

# 6. Execute DietPi PREP
echo "⚙️ Executing DietPi installer..."
if [ "$AUTO_MODE" -eq 1 ]; then
    /tmp/dietpi-installer || true
else
    /tmp/dietpi-installer
fi

# 7. Post-install automation: write /boot/dietpi.txt
if [ -n "$NET_IP" ] && [ -n "$NET_GW" ]; then
    mkdir -p /boot
    cat << EOF > /boot/dietpi.txt
AUTO_SETUP_AUTOMATED=1
AUTO_SETUP_GLOBAL_PASSWORD=${USER_PASS}
AUTO_SETUP_TIMEZONE=Europe/London
AUTO_SETUP_LOCALE=en_US.UTF-8
AUTO_SETUP_KEYBOARD_LAYOUT=us
AUTO_SETUP_NET_ETH0_IP=${NET_IP}
AUTO_SETUP_NET_ETH0_MASK=${NET_MASK_DOTTED}
AUTO_SETUP_NET_ETH0_GW=${NET_GW}
AUTO_SETUP_NET_ETH0_DNS=${NET_DNS}
AUTO_SETUP_NET_USESTATIC=1
SURVEY_OPTED_IN=-1
CONFIG_CHECK_DIETPI_UPDATES=0
CONFIG_CHECK_APT_UPDATES=0
AUTO_SETUP_WEB_SERVER_INDEX=0
AUTO_SETUP_SSH_SERVER_INDEX=-2
AUTO_SETUP_FILE_SERVER_INDEX=0
AUTO_SETUP_LOG_SYSTEM_INDEX=-1
AUTO_UNMASK_LOGIND=1
EOF
fi

echo "================================================================="
echo "   ✅ DIETPI CONVERSION COMPLETED!"
echo "   Rebooting into lightweight DietPi in 5 seconds..."
echo "================================================================="
sleep 5
reboot