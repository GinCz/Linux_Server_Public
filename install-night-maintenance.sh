#!/usr/bin/env bash
clear
# = Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz =
#
# install-night-maintenance.sh — Night maintenance script installer
# -------------------------------------------------------
# Usage:
#   bash install-night-maintenance.sh           → VPN mode: daily 02:00 + reboot
#   bash install-night-maintenance.sh --weekly  → WEB mode: Saturday 02:00 + reboot
#
# Steps: apt update → apt upgrade → cleanup → reboot
# After reboot (@reboot) — audit → Telegram ONLY on errors (silent, no sound)
# -------------------------------------------------------

MODE="${1:-daily}"
[ "$MODE" = "--weekly" ] && CRON_TIME="0 2 * * 6" || CRON_TIME="0 2 * * *"

T="1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ"
C="261784949"
LOG="/var/log/auto-upgrade.log"

tg() {
  curl -s -X POST "https://api.telegram.org/bot${T}/sendMessage" \
    -d "chat_id=${C}" \
    -d "parse_mode=HTML" \
    -d "disable_notification=true" \
    -d "text=$1" >/dev/null 2>&1 || true
}

# --- Disable conflicting system apt timers ---
echo "[1/5] Disabling apt-daily-upgrade.timer and apt-daily.timer..."
systemctl disable --now apt-daily-upgrade.timer 2>/dev/null || true
systemctl disable --now apt-daily.timer 2>/dev/null || true
echo "[OK] System apt timers disabled"

# --- Main night maintenance script ---
echo "[2/5] Writing /usr/local/bin/night-maintenance..."
cat > /usr/local/bin/night-maintenance << 'EOF'
#!/usr/bin/env bash
# = Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz =
#
# night-maintenance — nightly update + cleanup + reboot
# Steps: apt update → apt upgrade → autoremove → cleanup → reboot
# Telegram alerts are SILENT (disable_notification=true)

T="1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ"
C="261784949"
S="$(hostname)"
LOG="/var/log/auto-upgrade.log"

tg() {
  curl -s -X POST "https://api.telegram.org/bot${T}/sendMessage" \
    -d "chat_id=${C}" \
    -d "parse_mode=HTML" \
    -d "disable_notification=true" \
    -d "text=$1" >/dev/null 2>&1 || true
}

echo "==============================" >> "$LOG"
echo "$(date '+%Y-%m-%d %H:%M:%S') START" >> "$LOG"

# --- Step 1: apt update ---
if ! apt-get update -qq >> "$LOG" 2>&1; then
  tg "❌ <b>${S}</b>: apt update FAILED — check $LOG"
  exit 1
fi

# --- Step 2: apt upgrade (non-interactive, keep existing configs) ---
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  >> "$LOG" 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  tg "❌ <b>${S}</b>: apt upgrade ERROR (exit ${EXIT_CODE}) — check $LOG"
  exit 1
fi

PKG_COUNT=$(grep -c 'Setting up\|Unpacking' "$LOG" 2>/dev/null | tail -1 || echo 0)
echo "$(date '+%Y-%m-%d %H:%M:%S') UPDATE OK — packages: ${PKG_COUNT}" >> "$LOG"

# --- Step 3: cleanup ---
echo "$(date '+%Y-%m-%d %H:%M:%S') CLEANUP START" >> "$LOG"

DEBIAN_FRONTEND=noninteractive apt-get autoremove -y -qq \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  >> "$LOG" 2>&1 || true

apt-get autoclean -qq >> "$LOG" 2>&1 || true

journalctl --vacuum-size=100M >> "$LOG" 2>&1 || true
journalctl --vacuum-time=14d  >> "$LOG" 2>&1 || true

# Clear btmp if > 50MB
BTMP_SIZE=$(stat -c%s /var/log/btmp 2>/dev/null || echo 0)
if [ "$BTMP_SIZE" -gt 52428800 ]; then
  : > /var/log/btmp
  echo "$(date '+%Y-%m-%d %H:%M:%S') btmp cleared (was $(( BTMP_SIZE / 1048576 ))MB)" >> "$LOG"
fi

# Clear wtmp if > 50MB
WTMP_SIZE=$(stat -c%s /var/log/wtmp 2>/dev/null || echo 0)
if [ "$WTMP_SIZE" -gt 52428800 ]; then
  : > /var/log/wtmp
  echo "$(date '+%Y-%m-%d %H:%M:%S') wtmp cleared (was $(( WTMP_SIZE / 1048576 ))MB)" >> "$LOG"
fi

# Truncate this log if > 10MB
LOG_SIZE=$(stat -c%s "$LOG" 2>/dev/null || echo 0)
if [ "$LOG_SIZE" -gt 10485760 ]; then
  tail -500 "$LOG" > "${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"
  echo "$(date '+%Y-%m-%d %H:%M:%S') auto-upgrade.log truncated to last 500 lines" >> "$LOG"
fi

DISK_FREE=$(df -h / | awk 'NR==2{printf "%s used / %s total (%s free)", $3, $2, $4}')
echo "$(date '+%Y-%m-%d %H:%M:%S') CLEANUP OK — Disk: ${DISK_FREE}" >> "$LOG"

# --- Step 4: reboot ---
echo "$(date '+%Y-%m-%d %H:%M:%S') REBOOTING..." >> "$LOG"
sleep 3
/sbin/reboot
EOF

# --- Post-reboot audit script ---
echo "[3/5] Writing /usr/local/bin/night-audit..."
cat > /usr/local/bin/night-audit << 'EOF'
#!/usr/bin/env bash
# = Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz =
#
# night-audit — post-reboot health check
# Sends Telegram ONLY if something is wrong (silent, no sound)

T="1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ"
C="261784949"
S="$(hostname)"
LOG="/var/log/auto-upgrade.log"

tg() {
  curl -s -X POST "https://api.telegram.org/bot${T}/sendMessage" \
    -d "chat_id=${C}" \
    -d "parse_mode=HTML" \
    -d "disable_notification=true" \
    -d "text=$1" >/dev/null 2>&1 || true
}

sleep 30

echo "$(date '+%Y-%m-%d %H:%M:%S') POST-REBOOT AUDIT" >> "$LOG"

ERRORS=""

# Check failed services
FAILED=$(systemctl list-units --state=failed --no-legend 2>/dev/null | awk '{print $1}' | head -5 | tr '\n' ' ')
[ -n "$FAILED" ] && ERRORS="${ERRORS}❌ Failed services: ${FAILED}\n"

# Check RAM > 90%
RAM_PCT=$(free | awk '/^Mem:/{printf "%.0f", ($3/$2)*100}')
if [ "$RAM_PCT" -gt 90 ]; then
  RAM_INFO=$(free -m | awk '/^Mem:/{printf "%dMB/%dMB", $3,$2}')
  ERRORS="${ERRORS}⚠️ RAM critical: ${RAM_INFO} (${RAM_PCT}%)\n"
fi

# Check disk > 85%
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
  tg "🚨 <b>${S}</b> — problems after reboot!\n⏱ ${UPTIME}\n🧠 RAM: ${RAM}\n💾 Disk: ${DISK}\n⚡ Load: ${LOAD}\n\n${ERRORS}"
  echo "$(date '+%Y-%m-%d %H:%M:%S') ALERT SENT" >> "$LOG"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') OK — no issues, Telegram skipped" >> "$LOG"
fi
EOF

chmod +x /usr/local/bin/night-maintenance
chmod +x /usr/local/bin/night-audit

# --- Update crontab ---
echo "[4/5] Updating crontab (schedule: ${CRON_TIME})..."
(crontab -l 2>/dev/null \
  | grep -vE 'night-maintenance|night-audit|auto_upgrade|disk_cleanup'
  echo "${CRON_TIME} /usr/local/bin/night-maintenance >> /var/log/auto-upgrade.log 2>&1"
  echo "@reboot /usr/local/bin/night-audit >> /var/log/auto-upgrade.log 2>&1"
) | crontab -

echo "[5/5] Done!"
echo ""
echo "✅ Installed on $(hostname) | mode: ${MODE} | schedule: ${CRON_TIME}"
echo ""
crontab -l | grep -E 'night|reboot'
