#!/bin/bash
# =============================================================================
#   upload_iso_to_smb.sh  |  ISO Uploader to Samba/SMB  |  v.2026.07.31
#   github.com/GinCz/Linux_Server_Public
#
#   ISO Uploader -- download ISO files and store directly on Samba/SMB share
#   No local storage needed. Streams ISO via wget directly to mounted SMB share.
#   Part of the WinSambaBackup / Linux_Server_Public toolkit.
#
#   Keywords: ISO upload SMB, download ISO Samba, ISO to network share,
#     Windows ISO download Linux, ISO uploader bash, wget SMB ISO,
#     Clonezilla ISO, Windows Server ISO download, KVM ISO upload,
#     CIFS ISO upload, Linux ISO downloader, GinCz scripts
#
#   Author: VladiMIR Bulantsev (GinCz) + AI
#   Repository: https://github.com/GinCz/Linux_Server_Public
#   Script: Windows-VPS/upload_iso_to_smb.sh
#
#   Usage:
#     export LANG=C LC_ALL=C TERM=xterm-256color
#     curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Windows-VPS/upload_iso_to_smb.sh \
#       -o /tmp/upload_iso_to_smb.sh && bash /tmp/upload_iso_to_smb.sh
# =============================================================================
clear
set -euo pipefail

VERSION="v.2026.07.31"
SMB_HOST_DEFAULT="//s.gincz.com/soft/ISO"
MOUNT_POINT="/mnt/smb_iso"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
SEP_EQ="${YELLOW}==========================================================================================${NC}"
SEP_LN="${YELLOW}------------------------------------------------------------------------------------------${NC}"

step()  { echo -e "${SEP_LN}"; echo -e "${CYAN}${BOLD}  $1${NC}"; echo -e "${SEP_LN}"; }
ok()    { echo -e "  ${GREEN}[OK]${NC}  $1"; }
warn()  { echo -e "  ${YELLOW}[!!]${NC}  $1"; }
err()   { echo -e "  ${RED}[ERR]${NC} $1"; }
info()  { echo -e "  ${CYAN}---${NC}  $1"; }

cleanup() {
    echo -e "${SEP_LN}"
    echo -e "  ${YELLOW}[CLEANUP]${NC} Unmounting SMB share..."
    sync
    umount -l "${MOUNT_POINT}" 2>/dev/null || true
    echo -e "  ${GREEN}[DONE]${NC} Unmounted. Clean exit."
    echo -e "${SEP_EQ}"
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# HEADER
# ---------------------------------------------------------------------------
print_header() {
    clear
    echo -e "${SEP_EQ}"
    echo -e "${CYAN}${BOLD}  ISO Uploader to SMB  |  WinSambaBackup toolkit  |  ${VERSION}  |  github.com/GinCz${NC}"
    echo -e "${CYAN}  Share: ${SMB_HOST}  |  Target: ${MOUNT_POINT}${NC}"
    echo -e "${SEP_EQ}"
}

[[ $EUID -ne 0 ]] && { err "Must be run as root."; exit 1; }
SMB_HOST="${SMB_HOST_DEFAULT}"
print_header

# ---------------------------------------------------------------------------
# STEP 1  Credentials
# ---------------------------------------------------------------------------
step "STEP 1/4  Samba/SMB Connection & Credentials"
echo -e "  ${CYAN}Edit the path or press Enter to keep the default:${NC}"
read -r -e -i "${SMB_HOST_DEFAULT}" -p "  SMB Path   : " SMB_HOST
[[ -z "${SMB_HOST}" ]] && SMB_HOST="${SMB_HOST_DEFAULT}"
read -r -p "  SMB Username: " SMB_USER
read -r -s -p "  SMB Password: " SMB_PASS
echo
ok "Path: ${BOLD}${SMB_HOST}${NC}  |  User: ${BOLD}${SMB_USER}${NC}"
print_header

# ---------------------------------------------------------------------------
# STEP 2  Deps + Mount
# ---------------------------------------------------------------------------
step "STEP 2/4  Install Dependencies & Mount Samba Share"
apt-get update -qq
apt-get install -y cifs-utils wget -qq
ok "Dependencies installed: cifs-utils wget"
mkdir -p "${MOUNT_POINT}"
mountpoint -q "${MOUNT_POINT}" && umount -l "${MOUNT_POINT}"
mount -t cifs "${SMB_HOST}" "${MOUNT_POINT}" \
    -o username="${SMB_USER}",password="${SMB_PASS}",vers=3.0,iocharset=utf8
SMB_FREE=$(df -h "${MOUNT_POINT}" | awk 'NR==2{printf "Total:%s  Used:%s  Free:%s",$2,$3,$4}')
ok "SMB mounted.  ${SMB_FREE}"

# ---------------------------------------------------------------------------
# STEP 3  ISO selection
# ---------------------------------------------------------------------------
step "STEP 3/4  Select ISO to Download"
echo -e "  ${CYAN}Preset ISO images:${NC}"
echo -e "  ${YELLOW}[1]${NC}  Windows Server 2022 Evaluation  (~5.4 GB)"
echo -e "  ${YELLOW}[2]${NC}  Windows Server 2019 Evaluation  (~5.1 GB)"
echo -e "  ${YELLOW}[3]${NC}  Ubuntu 24.04 LTS Server          (~2.6 GB)"
echo -e "  ${YELLOW}[4]${NC}  Debian 12 Netinstall             (~0.7 GB)"
echo -e "  ${YELLOW}[0]${NC}  Enter custom URL"
echo -e "${SEP_LN}"
read -r -p "  Your choice: " ISO_CHOICE

case "${ISO_CHOICE}" in
    1) ISO_URL="https://software-download.microsoft.com/download/sg/20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
       ISO_NAME="WinServer2022_Eval.iso" ;;
    2) ISO_URL="https://software-download.microsoft.com/download/pr/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
       ISO_NAME="WinServer2019_Eval.iso" ;;
    3) ISO_URL="https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso"
       ISO_NAME="ubuntu-24.04-server.iso" ;;
    4) ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.0.0-amd64-netinst.iso"
       ISO_NAME="debian-12-netinstall.iso" ;;
    0) read -r -p "  Enter ISO URL: " ISO_URL
       read -r -e -p "  Filename to save as: " ISO_NAME ;;
    *) err "Invalid choice."; exit 1 ;;
esac

info "ISO: ${BOLD}${ISO_NAME}${NC}"
info "URL: ${ISO_URL}"
info "Destination: ${BOLD}${MOUNT_POINT}/${ISO_NAME}${NC}"

# ---------------------------------------------------------------------------
# STEP 4  Download
# ---------------------------------------------------------------------------
step "STEP 4/4  Downloading ISO to Samba Share"
echo -e "  ${RED}${BOLD}[INFO] Do NOT interrupt! Large files may take several minutes.${NC}"
sleep 2
wget -c --show-progress -O "${MOUNT_POINT}/${ISO_NAME}" "${ISO_URL}"
FINAL_SIZE=$(du -sh "${MOUNT_POINT}/${ISO_NAME}" 2>/dev/null | cut -f1 || echo "?")
SMB_FREE_NOW=$(df -h "${MOUNT_POINT}" | awk 'NR==2{print $4}')
echo -e "${SEP_EQ}"
echo -e "  ${GREEN}${BOLD}ISO UPLOAD COMPLETED!  $(date '+%Y-%m-%d %H:%M:%S %Z')${NC}"
echo -e "  ${GREEN}File: ${MOUNT_POINT}/${ISO_NAME}  |  Size: ${FINAL_SIZE}  |  SMB free: ${SMB_FREE_NOW}${NC}"
echo -e "${SEP_EQ}"
