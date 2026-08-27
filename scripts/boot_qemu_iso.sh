#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  boot_qemu_iso.sh | [v2026-08-27-Universal]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Universal Live Linux/Cloud QEMU ISO/IMG bootloader (x86_64 + ARM64 / Ampere)
# Servers     : Bare-metal / GRML / Cloud VPS (Oracle Cloud / NetCup / AWS / VDSina / LeaseWeb)
# Usage       : bash scripts/boot_qemu_iso.sh
# ==========================================================================================

# ── Colors & Styling (Exact User Theme: Cyan 81) ──────────────────────────────────────────
C='\033[38;5;81m'     # Серо-голубой фирменный
G='\033[0;92m'       # Зеленый
Y='\033[0;93m'       # Желтый
R='\033[1;31m'       # Красный
W='\033[1;37m'       # Яркий белый
D='\033[38;5;244m'    # Серый / Dim
X='\033[0m'          # Сброс
BOLD='\033[1m'
HR="${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"

# ── Config & Auto-Detection ───────────────────────────────────────────────────────────────
SERVER_IP="${SERVER_IP:-152.53.182.222}"
SSH_USER="${SSH_USER:-root}"
SSH_PASS="${SSH_PASS:-OKMokm-09}"
REMOTE_PATH="${REMOTE_PATH:-/storage/soft/ISO}"
MOUNT_POINT="${MOUNT_POINT:-/mnt/iso_server}"
VNC_PORT="5900"
VNC_DISPLAY=":0"
QEMU_PID=""
ARCH="$(uname -m)"

# ── Auto-detect Current Public IP ────────────────────────────────────────────────────────
MY_PUBLIC_IP=""
if grep -qiE 'amazon|ec2' /sys/class/dmi/id/* 2>/dev/null; then
    _AWS_TOKEN="$(curl -s --connect-timeout 0.3 -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60" 2>/dev/null)"
    if [ -n "$_AWS_TOKEN" ]; then
        MY_PUBLIC_IP="$(curl -s --connect-timeout 0.3 -H "X-aws-ec2-metadata-token: $_AWS_TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)"
    fi
fi
[ -z "$MY_PUBLIC_IP" ] && MY_PUBLIC_IP="$(curl -s --connect-timeout 2 https://api.ipify.org 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')"
MY_PUBLIC_IP=${MY_PUBLIC_IP:-"127.0.0.1"}

# ── Auto-detect RAM ───────────────────────────────────────────────────────────────────────
TOTAL_RAM_MB=$(free -m 2>/dev/null | awk '/^Mem:/{print $2}')
TOTAL_RAM_MB=${TOTAL_RAM_MB:-1024}

if [ -z "$RAM_MB" ]; then
    if [ "$TOTAL_RAM_MB" -le 1200 ]; then
        RAM_MB=650
    elif [ "$TOTAL_RAM_MB" -le 2200 ]; then
        RAM_MB=1200
    elif [ "$TOTAL_RAM_MB" -le 4500 ]; then
        RAM_MB=2048
    elif [ "$TOTAL_RAM_MB" -le 9000 ]; then
        RAM_MB=4096
    else
        RAM_MB=6144
    fi
fi

# ── Auto-detect Target Disk ───────────────────────────────────────────────────────────────
mapfile -t DETECTED_DISKS < <(lsblk -dpno NAME,TYPE 2>/dev/null | awk '$2=="disk"{print $1}')

if [ -z "$TARGET_DISK" ]; then
    if [ ${#DETECTED_DISKS[@]} -ge 1 ]; then
        TARGET_DISK="${DETECTED_DISKS[0]}"
    else
        TARGET_DISK="/dev/sda"
    fi
fi

# ── Ctrl+C handler ───────────────────────────────────────────────────────────────────────
trap_ctrlc() {
    echo -e "\n${Y}[!] Ctrl+C — stopping QEMU...${X}"
    if [ -n "$QEMU_PID" ] && kill -0 "$QEMU_PID" 2>/dev/null; then
        kill "$QEMU_PID" 2>/dev/null
        wait "$QEMU_PID" 2>/dev/null
    fi
    QEMU_PID=""
    echo -e "${C}[*] Back to menu...${X}\n"
    sleep 1
}
trap trap_ctrlc INT

# ── Header Banner ─────────────────────────────────────────────────────────────────────────
print_banner() {
    echo -e "${HR}"
    echo -e "  ${C}Universal QEMU Boot Launcher${X}  |  ${W}github.com/GinCz${X}  |  Arch: ${G}${ARCH}${X}"
    echo -e "  ISO Server: ${C}${SERVER_IP}${X}  |  Disk: ${Y}${TARGET_DISK}${X}  |  RAM: ${G}${RAM_MB} MB${X}"
    echo -e "  VNC: ${W}${BOLD}${MY_PUBLIC_IP}:${VNC_PORT}${X}"
    echo -e "${HR}"
}

# ── Check and install dependencies for Current Architecture ──────────────────────────────
check_deps() {
    local pkgs=("sshfs" "sshpass" "fuse3" "mc")
    
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        pkgs+=("qemu-system-arm" "qemu-efi-aarch64")
    else
        pkgs+=("qemu-system-x86")
    fi

    local need_install=0
    for pkg in "${pkgs[@]}"; do
        case "$pkg" in
            qemu-system-arm)
                command -v qemu-system-aarch64 >/dev/null 2>&1 || need_install=1 ;;
            qemu-system-x86)
                command -v qemu-system-x86_64 >/dev/null 2>&1 || need_install=1 ;;
            qemu-efi-aarch64)
                [ -f /usr/share/qemu-efi-aarch64/QEMU_EFI.fd ] || [ -f /usr/share/AAVMF/AAVMF_CODE.fd ] || need_install=1 ;;
            *)
                command -v "$pkg" >/dev/null 2>&1 || need_install=1 ;;
        esac
    done

    if [ "$need_install" -eq 1 ]; then
        echo -e "  ${Y}[!] Installing required packages for ${ARCH}...${X}"
        apt-get update -qq && apt-get install -y "${pkgs[@]}" >/dev/null 2>&1
        echo -e "  ${G}[+] Dependencies installed successfully${X}"
    fi
}

# ── KVM auto-detection ────────────────────────────────────────────────────────────────────
detect_kvm() {
    KVM_FLAG=""
    if [ ! -e /dev/kvm ]; then
        modprobe kvm 2>/dev/null
        if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
            modprobe kvm_arm 2>/dev/null
        else
            modprobe kvm_amd 2>/dev/null || modprobe kvm_intel 2>/dev/null
        fi
    fi
    
    if [ -e /dev/kvm ]; then
        KVM_FLAG="-enable-kvm"
        echo -e "  ${G}[+] Acceleration: KVM Hardware Enabled (${ARCH})${X}"
    else
        echo -e "  ${Y}[!] Acceleration: Software Emulation (KVM not available)${X}"
    fi
}

# ── Force-clean stale or broken FUSE mountpoint ──────────────────────────────────────────
cleanup_mountpoint() {
    umount -lf "$MOUNT_POINT" 2>/dev/null
    fusermount -u "$MOUNT_POINT" 2>/dev/null
    sleep 1
    if [ -d "$MOUNT_POINT" ] && ! mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        rm -rf "$MOUNT_POINT"
    fi
    mkdir -p "$MOUNT_POINT"
}

# ── Mount remote ISO storage ──────────────────────────────────────────────────────────────
mount_remote() {
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null && [ "$(ls -A "$MOUNT_POINT" 2>/dev/null)" ]; then
        return
    fi

    cleanup_mountpoint

    echo -e "  ${C}[*] Connecting ISO Storage (${SERVER_IP}:${REMOTE_PATH})...${X}"
    
    # Method 1: SSH key (if present)
    if [ -f /root/.ssh/id_ed25519 ] || [ -f /root/.ssh/id_rsa ]; then
        sshfs -o StrictHostKeyChecking=no,allow_other,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 \
            "${SSH_USER}@${SERVER_IP}:${REMOTE_PATH}" "$MOUNT_POINT" 2>/dev/null
    fi

    # Method 2: SSHPass Password fallback
    if ! mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        sshpass -p "${SSH_PASS}" sshfs -o StrictHostKeyChecking=no,allow_other,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 \
            "${SSH_USER}@${SERVER_IP}:${REMOTE_PATH}" "$MOUNT_POINT" 2>/dev/null
    fi

    if ! mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        echo -e "  ${R}[!] ERROR: SSHFS mount failed. Please check connection to ${SERVER_IP}.${X}"
        exit 1
    fi
    echo -e "  ${G}[+] Storage connected: ${MOUNT_POINT}${X}"
}

# ── Select Target Disk ────────────────────────────────────────────────────────────────────
select_disk() {
    if [ ${#DETECTED_DISKS[@]} -gt 1 ]; then
        echo -e "\n${C}DISKS DETECTED:${X}"
        for idx in "${!DETECTED_DISKS[@]}"; do
            size=$(lsblk -dno SIZE "${DETECTED_DISKS[$idx]}" 2>/dev/null)
            echo -e "  ${Y}$((idx + 1))${X}. ${W}${DETECTED_DISKS[$idx]}${X} (${size})"
        done
        echo ""
        read -rp "$(echo -e "Select Target Disk [1-${#DETECTED_DISKS[@]}] (Default: 1 - ${DETECTED_DISKS[0]}): ")" disk_choice
        if [[ "$disk_choice" =~ ^[0-9]+$ ]] && [ "$disk_choice" -ge 1 ] && [ "$disk_choice" -le "${#DETECTED_DISKS[@]}" ]; then
            TARGET_DISK="${DETECTED_DISKS[$((disk_choice - 1))]}"
        fi
    elif [ ${#DETECTED_DISKS[@]} -eq 1 ]; then
        TARGET_DISK="${DETECTED_DISKS[0]}"
    fi
}

# ── Print Image menu with Architecture Highlights ─────────────────────────────────────────
print_iso_menu() {
    local -n _isos=$1
    local total=${#_isos[@]}

    echo -e "\n${HR}"
    echo -e "  ${C}AVAILABLE IMAGES (${total} total)  |  Current Node: ${G}${ARCH}${X}"
    echo -e "${HR}"

    for i in "${!_isos[@]}"; do
        local name="${_isos[$i]}"
        local tag=""
        if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
            if [[ "$name" =~ [Aa][Rr][Mm]64|[Aa][Aa][Rr][Cc][Hh]64 ]]; then
                tag=" ${G}[ARM64 Native]${X}"
            else
                tag=" ${D}[x86 - Emulation]${X}"
            fi
        else
            if [[ "$name" =~ [Aa][Rr][Mm]64|[Aa][Aa][Rr][Cc][Hh]64 ]]; then
                tag=" ${D}[ARM64 - Emulation]${X}"
            else
                tag=" ${G}[x86_64 Native]${X}"
            fi
        fi
        printf "  ${Y}%2d${X}. %s%b\n" "$((i + 1))" "$name" "$tag"
    done

    echo -e "${HR}"
    echo -e "  ${D}Ctrl+C — stop QEMU  |  q — quit${X}"
}

# ══ MAIN ══════════════════════════════════════════════════════════════════════════════════════════

clear
check_deps
select_disk
detect_kvm
mount_remote
print_banner

# Auto-open VNC ports in iptables and ufw
iptables -I INPUT 1 -p tcp --dport 5900:5905 -j ACCEPT 2>/dev/null || true
if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    ufw allow 5900:5905/tcp comment 'QEMU VNC' >/dev/null 2>&1 || true
fi

while true; do

    mapfile -t ISOS < <(find "$MOUNT_POINT" -maxdepth 1 \( -iname "*.iso" -o -iname "*.img" \) -printf "%f\n" | sort -f)

    if [ ${#ISOS[@]} -eq 0 ]; then
        echo -e "${R}[!] No ISO/IMG files found in ${MOUNT_POINT}${X}"
        exit 1
    fi

    print_iso_menu ISOS

    TOTAL=${#ISOS[@]}
    echo ""
    read -rp "$(echo -e "${W}Select Image [1-${TOTAL}] or 'q' to quit: ${X}")" selection

    [[ "$selection" =~ ^[qQ]$ ]] && echo -e "\n${C}[*] Exiting...${X}\n" && break

    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "$TOTAL" ]; then
        echo -e "${R}[!] Invalid selection.${X}\n"
        continue
    fi

    SELECTED_ISO="${MOUNT_POINT}/${ISOS[$((selection - 1))]}"
    ISO_NAME="${ISOS[$((selection - 1))]}"

    [ ! -f "$SELECTED_ISO" ] && echo -e "${R}[!] File not found: ${SELECTED_ISO}${X}" && continue

    echo -e "\n${HR}"
    echo -e "  ${G}● LAUNCHING:${X} ${W}${BOLD}${ISO_NAME}${X}"
    echo -e "  ${C}VNC CONNECT:${X} ${W}${BOLD}${MY_PUBLIC_IP}:${VNC_PORT}${X}"
    echo -e "  ${D}Arch: ${ARCH}  |  Disk: ${TARGET_DISK}  |  RAM: ${RAM_MB}MB${X}"
    echo -e "${HR}\n"

    # Locate VirtIO drivers if available
    VIRTIO_ISO=""
    for v_candidate in "${MOUNT_POINT}"/virtio-win*.iso; do
        if [ -f "$v_candidate" ]; then
            VIRTIO_ISO="$v_candidate"
            break
        fi
    done

    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        # ── ARM64 Execution Mode (Ampere A1 / Apple / Graviton) ───────────────────────────
        UEFI_BIOS="/usr/share/qemu-efi-aarch64/QEMU_EFI.fd"
        [ ! -f "$UEFI_BIOS" ] && UEFI_BIOS="/usr/share/AAVMF/AAVMF_CODE.fd"
        [ ! -f "$UEFI_BIOS" ] && UEFI_BIOS="/usr/share/edk2/aarch64/QEMU_EFI.fd"

        CPU_OPT="-cpu host"
        [ -z "$KVM_FLAG" ] && CPU_OPT="-cpu cortex-a57"

        VIRTIO_ATTACH=""
        [ -n "$VIRTIO_ISO" ] && VIRTIO_ATTACH="-drive file=${VIRTIO_ISO},media=cdrom"

        qemu-system-aarch64 \
            ${KVM_FLAG} \
            ${CPU_OPT} \
            -M virt \
            -m "${RAM_MB}" \
            -smp 4 \
            -bios "${UEFI_BIOS}" \
            -drive file="${TARGET_DISK}",format=raw,if=virtio \
            -cdrom "${SELECTED_ISO}" \
            ${VIRTIO_ATTACH} \
            -device usb-ehci -device usb-kbd -device usb-tablet \
            -device virtio-net-pci,netdev=net0 \
            -netdev user,id=net0 \
            -vnc "0.0.0.0${VNC_DISPLAY}" &

    else
        # ── x86_64 Execution Mode ────────────────────────────────────────────────────────
        BOOT_DRIVE_FLAG=""
        if [[ "$ISO_NAME" =~ \.iso$ ]]; then
            BOOT_DRIVE_FLAG="-boot d -cdrom \"$SELECTED_ISO\""
        else
            BOOT_DRIVE_FLAG="-boot c -drive file=\"$SELECTED_ISO\",format=raw,if=ide,readonly=on"
        fi

        eval qemu-system-x86_64 \
            "${KVM_FLAG}" \
            -m "${RAM_MB}" \
            ${BOOT_DRIVE_FLAG} \
            -drive file="${TARGET_DISK}",format=raw,if=ide \
            -net nic,model=e1000 \
            -net user \
            -vga std \
            -audiodev none,id=noaudio \
            -machine pcspk-audiodev=noaudio \
            -vnc "0.0.0.0${VNC_DISPLAY}" &
    fi

    QEMU_PID=$!
    wait "$QEMU_PID"
    QEMU_PID=""
    echo -e "\n${C}[*] QEMU session ended.${X}\n"
    sleep 1

done

# ── Cleanup ───────────────────────────────────────────────────────────────────────────────
read -rp "$(echo -e "${Y}[?] Unmount ${MOUNT_POINT}? (y/n): ${X}")" unmount_choice
if [[ "$unmount_choice" =~ ^[Yy]$ ]]; then
    umount -lf "$MOUNT_POINT" 2>/dev/null
    fusermount -u "$MOUNT_POINT" 2>/dev/null
    rm -rf "$MOUNT_POINT"
    echo -e "${G}[+] Unmounted and cleaned up.${X}"
fi

echo -e "\n${HR}"
echo -e "  ${C}= Rooted by VladiMIR | AI = v2026.08.27 = github.com/GinCz =${X}"
echo -e "${HR}\n"
