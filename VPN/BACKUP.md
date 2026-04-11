# 🔒 VPN Docker Backup — Full Documentation

> **= Rooted by VladiMIR | AI =**  
> Script: [`vpn_docker_backup.sh`](vpn_docker_backup.sh)  
> Version: **v2026-04-11**  
> Server: **222-DE-NetCup** · `152.53.182.222` · Ubuntu 24 / FASTPANEL

---

## 📋 What does the script do?

1. Connects to each of the **8 VPN nodes** via SSH (key-based, no password)
2. Checks that the `amnezia-awg` Docker container is running
3. Cleans temporary files inside the container (`/tmp`, `/var/log/*.log`)
4. Runs `docker commit` — saves the current state of the container to an image
5. Archives the image remotely (`docker save | gzip` or `pigz` if available)
6. Downloads the archive via SCP to `/BACKUP/vpn/<node-name>/`
7. Rotates old archives — keeps only the last **7** copies per node
8. Prints a detailed report with sizes, speeds, and timestamps
9. Sends a Telegram notification (optional, configure token)

---

## ⚙️ Configuration

```bash
# In vpn_docker_backup.sh:
SSH_KEY="/root/.ssh/id_ed25519"   # SSH key for all nodes
SSH_PORT=22                        # Default port (can override per node)
SSH_USER="root"
LOCAL_BACKUP_ROOT="/BACKUP/vpn"   # Where archives are stored on 222
KEEP=7                             # Keep last 7 archives per node
CONTAINER="amnezia-awg"           # Docker container name on each node
TELEGRAM_TOKEN=""                  # Optional: Telegram bot token
TELEGRAM_CHAT_ID=""               # Optional: Telegram chat ID
```

> ⚠️ **Note:** The script currently has `KEEP=3` in code. Change to `KEEP=7` before the next automated run:
> ```bash
> sed -i 's/^KEEP=3$/KEEP=7/' /root/vpn_docker_backup.sh && grep KEEP /root/vpn_docker_backup.sh
> ```

---

## 🔐 SSH Key Setup

Done once per new node. Key is already deployed to all 8 current nodes.

```bash
# Generate key (if not exists)
ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519

# Copy to new node
ssh-copy-id -i /root/.ssh/id_ed25519 root@<node-ip>

# Verify (must print OK without password)
ssh -i /root/.ssh/id_ed25519 -o BatchMode=yes root@<node-ip> "echo OK"
```

**Result on 2026-04-10 for node SO_38 (.38):**
```
root@222-DE-NetCup:~# ssh-copy-id -i /root/.ssh/id_ed25519 root@xxx.xxx.xxx.38
Number of key(s) added: 1

root@222-DE-NetCup:~# ssh -i /root/.ssh/id_ed25519 -o BatchMode=yes root@xxx.xxx.xxx.38 "echo OK"
OK
```

---

## 🗓 Cron Schedule

Backup runs **automatically** on server **222-DE-NetCup** — **twice a week**:

| Day | Time | Task |
|---|---|---|
| Wednesday | **03:30** | `vpn_docker_backup.sh` |
| Saturday | **03:30** | `vpn_docker_backup.sh` |

```bash
# Current full crontab on server 222:
*/15 * * * *   bash /opt/server_tools/scripts/php_fpm_watchdog.sh
@reboot        sleep 60 && bash /root/Linux_Server_Public/scripts/fastpanel_php_ondemand_v2026-03-25.sh >> /var/log/php_ondemand.log 2>&1
0 2  * * *     /root/backup_clean.sh         >> /var/log/system-backup.log 2>&1
0 3  * * *     /root/docker_backup.sh        >> /var/log/docker-backup.log 2>&1
0 2  * * 3,6   bash /root/wp_update_all.sh   >> /var/log/wp_update.log 2>&1
* * * * *      cscli decisions list -o raw 2>/dev/null | awk -F',' '/ban/{c++} END{print c+0}' > /tmp/cs_banned_count
30 3 * * 3,6   bash /root/vpn_docker_backup.sh >> /var/log/vpn_backup.log 2>&1
```

> ⚠️ **No conflict**: `docker_backup.sh` runs at 03:00 every day.  
> VPN backup starts at **03:30** — after docker_backup finishes.

### Add/update the cron entry (one command):

```bash
crontab -l | grep -v 'vpn_docker_backup' | \
  { cat; echo "30 3 * * 3,6  bash /root/vpn_docker_backup.sh >> /var/log/vpn_backup.log 2>&1"; } \
  | crontab - && echo "✔ Done" && crontab -l
```

---

## 💾 Archive Structure on Server 222

All archives are stored on **server 222** at `/BACKUP/vpn/`, one subfolder per VPN node.

### Real directory structure example:

```
/BACKUP/vpn/
├── ALEX_47/
│   ├── amnezia-awg_2026-04-05_03-30.tar.gz   (13M)
│   ├── amnezia-awg_2026-04-08_03-30.tar.gz   (13M)
│   └── amnezia-awg_2026-04-10_12-19.tar.gz   (13M)  ← latest
├── TATRA_9/
│   ├── amnezia-awg_2026-04-05_03-30.tar.gz   (13M)
│   ├── amnezia-awg_2026-04-08_03-30.tar.gz   (13M)
│   └── amnezia-awg_2026-04-10_12-19.tar.gz   (13M)  ← latest
├── 4TON_237/
│   ├── amnezia-awg_2026-04-05_03-30.tar.gz   (13M)
│   ├── amnezia-awg_2026-04-08_03-30.tar.gz   (13M)
│   └── amnezia-awg_2026-04-10_12-19.tar.gz   (13M)  ← latest
├── SHAHIN_227/
├── STOLB_24/
├── PILIK_178/
├── ILYA_176/
└── SO_38/
```

### Filename format:
```
amnezia-awg_YYYY-MM-DD_HH-MM.tar.gz
              │          └─ time of backup start
              └─ date of backup
```

### Check what's saved right now on server 222:
```bash
# List all archives with sizes
ls -lh /BACKUP/vpn/TATRA_9/
ls -lh /BACKUP/vpn/ALEX_47/

# Check all nodes at once
for d in /BACKUP/vpn/*/; do
  echo "=== $d ==="
  ls -lh "$d"*.tar.gz 2>/dev/null || echo "  (empty)"
done

# Total size
du -sh /BACKUP/vpn/
```

---

## 💾 Archive Rotation

| Parameter | Value |
|---|---|
| Archives per node | **7** (last 7 runs) |
| Frequency | 2× per week (Wed + Sat) |
| History depth | **~3.5 weeks** per node |
| Archive size | ~13 MB each |
| Total storage | 8 nodes × 7 × 13MB ≈ **~730 MB** |
| Location | `/BACKUP/vpn/<node-name>/` |
| Log | `/var/log/vpn_backup.log` |

---

## 📊 Real Run Results — 2026-04-10

```
═══════════════════════════════════════════════════════════════════════════════
  🛡  VPN BACKUP  ·  222-DE-NetCup  ·  152.53.182.222
  📅 2026-04-10  12:19:11   💿 196G free   📊 load: 0.34, 0.44, 0.58
  🌐 8 VPN servers   🔄 keep: 7   📂 /BACKUP/vpn
═══════════════════════════════════════════════════════════════════════════════
```

| # | Node | Size | Speed | Time | Status |
|---|---|---|---|---|---|
| 1 | ALEX_47 | 13M | 46.6 MB/s | 3s | ✔ OK |
| 2 | 4TON_237 | 13M | 54.1 MB/s | 3s | ✔ OK |
| 3 | TATRA_9 | 13M | 50.2 MB/s | 3s | ✔ OK |
| 4 | SHAHIN_227 | 13M | 53.7 MB/s | 3s | ✔ OK |
| 5 | STOLB_24 | 13M | 65.5 MB/s | 3s | ✔ OK |
| 6 | PILIK_178 | 13M | 3.0 MB/s | 4s | ✔ OK |
| 7 | ILYA_176 | 13M | 58.5 MB/s | 3s | ✔ OK |
| 8 | SO_38 | 13M | 62.8 MB/s | 4s | ✔ OK |

```
  ✔  ALL DONE — NO ERRORS
  ├─ Servers OK  : 8/8
  ├─ Total size  : 227M
  ├─ Total time  : 53s
  ├─ Errors      : 0
  └─ Finished at : 2026-04-10 12:20:04
```

> **Note:** PILIK_178 (`.178`) has lower download speed (3.0 MB/s vs 50-65 MB/s on others).  
> May indicate network limitation on that node's provider. Monitor in future runs.

---

## 🚀 Manual Run

```bash
# Full run with output to console
bash /root/vpn_docker_backup.sh

# Via alias
f5vpn

# Run with log
bash /root/vpn_docker_backup.sh >> /var/log/vpn_backup.log 2>&1

# Watch the log
tail -f /var/log/vpn_backup.log

# Check archives for one node (example)
ls -lh /BACKUP/vpn/SO_38/

# Check all nodes archive count
for d in /BACKUP/vpn/*/; do echo "$(ls $d*.tar.gz 2>/dev/null | wc -l) archives — $d"; done
```

---

## 🔄 Restore from Backup

### Step-by-step: restore TATRA_9 from backup dated 2026-04-10

```bash
# === ON SERVER 222 ===

# 1. Check available archives for TATRA_9
ls -lh /BACKUP/vpn/TATRA_9/
# Output example:
# -rw-r--r-- 1 root root 13M Apr  5 03:31 amnezia-awg_2026-04-05_03-30.tar.gz
# -rw-r--r-- 1 root root 13M Apr  8 03:31 amnezia-awg_2026-04-08_03-30.tar.gz
# -rw-r--r-- 1 root root 13M Apr 10 12:19 amnezia-awg_2026-04-10_12-19.tar.gz  ← latest

# 2. Copy chosen archive to the target node
scp /BACKUP/vpn/TATRA_9/amnezia-awg_2026-04-10_12-19.tar.gz \
    root@144.124.232.9:/tmp/

# === ON TARGET NODE (TATRA_9 = 144.124.232.9) ===
ssh root@144.124.232.9

# 3. Stop current container
docker stop amnezia-awg

# 4. Load image from archive
docker load < /tmp/amnezia-awg_2026-04-10_12-19.tar.gz
# Output: Loaded image: amnezia-awg:latest

# 5. Start container
docker start amnezia-awg

# 6. Verify everything works
docker ps | grep amnezia
docker exec amnezia-awg awg show awg0 | grep -c "^peer"

# 7. Cleanup
rm /tmp/amnezia-awg_2026-04-10_12-19.tar.gz
```

### Another example: restore ALEX_47 from one week ago

```bash
# ON SERVER 222:
scp /BACKUP/vpn/ALEX_47/amnezia-awg_2026-04-05_03-30.tar.gz \
    root@109.234.38.47:/tmp/

# ON NODE ALEX_47:
ssh root@109.234.38.47
docker stop amnezia-awg
docker load < /tmp/amnezia-awg_2026-04-05_03-30.tar.gz
docker start amnezia-awg
docker ps | grep amnezia
```

### Another example: restore SO_38 (latest)

```bash
# ON SERVER 222:
LATEST=$(ls -t /BACKUP/vpn/SO_38/*.tar.gz | head -1)
echo "Restoring: $LATEST"
scp "$LATEST" root@144.124.233.38:/tmp/restore.tar.gz

# ON NODE SO_38:
ssh root@144.124.233.38
docker stop amnezia-awg
docker load < /tmp/restore.tar.gz
docker start amnezia-awg
docker exec amnezia-awg awg show awg0 | grep -c "^peer"
rm /tmp/restore.tar.gz
```

---

## 📝 Changelog

| Date | Version | Change |
|---|---|---|
| 2026-04-10 | v2026-04-10 | Initial script, 8 nodes, first manual run OK (8/8) |
| 2026-04-10 | v2026-04-10b | KEEP=7 confirmed, cron 2×/week Wed+Sat 03:30, BACKUP.md created |
| 2026-04-11 | v2026-04-11 | Added real path examples, full restore guide with 3 node examples |

---

*= Rooted by VladiMIR | AI =*
