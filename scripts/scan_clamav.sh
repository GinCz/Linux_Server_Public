#!/usr/bin/env bash
# Script:  scan_clamav.sh
# Version: v2026-03-19b
# Alias:   antivir         -> start scan
# Alias:   antivir-stop    -> kill all running scans
# Alias:   antivir-status  -> check if scan is running
# Purpose: Install (if missing), update and run ClamAV deep scan in background.
#          Sends Telegram notification on completion.
#          Safe: read-only, never deletes or modifies files.
# Author:  Ing. VladiMIR Bulantsev

clear

C='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; X='\033[0m'
HOST=$(hostname)
DATE=$(date +%Y-%m-%d_%H-%M)
LOG="/var/log/clamav_scan_${HOST}_${DATE}.log"
PIDFILE="/var/run/clamav_scan.pid"

# ── Load Telegram credentials ────────────────────────────────────────────────
# Looks for /etc/server_alerts.conf (root) or ~/.server_alerts.conf (ubuntu/aws)
for CONF in /etc/server_alerts.conf ~/.server_alerts.conf; do
    [ -f "$CONF" ] && source "$CONF" && break
done

# ── Telegram send function ───────────────────────────────────────────────────
tg_send() {
    [ -z "${TG_TOKEN:-}" ] && return
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d chat_id="${TG_CHAT}" \
        -d parse_mode="HTML" \
        -d text="$1" > /dev/null
}

# ── STOP mode: antivir-stop ──────────────────────────────────────────────────
# Kills all running clamscan processes and removes PID file
if [ "${1:-}" = "--stop" ]; then
    echo -e "${R}🛑 Stopping all ClamAV scan processes...${X}"
    KILLED=0

    # Kill by PID file if exists
    if [ -f "$PIDFILE" ]; then
        OLD_PID=$(cat "$PIDFILE")
        if kill -0 "$OLD_PID" 2>/dev/null; then
            kill -TERM "$OLD_PID" 2>/dev/null
            echo -e "${R}   Killed PID: ${OLD_PID}${X}"
            KILLED=$((KILLED + 1))
        fi
        rm -f "$PIDFILE"
    fi

    # Kill all clamscan processes (catches double-starts)
    while IFS= read -r PID; do
        kill -TERM "$PID" 2>/dev/null
        echo -e "${R}   Killed clamscan PID: ${PID}${X}"
        KILLED=$((KILLED + 1))
    done < <(pgrep clamscan 2>/dev/null)

    if [ "$KILLED" -eq 0 ]; then
        echo -e "${C}   No active ClamAV scan found.${X}"
    else
        echo -e "${R}✅ Stopped ${KILLED} process(es).${X}"
        tg_send "🛑 <b>ClamAV scan STOPPED</b>\n🖥 Server: <b>${HOST}</b>\n⚡ Killed: <b>${KILLED} process(es)</b>"
    fi
    exit 0
fi

# ── STATUS mode: antivir-status ──────────────────────────────────────────────
if [ "${1:-}" = "--status" ]; then
    PIDS=$(pgrep clamscan 2>/dev/null | tr '\n' ' ')
    if [ -n "$PIDS" ]; then
        echo -e "${Y}⏳ ClamAV scan is RUNNING (PID: ${PIDS})${X}"
        echo -e "   Last log: $(ls -t /var/log/clamav_scan_*.log 2>/dev/null | head -1)"
    else
        echo -e "${C}✅ No ClamAV scan running.${X}"
    fi
    exit 0
fi

# ── Check if scan already running ────────────────────────────────────────────
if pgrep clamscan > /dev/null 2>&1; then
    RUNNING_PIDS=$(pgrep clamscan | tr '\n' ' ')
    echo -e "${R}⚠️  ClamAV scan is ALREADY RUNNING (PID: ${RUNNING_PIDS})${X}"
    echo -e "${Y}   To stop:   antivir-stop${X}"
    echo -e "${Y}   To status: antivir-status${X}"
    echo -e "${Y}   To force new scan anyway: bash scan_clamav.sh --force${X}"
    [ "${1:-}" != "--force" ] && exit 1
fi

echo -e "${Y}========================================${X}"
echo -e "${Y} ClamAV Antivirus | ${HOST} | ${DATE}${X}"
echo -e "${Y}========================================${X}"

# ── Step 1: Auto-install ClamAV if missing ───────────────────────────────────
if ! command -v clamscan &>/dev/null; then
    echo -e "${Y}1. ClamAV not found — installing...${X}"
    apt-get update -qq && apt-get install -y clamav clamav-daemon -qq
    echo -e "${C}   Done!${X}"
else
    echo -e "${C}1. ClamAV is already installed.${X}"
fi

# ── Step 2: Update virus databases ───────────────────────────────────────────
echo -e "${Y}2. Updating virus databases...${X}"
systemctl stop clamav-freshclam 2>/dev/null
freshclam --quiet 2>/dev/null
systemctl start clamav-freshclam 2>/dev/null
echo -e "${C}   Done!${X}"

# ── Step 3: Count files to be scanned ────────────────────────────────────────
echo -n "3. Counting files in /var/www ... "
TOTAL=$(find /var/www -type f 2>/dev/null | wc -l)
echo -e "${C}Found ${TOTAL} files.${X}"

# ── Step 4: Notify Telegram — scan starting ───────────────────────────────────
tg_send "🔍 <b>ClamAV scan started</b>
🖥 Server: <b>${HOST}</b>
📁 Files: <b>${TOTAL}</b>
⏰ Started: $(date '+%Y-%m-%d %H:%M')

<i>You can close SSH — report will be sent on completion.</i>"

# ── Step 5: Launch background scan with nohup ─────────────────────────────────
# nice -n 19    → lowest CPU priority (does not affect websites)
# ionice -c 3   → idle I/O class (yields to all other disk activity)
# --infected    → log only infected files (clean output)
echo -e "${Y}4. Starting deep scan in background...${X}"
echo -e "${C}   You can close SSH now — Telegram will notify you when done.${X}"
echo -e "   Log: ${LOG}"
echo ""

nohup bash -c "
    echo \$\$ > '${PIDFILE}'
    START=\$(date +%s)
    echo '=== ClamAV Scan | ${HOST} | $(date) ===' > '${LOG}'

    nice -n 19 ionice -c 3 clamscan -r /var/www \\
        --log='${LOG}' \\
        --infected \\
        --exclude-dir='^/var/www/.*/data/tmp' \\
        --exclude-dir='^/var/www/.*/data/cache' \\
        2>/dev/null

    rm -f '${PIDFILE}'
    END=\$(date +%s)
    ELAPSED=\$(( (END - START) / 60 ))

    # Count infected files in log
    INFECTED=\$(grep -c 'FOUND' '${LOG}' 2>/dev/null || echo 0)

    if [ \"\$INFECTED\" = '0' ]; then
        ICON='✅'
        STATUS='Clean — no threats found'
    else
        ICON='🚨'
        STATUS=\"INFECTED: \$INFECTED file(s) — check log!\"
    fi

    # Send completion report to Telegram
    curl -s -X POST 'https://api.telegram.org/bot${TG_TOKEN}/sendMessage' \\
        -d chat_id='${TG_CHAT}' \\
        -d parse_mode='HTML' \\
        -d text=\"\${ICON} <b>ClamAV scan DONE</b>
🖥 Server: <b>${HOST}</b>
📁 Scanned: <b>${TOTAL} files</b>
🦠 Result: <b>\${STATUS}</b>
⏱ Time: <b>\${ELAPSED} min</b>
📄 Log: ${LOG}\" > /dev/null
" >> "${LOG}" 2>&1 &

SCAN_PID=$!
echo "$SCAN_PID" > "$PIDFILE"
echo -e "${C}✅ Scan running in background (PID: ${SCAN_PID})${X}"
echo -e "${C}📱 Telegram notification: @My_WWW_bot${X}"
echo -e "${Y}   To stop:   antivir-stop${X}"
echo -e "   Monitor:   tail -f ${LOG}"
