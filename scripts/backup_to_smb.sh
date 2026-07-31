#!/bin/bash
# =============================================================================
# backup_to_smb.sh
# Clonezilla (ocs-sr) / Partclone disk image backup to SMB network share
#
# What it does:
#   1. Optionally changes the SSH root password
#   2. Installs clonezilla + cifs-utils if not present
#   3. Mounts the SMB share at /home/partimag
#   4. Runs ocs-sr to create a smart block-level NTFS-aware compressed backup
#      of the entire disk (sda) with parallel gzip compression (-z1p)
#      and splits into 4 GB chunks
#   5. Unmounts the SMB share on exit
#
# Usage:
#   bash backup_to_smb.sh
#
# Restore:
#   Boot target machine from Clonezilla/Rescuezilla Live USB,
#   mount the same SMB share to /home/partimag,
#   run: ocs-sr -g auto -e1 auto -e2 -r -j2 -p true restoredisk <FOLDER> sda
#
# Requirements:
#   - Ubuntu 20.04+ / Debian-based system
#   - Network access to SMB share (//s.gincz.com/soft/ISO)
#   - Root privileges
# =============================================================================
# = Rooted by VladiMIR + AI | v.2026.07.31 | github.com/GinCz =
# =============================================================================

clear

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ── Banner ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║         Clonezilla  →  SMB Backup Script                 ║"
echo "║         Rooted by VladiMIR + AI  |  github.com/GinCz    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Root check ────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] This script must be run as root.${NC}" >&2
    exit 1
fi

# ── SMB share settings ────────────────────────────────────────────────────────
SMB_HOST="//s.gincz.com/soft/ISO"
MOUNT_POINT="/home/partimag"
DISK="sda"
BACKUP_NAME="WinServer2016_Backup_$(date +%Y%m%d_%H%M)"

# ── Optional: change SSH root password ───────────────────────────────────────
echo -e "${YELLOW}[1/5] SSH password change (press Enter to skip)${NC}"
read -r -s -p "New SSH root password (blank = keep current): " SSH_PASS
echo
if [[ -n "$SSH_PASS" ]]; then
    echo "root:${SSH_PASS}" | chpasswd
    systemctl restart ssh 2>/dev/null || /etc/init.d/ssh restart
    echo -e "${GREEN}    SSH password updated and service restarted.${NC}"
else
    echo -e "    Skipped."
fi

# ── SMB credentials ───────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[2/5] SMB credentials for ${SMB_HOST}${NC}"
read -r -p "SMB Username: " SMB_USER
read -r -s -p "SMB Password: " SMB_PASS
echo

# ── Install dependencies ──────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[3/5] Installing clonezilla + cifs-utils (if needed)...${NC}"
apt-get update -qq
apt-get install -y clonezilla cifs-utils pigz -qq
echo -e "${GREEN}    Dependencies OK.${NC}"

# ── Mount SMB share ───────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[4/5] Mounting ${SMB_HOST} → ${MOUNT_POINT}${NC}"
mkdir -p "${MOUNT_POINT}"

# Unmount cleanly if already mounted from a previous run
if mountpoint -q "${MOUNT_POINT}"; then
    echo -e "    Already mounted, remounting..."
    umount -l "${MOUNT_POINT}"
fi

mount -t cifs "${SMB_HOST}" "${MOUNT_POINT}" \
    -o username="${SMB_USER}",password="${SMB_PASS}",vers=3.0,iocharset=utf8

echo -e "${GREEN}    Mounted successfully.${NC}"

# ── Cleanup trap ─────────────────────────────────────────────────────────────
cleanup() {
    echo -e "\n${YELLOW}[INFO] Flushing filesystem buffers and unmounting SMB share...${NC}"
    sync
    sleep 2
    umount -l "${MOUNT_POINT}" 2>/dev/null || true
    echo -e "${GREEN}[DONE] SMB share unmounted.${NC}"
}
trap cleanup EXIT

# ── Run Clonezilla backup ─────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[5/5] Starting Clonezilla backup...${NC}"
echo -e "    Disk     : ${BOLD}${DISK}${NC}"
echo -e "    Backup   : ${BOLD}${BACKUP_NAME}${NC}"
echo -e "    Target   : ${BOLD}${MOUNT_POINT}/${BACKUP_NAME}${NC}"
echo -e "    Options  : -z1p (parallel gzip), -i 4000 MB chunks, -j2 (parallel I/O)"
echo ""
echo -e "${RED}[WARNING] Do NOT interrupt this process. Full disk will be imaged.${NC}"
sleep 3

ocs-sr \
    -q2 \
    -c \
    -j2 \
    -z1p \
    -i 4000 \
    -sfsck \
    -senc \
    -p true \
    savedisk "${BACKUP_NAME}" "${DISK}"

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║  BACKUP COMPLETED SUCCESSFULLY!                          ║${NC}"
echo -e "${GREEN}${BOLD}║  Location: \\\\s.gincz.com\\soft\\ISO\\${BACKUP_NAME}  ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}To restore, boot from Clonezilla/Rescuezilla Live USB and run:${NC}"
echo -e "  mount -t cifs ${SMB_HOST} /home/partimag -o username=USER,password=PASS,vers=3.0"
echo -e "  ocs-sr -g auto -e1 auto -e2 -r -j2 -p true restoredisk ${BACKUP_NAME} sda"
echo ""
