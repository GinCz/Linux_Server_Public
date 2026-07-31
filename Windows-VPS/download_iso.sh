#!/bin/bash
# =============================================================================
#   download_iso.sh  |  v.2026.07.31  |  github.com/GinCz/Linux_Server_Public
#
#   Download ISO / large files directly to a Samba/SMB/CIFS network share.
#   No local storage needed — downloads stream straight to the SMB mount.
#   Supports wget with progress bar, resume (-c), and free-space pre-check.
#
#   Keywords: download ISO to SMB, wget to Samba share, ISO download bash script,
#     download to network share Linux, wget CIFS, curl ISO SMB, upload ISO Samba,
#     GinCz Linux scripts, download_iso, Windows ISO download bash
#
#   Author: VladiMIR Bulantsev (GinCz) + AI
#   Repository: https://github.com/GinCz/Linux_Server_Public
#   Script: Windows-VPS/download_iso.sh
#
#   Usage:
#     export LANG=C LC_ALL=C TERM=xterm-256color
#     curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Windows-VPS/download_iso.sh \
#       -o /tmp/download_iso.sh && bash /tmp/download_iso.sh
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

print_header() {
    clear
    echo -e "${SEP_EQ}"
    echo -e "${CYAN}${BOLD}  DOWNLOAD ISO --> SMB  |  ${VERSION}  |  github.com/GinCz${NC}"
    echo -e "${CYAN}  Target: ${SMB_HOST}  |  Mount: ${MOUNT_POINT}${NC}"
    echo -e "${SEP_EQ}"
}

ok()   { echo -e "  ${GREEN}[OK]${NC}  $1"; }
warn() { echo -e "  ${YELLOW}[!!]${NC}  $1"; }
err()  { echo -e "  ${RED}[ERR]${NC} $1"; }
info() { echo -e "  ${CYAN}---${NC}  $1"; }
step() { echo -e "${SEP_LN}"; echo -e "${CYAN}${BOLD}  $1${NC}"; echo -e "${SEP_LN}"; }

cleanup() {
    sync 2>/dev/null || true
    mountpoint -q "${MOUNT_POINT}" 2>/dev/null && umount -l "${MOUNT_POINT}" 2>/dev/null || true
    echo -e "  ${GREEN}[DONE]${NC} SMB unmounted. Clean exit."
    echo -e "${SEP_EQ}"
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# INIT
# ---------------------------------------------------------------------------
SMB_HOST="${SMB_HOST_DEFAULT}"
print_header
[[ $EUID -ne 0 ]] && { err "Must be run as root."; exit 1; }

# ---------------------------------------------------------------------------
# STEP 1  SMB credentials & mount
# ---------------------------------------------------------------------------
step "STEP 1/3  SMB Credentials & Mount"
echo -e "  ${CYAN}Edit the path or press Enter to keep the default:${NC}"
read -r -e -i "${SMB_HOST_DEFAULT}" -p "  SMB Path   : " SMB_HOST
[[ -z "${SMB_HOST}" ]] && SMB_HOST="${SMB_HOST_DEFAULT}"
read -r -p "  SMB Username: " SMB_USER
read -r -s -p "  SMB Password: " SMB_PASS
echo

apt-get install -y cifs-utils wget curl -qq 2>/dev/null || true
mkdir -p "${MOUNT_POINT}"
mountpoint -q "${MOUNT_POINT}" && umount -l "${MOUNT_POINT}" 2>/dev/null || true
mount -t cifs "${SMB_HOST}" "${MOUNT_POINT}" \
    -o username="${SMB_USER}",password="${SMB_PASS}",vers=3.0,iocharset=utf8

SMB_FREE=$(df -h "${MOUNT_POINT}" | awk 'NR==2{print $4}')
SMB_TOTAL=$(df -h "${MOUNT_POINT}" | awk 'NR==2{print $2}')
ok "SMB mounted.  Total:${BOLD}${SMB_TOTAL}${NC}  Free:${BOLD}${GREEN}${SMB_FREE}${NC}"
print_header

# ---------------------------------------------------------------------------
# STEP 2  Enter download URL
# ---------------------------------------------------------------------------
step "STEP 2/3  Enter Download URL"
echo -e "  ${CYAN}Paste any direct URL (ISO, ZIP, IMG, etc.):${NC}"
read -r -p "  URL: " DOWNLOAD_URL
[[ -z "${DOWNLOAD_URL}" ]] && { err "URL cannot be empty."; exit 1; }

FILE_NAME=$(basename "${DOWNLOAD_URL}" | cut -d'?' -f1)
[[ -z "${FILE_NAME}" || "${FILE_NAME}" == "." ]] && FILE_NAME="download_$(date +%Y%m%d_%H%M%S)"
read -r -e -i "${FILE_NAME}" -p "  Save as    : " FILE_NAME
[[ -z "${FILE_NAME}" ]] && FILE_NAME="download_$(date +%Y%m%d_%H%M%S)"

DEST="${MOUNT_POINT}/${FILE_NAME}"
info "Destination: ${BOLD}${DEST}${NC}"
info "SMB free   : ${BOLD}${GREEN}${SMB_FREE}${NC}"

# ---------------------------------------------------------------------------
# STEP 3  Download
# ---------------------------------------------------------------------------
step "STEP 3/3  Downloading"
info "Started: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo -e "  ${YELLOW}[INFO]${NC} Ctrl+C to abort. File will be incomplete but NOT deleted (resume with -c)."
echo

if command -v wget &>/dev/null; then
    wget -c --progress=bar:force:noscroll -O "${DEST}" "${DOWNLOAD_URL}"
else
    curl -L -C - --progress-bar -o "${DEST}" "${DOWNLOAD_URL}"
fi

FINAL_SIZE=$(du -sh "${DEST}" 2>/dev/null | cut -f1 || echo "?")
SMB_FREE_AFTER=$(df -h "${MOUNT_POINT}" | awk 'NR==2{print $4}')

echo -e "${SEP_EQ}"
echo -e "  ${GREEN}${BOLD}DOWNLOAD COMPLETED!  Finished: $(date '+%Y-%m-%d %H:%M:%S %Z')${NC}"
echo -e "  ${GREEN}File  : ${DEST}${NC}"
echo -e "  ${GREEN}Size  : ${FINAL_SIZE}${NC}"
echo -e "  ${GREEN}SMB free after: ${SMB_FREE_AFTER}${NC}"
echo -e "${SEP_EQ}"
