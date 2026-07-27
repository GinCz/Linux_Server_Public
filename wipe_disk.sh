#!/bin/bash
clear
# = Rooted by VladiMIR + AI | v.2026.07.27 | github.com/GinCz =
# WARNING: Destroys ALL data on /dev/sda permanently!
# Usage in GRML:
#   bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/wipe_disk.sh)

DISK="/dev/sda"

echo "======================================="
echo " WARNING: ALL DATA ON ${DISK} WILL BE "
echo "       PERMANENTLY DESTROYED!          "
echo "======================================="
echo ""
echo "Current state:"
lsblk "${DISK}"
echo ""
read -p "Type YES to confirm: " confirm

if [ "${confirm}" != "YES" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Unmounting all partitions..."
umount ${DISK}* 2>/dev/null

echo "Wiping signatures (wipefs)..."
wipefs -a "${DISK}"

echo "Zeroing first 1MB (dd)..."
dd if=/dev/zero of="${DISK}" bs=512 count=2048 2>/dev/null

echo "Creating new empty MBR table (parted)..."
parted "${DISK}" --script mklabel msdos

partprobe "${DISK}" 2>/dev/null
sleep 1

echo ""
echo "=== Done. Disk ${DISK} is clean ==="
lsblk "${DISK}"
