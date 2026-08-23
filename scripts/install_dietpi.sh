#!/usr/bin/env bash
# ==============================================================================
# Script: install_dietpi.sh
# Description: Interactive / Automated Debian -> DietPi converter
#              Prompts for root password and executes official DietPi installer.
# Author: GinCz & Community (Linux Server Tools)
# ==============================================================================

set -e
clear

echo "================================================================="
echo "   🚀 DIETPI CONVERTER (Debian -> Pure Lightweight DietPi)       "
echo "================================================================="

# 1. Root check
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Ошибка: Запустите скрипт под пользователем root!"
    exit 1
fi

# 2. Prompt for Root Password
echo ""
if [ -n "$ROOT_PASS" ]; then
    USER_PASS="$ROOT_PASS"
    echo "✅ Использован пароль из переменной окружения ROOT_PASS."
else
    while [ -z "$USER_PASS" ]; do
        read -s -p "🔑 Введите новый пароль для root: " USER_PASS
        echo ""
        if [ -z "$USER_PASS" ]; then
            echo "⚠️ Пароль не может быть пустым! Повторите ввод:"
        fi
    done
    echo "✅ Пароль успешно принят."
fi

echo "root:$USER_PASS" | chpasswd

# 3. Add Master SSH keys if present in environment or pre-create folder
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# 4. Install Dependencies & Set Locales
echo ""
echo "📦 Обновление пакетов и генерация локалей en_US.UTF-8..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq curl ca-certificates git systemd-sysv wget locales tzdata >/dev/null 2>&1 || true
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen 2>/dev/null || true
locale-gen en_US.UTF-8 >/dev/null 2>&1 || true
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 >/dev/null 2>&1 || true
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 5. OS Version Check
DEBIAN_VER=$(grep -oP 'VERSION_ID="\K[^"]+' /etc/os-release 2>/dev/null || true)
if [ -n "$DEBIAN_VER" ] && [ "$DEBIAN_VER" != "12" ]; then
    echo "⚠️ ВНИМАНИЕ: Для 100% стабильности DietPi требуется Debian 12 (Bookworm). Текущая версия: $DEBIAN_VER"
fi

# 6. Capture Current IPv4 Network Configuration
echo ""
echo "🌐 Захват сетевых настроек хостинга (IP, Gateway, Mask)..."
ORIG_IP=$(ip -4 addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
ORIG_CIDR=$(ip -4 addr show scope global 2>/dev/null | awk '{print $4}' | head -n1 | cut -d/ -f2)
ORIG_GW=$(ip route show default 2>/dev/null | awk '{print $3}' | head -n1)

case "$ORIG_CIDR" in
    24) ORIG_MASK="255.255.255.0" ;;
    25) ORIG_MASK="255.255.255.128" ;;
    26) ORIG_MASK="255.255.255.192" ;;
    27) ORIG_MASK="255.255.255.224" ;;
    28) ORIG_MASK="255.255.255.240" ;;
    *) ORIG_MASK="255.255.255.0" ;;
esac

echo "   IP: ${ORIG_IP:-unknown} | Gateway: ${ORIG_GW:-unknown} | Mask: ${ORIG_MASK}"

# 7. Run Official DietPi Installer
INSTALLER_URL="https://raw.githubusercontent.com/MichaIng/DietPi/master/.build/images/dietpi-installer"
curl -sSfL "$INSTALLER_URL" -o /tmp/dietpi-installer
chmod +x /tmp/dietpi-installer

echo ""
echo "================================================================="
echo "   📋 ПОШАГОВАЯ ИНСТРУКЦИЯ ПО МЕНЮ DIETPI-INSTALLER:            "
echo "================================================================="
echo " 1️⃣  Name / Creator  ➔ Введите имя: GinCz или Vladimir (Enter)    "
echo " 2️⃣  Device Select   ➔ Выберите: 20 : Virtual machine (для VPS)   "
echo " 3️⃣  Target Distro   ➔ Выберите: Bookworm (Debian 12)             "
echo " 4️⃣  Wifi / Network  ➔ Нажмите <Ok> (Ethernet / по умолчанию)    "
echo " 5️⃣  Confirm Install ➔ Подтвердите установку (<Ok> / <Yes>)       "
echo "================================================================="
echo ""
read -t 5 -p "⏳ Запуск мастера через 5 сек (или нажмите Enter для немедленного старта)..." || true
echo ""

/tmp/dietpi-installer

# 8. Post-Install Auto-Configuration (Fix Static Network & Passwords)
if [ -n "$ORIG_IP" ] && [ -n "$ORIG_GW" ]; then
    echo ""
    echo "⚙️ Автоматическая фиксация статического IP ($ORIG_IP) в DietPi..."
    if [ -f /boot/dietpi.txt ]; then
        sed -i "s/^AUTO_SETUP_NET_USESTATIC=.*/AUTO_SETUP_NET_USESTATIC=1/" /boot/dietpi.txt 2>/dev/null || true
        sed -i "s/^AUTO_SETUP_NET_STATIC_IP=.*/AUTO_SETUP_NET_STATIC_IP=$ORIG_IP/" /boot/dietpi.txt 2>/dev/null || true
        sed -i "s/^AUTO_SETUP_NET_STATIC_MASK=.*/AUTO_SETUP_NET_STATIC_MASK=$ORIG_MASK/" /boot/dietpi.txt 2>/dev/null || true
        sed -i "s/^AUTO_SETUP_NET_STATIC_GATEWAY=.*/AUTO_SETUP_NET_STATIC_GATEWAY=$ORIG_GW/" /boot/dietpi.txt 2>/dev/null || true
        sed -i "s/^AUTO_SETUP_NET_STATIC_DNS=.*/AUTO_SETUP_NET_STATIC_DNS=8.8.8.8 1.1.1.1/" /boot/dietpi.txt 2>/dev/null || true
    fi

    cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address $ORIG_IP
    netmask $ORIG_MASK
    gateway $ORIG_GW
    dns-nameservers 8.8.8.8 1.1.1.1

auto ens3
iface ens3 inet static
    address $ORIG_IP
    netmask $ORIG_MASK
    gateway $ORIG_GW
    dns-nameservers 8.8.8.8 1.1.1.1
EOF
fi

echo ""
echo "================================================================="
echo "   ✅ DIETPI УСПЕШНО УСТАНОВЛЕН И НАСТРОЕН!                      "
echo "   Сеть и SSH настроены на IP: $ORIG_IP                          "
echo "   Нажмите Enter для перезагрузки...                             "
echo "================================================================="