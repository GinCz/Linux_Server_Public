#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════════════════
#  wipe_disk.sh
#
#  Description:
#    Fully wipes /dev/sda in a GRML (or any live Linux) environment.
#    Unmounts all partitions, removes filesystem signatures via wipefs,
#    overwrites the first 1 MB with zeros via dd, and creates a fresh
#    empty MBR partition table via parted — leaving the disk completely
#    clean and ready for a new OS installation or disk imaging.
#
#  ⚠  WARNING: This script permanently destroys ALL data on /dev/sda.
#     There is NO undo. Use only in a live environment on the target disk.
#
#  Usage (GRML live environment):
#    bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/wipe_disk.sh)
#
#  What it does:
#    1. Displays current disk layout (lsblk) and asks for explicit confirmation
#    2. Unmounts all partitions on /dev/sda (errors ignored — live env)
#    3. wipefs -a  — removes all filesystem/partition-table signatures
#    4. dd         — zeros the first 1 MB (MBR + partition table area)
#    5. parted     — writes a fresh empty MBR (msdos) partition table
#    6. partprobe  — notifies the kernel about the new partition table
#    7. Reports final disk state via lsblk
#
#  Requirements:
#    - GRML or any Debian / Ubuntu live environment
#    - Root privileges
#    - wipefs, dd, parted (pre-installed in GRML)
#
#  Target:  Any bare-metal server without ISO boot / KVM console access
#  Author:  VladiMIR + AI
#  GitHub:  github.com/GinCz
# ══════════════════════════════════════════════════════════════════════════════════════════

clear

# ── Colors ────────────────────────────────────────────────────────────────────────────────
RED='\033[0;31m';  GREEN='\033[0;32m';  YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m';      RESET='\033[0m'

# ── Config ────────────────────────────────────────────────────────────────────────────────
DISK="/dev/sda"

# ── Banner ────────────────────────────────────────────────────────────────────────────────
echo -e "${RED}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════════════════════════════════╗"
echo "  ║                          ⚠  DISK WIPE UTILITY  ⚠                               ║"
echo "  ║                                                                                 ║"
echo "  ║       Target: ${DISK}     │   wipefs + dd + parted msdos                    ║"
echo "  ║       ALL DATA WILL BE PERMANENTLY AND IRREVERSIBLY DESTROYED                  ║"
echo "  ╚══════════════════════════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ── Show current disk state ───────────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[*] Current disk layout:${RESET}"
lsblk "${DISK}"
echo ""

# ── Confirmation ─────────────────────────────────────────────────────────────────────────
echo -e "${YELLOW}[!] You are about to PERMANENTLY DESTROY all data on ${BOLD}${DISK}${RESET}${YELLOW}.${RESET}"
echo -e "${YELLOW}    This action cannot be undone.${RESET}\n"
read -rp "$(echo -e "${RED}${BOLD}    Type YES to confirm wipe of ${DISK}: ${RESET}")" confirm

if [ "${confirm}" != "YES" ]; then
    echo -e "\n${GREEN}[+] Aborted. No changes made.${RESET}"
    exit 0
fi

echo ""

# ── Step 1: Unmount all partitions ───────────────────────────────────────────────────────
echo -e "${YELLOW}[1/4] Unmounting all partitions on ${DISK}...${RESET}"
umount ${DISK}?* 2>/dev/null || true
umount ${DISK}*  2>/dev/null || true
echo -e "${GREEN}      Done (errors suppressed — live env).${RESET}\n"

# ── Step 2: Remove filesystem signatures ─────────────────────────────────────────────────
echo -e "${YELLOW}[2/4] Removing filesystem signatures (wipefs -a)...${RESET}"
wipefs -a "${DISK}"
echo -e "${GREEN}      Signatures cleared.${RESET}\n"

# ── Step 3: Zero first 1 MB ──────────────────────────────────────────────────────────────
echo -e "${YELLOW}[3/4] Zeroing first 1 MB — MBR + partition table area (dd)...${RESET}"
dd if=/dev/zero of="${DISK}" bs=512 count=2048 2>/dev/null
echo -e "${GREEN}      First 1 MB zeroed.${RESET}\n"

# ── Step 4: Write empty MBR partition table ───────────────────────────────────────────────
echo -e "${YELLOW}[4/4] Writing empty MBR partition table (parted msdos)...${RESET}"
parted "${DISK}" --script mklabel msdos
partprobe "${DISK}" 2>/dev/null
sleep 1
echo -e "${GREEN}      MBR table written.${RESET}\n"

# ── Result ────────────────────────────────────────────────────────────────────────────────
echo -e "${GREEN}${BOLD}  ╔══════════════════════════════════════════════════════════════════════════════════╗"
echo -e "  ║  ✓  ${DISK} has been fully wiped and is ready for a new installation.         ║"
echo -e "  ╚══════════════════════════════════════════════════════════════════════════════════╝${RESET}\n"

lsblk "${DISK}"

echo -e "\n${CYAN}${BOLD}= Rooted by VladiMIR + AI | v.2026.07.29 | github.com/GinCz =${RESET}\n"
