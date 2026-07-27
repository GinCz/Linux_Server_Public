#!/bin/bash
# ============================================================
#  boot_qemu_iso.sh
#  Description : Mount remote ISO storage via SSHFS and boot
#                selected ISO image in QEMU with auto KVM detect
#  Target      : GRML live environment (run locally)
#  Remote      : SRV-DE NetCup | 152.53.182.222
#  Author      : VladiMIR + AI
#  GitHub      : github.com/GinCz
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
    # Try to load KVM kernel modules (AMD first, then Intel)
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

# ── Build dynamic ISO list ────────────────────────────────
mapfile -t ISOS < <(find "$MOUNT_POINT" -maxdepth 1 -iname "*.iso" -printf "%f\n" | sort)

if [ ${#ISOS[@]} -eq 0 ]; then
    echo -e "${RED}[!] No ISO files found in ${MOUNT_POINT}${RESET}"
    exit 1
fi

# ── ISO selection menu ────────────────────────────────────
echo -e "\n${CYAN}${BOLD}  ┌──────────────────────────────────────────────┐"
echo -e "  │              Available ISO Images            │"
echo -e "  └──────────────────────────────────────────────┘${RESET}"

for i in "${!ISOS[@]}"; do
    printf "  ${YELLOW}%2d${RESET}. %s\n" "$((i+1))" "${ISOS[$i]}"
done

echo -e "${CYAN}  ────────────────────────────────────────────────${RESET}"
read -rp "$(echo -e "  ${BOLD}Select ISO [1-${#ISOS[@]}]: ${RESET}")" selection

if ! [[ "$selection" =~ ^[0-9]+$ ]] || \
   [ "$selection" -lt 1 ] || \
   [ "$selection" -gt "${#ISOS[@]}" ]; then
    echo -e "${RED}[!] Invalid selection. Exiting.${RESET}"
    exit 1
fi

SELECTED_ISO="${MOUNT_POINT}/${ISOS[$((selection-1))]}"

if [ ! -f "$SELECTED_ISO" ]; then
    echo -e "${RED}[!] File not found: ${SELECTED_ISO}${RESET}"
    exit 1
fi

# ── Launch QEMU ───────────────────────────────────────────
echo -e "\n${GREEN}${BOLD}[>] Booting:${RESET} ${ISOS[$((selection-1))]}"
echo -e "${YELLOW}    Mode   : ${KVM_FLAG:+KVM hardware}${KVM_FLAG:-Software emulation}${RESET}"
echo -e "${YELLOW}    Disk   : ${TARGET_DISK} (VirtIO)${RESET}"
echo -e "${YELLOW}    RAM    : ${RAM_MB} MB${RESET}"
echo -e "${YELLOW}    VNC    : 0.0.0.0:5900  →  connect with VNC viewer${RESET}\n"

qemu-system-x86_64 \
    ${KVM_FLAG} \
    -m "$RAM_MB" \
    -boot d \
    -cdrom "$SELECTED_ISO" \
    -drive file="$TARGET_DISK",format=raw,if=virtio \
    -net nic,model=virtio \
    -net user \
    -vga std \
    -vnc "0.0.0.0${VNC_DISPLAY}"

echo -e "\n${CYAN}[*] QEMU session ended.${RESET}"

# ── Cleanup ───────────────────────────────────────────────
read -rp "$(echo -e "${YELLOW}[?] Unmount ${MOUNT_POINT}? (y/n): ${RESET}")" unmount_choice
if [[ "$unmount_choice" =~ ^[Yy]$ ]]; then
    umount "$MOUNT_POINT" && \
    echo -e "${GREEN}[+] Unmounted successfully.${RESET}" || \
    echo -e "${RED}[!] Unmount failed. Try: fusermount -u ${MOUNT_POINT}${RESET}"
fi

echo -e "\n${CYAN}${BOLD}= Rooted by VladiMIR + AI | v.2026.07.27 | github.com/GinCz =${RESET}\n"
