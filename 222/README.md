# 🐳 222-DE-NetCup — Docker Backup Script

> `= Rooted by VladiMIR | AI =`  
> Server: **222-DE-NetCup** | IP: `xxx.xxx.xxx.222` | NetCup VPS 1000 G12, Ubuntu 24, FASTPANEL  
> ⚠️ Full IP address is stored in the private `Secret_Privat` repository.

---

## 📋 Overview

`docker_backup.sh` — full backup of all Docker containers on the server in a single run.  
Saves the image + data to a `.tar.gz` archive with rotation (keeps the last N copies).  
Supports two strategies: **volumes** (image + data) and **commit** (snapshot of a running container).

---

## 🗂 File Structure

```
222/
├── docker_backup.sh    # main backup script
└── README.md           # this documentation

/BACKUP/222/docker/     # archive storage folder on the server
├── crypto/             # crypto-bot archives
│   └── crypto-bot_YYYY-MM-DD_HH-MM.tar.gz
├── semaphore/          # semaphore archives
│   └── semaphore_YYYY-MM-DD_HH-MM.tar.gz
└── amnezia/            # amnezia-awg archives
    └── amnezia-awg_YYYY-MM-DD_HH-MM.tar.gz
```

---

## 🐳 Containers

| # | Container | Strategy | Data | Image |
|---|-----------|----------|------|-------|
| 1 | `crypto-bot` | volumes | `/root/crypto-docker` | `crypto-docker_crypto-bot:latest` |
| 2 | `semaphore` | volumes | `/root/semaphore-data` | `semaphoreui/semaphore:latest` |
| 3 | `amnezia-awg` | commit | — (commit snapshot) | `amnezia-awg` |

---

## ⚙️ Backup Strategies

### 🔵 Strategy: `volumes`
For containers that **can be stopped** during archiving.

**Algorithm:**
1. 🧹 Clean up junk in `data_dir` — delete `*.log`, `*.pyc`, `*.tmp`, `*.bak`, `__pycache__`
2. 💾 Save Docker image: `docker save image | pigz → /tmp/<label>-image.tar.gz`
3. ⏸ Stop: `docker-compose stop` (only if `compose_dir` is set)
4. 📦 Create archive: `tar + pigz → /BACKUP/222/docker/<label>/<label>_DATE.tar.gz`
   - Contains: `data_dir` + `image.tar.gz`
5. ▶️ Start again: `docker-compose up -d`
6. 🗑 Rotation: delete old archives, keep the last `$KEEP` copies

**Why does semaphore weigh 296M?**  
Image `semaphoreui/semaphore:latest` = **869MB** uncompressed.  
After pigz = **296MB** (~34% of original). This is normal — Go binary + full environment.

---

### 🟣 Strategy: `commit`
For containers that **cannot be stopped** (VPN, tunnels — `amnezia-awg`).

**Algorithm:**
1. 🧹 Clean up inside the container: `docker exec ... sh -c cleanup`
   - Removes `/tmp/*` and `/var/log/*.log`, `*.gz`
2. 📸 Snapshot: `docker commit <container> <label>-backup:DATE` → returns `commit_id`
3. 📦 Archive snapshot: `docker save <snapshot> | pigz → /BACKUP/222/docker/<label>/<label>_DATE.tar.gz`
4. 🗑 Remove temporary snapshot: `docker rmi <label>-backup:DATE`
5. 🗑 Rotate old archives

---

## 🚀 Installation and Usage

### Initial Installation

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
cd /root
git clone https://github.com/GinCz/Linux_Server_Public.git
cp Linux_Server_Public/222/docker_backup.sh /root/docker_backup.sh
chmod +x /root/docker_backup.sh
```

### Update the script

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
cd /root/Linux_Server_Public && git pull --rebase && \
cp 222/docker_backup.sh /root/docker_backup.sh && \
chmod +x /root/docker_backup.sh && echo "✅ OK"
```

### Manual run

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
/root/docker_backup.sh
```

### Automated run (cron)

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
crontab -e
# Add line (example — every night at 03:00):
# 0 3 * * * /root/docker_backup.sh >> /var/log/docker_backup.log 2>&1
```

---

## ⚙️ Configuration

All settings are at the top of the script:

```bash
TOKEN=""              # Telegram Bot Token (leave empty to disable notifications)
CHAT_ID=""            # Telegram Chat ID
BACKUP_ROOT="/BACKUP/222/docker"  # archive storage root
KEEP=3                # how many archives to keep per container
SERVER_LABEL="222-DE-NetCup"      # server label in output
```

> ⚠️ TOKEN and CHAT_ID must be stored in the private `Secret_Privat` repository — never commit them here.

### How to add a new container

Copy the config block, increment the number, choose a strategy and add the call to `MAIN`:

📋 **INFO ONLY — example config block**
```bash
# New container example (strategy: volumes)
CONTAINER_4_LABEL="my-app"
CONTAINER_4_STRATEGY="volumes"
CONTAINER_4_COMPOSE_DIR="/root/my-app"   # path to docker-compose (or "" if none)
CONTAINER_4_DATA_DIR="/root/my-app/data" # data folder to archive
CONTAINER_4_IMAGE="my-app"               # part of image name (grep -i)
CONTAINER_4_CLEANUP="
    find /root/my-app -name '*.log' -delete 2>/dev/null;
"
```

In the `MAIN` section:
```bash
print_header "4" "$CONTAINER_4_LABEL" "$CONTAINER_4_STRATEGY"
backup_volumes \
    "$CONTAINER_4_LABEL" "$CONTAINER_4_IMAGE" \
    "$CONTAINER_4_COMPOSE_DIR" "$CONTAINER_4_DATA_DIR" \
    "$CONTAINER_4_CLEANUP" "${BACKUP_ROOT}/my-app"
```

> Don't forget to update `TOTAL_CONTAINERS=4`

---

## 📤 Telegram Notifications

At the end of the script an summary report is sent to Telegram:

- ✅ on success: list of archives + total size + time
- ⚠️ on errors: error count + list of failed containers

To enable — fill in `TOKEN` and `CHAT_ID` in the config (store them in `Secret_Privat`).  
To get `CHAT_ID`: message the bot [@userinfobot](https://t.me/userinfobot).

---

## 🔧 Dependencies

| Tool | Purpose | Auto-install |
|------|---------|--------------|
| `pigz` | parallel compression (faster than gzip) | ✅ yes, if not found |
| `docker` | container management | ❌ must be pre-installed |
| `docker-compose` | start/stop stack | ❌ required for volumes strategy only |
| `tar` | archiving | ✅ present in Ubuntu |
| `bc` | MB/s speed calculation | ✅ present in Ubuntu |
| `curl` | Telegram API | ✅ present in Ubuntu |

---

## 📊 Sample Output

```
══════════════════════════════════════════════════════════════════════════════
  = Rooted by VladiMIR | AI =   🐳 DOCKER BACKUP   222-DE-NetCup
  📅 2026-04-08 22:56:00   compression: pigz ⚡
  🖥️  Hostname: 222-DE-NetCup   IP: xxx.xxx.xxx.222
  💿 Disk free: 196G   Load: 0.38, 0.90, 1.23
  📦 Containers: 3   Keep: 3   Root: /BACKUP/222/docker
══════════════════════════════════════════════════════════════════════════════
  [1/3] crypto-bot   strategy: volumes
22:56:00   🧹 crypto-bot cleanup...  data: 2.1M
22:56:00   💾 crypto-bot saving image...
22:56:00      └─ crypto-docker_crypto-bot:latest (267MB)
22:56:16   📦 crypto-bot archiving (pigz ⚡)...
22:56:17 ✅ crypto-bot: crypto-bot_2026-04-08_22-56.tar.gz
     ├─ Size   : 98M
     ├─ Time   : 1s  @ 97.7 MB/s
     └─ Status : OK ✓
     📂 Archives: 3/3 kept
══════════════════════════════════════════════════════════════════════════════
  ✅  ALL DONE — NO ERRORS
  ├─ Total size  : 1.2G
  ├─ Total time  : 40s
  ├─ Errors      : 0
  └─ Finished at : 2026-04-08 22:56:40
══════════════════════════════════════════════════════════════════════════════
```

---

## 🗄 Restore from Archive

### Restore image

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
# Extract archive
tar -xzf /BACKUP/222/docker/crypto/crypto-bot_2026-04-08_22-56.tar.gz -C /tmp/restore/

# Load image back into Docker
docker load < /tmp/restore/tmp/crypto-bot-image.tar.gz

# Verify
docker images | grep crypto
```

### Restore data

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
# Data is stored in the archive at the original path
# Example: restore /root/crypto-docker from archive
tar -xzf /BACKUP/222/docker/crypto/crypto-bot_2026-04-08_22-56.tar.gz \
    -C /root/crypto-docker --strip-components=1
```

---

## 📜 Changelog

| Version | Date | Changes |
|---------|------|---------|
| v2026-04-12 | 2026-04-12 | Translated README to English; masked IP to xxx.xxx.xxx.222 |
| v2026-04-08d | 2026-04-08 | `= Rooted by VladiMIR | AI =` in first line of header |
| v2026-04-08c | 2026-04-08 | Removed progress bar; compact output |
| v2026-04-08b | 2026-04-08 | Live progress bar; removed static star_progress |
| v2026-04-08 | 2026-04-08 | Initial version: spinner, colour output, two strategies, Telegram, rotation |

---

*= Rooted by VladiMIR | AI =*
