# ClamAV Antivirus — Auto-Install, Update & Background Scan with Telegram Alerts

**Script:** `scripts/scan_clamav.sh`
**Version:** `v2026-03-19`
**Alias:** `antivir`
**Author:** Ing. VladiMIR Bulantsev

---

## Overview

This script provides a fully automated ClamAV antivirus workflow for Ubuntu 24 servers.
It is designed for web hosting environments with multiple WordPress sites.

**Key features:**
- Auto-installs ClamAV if not present
- Updates virus databases before every scan
- Counts files before scanning so you see the scope
- Runs the scan **in the background** using `nohup` — you can safely close SSH
- Sends **Telegram notification** at scan start and on completion
- **Read-only mode** — never deletes or modifies files, only reports threats
- Logs results to `/var/log/clamav_scan_HOSTNAME_DATE.log`

---

## How It Works

```
antivir
  │
  ├─ 1. Check if ClamAV is installed → if not, run: apt install clamav clamav-daemon
  │
  ├─ 2. Update virus databases → freshclam (stops/starts clamav-freshclam service)
  │
  ├─ 3. Count files in /var/www → shows total before scan
  │
  ├─ 4. Send Telegram START message:
  │      🔍 ClamAV scan started
  │      🖥 Server: 222-DE-NetCup
  │      📁 Files: 668913
  │      ⏰ Started: 2026-03-19 17:21
  │      You can close SSH — report will arrive on completion.
  │
  ├─ 5. Launch scan with nohup in background (safe low-priority: nice -n 19 ionice -c 3)
  │      → SSH session can be closed now
  │
  └─ 6. On completion → Send Telegram DONE message:
         ✅ ClamAV scan DONE
         🖥 Server: 222-DE-NetCup
         📁 Scanned: 668913 files
         🦠 Result: Clean — no threats found
         ⏱ Time: 18 min
         📄 Log: /var/log/clamav_scan_222-DE-NetCup_2026-03-19_17-21.log
```

---

## Telegram Configuration

The script reads Telegram credentials from a config file.
**Never store tokens in public repositories.**

Create the config file on each server:

```bash
# For root servers (222-DE-NetCup, 109-RU-FastVDS)
cat > /etc/server_alerts.conf << 'EOF'
TG_TOKEN="YOUR_BOT_TOKEN"
TG_CHAT="YOUR_CHAT_ID"
EOF
chmod 600 /etc/server_alerts.conf
```

```bash
# For non-root servers (e.g. AWS ubuntu user)
cat > ~/.server_alerts.conf << 'EOF'
TG_TOKEN="YOUR_BOT_TOKEN"
TG_CHAT="YOUR_CHAT_ID"
EOF
chmod 600 ~/.server_alerts.conf

# Load automatically on login
echo 'source ~/.server_alerts.conf' >> ~/.bashrc
```

Test Telegram connection:

```bash
source /etc/server_alerts.conf
curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
  -d chat_id="$TG_CHAT" \
  -d text="✅ Test from $(hostname) — Telegram works!"
```

---

## Installation

```bash
# Pull latest scripts from repo
cd /opt/server_tools && git pull

# Add alias (once per server)
echo "alias antivir='bash /opt/server_tools/scripts/scan_clamav.sh'" \
  >> /opt/server_tools/shared_aliases.sh

# Reload aliases
source /opt/server_tools/shared_aliases.sh
```

---

## Usage

```bash
# Run antivirus (install + update + scan + Telegram)
antivir

# Or directly
bash /opt/server_tools/scripts/scan_clamav.sh

# Monitor scan progress in real time
tail -f /var/log/clamav_scan_$(hostname)_*.log

# View last scan results
ls -lt /var/log/clamav_scan_*.log | head -5
```

---

## Midnight Commander F2 Menu

Add to `~/.mc/menu`:

```
A   ClamAV: Run Antivirus Scan (background + Telegram)
    bash /opt/server_tools/scripts/scan_clamav.sh
```

---

## Script Source

```bash
#!/usr/bin/env bash
# Script:  scan_clamav.sh
# Version: v2026-03-19
# Alias:   antivir
# Purpose: Install (if missing), update and run ClamAV deep scan in background.
#          Sends Telegram notification on completion.
#          Safe: read-only, never deletes or modifies files.

clear

# Colors for terminal output
C='\033[0;32m'   # Green
R='\033[0;31m'   # Red
Y='\033[1;33m'   # Yellow
X='\033[0m'      # Reset

HOST=$(hostname)
DATE=$(date +%Y-%m-%d_%H-%M)
LOG="/var/log/clamav_scan_${HOST}_${DATE}.log"

# ── Load Telegram credentials ─────────────────────────────────────────────────
# Looks for config in /etc/server_alerts.conf (root servers)
# or ~/.server_alerts.conf (non-root, e.g. AWS ubuntu user)
for CONF in /etc/server_alerts.conf ~/.server_alerts.conf; do
    [ -f "$CONF" ] && source "$CONF" && break
done

# ── Telegram send function ────────────────────────────────────────────────────
tg_send() {
    [ -z "${TG_TOKEN:-}" ] && return
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d chat_id="${TG_CHAT}" \
        -d parse_mode="HTML" \
        -d text="$1" > /dev/null
}

echo -e "${Y}========================================${X}"
echo -e "${Y} ClamAV Antivirus | ${HOST} | ${DATE}${X}"
echo -e "${Y}========================================${X}"

# ── Step 1: Auto-install ClamAV if missing ────────────────────────────────────
if ! command -v clamscan &>/dev/null; then
    echo -e "${Y}1. ClamAV not found — installing...${X}"
    apt-get update -qq && apt-get install -y clamav clamav-daemon -qq
    echo -e "${C}   Done!${X}"
else
    echo -e "${C}1. ClamAV is already installed.${X}"
fi

# ── Step 2: Update virus databases ───────────────────────────────────────────
echo -e "${Y}2. Updating virus databases...${X}"
systemctl stop clamav-freshclam 2>/dev/null
freshclam --quiet 2>/dev/null
systemctl start clamav-freshclam 2>/dev/null
echo -e "${C}   Done!${X}"

# ── Step 3: Count files to be scanned ────────────────────────────────────────
echo -n "3. Counting files in /var/www ... "
TOTAL=$(find /var/www -type f 2>/dev/null | wc -l)
echo -e "${C}Found ${TOTAL} files.${X}"

# ── Step 4: Notify Telegram — scan starting ───────────────────────────────────
tg_send "🔍 <b>ClamAV scan started</b>
🖥 Server: <b>${HOST}</b>
📁 Files: <b>${TOTAL}</b>
⏰ Started: $(date '+%Y-%m-%d %H:%M')

<i>You can close SSH — report will be sent on completion.</i>"

# ── Step 5: Launch background scan with nohup ────────────────────────────────
# nice -n 19     → lowest CPU priority (does not affect websites)
# ionice -c 3    → idle I/O class (yields to all other disk activity)
# --infected     → log only infected files (clean output)
echo -e "${Y}4. Starting deep scan in background...${X}"
echo -e "${C}   You can close SSH now — Telegram will notify you when done.${X}"
echo -e "   Log: ${LOG}"
echo ""

nohup bash -c "
    START=\$(date +%s)
    echo '=== ClamAV Scan | ${HOST} | $(date) ===' > '${LOG}'

    nice -n 19 ionice -c 3 clamscan -r /var/www \\
        --log='${LOG}' \\
        --infected \\
        --exclude-dir='^/var/www/.*/data/tmp' \\
        --exclude-dir='^/var/www/.*/data/cache' \\
        2>/dev/null

    END=\$(date +%s)
    ELAPSED=\$(( (END - START) / 60 ))

    # Count FOUND entries in log
    INFECTED=\$(grep -c 'FOUND' '${LOG}' 2>/dev/null || echo 0)

    if [ \"\$INFECTED\" = '0' ]; then
        ICON='✅'
        STATUS='Clean — no threats found'
    else
        ICON='🚨'
        STATUS=\"INFECTED: \$INFECTED file(s) — check log!\"
    fi

    # Send completion report to Telegram
    curl -s -X POST 'https://api.telegram.org/bot${TG_TOKEN}/sendMessage' \\
        -d chat_id='${TG_CHAT}' \\
        -d parse_mode='HTML' \\
        -d text=\"\${ICON} <b>ClamAV scan DONE</b>
🖥 Server: <b>${HOST}</b>
📁 Scanned: <b>${TOTAL} files</b>
🦠 Result: <b>\${STATUS}</b>
⏱ Time: <b>\${ELAPSED} min</b>
📄 Log: ${LOG}\" > /dev/null
" >> "${LOG}" 2>&1 &

SCAN_PID=$!
echo -e "${C}✅ Scan running in background (PID: ${SCAN_PID})${X}"
echo -e "${C}📱 Telegram notification: @My_WWW_bot${X}"
echo -e "   Monitor: tail -f ${LOG}"
```

---

## Servers

| Server | IP | Location | Config file |
|---|---|---|---|
| 222-DE-NetCup | 152.53.182.222 | Germany | `/etc/server_alerts.conf` |
| 109-RU-FastVDS | 212.109.223.109 | Russia | `/etc/server_alerts.conf` |
| aws-crypto-bot | AWS | Cloud | `~/.server_alerts.conf` |

---

## Notes

- Telegram token and chat ID are stored in **private repository only** — never in this public repo
- Scan does not interfere with live websites due to `nice` and `ionice` settings
- Scan directory: `/var/www` (all hosted sites)
- Excluded: `data/tmp` and `data/cache` directories (no real files, just temp/cache)
- Log retention: manual — use `disk_cleanup.sh` to rotate old logs
