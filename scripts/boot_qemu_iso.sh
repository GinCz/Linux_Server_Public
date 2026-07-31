#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════════════════
#  boot_qemu_iso.sh
#
#  Description:
#    A GRML live-environment utility for remotely mounting an ISO image library from
#    SRV-DE (NetCup | 152.53.182.222) via SSHFS and booting any selected image inside
#    QEMU with full VirtIO disk passthrough and VNC remote console access.
#
#  Usage:
#    bash -c "$(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/boot_qemu_iso.sh)"
#
#  Controls:
#    [1-N]    Select ISO from the menu and boot it in QEMU
#    Ctrl+C   Kill the running QEMU session and return to the ISO menu
#    q        Quit the script gracefully (unmount prompt follows)
#
#  Target:    GRML live environment — run locally on bare metal
#  Remote:    SRV-DE NetCup | 152.53.182.222
#  Author:    VladiMIR + AI
#  GitHub:    github.com/GinCz
# ══════════════════════════════════════════════════════════════════════════════════════════

clear

# ── Colors ────────────────────────────────────────────────────────────────────────────────
RED='\033[0;31m';  GREEN='\033[0;32m';  YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

# ── Config ────────────────────────────────────────────────────────────────────────────────
SERVER_IP="152.53.182.222"
SSH_USER="root"
REMOTE_PATH="/storage/soft/ISO"
MOUNT_POINT="/mnt/iso_server"
TARGET_DISK="/dev/sda"
RAM_MB=4096
VNC_DISPLAY=":0"     # port 5900
QEMU_PID=""

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
    echo "  ║           🖥️  QEMU ISO Boot Launcher  🚀    github.com/GinCz           ║"
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
    # Lazy unmount handles "Transport endpoint is not connected" (stale FUSE)
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

# ── Print ISO menu (alphabetical) ──────────────────────────────────────────────────────────
print_iso_menu() {
    local -n _isos=$1
    local total=${#_isos[@]}

    echo -e "${CYAN}${BOLD}  ╔══════════════════════════════════════════════════════════════════════════════╗"
    echo -e "  ║                    📀  Available ISO Images  (${total} total)                     ║"
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
mount_remote

while true; do

    mapfile -t ISOS < <(find "$MOUNT_POINT" -maxdepth 1 -iname "*.iso" -printf "%f\n" | sort -f)

    if [ ${#ISOS[@]} -eq 0 ]; then
        echo -e "${RED}[!] No ISO files found in ${MOUNT_POINT}${RESET}"
        exit 1
    fi

    print_iso_menu ISOS

    TOTAL=${#ISOS[@]}
    read -rp "$(echo -e "  ${BOLD}Select ISO [1-${TOTAL}] or 'q' to quit: ${RESET}")" selection

    [[ "$selection" =~ ^[qQ]$ ]] && echo -e "\n${CYAN}[*] Exiting...${RESET}" && break

    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "$TOTAL" ]; then
        echo -e "${RED}[!] Invalid selection.${RESET}\n"
        continue
    fi

    SELECTED_ISO="${MOUNT_POINT}/${ISOS[$((selection - 1))]}"
    ISO_NAME="${ISOS[$((selection - 1))]}"

    [ ! -f "$SELECTED_ISO" ] && echo -e "${RED}[!] File not found: ${SELECTED_ISO}${RESET}" && continue

    echo -e "\n${GREEN}${BOLD}  ┃ 🚀 ${ISO_NAME}${RESET}"
    echo -e "  ${DIM}  KVM: ${KVM_FLAG:+enabled}${KVM_FLAG:-disabled (soft)}  |  Disk: ${TARGET_DISK}  |  RAM: ${RAM_MB}MB  |  VNC: 5900${RESET}\n"

    qemu-system-x86_64 \
        ${KVM_FLAG} \
        -m "$RAM_MB" \
        -boot d \
        -cdrom "$SELECTED_ISO" \
        -drive file="$TARGET_DISK",format=raw,if=virtio \
        -net nic,model=virtio \
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

echo -e "\n${CYAN}${BOLD}= Rooted by VladiMIR + AI | v.2026.07.31 | github.com/GinCz =${RESET}\n"
