#!/usr/bin/env bash
# = Rooted by VladiMIR + AI | v.2026.05.27 | github.com/GinCz =
#
# install-night.sh — Night maintenance script installer
# -------------------------------------------------------
# Schedule: 02:00 — apt update + upgrade → reboot
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
# = Rooted by VladiMIR + AI | v.2026.05.27 | github.com/GinCz =
#
# night-maintenance — nightly update + reboot
# Usage: called by cron at 02:00
# Steps: apt update → apt upgrade → reboot
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

# --- Step 3: reboot ---
echo "$(date '+%Y-%m-%d %H:%M:%S') REBOOTING..." >> "$LOG"
sleep 3
/sbin/reboot
EOF

# --- Post-reboot audit script ---
cat > /usr/local/bin/night-audit << 'EOF'
#!/usr/bin/env bash
# = Rooted by VladiMIR + AI | v.2026.05.27 | github.com/GinCz =
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
