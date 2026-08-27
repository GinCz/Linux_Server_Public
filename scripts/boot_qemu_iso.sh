#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  boot_qemu_iso.sh | [v2026-08-27-Universal]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Universal Live Linux/Cloud QEMU ISO/IMG bootloader (x86_64 + ARM64 / Ampere)
# Storage     : Dual Mode (HTTP Direct Stream/Cache at 1 Gbps + SSHFS fallback)
# Servers     : Bare-metal / GRML / Cloud VPS (Oracle Cloud / NetCup / AWS / VDSina / LeaseWeb)
# Usage       : bash scripts/boot_qemu_iso.sh
# ==========================================================================================

# ── Colors & Styling (Exact User Theme: Cyan 81) ──────────────────────────────────────────
C='\033[38;5;81m'     # Серо-голубой фирменный
G='\033[0;92m'       # Зеленый
Y='\033[0;93m'       # Желтый
R='\033[1;31m'       # Красный
W='\033[1;37m'       # Яркий белый
D='\033[38;5;244m'    # Серый / Dim
X='\033[0m'          # Сброс
BOLD='\033[1m'
HR="${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"

# ── Config & Auto-Detection ───────────────────────────────────────────────────────────────
SERVER_IP="${SERVER_IP:-152.53.182.222}"
HTTP_PORT="${HTTP_PORT:-8088}"
HTTP_URL="http://${SERVER_IP}:${HTTP_PORT}"
SSH_USER="${SSH_USER:-root}"
SSH_PASS="${SSH_PASS:-OKMokm-09}"
REMOTE_PATH="${REMOTE_PATH:-/storage/soft/ISO}"
LOCAL_ISO_DIR="/tmp/iso_cache"
VNC_PORT="5900"
VNC_DISPLAY=":0"
QEMU_PID=""
ARCH="$(uname -m)"

mkdir -p "$LOCAL_ISO_DIR"

# ── Auto-detect Current Public IP ────────────────────────────────────────────────────────
MY_PUBLIC_IP=""
if grep -qiE 'amazon|ec2' /sys/class/dmi/id/* 2>/dev/null; then
    _AWS_TOKEN="$(curl -s --connect-timeout 0.3 -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60" 2>/dev/null)"
    if [ -n "$_AWS_TOKEN" ]; then
        MY_PUBLIC_IP="$(curl -s --connect-timeout 0.3 -H "X-aws-ec2-metadata-token: $_AWS_TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)"
    fi
fi
[ -z "$MY_PUBLIC_IP" ] && MY_PUBLIC_IP="$(curl -s --connect-timeout 2 https://api.ipify.org 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')"
MY_PUBLIC_IP=${MY_PUBLIC_IP:-"127.0.0.1"}

# ── Auto-detect RAM ───────────────────────────────────────────────────────────────────────
TOTAL_RAM_MB=$(free -m 2>/dev/null | awk '/^Mem:/{print $2}')
TOTAL_RAM_MB=${TOTAL_RAM_MB:-1024}

if [ -z "$RAM_MB" ]; then
    if [ "$TOTAL_RAM_MB" -le 1200 ]; then
        RAM_MB=650
    elif [ "$TOTAL_RAM_MB" -le 2200 ]; then
        RAM_MB=1200
    elif [ "$TOTAL_RAM_MB" -le 4500 ]; then
        RAM_MB=2048
    elif [ "$TOTAL_RAM_MB" -le 9000 ]; then
        RAM_MB=4096
    else
        RAM_MB=6144
    fi
fi

# ── Auto-detect Target Disk ───────────────────────────────────────────────────────────────
mapfile -t DETECTED_DISKS < <(lsblk -dpno NAME,TYPE 2>/dev/null | awk '$2=="disk"{print $1}')

if [ -z "$TARGET_DISK" ]; then
    if [ ${#DETECTED_DISKS[@]} -ge 1 ]; then
        TARGET_DISK="${DETECTED_DISKS[0]}"
    else
        TARGET_DISK="/dev/sda"
    fi
fi

# ── Ctrl+C handler ───────────────────────────────────────────────────────────────────────
trap_ctrlc() {
    echo -e "\n${Y}[!] Ctrl+C — stopping QEMU...${X}"
    if [ -n "$QEMU_PID" ] && kill -0 "$QEMU_PID" 2>/dev/null; then
        kill "$QEMU_PID" 2>/dev/null
        wait "$QEMU_PID" 2>/dev/null
    fi
    QEMU_PID=""
    echo -e "${C}[*] Back to menu...${X}\n"
    sleep 1
}
trap trap_ctrlc INT

# ── Header Banner ─────────────────────────────────────────────────────────────────────────
print_banner() {
    echo -e "${HR}"
    echo -e "  ${C}Universal QEMU Boot Launcher${X}  |  ${W}github.com/GinCz${X}  |  Arch: ${G}${ARCH}${X}"
    echo -e "  ISO Storage: ${C}${HTTP_URL}${X}  |  Disk: ${Y}${TARGET_DISK}${X}  |  RAM: ${G}${RAM_MB} MB${X}"
    echo -e "  VNC: ${W}${BOLD}${MY_PUBLIC_IP}:${VNC_PORT}${X}"
    echo -e "${HR}"
}

# ── Check and install dependencies for Current Architecture ──────────────────────────────
check_deps() {
    local pkgs=("curl" "wget" "mc")
    
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        pkgs+=("qemu-system-arm" "qemu-efi-aarch64")
    else
        pkgs+=("qemu-system-x86")
    fi

    local need_install=0
    for pkg in "${pkgs[@]}"; do
        case "$pkg" in
            qemu-system-arm)
                command -v qemu-system-aarch64 >/dev/null 2>&1 || need_install=1 ;;
            qemu-system-x86)
                command -v qemu-system-x86_64 >/dev/null 2>&1 || need_install=1 ;;
            qemu-efi-aarch64)
                [ -f /usr/share/qemu-efi-aarch64/QEMU_EFI.fd ] || [ -f /usr/share/AAVMF/AAVMF_CODE.fd ] || need_install=1 ;;
            *)
                command -v "$pkg" >/dev/null 2>&1 || need_install=1 ;;
        esac
    done

    if [ "$need_install" -eq 1 ]; then
        echo -e "  ${Y}[!] Installing required packages for ${ARCH}...${X}"
        apt-get update -qq && apt-get install -y "${pkgs[@]}" >/dev/null 2>&1
        echo -e "  ${G}[+] Dependencies installed successfully${X}"
    fi
}

# ── KVM auto-detection ────────────────────────────────────────────────────────────────────
detect_kvm() {
    KVM_FLAG=""
    if [ ! -e /dev/kvm ]; then
        modprobe kvm 2>/dev/null
        if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
            modprobe kvm_arm 2>/dev/null
        else
            modprobe kvm_amd 2>/dev/null || modprobe kvm_intel 2>/dev/null
        fi
    fi
    
    if [ -e /dev/kvm ]; then
        KVM_FLAG="-enable-kvm"
        echo -e "  ${G}[+] Acceleration: KVM Hardware Enabled (${ARCH})${X}"
    else
        echo -e "  ${Y}[!] Acceleration: High-Performance Emulation (${ARCH})${X}"
    fi
}

# ── Fetch Image List via HTTP Storage ──────────────────────────────────────────────────────
fetch_iso_list() {
    echo -e "  ${C}[*] Fetching image catalog from ISO Server (${HTTP_URL})...${X}"
    local raw_html
    raw_html="$(curl -s --connect-timeout 4 "${HTTP_URL}/")"
    
    if [ -z "$raw_html" ]; then
        echo -e "  ${R}[!] Could not connect to ${HTTP_URL}. Checking network...${X}"
        exit 1
    fi

    mapfile -t ISOS < <(echo "$raw_html" | grep -oE 'href="[^"]+\.(iso|img|xz)"' | sed -E 's/href="([^"]+)"/\1/' | sed 's/%2B/+/g' | sort -f)
    
    if [ ${#ISOS[@]} -eq 0 ]; then
        echo -e "  ${R}[!] No ISO/IMG images found on server.${X}"
        exit 1
    fi
    echo -e "  ${G}[+] Loaded ${#ISOS[@]} available installation images${X}"
}

# ── Select Target Disk ────────────────────────────────────────────────────────────────────
select_disk() {
    if [ ${#DETECTED_DISKS[@]} -gt 1 ]; then
        echo -e "\n${C}DISKS DETECTED:${X}"
        for idx in "${!DETECTED_DISKS[@]}"; do
            size=$(lsblk -dno SIZE "${DETECTED_DISKS[$idx]}" 2>/dev/null)
            echo -e "  ${Y}$((idx + 1))${X}. ${W}${DETECTED_DISKS[$idx]}${X} (${size})"
        done
        echo ""
        read -rp "$(echo -e "Select Target Disk [1-${#DETECTED_DISKS[@]}] (Default: 1 - ${DETECTED_DISKS[0]}): ")" disk_choice
        if [[ "$disk_choice" =~ ^[0-9]+$ ]] && [ "$disk_choice" -ge 1 ] && [ "$disk_choice" -le "${#DETECTED_DISKS[@]}" ]; then
            TARGET_DISK="${DETECTED_DISKS[$((disk_choice - 1))]}"
        fi
    elif [ ${#DETECTED_DISKS[@]} -eq 1 ]; then
        TARGET_DISK="${DETECTED_DISKS[0]}"
    fi
}

# ── Print Image menu with Architecture Highlights ─────────────────────────────────────────
print_iso_menu() {
    local total=${#ISOS[@]}

    echo -e "\n${HR}"
    echo -e "  ${C}AVAILABLE IMAGES (${total} total)  |  Current Node: ${G}${ARCH}${X}"
    echo -e "${HR}"

    for i in "${!ISOS[@]}"; do
        local name="${ISOS[$i]}"
        local tag=""
        if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
            if [[ "$name" =~ [Aa][Rr][Mm]64|[Aa][Aa][Rr][Cc][Hh]64 ]]; then
                tag=" ${G}[ARM64 Native]${X}"
            else
                tag=" ${D}[x86 - Emulation]${X}"
            fi
        else
            if [[ "$name" =~ [Aa][Rr][Mm]64|[Aa][Aa][Rr][Cc][Hh]64 ]]; then
                tag=" ${D}[ARM64 - Emulation]${X}"
            else
                tag=" ${G}[x86_64 Native]${X}"
            fi
        fi
        printf "  ${Y}%2d${X}. %s%b\n" "$((i + 1))" "$name" "$tag"
    done

    echo -e "${HR}"
    echo -e "  ${D}Ctrl+C — stop QEMU  |  q — quit${X}"
}

# ══ MAIN ══════════════════════════════════════════════════════════════════════════════════════════

clear
check_deps
select_disk
detect_kvm
fetch_iso_list
print_banner

# Auto-open VNC ports in iptables and ufw
iptables -I INPUT 1 -p tcp --dport 5900:5905 -j ACCEPT 2>/dev/null || true
if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    ufw allow 5900:5905/tcp comment 'QEMU VNC' >/dev/null 2>&1 || true
fi

while true; do

    print_iso_menu

    TOTAL=${#ISOS[@]}
    echo ""
    read -rp "$(echo -e "${W}Select Image [1-${TOTAL}] or 'q' to quit: ${X}")" selection

    [[ "$selection" =~ ^[qQ]$ ]] && echo -e "\n${C}[*] Exiting...${X}\n" && break

    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "$TOTAL" ]; then
        echo -e "${R}[!] Invalid selection.${X}\n"
        continue
    fi

    ISO_NAME="${ISOS[$((selection - 1))]}"
    LOCAL_ISO_FILE="${LOCAL_ISO_DIR}/${ISO_NAME}"
    ENCODED_ISO_NAME=$(echo "$ISO_NAME" | sed 's/+/%2B/g')
    DOWNLOAD_URL="${HTTP_URL}/${ENCODED_ISO_NAME}"

    # Download or verify cached ISO file
    if [ ! -f "$LOCAL_ISO_FILE" ]; then
        echo -e "\n${C}[*] Downloading ${ISO_NAME} from high-speed storage...${X}"
        curl -C - --progress-bar -o "$LOCAL_ISO_FILE" "$DOWNLOAD_URL"
        if [ $? -ne 0 ] || [ ! -s "$LOCAL_ISO_FILE" ]; then
            echo -e "${R}[!] Download failed. Please retry.${X}"
            rm -f "$LOCAL_ISO_FILE"
            continue
        fi
        echo -e "${G}[+] Download complete!${X}"
    else
        echo -e "\n${G}[+] Using cached local image: ${ISO_NAME}${X}"
    fi

    # Check for VirtIO driver on ARM Windows
    VIRTIO_ATTACH=""
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        VIRTIO_FILE="${LOCAL_ISO_DIR}/virtio-win-0.1.285.iso"
        if [ ! -f "$VIRTIO_FILE" ]; then
            echo -e "${C}[*] Downloading VirtIO drivers (virtio-win)...${X}"
            curl -s -C - -o "$VIRTIO_FILE" "${HTTP_URL}/virtio-win-0.1.285.iso" 2>/dev/null || true
        fi
        if [ -s "$VIRTIO_FILE" ]; then
            VIRTIO_ATTACH="-drive file=${VIRTIO_FILE},media=cdrom"
        fi
    fi

    echo -e "\n${HR}"
    echo -e "  ${G}● LAUNCHING:${X} ${W}${BOLD}${ISO_NAME}${X}"
    echo -e "  ${C}VNC CONNECT:${X} ${W}${BOLD}${MY_PUBLIC_IP}:${VNC_PORT}${X}"
    echo -e "  ${D}Arch: ${ARCH}  |  Disk: ${TARGET_DISK}  |  RAM: ${RAM_MB}MB${X}"
    echo -e "${HR}\n"

    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        # ── ARM64 Execution Mode (Ampere A1 / Apple / Graviton) ───────────────────────────
        UEFI_BIOS="/usr/share/qemu-efi-aarch64/QEMU_EFI.fd"
        [ ! -f "$UEFI_BIOS" ] && UEFI_BIOS="/usr/share/AAVMF/AAVMF_CODE.fd"
        [ ! -f "$UEFI_BIOS" ] && UEFI_BIOS="/usr/share/edk2/aarch64/QEMU_EFI.fd"

        CPU_OPT="-cpu host"
        [ -z "$KVM_FLAG" ] && CPU_OPT="-cpu max"

        qemu-system-aarch64 \
            ${KVM_FLAG} \
            ${CPU_OPT} \
            -M virt \
            -m "${RAM_MB}" \
            -smp 4 \
            -bios "${UEFI_BIOS}" \
            -drive file="${TARGET_DISK}",format=raw,if=virtio \
            -cdrom "${LOCAL_ISO_FILE}" \
            ${VIRTIO_ATTACH} \
            -device usb-ehci -device usb-kbd -device usb-tablet \
            -device virtio-net-pci,netdev=net0 \
            -netdev user,id=net0 \
            -vnc "0.0.0.0${VNC_DISPLAY}" &

    else
        # ── x86_64 Execution Mode ────────────────────────────────────────────────────────
        BOOT_DRIVE_FLAG=""
        if [[ "$ISO_NAME" =~ \.iso$ ]]; then
            BOOT_DRIVE_FLAG="-boot d -cdrom \"$LOCAL_ISO_FILE\""
        else
            BOOT_DRIVE_FLAG="-boot c -drive file=\"$LOCAL_ISO_FILE\",format=raw,if=ide,readonly=on"
        fi

        eval qemu-system-x86_64 \
            "${KVM_FLAG}" \
            -m "${RAM_MB}" \
            ${BOOT_DRIVE_FLAG} \
            -drive file="${TARGET_DISK}",format=raw,if=ide \
            -net nic,model=e1000 \
            -net user \
            -vga std \
            -audiodev none,id=noaudio \
            -machine pcspk-audiodev=noaudio \
            -vnc "0.0.0.0${VNC_DISPLAY}" &
    fi

    QEMU_PID=$!
    wait "$QEMU_PID"
    QEMU_PID=""
    echo -e "\n${C}[*] QEMU session ended.${X}\n"
    sleep 1

done

echo -e "\n${HR}"
echo -e "  ${C}= Rooted by VladiMIR | AI = v2026.08.27 = github.com/GinCz =${X}"
echo -e "${HR}\n"
