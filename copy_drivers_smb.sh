#!/bin/bash
clear
# = Rooted by VladiMIR + AI | v.2026.07.27 | github.com/GinCz =
# Copy drivers from SMB share to Windows partition
# Run in GRML Live Linux via:
#   bash <(curl -sk https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/copy_drivers_smb.sh)

SMB_SHARE="//s.gincz.com/user/Server-2016"
SMB_MOUNT="/mnt/smb"
WIN_MOUNT="/mnt/wintarget"
WIN_DEST="${WIN_MOUNT}/Drivers"

echo "=== Driver Copy: SMB -> Windows Partition ==="
echo ""

# Install cifs-utils if missing
if ! command -v mount.cifs &>/dev/null; then
    echo "Installing cifs-utils..."
    apt-get install -y cifs-utils 2>/dev/null | tail -2
fi

# Mount Windows NTFS partition
echo "Mounting Windows partition /dev/sda1..."
mkdir -p "${WIN_MOUNT}"
if ! mountpoint -q "${WIN_MOUNT}"; then
    ntfs-3g /dev/sda1 "${WIN_MOUNT}"
    if [ $? -ne 0 ]; then
        echo "ERROR: Cannot mount /dev/sda1 as NTFS"
        echo "Check: lsblk && parted /dev/sda print"
        exit 1
    fi
fi
echo "OK: Windows partition mounted at ${WIN_MOUNT}"
df -h "${WIN_MOUNT}"
echo ""

# Ask SMB credentials
read -p "SMB Username: " SMB_USER
read -s -p "SMB Password: " SMB_PASS
echo ""
echo ""

# Mount SMB share
echo "Mounting SMB share ${SMB_SHARE}..."
mkdir -p "${SMB_MOUNT}"
mount -t cifs "${SMB_SHARE}" "${SMB_MOUNT}" \
    -o "username=${SMB_USER},password=${SMB_PASS},vers=3.0,iocharset=utf8,sec=ntlmssp"

if [ $? -ne 0 ]; then
    echo "ERROR: Cannot mount SMB share"
    echo "Check: network, credentials, share path"
    exit 1
fi

echo "OK: SMB share mounted"
echo ""
echo "Contents of SMB share:"
ls -la "${SMB_MOUNT}/"
echo ""

# Copy all files to Windows partition
mkdir -p "${WIN_DEST}"
echo "Copying all files to C:\\Drivers ..."
echo ""
cp -rv "${SMB_MOUNT}/." "${WIN_DEST}/"
COPY_STATUS=$?

sync
echo ""
echo "=== Result ==="
if [ ${COPY_STATUS} -eq 0 ]; then
    echo "OK: All files copied to ${WIN_DEST}"
    echo ""
    ls -lh "${WIN_DEST}/"
    echo ""
    df -h "${WIN_MOUNT}"
else
    echo "WARNING: cp exited with code ${COPY_STATUS} - check output above"
fi

# Unmount SMB
umount "${SMB_MOUNT}" 2>/dev/null && echo "SMB share unmounted."
echo ""
echo "Done. Proceed to Veeam Recovery step."
