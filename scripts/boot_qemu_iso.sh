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
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

# ── Config ───────────────────────────────────────────────────────═───────────────────────
SERVER_IP="152.53.182.222"
SSH_USER="root"
REMOTE_PATH="/storage/soft/ISO"
MOUNT_POINT="/mnt/iso_server"
TARGET_DISK="/dev/sda"
RAM_MB=4096
VNC_DISPLAY=":0"       # port 5900
VNC_WIDTH=1280
VNC_HEIGHT=1024
QEMU_PID=""

# ── ISO category definitions ──────────────────────────────────────────────────────────────
declare -A CAT_LABELS=(
    [anduin]="🐧  AnduinOS"
    [aomei]="💾  AOMEI Backup"
    [acronis]="🛡️   Acronis"
    [porteus]="🧩  Porteus"
    [q4os]="🖥️   Q4OS"
    [rescatux]="🚑  RescaTux"
    [runtu]="🐧  Runtu Linux"
    [win]="🪟  Windows PE"
)
CAT_ORDER=(anduin aomei acronis porteus q4os rescatux runtu win)

get_category_key() {
    local name_lc
    name_lc=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    for key in "${CAT_ORDER[@]}"; do
        [[ "$name_lc" == *"$key"* ]] && echo "$key" && return
    done
    echo "other"
}

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
    printf "  ║  🌐 %-18s  💾 %-10s  🧠 RAM: %-4sMB  📺 VNC: 5900 (%dx%d)  ║\n" \
        "$SERVER_IP" "$TARGET_DISK" "$RAM_MB" "$VNC_WIDTH" "$VNC_HEIGHT"
    echo "  ╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

# ── Check and install dependencies ──────────────────────────────────────────────────────
check_deps() {
    echo -e "${YELLOW}[*] Checking dependencies...${RESET}"
    for pkg in sshfs qemu-system-x86 mc; do
        if ! command -v "${pkg%%-*}" >/dev/null 2>&1; then
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

# ── Mount remote ISO storage ──────────────────────────────────────────────────────────────
mount_remote() {
    mkdir -p "$MOUNT_POINT"
    if mountpoint -q "$MOUNT_POINT"; then
        echo -e "  ${GREEN}[+] Already mounted: ${MOUNT_POINT}${RESET}"
    else
        echo -e "  ${YELLOW}[*] Mounting ${SSH_USER}@${SERVER_IP}:${REMOTE_PATH}${RESET}"
        echo -e "  ${CYAN}    Enter root password for ${SERVER_IP}:${RESET}"
        sshfs -o StrictHostKeyChecking=no,reconnect \
            "${SSH_USER}@${SERVER_IP}:${REMOTE_PATH}" "$MOUNT_POINT"
        if [ $? -ne 0 ]; then
            echo -e "  ${RED}[!] ERROR: SSHFS mount failed.${RESET}"
            exit 1
        fi
        echo -e "  ${GREEN}[+] Mounted → ${MOUNT_POINT}${RESET}"
    fi
    echo
}

# ── Print categorized ISO menu ────────────────────────────────────────────────────────────
print_iso_menu() {
    local -n _isos=$1

    declare -A cat_items
    for i in "${!_isos[@]}"; do
        local ckey
        ckey=$(get_category_key "${_isos[$i]}")
        cat_items[$ckey]+="$i "
    done

    local num=0
    declare -gA IDX_TO_ISO=()

    echo -e "${CYAN}${BOLD}  ╔══════════════════════════════════════════════════════════════════════════════╗"
    echo -e "  ║                       📀  Available ISO Images  (${#_isos[@]} total)                  ║"
    echo -e "  ╚══════════════════════════════════════════════════════════════════════════════╝${RESET}"

    for ckey in "${CAT_ORDER[@]}" other; do
        [ -z "${cat_items[$ckey]+x}" ] && continue
        local label="${CAT_LABELS[$ckey]:-📁  Other}"
        [ "$ckey" = "other" ] && label="📁  Other"
        echo -e "  ${MAGENTA}${BOLD} ${label}${RESET}"
        for orig_i in ${cat_items[$ckey]}; do
            num=$((num + 1))
            IDX_TO_ISO[$num]="$orig_i"
            printf "  ${YELLOW}  %2d${RESET}. %s\n" "$num" "${_isos[$orig_i]}"
        done
    done
    echo -e "  ${DIM}  ────────────────────────────────────────────────────────────────────────────  Ctrl+C — stop QEMU  │  q — quit${RESET}"
}

# ══ MAIN ══════════════════════════════════════════════════════════════════════════════════════════

print_banner
check_deps
detect_kvm
mount_remote

while true; do

    mapfile -t ISOS < <(find "$MOUNT_POINT" -maxdepth 1 -iname "*.iso" -printf "%f\n" | sort)

    if [ ${#ISOS[@]} -eq 0 ]; then
        echo -e "${RED}[!] No ISO files found in ${MOUNT_POINT}${RESET}"
        exit 1
    fi

    print_iso_menu ISOS

    TOTAL=${#IDX_TO_ISO[@]}
    read -rp "$(echo -e "  ${BOLD}Select ISO [1-${TOTAL}] or 'q' to quit: ${RESET}")" selection

    [[ "$selection" =~ ^[qQ]$ ]] && echo -e "\n${CYAN}[*] Exiting...${RESET}" && break

    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "$TOTAL" ]; then
        echo -e "${RED}[!] Invalid selection.${RESET}\n"
        continue
    fi

    ORIG_IDX="${IDX_TO_ISO[$selection]}"
    SELECTED_ISO="${MOUNT_POINT}/${ISOS[$ORIG_IDX]}"
    ISO_NAME="${ISOS[$ORIG_IDX]}"

    [ ! -f "$SELECTED_ISO" ] && echo -e "${RED}[!] File not found: ${SELECTED_ISO}${RESET}" && continue

    echo -e "\n${GREEN}${BOLD}  ┃ 🚀 ${ISO_NAME}${RESET}"
    echo -e "  ${DIM}  KVM: ${KVM_FLAG:+enabled}${KVM_FLAG:-disabled (soft)}  |  Disk: ${TARGET_DISK}  |  RAM: ${RAM_MB}MB  |  VNC: 5900 (${VNC_WIDTH}x${VNC_HEIGHT})${RESET}\n"

    # -device VGA with xres/yres sets the initial framebuffer resolution
    # virtio-vga supports dynamic resize; fallback: -vga std with -global
    qemu-system-x86_64 \
        ${KVM_FLAG} \
        -m "$RAM_MB" \
        -boot d \
        -cdrom "$SELECTED_ISO" \
        -drive file="$TARGET_DISK",format=raw,if=virtio \
        -device VGA,vgamem_mb=16,xres=${VNC_WIDTH},yres=${VNC_HEIGHT} \
        -net nic,model=virtio \
        -net user \
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
    umount "$MOUNT_POINT" 2>/dev/null || fusermount -u "$MOUNT_POINT" 2>/dev/null
    echo -e "${GREEN}[+] Unmounted.${RESET}"
fi

echo -e "\n${CYAN}${BOLD}= Rooted by VladiMIR + AI | v.2026.07.31 | github.com/GinCz =${RESET}\n"
