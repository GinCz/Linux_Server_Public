#!/bin/bash
# =============================================================================
# backup_to_smb.sh
# Clonezilla (ocs-sr) / Partclone — Backup & Restore via SMB network share
#
# Modes:
#   BACKUP  — saves full disk image to \\s.gincz.com\soft\ISO
#             automatically removes pagefile.sys from all NTFS partitions
#             before imaging to reduce backup size
#   RESTORE — lists available backups on the SMB share,
#             lets you pick one and restores it to sda
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
RED='\033[0;31m'   GREEN='\033[0;32m'   YELLOW='\033[1;33m'
CYAN='\033[0;36m'  BOLD='\033[1m'       NC='\033[0m'

# ── Banner ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║     Clonezilla  ↔  SMB  Backup & Restore Script         ║"
echo "║     Rooted by VladiMIR + AI  |  github.com/GinCz       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Root check ────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] This script must be run as root.${NC}" >&2
    exit 1
fi

# ── Config ────────────────────────────────────────────────────────────────────
SMB_HOST="//s.gincz.com/soft/ISO"
MOUNT_POINT="/home/partimag"
DISK="sda"

# ── Mode selection ────────────────────────────────────────────────────────────
echo -e "${BOLD}Select operation mode:${NC}"
echo -e "  ${GREEN}[1]${NC} BACKUP   — create new disk image on SMB share"
echo -e "  ${CYAN}[2]${NC} RESTORE  — restore disk from existing image on SMB share"
echo ""
read -r -p "Enter 1 or 2: " MODE_CHOICE
echo ""

if [[ "$MODE_CHOICE" != "1" && "$MODE_CHOICE" != "2" ]]; then
    echo -e "${RED}[ERROR] Invalid choice. Exiting.${NC}"
    exit 1
fi

# ── Optional: change SSH root password ───────────────────────────────────────
echo -e "${YELLOW}[STEP 1] SSH password change (press Enter to skip)${NC}"
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
echo -e "${YELLOW}[STEP 2] SMB credentials for ${SMB_HOST}${NC}"
read -r -p "SMB Username: " SMB_USER
read -r -s -p "SMB Password: " SMB_PASS
echo

# ── Install dependencies ──────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[STEP 3] Installing clonezilla + cifs-utils + pigz (if needed)...${NC}"
apt-get update -qq
apt-get install -y clonezilla cifs-utils pigz ntfs-3g -qq
echo -e "${GREEN}    Dependencies OK.${NC}"

# ── Mount SMB share ───────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[STEP 4] Mounting ${SMB_HOST} → ${MOUNT_POINT}${NC}"
mkdir -p "${MOUNT_POINT}"

if mountpoint -q "${MOUNT_POINT}"; then
    echo -e "    Already mounted, remounting..."
    umount -l "${MOUNT_POINT}"
fi

mount -t cifs "${SMB_HOST}" "${MOUNT_POINT}" \
    -o username="${SMB_USER}",password="${SMB_PASS}",vers=3.0,iocharset=utf8
echo -e "${GREEN}    Mounted successfully.${NC}"

# ── Cleanup trap ─────────────────────────────────────────────────────────────
cleanup() {
    echo -e "\n${YELLOW}[INFO] Flushing buffers and unmounting SMB share...${NC}"
    sync
    sleep 2
    # Unmount NTFS temp mounts if any are left
    for mp in /mnt/ntfs_part_*; do
        mountpoint -q "$mp" 2>/dev/null && umount -l "$mp" 2>/dev/null || true
    done
    umount -l "${MOUNT_POINT}" 2>/dev/null || true
    echo -e "${GREEN}[DONE] Cleanup complete.${NC}"
}
trap cleanup EXIT

# =============================================================================
# MODE: BACKUP
# =============================================================================
if [[ "$MODE_CHOICE" == "1" ]]; then

    BACKUP_NAME="WinServer2016_Backup_$(date +%Y%m%d_%H%M)"

    # ── Remove pagefile.sys from all NTFS partitions ─────────────────────────
    echo ""
    echo -e "${YELLOW}[STEP 5] Searching for pagefile.sys on NTFS partitions of /dev/${DISK}...${NC}"

    NTFS_PARTS=$(lsblk -rno NAME,FSTYPE "/dev/${DISK}" 2>/dev/null | awk '$2=="ntfs" {print $1}')

    if [[ -z "$NTFS_PARTS" ]]; then
        echo -e "    No NTFS partitions found on /dev/${DISK}, skipping pagefile removal."
    else
        for PART in $NTFS_PARTS; do
            PART_DEV="/dev/${PART}"
            TMP_MOUNT="/mnt/ntfs_part_${PART}"
            mkdir -p "${TMP_MOUNT}"

            echo -e "    Mounting ${PART_DEV} at ${TMP_MOUNT}..."
            # remove_hiberfile to allow safe mount of possibly hibernated Windows
            ntfs-3g -o remove_hiberfile "${PART_DEV}" "${TMP_MOUNT}" 2>/dev/null || \
                mount -t ntfs-3g -o remove_hiberfile "${PART_DEV}" "${TMP_MOUNT}" 2>/dev/null || {
                    echo -e "    ${RED}[WARN] Cannot mount ${PART_DEV}, skipping pagefile removal for this partition.${NC}"
                    continue
                }

            if [[ -f "${TMP_MOUNT}/pagefile.sys" ]]; then
                PAGE_SIZE=$(du -sh "${TMP_MOUNT}/pagefile.sys" 2>/dev/null | cut -f1)
                rm -f "${TMP_MOUNT}/pagefile.sys"
                echo -e "    ${GREEN}Removed pagefile.sys (${PAGE_SIZE}) from ${PART_DEV}${NC}"
            else
                echo -e "    pagefile.sys not found on ${PART_DEV}, skipping."
            fi

            umount "${TMP_MOUNT}" 2>/dev/null || umount -l "${TMP_MOUNT}" 2>/dev/null || true
        done
    fi

    # ── Run Clonezilla backup ─────────────────────────────────────────────────
    echo ""
    echo -e "${YELLOW}[STEP 6] Starting Clonezilla backup...${NC}"
    echo -e "    Disk     : ${BOLD}/dev/${DISK}${NC}"
    echo -e "    Backup   : ${BOLD}${BACKUP_NAME}${NC}"
    echo -e "    Target   : ${BOLD}${MOUNT_POINT}/${BACKUP_NAME}${NC}"
    echo -e "    Options  : -z1p (parallel gzip pigz), -i 4000 MB chunks, -j2 (parallel I/O)"
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

# =============================================================================
# MODE: RESTORE
# =============================================================================
elif [[ "$MODE_CHOICE" == "2" ]]; then

    # ── List available backups on SMB share ──────────────────────────────────
    echo ""
    echo -e "${YELLOW}[STEP 5] Scanning available backups on SMB share...${NC}"

    # A valid Clonezilla backup folder always contains a blkid.list file
    mapfile -t BACKUPS < <(find "${MOUNT_POINT}" -maxdepth 2 -name "blkid.list" 2>/dev/null \
        | sed 's|/blkid.list||' \
        | xargs -I{} basename {} \
        | sort)

    if [[ ${#BACKUPS[@]} -eq 0 ]]; then
        echo -e "${RED}[ERROR] No valid Clonezilla backups found in ${MOUNT_POINT}.${NC}"
        echo -e "        Make sure the SMB share is mounted and contains backup folders."
        exit 1
    fi

    echo ""
    echo -e "${BOLD}Available backups:${NC}"
    for i in "${!BACKUPS[@]}"; do
        BDIR="${MOUNT_POINT}/${BACKUPS[$i]}"
        # Get folder size
        BSIZE=$(du -sh "${BDIR}" 2>/dev/null | cut -f1 || echo "?")
        # Get creation date from sda-pt.sf or folder mtime
        BDATE=$(stat -c '%y' "${BDIR}" 2>/dev/null | cut -d'.' -f1 || echo "unknown")
        echo -e "  ${GREEN}[$((i+1))]${NC} ${BOLD}${BACKUPS[$i]}${NC}"
        echo -e "       Size: ${BSIZE}   Created: ${BDATE}"
    done
    echo ""

    read -r -p "Enter backup number to restore [1-${#BACKUPS[@]}]: " RESTORE_CHOICE
    echo ""

    # Validate input
    if ! [[ "$RESTORE_CHOICE" =~ ^[0-9]+$ ]] || \
       [[ "$RESTORE_CHOICE" -lt 1 ]] || \
       [[ "$RESTORE_CHOICE" -gt ${#BACKUPS[@]} ]]; then
        echo -e "${RED}[ERROR] Invalid selection. Exiting.${NC}"
        exit 1
    fi

    SELECTED_BACKUP="${BACKUPS[$((RESTORE_CHOICE-1))]}"

    echo -e "${RED}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}${BOLD}║  !! WARNING: RESTORE WILL OVERWRITE /dev/${DISK} !!       ║${NC}"
    echo -e "${RED}${BOLD}║  All data on the disk will be PERMANENTLY DESTROYED!     ║${NC}"
    echo -e "${RED}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Selected backup : ${BOLD}${SELECTED_BACKUP}${NC}"
    echo -e "  Target disk     : ${BOLD}/dev/${DISK}${NC}"
    echo ""
    read -r -p "Type YES to confirm restore: " CONFIRM
    echo ""

    if [[ "$CONFIRM" != "YES" ]]; then
        echo -e "${YELLOW}[ABORTED] Restore cancelled by user.${NC}"
        exit 0
    fi

    # ── Run Clonezilla restore ────────────────────────────────────────────────
    echo -e "${YELLOW}[STEP 6] Starting Clonezilla restore...${NC}"
    echo -e "    Backup : ${BOLD}${SELECTED_BACKUP}${NC}"
    echo -e "    Target : ${BOLD}/dev/${DISK}${NC}"
    sleep 3

    ocs-sr \
        -g auto \
        -e1 auto \
        -e2 \
        -r \
        -j2 \
        -p true \
        restoredisk "${SELECTED_BACKUP}" "${DISK}"

    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║  RESTORE COMPLETED SUCCESSFULLY!                         ║${NC}"
    echo -e "${GREEN}${BOLD}║  You can now reboot the machine.                         ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
fi

echo ""
