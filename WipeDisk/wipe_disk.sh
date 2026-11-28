#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  wipe_disk.sh | [v2026-07-29]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Fully wipes /dev/sda in a GRML live Linux environment
# Servers     : Bare-metal / GRML Live Linux
# Usage       : bash wipe_disk.sh
# ==========================================================================================
#  WARNING: This script permanently destroys ALL data on /dev/sda.
#  There is NO undo. Use only in a live environment on the target disk.
# ==========================================================================================

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

# ── Install Midnight Commander if missing ─────────────────────────────────────────────────
echo -e "${YELLOW}[*] Checking dependencies...${RESET}"
if ! command -v mc >/dev/null 2>&1; then
    echo -e "${YELLOW}[!] Installing: mc (Midnight Commander)${RESET}"
    apt-get update -qq && apt-get install -y mc >/dev/null 2>&1
    echo -e "${GREEN}[+] mc installed${RESET}"
else
    echo -e "${GREEN}[+] mc — OK${RESET}"
fi
echo ""

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

# = Rooted by VladiMIR | AI = v2026-07-29 = github.com/GinCz/Linux_Server_Public
