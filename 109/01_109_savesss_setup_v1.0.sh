#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  01_109_savesss_setup_v1.0.sh | [v2026-05-01]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Deploy /usr/local/bin/savesss data export script from 109-RU to 222-DE
# Servers     : 109-RU FastVDS (212.109.223.109)
# Usage       : bash 109/01_109_savesss_setup_v1.0.sh
# ==========================================================================================

cat > /usr/local/bin/savesss << 'EOF'
#!/usr/bin/env bash
clear
echo "1. Collecting 109 Server Data (Local)"
LOCAL_BACKUP_DIR="/var/www/gincz/data/www/prodvig-saita.ru/server-set"
if [ ! -d "$LOCAL_BACKUP_DIR" ]; then echo "❌ Error: Directory $LOCAL_BACKUP_DIR not found!"; exit 1; fi
cp /usr/local/bin/savesss "$LOCAL_BACKUP_DIR/109-export-to-main-server.sh"
SHORT_NAME="109_PRODVIG"
EXTERNAL_IP="212.109.223.109"
FOLDER_NAME="${EXTERNAL_IP}__${SHORT_NAME}"
ARCHIVE="/tmp/report-${SHORT_NAME}.tar.gz"
cd "$LOCAL_BACKUP_DIR" && tar -czf "$ARCHIVE" ./* 2>/dev/null || { echo "❌ Error: Archiving failed!"; exit 1; }
mkdir -p ~/.ssh
ssh -M -f -N -o ControlPath=~/.ssh/cm-%r@%h:%p root@152.53.182.222 || { echo "❌ Error: Connection failed!"; exit 1; }
scp -o ControlPath=~/.ssh/cm-%r@%h:%p "$ARCHIVE" root@152.53.182.222:/tmp/ && \
ssh -o ControlPath=~/.ssh/cm-%r@%h:%p root@152.53.182.222 "mkdir -p /var/www/gincz/data/www/gincz.com/server-set/${FOLDER_NAME} && tar -xzf /tmp/report-${SHORT_NAME}.tar.gz -C /var/www/gincz/data/www/gincz.com/server-set/${FOLDER_NAME} && chown -R gincz:gincz /var/www/gincz/data/www/gincz.com/server-set/${FOLDER_NAME} && rm /tmp/report-${SHORT_NAME}.tar.gz" && \
ssh -O exit -o ControlPath=~/.ssh/cm-%r@%h:%p root@152.53.182.222 2>/dev/null && rm -f "$ARCHIVE"
EOF
chmod +x /usr/local/bin/savesss

echo "========================================="

# = Rooted by VladiMIR | AI = v2026-05-01 = github.com/GinCz/Linux_Server_Public


