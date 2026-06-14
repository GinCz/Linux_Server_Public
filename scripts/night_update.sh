#!/bin/bash
# =============================================================
# Script:      night_update.sh
# Version:     v2026.06.15b
# Location:    /root/night_update.sh  (downloaded from GitHub)
#
# Usage:
#   bash /root/night_update.sh --mode=vpn    # VPN nodes: update + reboot (Wed & Sat)
#   bash /root/night_update.sh --mode=sites  # Site servers: update, NO reboot (Sat only)
#   bash /root/night_update.sh --audit       # Post-reboot audit (called via @reboot cron)
#   bash /root/night_update.sh --mode=vpn --force  # Run immediately, ignore schedule
#
# Cron for VPN servers (Wed + Sat at 02:00):
#   0 2 * * 3,6 bash /root/night_update.sh --mode=vpn >> /var/log/night_update.log 2>&1
#
# Cron for site servers (Sat only at 02:00, NO reboot):
#   0 2 * * 6 bash /root/night_update.sh --mode=sites >> /var/log/night_update.log 2>&1
#
# @reboot cron (ALL servers):
#   @reboot sleep 30 && bash /root/night_update.sh --audit >> /var/log/night_update.log 2>&1
#
# TG credentials: /root/.tg_config  (chmod 600, NOT in repo)
#   Содержимое: TG_TOKEN="..." TG_CHAT="..."
#   Задеплоен на все 10 серверов — см. scripts/README.md
#
# = Rooted by VladiMIR + AI | v.2026.06.15b | github.com/GinCz/Linux_Server_Public =
# =============================================================

# Telegram credentials — из файла на сервере, не из репо
source /root/.tg_config 2>/dev/null || { echo "ERROR: /root/.tg_config not found"; exit 1; }
T="$TG_TOKEN"
C="$TG_CHAT"

S="$(hostname)"
LOG="/var/log/night_update.log"

# Сервисы которые шумят но не являются реальными ошибками
NOISE_SERVICES="certbot|exim4|fwupd|motd-news|logrotate|openipmi|packagekit|apport"

tg() {
    curl -s -X POST "https://api.telegram.org/bot${T}/sendMessage" \
        -d "chat_id=${C}" \
        -d "parse_mode=HTML" \
        -d "disable_notification=true" \
        -d "text=$1" >/dev/null 2>&1 || true
}

# =============================================================
# --audit : POST-REBOOT CHECK (called via @reboot cron)
# =============================================================
if [ "$1" = "--audit" ]; then
    sleep 90
    echo "$(date '+%Y-%m-%d %H:%M:%S') POST-REBOOT AUDIT — ${S}" >> "$LOG"
    ERRORS=""

    # Failed services — фильтруем системный шум
    FAILED=$(systemctl list-units --state=failed --no-legend 2>/dev/null \
        | awk '{print $2}' \
        | grep -Ev "^$|${NOISE_SERVICES}" \
        | head -5 | tr '\n' ' ')
    [ -n "$FAILED" ] && ERRORS="${ERRORS}&#x274C; Failed: ${FAILED}\n"

    # RAM > 90%
    RAM_PCT=$(free | awk '/^Mem:/{printf "%.0f", ($3/$2)*100}')
    if [ "$RAM_PCT" -gt 90 ]; then
        RAM_INFO=$(free -m | awk '/^Mem:/{printf "%dMB/%dMB", $3,$2}')
        ERRORS="${ERRORS}&#x26A0; RAM critical: ${RAM_INFO} (${RAM_PCT}%)\n"
    fi

    # Disk > 85%
    DISK_PCT=$(df / | awk 'NR==2{gsub(/%/,"",$5); print $5}')
    if [ "$DISK_PCT" -gt 85 ]; then
        DISK_INFO=$(df -h / | awk 'NR==2{printf "%s used (%s)", $3,$5}')
        ERRORS="${ERRORS}&#x26A0; Disk critical: ${DISK_INFO}\n"
    fi

    if [ -n "$ERRORS" ]; then
        UPTIME=$(uptime -p)
        RAM=$(free -m | awk '/^Mem:/{printf "%dMB/%dMB (%d%%)", $3,$2,($3/$2)*100}')
        DISK=$(df -h / | awk 'NR==2{printf "%s used (%s)", $3,$5}')
        LOAD=$(awk '{print $1,$2,$3}' /proc/loadavg)
        tg "&#x1F6A8; <b>${S}</b> — problems after reboot!
&#x23F1; ${UPTIME}
&#x1F9E0; RAM: ${RAM}
&#x1F4BE; Disk: ${DISK}
&#x26A1; Load: ${LOAD}

${ERRORS}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') AUDIT ALERT SENT" >> "$LOG"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') AUDIT OK — no issues" >> "$LOG"
    fi
    exit 0
fi

# =============================================================
# PARSE MODE
# =============================================================
MODE=""
FORCE=0
for ARG in "$@"; do
    case "$ARG" in
        --mode=vpn)   MODE="vpn" ;;
        --mode=sites) MODE="sites" ;;
        --force)      FORCE=1 ;;
    esac
done

if [ -z "$MODE" ]; then
    echo "Usage: $0 --mode=vpn|sites [--force] [--audit]"
    echo "  --mode=vpn   : update + reboot (VPN nodes, Wed & Sat)"
    echo "  --mode=sites : update only, NO reboot (site servers, Sat only)"
    echo "  --audit      : post-reboot check"
    echo "  --force      : ignore schedule, run now"
    exit 1
fi

# =============================================================
# SCHEDULE CHECK
# =============================================================
DOW=$(date +%u)   # 1=Mon ... 6=Sat ... 7=Sun
# vpn   — среда (3) и суббота (6)
# sites — только суббота (6)

if [ "$FORCE" -eq 0 ]; then
    if [ "$MODE" = "vpn" ] && [ "$DOW" != "3" ] && [ "$DOW" != "6" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') SKIP — VPN runs Wed+Sat only (today DOW=${DOW})"
        exit 0
    fi
    if [ "$MODE" = "sites" ] && [ "$DOW" != "6" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') SKIP — Sites run Sat only (today DOW=${DOW})"
        exit 0
    fi
fi

# =============================================================
# MAIN UPDATE
# =============================================================
exec >> "$LOG" 2>&1
echo "========================================"
echo "$(date '+%Y-%m-%d %H:%M:%S') NIGHT UPDATE START — ${S} [mode=${MODE}]"

# apt update
if ! apt-get update -qq; then
    tg "&#x274C; <b>${S}</b>: apt update FAILED"
    exit 1
fi

# apt upgrade
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    tg "&#x274C; <b>${S}</b>: apt upgrade ERROR (exit ${EXIT_CODE})"
    exit 1
fi

# Cleanup
DEBIAN_FRONTEND=noninteractive apt-get autoremove -y -qq \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" || true
apt-get autoclean -qq || true
apt-get clean -qq || true

# Очистка tmp
find /tmp -mindepth 1 -mtime +1 -delete 2>/dev/null || true
find /var/tmp -mindepth 1 -mtime +7 -delete 2>/dev/null || true

# Очистка журналов
journalctl --vacuum-size=100M --quiet || true
journalctl --vacuum-time=14d --quiet  || true

# btmp / wtmp > 50MB
for F in /var/log/btmp /var/log/wtmp; do
    SZ=$(stat -c%s "$F" 2>/dev/null || echo 0)
    if [ "$SZ" -gt 52428800 ]; then
        : > "$F"
        echo "$(date '+%Y-%m-%d %H:%M:%S') $(basename $F) cleared ($(( SZ / 1048576 ))MB)"
    fi
done

# Ротация этого лога > 10MB
LOG_SIZE=$(stat -c%s "$LOG" 2>/dev/null || echo 0)
if [ "$LOG_SIZE" -gt 10485760 ]; then
    tail -500 "$LOG" > "${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"
    echo "$(date '+%Y-%m-%d %H:%M:%S') log rotated (kept last 500 lines)"
fi

DISK_FREE=$(df -h / | awk 'NR==2{printf "%s used / %s total (%s free)", $3, $2, $4}')
echo "$(date '+%Y-%m-%d %H:%M:%S') UPDATE + CLEANUP OK — Disk: ${DISK_FREE}"

# =============================================================
# REBOOT LOGIC
# =============================================================
REBOOT_REQUIRED=0
PKGS=""
[ -f /var/run/reboot-required ] && REBOOT_REQUIRED=1
PKGS=$(cat /var/run/reboot-required.pkgs 2>/dev/null | tr '\n' ' ')

if [ "$MODE" = "vpn" ]; then
    # VPN — всегда перезагружаемся
    echo "$(date '+%Y-%m-%d %H:%M:%S') REBOOTING (VPN mode)..."
    tg "&#x1F504; <b>${S}</b> — ночное обновление OK, перезагрузка
&#x1F4C5; $(date '+%Y-%m-%d %H:%M')
&#x1F4BE; Disk: ${DISK_FREE}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') NIGHT UPDATE FINISH"
    echo "========================================"
    sleep 5
    /sbin/reboot

elif [ "$MODE" = "sites" ]; then
    # SITES — никогда не перезагружаемся сами, только TG если надо
    if [ "$REBOOT_REQUIRED" -eq 1 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') ⚠ Kernel update — MANUAL reboot required!"
        tg "&#x1F504; <b>${S}</b> — обновление OK, нужна <b>ручная перезагрузка</b>
&#x26A0; Kernel packages updated: ${PKGS}
&#x1F4C5; $(date '+%Y-%m-%d %H:%M')
&#x1F4BE; Disk: ${DISK_FREE}"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') No reboot needed"
        tg "&#x2705; <b>${S}</b> — ночное обновление OK
&#x1F4C5; $(date '+%Y-%m-%d %H:%M')
&#x1F4BE; Disk: ${DISK_FREE}"
    fi
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') NIGHT UPDATE FINISH"
echo "========================================"
