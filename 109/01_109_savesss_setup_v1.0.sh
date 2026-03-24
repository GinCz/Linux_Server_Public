cat > /usr/local/bin/savesss << 'EOF'
#!/usr/bin/env bash
clear
echo "1. СБОР ДАННЫХ 109 СЕРВЕРА (Локально)"
LOCAL_BACKUP_DIR="/var/www/gincz/data/www/prodvig-saita.ru/server-set"
if [ ! -d "$LOCAL_BACKUP_DIR" ]; then echo "❌ Ошибка: Папка $LOCAL_BACKUP_DIR не найдена!"; exit 1; fi
cp /usr/local/bin/savesss "$LOCAL_BACKUP_DIR/109-export-to-main-server.sh"
SHORT_NAME="109_PRODVIG"
EXTERNAL_IP="xxx.xxx.xxx.109"
FOLDER_NAME="${EXTERNAL_IP}__${SHORT_NAME}"
ARCHIVE="/tmp/report-${SHORT_NAME}.tar.gz"
cd "$LOCAL_BACKUP_DIR" && tar -czf "$ARCHIVE" ./* 2>/dev/null || { echo "❌ Ошибка архивации!"; exit 1; }
mkdir -p ~/.ssh
ssh -M -f -N -o ControlPath=~/.ssh/cm-%r@%h:%p root@xxx.xxx.xxx.222 || { echo "❌ Ошибка подключения!"; exit 1; }
scp -o ControlPath=~/.ssh/cm-%r@%h:%p "$ARCHIVE" root@xxx.xxx.xxx.222:/tmp/ && \
ssh -o ControlPath=~/.ssh/cm-%r@%h:%p root@xxx.xxx.xxx.222 "mkdir -p /var/www/gincz/data/www/gincz.com/server-set/${FOLDER_NAME} && tar -xzf /tmp/report-${SHORT_NAME}.tar.gz -C /var/www/gincz/data/www/gincz.com/server-set/${FOLDER_NAME} && chown -R gincz:gincz /var/www/gincz/data/www/gincz.com/server-set/${FOLDER_NAME} && rm /tmp/report-${SHORT_NAME}.tar.gz" && \
ssh -O exit -o ControlPath=~/.ssh/cm-%r@%h:%p root@xxx.xxx.xxx.222 2>/dev/null && rm -f "$ARCHIVE"
EOF
chmod +x /usr/local/bin/savesss
