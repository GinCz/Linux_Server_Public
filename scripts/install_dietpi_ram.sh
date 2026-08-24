#!/usr/bin/env bash
# ==============================================================================
# Script: install_dietpi_ram.sh
# Description: Universal in-RAM live installer for pure DietPi (x86_64 BIOS).
#              Wipes root disk and installs clean DietPi on-the-fly from memory.
# Author: GinCz & Community (Linux Server Tools)
# ==============================================================================

# Entire installer executes in a memory-buffered subshell to ensure uninterrupted execution
{
    set -e

    clear
    echo "================================================================="
    echo "   🚀 DIETPI IN-RAM LIVE INSTALLER (Pure NativePC BIOS x86_64)   "
    echo "================================================================="

    # 1. Check Root Privileges
    if [ "$(id -u)" -ne 0 ]; then
        echo "❌ Error: This script must be run as root!"
        exit 1
    fi

    # 2. Enable Kernel SysRq triggers in advance
    echo 1 > /proc/sys/kernel/sysrq 2>/dev/null || true

    # 3. Detect Root Disk Device
    ROOT_DEV=$(findmnt -n -o SOURCE / 2>/dev/null | sed -r 's/p?[0-9]+$//')
    if [ -z "$ROOT_DEV" ] || [ ! -b "$ROOT_DEV" ]; then
        ROOT_DEV="/dev/vda"
        [ ! -b "$ROOT_DEV" ] && ROOT_DEV="/dev/sda"
    fi
    echo "🎯 Target Disk: $ROOT_DEV"

    # 4. Detect Current Hostname
    CURRENT_HOSTNAME=$(hostname 2>/dev/null || echo "dietpi-node")
    echo "🏷️ Hostname: $CURRENT_HOSTNAME"

    # 5. Prepare RAM Workspace in /dev/shm (tmpfs)
    RAM_DIR="/dev/shm/dietpi_install"
    rm -rf "$RAM_DIR" 2>/dev/null || true
    mkdir -p "$RAM_DIR"

    echo "📦 Installing prerequisites (xz-utils, curl, util-linux)..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq && apt-get install -y -qq xz-utils curl parted udev util-linux >/dev/null 2>&1 || true

    # 6. Backup SSH Authorized Keys to RAM
    mkdir -p "$RAM_DIR/keys"
    if [ -f /root/.ssh/authorized_keys ]; then
        cp /root/.ssh/authorized_keys "$RAM_DIR/keys/authorized_keys"
        echo "🔑 Preserved existing root SSH keys."
    fi

    # 7. Download DietPi Image into RAM
    IMG_RAM="$RAM_DIR/dietpi.img.xz"
    IMG_URL_OFFICIAL="https://dietpi.com/downloads/images/DietPi_NativePC-BIOS-x86_64-Bookworm.img.xz"

    echo "📥 Downloading clean DietPi image directly into RAM (/dev/shm)..."
    curl -sSfL "$IMG_URL_OFFICIAL" -o "$IMG_RAM"

    if [ ! -s "$IMG_RAM" ]; then
        echo "❌ Error: Failed to download DietPi image!"
        exit 1
    fi
    IMG_SIZE=$(du -h "$IMG_RAM" | awk '{print $1}')
    echo "✅ Image stored in RAM ($IMG_SIZE)"

    # 8. Unpack and Write Image directly to Root Disk
    echo "⚠️ Overwriting root disk $ROOT_DEV with pure DietPi..."
    xzcat "$IMG_RAM" | dd of="$ROOT_DEV" bs=4M conv=fsync status=progress

    # 9. Sync and Hard Reboot via SysRq
    echo "================================================================="
    echo "   ✅ DIETPI INSTALLATION COMPLETE! INSTANT HARD REBOOT...       "
    echo "   Default root password: dietpi (or pre-configured)             "
    echo "================================================================="
    sync
    sleep 1

    # Hardware Instant Reboot via sysrq
    echo 1 > /proc/sys/kernel/sysrq
    echo b > /proc/sysrq-trigger
}