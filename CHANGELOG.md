# Changelog — Linux_Server_Public

> All notable changes to server infrastructure, scripts, and configurations are documented here.
> Format: `[YYYY-MM-DD] | Server | Category | Description`

---

## [2026-06-10] — sos.sh v2026.06.10d — Unified Installer + Audit Script

**Script:** `scripts/sos.sh`
**Version:** `v2026.06.10d`

### Summary

The `install_sos.sh` script was eliminated entirely. All installation logic was merged
directly into `sos.sh`. The script now serves two purposes in a single file:
1. **Installer** — downloads itself, places binary at `/usr/local/bin/sos`, writes aliases
2. **Audit tool** — runs the full server status report for the selected time window

---

### Problem 1 — Two Scripts Were Redundant

Previously the workflow required:
```bash
bash <(curl install_sos.sh)   # step 1 — install
sos                           # step 2 — run audit
```

This was redundant. The user had to maintain two separate scripts in the repository,
keep them in sync, and run two commands for a simple setup. The `install_sos.sh` script
did nothing that `sos.sh` itself could not do.

**Fix:** Deleted `install_sos.sh`. All install logic (`curl` self-download, `chmod +x`,
alias injection into `.bashrc` / `.bash_profile`) moved into `sos.sh` as `do_install()`.

---

### Problem 2 — Missing "Run / Install" First Menu Step

When running `bash <(curl -fsSL .../sos.sh)`, the script was skipping the first
selection menu and jumping directly to the time window selection (1h / 3h / 24h / 120h).
The user had to always see "Run or Install?" as the **very first question** when launching
from GitHub via curl-pipe, but this menu was absent.

**Root cause investigated:**
- First attempt: used `$0 == "bash"` to detect pipe mode. Failed on some systems where
  `$0` in process substitution returns `/proc/self/fd/63` or a file descriptor path,
  not the string `"bash"`.
- Second attempt: used `[ -t 0 ]` (stdin is a terminal) and `[ -p /dev/stdin ]`
  (stdin is a pipe). Also unreliable — process substitution `bash <(...)` does NOT
  set stdin to a pipe; it passes a file descriptor, so `-p /dev/stdin` returned false.
- **Final fix:** Compare `realpath "$0"` against `realpath "/usr/local/bin/sos"`.

```bash
SELF_REAL="$(realpath "$0" 2>/dev/null || echo "$0")"
SOS_BIN_REAL="$(realpath "/usr/local/bin/sos" 2>/dev/null || echo "/usr/local/bin/sos")"

if [ "$SELF_REAL" = "$SOS_BIN_REAL" ]; then
  IS_INSTALLED=1   # launched as installed binary → go directly to time window
else
  IS_INSTALLED=0   # launched via curl|bash → show "Run / Install" first
fi
```

When launched via `bash <(curl ...)`, bash reads the script from a file descriptor like
`/proc/self/fd/63`. `realpath` on that path will **never** equal `/usr/local/bin/sos`,
so `IS_INSTALLED` is always `0` in pipe mode. When launched as the installed binary,
`realpath /usr/local/bin/sos` equals itself, so `IS_INSTALLED=1`.

---

### Final Behavior

#### Mode A — From GitHub (curl-pipe, first-time setup)

```
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh)
```

```
==========================================================================================
  SOS v.2026.06.10d  |  hostname  |  2026-06-10 01:08:00
==========================================================================================

  Что делаем?

    1) Run     — запустить аудит сейчас (без установки)
    2) Install — установить sos на сервер + прописать алиас

  »
```

- Choice `1` → asks time window → runs audit
- Choice `2` → runs `do_install()`:
  - Downloads `sos.sh` from GitHub to `/usr/local/bin/sos`
  - Sets `chmod +x /usr/local/bin/sos`
  - Removes old alias lines from `/root/.bashrc` and `/root/.bash_profile`
  - Appends fresh `alias sos='/usr/local/bin/sos'` block to both files
  - Sources `/root/.bashrc`
  - **Immediately runs the audit for 24h** — no extra prompt after install

#### Mode B — Installed binary (`/usr/local/bin/sos`)

```bash
sos          # asks time window
sos 1h       # runs audit for 1 hour immediately
sos 3h       # runs audit for 3 hours immediately
sos 24h      # runs audit for 24 hours immediately
sos 120h     # runs audit for 120 hours immediately
```

Aliases registered: `sos`, `sos1`, `sos3`, `sos24`, `sos120`

---

### Files Changed

| File | Action |
|---|---|
| `scripts/sos.sh` | Rewrote entry point, added `do_install()`, added `IS_INSTALLED` detection via `realpath` |
| `scripts/install_sos.sh` | **Deleted** — no longer needed |
| `CHANGELOG.md` | This entry |

---

### Install Command (Current)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh) && source ~/.bashrc
```

Then choose `2) Install`. After that, `sos` command is available system-wide.

---

### Update Command

```bash
sos --update
# or equivalently:
bash <(curl -fsSL https://raw.githubusercontent.com/.../sos.sh)  → choose 2) Install
```

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

> _= Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =_
