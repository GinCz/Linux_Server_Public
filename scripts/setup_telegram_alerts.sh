#!/bin/bash
clear
# setup_telegram_alerts.sh — Install Telegram alerts on any server
# Version: v2026-08-01
# Usage: bash /root/Linux_Server_Public/scripts/setup_telegram_alerts.sh
# NOTE: Token is read from /root/.server_env (TG_TOKEN variable)
#       Or export TG_TOKEN before running this script
# = Rooted by VladiMIR + AI | v.2026.08.01 | github.com/GinCz =

source /root/.server_env 2>/dev/null || true

TG_TOKEN="${TG_TOKEN:-}"
TG_CHAT="${TG_CHAT_ID:-261784949}"
HOST=$(hostname)
IP=$(hostname -I | awk '{print $1}')
ALERT_SCRIPT="/root/Linux_Server_Public/scripts/telegram_alert.sh"

if [ -z "$TG_TOKEN" ]; then
    echo "ERROR: TG_TOKEN is not set!"
    echo "Run: export TG_TOKEN='your_bot_token' before this script"
    echo "Or add TG_TOKEN=... to /root/.server_env"
    exit 1
fi

TRUSTED_IPS="185.100.197.16 90.181.133.10 185.14.233.235 185.14.232.0"

echo ""
echo "=== TELEGRAM ALERTS SETUP: $HOST ==="
echo ""

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

echo "[2/4] Installing cron job (every 5 min)..."
chmod +x "$ALERT_SCRIPT"
(crontab -l 2>/dev/null | grep -v 'telegram_alert'; echo "*/5 * * * * bash $ALERT_SCRIPT") | crontab -
echo "   ✅ Cron installed: every 5 minutes"

echo "[3/4] Installing SSH login alert (whitelist: $TRUSTED_IPS)..."

SSH_BLOCK=$(cat << SSHEOF
if [ -n "\$SSH_CLIENT" ]; then
    source /root/.server_env 2>/dev/null || true
    _TG_TOKEN="\${TG_TOKEN:-}"
    _TG_CHAT="\${TG_CHAT_ID:-261784949}"
    _FROM_IP=\$(echo \$SSH_CLIENT | awk '{print \$1}')
    _TRUSTED="185.100.197.16 90.181.133.10 185.14.233.235 185.14.232.0"
    _IS_TRUSTED=0
    for _T in \$_TRUSTED; do
        [ "\$_FROM_IP" = "\$_T" ] && _IS_TRUSTED=1 && break
    done
    if [ "\$_IS_TRUSTED" = "0" ] && [ -n "\$_TG_TOKEN" ]; then
        curl -s -X POST "https://api.telegram.org/bot\${_TG_TOKEN}/sendMessage" \
            -d chat_id="\${_TG_CHAT}" \
            -d parse_mode="HTML" \
            -d text="&#x1F6A8; <b>UNKNOWN SSH LOGIN</b>%0A&#x1F5A5; \$(hostname) (\$(hostname -I | awk '{print \$1}'))%0AUser: \$USER%0AFrom: <b>\$_FROM_IP</b>" \
            > /dev/null 2>&1
    fi
fi
SSHEOF
)

if ! grep -q 'UNKNOWN SSH LOGIN' /etc/profile.d/motd_banner.sh 2>/dev/null; then
    echo "$SSH_BLOCK" >> /etc/profile.d/motd_banner.sh
    echo "   ✅ SSH alert added to /etc/profile.d/motd_banner.sh"
else
    echo "   ✔ SSH alert already exists — skipped"
fi

echo "[4/4] Done!"
echo ""
echo "✅ Telegram alerts active on: $HOST ($IP)"
echo "✅ Monitoring every 5 min: CPU RAM Disk Nginx PHP-FPM"
echo "✅ SSH alert: fires ONLY for unknown IPs"
echo "✅ Trusted IPs (no alert): $TRUSTED_IPS"
echo "✅ Alerts go to Chat ID: ${TG_CHAT} (@My_WWW_bot)"
echo ""
echo "To test manually:"
echo "  bash $ALERT_SCRIPT"
echo ""
echo "========================================="
