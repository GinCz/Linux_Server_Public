#!/bin/bash
# ============================================================
#  boot_qemu_iso.sh
#
#  Description:
#    A GRML live-environment utility for remotely mounting an
#    ISO image library from SRV-DE (NetCup) via SSHFS and
#    booting any selected image inside QEMU with full VirtIO
#    disk passthrough and VNC remote console access.
#
#  How it works:
#    1. Checks and installs missing dependencies (sshfs, qemu)
#    2. Auto-detects KVM support; falls back to software
#       emulation if the host does not allow nested virt
#    3. Mounts the remote ISO folder over SSHFS (one-time,
#       stays mounted between sessions)
#    4. Presents a numbered menu of all .iso files found
#    5. Launches QEMU with the selected ISO as a CD-ROM boot
#       device and /dev/sda passed through via VirtIO driver
#    6. Exposes a VNC server on 0.0.0.0:5900 — connect with
#       any VNC viewer (UltraVNC, TigerVNC, RealVNC, etc.)
#    7. After QEMU exits (or Ctrl+C), returns to the ISO menu
#       — no need to re-run the script to try another image
#    8. On quit ('q'), offers to unmount the SSHFS share
#
#  Usage:
#    bash -c "$(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/boot_qemu_iso.sh)"
#
#  Controls:
#    [1-N]   Select ISO from menu and boot it
#    Ctrl+C  Kill running QEMU session, return to menu
#    q       Quit the script (unmount prompt follows)
#
#  Requirements:
#    - GRML or any Debian/Ubuntu live environment
#    - Network access to 152.53.182.222 (SSH port 22)
#    - Root or sudo privileges
#    - VNC viewer on the client machine
#
#  Target:   GRML live environment (run locally on bare metal)
#  Remote:   SRV-DE NetCup | 152.53.182.222
#  Author:   VladiMIR + AI
#  GitHub:   github.com/GinCz
# ============================================================

clear

# ── Colors ────────────────────────────────────────────────
RED='\033[0;31m';  GREEN='\033[0;32m';  YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m';      RESET='\033[0m'

# ── Config ────────────────────────────────────────────────
SERVER_IP="152.53.182.222"
SSH_USER="root"
REMOTE_PATH="/storage/soft/ISO"
MOUNT_POINT="/mnt/iso_server"
TARGET_DISK="/dev/sda"
RAM_MB=4096
VNC_DISPLAY=":0"     # port 5900

QEMU_PID=""

# ── Ctrl+C handler ────────────────────────────────────────
# Kills the running QEMU process and returns to ISO menu
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

# ── Banner ────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║           QEMU ISO Boot Launcher             ║"
echo "  ║   Remote: ${SERVER_IP}              ║"
echo "  ║   VNC port: 5900  |  RAM: ${RAM_MB} MB          ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${RESET}"

# ── Check dependencies ────────────────────────────────────
echo -e "${YELLOW}[*] Checking dependencies...${RESET}"

for pkg in sshfs qemu-system-x86; do
    if ! command -v "${pkg%%-*}" >/dev/null 2>&1; then
        echo -e "${YELLOW}[!] Installing: ${pkg}${RESET}"
        apt-get update -qq && apt-get install -y "$pkg" >/dev/null 2>&1
        echo -e "${GREEN}[+] ${pkg} installed${RESET}"
    else
        echo -e "${GREEN}[+] ${pkg} — OK${RESET}"
    fi
done

# ── KVM auto-detection ────────────────────────────────────
KVM_FLAG=""
echo -e "\n${YELLOW}[*] Checking KVM availability...${RESET}"

if [ ! -e /dev/kvm ]; then
    modprobe kvm       2>/dev/null
    modprobe kvm_amd   2>/dev/null || modprobe kvm_intel 2>/dev/null
fi

if [ -e /dev/kvm ]; then
    KVM_FLAG="-enable-kvm"
    echo -e "${GREEN}[+] KVM available — hardware acceleration enabled${RESET}"
else
    echo -e "${YELLOW}[!] KVM not available — falling back to software emulation${RESET}"
    echo -e "${YELLOW}    (slower, but guaranteed to work on any host)${RESET}"
fi

# ── Mount remote ISO storage ──────────────────────────────
mkdir -p "$MOUNT_POINT"

if mountpoint -q "$MOUNT_POINT"; then
    echo -e "${GREEN}[+] Already mounted: ${MOUNT_POINT}${RESET}"
else
    echo -e "\n${YELLOW}[*] Mounting ${SSH_USER}@${SERVER_IP}:${REMOTE_PATH}${RESET}"
    echo -e "${CYAN}    Enter root password for ${SERVER_IP}:${RESET}"
    sshfs "${SSH_USER}@${SERVER_IP}:${REMOTE_PATH}" "$MOUNT_POINT"

    if [ $? -ne 0 ]; then
        echo -e "${RED}[!] ERROR: Failed to mount SSHFS. Check credentials or network.${RESET}"
        exit 1
    fi
    echo -e "${GREEN}[+] Mounted successfully → ${MOUNT_POINT}${RESET}"
fi

# ── Main loop — ISO menu + QEMU launch ────────────────────
while true; do

    # Rebuild list on every iteration (picks up any new files)
    mapfile -t ISOS < <(find "$MOUNT_POINT" -maxdepth 1 -iname "*.iso" -printf "%f\n" | sort)

    if [ ${#ISOS[@]} -eq 0 ]; then
        echo -e "${RED}[!] No ISO files found in ${MOUNT_POINT}${RESET}"
        exit 1
    fi

    echo -e "\n${CYAN}${BOLD}  ┌──────────────────────────────────────────────┐"
    echo -e "  │              Available ISO Images            │"
    echo -e "  └──────────────────────────────────────────────┘${RESET}"

    for i in "${!ISOS[@]}"; do
        printf "  ${YELLOW}%2d${RESET}. %s\n" "$((i+1))" "${ISOS[$i]}"
    done

    echo -e "${CYAN}  ────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}Ctrl+C — stop QEMU and return here at any time${RESET}"
    read -rp "$(echo -e "  ${BOLD}Select ISO [1-${#ISOS[@]}] or 'q' to quit: ${RESET}")" selection

    # Quit
    if [[ "$selection" =~ ^[qQ]$ ]]; then
        echo -e "\n${CYAN}[*] Exiting...${RESET}"
        break
    fi

    # Validate
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || \
       [ "$selection" -lt 1 ] || \
       [ "$selection" -gt "${#ISOS[@]}" ]; then
        echo -e "${RED}[!] Invalid selection. Try again.${RESET}"
        continue
    fi

    SELECTED_ISO="${MOUNT_POINT}/${ISOS[$((selection-1))]}"

    if [ ! -f "$SELECTED_ISO" ]; then
        echo -e "${RED}[!] File not found: ${SELECTED_ISO}${RESET}"
        continue
    fi

    # ── Launch QEMU ───────────────────────────────────────
    echo -e "\n${GREEN}${BOLD}[>] Booting:${RESET} ${ISOS[$((selection-1))]}"
    echo -e "${YELLOW}    Mode   : ${KVM_FLAG:+KVM hardware}${KVM_FLAG:-Software emulation}${RESET}"
    echo -e "${YELLOW}    Disk   : ${TARGET_DISK} (VirtIO)${RESET}"
    echo -e "${YELLOW}    RAM    : ${RAM_MB} MB${RESET}"
    echo -e "${YELLOW}    Audio  : disabled${RESET}"
    echo -e "${YELLOW}    VNC    : 0.0.0.0:5900  →  connect with VNC viewer${RESET}"
    echo -e "${YELLOW}    Tip    : Press Ctrl+C to stop and return to menu${RESET}\n"

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

    echo -e "\n${CYAN}[*] QEMU session ended.${RESET}"

done

# ── Cleanup ───────────────────────────────────────────────
read -rp "$(echo -e "${YELLOW}[?] Unmount ${MOUNT_POINT}? (y/n): ${RESET}")" unmount_choice
if [[ "$unmount_choice" =~ ^[Yy]$ ]]; then
    umount "$MOUNT_POINT" && \
    echo -e "${GREEN}[+] Unmounted successfully.${RESET}" || \
    echo -e "${RED}[!] Unmount failed. Try: fusermount -u ${MOUNT_POINT}${RESET}"
fi

echo -e "\n${CYAN}${BOLD}= Rooted by VladiMIR + AI | v.2026.07.27 | github.com/GinCz =${RESET}\n"
