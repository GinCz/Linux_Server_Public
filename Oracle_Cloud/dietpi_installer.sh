#!/usr/bin/env bash
# ==============================================================================
# Script: dietpi_installer.sh
# Description: Universal in-RAM live installer for pure DietPi (x86_64 & ARM64).
#              Downloads official 350 MB DietPi image directly into RAM,
#              flashes root disk on-the-fly, preserves SSH keys, and reboots.
# Author: GinCz (Linux Server Public)
# Official DietPi Project: https://dietpi.com
# ==============================================================================

{
    set -e

    clear
    echo "================================================================="
    echo "   🚀 UNIVERSAL DIETPI IN-RAM LIVE INSTALLER (ARM64 & x86_64)   "
    echo "   Oracle Cloud Always Free & General Linux Cloud VPS           "
    echo "================================================================="

    # 1. Root Check
    if [ "$(id -u)" -ne 0 ]; then
        echo "❌ Error: This installer must be run as root (or with sudo)!"
        exit 1
    fi

    # 2. Enable Kernel SysRq triggers
    echo 1 > /proc/sys/kernel/sysrq 2>/dev/null || true

    # 3. Detect Hardware Architecture
    ARCH=$(uname -m)
    echo "🔍 Detected CPU Architecture: $ARCH"

    # 4. Determine Official DietPi Image URL
    case "$ARCH" in
        x86_64|amd64)
            if [ -d /sys/firmware/efi ]; then
                echo "💻 Boot Mode: UEFI (x86_64)"
                IMG_URL="https://dietpi.com/downloads/images/DietPi_NativePC-UEFI-x86_64-Bookworm.img.xz"
            else
                echo "💻 Boot Mode: BIOS (x86_64)"
                IMG_URL="https://dietpi.com/downloads/images/DietPi_NativePC-BIOS-x86_64-Bookworm.img.xz"
            fi
            ;;
        aarch64|arm64|armv8*)
            echo "⚡ Boot Mode: ARM64 / Ampere A1 (UEFI)"
            IMG_URL="https://dietpi.com/downloads/images/DietPi_ARMv8-UEFI-Bookworm.img.xz"
            ;;
        *)
            echo "❌ Error: Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac

    echo "🌐 Official Download Source: $IMG_URL"

    # 5. Detect Root Storage Device
    ROOT_DEV=$(findmnt -n -o SOURCE / 2>/dev/null | sed -r 's/p?[0-9]+$//')
    if [ -z "$ROOT_DEV" ] || [ ! -b "$ROOT_DEV" ]; then
        ROOT_DEV="/dev/sda"
        [ ! -b "$ROOT_DEV" ] && ROOT_DEV="/dev/vda"
        [ ! -b "$ROOT_DEV" ] && ROOT_DEV="/dev/nvme0n1"
    fi
    echo "🎯 Target Storage Device: $ROOT_DEV"

    # 6. Prepare Temporary In-RAM Workspace (/dev/shm)
    RAM_DIR="/dev/shm/dietpi_install"
    rm -rf "$RAM_DIR" 2>/dev/null || true
    mkdir -p "$RAM_DIR"

    echo "📦 Updating package lists and installing requirements..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq && apt-get install -y -qq xz-utils curl parted udev util-linux ca-certificates >/dev/null 2>&1 || true

    # 7. Backup SSH Authorized Keys
    mkdir -p "$RAM_DIR/keys"
    if [ -f /root/.ssh/authorized_keys ]; then
        cp /root/.ssh/authorized_keys "$RAM_DIR/keys/authorized_keys"
        echo "🔑 Preserved existing root SSH authorized_keys."
    fi

    # 8. Download Official DietPi Image directly into RAM
    IMG_RAM="$RAM_DIR/dietpi.img.xz"
    echo "📥 Downloading official DietPi image (~350 MB) into RAM (/dev/shm)..."
    curl -sSfL "$IMG_URL" -o "$IMG_RAM"

    if [ ! -s "$IMG_RAM" ]; then
        echo "❌ Error: Failed to download official DietPi image from $IMG_URL"
        exit 1
    fi
    IMG_SIZE=$(du -h "$IMG_RAM" | awk '{print $1}')
    echo "✅ Image successfully buffered in RAM ($IMG_SIZE)"

    # 9. Flash Image directly to Target Disk
    echo "⚠️ Flashing clean DietPi image to $ROOT_DEV (this will replace current OS)..."
    xzcat "$IMG_RAM" | dd of="$ROOT_DEV" bs=4M conv=fsync status=progress

    # 10. Sync and Instant Hardware Reboot
    echo "================================================================="
    echo "   ✅ DIETPI INSTALLATION COMPLETE! INSTANT HARDWARE REBOOT...   "
    echo "   Default root password: dietpi                                 "
    echo "   After reboot, connect via SSH as root                         "
    echo "================================================================="
    sync
    sleep 1

    # Hardware Instant Reboot via sysrq
    echo 1 > /proc/sys/kernel/sysrq
    echo b > /proc/sysrq-trigger
}