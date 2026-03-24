#!/bin/bash
# telegram_alert.sh — Universal Telegram alerts for all servers
# Version: v2026-03-24
# Monitors: CPU, RAM, Disk, Nginx, PHP-FPM, SSH login
# Setup: bash /root/Linux_Server_Public/scripts/setup_telegram_alerts.sh

TG_TOKEN="1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ"
TG_CHAT="261784949"
HOST=$(hostname)
IP=$(hostname -I | awk '{print $1}')

CPU_LIMIT=80
RAM_LIMIT=85
DISK_LIMIT=80

send_alert() {
    local MSG="$1"
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d chat_id="${TG_CHAT}" \
        -d parse_mode="HTML" \
        -d text="${MSG}" > /dev/null 2>&1
}

# --- CPU ---
CPU=$(top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}')
if [ "$CPU" -gt "$CPU_LIMIT" ]; then
    send_alert "🔴 <b>CPU ALERT</b>\n🖥 ${HOST} (${IP})\nCPU: <b>${CPU}%</b> (limit: ${CPU_LIMIT}%)"
fi

# --- RAM ---
RAM_USED=$(free | awk '/Mem:/{printf "%.0f", $3/$2*100}')
RAM_INFO=$(free -m | awk '/Mem:/{printf "%s/%s MB", $3, $2}')
if [ "$RAM_USED" -gt "$RAM_LIMIT" ]; then
    send_alert "🔴 <b>RAM ALERT</b>\n🖥 ${HOST} (${IP})\nRAM: <b>${RAM_USED}%</b> — ${RAM_INFO} (limit: ${RAM_LIMIT}%)"
fi

# --- DISK ---
DISK_USED=$(df / | awk 'NR==2{print int($5)}')
DISK_INFO=$(df -h / | awk 'NR==2{printf "%s / %s", $3, $2}')
if [ "$DISK_USED" -gt "$DISK_LIMIT" ]; then
    send_alert "🔴 <b>DISK ALERT</b>\n🖥 ${HOST} (${IP})\nDisk: <b>${DISK_USED}%</b> — ${DISK_INFO} (limit: ${DISK_LIMIT}%)"
fi

# --- NGINX ---
if ! systemctl is-active --quiet nginx; then
    send_alert "🔴 <b>NGINX DOWN</b>\n🖥 ${HOST} (${IP})\nnginx is NOT running!"
fi

# --- PHP-FPM ---
if systemctl list-units --type=service | grep -q 'php.*fpm'; then
    if ! systemctl is-active --quiet "$(systemctl list-units --type=service | grep 'php.*fpm' | awk '{print $1}' | head -1)"; then
        send_alert "🔴 <b>PHP-FPM DOWN</b>\n🖥 ${HOST} (${IP})\nPHP-FPM is NOT running!"
    fi
fi
