# 🖥️ Server 222 — DE-NetCup

> **Updated:** 2026-03-30 | = Rooted by VladiMIR | AI =

## 🔧 Hardware
| Parameter | Value |
|---|---|
| **IP** | 152.53.182.222 |
| **Provider** | NetCup.com, Germany |
| **Tariff** | VPS 1000 G12 (2026) |
| **CPU** | 4 vCore AMD EPYC-Genoa |
| **RAM** | 8 GB DDR5 ECC |
| **Disk** | 256 GB NVMe |
| **OS** | Ubuntu 24 LTS |
| **Panel** | FastPanel (PHP 8.3 / 8.4) |
| **Price** | 8.60 EUR/mo |
| **Cloudflare** | YES — all sites behind Cloudflare |

## 🌐 Network & Security
- **Hostname:** `222-DE-NetCup`
- **Cloudflare:** All .eu / .cz / .uk / .com / .ru domains
- **CrowdSec:** Active (nginx bouncer + SSH)
- **AmneziaVPN:** Active (Docker container)
- **Fail2ban:** Active

## 🔗 Admin Links
| Service | URL |
|---|---|
| **FastPanel** | https://server.gincz.com:8888 |
| **Semaphore UI** | https://server.gincz.com:3000 |
| **Crypto-Bot Web** | https://server.gincz.com/303/ |
| **Netdata** | http://152.53.182.222:19999 |
| **AmneziaVPN panel** | managed via Docker CLI |

## 🐳 Docker Containers

### 1. Crypto-Bot (`crypto-bot`)
- **Location:** `/root/crypto-docker/`
- **Compose:** `/root/crypto-docker/docker-compose.yml`
- **Start:** `bash /root/crypto-docker/scripts/tr_docker.sh` → alias **`bot`**
- **Deploy:** `bash /root/crypto-docker/scripts/deploy.sh`
- **Reset:** `bash /root/crypto-docker/scripts/reset.sh`
- **Web UI:** https://server.gincz.com/303/
- **Backup:** `/BACKUP/222/docker/crypto/` (cron 03:00 daily)

| Script | Description |
|---|---|
| `tr_docker.sh` | **Main bot start** — alias `bot` (NOT `tr` — conflicts with system util!) |
| `tr.sh` | Start trading directly (no Docker wrapper) |
| `deploy.sh` | Full container redeploy |
| `reset.sh` | Reset and restart container |
| `start.sh` | Start container |
| `trade.py` | Core trading logic |
| `scanner.py` | Market scanner |
| `trades_report.py` | Full trades report |
| `tr_report.py` | Short report (updated 2026-03-25) |
| `paper_trade.py` | Paper trading (test, no real money) |
| `paper_report.py` | Paper trading report |
| `push_stats.sh` | Push statistics |
| `303-crypto.conf` | Nginx config for bot web UI |

> ⚠️ **Alias `tr` → renamed to `bot`** — `tr` is a system Linux utility (translate chars). Use `bot` only!

---

### 2. Semaphore (`semaphore`)
- **Location:** `/root/semaphore-data/`
- **Compose:** `/root/semaphore-data/docker-compose.yml`
- **Web UI:** https://server.gincz.com:3000
- **Port:** 3000 (internal) → Nginx proxy + SSL via Cloudflare
- **DB:** SQLite (inside container volume)
- **Start:** `cd /root/semaphore-data && docker compose up -d`
- **Stop:** `cd /root/semaphore-data && docker compose down`
- **Backup:** `/BACKUP/222/docker/semaphore/` (cron 03:00 daily, ~300 MB)
- **Used for:** Automated deployment tasks, server scripts via Ansible playbooks

---

### 3. AmneziaVPN (`amnezia`)
- **Location:** `/root/amnezia/` or managed via AmneziaWG
- **Protocol:** AmneziaWG (modified WireGuard)
- **Start:** `docker compose up -d` in amnezia directory
- **Backup:** `/BACKUP/222/docker/amnezia/` (cron 03:00 daily, ~13 MB)
- **Purpose:** VPN access to server and private tunnels

---

## 📅 Cron Jobs (full list)
```
# System backup + deep cleanup
0 2 * * *   /root/backup_clean.sh >> /var/log/system-backup.log 2>&1

# Docker containers backup (crypto + semaphore + amnezia)
0 3 * * *   /root/docker_backup.sh >> /var/log/docker-backup.log 2>&1

# WordPress cron (44 sites)
0 23 * * *  wp-cron.php (44 sites)

# Disk cleanup (every Sunday)
0 3 * * 0   disk_cleanup.sh
```

## 💾 Backup Strategy
| Script | Time | What | Where | Keep |
|---|---|---|---|---|
| `backup_clean.sh` | 02:00 | `/etc` + `/root` configs (< 30 MB) | `/BACKUP/222/` + remote 109 | 10 |
| `docker_backup.sh` | 03:00 | crypto + semaphore + amnezia | `/BACKUP/222/docker/` + remote 109 | 5 each |

**Restore system:**
```bash
tar -xzf BackUp_222-EU__YYYY-MM-DD_HH-MM.tar.gz -C /
```

**Current backup sizes:**
- System archives: ~130 MB each
- Semaphore: ~300 MB
- Crypto: ~100 MB
- Amnezia: ~13 MB

## 🌍 WordPress Sites (44 total)

| Domain | User | WP Cron |
|---|---|---|
| detailing-alex.eu | alex_detailing | system 23:00 |
| ru-tv.eu | gincz | system 23:00 |
| ekaterinburg-sro.eu | gincz | system 23:00 |
| eco-seo.cz | gincz | system 23:00 |
| eurasia-translog.cz | serg_et | system 23:00 |
| east-vector.cz | serg_et | system 23:00 |
| rail-east.uk | serg_et | system 23:00 |
| vymena-motoroveho-oleje.cz | serg_pimonov | system 23:00 |
| car-chip.eu | serg_pimonov | system 23:00 |
| diamond-odtah.cz | diamond-drivers | system 23:00 |
| sveta-drobot.cz | sveta_drobot | system 23:00 |
| bio-zahrada.eu | tan-adrian | system 23:00 |
| alejandrofashion.cz | alejandrofashion | system 23:00 |
| czechtoday.eu | dmitry-vary | system 23:00 |
| stm-services-group.cz | tatiana_podzolkova | system 23:00 |
| autoservis-praha.eu | arslan | system 23:00 |
| praha-autoservis.eu | bayerhoff | system 23:00 |
| neonella.eu | neonella | system 23:00 |
| megan-consult.cz | igor_kap | system 23:00 |
| abl-metal.com | igor_kap | system 23:00 |
| stopservis-vestec.cz | serg_reno | system 23:00 |
| kadernik-olga.eu | olga_pisareva | system 23:00 |
| kk-med.eu | karina | system 23:00 |
| kadernictvi-salon.eu | viktoria | system 23:00 |
| doska-hun.ru | doski | system 23:00 |
| doska-ua.ru | doski | system 23:00 |
| doska-mld.ru | doski | system 23:00 |
| doska-it.ru | doski | system 23:00 |
| doska-esp.ru | doski | system 23:00 |
| doska-cz.ru | doski | system 23:00 |
| doska-isl.ru | doski | system 23:00 |
| doska-pl.ru | doski | system 23:00 |
| doska-de.ru | doski | system 23:00 |
| doska-gr.ru | doski | system 23:00 |
| doska-fr.ru | doski | system 23:00 |
| balance-b2b.eu | sveta_tuk | system 23:00 |
| car-bus-autoservice.cz | andrey-autoservis | system 23:00 |
| autoservis-rychlik.cz | andrey-autoservis | system 23:00 |
| hulk-jobs.cz | hulk | system 23:00 |
| gadanie-tel.eu | gadanie-tel | system 23:00 |
| lybawa.com | gadanie-tel | system 23:00 |
| wowflow.cz | wowflow | system 23:00 |
| svetaform.eu | spa | system 23:00 |
| tstwist.cz | tstwist | system 23:00 |

## ⌨️ Aliases (quick commands)
```
load       — git pull (update scripts from GitHub)
save       — git add + commit + push
infooo     — full server info (RAM, CPU, disk, docker, WP)
sos        — emergency status check
fight      — CrowdSec + firewall status
domains    — list all domains with SSL status
backup     — run backup_clean.sh manually
antivir    — ClamAV scan
banlog     — show CrowdSec ban log
303        — crypto-bot web UI shortcut
bot        — start crypto-bot (alias for tr_docker.sh)
chname     — change hostname
mailclean  — clean mail queue
wphealth   — check all WP sites health
cleanup    — manual server cleanup
wpcron     — run WP cron for all 44 sites
aw         — AmneziaVPN status
audit      — security audit
aws-test   — AWS connection test
```

## 📁 Key Files & Paths
```
/root/backup_clean.sh          — system backup + cleanup (cron 02:00)
/root/docker_backup.sh         — docker backup (cron 03:00)
/root/crypto-docker/           — crypto-bot project
/root/semaphore-data/          — semaphore project
/root/Linux_Server_Public/     — GitHub repo (this repo)
/BACKUP/222/                   — local system backups
/BACKUP/222/docker/            — local docker backups
/var/log/system-backup.log     — backup_clean.sh log
/var/log/docker-backup.log     — docker_backup.sh log
```
