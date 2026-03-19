# ClamAV Antivirus — Auto-Install, Update & Background Scan with Telegram Alerts

**Script:** `scripts/scan_clamav.sh`  
**Version:** `v2026-03-19b`  
**Aliases:** `antivir` · `antivir-stop` · `antivir-status`  
**Author:** Ing. VladiMIR Bulantsev  

---

## Overview

Fully automated ClamAV antivirus workflow for Ubuntu 24 servers with multiple WordPress sites.

**Key features:**
- Auto-installs ClamAV if not present
- Updates virus databases before every scan
- Detects if scan is **already running** — prevents double-start
- Runs scan **in the background** via `nohup` — close SSH any time
- **Stop any running scan** with `antivir-stop`
- Sends **Telegram notification** at scan start and on completion
- **Read-only** — never deletes or modifies files, only reports threats
- Saves PID to `/var/run/clamav_scan.pid` for reliable stop
- Logs to `/var/log/clamav_scan_HOSTNAME_DATE.log`

---

## Aliases

| Alias | Action |
|---|---|
| `antivir` | Start scan (blocks if already running) |
| `antivir-stop` | Kill all running scans + Telegram notification |
| `antivir-status` | Check if scan is running, show PID and last log |

---

## How It Works

```
antivir
  │
  ├─ Check if already running → show warning + exit (use --force to override)
  │
  ├─ 1. Install ClamAV if missing → apt install clamav clamav-daemon
  │
  ├─ 2. Update virus databases → freshclam
  │
  ├─ 3. Count files in /var/www
  │
  ├─ 4. Telegram START message:
  │      🔍 ClamAV scan started
  │      🖥 Server: 222-DE-NetCup
  │      📁 Files: 668913
  │      ⏰ Started: 2026-03-19 17:21
  │      You can close SSH — report will arrive on completion.
  │
  ├─ 5. nohup → background scan (nice -n 19, ionice -c 3)
  │      PID saved to /var/run/clamav_scan.pid
  │      ↳ SSH session can be closed now
  │
  └─ 6. On completion → Telegram DONE:
         ✅ ClamAV scan DONE
         🖥 Server: 222-DE-NetCup
         📁 Scanned: 668913 files
         🦠 Result: Clean — no threats found
         ⏱ Time: 18 min
         📄 Log: /var/log/clamav_scan_...

antivir-stop
  │
  ├─ Read PID from /var/run/clamav_scan.pid
  ├─ Kill all clamscan processes (handles double-start)
  └─ Telegram: 🛑 ClamAV scan STOPPED
```

---

## Telegram Configuration

**Never store tokens in public repositories.**

```bash
# Root servers (222-DE-NetCup, 109-RU-FastVDS)
cat > /etc/server_alerts.conf << 'EOF'
TG_TOKEN="YOUR_BOT_TOKEN"
TG_CHAT="YOUR_CHAT_ID"
EOF
chmod 600 /etc/server_alerts.conf
```

```bash
# Non-root servers (AWS ubuntu user)
cat > ~/.server_alerts.conf << 'EOF'
TG_TOKEN="YOUR_BOT_TOKEN"
TG_CHAT="YOUR_CHAT_ID"
EOF
chmod 600 ~/.server_alerts.conf
echo 'source ~/.server_alerts.conf' >> ~/.bashrc
```

Test:
```bash
source /etc/server_alerts.conf
curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
  -d chat_id="$TG_CHAT" \
  -d text="✅ Test from $(hostname) — Telegram works!"
```

---

## Installation

### Servers 222 and 109 (root)

```bash
# Update scripts from repo
cd /opt/server_tools && git pull

# Add aliases (once)
grep -q 'antivir' /opt/server_tools/shared_aliases.sh || cat >> /opt/server_tools/shared_aliases.sh << 'EOF'
alias antivir='bash /opt/server_tools/scripts/scan_clamav.sh'
alias antivir-stop='bash /opt/server_tools/scripts/scan_clamav.sh --stop'
alias antivir-status='bash /opt/server_tools/scripts/scan_clamav.sh --status'
EOF

source /opt/server_tools/shared_aliases.sh
```

### AWS Server (ubuntu)

```bash
# Clone repo
git clone https://github.com/GinCz/Linux_Server_Public.git ~/server_tools

# Add aliases to bashrc
cat >> ~/.bashrc << 'EOF'
alias antivir='bash ~/server_tools/scripts/scan_clamav.sh'
alias antivir-stop='bash ~/server_tools/scripts/scan_clamav.sh --stop'
alias antivir-status='bash ~/server_tools/scripts/scan_clamav.sh --status'
EOF

source ~/.bashrc
```

---

## Usage

```bash
# Start scan (auto-installs, updates DB, background, Telegram)
antivir

# Check if scan is running
antivir-status

# Stop all running scans + Telegram notification
antivir-stop

# Force new scan even if one is already running
bash /opt/server_tools/scripts/scan_clamav.sh --force

# Monitor scan progress
tail -f /var/log/clamav_scan_$(hostname)_*.log

# View last scan log
ls -lt /var/log/clamav_scan_*.log | head -3
```

---

## Midnight Commander F2 Menu

Add to `~/.mc/menu`:

```
A   ClamAV: Start Antivirus Scan (background + Telegram)
    bash /opt/server_tools/scripts/scan_clamav.sh
B   ClamAV: Stop Running Scan
    bash /opt/server_tools/scripts/scan_clamav.sh --stop
C   ClamAV: Check Scan Status
    bash /opt/server_tools/scripts/scan_clamav.sh --status
```

---

## Servers

| Server | IP | User | Config file | Repo path |
|---|---|---|---|---|
| 222-DE-NetCup | 152.53.182.222 | root | `/etc/server_alerts.conf` | `/opt/server_tools` |
| 109-RU-FastVDS | 212.109.223.109 | root | `/etc/server_alerts.conf` | `/opt/server_tools` |
| aws-crypto-bot | AWS | ubuntu | `~/.server_alerts.conf` | `~/server_tools` |

---

## Notes

- Telegram token and chat ID are stored in **private repository only**
- Scan uses `nice -n 19` + `ionice -c 3` → lowest possible priority, websites unaffected
- Scan directory: `/var/www` (all hosted sites)
- Excluded: `data/tmp` and `data/cache` (temp/cache only, no real files)
- PID file: `/var/run/clamav_scan.pid` — used for reliable stop
- Log retention: manual — use `disk_cleanup.sh` to rotate old logs
