# 🔒 VPN Docker Backup — Full Documentation

> **= Rooted by VladiMIR | AI =**  
> Script: [`vpn_docker_backup.sh`](vpn_docker_backup.sh)  
> Version: **v2026-04-10**  
> Server: **222-DE-NetCup** · `152.53.182.xxx` · Ubuntu 24 / FASTPANEL

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
  🛡  VPN BACKUP  ·  222-DE-NetCup  ·  152.53.182.xxx
  📅 2026-04-10  12:19:11   💿 196G free   📊 load: 0.34, 0.44, 0.58
  🌐 8 VPN servers   🔄 keep: 7   📂 /BACKUP/vpn
═══════════════════════════════════════════════════════════════════════════════
```

| # | Node | IP (masked) | Size | Speed | Time | Status |
|---|---|---|---|---|---|---|
| 1 | ALEX_47 | `xxx.xxx.xx.47` | 13M | 46.6 MB/s | 3s | ✔ OK |
| 2 | 4TON_237 | `xxx.xxx.xxx.237` | 13M | 54.1 MB/s | 3s | ✔ OK |
| 3 | TATRA_9 | `xxx.xxx.xxx.9` | 13M | 50.2 MB/s | 3s | ✔ OK |
| 4 | SHAHIN_227 | `xxx.xxx.xxx.227` | 13M | 53.7 MB/s | 3s | ✔ OK |
| 5 | STOLB_24 | `xxx.xxx.xxx.24` | 13M | 65.5 MB/s | 3s | ✔ OK |
| 6 | PILIK_178 | `xx.xx.xxx.178` | 13M | 3.0 MB/s | 4s | ✔ OK |
| 7 | ILYA_176 | `xxx.xxx.xxx.176` | 13M | 58.5 MB/s | 3s | ✔ OK |
| 8 | SO_38 | `xxx.xxx.xxx.38` | 13M | 62.8 MB/s | 4s | ✔ OK |

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

```bash
# On server 222 — copy archive to target node
scp /BACKUP/vpn/SO_38/amnezia-awg_2026-04-10_12-19.tar.gz root@<node-ip>:/tmp/

# On target node — restore
ssh root@<node-ip>
  docker stop amnezia-awg
  docker load < /tmp/amnezia-awg_2026-04-10_12-19.tar.gz
  docker start amnezia-awg
  docker ps | grep amnezia
```

---

## 📝 Changelog

| Date | Version | Change |
|---|---|---|
| 2026-04-10 | v2026-04-10 | Initial script, 8 nodes, KEEP=3, manual run |
| 2026-04-10 | v2026-04-10b | KEEP=7, cron 2×/week Wed+Sat 03:30, conflict fix |

---

*= Rooted by VladiMIR | AI =*
