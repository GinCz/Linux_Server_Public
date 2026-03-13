#!/usr/bin/env bash
clear
# English comments: Universal Public Installer v1.0
CONF_FILE="/root/.server_env"
if [ ! -f "$CONF_FILE" ]; then
    echo "❌ Error: /root/.server_env not found!"
    exit 1
fi
source "$CONF_FILE"

echo "🚀 Starting setup on $(hostname)..."
# Пример использования переменной бота из конфига
curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
     -d "chat_id=${TG_CHAT_ID}" -d "text=Setup started on $(hostname)" >/dev/null

# Здесь будет ваш основной код настройки, использующий переменные
echo "✅ Done!"
