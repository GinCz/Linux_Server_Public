#!/bin/bash
# =============================================================================
#
#   backup_to_smb.sh
#
#   Description :
#     Interactive Backup & Restore tool for bare-metal disk images.
#     Uses Clonezilla (ocs-sr) engine with Partclone underneath for
#     filesystem-aware, block-level imaging of NTFS / ext4 / other
#     partitions.  Images are compressed on-the-fly with parallel gzip
#     (pigz) and written directly to a CIFS/SMB network share without
#     any intermediate local caching.
#
#   Features :
#     - Interactive mode selector: BACKUP or RESTORE at startup
#     - Sets system timezone to Europe/Prague before any operation
#     - Sets console resolution to 1024x768 for comfortable display
#     - Optional SSH root password change at startup
#     - Auto-installs required packages (clonezilla, cifs-utils,
#       pigz, ntfs-3g) if not present
#     - Mounts SMB share with SMB 3.0, remounts cleanly if stale
#     - BACKUP mode :
#         * Scans all NTFS partitions on the target disk
#         * Removes pagefile.sys to reduce image size
#         * Safely handles hibernated Windows (remove_hiberfile)
#         * Runs ocs-sr savedisk with parallel gzip (-z1p)
#           split into 4 GB chunks (-i 4000) and parallel I/O (-j2)
#     - RESTORE mode :
#         * Scans SMB share for all valid Clonezilla backup folders
#         * Shows numbered list with size and creation date
#         * Requires manual confirmation (type YES) before overwriting
#         * Runs ocs-sr restoredisk with auto partition table repair
#     - Trap-based cleanup: always unmounts SMB and NTFS temp mounts
#       on exit, even on error or Ctrl+C
#
#   Target     : Ubuntu 20.04+ / Debian-based systems
#   Privileges : Must be run as root
#   SMB share  : //s.gincz.com/soft/ISO
#   Disk       : /dev/sda  (change DISK variable if needed)
#
#   Usage :
#     bash backup_to_smb.sh
#
#   Restore command (manual, from Live USB) :
#     mount -t cifs //s.gincz.com/soft/ISO /home/partimag \
#       -o username=USER,password=PASS,vers=3.0
#     ocs-sr -g auto -e1 auto -e2 -r -j2 -p true \
#       restoredisk <BACKUP_FOLDER_NAME> sda
#
#   Version    : v.2026.07.31
#   Author     : VladiMIR + AI
#   Repository : https://github.com/GinCz/Linux_Server_Public
#
# = Rooted by VladiMIR + AI | v.2026.07.31 | github.com/GinCz =
# =============================================================================

clear
set -euo pipefail

# =============================================================================
# CONSTANTS
# =============================================================================
VERSION="v.2026.07.31"
SMB_HOST="//s.gincz.com/soft/ISO"
MOUNT_POINT="/home/partimag"
DISK="sda"
TIMEZONE="Europe/Prague"
RESOLUTION="1024x768"

# =============================================================================
# COLORS
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Separator styles (your trademark style)
SEP_EQ="${YELLOW}=================================================================${NC}"
SEP_LINE="${YELLOW}-----------------------------------------------------------------${NC}"

# =============================================================================
# FUNCTIONS
# =============================================================================

print_header() {
    clear
    echo -e "${SEP_EQ}"
    echo -e "${CYAN}${BOLD}"
    echo "    ____             _                  _____ __  __ ____  "
    echo "   | __ )  __ _  ___| | ___   _ _ __   / ____|  \/  |  _ \ "
    echo "   |  _ \ / _\` |/ __| |/ / | | | '_ \ \\___  \ |\/| | |_) |"
    echo "   | |_) | (_| | (__|   <| |_| | |_) | ___) | |  | |  _ < "
    echo "   |____/ \\__,_|\___|_|\_\\\\__,_| .__/ |_____/|_|  |_|_| \_\\"
    echo "                                  |_|                       "
    echo -e "${NC}"
    echo -e "${CYAN}${BOLD}       Clonezilla / Partclone  --  Backup & Restore Tool${NC}"
    echo -e "${CYAN}       SMB Target: ${SMB_HOST}${NC}"
    echo -e "${CYAN}       Rooted by VladiMIR + AI  |  ${VERSION}  |  github.com/GinCz${NC}"
    echo -e "${SEP_EQ}"
    echo ""
}

step() {
    echo ""
    echo -e "${SEP_LINE}"
    echo -e "${CYAN}${BOLD}  $1${NC}"
    echo -e "${SEP_LINE}"
}

ok()   { echo -e "  ${GREEN}[OK]${NC}  $1"; }
warn() { echo -e "  ${YELLOW}[!!]${NC}  $1"; }
err()  { echo -e "  ${RED}[ERR]${NC} $1"; }

# =============================================================================
# BANNER
# =============================================================================
print_header

# =============================================================================
# ROOT CHECK
# =============================================================================
if [[ $EUID -ne 0 ]]; then
    err "This script must be run as root."
    exit 1
fi

# =============================================================================
# STEP 0 — SET TIMEZONE + RESOLUTION
# =============================================================================
step "STEP 0 of 6  =  System Timezone & Console Resolution"

echo -e "  Setting timezone to: ${BOLD}${TIMEZONE}${NC}"
timedatectl set-timezone "${TIMEZONE}" 2>/dev/null || \
    ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
ok "Timezone set to ${TIMEZONE}  ( $(date '+%Z %z') )  Current time: $(date '+%Y-%m-%d %H:%M:%S')"

echo ""
echo -e "  Setting console resolution to: ${BOLD}${RESOLUTION}${NC}"
# Works in KVM/VNC console and raw TTY environments
if command -v fbset &>/dev/null; then
    fbset -g 1024 768 1024 768 32 2>/dev/null && ok "Resolution set via fbset" || warn "fbset failed, trying stty"
elif command -v setterm &>/dev/null; then
    setterm --resize 2>/dev/null || true
fi
# For GRUB/KVM virtual console — set VGA mode if available
if [[ -f /sys/class/graphics/fb0/virtual_size ]]; then
    echo "1024,768" > /sys/class/graphics/fb0/virtual_size 2>/dev/null || true
fi
# Universal: resize terminal window via ANSI escape (works in most emulators)
printf '\033[8;48;128t' 2>/dev/null || true
ok "Console geometry adjusted to ${RESOLUTION}"

# =============================================================================
# STEP 1 — MODE SELECTION
# =============================================================================
step "STEP 1 of 6  =  Select Operation Mode"

echo -e "  ${YELLOW}===${NC} ${GREEN}${BOLD}[1] BACKUP${NC}   — image disk to SMB share"
echo -e "  ${YELLOW}===${NC} ${CYAN}${BOLD}[2] RESTORE${NC}  — restore disk from SMB share"
echo ""
read -r -p "  Enter 1 or 2: " MODE_CHOICE
echo ""

if [[ "$MODE_CHOICE" != "1" && "$MODE_CHOICE" != "2" ]]; then
    err "Invalid choice '${MODE_CHOICE}'. Exiting."
    exit 1
fi

[[ "$MODE_CHOICE" == "1" ]] && ok "Mode selected: ${BOLD}BACKUP${NC}" || ok "Mode selected: ${BOLD}RESTORE${NC}"

# =============================================================================
# STEP 2 — OPTIONAL SSH PASSWORD CHANGE
# =============================================================================
step "STEP 2 of 6  =  SSH Root Password (optional)"

read -r -s -p "  New SSH root password (blank = keep current): " SSH_PASS
echo
if [[ -n "$SSH_PASS" ]]; then
    echo "root:${SSH_PASS}" | chpasswd
    systemctl restart ssh 2>/dev/null || /etc/init.d/ssh restart
    ok "SSH password updated and service restarted."
else
    warn "Skipped — password unchanged."
fi

# =============================================================================
# STEP 3 — SMB CREDENTIALS
# =============================================================================
step "STEP 3 of 6  =  SMB Credentials"

echo -e "  Share: ${BOLD}${SMB_HOST}${NC}"
echo ""
read -r -p "  SMB Username: " SMB_USER
read -r -s -p "  SMB Password: " SMB_PASS
echo
ok "Credentials received."

# =============================================================================
# STEP 4 — INSTALL DEPENDENCIES
# =============================================================================
step "STEP 4 of 6  =  Install Dependencies"

echo -e "  Packages: clonezilla  cifs-utils  pigz  ntfs-3g"
apt-get update -qq
apt-get install -y clonezilla cifs-utils pigz ntfs-3g -qq
ok "All dependencies are installed."

# =============================================================================
# STEP 5 — MOUNT SMB SHARE
# =============================================================================
step "STEP 5 of 6  =  Mount SMB Share"

mkdir -p "${MOUNT_POINT}"

if mountpoint -q "${MOUNT_POINT}"; then
    warn "Already mounted — remounting cleanly..."
    umount -l "${MOUNT_POINT}"
fi

echo -e "  Mounting ${BOLD}${SMB_HOST}${NC} → ${BOLD}${MOUNT_POINT}${NC} ..."
mount -t cifs "${SMB_HOST}" "${MOUNT_POINT}" \
    -o username="${SMB_USER}",password="${SMB_PASS}",vers=3.0,iocharset=utf8
ok "SMB share mounted successfully."

# =============================================================================
# CLEANUP TRAP  —  always runs on exit, error, or Ctrl+C
# =============================================================================
cleanup() {
    echo ""
    echo -e "${SEP_LINE}"
    echo -e "  ${YELLOW}[CLEANUP]${NC} Flushing filesystem buffers..."
    sync
    sleep 2
    for mp in /mnt/ntfs_part_*; do
        [[ -d "$mp" ]] && mountpoint -q "$mp" 2>/dev/null && umount -l "$mp" 2>/dev/null || true
    done
    umount -l "${MOUNT_POINT}" 2>/dev/null || true
    echo -e "  ${GREEN}[DONE]${NC} SMB share unmounted. All clean."
    echo -e "${SEP_EQ}"
}
trap cleanup EXIT

# =============================================================================
# STEP 6 — BACKUP or RESTORE
# =============================================================================
step "STEP 6 of 6  =  Execute Operation"

# -----------------------------------------------------------------------------
# MODE: BACKUP
# -----------------------------------------------------------------------------
if [[ "$MODE_CHOICE" == "1" ]]; then

    BACKUP_NAME="WinServer2016_Backup_$(date +%Y%m%d_%H%M)"

    echo -e "  ${YELLOW}===  Remove pagefile.sys from NTFS partitions  ===${NC}"
    echo ""

    NTFS_PARTS=$(lsblk -rno NAME,FSTYPE "/dev/${DISK}" 2>/dev/null | awk '$2=="ntfs" {print $1}')

    if [[ -z "$NTFS_PARTS" ]]; then
        warn "No NTFS partitions found on /dev/${DISK} — skipping pagefile removal."
    else
        for PART in $NTFS_PARTS; do
            PART_DEV="/dev/${PART}"
            TMP_MOUNT="/mnt/ntfs_part_${PART}"
            mkdir -p "${TMP_MOUNT}"

            echo -e "  Mounting ${BOLD}${PART_DEV}${NC} ..."
            ntfs-3g -o remove_hiberfile "${PART_DEV}" "${TMP_MOUNT}" 2>/dev/null || \
            mount -t ntfs-3g -o remove_hiberfile "${PART_DEV}" "${TMP_MOUNT}" 2>/dev/null || {
                warn "Cannot mount ${PART_DEV} — skipping pagefile removal for this partition."
                continue
            }

            if [[ -f "${TMP_MOUNT}/pagefile.sys" ]]; then
                PAGE_SIZE=$(du -sh "${TMP_MOUNT}/pagefile.sys" 2>/dev/null | cut -f1)
                rm -f "${TMP_MOUNT}/pagefile.sys"
                ok "Removed pagefile.sys (${PAGE_SIZE}) from ${PART_DEV}"
            else
                warn "pagefile.sys not found on ${PART_DEV} — nothing to remove."
            fi

            umount "${TMP_MOUNT}" 2>/dev/null || umount -l "${TMP_MOUNT}" 2>/dev/null || true
        done
    fi

    echo ""
    echo -e "  ${YELLOW}===  Clonezilla savedisk  ===${NC}"
    echo ""
    echo -e "  Disk     : ${BOLD}/dev/${DISK}${NC}"
    echo -e "  Backup   : ${BOLD}${BACKUP_NAME}${NC}"
    echo -e "  Target   : ${BOLD}${MOUNT_POINT}/${BACKUP_NAME}${NC}"
    echo -e "  Method   : Partclone + pigz parallel gzip (-z1p)"
    echo -e "  Chunks   : 4000 MB per file (-i 4000)"
    echo -e "  I/O      : parallel read/write (-j2)"
    echo -e "  Time     : $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo ""
    echo -e "  ${RED}${BOLD}[WARNING]  Do NOT interrupt this process!${NC}"
    echo -e "  ${RED}Full disk will be imaged. This may take 15-60 minutes.${NC}"
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
    echo -e "${SEP_EQ}"
    echo -e "  ${GREEN}${BOLD}BACKUP COMPLETED SUCCESSFULLY!${NC}"
    echo -e "  ${GREEN}Finished : $(date '+%Y-%m-%d %H:%M:%S %Z')${NC}"
    echo -e "  ${GREEN}Location : \\\\s.gincz.com\\soft\\ISO\\${BACKUP_NAME}${NC}"
    echo -e "${SEP_EQ}"

# -----------------------------------------------------------------------------
# MODE: RESTORE
# -----------------------------------------------------------------------------
elif [[ "$MODE_CHOICE" == "2" ]]; then

    echo -e "  ${YELLOW}===  Scanning available backups on SMB share  ===${NC}"
    echo ""

    mapfile -t BACKUPS < <(find "${MOUNT_POINT}" -maxdepth 2 -name "blkid.list" 2>/dev/null \
        | sed 's|/blkid.list||' \
        | xargs -I{} basename {} \
        | sort)

    if [[ ${#BACKUPS[@]} -eq 0 ]]; then
        err "No valid Clonezilla backups found in ${MOUNT_POINT}."
        err "Make sure the SMB share is mounted and contains backup folders."
        exit 1
    fi

    echo -e "  Found ${BOLD}${#BACKUPS[@]}${NC} backup(s):"
    echo ""
    for i in "${!BACKUPS[@]}"; do
        BDIR="${MOUNT_POINT}/${BACKUPS[$i]}"
        BSIZE=$(du -sh "${BDIR}" 2>/dev/null | cut -f1 || echo "?")
        BDATE=$(stat -c '%y' "${BDIR}" 2>/dev/null | cut -d'.' -f1 || echo "unknown")
        echo -e "  ${YELLOW}===${NC} ${CYAN}${BOLD}[$((i+1))]${NC} ${BOLD}${BACKUPS[$i]}${NC}"
        echo -e "        Size: ${BOLD}${BSIZE}${NC}   Created: ${BDATE}"
        echo ""
    done

    read -r -p "  Enter backup number to restore [1-${#BACKUPS[@]}]: " RESTORE_CHOICE
    echo ""

    if ! [[ "$RESTORE_CHOICE" =~ ^[0-9]+$ ]] || \
       [[ "$RESTORE_CHOICE" -lt 1 ]] || \
       [[ "$RESTORE_CHOICE" -gt ${#BACKUPS[@]} ]]; then
        err "Invalid selection '${RESTORE_CHOICE}'. Exiting."
        exit 1
    fi

    SELECTED_BACKUP="${BACKUPS[$((RESTORE_CHOICE-1))]}"

    echo -e "${SEP_EQ}"
    echo -e "  ${RED}${BOLD}!! WARNING: DESTRUCTIVE OPERATION !!${NC}"
    echo -e "${SEP_EQ}"
    echo -e "  ${RED}RESTORE will PERMANENTLY OVERWRITE /dev/${DISK}${NC}"
    echo -e "  ${RED}ALL existing data on the disk will be DESTROYED!${NC}"
    echo -e "${SEP_LINE}"
    echo -e "  Selected backup : ${BOLD}${SELECTED_BACKUP}${NC}"
    echo -e "  Target disk     : ${BOLD}/dev/${DISK}${NC}"
    echo -e "  Started at      : $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo -e "${SEP_LINE}"
    echo ""
    read -r -p "  Type ${BOLD}YES${NC} to confirm restore (anything else = abort): " CONFIRM
    echo ""

    if [[ "$CONFIRM" != "YES" ]]; then
        warn "Restore ABORTED by user."
        exit 0
    fi

    echo -e "  ${YELLOW}===  Clonezilla restoredisk  ===${NC}"
    echo ""
    echo -e "  Backup : ${BOLD}${SELECTED_BACKUP}${NC}"
    echo -e "  Target : ${BOLD}/dev/${DISK}${NC}"
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
    echo -e "${SEP_EQ}"
    echo -e "  ${GREEN}${BOLD}RESTORE COMPLETED SUCCESSFULLY!${NC}"
    echo -e "  ${GREEN}Finished : $(date '+%Y-%m-%d %H:%M:%S %Z')${NC}"
    echo -e "  ${GREEN}Restored : ${SELECTED_BACKUP}  ==>  /dev/${DISK}${NC}"
    echo -e "  ${GREEN}You can now reboot the machine.${NC}"
    echo -e "${SEP_EQ}"
fi

echo ""
