# 📋 CHANGELOG — Linux_Server_Public

All notable changes to this repository are documented here.  
Format: `YYYY-MM-DD | [server] | description`

---

## 2026-04-10 | VPN + ALL | Full documentation pass + backup system launch

### What was done:

#### 🔐 SSH Key Setup (VPN nodes)
- Generated `ed25519` SSH key pair for VPN node access from server 222
- Added public key to all VPN nodes `~/.ssh/authorized_keys`
- Tested passwordless SSH from 222 → all VPN nodes ✅

#### 💾 VPN Docker Backup System (`vpn_docker_backup.sh`)
- **First successful run:** 2026-04-10 at ~13:00 CEST (manual test)
- Backed up AWG Docker volumes from all active nodes
- Archives uploaded to AWS S3 successfully
- **Settings confirmed:**
  - `KEEP=7` — keeps last 7 daily backups per node
  - Cron scheduled: **03:30 daily** → `/var/log/vpn_backup.log`
- Log location: `/var/log/vpn_backup.log`

#### 📖 Documentation created/updated:
- `VPN/BACKUP.md` — created: full backup system docs, how-to, cron setup, restore procedure, real run output from 2026-04-10
- `VPN/README.md` — updated: full file index with descriptions for all scripts and docs, node table, quick-start guide, backup quick reference
- `README.md` (root) — updated: both server specs, SSH key management section, backup system section, quick links, full coding standards with naming convention

#### 🗂️ Repository structure verified:
- All files in `222/`, `109/`, `VPN/`, `scripts/` reviewed
- No secrets found in public files ✅
- All scripts follow header/version/clear standards ✅

---

## 2026-04-08 | 222 + 109 | PHP-FPM per-site limits system

- Created `set_php_fpm_limits_v2026-04-07.sh` for both servers
- Added systemd cgroup: `CPUQuota=320%`, `MemoryMax=6.8G` per PHP-FPM service
- Set `pm.max_children=8`, `pm.max_requests=500` per pool
- Created `php_fpm_limits_info.md` with full parameter explanation
- Updated `222/README.md` and `109/README.md` with watchdog and limits docs

---

## 2026-04-07 | 222 | PHP-FPM watchdog + Telegram alerts

- Deployed `php_fpm_watchdog.sh` on server 222
- Watchdog checks CPU usage per pool every 5 minutes
- Auto-restarts pool if CPU > 90% for > 15 minutes
- Sends Telegram alert with pool name and CPU% on restart
- Added cron: `*/5 * * * * /root/php_fpm_watchdog.sh`

---

## 2026-04-05 | 222 | CrowdSec + Nginx bouncer fix

- Fixed CrowdSec engine INACTIVE state after hub corruption
- Script: `fix_nginx_crowdsec_222_v2026-04-05.sh`
- Rebuilt hub: `cscli hub update && cscli hub upgrade`
- Verified Nginx bouncer active and blocking ✅
- Updated `222/INSTALL_SCRIPTS.md` with fix procedure

---

## 2026-03-16 | ALL | Initial public repository setup

- Created `Linux_Server_Public` repository
- Added folder structure: `222/`, `109/`, `VPN/`, `scripts/`
- Added coding standards to root `README.md`
- Imported existing scripts from both servers
- Added `AMNEZIA_SETUP.md` and `AMNEZIA_INSTALL.md`
- Set up `save.sh` alias for quick git push on all servers

---

*= Rooted by VladiMIR | AI =*
