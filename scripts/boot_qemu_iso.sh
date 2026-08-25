#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  boot_qemu_iso.sh | [v2026-08-25b]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Live Linux QEMU ISO/IMG direct bootloader (IDE/e1000 compatible for WinPE)
# Servers     : Bare-metal / GRML / Cloud VPS (AWS/NetCup/Oracle/FirstVDS)
# Usage       : bash scripts/boot_qemu_iso.sh
# ==========================================================================================
RED='\033[0;31m';  GREEN='\033[0;32m';  YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

# ── Config & Auto-Detection ───────────────────────────────────────────────────────────────
SERVER_IP="${SERVER_IP:-152.53.182.222}"
SSH_USER="${SSH_USER:-root}"
REMOTE_PATH="${REMOTE_PATH:-/storage/soft/ISO}"
MOUNT_POINT="${MOUNT_POINT:-/mnt/iso_server}"
VNC_DISPLAY=":0"     # port 5900
QEMU_PID=""

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
    else
        RAM_MB=4096
    fi
fi

# ── Auto-detect Target Disk ───────────────────────────────────────────────────────────────
mapfile -t DETECTED_DISKS < <(lsblk -dpno NAME,TYPE 2>/dev/null | awk '$2=="disk"{print $1}')

if [ -z "$TARGET_DISK" ]; then
    if [ ${#DETECTED_DISKS[@]} -eq 1 ]; then
        TARGET_DISK="${DETECTED_DISKS[0]}"
    elif [ ${#DETECTED_DISKS[@]} -gt 1 ]; then
        TARGET_DISK="${DETECTED_DISKS[0]}"
    else
        TARGET_DISK="/dev/sda"
    fi
fi

# ── Ctrl+C handler ───────────────────────────────────────────────────────────────────────
trap_ctrlc() {
    echo -e "\n${YELLOW}[!] Ctrl+C — stopping QEMU...${RESET}"
    if [ -n "$QEMU_PID" ] && kill -0 "$QEMU_PID" 2>/dev/null; then
        kill "$QEMU_PID" 2>/dev/null
        wait "$QEMU_PID" 2>/dev/null
    fi
    QEMU_PID=""
    echo -e "${CYAN}[*] Back to menu...${RESET}\n"
    sleep 1
}
trap trap_ctrlc INT

# ── Banner ────────────────────────────────────────────────────────────────────────────────
print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "  ║           🖥️  QEMU ISO/IMG Boot Launcher  🚀    github.com/GinCz       ║"
    echo "  ╠══════════════════════════════════════════════════════════════════════════════╣"
    printf "  ║  🌐 %-18s  💾 %-10s  🧠 RAM: %-6sMB  📺 VNC: 5900       ║\n" "$SERVER_IP" "$TARGET_DISK" "$RAM_MB"
    echo "  ╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

# ── Check and install dependencies ──────────────────────────────────────────────────────
check_deps() {
    echo -e "${YELLOW}[*] Checking dependencies...${RESET}"
    declare -A DEPS=(
        [sshfs]="sshfs"
        [qemu-system-x86]="qemu-system-x86_64"
        [mc]="mc"
    )
    for pkg in "${!DEPS[@]}"; do
        bin="${DEPS[$pkg]}"
        if ! command -v "$bin" >/dev/null 2>&1; then
            echo -e "  ${YELLOW}[!] Installing: ${pkg}${RESET}"
            apt-get update -qq && apt-get install -y "$pkg" >/dev/null 2>&1
            echo -e "  ${GREEN}[+] ${pkg} installed${RESET}"
        else
            echo -e "  ${GREEN}[+] ${pkg} OK${RESET}"
        fi
    done
}

# ── KVM auto-detection ────────────────────────────────────────────────────────────────────
detect_kvm() {
    KVM_FLAG=""
    if [ ! -e /dev/kvm ]; then
        modprobe kvm 2>/dev/null
        modprobe kvm_amd 2>/dev/null || modprobe kvm_intel 2>/dev/null
    fi
    if [ -e /dev/kvm ]; then
        KVM_FLAG="-enable-kvm"
        echo -e "  ${GREEN}[+] KVM OK — hardware acceleration enabled${RESET}"
    else
        echo -e "  ${YELLOW}[!] KVM unavailable — software emulation${RESET}"
    fi
}

# ── Force-clean stale or broken FUSE mountpoint ──────────────────────────────────────────
cleanup_mountpoint() {
    umount -lf "$MOUNT_POINT" 2>/dev/null
    fusermount -u "$MOUNT_POINT" 2>/dev/null
    sleep 1
    if [ -d "$MOUNT_POINT" ] && ! mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        rm -rf "$MOUNT_POINT"
        echo -e "  ${YELLOW}[*] Cleaned up stale mountpoint${RESET}"
    fi
    mkdir -p "$MOUNT_POINT"
}

# ── Mount remote ISO storage ──────────────────────────────────────────────────────────────
mount_remote() {
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        echo -e "  ${GREEN}[+] Already mounted: ${MOUNT_POINT}${RESET}"
        echo
        return
    fi

    cleanup_mountpoint

    echo -e "  ${YELLOW}[*] Mounting ${SSH_USER}@${SERVER_IP}:${REMOTE_PATH}${RESET}"
    echo -e "  ${CYAN}    Enter root password for ${SERVER_IP}:${RESET}"
    sshfs -o StrictHostKeyChecking=no,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 \
        "${SSH_USER}@${SERVER_IP}:${REMOTE_PATH}" "$MOUNT_POINT"

    if [ $? -ne 0 ]; then
        echo -e "  ${RED}[!] ERROR: SSHFS mount failed.${RESET}"
        exit 1
    fi
    echo -e "  ${GREEN}[+] Mounted → ${MOUNT_POINT}${RESET}"
    echo
}

# ── Select Target Disk ────────────────────────────────────────────────────────────────────
select_disk() {
    if [ ${#DETECTED_DISKS[@]} -gt 1 ]; then
        echo -e "${YELLOW}[?] Detected multiple disks:${RESET}"
        for idx in "${!DETECTED_DISKS[@]}"; do
            size=$(lsblk -dno SIZE "${DETECTED_DISKS[$idx]}" 2>/dev/null)
            echo -e "    $((idx + 1)). ${DETECTED_DISKS[$idx]} (${size})"
        done
        read -rp "  Select Target Disk [1-${#DETECTED_DISKS[@]}] (Default: 1 - ${DETECTED_DISKS[0]}): " disk_choice
        if [[ "$disk_choice" =~ ^[0-9]+$ ]] && [ "$disk_choice" -ge 1 ] && [ "$disk_choice" -le "${#DETECTED_DISKS[@]}" ]; then
            TARGET_DISK="${DETECTED_DISKS[$((disk_choice - 1))]}"
        fi
    elif [ ${#DETECTED_DISKS[@]} -eq 1 ]; then
        TARGET_DISK="${DETECTED_DISKS[0]}"
    fi
    echo -e "  ${GREEN}[+] Target Disk selected: ${TARGET_DISK}${RESET}\n"
}

# ── Print Image menu (alphabetical) ────────────────────────────────────────────────────────
print_iso_menu() {
    local -n _isos=$1
    local total=${#_isos[@]}

    echo -e "${CYAN}${BOLD}  ╔══════════════════════════════════════════════════════════════════════════════╗"
    echo -e "  ║               📀  Available ISO / IMG Images  (${total} total)               ║"
    echo -e "  ╚══════════════════════════════════════════════════════════════════════════════╝${RESET}"

    for i in "${!_isos[@]}"; do
        printf "  ${YELLOW}%3d${RESET}. %s\n" "$((i + 1))" "${_isos[$i]}"
    done

    echo -e "  ${DIM}  ─────────────────────────────────────────────────────────────────  Ctrl+C — stop QEMU  │  q — quit${RESET}"
}

# ══ MAIN ══════════════════════════════════════════════════════════════════════════════════════════

print_banner
check_deps
detect_kvm
select_disk
mount_remote

# Open VNC port in UFW if active
if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    ufw allow 5900/tcp comment 'QEMU VNC' >/dev/null 2>&1 || true
fi

while true; do

    mapfile -t ISOS < <(find "$MOUNT_POINT" -maxdepth 1 \( -iname "*.iso" -o -iname "*.img" \) -printf "%f\n" | sort -f)

    if [ ${#ISOS[@]} -eq 0 ]; then
        echo -e "${RED}[!] No ISO/IMG files found in ${MOUNT_POINT}${RESET}"
        exit 1
    fi

    print_iso_menu ISOS

    TOTAL=${#ISOS[@]}
    read -rp "$(echo -e "  ${BOLD}Select Image [1-${TOTAL}] or 'q' to quit: ${RESET}")" selection

    [[ "$selection" =~ ^[qQ]$ ]] && echo -e "\n${CYAN}[*] Exiting...${RESET}" && break

    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "$TOTAL" ]; then
        echo -e "${RED}[!] Invalid selection.${RESET}\n"
        continue
    fi

    SELECTED_ISO="${MOUNT_POINT}/${ISOS[$((selection - 1))]}"
    ISO_NAME="${ISOS[$((selection - 1))]}"

    [ ! -f "$SELECTED_ISO" ] && echo -e "${RED}[!] File not found: ${SELECTED_ISO}${RESET}" && continue

    echo -e "\n${GREEN}${BOLD}  ┃ 🚀 ${ISO_NAME}${RESET}"
    echo -e "  ${DIM}  KVM: ${KVM_FLAG:+enabled}${KVM_FLAG:-disabled (soft)}  |  Disk: ${TARGET_DISK} (IDE)  |  RAM: ${RAM_MB}MB  |  NIC: Intel e1000  |  VNC: 5900${RESET}\n"

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

    QEMU_PID=$!
    wait "$QEMU_PID"
    QEMU_PID=""
    echo -e "\n${CYAN}[*] QEMU session ended.${RESET}\n"
    sleep 1

done

# ── Cleanup ───────────────────────────────────────────────────────────────────────────────
read -rp "$(echo -e "${YELLOW}[?] Unmount ${MOUNT_POINT}? (y/n): ${RESET}")" unmount_choice
if [[ "$unmount_choice" =~ ^[Yy]$ ]]; then
    umount -lf "$MOUNT_POINT" 2>/dev/null
    fusermount -u "$MOUNT_POINT" 2>/dev/null
    rm -rf "$MOUNT_POINT"
    echo -e "${GREEN}[+] Unmounted and cleaned up.${RESET}"
fi

echo -e "\n${CYAN}${BOLD}= Rooted by VladiMIR + AI | v.2026.08.25 | github.com/GinCz =${RESET}\n"
