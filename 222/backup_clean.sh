#!/bin/bash
clear
# =============================================================================
#  backup_clean.sh — Deep Clean + System Backup — Server 222-DE-NetCup
# =============================================================================
#  Version    : v2026-03-30
#  Author     : Ing. VladiMIR Bulantsev
#  GitHub     : https://github.com/GinCz/Linux_Server_Public
# =============================================================================
#
#  DESCRIPTION
#  -----------
#  Nightly script running at 02:00 via cron.
#  1. Deep cleanup of server junk (logs, cache, temp, VSCode binaries, etc.)
#  2. Selective archive of config files only (target: <30 MB)
#  3. Save locally to /BACKUP/222/
#  4. Send copy to remote server 109 via SCP
#  5. Telegram notification — ONLY on error
#
#  WHAT IS ARCHIVED
#  ----------------
#  /etc                          — all system configs
#  /root/.ssh                    — SSH keys
#  /root/*.sh                    — root-level scripts
#  /root/Linux_Server_Public     — GitHub repo (configs, scripts)
#  /root/crypto-docker/scripts   — crypto-bot scripts
#  /root/crypto-docker/templates — crypto-bot templates
#  /root/crypto-docker/docker-compose.yml
#  /root/semaphore-data          — semaphore config (NO DB — covered by docker_backup.sh)
#  /usr/local/fastpanel2         — FastPanel config, SSL, templates
#
#  WHAT IS NOT ARCHIVED
#  --------------------
#  Docker container data         — handled by docker_backup.sh (cron 03:00)
#  /var/www sites                — too large, use FastPanel backup
#  logs, cache, sessions, tmp    — cleaned before archive
#  .git folders                  — not needed
#  VSCode server binaries        — cleaned before archive
#  node_modules                  — too large
#
#  CRON
#  ----
#  0 2 * * * /root/backup_clean.sh >> /var/log/system-backup.log 2>&1
#
#  ROTATION
#  --------
#  Keeps last 10 archives locally and on remote 109.
#
#  RESTORE
#  -------
#  tar -xzf BackUp_222-EU__YYYY-MM-DD_HH-MM.tar.gz -C /
#
# =============================================================================
#  = Rooted by VladiMIR | AI =
# =============================================================================

C="\033[1;36m"; G="\033[1;32m"; Y="\033[1;33m"; R="\033[1;31m"; X="\033[0m"
HR="${Y}═══════════════════════════════════════════════════════════════════════════════════════════════${X}"

# =============================================================================
#  CONFIG
# =============================================================================

SERVER_NAME="222-EU"
LOCAL_DIR="/BACKUP/222"
REMOTE_USER="vlad"
REMOTE_IP="212.109.223.109"
REMOTE_DIR="/BACKUP/222"
KEEP_BACKUPS=10

# Telegram token — read from crypto-bot config.json (no hardcode in public repo)
TG_TOKEN=$(python3 -c "import json; c=json.load(open('/root/crypto-docker/config.json')); print(c.get('tg_token',''))" 2>/dev/null)
TG_CHAT=$(python3 -c "import json; c=json.load(open('/root/crypto-docker/config.json')); print(c.get('tg_chat_id',''))" 2>/dev/null)

# =============================================================================
#  INTERNAL
# =============================================================================

TIMESTAMP=$(date '+%Y-%m-%d_%H-%M')
FILENAME="BackUp_${SERVER_NAME}__${TIMESTAMP}.tar.gz"
TMPFILE="/tmp/${FILENAME}"
ERRORS=0

log()  { echo -e "${C}$(date +%H:%M:%S)${X} $1"; }
fail() { echo -e "${R}$(date +%H:%M:%S) ❌ $1${X}"; ERRORS=$((ERRORS+1)); }

tg_send() {
    [ -z "$TG_TOKEN" ] && return
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d chat_id="${TG_CHAT}" \
        -d parse_mode="Markdown" \
        -d text="$1" >/dev/null 2>&1
}

echo -e "$HR"
echo -e "${Y}   🖿️  BACKUP+CLEAN — ${SERVER_NAME}  →  local + ${REMOTE_IP}${X}"
echo -e "${Y}   📅 $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "$HR"
echo

# =============================================================================
#  [1/6] DEEP CLEANUP
# =============================================================================
log "[1/6] Deep cleanup..."

# System journals
journalctl --vacuum-time=1s >/dev/null 2>&1

# APT cache
apt-get clean -qq 2>/dev/null

# Temp files
rm -f /tmp/disk_test_file.* 2>/dev/null
rm -f /tmp/*.tar.gz /tmp/*.tar /tmp/*.zip 2>/dev/null

# Old nginx/wp backup folders in /root
rm -rf /root/nginx-wp-protect-backup-* 2>/dev/null
rm -rf /root/wp-final-backup-* /root/wp-protect-backup-* 2>/dev/null
rm -rf /root/nginx_backups_* 2>/dev/null

# SSH diagnostic logs
rm -rf /root/ssh_logs /root/ssh_full_*.log 2>/dev/null

# Diagnostic / audit files older than 7 days
find /root -maxdepth 1 -name "diag-*"              -mtime +7 -delete 2>/dev/null
find /root -maxdepth 1 -name "alliances_inventory_*" -mtime +7 -delete 2>/dev/null
find /root -maxdepth 1 -name "*.log"               -mtime +7 -delete 2>/dev/null
find /root -maxdepth 1 -name "*.txt"               -mtime +30 -delete 2>/dev/null
find /root -maxdepth 1 -name "*.py"                -mtime +30 -delete 2>/dev/null
find /root -maxdepth 2 -name "*.sh" -path "*/safe-backup*" -delete 2>/dev/null

# Wireguard temp archive
rm -f /root/wireguard.tar 2>/dev/null

# proftpd blacklist (regenerated automatically)
rm -f /etc/proftpd/blacklist.dat 2>/dev/null

# VSCode Server binaries (heavy, not needed in backup)
rm -rf /root/.vscode-server/cli/servers/*/server/node_modules 2>/dev/null
rm -rf /root/.vscode-server/cli/servers/*/server/extensions/node_modules 2>/dev/null
rm -f  /root/.vscode-server/cli/servers/*/server/node 2>/dev/null
rm -f  /root/.vscode-server/code-* 2>/dev/null

# Python cache in all projects
find /root -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
find /root -type f -name "*.pyc" -delete 2>/dev/null

# Crowdsec hub (large, reinstalled via cscli)
rm -rf /etc/crowdsec/hub 2>/dev/null

log "  ✅ cleanup done"
echo

# =============================================================================
#  [2/6] ROTATE OLD BACKUPS (before creating new)
# =============================================================================
log "[2/6] Rotating old local backups (keep ${KEEP_BACKUPS})..."
ls -t "${LOCAL_DIR}"/BackUp_${SERVER_NAME}__*.tar.gz 2>/dev/null \
    | tail -n +$((KEEP_BACKUPS+1)) | xargs -r rm -f
log "  ✅ done"
echo

# =============================================================================
#  [3/6] CREATE ARCHIVE (configs only, target <30 MB)
# =============================================================================
log "[3/6] Creating archive (configs only)..."
mkdir -p "${LOCAL_DIR}"

tar -czf "${TMPFILE}" \
    /etc \
    /root/.ssh \
    /root/*.sh \
    /root/Linux_Server_Public \
    /root/crypto-docker/scripts \
    /root/crypto-docker/templates \
    /root/crypto-docker/docker-compose.yml \
    /root/semaphore-data \
    /usr/local/fastpanel2/config \
    /usr/local/fastpanel2/templates \
    /usr/local/fastpanel2/letsencrypt \
    /usr/local/fastpanel2/ssl \
    /usr/local/fastpanel2/skel \
    /usr/local/fastpanel2/location-nginx \
    /usr/local/fastpanel2/configuration_backup \
    --exclude='*/.git' \
    --exclude='*/session/*' \
    --exclude='*/sessions/*' \
    --exclude='*/cache/*' \
    --exclude='*/logs/*' \
    --exclude='*/log/*' \
    --exclude='*/tmp/*' \
    --exclude='*/node_modules/*' \
    --exclude='*/__pycache__/*' \
    --exclude='*.pyc' \
    --exclude='*/data/www/*' \
    --exclude='*/data/backups/*' \
    --exclude='/root/crypto-docker/data/*' \
    --exclude='/BACKUP/*' \
    --exclude='/root/.vscode-server' \
    --exclude='/etc/crowdsec/hub' \
    --exclude='/etc/apparmor.d' \
    --exclude='/etc/proftpd/blacklist.dat' \
    2>/dev/null

SIZE=$(du -sh "${TMPFILE}" 2>/dev/null | cut -f1)

if [ -s "${TMPFILE}" ]; then
    log "  ✅ ${FILENAME} (${Y}${SIZE}${X})"
else
    fail "Archive FAILED or empty"
fi
echo

# =============================================================================
#  [4/6] SAVE LOCALLY
# =============================================================================
log "[4/6] Saving locally → ${LOCAL_DIR}..."
cp "${TMPFILE}" "${LOCAL_DIR}/" && log "  ✅ done" || fail "Local copy FAILED"
echo

# =============================================================================
#  [5/6] SEND TO REMOTE 109
# =============================================================================
log "[5/6] Sending to ${REMOTE_IP}..."
REMOTE_OK=0

ssh -o StrictHostKeyChecking=no -o ConnectTimeout=15 \
    ${REMOTE_USER}@${REMOTE_IP} \
    "mkdir -p ${REMOTE_DIR} && ls -t ${REMOTE_DIR}/BackUp_${SERVER_NAME}__*.tar.gz 2>/dev/null | tail -n +$((KEEP_BACKUPS+1)) | xargs -r rm -f" \
    2>/dev/null

scp -o StrictHostKeyChecking=no -o ConnectTimeout=15 \
    "${TMPFILE}" "${REMOTE_USER}@${REMOTE_IP}:${REMOTE_DIR}/" 2>/dev/null \
    && REMOTE_OK=1

rm -f "${TMPFILE}"

if [ $REMOTE_OK -eq 1 ]; then
    log "  ✅ copy sent to ${REMOTE_IP}"
else
    fail "SCP to ${REMOTE_IP} FAILED — saved locally only"
fi
echo

# =============================================================================
#  [6/6] TELEGRAM — only on error
# =============================================================================
if [ $ERRORS -gt 0 ]; then
    log "[6/6] Telegram — sending error alert..."
    tg_send "⚠️ *BACKUP ERROR* | ${SERVER_NAME}%0A%0A📦 ${FILENAME}%0A📊 Size: ${SIZE}%0A%0A❌ Errors: ${ERRORS}%0A🕐 $(date '+%Y-%m-%d %H:%M')"
else
    log "[6/6] Telegram — all OK, no notification sent"
fi
echo

# =============================================================================
#  SUMMARY
# =============================================================================
echo -e "$HR"
LOCAL_COUNT=$(ls "${LOCAL_DIR}"/BackUp_${SERVER_NAME}__*.tar.gz 2>/dev/null | wc -l)

if [ $ERRORS -eq 0 ]; then
    log "${G}✅ ALL OK — ${FILENAME} (${SIZE}) — ${LOCAL_COUNT}/${KEEP_BACKUPS} local archives${X}"
else
    log "${R}⚠️  DONE WITH ${ERRORS} ERROR(S)${X}"
fi

echo -e "$HR"
echo -e "${Y}              = Rooted by VladiMIR | AI =${X}"
echo -e "$HR"
echo
