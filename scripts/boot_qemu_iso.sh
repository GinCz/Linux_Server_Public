#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════════════════
#  boot_qemu_iso.sh
#
#  Description:
#    A GRML live-environment utility for remotely mounting an ISO image library from
#    SRV-DE (NetCup | 152.53.182.222) via SSHFS and booting any selected image inside
#    QEMU with full VirtIO disk passthrough and VNC remote console access.
#
#  How it works:
#    1. Checks and auto-installs missing dependencies (sshfs, qemu-system-x86, mc)
#    2. Auto-detects KVM support; attempts to load kvm_amd / kvm_intel kernel modules;
#       falls back to software emulation if the host does not allow nested virtualization
#    3. Mounts the remote ISO folder over SSHFS (one-time password prompt; stays mounted
#       between QEMU sessions — no need to re-authenticate)
#    4. Presents a categorized numbered menu of all .iso files found in the remote directory
#    5. Launches QEMU with the selected ISO as a CD-ROM boot device and /dev/sda passed
#       through via the VirtIO driver for maximum disk I/O performance
#    6. Exposes a VNC server on 0.0.0.0:5900 — connect with any VNC viewer
#       (UltraVNC, TigerVNC, RealVNC, etc.) from any machine on the network
#    7. After QEMU exits or is interrupted with Ctrl+C, automatically returns to the
#       ISO selection menu — no need to re-run the script to try another image
#    8. On quit ('q'), offers to cleanly unmount the SSHFS share
#
#  Usage:
#    bash -c "$(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/boot_qemu_iso.sh)"
#
#  Controls:
#    [1-N]    Select ISO from the menu and boot it in QEMU
#    Ctrl+C   Kill the running QEMU session and return to the ISO menu
#    q        Quit the script gracefully (unmount prompt follows)
#
#  Requirements:
#    - GRML or any Debian / Ubuntu live environment with internet access
#    - Network access to 152.53.182.222 on SSH port 22
#    - Root or sudo privileges (needed for modprobe, apt-get, sshfs)
#    - A VNC viewer on the client machine (port 5900)
#
#  Target:    GRML live environment — run locally on bare metal
#  Remote:    SRV-DE NetCup | 152.53.182.222
#  Author:    VladiMIR + AI
#  GitHub:    github.com/GinCz
# ══════════════════════════════════════════════════════════════════════════════════════════

clear

# ── Colors ────────────────────────────────────────────────────────────────────────────────
RED='\033[0;31m';    GREEN='\033[0;32m';   YELLOW='\033[1;33m'
CYAN='\033[0;36m';   BLUE='\033[0;34m';    MAGENTA='\033[0;35m'
WHITE='\033[1;37m';  BOLD='\033[1m';       DIM='\033[2m';  RESET='\033[0m'

# ── Config ────────────────────────────────────────────────────────────────────────────────
SERVER_IP="152.53.182.222"
SSH_USER="root"
REMOTE_PATH="/storage/soft/ISO"
MOUNT_POINT="/mnt/iso_server"
TARGET_DISK="/dev/sda"
RAM_MB=4096
VNC_DISPLAY=":0"     # port 5900

QEMU_PID=""

# ── ISO category definitions ──────────────────────────────────────────────────────────────
# Format: "KEYWORD|DISPLAY_CATEGORY"
# First matching keyword wins; unmatched files go to "Other"
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
        if [[ "$name_lc" == *"$key"* ]]; then
            echo "$key"
            return
        fi
    done
    echo "other"
}

# ── Ctrl+C handler ────────────────────────────────────────────────────────────────────────
trap_ctrlc() {
    echo -e "\n\n${YELLOW}[!] Ctrl+C detected — stopping QEMU...${RESET}"
    if [ -n "$QEMU_PID" ] && kill -0 "$QEMU_PID" 2>/dev/null; then
        kill "$QEMU_PID" 2>/dev/null
        wait "$QEMU_PID" 2>/dev/null
    fi
    QEMU_PID=""
    echo -e "${CYAN}[*] Returning to ISO selection menu...${RESET}\n"
    sleep 1
}
trap trap_ctrlc INT

# ── Banner ────────────────────────────────────────────────────────────────────────────────
print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                                  ║"
    echo "  ║   ██████  ██    ██ ███████ ███    ███  ██  ██████   ██████                       ║"
    echo "  ║  ██    ██ ██    ██ ██      ████  ████  ██ ██       ██    ██                      ║"
    echo "  ║  ██    ██ ██    ██ █████   ██ ████ ██  ██  ██████  ██    ██                      ║"
    echo "  ║  ██ ▄▄ ██ ██    ██ ██      ██  ██  ██  ██       ██ ██    ██                      ║"
    echo "  ║   ██████   ██████  ███████ ██      ██  ██  ██████   ██████                       ║"
    echo "  ║                                                                                  ║"
    echo "  ║                      🖥️  QEMU ISO Boot Launcher  🚀                              ║"
    echo "  ╠══════════════════════════════════════════════════════════════════════════════════╣"
    printf "  ║  🌐 Remote : %-20s  💾 Disk : %-10s  🧠 RAM: %s MB       ║\n" "$SERVER_IP" "$TARGET_DISK" "$RAM_MB"
    echo "  ║  📺 VNC    : 0.0.0.0:5900              🔑 User : root                           ║"
    echo "  ║  🔄 Ctrl+C : stop QEMU → back to menu  ❌  q   : quit & unmount                 ║"
    echo "  ╚══════════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

# ── Check and install dependencies ───────────────────────────────────────────────────────
check_deps() {
    echo -e "${YELLOW}[*] Checking dependencies...${RESET}"
    local pkg cmd ok=true
    for pkg in sshfs qemu-system-x86 mc; do
        cmd="${pkg%%-*}"
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo -e "  ${YELLOW}[!] Installing: ${pkg}${RESET}"
            apt-get update -qq && apt-get install -y "$pkg" >/dev/null 2>&1
            echo -e "  ${GREEN}[+] ${pkg} installed${RESET}"
        else
            echo -e "  ${GREEN}[+] ${pkg} — OK${RESET}"
        fi
    done
    echo
}

# ── KVM auto-detection ────────────────────────────────────────────────────────────────────
detect_kvm() {
    KVM_FLAG=""
    echo -e "${YELLOW}[*] Checking KVM availability...${RESET}"
    if [ ! -e /dev/kvm ]; then
        modprobe kvm       2>/dev/null
        modprobe kvm_amd   2>/dev/null || modprobe kvm_intel 2>/dev/null
    fi
    if [ -e /dev/kvm ]; then
        KVM_FLAG="-enable-kvm"
        echo -e "  ${GREEN}[+] KVM available — hardware acceleration enabled${RESET}"
    else
        echo -e "  ${YELLOW}[!] KVM not available — software emulation (slower)${RESET}"
    fi
    echo
}

# ── Mount remote ISO storage ──────────────────────────────────────────────────────────────
mount_remote() {
    mkdir -p "$MOUNT_POINT"
    if mountpoint -q "$MOUNT_POINT"; then
        echo -e "${GREEN}[+] Already mounted: ${MOUNT_POINT}${RESET}\n"
    else
        echo -e "${YELLOW}[*] Mounting ${SSH_USER}@${SERVER_IP}:${REMOTE_PATH}${RESET}"
        echo -e "${CYAN}    Enter root password for ${SERVER_IP}:${RESET}"
        sshfs "${SSH_USER}@${SERVER_IP}:${REMOTE_PATH}" "$MOUNT_POINT"
        if [ $? -ne 0 ]; then
            echo -e "${RED}[!] ERROR: Failed to mount SSHFS. Check credentials or network.${RESET}"
            exit 1
        fi
        echo -e "${GREEN}[+] Mounted successfully → ${MOUNT_POINT}${RESET}\n"
    fi
}

# ── Print categorized ISO menu ────────────────────────────────────────────────────────────
print_iso_menu() {
    local -n _isos=$1
    local -n _idx_map=$2

    echo -e "${CYAN}${BOLD}  ╔══════════════════════════════════════════════════════════════════════════════════╗"
    echo -e "  ║                           📀  Available ISO Images                             ║"
    echo -e "  ╚══════════════════════════════════════════════════════════════════════════════════╝${RESET}"

    declare -A cat_items
    for i in "${!_isos[@]}"; do
        local iso="${_isos[$i]}"
        local ckey
        ckey=$(get_category_key "$iso")
        cat_items[$ckey]+="$i "
    done

    local num=0
    declare -g IDX_TO_ISO=()

    # Print known categories in order
    for ckey in "${CAT_ORDER[@]}" other; do
        [ -z "${cat_items[$ckey]+x}" ] && continue
        local label="${CAT_LABELS[$ckey]:-📁  Other}"
        [ "$ckey" = "other" ] && label="📁  Other"
        echo -e "\n  ${MAGENTA}${BOLD}  ${label}${RESET}"
        echo -e "  ${DIM}  ─────────────────────────────────────────────────────────────────────────────${RESET}"
        for orig_i in ${cat_items[$ckey]}; do
            num=$((num + 1))
            IDX_TO_ISO[$num]="$orig_i"
            printf "  ${YELLOW}  %2d${RESET}. %s\n" "$num" "${_isos[$orig_i]}"
        done
    done

    echo -e "\n  ${CYAN}  ──────────────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${DIM}  Total: ${#_isos[@]} images  │  Ctrl+C — stop QEMU and return here  │  q — quit${RESET}"
    echo
}

# ══════════════════════════════════════════════════════════════════════════════════════════
# ── MAIN ─────────────────────────────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════════════════

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

    declare -A IDX_TO_ISO
    print_iso_menu ISOS IDX_TO_ISO

    TOTAL=${#IDX_TO_ISO[@]}
    read -rp "$(echo -e "  ${BOLD}Select ISO [1-${TOTAL}] or 'q' to quit: ${RESET}")" selection

    # Quit
    if [[ "$selection" =~ ^[qQ]$ ]]; then
        echo -e "\n${CYAN}[*] Exiting...${RESET}"
        break
    fi

    # Validate
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || \
       [ "$selection" -lt 1 ] || \
       [ "$selection" -gt "$TOTAL" ]; then
        echo -e "${RED}[!] Invalid selection. Try again.${RESET}\n"
        continue
    fi

    ORIG_IDX="${IDX_TO_ISO[$selection]}"
    SELECTED_ISO="${MOUNT_POINT}/${ISOS[$ORIG_IDX]}"
    ISO_NAME="${ISOS[$ORIG_IDX]}"

    if [ ! -f "$SELECTED_ISO" ]; then
        echo -e "${RED}[!] File not found: ${SELECTED_ISO}${RESET}"
        continue
    fi

    # ── Launch QEMU ───────────────────────────────────────────────────────────────────────
    echo -e "\n${GREEN}${BOLD}  ╔══════════════════════════════════════════════════════╗"
    printf   "  ║  🚀 Booting: %-40s║\n" "$ISO_NAME"
    echo -e  "  ╠══════════════════════════════════════════════════════╣"
    printf   "  ║  ⚡ Mode  : %-40s║\n" "${KVM_FLAG:+KVM hardware acceleration}"
    [ -z "$KVM_FLAG" ] && printf "  ║  ⚡ Mode  : %-40s║\n" "Software emulation"
    printf   "  ║  💾 Disk  : %-40s║\n" "${TARGET_DISK} (VirtIO)"
    printf   "  ║  🧠 RAM   : %-40s║\n" "${RAM_MB} MB"
    printf   "  ║  📺 VNC   : %-40s║\n" "0.0.0.0:5900 → connect with VNC viewer"
    echo -e  "  ╚══════════════════════════════════════════════════════╝${RESET}\n"

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

    echo -e "\n${CYAN}[*] QEMU session ended. Returning to menu...${RESET}\n"
    sleep 1

done

# ── Cleanup ───────────────────────────────────────────────────────────────────────────────
read -rp "$(echo -e "${YELLOW}[?] Unmount ${MOUNT_POINT}? (y/n): ${RESET}")" unmount_choice
if [[ "$unmount_choice" =~ ^[Yy]$ ]]; then
    umount "$MOUNT_POINT" && \
    echo -e "${GREEN}[+] Unmounted successfully.${RESET}" || \
    echo -e "${RED}[!] Unmount failed. Try: fusermount -u ${MOUNT_POINT}${RESET}"
fi

echo -e "\n${CYAN}${BOLD}= Rooted by VladiMIR + AI | v.2026.07.30 | github.com/GinCz =${RESET}\n"
