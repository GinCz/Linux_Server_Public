#!/usr/bin/env bash
# =============================================================================
# scan_clamav_vpn.sh — ClamAV On-Demand Scanner for VPN Servers
# =============================================================================
# Version  : v2026-05-01
# Author   : Ing. VladiMIR Bulantsev
# GitHub   : https://github.com/GinCz/Linux_Server_Public
#
# PURPOSE:
#   Manual antivirus scan for VPN servers (no permanent daemon).
#   Scans /root, /tmp, /var/tmp, /home, /opt, /etc.
#   Sends Telegram report on completion (threats found OR clean).
#
# USAGE:
#   bash /root/Linux_Server_Public/VPN/scan_clamav_vpn.sh
#   alias: antivir
#
# REQUIREMENTS:
#   - clamav installed: apt install -y clamav
#   - TG_TOKEN and TG_CHAT_ID exported in environment
#     (source /root/Linux_Server_Public/scripts/common.sh)
#
# INSTALL (one-time):
#   apt install -y clamav && systemctl stop clamav-freshclam
#   systemctl disable clamav-freshclam   # disable auto-daemon
#   freshclam                            # update DB manually once
#
# NOTE: clamd daemon is NOT used. Scan runs via clamscan (on-demand only).
#       This saves ~200MB RAM permanently on VPN servers.
# = Rooted by VladiMIR | AI =
# =============================================================================

clear

source /root/Linux_Server_Public/scripts/common.sh 2>/dev/null

C='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; B='\033[0;34m'; X='\033[0m'
SERVER_NAME=$(hostname)
SERVER_IP=$(hostname -I | awk '{print $1}')
LOG_FILE="/tmp/clamav_vpn_${SERVER_NAME}.log"
> "$LOG_FILE"

echo -e "${Y}╔══════════════════════════════════════════════════════╗${X}"
echo -e "${Y}║        ClamAV On-Demand Scanner — VPN Server        ║${X}"
echo -e "${Y}╚══════════════════════════════════════════════════════╝${X}"
echo -e "  Server : ${C}${SERVER_NAME}${X} (${SERVER_IP})"
echo -e "  Date   : $(date '+%Y-%m-%d %H:%M:%S')\n"

# Install ClamAV if missing
if ! command -v clamscan &>/dev/null; then
    echo -e "${Y}[!] ClamAV not found. Installing...${X}"
    apt-get install -y clamav 2>&1 | tail -5
    systemctl stop clamav-freshclam 2>/dev/null
    systemctl disable clamav-freshclam 2>/dev/null
    echo -e "${C}[+] ClamAV installed. Daemon disabled (on-demand mode).${X}\n"
fi

# Step 1: Update virus definitions
echo -e "${B}[1/3] Updating virus definitions...${X}"
systemctl stop clamav-freshclam 2>/dev/null
freshclam --quiet 2>/dev/null && echo -e "${C}     Done.${X}" || echo -e "${Y}     Skipped (already up to date).${X}"
echo ""

# Scan targets for VPN servers
SCAN_PATHS="/root /tmp /var/tmp /home /opt /etc"

# Step 2: Count files
echo -e "${B}[2/3] Counting files in: ${SCAN_PATHS}${X}"
TOTAL_FILES=$(find $SCAN_PATHS -type f 2>/dev/null | wc -l)
echo -e "     Found ${C}${TOTAL_FILES}${X} files to scan.\n"

# Step 3: Scan
echo -e "${B}[3/3] Scanning (low priority, background I/O)...${X}\n"

nice -n 19 ionice -c 3 clamscan -r --no-summary $SCAN_PATHS 2>/dev/null | \
awk -v total="$TOTAL_FILES" -v logfile="$LOG_FILE" -v green="\033[0;32m" -v red="\033[0;31m" -v reset="\033[0m" '
{
    count++
    if (count % 100 == 0 || count == total) {
        pct = (total > 0) ? (count / total) * 100 : 100
        printf "\r  ⏳ Progress: [%.1f%%] (%d / %d files) \033[K", pct, count, total
        fflush()
    }
    if ($0 ~ / FOUND$/) {
        printf "\n" red "  ⚠️  THREAT: %s" reset "\n", $0
        print $0 >> logfile
        fflush()
    }
}'

echo -e "\n"

# Results
INFECTED_COUNT=0
[ -f "$LOG_FILE" ] && INFECTED_COUNT=$(wc -l < "$LOG_FILE")

echo -e "${C}╔══════════════════════════════════╗${X}"
echo -e "${C}║          SCAN COMPLETE           ║${X}"
echo -e "${C}╚══════════════════════════════════╝${X}"
echo -e "  Files scanned : ${TOTAL_FILES}"

if [ "$INFECTED_COUNT" -gt 0 ]; then
    echo -e "  Threats found : ${R}${INFECTED_COUNT}${X}\n"
    echo -e "${R}Infected files:${X}"
    cat "$LOG_FILE"

    # Telegram alert — threats found
    TG_MSG="⚠️ SERVER: ${SERVER_NAME} (${SERVER_IP})%0A"
    TG_MSG+="🦠 ClamAV ALERT: ${INFECTED_COUNT} threat(s) found!%0A"
    TG_MSG+="📁 Scanned: ${TOTAL_FILES} files%0A"
    TG_MSG+="📋 Top threats:%0A"
    BAD_FILES=$(head -n 10 "$LOG_FILE" | sed 's/ .*//' | tr '\n' '%0A')
    TG_MSG+="${BAD_FILES}"

    if [ -n "$TG_TOKEN" ] && [ -n "$TG_CHAT_ID" ]; then
        echo -e "\n${R}[!] Sending Telegram alert...${X}"
        curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
            -d "chat_id=${TG_CHAT_ID}&text=${TG_MSG}" > /dev/null
        echo -e "${C}    Alert sent.${X}"
    else
        echo -e "${Y}[!] TG_TOKEN or TG_CHAT_ID not set — Telegram alert skipped.${X}"
    fi
else
    echo -e "  Threats found : ${C}0 (CLEAN ✅)${X}\n"

    # Telegram report — clean
    TG_MSG="✅ SERVER: ${SERVER_NAME} (${SERVER_IP})%0A"
    TG_MSG+="🛡️ ClamAV scan complete — NO threats found.%0A"
    TG_MSG+="📁 Files scanned: ${TOTAL_FILES}%0A"
    TG_MSG+="📅 $(date '+%Y-%m-%d %H:%M')"

    if [ -n "$TG_TOKEN" ] && [ -n "$TG_CHAT_ID" ]; then
        echo -e "${C}[+] Sending clean report to Telegram...${X}"
        curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
            -d "chat_id=${TG_CHAT_ID}&text=${TG_MSG}" > /dev/null
        echo -e "${C}    Report sent.${X}"
    else
        echo -e "${Y}[!] TG_TOKEN or TG_CHAT_ID not set — Telegram report skipped.${X}"
    fi
fi

echo ""
