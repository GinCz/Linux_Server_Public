#!/bin/bash
clear
# = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =
# install_clamav.sh — ClamAV full installer
# Installs ClamAV, fixes freshclam DB update (OOM), sets up swap,
# deploys /usr/local/bin/antivir, configures cron and aliases.
# Usage: bash /root/Linux_Server_Public/scripts/install_clamav.sh

CYAN='\033[01;96m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
RESET='\033[0m'
LINE="================================================================"

REPO="/root/Linux_Server_Public"
REPO_URL="https://github.com/GinCz/Linux_Server_Public.git"
SCAN_SRC="$REPO/scripts/scan_clamav.sh"
ANTIVIR_BIN="/usr/local/bin/antivir"
BASHRC="/root/.bashrc"
BASH_PROFILE="/root/.bash_profile"
SWAP_FILE="/swapfile"
SWAP_MIN_FREE_MB=2048   # minimum free disk space required after swap creation
SWAP_SIZE_MB=1024       # swap to create (1GB)

step() { echo -e "${YELLOW}  [$1] $2${RESET}"; }
ok()   { echo -e "        ${GREEN}✓ $1${RESET}"; }
err()  { echo -e "        ${RED}✗ $1${RESET}"; }

echo -e "${CYAN}${LINE}${RESET}"
echo -e "${GREEN}  ANTIVIR INSTALLER — ClamAV + freshclam + swap + cron${RESET}"
echo -e "${CYAN}${LINE}${RESET}"

# --- STEP 1: Repo sync -------------------------------------------------------
step "1/7" "Syncing repository..."
if [ ! -d "$REPO/.git" ]; then
    cd /root && git clone "$REPO_URL"
else
    cd "$REPO" && git pull origin main --no-rebase --no-edit 2>&1 | tail -3
fi
[ ! -f "$SCAN_SRC" ] && { err "$SCAN_SRC not found. Abort."; exit 1; }
ok "Repo ready"

# --- STEP 2: Install ClamAV --------------------------------------------------
step "2/7" "Installing ClamAV..."
export DEBIAN_FRONTEND=noninteractive
if ! command -v clamscan >/dev/null 2>&1; then
    apt-get update -yqq
    apt-get install -yqq clamav clamav-freshclam
    ok "ClamAV installed"
else
    ok "ClamAV already installed: $(clamscan --version | head -1)"
fi

# --- STEP 3: Swap setup -------------------------------------------------------
step "3/7" "Checking swap..."
SWAP_CURRENT=$(swapon --show=SIZE --noheadings 2>/dev/null | awk '{sum+=$1} END{print sum+0}')
if [ "${SWAP_CURRENT:-0}" -gt 0 ]; then
    ok "Swap already active ($(free -h | awk '/Swap/{print $2}'))"
elif [ -f "$SWAP_FILE" ]; then
    ok "Swapfile exists, activating..."
    swapon "$SWAP_FILE" 2>/dev/null || true
else
    # Check free disk space
    FREE_MB=$(df / --output=avail -m 2>/dev/null | tail -1 | tr -d ' ')
    NEED_MB=$(( SWAP_SIZE_MB + SWAP_MIN_FREE_MB ))
    if [ "${FREE_MB:-0}" -ge "$NEED_MB" ]; then
        echo -e "        Free disk: ${FREE_MB}MB — creating ${SWAP_SIZE_MB}MB swap..."
        fallocate -l ${SWAP_SIZE_MB}M "$SWAP_FILE" 2>/dev/null || dd if=/dev/zero of="$SWAP_FILE" bs=1M count="$SWAP_SIZE_MB" status=none
        chmod 600 "$SWAP_FILE"
        mkswap "$SWAP_FILE" > /dev/null
        swapon "$SWAP_FILE"
        ok "Swap ${SWAP_SIZE_MB}MB created and activated"
        # Make persistent
        grep -q "$SWAP_FILE" /etc/fstab 2>/dev/null || \
            echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
        ok "Added to /etc/fstab (persistent)"
    elif [ "${FREE_MB:-0}" -ge 512 ]; then
        # Not enough for 1GB, create smaller swap
        SMALL=$(( FREE_MB - SWAP_MIN_FREE_MB ))
        echo -e "        Low disk (${FREE_MB}MB free) — creating smaller ${SMALL}MB swap..."
        fallocate -l ${SMALL}M "$SWAP_FILE" 2>/dev/null || dd if=/dev/zero of="$SWAP_FILE" bs=1M count="$SMALL" status=none
        chmod 600 "$SWAP_FILE"
        mkswap "$SWAP_FILE" > /dev/null
        swapon "$SWAP_FILE"
        ok "Swap ${SMALL}MB created (disk space limited)"
        grep -q "$SWAP_FILE" /etc/fstab 2>/dev/null || \
            echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
    else
        err "Disk too full (${FREE_MB}MB free) — skipping swap. freshclam may fail on low-RAM servers!"
    fi
fi

# --- STEP 4: Fix freshclam config --------------------------------------------
step "4/7" "Configuring freshclam..."
FRESHCLAM_CONF="/etc/clamav/freshclam.conf"
if [ -f "$FRESHCLAM_CONF" ]; then
    # Ensure Checks is reasonable (12 per day = every 2h)
    if grep -q '^Checks' "$FRESHCLAM_CONF"; then
        sed -i 's/^Checks.*/Checks 12/' "$FRESHCLAM_CONF"
    else
        echo 'Checks 12' >> "$FRESHCLAM_CONF"
    fi
    # Remove Example line if present
    sed -i '/^Example$/d' "$FRESHCLAM_CONF"
    ok "freshclam.conf updated (Checks=12)"
fi

# Stop service before manual update
systemctl stop clamav-freshclam 2>/dev/null || true

# Update DB only if missing or older than 24h
DB_DAILY="/var/lib/clamav/daily.cvd"
NEED_UPDATE=0
if [ ! -f "$DB_DAILY" ]; then
    NEED_UPDATE=1
else
    DB_AGE=$(( $(date +%s) - $(stat -c %Y "$DB_DAILY" 2>/dev/null || echo 0) ))
    [ "$DB_AGE" -gt 86400 ] && NEED_UPDATE=1
fi

if [ "$NEED_UPDATE" -eq 1 ]; then
    echo -e "        Downloading virus definitions (this takes ~1 min)..."
    # Remove broken/incomplete DB files
    rm -f /var/lib/clamav/*.cvd /var/lib/clamav/*.cld 2>/dev/null
    nice -n 19 ionice -c3 freshclam --stdout 2>&1 | grep -E '(updated|failed|ERROR|version:|Testing)' || true
    if [ -f "$DB_DAILY" ]; then
        ok "Virus DB updated (daily: $(stat -c %y $DB_DAILY | cut -d. -f1))"
    else
        err "DB update failed — run 'freshclam --stdout' manually to debug"
    fi
else
    ok "Virus DB is fresh (< 24h old), skipping update"
fi

# Restart freshclam service
systemctl enable clamav-freshclam 2>/dev/null || true
systemctl start clamav-freshclam 2>/dev/null || true

# --- STEP 5: Deploy antivir binary -------------------------------------------
step "5/7" "Installing /usr/local/bin/antivir..."
cp "$SCAN_SRC" "$ANTIVIR_BIN"
chmod +x "$ANTIVIR_BIN"
ok "Installed: $ANTIVIR_BIN"

# --- STEP 6: Setup cron -------------------------------------------------------
step "6/7" "Setting up cron (daily scan at 03:00)..."
CRON_LINE="0 3 * * * /usr/local/bin/antivir >/dev/null 2>&1"
CRON_MARKER="# antivir-clamav-daily"
# Remove old entry if exists
crontab -l 2>/dev/null | grep -v 'antivir' | grep -v 'clamav' > /tmp/_cron_tmp 2>/dev/null || true
# Add fresh
echo "$CRON_MARKER" >> /tmp/_cron_tmp
echo "$CRON_LINE" >> /tmp/_cron_tmp
crontab /tmp/_cron_tmp
rm -f /tmp/_cron_tmp
ok "Cron job set: daily at 03:00"

# --- STEP 7: Write aliases ---------------------------------------------------
step "7/7" "Writing aliases..."
ALIAS_MARKER="# === antivir aliases ==="
for FILE in "$BASHRC" "$BASH_PROFILE"; do
    touch "$FILE"
    # Remove old block
    grep -q "$ALIAS_MARKER" "$FILE" 2>/dev/null && \
        sed -i "/${ALIAS_MARKER}/,/# ===/{ /# ===/!d; /${ALIAS_MARKER}/d }" "$FILE" 2>/dev/null
    sed -i '/alias antivir/d' "$FILE" 2>/dev/null
    printf '%s\n' \
        "" \
        "$ALIAS_MARKER" \
        "alias antivir='/usr/local/bin/antivir'" \
        "alias antivir-log='tail -50 /var/log/clamav/manual_scan.log'" \
        "alias antivir-status='/usr/local/bin/antivir status'" >> "$FILE"
done
source "$BASHRC" 2>/dev/null || true
ok "Aliases written to .bashrc and .bash_profile"

# --- DONE --------------------------------------------------------------------
echo -e ""
echo -e "${CYAN}${LINE}${RESET}"
echo -e "${GREEN}  DONE! antivir is ready.${RESET}"
echo -e ""
echo -e "  ${YELLOW}Usage:${RESET}"
echo -e "    ${GREEN}antivir${RESET}         — start full scan (background)"
echo -e "    ${GREEN}antivir status${RESET}  — check if scan is running"
echo -e "    ${GREEN}antivir log${RESET}     — tail last scan log"
echo -e "    ${GREEN}antivir-log${RESET}     — same via alias"
echo -e ""
echo -e "  ${YELLOW}Scan paths:${RESET} /etc /root /home /var/www"
echo -e "  ${YELLOW}Cron:${RESET}       daily at 03:00"
echo -e "  ${YELLOW}Telegram:${RESET}   alert on completion"
echo -e "  ${YELLOW}Swap:${RESET}       $(free -h | awk '/Swap/{print $2}') active"
echo -e "  ${YELLOW}Virus DB:${RESET}   $(ls -lh /var/lib/clamav/daily.cvd 2>/dev/null | awk '{print $5" — "$6" "$7" "$8}' || echo 'not found')"
echo -e ""
echo -e "  Run: ${CYAN}source ~/.bashrc${RESET}  — to activate aliases now"
echo -e "${CYAN}${LINE}${RESET}"
# = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =
