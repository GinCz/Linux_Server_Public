#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  boot_acronis.sh | [v2026-07-27]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Mounts SMB/SFTP ISO and boots via QEMU with VNC on port 5900
# Servers     : Bare-metal / GRML Live Linux
# Usage       : bash boot_acronis.sh
# ==========================================================================================
clear
# WARNING: This script provides direct block device access to /dev/sda via QEMU.
# Ensure the host OS is not actively writing to the disk to prevent data corruption.

# Enable SSH access (safe to run even if already enabled)
grml-lang us 2>/dev/null
grep -q "PermitRootLogin yes" /etc/ssh/sshd_config || echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
service ssh restart 2>/dev/null || service sshd restart 2>/dev/null
echo root:OKMokm-09 | chpasswd
echo "SSH enabled. Connect: ssh root@$(hostname -I | awk '{print $1}') / OKMokm-09"
echo ""

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
    sshfs root@152.53.182.222:/storage/soft/ISO /mnt/sftp_share

    echo ""
    echo "--- Select ISO for Boot ---"
    mapfile -t iso_files < <(find /mnt/sftp_share -maxdepth 1 -name "*.iso" -type f)

    if [ ${#iso_files[@]} -eq 0 ]; then
        echo "Error: No ISO files found in /mnt/sftp_share."
        exit 1
    fi

    for i in "${!iso_files[@]}"; do
        printf "%d) %s\n" "$((i+1))" "$(basename "${iso_files[$i]}")"
    done

    read -p "Select an ISO (1-${#iso_files[@]}): " iso_choice

    if ! [[ "$iso_choice" =~ ^[0-9]+$ ]] || [ "$iso_choice" -lt 1 ] || [ "$iso_choice" -gt "${#iso_files[@]}" ]; then
        echo "Error: Invalid selection. Exiting."
        exit 1
    fi

    SELECTED_ISO="${iso_files[$((iso_choice-1))]}"
    echo "Selected: $(basename "$SELECTED_ISO")"

    echo ""
    echo "--- Mounting Samba Share ---"
    SMB_PATH="//s.gincz.com/user/Server-2016"
    echo "Target Path: $SMB_PATH"

    read -p "SMB Username (leave blank to skip): " smb_user
    if [ -n "$smb_user" ]; then
        read -s -p "SMB Password: " smb_pass
        echo ""
        mkdir -p /mnt/smb_share
        mount -t cifs "$SMB_PATH" /mnt/smb_share -o username="$smb_user",password="$smb_pass"
        echo "Samba share mounted at /mnt/smb_share"
    else
        echo "Samba mount skipped."
    fi

    echo ""
    echo "Starting QEMU with $(basename "$SELECTED_ISO")..."
    echo "Connect via VNC on port 5900."
    echo "Press Ctrl+Alt+Del in VNC, then ESC to enter boot menu and select CD-ROM."

    qemu-system-x86_64 \
        -m 2048 \
        -drive file=/dev/sda,format=raw,index=0,media=disk \
        -cdrom "$SELECTED_ISO" \
        -netdev user,id=net0 \
        -device e1000,netdev=net0 \
        -boot order=d \
        -vnc 0.0.0.0:0
}

# = Rooted by VladiMIR | AI = v2026-07-27 = github.com/GinCz/Linux_Server_Public
