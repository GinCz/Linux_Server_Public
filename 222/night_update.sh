#!/bin/bash
# /root/night_update.sh — nightly update + cleanup + kernel check + post-boot audit
# NO automatic reboot — Telegram alert if kernel requires reboot (silent)
# NOTE: Set TG_TOKEN in /root/.server_env
# = Rooted by VladiMIR + AI | v.2026.08.01 | github.com/GinCz =

source /root/.server_env 2>/dev/null || true
T="${TG_TOKEN:-}"
C="${TG_CHAT_ID:-261784949}"
S="$(hostname)"
LOG="/var/log/night_update.log"

tg() {
    [ -z "$T" ] && return
    curl -s -X POST "https://api.telegram.org/bot${T}/sendMessage" \
        -d "chat_id=${C}" \
        -d "parse_mode=HTML" \
        -d "disable_notification=true" \
        -d "text=$1" >/dev/null 2>&1 || true
}

if [ "$1" = "--audit" ]; then
    sleep 30
    echo "$(date '+%Y-%m-%d %H:%M:%S') POST-REBOOT AUDIT on ${S}" >> "$LOG"
    ERRORS=""

    FAILED=$(systemctl list-units --state=failed --no-legend 2>/dev/null | awk '{print $1}' | head -5 | tr '\n' ' ')
    [ -n "$FAILED" ] && ERRORS="${ERRORS}❌ Failed services: ${FAILED}\n"

    RAM_PCT=$(free | awk '/^Mem:/{printf "%.0f", ($3/$2)*100}')
    if [ "$RAM_PCT" -gt 90 ]; then
        RAM_INFO=$(free -m | awk '/^Mem:/{printf "%dMB/%dMB", $3,$2}')
        ERRORS="${ERRORS}⚠️ RAM critical: ${RAM_INFO} (${RAM_PCT}%)\n"
    fi

    DISK_PCT=$(df / | awk 'NR==2{gsub(/%/,"",$5); print $5}')
    if [ "$DISK_PCT" -gt 85 ]; then
        DISK_INFO=$(df -h / | awk 'NR==2{printf "%s used (%s)", $3,$5}')
        ERRORS="${ERRORS}⚠️ Disk critical: ${DISK_INFO}\n"
    fi

    if [ -n "$ERRORS" ]; then
        UPTIME=$(uptime -p)
        RAM=$(free -m | awk '/^Mem:/{printf "%dMB/%dMB (%d%%)", $3,$2,($3/$2)*100}')
        DISK=$(df -h / | awk 'NR==2{printf "%s used (%s)", $3,$5}')
        LOAD=$(awk '{print $1,$2,$3}' /proc/loadavg)
        tg "🚨 <b>${S}</b> — problems after reboot!
⏱ ${UPTIME}
🧠 RAM: ${RAM}
💾 Disk: ${DISK}
⚡ Load: ${LOAD}

${ERRORS}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') AUDIT ALERT SENT" >> "$LOG"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') AUDIT OK — no issues" >> "$LOG"
    fi
    exit 0
fi

exec >> "$LOG" 2>&1
echo "========================================"
echo "$(date '+%Y-%m-%d %H:%M:%S') NIGHT UPDATE START — ${S}"

if ! apt-get update -qq; then
    tg "❌ <b>${S}</b>: apt update FAILED"
    exit 1
fi

DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    tg "❌ <b>${S}</b>: apt upgrade ERROR (exit ${EXIT_CODE})"
    exit 1
fi

DEBIAN_FRONTEND=noninteractive apt-get autoremove -y -qq \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" || true
apt-get autoclean -qq || true
journalctl --vacuum-size=100M --quiet || true
journalctl --vacuum-time=14d --quiet  || true

for F in /var/log/btmp /var/log/wtmp; do
    SZ=$(stat -c%s "$F" 2>/dev/null || echo 0)
    if [ "$SZ" -gt 52428800 ]; then
        : > "$F"
        echo "$(date '+%Y-%m-%d %H:%M:%S') $(basename $F) cleared ($(( SZ / 1048576 ))MB)"
    fi
done

LOG_SIZE=$(stat -c%s "$LOG" 2>/dev/null || echo 0)
if [ "$LOG_SIZE" -gt 10485760 ]; then
    tail -500 "$LOG" > "${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"
    echo "$(date '+%Y-%m-%d %H:%M:%S') log truncated to last 500 lines"
fi

DISK_FREE=$(df -h / | awk 'NR==2{printf "%s used / %s total (%s free)", $3, $2, $4}')
echo "$(date '+%Y-%m-%d %H:%M:%S') UPDATE + CLEANUP OK — Disk: ${DISK_FREE}"

REBOOT_REQUIRED=0
PKGS=""
if [ -f /var/run/reboot-required ]; then
    REBOOT_REQUIRED=1
    PKGS=$(cat /var/run/reboot-required.pkgs 2>/dev/null | tr '\n' ' ')
fi

if [ "$REBOOT_REQUIRED" -eq 1 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') ⚠️ Kernel update — reboot required!"
    tg "🔄 <b>${S}</b> — kernel update installed
⚠️ Reboot required (manual)
📦 Packages: ${PKGS}
📅 $(date '+%Y-%m-%d %H:%M')"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') No reboot needed"
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') NIGHT UPDATE FINISH"
echo "========================================"
