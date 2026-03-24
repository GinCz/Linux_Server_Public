#!/bin/bash
clear
# setup_telegram_alerts.sh — Install Telegram alerts on any server
# Version: v2026-03-24
# Usage: bash /root/Linux_Server_Public/scripts/setup_telegram_alerts.sh

TG_TOKEN="1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ"
TG_CHAT="261784949"
HOST=$(hostname)
IP=$(hostname -I | awk '{print $1}')
ALERT_SCRIPT="/root/Linux_Server_Public/scripts/telegram_alert.sh"

echo ""
echo "=== TELEGRAM ALERTS SETUP: $HOST ==="
echo ""

# --- 1. Test connection ---
echo "[1/4] Testing Telegram connection..."
RESULT=$(curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -d chat_id="${TG_CHAT}" \
    -d parse_mode="HTML" \
    -d text="✅ <b>Telegram alerts activated</b>%0A🖥 Server: <b>${HOST}</b> (${IP})%0AMonitoring: CPU RAM Disk Nginx PHP-FPM SSH")
if echo "$RESULT" | grep -q '"ok":true'; then
    echo "   ✅ Telegram OK — test message sent!"
else
    echo "   ❌ Telegram ERROR: $RESULT"
    exit 1
fi

# --- 2. Install cron every 5 minutes ---
echo "[2/4] Installing cron job (every 5 min)..."
chmod +x "$ALERT_SCRIPT"
(crontab -l 2>/dev/null | grep -v 'telegram_alert'; echo "*/5 * * * * bash $ALERT_SCRIPT") | crontab -
echo "   ✅ Cron installed: every 5 minutes"

# --- 3. SSH login alert ---
echo "[3/4] Installing SSH login alert..."
SSH_ALERT_LINE="if [ -n \"\$SSH_CLIENT\" ]; then curl -s -X POST \"https://api.telegram.org/bot${TG_TOKEN}/sendMessage\" -d chat_id=\"${TG_CHAT}\" -d parse_mode=\"HTML\" -d text=\"🔑 <b>SSH LOGIN</b>%0A🖥 ${HOST} (${IP})%0AUser: \$USER%0AFrom: \$(echo \$SSH_CLIENT | awk '{print \$1}')\" > /dev/null 2>&1; fi"
if ! grep -q 'SSH LOGIN' /etc/profile.d/motd_banner.sh 2>/dev/null; then
    echo "$SSH_ALERT_LINE" >> /etc/profile.d/motd_banner.sh
    echo "   ✅ SSH login alert added to /etc/profile.d/motd_banner.sh"
else
    echo "   ✔ SSH login alert already exists"
fi

# --- 4. Summary ---
echo "[4/4] Done!"
echo ""
echo "✅ Telegram alerts active on: $HOST ($IP)"
echo "✅ Monitoring every 5 min: CPU RAM Disk Nginx PHP-FPM"
echo "✅ SSH login alert: every login sends Telegram message"
echo "✅ Alerts go to Chat ID: ${TG_CHAT}"
echo ""
echo "To test manually:"
echo "  bash $ALERT_SCRIPT"
echo ""
