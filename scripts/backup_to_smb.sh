#!/bin/bash
# =============================================================================
#
#   backup_to_smb.sh
#
#   Description :
#     Interactive Backup & Restore tool for bare-metal Windows disk images.
#     Uses Clonezilla (ocs-sr) engine with Partclone underneath for
#     filesystem-aware, block-level imaging of NTFS partitions.
#     Images are compressed on-the-fly with parallel gzip (pigz) and
#     written directly to a CIFS/SMB network share without any
#     intermediate local caching.
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
#         * Pre-flight report: SMB free space + Windows partition used space
#         * Auto-detects the Windows partition (contains \Windows folder)
#         * Full Windows temp cleanup before imaging:
#             - pagefile.sys       (Windows page file, up to 32 GB)
#             - hiberfil.sys       (hibernation image, 75% of RAM)
#             - swapfile.sys       (Modern Standby swap, Win10+)
#             - Windows\Temp\*     (system temp files)
#             - Windows\Prefetch\* (prefetch cache)
#             - Windows\SoftwareDistribution\Download\*  (Windows Update cache)
#             - Users\*\AppData\Local\Temp\*  (per-user temp)
#             - $Recycle.Bin contents on all NTFS partitions
#             - Windows\Logs\*    (system logs)
#             - Windows\Minidump\* (crash dumps)
#         * Shows bytes freed per item and total saved
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
#   Version    : v.2026.07.31b
#   Author     : VladiMIR + AI
#   Repository : https://github.com/GinCz/Linux_Server_Public
#
# = Rooted by VladiMIR + AI | v.2026.07.31b | github.com/GinCz =
# =============================================================================

clear
set -euo pipefail

# =============================================================================
# CONSTANTS
# =============================================================================
VERSION="v.2026.07.31b"
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
SEP_EQ="${YELLOW}=================================================================${NC}"
SEP_LINE="${YELLOW}-----------------------------------------------------------------${NC}"

# =============================================================================
# HELPER FUNCTIONS
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
    echo -e "${CYAN}       SMB Target : ${SMB_HOST}${NC}"
    echo -e "${CYAN}       Version    : ${VERSION}  |  github.com/GinCz${NC}"
    echo -e "${SEP_EQ}"
    echo ""
}

step()  { echo ""; echo -e "${SEP_LINE}"; echo -e "${CYAN}${BOLD}  $1${NC}"; echo -e "${SEP_LINE}"; }
ok()    { echo -e "  ${GREEN}[OK]${NC}  $1"; }
warn()  { echo -e "  ${YELLOW}[!!]${NC}  $1"; }
err()   { echo -e "  ${RED}[ERR]${NC} $1"; }
info()  { echo -e "  ${CYAN}---${NC}  $1"; }

# Returns human-readable size of a path; 0B if missing/empty
path_size() {
    local p="$1"
    [[ -e "$p" ]] && du -sh "$p" 2>/dev/null | cut -f1 || echo "0B"
}

# Removes a file or directory tree; prints freed bytes; returns freed bytes (approx)
clean_item() {
    local label="$1"
    local target="$2"
    local type="$3"   # "file" or "dir"

    if [[ "$type" == "file" && ! -f "$target" ]]; then
        warn "Not found: ${label}  (${target})"
        echo 0; return
    fi
    if [[ "$type" == "dir" && ! -d "$target" ]]; then
        warn "Not found: ${label}  (${target})"
        echo 0; return
    fi

    local size
    size=$(du -sb "$target" 2>/dev/null | awk '{print $1}' || echo 0)
    local size_h
    size_h=$(du -sh "$target" 2>/dev/null | cut -f1 || echo "0B")

    if [[ "$type" == "file" ]]; then
        rm -f "$target"
    else
        rm -rf "${target:?}/"*  2>/dev/null || true
    fi

    ok "Cleaned ${label}  freed: ${BOLD}${size_h}${NC}"
    echo "$size"
}

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
# STEP 0  =  Timezone & Console Resolution
# =============================================================================
step "STEP 0 of 6  =  System Timezone & Console Resolution"

timedatectl set-timezone "${TIMEZONE}" 2>/dev/null || \
    ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
ok "Timezone : ${BOLD}${TIMEZONE}${NC}  ( $(date '+%Z %z') )   Time: $(date '+%Y-%m-%d %H:%M:%S')"

if command -v fbset &>/dev/null; then
    fbset -g 1024 768 1024 768 32 2>/dev/null && ok "Resolution set via fbset (${RESOLUTION})" || true
fi
[[ -f /sys/class/graphics/fb0/virtual_size ]] && \
    echo "1024,768" > /sys/class/graphics/fb0/virtual_size 2>/dev/null || true
printf '\033[8;48;128t' 2>/dev/null || true
ok "Console geometry adjusted to ${RESOLUTION}"

# =============================================================================
# STEP 1  =  Mode Selection
# =============================================================================
step "STEP 1 of 6  =  Select Operation Mode"

echo -e "  ${YELLOW}===${NC} ${GREEN}${BOLD}[1] BACKUP${NC}   --- image /dev/${DISK} to SMB share"
echo -e "  ${YELLOW}===${NC} ${CYAN}${BOLD}[2] RESTORE${NC}  --- restore /dev/${DISK} from SMB share"
echo ""
read -r -p "  Enter 1 or 2: " MODE_CHOICE
echo ""

if [[ "$MODE_CHOICE" != "1" && "$MODE_CHOICE" != "2" ]]; then
    err "Invalid choice '${MODE_CHOICE}'. Exiting."
    exit 1
fi
[[ "$MODE_CHOICE" == "1" ]] && ok "Mode: ${BOLD}BACKUP${NC}" || ok "Mode: ${BOLD}RESTORE${NC}"

# =============================================================================
# STEP 2  =  Optional SSH Password Change
# =============================================================================
step "STEP 2 of 6  =  SSH Root Password  (optional)"

read -r -s -p "  New SSH root password  (blank = skip): " SSH_PASS
echo
if [[ -n "$SSH_PASS" ]]; then
    echo "root:${SSH_PASS}" | chpasswd
    systemctl restart ssh 2>/dev/null || /etc/init.d/ssh restart
    ok "SSH password updated and service restarted."
else
    warn "Skipped --- password unchanged."
fi

# =============================================================================
# STEP 3  =  SMB Credentials
# =============================================================================
step "STEP 3 of 6  =  SMB Credentials"

echo -e "  Share: ${BOLD}${SMB_HOST}${NC}"
echo ""
read -r -p "  SMB Username: " SMB_USER
read -r -s -p "  SMB Password: " SMB_PASS
echo
ok "Credentials received."

# =============================================================================
# STEP 4  =  Install Dependencies
# =============================================================================
step "STEP 4 of 6  =  Install Dependencies"

echo -e "  Packages: clonezilla  cifs-utils  pigz  ntfs-3g"
apt-get update -qq
apt-get install -y clonezilla cifs-utils pigz ntfs-3g -qq
ok "All dependencies installed."

# =============================================================================
# STEP 5  =  Mount SMB Share
# =============================================================================
step "STEP 5 of 6  =  Mount SMB Share"

mkdir -p "${MOUNT_POINT}"

if mountpoint -q "${MOUNT_POINT}"; then
    warn "Already mounted --- remounting cleanly..."
    umount -l "${MOUNT_POINT}"
fi

echo -e "  Mounting ${BOLD}${SMB_HOST}${NC} --> ${BOLD}${MOUNT_POINT}${NC} ..."
mount -t cifs "${SMB_HOST}" "${MOUNT_POINT}" \
    -o username="${SMB_USER}",password="${SMB_PASS}",vers=3.0,iocharset=utf8
ok "SMB share mounted successfully."

# --- Show SMB free space right after mount ---
SMB_FREE=$(df -h "${MOUNT_POINT}" 2>/dev/null | awk 'NR==2{print $4}' || echo "unknown")
SMB_USED=$(df -h "${MOUNT_POINT}" 2>/dev/null | awk 'NR==2{print $3}' || echo "unknown")
SMB_TOTAL=$(df -h "${MOUNT_POINT}" 2>/dev/null | awk 'NR==2{print $2}' || echo "unknown")
echo ""
echo -e "  ${YELLOW}===  SMB Share Disk Space  ===${NC}"
info "Total  : ${BOLD}${SMB_TOTAL}${NC}"
info "Used   : ${BOLD}${SMB_USED}${NC}"
info "Free   : ${BOLD}${GREEN}${SMB_FREE}${NC}"

# =============================================================================
# CLEANUP TRAP  ---  always runs on exit, error, or Ctrl+C
# =============================================================================
cleanup() {
    echo ""
    echo -e "${SEP_LINE}"
    echo -e "  ${YELLOW}[CLEANUP]${NC} Flushing filesystem buffers..."
    sync; sleep 2
    for mp in /mnt/ntfs_part_*; do
        [[ -d "$mp" ]] && mountpoint -q "$mp" 2>/dev/null && umount -l "$mp" 2>/dev/null || true
    done
    umount -l "${MOUNT_POINT}" 2>/dev/null || true
    echo -e "  ${GREEN}[DONE]${NC} All mounts released. Clean exit."
    echo -e "${SEP_EQ}"
}
trap cleanup EXIT

# =============================================================================
# STEP 6  =  Execute Operation
# =============================================================================
step "STEP 6 of 6  =  Execute Operation"

# =============================================================================
# MODE: BACKUP
# =============================================================================
if [[ "$MODE_CHOICE" == "1" ]]; then

    BACKUP_NAME="WinServer2016_Backup_$(date +%Y%m%d_%H%M)"

    # -------------------------------------------------------------------------
    # Find NTFS partitions and locate the Windows partition
    # -------------------------------------------------------------------------
    echo -e "  ${YELLOW}===  Scan NTFS partitions on /dev/${DISK}  ===${NC}"
    echo ""

    NTFS_PARTS=$(lsblk -rno NAME,FSTYPE "/dev/${DISK}" 2>/dev/null | awk '$2=="ntfs" {print $1}')

    if [[ -z "$NTFS_PARTS" ]]; then
        warn "No NTFS partitions found on /dev/${DISK}."
        warn "Skipping cleanup phase. Proceeding to backup."
    else
        WIN_PART=""       # partition device that contains \Windows folder
        WIN_MOUNT=""      # its mountpoint
        TOTAL_FREED=0     # bytes freed across all cleanup operations

        for PART in $NTFS_PARTS; do
            PART_DEV="/dev/${PART}"
            TMP_MOUNT="/mnt/ntfs_part_${PART}"
            mkdir -p "${TMP_MOUNT}"

            info "Mounting ${BOLD}${PART_DEV}${NC} at ${TMP_MOUNT} ..."
            ntfs-3g -o remove_hiberfile "${PART_DEV}" "${TMP_MOUNT}" 2>/dev/null || \
            mount -t ntfs-3g -o remove_hiberfile "${PART_DEV}" "${TMP_MOUNT}" 2>/dev/null || {
                warn "Cannot mount ${PART_DEV} --- skipping."
                continue
            }

            # --- Show partition used space ---
            PART_USED=$(df -h "${TMP_MOUNT}" 2>/dev/null | awk 'NR==2{print $3}' || echo "?")
            PART_FREE=$(df -h "${TMP_MOUNT}" 2>/dev/null | awk 'NR==2{print $4}' || echo "?")
            PART_TOTAL=$(df -h "${TMP_MOUNT}" 2>/dev/null | awk 'NR==2{print $2}' || echo "?")
            info "${PART_DEV}  ---  Total: ${BOLD}${PART_TOTAL}${NC}  Used: ${BOLD}${PART_USED}${NC}  Free: ${BOLD}${PART_FREE}${NC}"

            # --- Recycle Bin cleanup on every NTFS partition ---
            FREED=$(clean_item "\$Recycle.Bin on ${PART_DEV}" "${TMP_MOUNT}/\$Recycle.Bin" "dir")
            TOTAL_FREED=$(( TOTAL_FREED + FREED ))

            # --- Detect Windows partition by presence of \Windows folder ---
            if [[ -d "${TMP_MOUNT}/Windows" ]]; then
                ok "Found Windows folder on ${BOLD}${PART_DEV}${NC}  --- this is the system partition (C:)"
                WIN_PART="${PART_DEV}"
                WIN_MOUNT="${TMP_MOUNT}"

                # Show how much data the Windows partition actually uses
                echo ""
                echo -e "  ${YELLOW}===  Windows Partition Space Report  ===${NC}"
                info "Partition     : ${BOLD}${WIN_PART}${NC}"
                info "Total size    : ${BOLD}${PART_TOTAL}${NC}"
                info "Currently used: ${BOLD}${PART_USED}${NC}  (this is what Partclone will image)"
                info "Free on disk  : ${BOLD}${PART_FREE}${NC}"
                echo ""

                # --- Full Windows temp cleanup ---
                echo -e "  ${YELLOW}===  Windows Temp Cleanup  ===${NC}"
                echo ""

                # 1. pagefile.sys --- Windows page file (up to RAM size, typically 4-32 GB)
                FREED=$(clean_item "pagefile.sys" "${WIN_MOUNT}/pagefile.sys" "file")
                TOTAL_FREED=$(( TOTAL_FREED + FREED ))

                # 2. hiberfil.sys --- Hibernation image (75% of physical RAM)
                FREED=$(clean_item "hiberfil.sys" "${WIN_MOUNT}/hiberfil.sys" "file")
                TOTAL_FREED=$(( TOTAL_FREED + FREED ))

                # 3. swapfile.sys --- Modern Standby swap (Windows 10/11/Server 2016+)
                FREED=$(clean_item "swapfile.sys" "${WIN_MOUNT}/swapfile.sys" "file")
                TOTAL_FREED=$(( TOTAL_FREED + FREED ))

                # 4. Windows\Temp --- System temporary files
                FREED=$(clean_item "Windows\\Temp" "${WIN_MOUNT}/Windows/Temp" "dir")
                TOTAL_FREED=$(( TOTAL_FREED + FREED ))

                # 5. Windows\Prefetch --- Prefetch/superfetch cache files
                FREED=$(clean_item "Windows\\Prefetch" "${WIN_MOUNT}/Windows/Prefetch" "dir")
                TOTAL_FREED=$(( TOTAL_FREED + FREED ))

                # 6. Windows\Logs --- System event logs (can be hundreds of MB)
                FREED=$(clean_item "Windows\\Logs" "${WIN_MOUNT}/Windows/Logs" "dir")
                TOTAL_FREED=$(( TOTAL_FREED + FREED ))

                # 7. Windows\Minidump --- Crash dump files
                FREED=$(clean_item "Windows\\Minidump" "${WIN_MOUNT}/Windows/Minidump" "dir")
                TOTAL_FREED=$(( TOTAL_FREED + FREED ))

                # 8. Windows\SoftwareDistribution\Download --- Windows Update cache
                FREED=$(clean_item "Windows\\SoftwareDistribution\\Download" \
                    "${WIN_MOUNT}/Windows/SoftwareDistribution/Download" "dir")
                TOTAL_FREED=$(( TOTAL_FREED + FREED ))

                # 9. All user Temp folders --- C:\Users\*\AppData\Local\Temp
                if [[ -d "${WIN_MOUNT}/Users" ]]; then
                    for USER_DIR in "${WIN_MOUNT}/Users/"*/; do
                        USER_TEMP="${USER_DIR}AppData/Local/Temp"
                        USERNAME=$(basename "${USER_DIR}")
                        if [[ -d "${USER_TEMP}" ]]; then
                            FREED=$(clean_item "Users\\${USERNAME}\\AppData\\Local\\Temp" \
                                "${USER_TEMP}" "dir")
                            TOTAL_FREED=$(( TOTAL_FREED + FREED ))
                        fi
                    done
                fi

                # 10. Windows Update leftover: C:\Windows\SoftwareDistribution\PostRebootEventCache.V2
                FREED=$(clean_item "Windows\\SoftwareDistribution\\PostRebootEventCache" \
                    "${WIN_MOUNT}/Windows/SoftwareDistribution/PostRebootEventCache.V2" "dir")
                TOTAL_FREED=$(( TOTAL_FREED + FREED ))

                echo ""
                # Convert total freed bytes to human-readable
                FREED_H=$(numfmt --to=iec-i --suffix=B "${TOTAL_FREED}" 2>/dev/null || \
                          echo "$(( TOTAL_FREED / 1024 / 1024 )) MB")
                echo -e "  ${GREEN}${BOLD}=== Total space freed by cleanup: ${FREED_H} ===${NC}"

                # Show updated used space after cleanup
                PART_USED_AFTER=$(df -h "${WIN_MOUNT}" 2>/dev/null | awk 'NR==2{print $3}' || echo "?")
                info "Windows partition used AFTER cleanup: ${BOLD}${PART_USED_AFTER}${NC}"
                info "This is the actual data Partclone will image."
                echo ""

            else
                # Not a Windows partition --- unmount and continue
                umount "${TMP_MOUNT}" 2>/dev/null || umount -l "${TMP_MOUNT}" 2>/dev/null || true
            fi
        done

        if [[ -z "$WIN_PART" ]]; then
            warn "Windows folder not found on any NTFS partition."
            warn "Cleanup skipped. Proceeding to full disk backup."
        else
            # Unmount Windows partition before imaging
            umount "${WIN_MOUNT}" 2>/dev/null || umount -l "${WIN_MOUNT}" 2>/dev/null || true
            ok "Windows partition unmounted. Ready for imaging."
        fi
    fi

    # -------------------------------------------------------------------------
    # Pre-flight summary: SMB free vs data to backup
    # -------------------------------------------------------------------------
    echo ""
    echo -e "  ${YELLOW}===  Pre-flight Space Check  ===${NC}"
    SMB_FREE_NOW=$(df -h "${MOUNT_POINT}" 2>/dev/null | awk 'NR==2{print $4}' || echo "unknown")
    DISK_USED=$(df -h "/dev/${DISK}" 2>/dev/null | awk 'NR==2{print $3}' 2>/dev/null || \
        lsblk -dno SIZE "/dev/${DISK}" 2>/dev/null || echo "unknown")
    info "SMB free space available  : ${BOLD}${GREEN}${SMB_FREE_NOW}${NC}"
    info "Full disk size  /dev/${DISK} : ${BOLD}$(lsblk -dno SIZE /dev/${DISK} 2>/dev/null || echo 'unknown')${NC}"
    info "Backup with -z1p compression typically produces 30-60%% of raw used data."
    echo ""

    # -------------------------------------------------------------------------
    # Run Clonezilla backup
    # -------------------------------------------------------------------------
    echo -e "  ${YELLOW}===  Clonezilla savedisk  ===${NC}"
    echo ""
    echo -e "  Disk     : ${BOLD}/dev/${DISK}${NC}"
    echo -e "  Backup   : ${BOLD}${BACKUP_NAME}${NC}"
    echo -e "  Target   : ${BOLD}${MOUNT_POINT}/${BACKUP_NAME}${NC}"
    echo -e "  Method   : Partclone + pigz parallel gzip  (-z1p)"
    echo -e "  Chunks   : 4000 MB per file  (-i 4000)"
    echo -e "  I/O      : parallel read/write  (-j2)"
    echo -e "  Started  : $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo ""
    echo -e "  ${RED}${BOLD}[WARNING]  Do NOT interrupt! This may take 15-60 minutes.${NC}"
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
    # Show final backup folder size
    BSIZE=$(du -sh "${MOUNT_POINT}/${BACKUP_NAME}" 2>/dev/null | cut -f1 || echo "?")
    echo -e "  ${GREEN}Backup size on share : ${BOLD}${BSIZE}${NC}"
    echo -e "${SEP_EQ}"

# =============================================================================
# MODE: RESTORE
# =============================================================================
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
        echo -e "  ${YELLOW}===${NC} ${CYAN}${BOLD}[$((i+1))]${NC}  ${BOLD}${BACKUPS[$i]}${NC}"
        echo -e "         Size: ${BOLD}${BSIZE}${NC}   Created: ${BDATE}"
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
    read -r -p "  Type YES to confirm restore (anything else = abort): " CONFIRM
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
