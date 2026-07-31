#!/bin/bash
# =============================================================================
#   WinSambaBackup  |  backup_to_smb.sh  |  v.2026.07.31j
#   github.com/GinCz/Linux_Server_Public
#
#   WinSambaBackup — Windows bare-metal backup & restore over Samba/SMB
#   Uses Clonezilla + Partclone + pigz to create compressed disk images
#   and store them directly on a CIFS/SMB/Samba network share.
#   No local storage needed. Runs from any Live/recovery system.
#
#   Keywords: WinSambaBackup, Windows backup SMB, Samba backup script,
#     Clonezilla SMB, bare-metal backup Linux, Windows Server backup bash,
#     Partclone CIFS, disk image SMB share, KVM backup Clonezilla,
#     backup restore delete Samba, ntfs-3g backup, pigz disk image,
#     GinCz Linux scripts, backup_to_smb
#
#   Author: VladiMIR Bulantsev (GinCz) + AI
#   Repository: https://github.com/GinCz/Linux_Server_Public
#   Script: scripts/backup_to_smb.sh
#
#   Changelog:
#     v.2026.07.31j  - Rebranded to WinSambaBackup; SMB path editable with default
#     v.2026.07.31i  - Separators 90 chars; [0]=New Backup; no Exit option
#     v.2026.07.31h  - 7-method 1024x768 enforcement; compact single-line output
#     v.2026.07.31g  - New flow: creds -> mount -> list -> select -> action
#     v.2026.07.31f  - DELETE action added; select backup then [1]Restore/[2]Delete
#     v.2026.07.31e  - RESTORE submenu groundwork
#     v.2026.07.31d  - Plain-text banner (ASCII-art broken in KVM VNC)
#     v.2026.07.31c  - Fixed arithmetic crash in clean_item(); fixed $Recycle.Bin expansion
#     v.2026.07.31b  - 10-category Windows temp cleanup; smart NTFS partition detection
#     v.2026.07.31   - Initial version
#
#   Usage:
#     export LANG=C LC_ALL=C TERM=xterm-256color
#     curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/backup_to_smb.sh \
#       -o /tmp/backup_to_smb.sh && bash /tmp/backup_to_smb.sh
# =============================================================================
clear
set -euo pipefail

VERSION="v.2026.07.31j"
SMB_HOST_DEFAULT="//s.gincz.com/soft/ISO"
MOUNT_POINT="/home/partimag"
DISK="sda"
TIMEZONE="Europe/Prague"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
SEP_EQ="${YELLOW}==========================================================================================${NC}"
SEP_LN="${YELLOW}------------------------------------------------------------------------------------------${NC}"

# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------
set_resolution() {
    command -v fbset &>/dev/null && fbset -g 1024 768 1024 768 32 2>/dev/null || true
    for fb in /sys/class/graphics/fb*/virtual_size; do
        [[ -f "$fb" ]] && echo "1024,768" > "$fb" 2>/dev/null || true
    done
    command -v setterm &>/dev/null && setterm --resize 2>/dev/null || true
    [[ -n "${DISPLAY:-}" ]] && command -v xrandr &>/dev/null && xrandr -s 1024x768 2>/dev/null || true
    stty cols 128 rows 48 2>/dev/null || true
    printf '\033[8;48;128t' 2>/dev/null || true
}

print_header() {
    clear
    echo -e "${SEP_EQ}"
    echo -e "${CYAN}${BOLD}  WinSambaBackup  |  Clonezilla+Partclone  |  ${VERSION}  |  github.com/GinCz${NC}"
    echo -e "${CYAN}  Share: ${SMB_HOST}  |  Disk: /dev/${DISK}${NC}"
    echo -e "${SEP_EQ}"
}

step()  { echo -e "${SEP_LN}"; echo -e "${CYAN}${BOLD}  $1${NC}"; echo -e "${SEP_LN}"; }
ok()    { echo -e "  ${GREEN}[OK]${NC}  $1"; }
warn()  { echo -e "  ${YELLOW}[!!]${NC}  $1"; }
err()   { echo -e "  ${RED}[ERR]${NC} $1"; }
info()  { echo -e "  ${CYAN}---${NC}  $1"; }

clean_item() {
    local label="$1" target="$2" type="$3"
    if [[ "$type" == "file" && ! -f "$target" ]]; then warn "Skip: ${label}" >&2; echo 0; return; fi
    if [[ "$type" == "dir"  && ! -d "$target" ]]; then warn "Skip: ${label}" >&2; echo 0; return; fi
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
        echo -e "  ${YELLOW}===${NC} ${CYAN}${BOLD}[$((i+1))]${NC}  ${BOLD}${_arr[$i]}${NC}  ${BSIZE}  ${BDATE}"
    done
}

# ---------------------------------------------------------------------------
# INIT
# ---------------------------------------------------------------------------
set_resolution
SMB_HOST="${SMB_HOST_DEFAULT}"
print_header
[[ $EUID -ne 0 ]] && { err "Must be run as root."; exit 1; }

# ---------------------------------------------------------------------------
# STEP 1  Timezone
# ---------------------------------------------------------------------------
step "STEP 1/4  Timezone & Console"
timedatectl set-timezone "${TIMEZONE}" 2>/dev/null || \
    ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
ok "TZ: ${BOLD}${TIMEZONE}${NC}  $(date '+%Z %z  %Y-%m-%d %H:%M:%S')"
ok "Console: 128x48 requested (1024x768 equivalent)"

# ---------------------------------------------------------------------------
# STEP 2  SMB Path + Credentials
# ---------------------------------------------------------------------------
step "STEP 2/4  SMB Connection & Credentials  [WinSambaBackup]"
echo -e "  ${CYAN}Edit the path or press Enter to keep the default:${NC}"
# read -e -i: readline editing with pre-filled default (Backspace/Ctrl+U to clear)
read -r -e -i "${SMB_HOST_DEFAULT}" -p "  SMB Path   : " SMB_HOST
[[ -z "${SMB_HOST}" ]] && SMB_HOST="${SMB_HOST_DEFAULT}"
read -r -p "  SMB Username: " SMB_USER
read -r -s -p "  SMB Password: " SMB_PASS
echo
ok "Path: ${BOLD}${SMB_HOST}${NC}  |  User: ${BOLD}${SMB_USER}${NC}"
print_header

# ---------------------------------------------------------------------------
# STEP 3  Deps + Mount
# ---------------------------------------------------------------------------
step "STEP 3/4  Install Dependencies & Mount SMB Share"
echo -e "  Packages: clonezilla  cifs-utils  pigz  ntfs-3g"
apt-get update -qq
apt-get install -y clonezilla cifs-utils pigz ntfs-3g -qq
ok "All dependencies installed."
mkdir -p "${MOUNT_POINT}"
if mountpoint -q "${MOUNT_POINT}"; then
    warn "Already mounted - remounting..."
    umount -l "${MOUNT_POINT}"
fi
echo -e "  Mounting ${BOLD}${SMB_HOST}${NC} --> ${BOLD}${MOUNT_POINT}${NC} ..."
mount -t cifs "${SMB_HOST}" "${MOUNT_POINT}" \
    -o username="${SMB_USER}",password="${SMB_PASS}",vers=3.0,iocharset=utf8
ok "SMB mounted.  $(df -h "${MOUNT_POINT}" 2>/dev/null | awk 'NR==2{printf "Total:%s  Used:%s  Free:%s",$2,$3,$4}')"

# ---------------------------------------------------------------------------
# CLEANUP TRAP
# ---------------------------------------------------------------------------
cleanup() {
    echo -e "${SEP_LN}"
    echo -e "  ${YELLOW}[CLEANUP]${NC} Syncing & unmounting..."
    sync; sleep 2
    for mp in /mnt/ntfs_part_*; do
        [[ -d "$mp" ]] && mountpoint -q "$mp" 2>/dev/null && umount -l "$mp" 2>/dev/null || true
    done
    umount -l "${MOUNT_POINT}" 2>/dev/null || true
    echo -e "  ${GREEN}[DONE]${NC} All mounts released. Clean exit."
    echo -e "${SEP_EQ}"
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# STEP 4  Backup list & action
# ---------------------------------------------------------------------------
step "STEP 4/4  Select Backup & Action"
echo -e "  ${YELLOW}=== WinSambaBackup: Scanning SMB share for Clonezilla images... ===${NC}"
mapfile -t BACKUPS < <(find "${MOUNT_POINT}" -maxdepth 2 -name "blkid.list" 2>/dev/null \
    | sed 's|/blkid.list||' | xargs -I{} basename {} | sort)

if [[ ${#BACKUPS[@]} -eq 0 ]]; then
    warn "No WinSambaBackup images found on SMB share."
    echo -e "  ${YELLOW}===${NC} ${GREEN}${BOLD}[0]${NC} Create new BACKUP image of /dev/${DISK}"
    read -r -p "  Enter 0 to start backup (Ctrl+C to abort): " EMPTY_CHOICE
    [[ "$EMPTY_CHOICE" == "0" ]] || exit 0
    DO_BACKUP=1
else
    echo -e "  Found ${BOLD}${#BACKUPS[@]}${NC} WinSambaBackup image(s):"
    print_backup_list BACKUPS
    echo -e "${SEP_LN}"
    echo -e "  Enter backup number [1-${#BACKUPS[@]}] to manage  ${YELLOW}||${NC}  ${GREEN}${BOLD}[0]${NC} Create new BACKUP"
    read -r -p "  Your choice: " TOP_CHOICE

    if [[ "$TOP_CHOICE" == "0" ]]; then
        DO_BACKUP=1
    elif [[ "$TOP_CHOICE" =~ ^[0-9]+$ ]] && \
         [[ "$TOP_CHOICE" -ge 1 ]] && [[ "$TOP_CHOICE" -le ${#BACKUPS[@]} ]]; then

        SELECTED_BACKUP="${BACKUPS[$((TOP_CHOICE-1))]}"
        SELECTED_DIR="${MOUNT_POINT}/${SELECTED_BACKUP}"
        SEL_SIZE=$(du -sh "${SELECTED_DIR}" 2>/dev/null | cut -f1 || echo "?")
        echo -e "  Selected: ${CYAN}${BOLD}${SELECTED_BACKUP}${NC}  (${SEL_SIZE})"
        echo -e "  ${YELLOW}===${NC} ${GREEN}${BOLD}[1] RESTORE${NC} -- restore to /dev/${DISK}  ${YELLOW}||${NC}  ${RED}${BOLD}[2] DELETE${NC} -- remove from SMB"
        read -r -p "  Enter 1 or 2: " ACTION_CHOICE

        if [[ "$ACTION_CHOICE" == "1" ]]; then
            echo -e "${SEP_EQ}"
            echo -e "  ${RED}${BOLD}!! WARNING: DESTRUCTIVE OPERATION !!${NC}"
            echo -e "  ${RED}RESTORE will PERMANENTLY OVERWRITE /dev/${DISK} -- ALL data will be DESTROYED!${NC}"
            echo -e "${SEP_LN}"
            echo -e "  Backup: ${BOLD}${SELECTED_BACKUP}${NC}  (${SEL_SIZE})  -->  /dev/${DISK}  |  $(date '+%Y-%m-%d %H:%M:%S %Z')"
            echo -e "${SEP_LN}"
            read -r -p "  Type YES to confirm restore (anything else = abort): " CONFIRM
            if [[ "$CONFIRM" != "YES" ]]; then warn "Restore ABORTED."; exit 0; fi
            sleep 3
            ocs-sr -g auto -e1 auto -e2 -r -j2 -p true restoredisk "${SELECTED_BACKUP}" "${DISK}"
            echo -e "${SEP_EQ}"
            echo -e "  ${GREEN}${BOLD}RESTORE COMPLETED!  $(date '+%Y-%m-%d %H:%M:%S %Z')${NC}"
            echo -e "  ${GREEN}${SELECTED_BACKUP} ==> /dev/${DISK}  |  You can now reboot.${NC}"
            echo -e "${SEP_EQ}"
            exit 0

        elif [[ "$ACTION_CHOICE" == "2" ]]; then
            echo -e "${SEP_EQ}"
            echo -e "  ${RED}${BOLD}!! PERMANENTLY DELETE: ${SELECTED_BACKUP}  (${SEL_SIZE}) !!${NC}"
            echo -e "${SEP_LN}"
            read -r -p "  Type YES to confirm deletion (anything else = abort): " DEL_CONFIRM
            if [[ "$DEL_CONFIRM" != "YES" ]]; then warn "Deletion ABORTED."; exit 0; fi
            echo -e "  ${YELLOW}[DEL]${NC} Deleting ${BOLD}${SELECTED_BACKUP}${NC} ..."
            rm -rf "${SELECTED_DIR:?}"
            ok "Deleted: ${SELECTED_BACKUP}  |  SMB free now: $(df -h "${MOUNT_POINT}" 2>/dev/null | awk 'NR==2{print $4}')"
            echo -e "${SEP_EQ}"
            echo -e "  ${GREEN}${BOLD}DELETE COMPLETED.  Freed ~${SEL_SIZE}.${NC}"
            echo -e "${SEP_EQ}"
            exit 0
        else
            err "Invalid choice '${ACTION_CHOICE}'."; exit 1
        fi
    else
        err "Invalid input '${TOP_CHOICE}'."; exit 1
    fi
fi

# ---------------------------------------------------------------------------
# BACKUP  (WinSambaBackup — Clonezilla savedisk)
# ---------------------------------------------------------------------------
BACKUP_NAME="WinServer2016_Backup_$(date +%Y%m%d_%H%M)"
echo -e "  ${YELLOW}=== Scan NTFS partitions on /dev/${DISK} ===${NC}"
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
            warn "Cannot mount ${PART_DEV} - skipping."; continue
        }
        info "${PART_DEV}  $(df -h "${TMP_MOUNT}" 2>/dev/null | awk 'NR==2{printf "Total:%s Used:%s Free:%s",$2,$3,$4}')"
        RECYCLE_PATH="${TMP_MOUNT}"/'$Recycle.Bin'
        FREED=$(clean_item '$Recycle.Bin' "${RECYCLE_PATH}" "dir")
        TOTAL_FREED=$(( TOTAL_FREED + FREED ))
        if [[ -d "${TMP_MOUNT}/Windows" ]]; then
            ok "Windows partition: ${BOLD}${PART_DEV}${NC}"
            WIN_PART="${PART_DEV}" WIN_MOUNT="${TMP_MOUNT}"
            echo -e "  ${YELLOW}=== WinSambaBackup: Windows Temp Cleanup ===${NC}"
            for _item in \
                "pagefile.sys|${WIN_MOUNT}/pagefile.sys|file" \
                "hiberfil.sys|${WIN_MOUNT}/hiberfil.sys|file" \
                "swapfile.sys|${WIN_MOUNT}/swapfile.sys|file" \
                "Win\\Temp|${WIN_MOUNT}/Windows/Temp|dir" \
                "Win\\Prefetch|${WIN_MOUNT}/Windows/Prefetch|dir" \
                "Win\\Logs|${WIN_MOUNT}/Windows/Logs|dir" \
                "Win\\Minidump|${WIN_MOUNT}/Windows/Minidump|dir" \
                "Win\\SWDist\\Download|${WIN_MOUNT}/Windows/SoftwareDistribution/Download|dir" \
                "Win\\SWDist\\PostReboot|${WIN_MOUNT}/Windows/SoftwareDistribution/PostRebootEventCache.V2|dir"
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
                    FREED=$(clean_item "Users\\${USERNAME}\\Temp" "${USER_TEMP}" "dir")
                    TOTAL_FREED=$(( TOTAL_FREED + FREED ))
                done
            fi
            FREED_H=$(numfmt --to=iec-i --suffix=B "${TOTAL_FREED}" 2>/dev/null || echo "$(( TOTAL_FREED/1024/1024 )) MB")
            ok "Total freed: ${BOLD}${FREED_H}${NC}  |  Used after: $(df -h "${WIN_MOUNT}" 2>/dev/null | awk 'NR==2{print $3}')"
        else
            umount "${TMP_MOUNT}" 2>/dev/null || umount -l "${TMP_MOUNT}" 2>/dev/null || true
        fi
    done
    if [[ -z "$WIN_PART" ]]; then
        warn "Windows partition not found. Cleanup skipped."
    else
        umount "${WIN_MOUNT}" 2>/dev/null || umount -l "${WIN_MOUNT}" 2>/dev/null || true
        ok "Windows partition unmounted. Ready for WinSambaBackup imaging."
    fi
fi

SMB_FREE_NOW=$(df -h "${MOUNT_POINT}" 2>/dev/null | awk 'NR==2{print $4}' || echo "?")
DISK_SIZE=$(lsblk -dno SIZE "/dev/${DISK}" 2>/dev/null || echo "?")
info "Pre-flight: SMB free ${BOLD}${GREEN}${SMB_FREE_NOW}${NC}  |  Disk /dev/${DISK}: ${BOLD}${DISK_SIZE}${NC}  |  -z1p ~30-60%% of used data"
echo -e "  ${YELLOW}=== WinSambaBackup: Clonezilla savedisk ===${NC}"
info "Disk:/dev/${DISK}  Name:${BOLD}${BACKUP_NAME}${NC}  Target:${MOUNT_POINT}/${BACKUP_NAME}"
info "Method: Partclone+pigz -z1p  Chunks:4000MB  I/O:-j2  Started:$(date '+%Y-%m-%d %H:%M:%S %Z')"
echo -e "  ${RED}${BOLD}[WARNING] Do NOT interrupt! This may take 15-60 minutes.${NC}"
sleep 3

ocs-sr -q2 -c -j2 -z1p -i 4000 -sfsck -senc -p true savedisk "${BACKUP_NAME}" "${DISK}"

BSIZE=$(du -sh "${MOUNT_POINT}/${BACKUP_NAME}" 2>/dev/null | cut -f1 || echo "?")
echo -e "${SEP_EQ}"
echo -e "  ${GREEN}${BOLD}WinSambaBackup COMPLETED!  Finished: $(date '+%Y-%m-%d %H:%M:%S %Z')${NC}"
echo -e "  ${GREEN}Location: ${SMB_HOST}/${BACKUP_NAME}  |  Size: ${BSIZE}${NC}"
echo -e "${SEP_EQ}"
