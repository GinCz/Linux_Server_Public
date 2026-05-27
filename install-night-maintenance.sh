#!/usr/bin/env bash
# = Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz =
#
# install-night-maintenance.sh — Night maintenance script installer
# -------------------------------------------------------
# Schedule: 02:00 — apt update + upgrade → cleanup → reboot
# After reboot (@reboot) — audit → Telegram ONLY on errors
# On any error — Telegram alert
# -------------------------------------------------------

T="1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ"
C="261784949"
S="$(hostname)"
LOG="/var/log/auto-upgrade.log"

# --- Telegram helper ---
tg() {
  curl -s -X POST "https://api.telegram.org/bot${T}/sendMessage" \
    -d "chat_id=${C}" \
    -d "parse_mode=HTML" \
    -d "text=$1" >/dev/null 2>&1 || true
}

# --- Main night maintenance script ---
cat > /usr/local/bin/night-maintenance << 'EOF'
#!/usr/bin/env bash
# = Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz =
#
# night-maintenance — nightly update + cleanup + reboot
# Usage: called by cron at 02:00
# Steps: apt update → apt upgrade → cleanup → reboot
# On error: Telegram alert

T="1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ"
C="261784949"
S="$(hostname)"
LOG="/var/log/auto-upgrade.log"

tg() {
  curl -s -X POST "https://api.telegram.org/bot${T}/sendMessage" \
    -d "chat_id=${C}" \
    -d "parse_mode=HTML" \
    -d "text=$1" >/dev/null 2>&1 || true
}

echo "==============================" >> "$LOG"
echo "$(date '+%Y-%m-%d %H:%M:%S') START" >> "$LOG"

# --- Step 1: apt update ---
if ! apt-get update -qq >> "$LOG" 2>&1; then
  tg "❌ <b>${S}</b>: apt update FAILED — check $LOG"
  exit 1
fi

# --- Step 2: apt upgrade ---
UPGRADED=$(apt-get upgrade -y -qq 2>&1 | tee -a "$LOG")
PKG_COUNT=$(echo "$UPGRADED" | grep -c 'upgraded\|installed' || true)

if echo "$UPGRADED" | grep -qi 'error\|failed'; then
  tg "❌ <b>${S}</b>: apt upgrade ERROR — check $LOG"
  exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') UPDATE OK — packages: ${PKG_COUNT}" >> "$LOG"

# --- Step 3: cleanup ---
echo "$(date '+%Y-%m-%d %H:%M:%S') CLEANUP START" >> "$LOG"

# Remove unused packages
apt-get autoremove -y -qq >> "$LOG" 2>&1 || true

# Clean apt cache
apt-get autoclean -qq >> "$LOG" 2>&1 || true

# Rotate journald logs: keep max 100MB
journalctl --vacuum-size=100M >> "$LOG" 2>&1 || true

# Remove old journal entries older than 14 days
journalctl --vacuum-time=14d >> "$LOG" 2>&1 || true

# Clear btmp (failed logins) if larger than 50MB
BTMP_SIZE=$(stat -c%s /var/log/btmp 2>/dev/null || echo 0)
if [ "$BTMP_SIZE" -gt 52428800 ]; then
  : > /var/log/btmp
  echo "$(date '+%Y-%m-%d %H:%M:%S') btmp cleared (was $(( BTMP_SIZE / 1048576 ))MB)" >> "$LOG"
fi

# Clear wtmp (login history) if larger than 50MB
WTMP_SIZE=$(stat -c%s /var/log/wtmp 2>/dev/null || echo 0)
if [ "$WTMP_SIZE" -gt 52428800 ]; then
  : > /var/log/wtmp
  echo "$(date '+%Y-%m-%d %H:%M:%S') wtmp cleared (was $(( WTMP_SIZE / 1048576 ))MB)" >> "$LOG"
fi

# Truncate auto-upgrade.log itself if larger than 10MB
UPGLOG_SIZE=$(stat -c%s "$LOG" 2>/dev/null || echo 0)
if [ "$UPGLOG_SIZE" -gt 10485760 ]; then
  tail -500 "$LOG" > "${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"
  echo "$(date '+%Y-%m-%d %H:%M:%S') auto-upgrade.log truncated to last 500 lines" >> "$LOG"
fi

# Report free disk after cleanup
DISK_FREE=$(df -h / | awk 'NR==2{printf "%s used / %s total (%s free)", $3, $2, $4}')
echo "$(date '+%Y-%m-%d %H:%M:%S') CLEANUP OK — Disk: ${DISK_FREE}" >> "$LOG"

# --- Step 4: reboot ---
echo "$(date '+%Y-%m-%d %H:%M:%S') REBOOTING..." >> "$LOG"
sleep 3
/sbin/reboot
EOF

# --- Post-reboot audit script ---
cat > /usr/local/bin/night-audit << 'EOF'
#!/usr/bin/env bash
# = Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz =
#
# night-audit — post-reboot health check
# Sends Telegram ONLY if something is wrong
# Usage: called by cron @reboot

T="1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ"
C="261784949"
S="$(hostname)"
LOG="/var/log/auto-upgrade.log"

tg() {
  curl -s -X POST "https://api.telegram.org/bot${T}/sendMessage" \
    -d "chat_id=${C}" \
    -d "parse_mode=HTML" \
    -d "text=$1" >/dev/null 2>&1 || true
}

# Wait for system to fully boot
sleep 30

echo "$(date '+%Y-%m-%d %H:%M:%S') POST-REBOOT AUDIT" >> "$LOG"

ERRORS=""

# --- Check failed services ---
FAILED=$(systemctl list-units --state=failed --no-legend 2>/dev/null | awk '{print $1}' | head -5 | tr '\n' ' ')
if [ -n "$FAILED" ]; then
  ERRORS="${ERRORS}❌ Failed services: ${FAILED}\n"
fi

# --- Check RAM (alert if > 90%) ---
RAM_PCT=$(free | awk '/^Mem:/{printf "%.0f", ($3/$2)*100}')
if [ "$RAM_PCT" -gt 90 ]; then
  RAM_INFO=$(free -m | awk '/^Mem:/{printf "%dMB/%dMB", $3,$2}')
  ERRORS="${ERRORS}⚠️ RAM critical: ${RAM_INFO} (${RAM_PCT}%)\n"
fi

# --- Check disk (alert if > 85%) ---
DISK_PCT=$(df / | awk 'NR==2{gsub(/%/,"",$5); print $5}')
if [ "$DISK_PCT" -gt 85 ]; then
  DISK_INFO=$(df -h / | awk 'NR==2{printf "%s used (%s)", $3,$5}')
  ERRORS="${ERRORS}⚠️ Disk critical: ${DISK_INFO}\n"
fi

# --- Run audit if exists ---
if [ -x /usr/local/bin/audit ]; then
  AUDIT_RESULT=$(timeout 60 /usr/local/bin/audit 2>&1 | tail -5)
  echo "$AUDIT_RESULT" >> "$LOG"
fi

# --- Send alert ONLY if errors found ---
if [ -n "$ERRORS" ]; then
  UPTIME=$(uptime -p)
  RAM=$(free -m | awk '/^Mem:/{printf "%dMB/%dMB (%d%%)", $3,$2,($3/$2)*100}')
  DISK=$(df -h / | awk 'NR==2{printf "%s used (%s)", $3,$5}')
  LOAD=$(awk '{print $1,$2,$3}' /proc/loadavg)

  MSG="🚨 <b>${S}</b> — problems after reboot!
⏱ ${UPTIME}
🧠 RAM: ${RAM}
💾 Disk: ${DISK}
⚡ Load: ${LOAD}

${ERRORS}"

  tg "$MSG"
  echo "$(date '+%Y-%m-%d %H:%M:%S') ALERT SENT" >> "$LOG"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') OK — no issues, Telegram skipped" >> "$LOG"
fi
EOF

chmod +x /usr/local/bin/night-maintenance
chmod +x /usr/local/bin/night-audit

# --- Update crontab ---
(crontab -l 2>/dev/null \
  | grep -vE 'apt.*update|apt.*upgrade|/sbin/reboot|night-maintenance|night-audit|auto_upgrade|0 2 \* \* \* /usr/local/bin/audit'
  echo "0 2 * * * /usr/local/bin/night-maintenance >> /var/log/auto-upgrade.log 2>&1"
  echo "@reboot /usr/local/bin/night-audit >> /var/log/auto-upgrade.log 2>&1"
) | crontab -

echo "✅ Installed on $(hostname)"
crontab -l | grep -E 'night|reboot'
