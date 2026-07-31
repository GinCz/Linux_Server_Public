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
#   Flow :
#     1. Banner
#     2. SMB Credentials  (user/pass)
#     3. Install deps, Mount SMB share
#     4. Show backup list  ← immediately after mount
#     5. Select backup number
#     6. Action: [1] RESTORE  /  [2] DELETE  /  [3] BACKUP new image
#
#   Target     : Ubuntu 20.04+ / Debian-based systems
#   Privileges : Must be run as root
#   SMB share  : //s.gincz.com/soft/ISO
#   Disk       : /dev/sda
#
#   Usage :
#     export LANG=C LC_ALL=C TERM=xterm-256color
#     curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/backup_to_smb.sh \
#       -o /tmp/backup_to_smb.sh && bash /tmp/backup_to_smb.sh
#
#   Version    : v.2026.07.31g
#   Author     : VladiMIR + AI
#   Repository : https://github.com/GinCz/Linux_Server_Public
#
#   Changelog  :
#     v.2026.07.31g  - New flow: credentials -> mount -> list -> select -> action
#                      [1] Restore  [2] Delete  [3] Backup new image
#     v.2026.07.31f  - RESTORE: select backup first, then [1] Restore / [2] Delete
#     v.2026.07.31e  - RESTORE submenu before selection
#     v.2026.07.31d  - Compact text banner
#     v.2026.07.31c  - Fixes: clean_item, $Recycle.Bin, renumbered steps
#     v.2026.07.31b  - Smart Windows detection, temp cleanup, space reports
#     v.2026.07.31   - Initial version
#
# = Rooted by VladiMIR + AI | v.2026.07.31g | github.com/GinCz =
# =============================================================================

clear
set -euo pipefail

# =============================================================================
# CONSTANTS
# =============================================================================
VERSION="v.2026.07.31g"
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
# HELPERS
# =============================================================================
print_header() {
    clear
    echo -e "${SEP_EQ}"
    echo -e "${CYAN}${BOLD}"
    echo "   BACKUP / SMB"
    echo "   Clonezilla + Partclone -- Backup & Restore Tool"
    echo -e "${NC}"
    echo -e "${CYAN}   SMB  : ${SMB_HOST}${NC}"
    echo -e "${CYAN}   Ver  : ${VERSION}  |  github.com/GinCz${NC}"
    echo -e "${SEP_EQ}"
    echo ""
}

step()  { echo ""; echo -e "${SEP_LINE}"; echo -e "${CYAN}${BOLD}  $1${NC}"; echo -e "${SEP_LINE}"; }
ok()    { echo -e "  ${GREEN}[OK]${NC}  $1"; }
warn()  { echo -e "  ${YELLOW}[!!]${NC}  $1"; }
err()   { echo -e "  ${RED}[ERR]${NC} $1"; }
info()  { echo -e "  ${CYAN}---${NC}  $1"; }

clean_item() {
    local label="$1" target="$2" type="$3"
    if [[ "$type" == "file" && ! -f "$target" ]]; then warn "Not found : ${label}" >&2; echo 0; return; fi
    if [[ "$type" == "dir"  && ! -d "$target" ]]; then warn "Not found : ${label}" >&2; echo 0; return; fi
    local size size_h
    size=$(du -sb "$target" 2>/dev/null | awk '{print $1}' || echo 0)
    size_h=$(du -sh "$target" 2>/dev/null | cut -f1 || echo "0B")
    if [[ "$type" == "file" ]]; then rm -f "$target"
    else rm -rf "${target:?}/"* 2>/dev/null || true; fi
    ok "Cleaned ${label}  freed: ${BOLD}${size_h}${NC}" >&2
    echo "$size"
}

print_backup_list() {
    local -n _arr=$1
    for i in "${!_arr[@]}"; do
        local BDIR="${MOUNT_POINT}/${_arr[$i]}"
        local BSIZE BDATE
        BSIZE=$(du -sh "${BDIR}" 2>/dev/null | cut -f1 || echo "?")
        BDATE=$(stat -c '%y' "${BDIR}" 2>/dev/null | cut -d'.' -f1 || echo "?")
        echo -e "  ${YELLOW}===${NC} ${CYAN}${BOLD}[$((i+1))]${NC}  ${BOLD}${_arr[$i]}${NC}   ${BSIZE}   ${BDATE}"
    done
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
# STEP 1 of 4  =  Timezone & Console
# =============================================================================
step "STEP 1 of 4  =  System Timezone & Console Resolution"

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
# STEP 2 of 4  =  SMB Credentials
# =============================================================================
step "STEP 2 of 4  =  SMB Credentials"

echo -e "  Share: ${BOLD}${SMB_HOST}${NC}"
echo ""
read -r -p "  SMB Username: " SMB_USER
read -r -s -p "  SMB Password: " SMB_PASS
echo
ok "Credentials received."

# =============================================================================
# STEP 3 of 4  =  Install Dependencies & Mount SMB
# =============================================================================
step "STEP 3 of 4  =  Install Dependencies & Mount SMB Share"

echo -e "  Packages: clonezilla  cifs-utils  pigz  ntfs-3g"
apt-get update -qq
apt-get install -y clonezilla cifs-utils pigz ntfs-3g -qq
ok "All dependencies installed."

echo ""
mkdir -p "${MOUNT_POINT}"
if mountpoint -q "${MOUNT_POINT}"; then
    warn "Already mounted --- remounting cleanly..."
    umount -l "${MOUNT_POINT}"
fi
echo -e "  Mounting ${BOLD}${SMB_HOST}${NC} --> ${BOLD}${MOUNT_POINT}${NC} ..."
mount -t cifs "${SMB_HOST}" "${MOUNT_POINT}" \
    -o username="${SMB_USER}",password="${SMB_PASS}",vers=3.0,iocharset=utf8
ok "SMB share mounted successfully."

SMB_FREE=$(df  -h "${MOUNT_POINT}" 2>/dev/null | awk 'NR==2{print $4}' || echo "?")
SMB_USED=$(df  -h "${MOUNT_POINT}" 2>/dev/null | awk 'NR==2{print $3}' || echo "?")
SMB_TOTAL=$(df -h "${MOUNT_POINT}" 2>/dev/null | awk 'NR==2{print $2}' || echo "?")
echo ""
echo -e "  ${YELLOW}===  SMB Share Disk Space  ===${NC}"
info "Total : ${BOLD}${SMB_TOTAL}${NC}  Used : ${BOLD}${SMB_USED}${NC}  Free : ${BOLD}${GREEN}${SMB_FREE}${NC}"

# =============================================================================
# CLEANUP TRAP
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
# STEP 4 of 4  =  Backup List & Action
# =============================================================================
step "STEP 4 of 4  =  Select Backup & Action"

# --- Scan ---
echo -e "  ${YELLOW}===  Scanning available backups on SMB share  ===${NC}"
echo ""
mapfile -t BACKUPS < <(find "${MOUNT_POINT}" -maxdepth 2 -name "blkid.list" 2>/dev/null \
    | sed 's|/blkid.list||' | xargs -I{} basename {} | sort)

if [[ ${#BACKUPS[@]} -eq 0 ]]; then
    warn "No existing backups found on SMB share."
    echo ""
    echo -e "  ${YELLOW}===${NC} ${GREEN}${BOLD}[1] BACKUP${NC}  --- create new image of /dev/${DISK}"
    echo -e "  ${YELLOW}===${NC} ${RED}${BOLD}[0] EXIT${NC}"
    echo ""
    read -r -p "  Enter choice: " EMPTY_CHOICE
    [[ "$EMPTY_CHOICE" == "1" ]] || exit 0
    # jump straight to backup
    DO_BACKUP=1
else
    echo -e "  Found ${BOLD}${#BACKUPS[@]}${NC} backup(s):"
    echo ""
    print_backup_list BACKUPS
    echo ""

    # -------------------------------------------------------------------------
    # Select backup number OR choose to make a new backup
    # -------------------------------------------------------------------------
    echo -e "  ${YELLOW}===${NC} ${CYAN}${BOLD}[1-${#BACKUPS[@]}]${NC}  Select backup to restore or delete"
    echo -e "  ${YELLOW}===${NC} ${GREEN}${BOLD}[B]${NC}       Create new BACKUP image of /dev/${DISK}"
    echo -e "  ${YELLOW}===${NC} ${RED}${BOLD}[0]${NC}       Exit"
    echo ""
    read -r -p "  Your choice: " TOP_CHOICE
    echo ""

    if [[ "${TOP_CHOICE,,}" == "b" ]]; then
        DO_BACKUP=1
    elif [[ "$TOP_CHOICE" == "0" ]]; then
        warn "Exiting."; exit 0
    elif [[ "$TOP_CHOICE" =~ ^[0-9]+$ ]] && \
         [[ "$TOP_CHOICE" -ge 1 ]] && \
         [[ "$TOP_CHOICE" -le ${#BACKUPS[@]} ]]; then

        SELECTED_BACKUP="${BACKUPS[$((TOP_CHOICE-1))]}"
        SELECTED_DIR="${MOUNT_POINT}/${SELECTED_BACKUP}"
        SEL_SIZE=$(du -sh "${SELECTED_DIR}" 2>/dev/null | cut -f1 || echo "?")

        echo -e "  Selected : ${CYAN}${BOLD}${SELECTED_BACKUP}${NC}   (${SEL_SIZE})"
        echo ""
        echo -e "  ${YELLOW}===${NC} ${GREEN}${BOLD}[1] RESTORE${NC}  --- restore this backup to /dev/${DISK}"
        echo -e "  ${YELLOW}===${NC} ${RED}${BOLD}[2] DELETE${NC}   --- permanently delete this backup from SMB"
        echo ""
        read -r -p "  Enter 1 or 2: " ACTION_CHOICE
        echo ""

        # =====================================================================
        # ACTION: RESTORE
        # =====================================================================
        if [[ "$ACTION_CHOICE" == "1" ]]; then

            echo -e "${SEP_EQ}"
            echo -e "  ${RED}${BOLD}!! WARNING: DESTRUCTIVE OPERATION !!${NC}"
            echo -e "${SEP_EQ}"
            echo -e "  ${RED}RESTORE will PERMANENTLY OVERWRITE /dev/${DISK}${NC}"
            echo -e "  ${RED}ALL existing data on the disk will be DESTROYED!${NC}"
            echo -e "${SEP_LINE}"
            echo -e "  Backup : ${BOLD}${SELECTED_BACKUP}${NC}   (${SEL_SIZE})   Target : ${BOLD}/dev/${DISK}${NC}"
            echo -e "  Time   : $(date '+%Y-%m-%d %H:%M:%S %Z')"
            echo -e "${SEP_LINE}"
            echo ""
            read -r -p "  Type YES to confirm restore (anything else = abort): " CONFIRM
            echo ""
            if [[ "$CONFIRM" != "YES" ]]; then
                warn "Restore ABORTED by user."; exit 0
            fi

            sleep 3
            ocs-sr -g auto -e1 auto -e2 -r -j2 -p true restoredisk "${SELECTED_BACKUP}" "${DISK}"

            echo ""
            echo -e "${SEP_EQ}"
            echo -e "  ${GREEN}${BOLD}RESTORE COMPLETED SUCCESSFULLY!${NC}"
            echo -e "  ${GREEN}Finished : $(date '+%Y-%m-%d %H:%M:%S %Z')${NC}"
            echo -e "  ${GREEN}Restored : ${SELECTED_BACKUP}  ==>  /dev/${DISK}${NC}"
            echo -e "  ${GREEN}You can now reboot the machine.${NC}"
            echo -e "${SEP_EQ}"
            exit 0

        # =====================================================================
        # ACTION: DELETE
        # =====================================================================
        elif [[ "$ACTION_CHOICE" == "2" ]]; then

            echo -e "${SEP_EQ}"
            echo -e "  ${RED}${BOLD}!! The following backup will be PERMANENTLY DELETED: !!${NC}"
            echo -e "${SEP_LINE}"
            echo -e "  ${RED}${BOLD}  ---  ${SELECTED_BACKUP}${NC}   (${SEL_SIZE})"
            echo -e "${SEP_LINE}"
            echo ""
            read -r -p "  Type YES to confirm deletion (anything else = abort): " DEL_CONFIRM
            echo ""
            if [[ "$DEL_CONFIRM" != "YES" ]]; then
                warn "Deletion ABORTED by user."; exit 0
            fi

            echo -e "  ${YELLOW}[DEL]${NC} Deleting ${BOLD}${SELECTED_BACKUP}${NC} ..."
            rm -rf "${SELECTED_DIR:?}"
            ok "Deleted : ${SELECTED_BACKUP}"

            SMB_FREE_NOW=$(df -h "${MOUNT_POINT}" 2>/dev/null | awk 'NR==2{print $4}' || echo "?")
            echo ""
            echo -e "${SEP_EQ}"
            echo -e "  ${GREEN}${BOLD}DELETE COMPLETED.${NC}"
            echo -e "  ${GREEN}Freed ~${SEL_SIZE}.  SMB free space now : ${BOLD}${SMB_FREE_NOW}${NC}"
            echo -e "${SEP_EQ}"
            exit 0

        else
            err "Invalid choice '${ACTION_CHOICE}'. Exiting."; exit 1
        fi

    else
        err "Invalid input '${TOP_CHOICE}'. Exiting."; exit 1
    fi
fi

# =============================================================================
# BACKUP  (reached via [B] or empty-share auto-select)
# =============================================================================

BACKUP_NAME="WinServer2016_Backup_$(date +%Y%m%d_%H%M)"

echo -e "  ${YELLOW}===  Scan NTFS partitions on /dev/${DISK}  ===${NC}"
echo ""
NTFS_PARTS=$(lsblk -rno NAME,FSTYPE "/dev/${DISK}" 2>/dev/null | awk '$2=="ntfs" {print $1}')

if [[ -z "$NTFS_PARTS" ]]; then
    warn "No NTFS partitions found on /dev/${DISK}. Skipping cleanup."
else
    WIN_PART="" WIN_MOUNT="" TOTAL_FREED=0

    for PART in $NTFS_PARTS; do
        PART_DEV="/dev/${PART}"
        TMP_MOUNT="/mnt/ntfs_part_${PART}"
        mkdir -p "${TMP_MOUNT}"

        info "Mounting ${BOLD}${PART_DEV}${NC} ..."
        ntfs-3g -o remove_hiberfile "${PART_DEV}" "${TMP_MOUNT}" 2>/dev/null || \
        mount -t ntfs-3g -o remove_hiberfile "${PART_DEV}" "${TMP_MOUNT}" 2>/dev/null || {
            warn "Cannot mount ${PART_DEV} --- skipping."; continue
        }

        PART_USED=$(df  -h "${TMP_MOUNT}" 2>/dev/null | awk 'NR==2{print $3}' || echo "?")
        PART_FREE=$(df  -h "${TMP_MOUNT}" 2>/dev/null | awk 'NR==2{print $4}' || echo "?")
        PART_TOTAL=$(df -h "${TMP_MOUNT}" 2>/dev/null | awk 'NR==2{print $2}' || echo "?")
        info "${PART_DEV}  ---  Total: ${BOLD}${PART_TOTAL}${NC}  Used: ${BOLD}${PART_USED}${NC}  Free: ${BOLD}${PART_FREE}${NC}"

        RECYCLE_PATH="${TMP_MOUNT}"/'$Recycle.Bin'
        FREED=$(clean_item '$Recycle.Bin' "${RECYCLE_PATH}" "dir")
        TOTAL_FREED=$(( TOTAL_FREED + FREED ))

        if [[ -d "${TMP_MOUNT}/Windows" ]]; then
            ok "Found Windows folder on ${BOLD}${PART_DEV}${NC}  --- system partition (C:)"
            WIN_PART="${PART_DEV}" WIN_MOUNT="${TMP_MOUNT}"

            echo ""
            echo -e "  ${YELLOW}===  Windows Partition Space Report  ===${NC}"
            info "Partition : ${BOLD}${WIN_PART}${NC}   Total / Used / Free : ${BOLD}${PART_TOTAL}${NC} / ${BOLD}${PART_USED}${NC} / ${BOLD}${PART_FREE}${NC}"
            echo ""
            echo -e "  ${YELLOW}===  Windows Temp Cleanup  ===${NC}"
            echo ""

            for _item in \
                "pagefile.sys|${WIN_MOUNT}/pagefile.sys|file" \
                "hiberfil.sys|${WIN_MOUNT}/hiberfil.sys|file" \
                "swapfile.sys|${WIN_MOUNT}/swapfile.sys|file" \
                "Windows\\Temp|${WIN_MOUNT}/Windows/Temp|dir" \
                "Windows\\Prefetch|${WIN_MOUNT}/Windows/Prefetch|dir" \
                "Windows\\Logs|${WIN_MOUNT}/Windows/Logs|dir" \
                "Windows\\Minidump|${WIN_MOUNT}/Windows/Minidump|dir" \
                "Win\\SoftwareDistrib\\Download|${WIN_MOUNT}/Windows/SoftwareDistribution/Download|dir" \
                "Win\\SoftwareDistrib\\PostRebootCache|${WIN_MOUNT}/Windows/SoftwareDistribution/PostRebootEventCache.V2|dir"
            do
                IFS='|' read -r _label _path _type <<< "${_item}"
                FREED=$(clean_item "${_label}" "${_path}" "${_type}")
                TOTAL_FREED=$(( TOTAL_FREED + FREED ))
            done

            if [[ -d "${WIN_MOUNT}/Users" ]]; then
                for USER_DIR in "${WIN_MOUNT}/Users/"*/; do
                    USER_TEMP="${USER_DIR}AppData/Local/Temp"
                    USERNAME=$(basename "${USER_DIR}")
                    [[ -d "${USER_TEMP}" ]] || continue
                    FREED=$(clean_item "Users\\${USERNAME}\\AppData\\Temp" "${USER_TEMP}" "dir")
                    TOTAL_FREED=$(( TOTAL_FREED + FREED ))
                done
            fi

            echo ""
            FREED_H=$(numfmt --to=iec-i --suffix=B "${TOTAL_FREED}" 2>/dev/null || \
                      echo "$(( TOTAL_FREED / 1024 / 1024 )) MB")
            echo -e "  ${GREEN}${BOLD}=== Total freed by cleanup: ${FREED_H} ===${NC}"
            PART_USED_AFTER=$(df -h "${WIN_MOUNT}" 2>/dev/null | awk 'NR==2{print $3}' || echo "?")
            info "Windows used AFTER cleanup : ${BOLD}${PART_USED_AFTER}${NC}  (actual data for Partclone)"
            echo ""

        else
            umount "${TMP_MOUNT}" 2>/dev/null || umount -l "${TMP_MOUNT}" 2>/dev/null || true
        fi
    done

    if [[ -z "$WIN_PART" ]]; then
        warn "Windows folder not found on any NTFS partition. Cleanup skipped."
    else
        umount "${WIN_MOUNT}" 2>/dev/null || umount -l "${WIN_MOUNT}" 2>/dev/null || true
        ok "Windows partition unmounted. Ready for imaging."
    fi
fi

echo ""
echo -e "  ${YELLOW}===  Pre-flight Space Check  ===${NC}"
SMB_FREE_NOW=$(df -h "${MOUNT_POINT}" 2>/dev/null | awk 'NR==2{print $4}' || echo "?")
DISK_SIZE=$(lsblk -dno SIZE "/dev/${DISK}" 2>/dev/null || echo "?")
info "SMB free : ${BOLD}${GREEN}${SMB_FREE_NOW}${NC}   Disk /dev/${DISK} : ${BOLD}${DISK_SIZE}${NC}   Compression -z1p ~ 30-60%% of used data."
echo ""

echo -e "  ${YELLOW}===  Clonezilla savedisk  ===${NC}"
echo ""
echo -e "  Disk    : ${BOLD}/dev/${DISK}${NC}   Backup : ${BOLD}${BACKUP_NAME}${NC}"
echo -e "  Target  : ${BOLD}${MOUNT_POINT}/${BACKUP_NAME}${NC}"
echo -e "  Method  : Partclone + pigz -z1p   Chunks : 4000 MB   I/O : -j2"
echo -e "  Started : $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo ""
echo -e "  ${RED}${BOLD}[WARNING]  Do NOT interrupt! This may take 15-60 minutes.${NC}"
sleep 3

ocs-sr -q2 -c -j2 -z1p -i 4000 -sfsck -senc -p true savedisk "${BACKUP_NAME}" "${DISK}"

echo ""
echo -e "${SEP_EQ}"
echo -e "  ${GREEN}${BOLD}BACKUP COMPLETED SUCCESSFULLY!${NC}"
echo -e "  ${GREEN}Finished : $(date '+%Y-%m-%d %H:%M:%S %Z')${NC}"
echo -e "  ${GREEN}Location : \\\\s.gincz.com\\soft\\ISO\\${BACKUP_NAME}${NC}"
BSIZE=$(du -sh "${MOUNT_POINT}/${BACKUP_NAME}" 2>/dev/null | cut -f1 || echo "?")
echo -e "  ${GREEN}Backup size on share : ${BOLD}${BSIZE}${NC}"
echo -e "${SEP_EQ}"

echo ""
