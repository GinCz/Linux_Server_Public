#!/usr/bin/env bash
# ==============================================================================
# Script: install_dietpi_ram.sh
# Description: Live in-RAM installation of pure DietPi (NativePC-BIOS x86_64)
#              Completely wipes the root disk and installs pure DietPi from RAM.
# Author: GinCz (Vladimir Bulantsev) + AI
# ==============================================================================

set -e

clear
echo "================================================================="
echo "   🚀 DIETPI IN-RAM LIVE INSTALLER (Pure NativePC BIOS x86_64)   "
echo "================================================================="

# 1. Root check
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Ошибка: Скрипт должен выполняться с правами root!"
    exit 1
fi

# 2. Detect Root Disk
ROOT_DEV=$(findmnt -n -o SOURCE / 2>/dev/null | sed -r 's/p?[0-9]+$//')
if [ -z "$ROOT_DEV" ] || [ ! -b "$ROOT_DEV" ]; then
    ROOT_DEV="/dev/vda"
    [ ! -b "$ROOT_DEV" ] && ROOT_DEV="/dev/sda"
fi
echo "🎯 Целевой диск для установки: $ROOT_DEV"

# 3. Detect Hostname
CURRENT_HOSTNAME=$(hostname)
echo "🏷️ Имя хоста: $CURRENT_HOSTNAME"

# 4. Prepare RAM Workspace
RAM_DIR="/dev/shm/dietpi_install"
rm -rf "$RAM_DIR"
mkdir -p "$RAM_DIR"

echo "📦 Установка необходимых утилит (xz-utils, curl, parted, util-linux)..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq xz-utils curl parted udev >/dev/null 2>&1 || true

# 5. Backup SSH Authorized Keys
mkdir -p "$RAM_DIR/keys"
if [ -f /root/.ssh/authorized_keys ]; then
    cp /root/.ssh/authorized_keys "$RAM_DIR/keys/authorized_keys"
    echo "🔑 Скопированы текущие SSH-ключи root."
fi

# 6. Download DietPi Image into RAM
IMG_RAM="$RAM_DIR/dietpi.img.xz"
IMG_URL_PRIMARY="http://152.53.182.222:8080/DietPi_NativePC-BIOS-x86_64-Bookworm.img.xz"
IMG_URL_OFFICIAL="https://dietpi.com/downloads/images/DietPi_NativePC-BIOS-x86_64-Bookworm.img.xz"

echo "📥 Загрузка чистого образа DietPi в RAM (/dev/shm)..."
if curl -sSfL --connect-timeout 5 "$IMG_URL_PRIMARY" -o "$IMG_RAM" 2>/dev/null; then
    echo "✅ Загружено с локального сервера 222"
else
    echo "🌐 Загрузка с официального репозитория DietPi..."
    curl -sSfL "$IMG_URL_OFFICIAL" -o "$IMG_RAM"
fi

if [ ! -s "$IMG_RAM" ]; then
    echo "❌ Ошибка: Файл образа DietPi не загружен или пуст!"
    exit 1
fi
echo "✅ Образ успешно сохранён в оперативной памяти ($(du -h "$IMG_RAM" | awk '{print $1}'))"

# 7. Write DietPi Image directly to Root Disk
echo "⚠️ ВНИМАНИЕ: Начинается прямая перезапись диска $ROOT_DEV чистым образом DietPi..."
xzcat "$IMG_RAM" | dd of="$ROOT_DEV" bs=4M conv=fsync status=progress

echo "🔄 Обновление таблицы разделов..."
sync
partprobe "$ROOT_DEV" 2>/dev/null || blockdev --rereadpt "$ROOT_DEV" 2>/dev/null || true
sleep 2

# 8. Mount DietPi Root & Configure First Boot
TARGET_PART="${ROOT_DEV}1"
[ ! -b "$TARGET_PART" ] && TARGET_PART="${ROOT_DEV}p1"

MNT_DIR="$RAM_DIR/mnt"
mkdir -p "$MNT_DIR"
mount "$TARGET_PART" "$MNT_DIR"

echo "⚙️ Предварительная настройка DietPi (dietpi.txt)..."
if [ -f "$MNT_DIR/boot/dietpi.txt" ]; then
    # Автоматическое лицензирование и первый запуск
    sed -i 's/^AUTO_SETUP_ACCEPT_LICENSE=.*/AUTO_SETUP_ACCEPT_LICENSE=1/' "$MNT_DIR/boot/dietpi.txt"
    sed -i 's/^AUTO_SETUP_AUTOMATED=.*/AUTO_SETUP_AUTOMATED=1/' "$MNT_DIR/boot/dietpi.txt"
    sed -i 's/^AUTO_SETUP_GLOBAL_PASSWORD=.*/AUTO_SETUP_GLOBAL_PASSWORD=OKMokm-09/' "$MNT_DIR/boot/dietpi.txt"
    sed -i 's/^AUTO_SETUP_KEYBOARD_LAYOUT=.*/AUTO_SETUP_KEYBOARD_LAYOUT=us/' "$MNT_DIR/boot/dietpi.txt"
    sed -i 's/^AUTO_SETUP_TIMEZONE=.*/AUTO_SETUP_TIMEZONE=Europe\/Prague/' "$MNT_DIR/boot/dietpi.txt"
    sed -i 's/^AUTO_SETUP_NET_ETHERNET_ENABLED=.*/AUTO_SETUP_NET_ETHERNET_ENABLED=1/' "$MNT_DIR/boot/dietpi.txt"
    sed -i 's/^AUTO_SETUP_NET_WIFI_ENABLED=.*/AUTO_SETUP_NET_WIFI_ENABLED=0/' "$MNT_DIR/boot/dietpi.txt"
    sed -i 's/^SURVEY_OPTED_IN=.*/SURVEY_OPTED_IN=0/' "$MNT_DIR/boot/dietpi.txt"
    sed -i "s/^CONFIG_HOSTNAME=.*/CONFIG_HOSTNAME=$CURRENT_HOSTNAME/" "$MNT_DIR/boot/dietpi.txt"
fi

# Внедрение SSH ключей
mkdir -p "$MNT_DIR/root/.ssh"
if [ -f "$RAM_DIR/keys/authorized_keys" ]; then
    cat "$RAM_DIR/keys/authorized_keys" > "$MNT_DIR/root/.ssh/authorized_keys"
fi
chmod 700 "$MNT_DIR/root/.ssh"
chmod 600 "$MNT_DIR/root/.ssh/authorized_keys" 2>/dev/null || true

# Включаем SSH Dropbear/OpenSSH в DietPi
sed -i 's/^AUTO_SETUP_SSH_SERVER_INDEX=.*/AUTO_SETUP_SSH_SERVER_INDEX=-1/' "$MNT_DIR/boot/dietpi.txt" 2>/dev/null || true

sync
umount "$MNT_DIR"
sync

echo "================================================================="
echo "   ✅ УСТАНОВКА DIETPI ЗАВЕРШЕНА! СЕРВЕР ПЕРЕЗАГРУЖАЕТСЯ...      "
echo "   Пароль root по умолчанию: OKMokm-09                           "
echo "   SSH ключи сохранены.                                          "
echo "================================================================="
sleep 2

# 9. Hardware Instant Reboot via sysrq
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger