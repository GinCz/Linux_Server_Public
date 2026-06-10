#!/bin/bash
clear
# = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =
# install_clamav_standalone.sh
# Zero-dependency ClamAV installer — no repo required.
# Installs ClamAV, swap (smart sizing), freshclam DB,
# deploys /usr/local/bin/antivir, cron, aliases.
# Usage: bash install_clamav_standalone.sh

CYAN='\033[01;96m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
RESET='\033[0m'
LINE="================================================================"

ANTIVIR_BIN="/usr/local/bin/antivir"
BASHRC="/root/.bashrc"
BASH_PROFILE="/root/.bash_profile"
SWAP_FILE="/swapfile"
SWAP_SIZE_MB=1024
SWAP_MIN_FREE_MB=2048

step() { echo -e "${YELLOW}  [$1] $2${RESET}"; }
ok()   { echo -e "        ${GREEN}\u2713 $1${RESET}"; }
err()  { echo -e "        ${RED}\u2717 $1${RESET}"; }

echo -e "${CYAN}${LINE}${RESET}"
echo -e "${GREEN}  ANTIVIR STANDALONE INSTALLER v2026.06.10${RESET}"
echo -e "${CYAN}${LINE}${RESET}"

# --- STEP 1: Install ClamAV --------------------------------------------------
step "1/6" "Installing ClamAV..."
export DEBIAN_FRONTEND=noninteractive
if ! command -v clamscan >/dev/null 2>&1; then
    apt-get update -yqq
    apt-get install -yqq clamav clamav-freshclam
    ok "ClamAV installed"
else
    ok "Already installed: $(clamscan --version | head -1)"
fi

# --- STEP 2: Swap ------------------------------------------------------------
step "2/6" "Checking swap..."
if swapon --show 2>/dev/null | grep -q .; then
    ok "Swap active: $(free -h | awk '/Swap/{print $2}')"
elif [ -f "$SWAP_FILE" ]; then
    swapon "$SWAP_FILE" 2>/dev/null && ok "Swapfile activated" || err "swapon failed"
else
    FREE_MB=$(df / --output=avail -m 2>/dev/null | tail -1 | tr -d ' ')
    if [ "${FREE_MB:-0}" -ge $(( SWAP_SIZE_MB + SWAP_MIN_FREE_MB )) ]; then
        CREATE_MB=$SWAP_SIZE_MB
    elif [ "${FREE_MB:-0}" -ge 512 ]; then
        CREATE_MB=$(( FREE_MB - SWAP_MIN_FREE_MB ))
        [ "$CREATE_MB" -lt 256 ] && CREATE_MB=256
    else
        CREATE_MB=0
    fi
    if [ "$CREATE_MB" -gt 0 ]; then
        echo -e "        Free disk: ${FREE_MB}MB \u2014 creating ${CREATE_MB}MB swap..."
        fallocate -l ${CREATE_MB}M "$SWAP_FILE" 2>/dev/null || \
            dd if=/dev/zero of="$SWAP_FILE" bs=1M count="$CREATE_MB" status=none
        chmod 600 "$SWAP_FILE"
        mkswap "$SWAP_FILE" >/dev/null
        swapon "$SWAP_FILE"
        grep -q "$SWAP_FILE" /etc/fstab 2>/dev/null || \
            echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
        ok "Swap ${CREATE_MB}MB created and persistent"
    else
        err "Disk too full (${FREE_MB}MB) \u2014 swap skipped. freshclam may fail on low-RAM servers!"
    fi
fi

# --- STEP 3: freshclam DB ----------------------------------------------------
step "3/6" "Updating virus definitions..."
systemctl stop clamav-freshclam 2>/dev/null || true
# Fix config
FC="/etc/clamav/freshclam.conf"
[ -f "$FC" ] && sed -i '/^Example$/d; s/^Checks.*/Checks 12/' "$FC"
grep -q '^Checks' "$FC" 2>/dev/null || echo 'Checks 12' >> "$FC"
# Remove broken DB
DB_DAILY="/var/lib/clamav/daily.cvd"
DB_AGE=99999
[ -f "$DB_DAILY" ] && DB_AGE=$(( $(date +%s) - $(stat -c %Y "$DB_DAILY" 2>/dev/null || echo 0) ))
if [ "$DB_AGE" -gt 86400 ]; then
    rm -f /var/lib/clamav/*.cvd /var/lib/clamav/*.cld 2>/dev/null
    echo -e "        Downloading (~110MB, ~1 min)..."
    nice -n 19 ionice -c3 freshclam --stdout 2>&1 | \
        grep -E '(updated|failed|ERROR|version:|Testing|killed)' || true
fi
if [ -f "$DB_DAILY" ]; then
    ok "DB ready: $(ls -lh $DB_DAILY | awk '{print $5}') daily.cvd"
else
    err "DB still missing \u2014 run 'freshclam --stdout' manually"
fi
systemctl enable clamav-freshclam 2>/dev/null || true
systemctl start  clamav-freshclam 2>/dev/null || true

# --- STEP 4: Deploy /usr/local/bin/antivir -----------------------------------
step "4/6" "Deploying /usr/local/bin/antivir..."
cat > "$ANTIVIR_BIN" << 'ANTIVIR_SCRIPT'
#!/bin/bash
# = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =
# antivir — ClamAV scan with Telegram report
# Usage: antivir         → full scan (background, nohup)
#        antivir status  → check if scan is running
#        antivir log     → tail last scan log

HOST="$(hostname)"
DATE_NOW="$(date '+%Y-%m-%d %H:%M:%S')"
LOG_DIR="/var/log/clamav"
LOG_FILE="$LOG_DIR/manual_scan.log"
PID_FILE="/var/run/antivir_scan.pid"
SCAN_PATHS="/etc /root /home /var/www"
EXCLUDE_DIRS="^/sys|^/proc|^/dev|^/run|^/snap|^/tmp|^/mnt|^/media|^/var/lib/docker|^/var/lib/containerd"

mkdir -p "$LOG_DIR"

case "${1:-}" in
    status)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat $PID_FILE)" 2>/dev/null; then
            echo "RUNNING: PID=$(cat $PID_FILE)"
        else
            echo "NOT running"
        fi
        exit 0
        ;;
    log)
        tail -50 "$LOG_FILE"
        exit 0
        ;;
esac

if [ -f "$PID_FILE" ] && kill -0 "$(cat $PID_FILE)" 2>/dev/null; then
    echo "Scan already running (PID=$(cat $PID_FILE)). Use: antivir log"
    exit 1
fi

nohup bash -c '
    LOG_DIR="'"$LOG_DIR"'"
    LOG_FILE="'"$LOG_FILE"'"
    PID_FILE="'"$PID_FILE"'"
    HOST="'"$HOST"'"
    DATE_NOW="'"$DATE_NOW"'"
    SCAN_PATHS="'"$SCAN_PATHS"'"
    EXCLUDE_DIRS="'"$EXCLUDE_DIRS"'"

    echo $$ > "$PID_FILE"

    {
    echo "========================================"
    echo "ClamAV scan on $HOST at $DATE_NOW"
    echo "========================================"

    if ! command -v clamscan >/dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y && apt-get install -y clamav clamav-freshclam
    fi

    # Update DB if older than 24h
    DB="/var/lib/clamav/daily.cvd"
    DB_AGE=99999
    [ -f "$DB" ] && DB_AGE=$(( $(date +%s) - $(stat -c %Y "$DB" 2>/dev/null || echo 0) ))
    if [ "$DB_AGE" -gt 86400 ]; then
        echo "--- Updating virus databases..."
        systemctl stop clamav-freshclam 2>/dev/null || true
        freshclam 2>&1 | grep -E "(updated|failed|ERROR|version:)" || true
        systemctl start clamav-freshclam 2>/dev/null || true
    fi

    TMP_RESULT="$(mktemp)"
    echo "--- Starting scan: $SCAN_PATHS ..."
    clamscan -r -i \
        --max-filesize=200M \
        --max-scansize=500M \
        --exclude-dir="$EXCLUDE_DIRS" \
        $SCAN_PATHS > "$TMP_RESULT" 2>&1 || true

    cat "$TMP_RESULT"

    INFECTED="$(awk -F": " "/Infected files:/ {print \$2}" "$TMP_RESULT" | tail -1 | tr -d " \t\r\n")"
    ERRORS="$(awk   -F": " "/Total errors:/   {print \$2}" "$TMP_RESULT" | tail -1 | tr -d " \t\r\n")"
    INFECTED="${INFECTED:-0}"
    ERRORS="${ERRORS:-0}"

    TG_SCRIPT="/root/Linux_Server_Public/scripts/telegram_alert.sh"
    if [ "${INFECTED}" != "0" ] && [ -n "${INFECTED//[0-9]/}" = "" ] 2>/dev/null; then
        [ "$INFECTED" -gt 0 ] 2>/dev/null && STATUS="ALERT" || STATUS="OK"
    else
        STATUS="OK"
    fi

    if [ "$STATUS" = "ALERT" ]; then
        MSG="\U0001F6A8 ClamAV ALERT on $HOST
Infected: $INFECTED | Errors: $ERRORS
Time: $(date +"%Y-%m-%d %H:%M:%S")"
        [ -x "$TG_SCRIPT" ] && "$TG_SCRIPT" "$MSG" >/dev/null 2>&1 || true
        echo "ALERT: infected=$INFECTED"
    else
        MSG="\u2705 ClamAV OK on $HOST
Infected: 0 | Errors: $ERRORS
Time: $(date +"%Y-%m-%d %H:%M:%S")"
        [ -x "$TG_SCRIPT" ] && "$TG_SCRIPT" "$MSG" >/dev/null 2>&1 || true
        echo "OK: no infected files"
    fi

    rm -f "$TMP_RESULT" "$PID_FILE"
    } >> "$LOG_FILE" 2>&1
' > /dev/null 2>&1 &

echo "ClamAV scan started in background (PID=$!)"
echo "  antivir log     \u2192 see progress"
echo "  antivir status  \u2192 check if running"
echo "Telegram message will be sent when done."
exit 0
ANTIVIR_SCRIPT

chmod +x "$ANTIVIR_BIN"
ok "Installed: $ANTIVIR_BIN"

# --- STEP 5: Cron ------------------------------------------------------------
step "5/6" "Setting up cron (daily at 03:00)..."
{ crontab -l 2>/dev/null | grep -v antivir | grep -v 'clamav-daily'; \
  echo '# antivir-clamav-daily'; \
  echo '0 3 * * * /usr/local/bin/antivir >/dev/null 2>&1'; \
} | crontab -
ok "Cron: 0 3 * * * antivir"

# --- STEP 6: Aliases ---------------------------------------------------------
step "6/6" "Writing aliases..."
MARKER="# === antivir aliases ==="
for FILE in "$BASHRC" "$BASH_PROFILE"; do
    touch "$FILE"
    sed -i '/# === antivir aliases ===/,/^$/d' "$FILE" 2>/dev/null
    sed -i '/alias antivir/d' "$FILE" 2>/dev/null
    printf '\n%s\n%s\n%s\n%s\n' \
        "$MARKER" \
        "alias antivir='/usr/local/bin/antivir'" \
        "alias antivir-log='tail -50 /var/log/clamav/manual_scan.log'" \
        "alias antivir-status='/usr/local/bin/antivir status'" >> "$FILE"
done
source "$BASHRC" 2>/dev/null || true
ok "Aliases ready (.bashrc + .bash_profile)"

# --- Summary -----------------------------------------------------------------
echo -e ""
echo -e "${CYAN}${LINE}${RESET}"
echo -e "${GREEN}  DONE! antivir installed.${RESET}"
echo -e ""
echo -e "  ${YELLOW}Commands:${RESET}"
echo -e "    ${GREEN}antivir${RESET}         \u2014 start scan (background)"
echo -e "    ${GREEN}antivir status${RESET}  \u2014 is scan running?"
echo -e "    ${GREEN}antivir log${RESET}     \u2014 tail scan log"
echo -e "    ${GREEN}antivir-log${RESET}     \u2014 same via alias"
echo -e ""
echo -e "  ${YELLOW}Scan paths:${RESET} /etc /root /home /var/www"
echo -e "  ${YELLOW}Cron:${RESET}       daily 03:00"
echo -e "  ${YELLOW}Swap:${RESET}       $(free -h | awk '/Swap/{print $2}') active"
echo -e "  ${YELLOW}Virus DB:${RESET}   $(ls -lh /var/lib/clamav/daily.cvd 2>/dev/null | awk '{print $5" \u2014 "$8" "$7" "$6}' || echo 'not found')"
echo -e ""
echo -e "  Run: ${CYAN}source ~/.bashrc${RESET}  \u2014 activate aliases in current session"
echo -e "${CYAN}${LINE}${RESET}"
# = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =
