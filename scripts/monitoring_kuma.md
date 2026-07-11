# 📊 Uptime Kuma — Monitoring Reference

> = Rooted by VladiMIR + AI | v2026.07.11 | github.com/GinCz =

---

## 🖥️ Monitoring server

| Parameter | Value |
|---|---|
| Server | VPN-EU (TATRA_9) |
| Web interface | http://[VPN-IP]:3001 |
| Timezone | Europe/Prague (CET/CEST) |
| Docker container | `uptime-kuma` (louislam/uptime-kuma:2) |
| Database | `/app/data/kuma.db` (SQLite) |
| Port | 3001 → 3001 (tcp) |

---

## 📁 Data location

```
Docker container name: uptime-kuma
Docker volume / bind:  /app/data/kuma.db  — main database
```

### Direct database access (run on the VPN server):
```bash
docker exec uptime-kuma sqlite3 /app/data/kuma.db "SELECT name FROM monitor;"
```

---

## ⚙️ Monitor settings (applied 2026-03-27)

| Parameter | Value | DB column |
|---|---|---|
| Poll interval | 90 seconds | `interval` |
| Retries before alert | 3 | `maxretries` |
| Request timeout | 48 seconds | `timeout` |
| VPN monitor timeout | 10 seconds | `timeout` |

**Alert logic:** 3 retries × 90 sec = **4.5 minutes** before notification is sent.
Cold start of PHP-FPM (ondemand) does not trigger an alert.

---

## 📊 Monitor groups

| Group | Description |
|---|---|
| Server **222** | European hosting sites, with Cloudflare |
| Server **109** | Russian sites, without Cloudflare |
| **VPN** monitors | 8 VPN nodes, timeout=10, maxretries=3 |

---

## 🛠️ SQL management

> ⚠️ Run on the **VPN server**

### View all monitors:
```bash
docker exec uptime-kuma sqlite3 /app/data/kuma.db \
  "SELECT name, maxretries, timeout, interval FROM monitor ORDER BY name;"
```

### Set maxretries=3 for all:
```bash
docker exec uptime-kuma sqlite3 /app/data/kuma.db \
  "UPDATE monitor SET maxretries=3 WHERE maxretries < 2;"
```

### Change timeout for a specific monitor:
```bash
docker exec uptime-kuma sqlite3 /app/data/kuma.db \
  "UPDATE monitor SET timeout=10 WHERE name='monitor_name';"
```

### Monitor table structure (key columns):
```
id             — monitor ID
name           — name
interval       — poll interval (seconds)
maxretries     — retries before alert (NOT max_retries!)
timeout        — request timeout (seconds, DOUBLE)
retry_interval — interval between retries
active         — 1=active, 0=paused
url            — URL for HTTP monitors
type           — type: http / ping / tcp / ...
```

---

## 💾 Kuma database backup

### Backup scheme:
- **Source:** VPN server, Docker container `uptime-kuma`
- **Destination:** Server 222, folder `/BACKUP/kuma/`
- **Schedule:** 1st of each month at 03:00 CET

Notifications are configured via `/root/.server_alliances.conf`.
Variables: `TG_TOKEN`, `TG_CHAT_ID`, `SERVER_TAG`, `PAIR_222_IP`.

### Telegram notifications:

**On success:**
```
✅ Kuma Backup OK
📦 File: kuma_2026-03-27.db
📐 Size: 1.8M
🖥️ Server: VPN-EU-Tatra-9
📤 Sent to server 222: /BACKUP/kuma
🗂️ Backups on 222: 1 (max. 3)
📅 27.03.2026 11:54 CET
```

**On docker cp error:**
```
❌ Kuma Backup FAILED
🖥️ VPN-EU-Tatra-9
⚠️ docker cp exited with error
```

**On rsync error:**
```
❌ Kuma Backup FAILED (rsync)
🖥️ VPN-EU-Tatra-9
⚠️ Failed to send to server 222
```

> Notification is sent **always** — both on success and any failure.

---

## 🔄 Restart Kuma

> ⚠️ Run on the **VPN server**

```bash
docker restart uptime-kuma
docker ps | grep kuma
docker logs uptime-kuma --tail=50
```

---

## 🌐 Server timezone

```bash
timedatectl set-timezone Europe/Prague
locale-gen en_GB.UTF-8
update-locale LC_TIME=en_GB.UTF-8
```

---

## ⚠️ Known issues

| Monitor (222) | Issue | Cause |
|---|---|---|
| sveta-drobot.cz | HTTP 500 occasionally | PHP error on the site |
| sveta-drobot.cz | timeout 48000ms (rare) | PHP ondemand cold start |
| kk-med.cz | timeout=30 (special) | Intentionally reduced |

---

*= Rooted by VladiMIR + AI | v2026.07.11 | github.com/GinCz =*
