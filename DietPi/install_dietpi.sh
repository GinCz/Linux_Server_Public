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
read -s -p "🔑 Введите новый пароль для root (или нажмите Enter для 'OKMokm-09'): " USER_PASS
echo ""
if [ -z "$USER_PASS" ]; then
    USER_PASS="OKMokm-09"
    echo "✅ Установлен стандартный пароль: OKMokm-09"
else
    echo "✅ Пароль успешно принят."
fi

echo "root:$USER_PASS" | chpasswd

# 3. Add Master SSH keys if present in environment or pre-create folder
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# 4. Install Dependencies
echo ""
echo "📦 Обновление пакетов и загрузка официального мастера DietPi..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq curl ca-certificates git systemd-sysv wget locales >/dev/null 2>&1 || true

# 5. Run Official DietPi Installer
INSTALLER_URL="https://raw.githubusercontent.com/MichaIng/DietPi/master/.build/images/dietpi-installer"
curl -sSfL "$INSTALLER_URL" -o /tmp/dietpi-installer
chmod +x /tmp/dietpi-installer

echo ""
echo "================================================================="
echo "   🚀 ЗАПУСК МАСТЕРА DIETPI...                                   "
echo "   В меню выберите: Generic PC (x86_64) -> Bookworm              "
echo "================================================================="
sleep 2

/tmp/dietpi-installer