#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  scan_clamav.sh | [v2026-09-07]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : ClamAV Malware Scanner with Low-Priority background execution & TG alerts
# Servers     : All Linux Nodes (222-DE, 109-RU, VPN nodes)
# Usage       : bash scan_clamav.sh [status|log|install|run|scan|report] [--defer]
# ==========================================================================================

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

HOST="$(hostname)"
DATE_NOW="$(date '+%Y-%m-%d %H:%M:%S')"
LOG_DIR="/var/log/clamav"
LOG_FILE="$LOG_DIR/manual_scan.log"
REPORT_FILE="$LOG_DIR/last_scan_report.txt"
PID_FILE="/var/run/antivir_scan.pid"
SCAN_PATHS="/etc /root /home /var/www"
EXCLUDE_DIRS="^/sys|^/proc|^/dev|^/run|^/snap|^/tmp|^/mnt|^/media|^/var/lib/docker|^/var/lib/containerd"

mkdir -p "$LOG_DIR"

C='\033[1;36m'; G='\033[0;92m'; Y='\033[0;93m'; R='\033[1;31m'; W='\033[1;37m'; X='\033[0m'
HR="${C}==========================================================================================${X}"

# Telegram integration
TG_CONFIG="/root/.tg_config"
[ -f "$TG_CONFIG" ] && source "$TG_CONFIG"
TG_TOKEN="${TG_TOKEN:-1226649515:AAEVdcIptwV2n6z2hkMVB3i9sDnnt1laKN0}"
TG_CHAT="${TG_CHAT:-261784949}"

tg() {
    local text="$1"
    [[ -n "$TG_TOKEN" && -n "$TG_CHAT" ]] || return 0
    if ! curl -fsS -m 5 -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
      -d chat_id="$TG_CHAT" \
      -d parse_mode="HTML" \
      --data-urlencode text="$text" >/dev/null 2>&1; then
        curl -fsS -m 10 -X POST "http://152.53.182.222:8899/bot${TG_TOKEN}/sendMessage" \
          -d chat_id="$TG_CHAT" \
          -d parse_mode="HTML" \
          --data-urlencode text="$text" >/dev/null 2>&1 || true
    fi
}

send_report() {
    echo -e "$HR"
    if [ -f "$REPORT_FILE" ]; then
        MSG="$(cat "$REPORT_FILE")"
        if [ -n "$MSG" ]; then
            tg "$MSG"
            echo -e "${G}✔ ClamAV report successfully sent to Telegram:${X}"
            echo "$MSG"
            mv -f "$REPORT_FILE" "${REPORT_FILE}.sent" 2>/dev/null || true
            echo -e "$HR"
            exit 0
        fi
    fi
    echo -e "${Y}○ No pending ClamAV scan report found at ${REPORT_FILE}${X}"
    echo -e "$HR"
    exit 0
}

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
        if [ -f "$REPORT_FILE" ]; then
            echo -e "${C}Pending Monday report available in ${REPORT_FILE}${X}"
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
    nice -n 19 freshclam --quiet 2>&1 || true
    systemctl start clamav-freshclam 2>/dev/null || true
    
    if ! grep -q "alias antivir=" /root/.bashrc 2>/dev/null; then
        echo "alias antivir='/usr/local/bin/scan_clamav.sh'" >> /root/.bashrc
    fi
    
    echo -e "${G}✔ ClamAV successfully installed and ready to use!${X}"
    echo -e "$HR"
}

start_scan() {
    local DEFER="${1:-0}"

    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo -e "${Y}⚠ Scan already running (PID=$(cat "$PID_FILE")). Use: antivir log${X}"
        exit 1
    fi

    rm -f "$PID_FILE" 2>/dev/null

    nohup bash -c '
        export LC_ALL=C.UTF-8
        export LANG=C.UTF-8

        LOG_DIR="'"$LOG_DIR"'"
        LOG_FILE="'"$LOG_FILE"'"
        REPORT_FILE="'"$REPORT_FILE"'"
        PID_FILE="'"$PID_FILE"'"
        HOST="'"$HOST"'"
        DATE_NOW="'"$DATE_NOW"'"
        SCAN_PATHS="'"$SCAN_PATHS"'"
        EXCLUDE_DIRS="'"$EXCLUDE_DIRS"'"
        TG_TOKEN="'"$TG_TOKEN"'"
        TG_CHAT="'"$TG_CHAT"'"
        DEFER="'"$DEFER"'"

        tg() {
            local text="$1"
            [[ -n "$TG_TOKEN" && -n "$TG_CHAT" ]] || return 0
            if ! curl -fsS -m 5 -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
              -d chat_id="$TG_CHAT" \
              -d parse_mode="HTML" \
              --data-urlencode text="$text" >/dev/null 2>&1; then
                curl -fsS -m 10 -X POST "http://152.53.182.222:8899/bot${TG_TOKEN}/sendMessage" \
                  -d chat_id="$TG_CHAT" \
                  -d parse_mode="HTML" \
                  --data-urlencode text="$text" >/dev/null 2>&1 || true
            fi
        }

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
        nice -n 19 freshclam --quiet 2>&1 || true
        systemctl start clamav-freshclam 2>/dev/null || true

        TMP_RESULT="$(mktemp)"

        echo "--- Starting low-priority scan: $SCAN_PATHS ..."
        
        # Run with lowest CPU and I/O priority
        if command -v ionice >/dev/null 2>&1; then
            IONICE_CMD="ionice -c 2 -n 7"
        else
            IONICE_CMD=""
        fi

        nice -n 19 $IONICE_CMD clamscan -r -i \
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

        IP=$(hostname -I 2>/dev/null | awk "{print \$1}")
        [ -z "$IP" ] && IP="unknown"

        if [ "$INFECTED" -gt 0 ] 2>/dev/null; then
            INFECTED_ITEMS=$(grep "FOUND" "$TMP_RESULT" | head -10)
            MSG="🚨 <b>ClamAV ALERT</b> — <b>${HOST}</b> (${IP})
<b>Infected files: ${INFECTED}</b> | Errors: ${ERRORS}
📅 $(date "+%Y-%m-%d %H:%M:%S")

<b>Found:</b>
<code>${INFECTED_ITEMS}</code>"
            echo "$MSG" > "$REPORT_FILE"
            # Always send emergency alert immediately on infection!
            tg "$MSG"
            echo "ALERT: infected=$INFECTED (Immediate TG alert sent)"
        else
            MSG="✅ <b>ClamAV scan OK</b> — <b>${HOST}</b> (${IP})
Infected files: 0 | Errors: ${ERRORS}
📅 $(date "+%Y-%m-%d %H:%M:%S")"
            echo "$MSG" > "$REPORT_FILE"
            if [ "$DEFER" = "1" ]; then
                echo "OK: scan complete, TG report deferred to Monday morning"
            else
                tg "$MSG"
                echo "OK: no infected files found (TG alert sent)"
            fi
        fi

        rm -f "$TMP_RESULT" "$PID_FILE"
        } >> "$LOG_FILE" 2>&1
    ' > /dev/null 2>&1 &

    echo -e "$HR"
    echo -e "${G}✔ ClamAV low-priority scan started in background (PID=$!)${X}"
    echo -e "  ${C}antivir log${X}     → see progress"
    echo -e "  ${C}antivir status${X}  → check if running"
    if [ "$DEFER" = "1" ]; then
        echo -e "  Report will be deferred until scheduled Monday trigger."
    else
        echo -e "  Telegram notification will be sent automatically when finished."
    fi
    echo -e "$HR"
}

# Parse CLI flags
DEFER_FLAG=0
ACTION=""

for arg in "$@"; do
    case "$arg" in
        --defer) DEFER_FLAG=1 ;;
        status|log|install|report|send-report|run|scan) ACTION="$arg" ;;
    esac
done

case "$ACTION" in
    status) show_status ;;
    log) show_log ;;
    install) install_clamav; exit 0 ;;
    report|send-report) send_report; exit 0 ;;
    run|scan) start_scan "$DEFER_FLAG"; exit 0 ;;
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
    echo -e "    ${C}2)${X} Run scan now in background (Low Priority)"
    echo -e "    ${C}3)${X} View scan process & logs (antivir log)"
    echo -e "    ${C}4)${X} Check status (antivir status)"
    echo -e "    ${C}5)${X} Send pending scan report to Telegram (antivir report)"
    echo -e "$HR"
    read -rp "Enter choice [2]: " CHOICE
    CHOICE=${CHOICE:-2}

    case "$CHOICE" in
        1) install_clamav ;;
        2) start_scan 0 ;;
        3) show_log ;;
        4) show_status ;;
        5) send_report ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac
else
    start_scan "$DEFER_FLAG"
fi
