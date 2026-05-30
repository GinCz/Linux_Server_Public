# Changelog — Linux_Server_Public

> All notable changes to server infrastructure, scripts, and configurations are documented here.
> Format: `[YYYY-MM-DD] | Server | Category | Description`

---

## [2026-05-30] — Multi-Server ClamAV Audit + FastPanel File Manager Fix

### 🛡️ ClamAV — Full Network Audit (9 servers)

| Server IP | ClamAV Before | DB Before | Action | Result |
|---|---|---|---|---|
| 109.234.38.47 | ✅ INSTALLED | ✅ Present | No action needed | ✅ OK |
| 144.124.228.237 | ✅ INSTALLED | ❌ Missing | Sync DB from donor | ✅ Fixed |
| 144.124.232.9 | ✅ INSTALLED | ❌ Missing | Sync DB from donor | ✅ Fixed |
| 144.124.228.227 | ❌ NOT installed | ❌ Missing | Install + sync DB | ✅ Fixed |
| 144.124.239.24 | ✅ INSTALLED | ❌ Missing | Sync DB from donor | ✅ Fixed |
| 91.84.118.178 | ❌ NOT installed | ❌ Missing | Install + sync DB | ✅ Fixed |
| 146.103.110.176 | ❌ NOT installed | ❌ Missing | Install + sync DB | ✅ Fixed |
| 144.124.233.38 | ✅ INSTALLED | ✅ Present | No action needed | ✅ OK |
| 212.109.223.109 | ✅ INSTALLED | ✅ Present | No action needed | ✅ OK |

**Donor server:** `152.53.182.222` (DE-EU-NetCup)  
**DB export URL:** `http://152.53.182.222/clam_db.tar.gz` (Host: czechtoday.eu)  
**DB files synced:** `main.cvd`, `daily.cvd`, `bytecode.cvd`  
**freshclam:** masked on all servers (manual sync via donor pattern)  

**DB sync command used on all receivers:**
```bash
cd /var/lib/clamav
wget -q --header="Host: czechtoday.eu" http://152.53.182.222/clam_db.tar.gz -O clam_db.tar.gz
tar -xzf clam_db.tar.gz && rm clam_db.tar.gz
chown -R clamav:clamav /var/lib/clamav
```

---

### 🔧 FastPanel — File Manager Fix (wowflow.cz on 152.53.182.222)

**Problem:**  
FastPanel File Manager on site `wowflow.cz` failed to open with error:
```
Runtime error: unable to execute: "/usr/bin/systemctl start filemanagersystemd@wowflow.service"
Warning: The unit file, source configuration file or drop-ins of
filemanagersystemd@wowflow.service changed on disk.
Run 'systemctl daemon-reload' to reload units.
Job for filemanagersystemd@wowflow.service failed because the control
process exited with error code.
```

**Root cause:**  
The `filemanagersystemd@wowflow.service` systemd unit file was modified on disk
(likely after a FastPanel update) but `systemd` was not reloaded, causing
the service start to fail with exit code 1.

**Fix applied on server 152.53.182.222:**
```bash
systemctl daemon-reload
systemctl reset-failed filemanagersystemd@wowflow.service
systemctl start filemanagersystemd@wowflow.service
systemctl status filemanagersystemd@wowflow.service --no-pager -n 20
```

**Prevention:** After any FastPanel update, always run `systemctl daemon-reload`
before accessing File Manager in the panel.

---

## [2026-05-29] — ClamAV Scan Script + Multi-Server Monitoring

- `scan_clamav.sh` established on `212.109.223.109` — weekly Sunday 02:00 cron
- Multi-server monitoring scripts reviewed and updated
- VPN server network audit performed
- PHP-FPM watchdog daemon verified on `212.109.223.109`

---

## [2026-03-12] — Cloudflare Configuration Backup

- `109/cloudflare.conf.bak.20260312` — backup before Cloudflare IP range update
- `109/cloudflare_real_ip.conf.bak.20260312` — backup of real IP resolution config
- Nginx reloaded after applying updated Cloudflare IP ranges

---

> _= Rooted by VladiMIR + AI | v.2026.05.30 | github.com/GinCz =_
