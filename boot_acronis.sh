clear
# WARNING: This script provides direct block device access to /dev/sda via QEMU.
# Ensure the host OS is not actively writing to the disk to prevent data corruption.

{
    umount /mnt/sftp_share 2>/dev/null
    umount /mnt/smb_share 2>/dev/null

    echo "Checking and installing required packages..."
    if ! command -v qemu-system-x86_64 >/dev/null || ! command -v sshfs >/dev/null || ! command -v mount.cifs >/dev/null; then
        apt-get update >/dev/null 2>&1
        apt-get install -y qemu-system-x86 sshfs cifs-utils >/dev/null 2>&1
    fi

    echo "--- Mounting SFTP (SRV-DE) ---"
    mkdir -p /mnt/sftp_share
    sshfs root@152.53.182.222:/storage/user /mnt/sftp_share

    echo ""
    echo "--- Mounting Samba Share ---"
    read -p "Enter Samba Share Path (e.g., //192.168.1.10/share) or leave blank to skip: " smb_path
    
    if [ -n "$smb_path" ]; then
        read -p "SMB Username: " smb_user
        read -s -p "SMB Password: " smb_pass
        echo ""
        mkdir -p /mnt/smb_share
        mount -t cifs "$smb_path" /mnt/smb_share -o username="$smb_user",password="$smb_pass"
        echo "Samba share mounted at /mnt/smb_share"
    else
        echo "Samba mount skipped."
    fi

    echo ""
    echo "Starting QEMU with Linux_Acronis_2018.iso..."
    echo "Connect via VNC on port 5900."
    echo "Booting directly from CD-ROM..."

    qemu-system-x86_64 \
        -m 2048 \
        -drive file=/dev/sda,format=raw,index=0,media=disk \
        -cdrom "/mnt/sftp_share/Linux_Acronis_2018.iso" \
        -netdev user,id=net0 \
        -device e1000,netdev=net0 \
        -boot order=d \
        -vnc 0.0.0.0:0
}

# = Rooted by VladiMIR + AI | v.2026.07.26 | github.com/GinCz =
