# Changelog — Linux_Server_Public

> All notable changes to server infrastructure, scripts, and configurations are documented here.
> Format: `[YYYY-MM-DD] | Server | Category | Description`

---

## [2026-05-31] — Go Runtime mmap Crash Fix (FastPanel File Manager / wowflow)

**Server:** 152.53.182.222 (EU-NetCup)  
**Affected service:** `filemanagersystemd@wowflow.service`

### Problem
FastPanel File Manager for user `wowflow` crashed immediately at start:
```
fatal error: failed to reserve page summary memory
runtime.(*pageAlloc).sysInit → mpagealloc_64bit.go:81
```
Process exited `status=2` before reaching `main()`.

### Root Cause
Line `@wowflow hard as 300000` in `/etc/security/limits.conf` set a 293 MB virtual
address space limit (`RLIMIT_AS`). The Go runtime unconditionally reserves several
hundred gigabytes of **virtual** (not physical) address space via `mmap` at startup.
Kernel enforces `RLIMIT_AS` against `mmap` calls → Go panics before start.

**Key insight:** This is NOT a RAM issue. Go does not allocate physical memory,
just reserves virtual address space. `hard as` is fundamentally incompatible with
any Go binary, regardless of the value set.

### Fix
```bash
sed -i '/@wowflow hard as/d' /etc/security/limits.conf
systemctl daemon-reload
systemctl reset-failed filemanagersystemd@wowflow.service
systemctl start filemanagersystemd@wowflow.service
```
`nproc 50` limit kept. Service started successfully at 01:19:34 CEST.

### Scope check
- Server 222: no other `hard as` entries ✅
- Server 109: no `hard as` entries, no filemanager services ✅

**Full postmortem:** `222/FASTPANEL_GO_MMAP_FIX.md`

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

> _= Rooted by VladiMIR + AI | v.2026.05.31 | github.com/GinCz =_
