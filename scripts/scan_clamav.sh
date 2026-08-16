#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  scan_clamav.sh | [v2026-08-17]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : ClamAV Malware Scanner with Interactive Menu, Status & Logs
# Servers     : All Linux Nodes (222-DE, 109-RU, VPN nodes)
# Usage       : bash scripts/scan_clamav.sh [status|log|install|run]
# ==========================================================================================

HOST="$(hostname)"
DATE_NOW="$(date '+%Y-%m-%d %H:%M:%S')"
LOG_DIR="/var/log/clamav"
LOG_FILE="$LOG_DIR/manual_scan.log"
PID_FILE="/var/run/antivir_scan.pid"
SCAN_PATHS="/etc /root /home /var/www"
EXCLUDE_DIRS="^/sys|^/proc|^/dev|^/run|^/snap|^/tmp|^/mnt|^/media|^/var/lib/docker|^/var/lib/containerd"

mkdir -p "$LOG_DIR"

C='\033[1;36m'; G='\033[0;92m'; Y='\033[0;93m'; R='\033[1;31m'; W='\033[1;37m'; X='\033[0m'
HR="${C}==========================================================================================${X}"

show_log() {
    echo -e "$HR"
    echo -e "${Y}  📋 ClamAV Scan Log (Last 40 lines):${X}"
    echo -e "$HR"
    if [ -f "$LOG_FILE" ]; then
        tail -n 40 "$LOG_FILE"
    else
        echo -e "${Y}Log file $LOG_FILE not found.${X}"
    fi
    exit 0
}

show_status() {
    echo -e "$HR"
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        PID=$(cat "$PID_FILE")
        echo -e "${G}✔ Scan is currently RUNNING (PID=${PID})${X}"
        echo -e "Use: ${C}antivir log${X} to view real-time log"
    else
        echo -e "${Y}○ Scan is NOT running.${X}"
        if [ -f "$LOG_FILE" ]; then
            LAST_LINE=$(grep "ClamAV scan on" "$LOG_FILE" 2>/dev/null | tail -1)
            [ -n "$LAST_LINE" ] && echo -e "${W}Last scan: ${LAST_LINE}${X}"
        fi
    fi
    echo -e "$HR"
    exit 0
}

install_clamav() {
    echo -e "$HR"
    echo -e "${Y}  📦 Installing / Updating ClamAV packages...${X}"
    echo -e "$HR"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y clamav clamav-freshclam
    
    echo -e "${Y}--- Updating virus database (freshclam)...${X}"
    systemctl stop clamav-freshclam 2>/dev/null || true
    freshclam --quiet 2>&1 || true
    systemctl start clamav-freshclam 2>/dev/null || true
    
    if ! grep -q "alias antivir=" /root/.bashrc 2>/dev/null; then
        echo "alias antivir='/usr/local/bin/scan_clamav.sh'" >> /root/.bashrc
    fi
    
    echo -e "${G}✔ ClamAV successfully installed and ready to use!${X}"
    echo -e "$HR"
}

start_scan() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo -e "${Y}⚠ Scan already running (PID=$(cat "$PID_FILE")). Use: antivir log${X}"
        exit 1
    fi

    rm -f "$PID_FILE" 2>/dev/null

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
            apt-get update -qq
            apt-get install -y clamav clamav-freshclam
        fi

        echo "--- Updating virus databases (freshclam)..."
        systemctl stop clamav-freshclam 2>/dev/null || true
        freshclam --quiet 2>&1 || true
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

    echo -e "$HR"
    echo -e "${G}✔ ClamAV scan started in background (PID=$!)${X}"
    echo -e "  ${C}antivir log${X}     → see progress"
    echo -e "  ${C}antivir status${X}  → check if running"
    echo -e "Telegram message will be sent when done."
    echo -e "$HR"
}

# CLI arguments
case "${1:-}" in
    status) show_status ;;
    log) show_log ;;
    install) install_clamav; exit 0 ;;
    run|scan) start_scan; exit 0 ;;
esac

# Interactive Menu
if [ -t 0 ] && [ -t 1 ]; then
    CURRENT_STATUS="${Y}○ NOT running${X}"
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        CURRENT_STATUS="${G}● RUNNING (PID=$(cat "$PID_FILE"))${X}"
    fi

    echo -e "$HR"
    echo -e "${Y}  🛡️  ClamAV Antivirus — ${W}${HOST}${X} [Status: ${CURRENT_STATUS}]"
    echo -e "$HR"
    echo -e "    ${C}1)${X} Install / Update ClamAV & Freshclam"
    echo -e "    ${C}2)${X} Run scan now in background (One-off)"
    echo -e "    ${C}3)${X} View scan process & logs (antivir log)"
    echo -e "    ${C}4)${X} Check status (antivir status)"
    echo -e "$HR"
    read -rp "Enter choice [3]: " CHOICE
    CHOICE=${CHOICE:-3}

    case "$CHOICE" in
        1) install_clamav ;;
        2) start_scan ;;
        3) show_log ;;
        4) show_status ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac
else
    start_scan
fi
