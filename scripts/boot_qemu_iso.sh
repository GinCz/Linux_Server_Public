clear
#!/bin/bash
# Description: Mounts a remote SFTP directory containing ISOs and boots selected ISO in QEMU
# Target Server: SRV-DE (NetCup)

SERVER_IP="152.53.182.222"
REMOTE_PATH="/storage/soft/ISO"
MOUNT_POINT="/mnt/iso_server"
TARGET_DISK="/dev/sda"

echo "Checking dependencies..."
if ! command -v sshfs >/dev/null 2>&1; then
    echo "Installing sshfs..."
    apt-get update -qq && apt-get install -y sshfs qemu-system-x86
fi

mkdir -p "$MOUNT_POINT"

# Mount the remote directory if not already mounted
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "Connecting to $SERVER_IP via SFTP..."
    echo "Please enter the root password for $SERVER_IP:"
    sshfs root@${SERVER_IP}:${REMOTE_PATH} "$MOUNT_POINT"
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to mount SFTP directory. Please check your credentials."
        exit 1
    fi
    echo "Successfully mounted $SERVER_IP:$REMOTE_PATH to $MOUNT_POINT"
fi

# Define the array of available ISOs
ISOS=(
    "Linux_Acronis_2018.iso"
    "Win_10_PE_Acronis_2018.iso"
    "Win_10_PE_Acronis_x86_x64_Ru_620Mb.iso"
    "Win_10_PE_x64_Acronis_evgen.iso"
    "AnduinOS-1.3.4-en_US.iso"
    "Porteus-Cinnamon-v4.0-x86_64.iso"
    "Porteus-CINNAMON-v5.1-alpha-x86_64.iso"
    "Porteus-XFCE-v5.1-alpha-x86_64.iso"
    "Runtu-lite-20.04.iso"
)

echo "=========================================="
echo "          Select ISO to Boot              "
echo "=========================================="
for i in "${!ISOS[@]}"; do
    echo "$((i+1)). ${ISOS[$i]}"
done
echo "=========================================="

read -p "Enter the number of the ISO (1-${#ISOS[@]}): " selection

# Validate input
if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#ISOS[@]}" ]; then
    echo "Invalid selection. Exiting."
    exit 1
fi

SELECTED_ISO="${MOUNT_POINT}/${ISOS[$((selection-1))]}"

if [ ! -f "$SELECTED_ISO" ]; then
    echo "Error: File not found at $SELECTED_ISO"
    echo "Make sure the file exists on the remote server."
    exit 1
fi

echo "Booting $SELECTED_ISO..."
echo "Physical disk $TARGET_DISK will be mapped using VirtIO."
echo "You can connect to the VNC console on port 5900."

# Run QEMU with KVM, 4GB RAM, CD-ROM as priority boot, and physical disk attached via virtio
qemu-system-x86_64 \
    -enable-kvm \
    -m 4096 \
    -boot d \
    -cdrom "$SELECTED_ISO" \
    -drive file="$TARGET_DISK",format=raw,if=virtio \
    -net nic,model=virtio -net user \
    -vga std \
    -vnc 0.0.0.0:0

echo "QEMU virtual machine has been stopped."

# Cleanup
read -p "Do you want to unmount the SFTP directory? (y/n): " unmount_choice
if [[ "$unmount_choice" == "y" || "$unmount_choice" == "Y" ]]; then
    umount "$MOUNT_POINT"
    echo "Directory unmounted successfully."
fi

# = Rooted by VladiMIR + AI | v.2026.07.27 | github.com/GinCz =
