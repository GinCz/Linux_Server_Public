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

# 6. Run Official DietPi Installer
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
echo " 6️⃣  Reboot Server   ➔ После завершения нажмите Enter для reboot "
echo " 7️⃣  Первый вход SSH ➔ Логин: root | Пароль: dietpi (или ваш)   "
echo " 8️⃣  Next Step       ➔ После входа запустите new_server_install  "
echo "================================================================="
echo ""
read -t 5 -p "⏳ Запуск мастера через 5 сек (или нажмите Enter для немедленного старта)..." || true
echo ""

/tmp/dietpi-installer