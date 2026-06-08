#!/bin/bash
# = Rooted by VladiMIR + AI | v.2026.06.08 | github.com/GinCz =
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

send_tg() {
    local msg="$1"
    if [ -x /root/Linux_Server_Public/scripts/telegram_alert.sh ]; then
        /root/Linux_Server_Public/scripts/telegram_alert.sh "$msg" >/dev/null 2>&1 || true
    fi
}

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

# Run the actual scan in background
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
        echo "ClamAV not installed. Installing..."
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get install -y clamav clamav-freshclam
    fi

    echo "--- Updating virus databases (freshclam)..."
    systemctl stop clamav-freshclam 2>/dev/null || true
    freshclam 2>&1 || true
    systemctl start clamav-freshclam 2>/dev/null || true

    TMP_RESULT="$(mktemp)"

    echo "--- Starting scan: $SCAN_PATHS ..."
    clamscan -r -i \
        --max-filesize=200M \
        --max-scansize=500M \
        --exclude-dir="$EXCLUDE_DIRS" \
        $SCAN_PATHS > "$TMP_RESULT" 2>&1 || true

    cat "$TMP_RESULT"

    INFECTED="$(awk -F": " "/Infected files:/ {print \$2}" "$TMP_RESULT" | tail -1)"
    ERRORS="$(awk -F": " "/Total errors:/ {print \$2}" "$TMP_RESULT" | tail -1)"
    INFECTED="${INFECTED:-0}"
    ERRORS="${ERRORS:-0}"

    grep -E -- "Scanned files:|Infected files:|Total errors:|Data scanned:|Time:" "$TMP_RESULT" || true

    if [ "$INFECTED" -gt 0 ] 2>/dev/null; then
        MSG="🚨 ClamAV ALERT on $HOST
Infected files: $INFECTED
Errors: $ERRORS
Time: $(date +"%Y-%m-%d %H:%M:%S")"
        [ -x /root/Linux_Server_Public/scripts/telegram_alert.sh ] && \
            /root/Linux_Server_Public/scripts/telegram_alert.sh "$MSG" >/dev/null 2>&1 || true
        echo "ALERT: infected=$INFECTED"
    else
        MSG="✅ ClamAV scan OK on $HOST
Infected files: 0 | Errors: $ERRORS
Time: $(date +"%Y-%m-%d %H:%M:%S")"
        [ -x /root/Linux_Server_Public/scripts/telegram_alert.sh ] && \
            /root/Linux_Server_Public/scripts/telegram_alert.sh "$MSG" >/dev/null 2>&1 || true
        echo "OK: no infected files found"
    fi

    rm -f "$TMP_RESULT" "$PID_FILE"
    } >> "$LOG_FILE" 2>&1
' > /dev/null 2>&1 &

echo "ClamAV scan started in background (PID=$!)"
echo "  antivir log     → see progress"
echo "  antivir status  → check if running"
echo "Telegram message will be sent when done."
exit 0
