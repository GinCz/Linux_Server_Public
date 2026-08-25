# WORKLOG — Linux Server Automation

> Repository: [GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)  
> Author: VladiMIR + AI  
> Format: reverse-chronological (newest session first)

---

## Session: 2026-08-25 — Hardcore Disk Cleanup & Swap Optimization (`server_cleanup.sh`)

**Environment:** All Linux & Ubuntu 24.04 VPN / Master Nodes (4Ton-237, DE-222, RU-109, etc.)  
**Status:** ✅ Completed

### Goal
Upgrade the global `cleanup` utility (`scripts/server_cleanup.sh`, `cleanup/server_cleanup.sh`, and `Ubuntu24_Slim/ubuntu24_slim.sh`) for aggressive disk recovery while providing 100% strict preservation for critical background services: **AdGuard Home, Xray VPN (x-ui/xray), Samba (smbd/nmbd), Uptime Kuma monitoring, and SSH/CrowdSec**.

### What was done
1. **Intelligent Swapfile Optimization:**
   - Implemented automated detection and downsizing of oversized `/swapfile` (reducing from 3 GB to 1 GB), recovering **2+ GB** of pure root disk space on small VPS nodes while keeping `zram0` active.
2. **Aggressive System Pruning:**
   - Automated removal of Canonical bloatware & telemetry (`apport`, `whoopsie`, `ubuntu-report`, `popularity-contest`, `landscape-common`).
   - Journal vacuuming with rotation down to 30 MB / 2 days.
   - Purged unused Linux kernels, APT cache, rotated archive logs (`*.gz`, `*.1`, `*.old`), and temporary files (`/tmp`, `/var/tmp`, `/var/crash`).
   - Cleaned up unused snapd dependencies where no custom snaps are present.
3. **Protected Service Health Guard:**
   - Added automated status validation ensuring Xray VPN, Samba, AdGuard Home, Uptime Kuma, and SSH remain active and intact after cleanup.
4. **Synchronized Global Repositories:**
   - Updated `scripts/server_cleanup.sh`, `cleanup/server_cleanup.sh`, and `Ubuntu24_Slim/ubuntu24_slim.sh` for 1-click execution via terminal alias `cleanup`.

---

## Session: 2026-08-23 — Oracle Cloud Always Free Infrastructure & DietPi Live Installer

**Environment:** Oracle Cloud Infrastructure & Public Linux VPS  
**Status:** ✅ Completed

### Goal
Document the complete Oracle Cloud Always Free infrastructure (4 ARM OCPU / 24 GB RAM + 2 AMD Micro), publish a step-by-step 0.00 € / month hardening checklist, and deploy a universal in-RAM 1-click live installer for 350 MB pure DietPi OS.

### What was done
1. **Created `Oracle_Cloud/` Module:**
   - Authored `Oracle_Cloud/README.md` with complete service catalogs, storage quotas (200 GB NVMe), networking (2 public IPv4s, /64 IPv6, 10 TB egress), and 7-step zero-cost hardening checklist.
   - Documented Pay-As-You-Go upgrade strategy for lifetime immunity against Idle Instance Reclamation.
2. **Built Universal In-RAM DietPi Live Installer (`Oracle_Cloud/dietpi_installer.sh`):**
   - Implemented auto-detection for ARM64 (Ampere A1) and x86_64 architectures.
   - Configured official download CDN mirror (`dietpi.com`) without private network share dependencies.
   - Added in-RAM buffering in `/dev/shm`, preservation of `/root/.ssh/authorized_keys`, direct disk block writing, and kernel hardware instant reboot via SysRq.
3. **Authored Step-by-Step Manual (`Oracle_Cloud/DIETPI_INSTALLATION_GUIDE.md`):**
   - Detailed base Debian 12 deployment, 1-line execution, and post-installation tuning.
4. **Updated Master Repository Index (`README.md`):**
   - Linked new module in Quick Start and repository structure.

---

## Session: 2026-08-17 — Global MOTD Standardization & ClamAV Deployment

**Environment:** Server 222 (Master), Server 109, and 10 VPN Nodes  
**Status:** ✅ Completed

### Goal
Standardize MOTD banners, clean up deprecated scripts across all servers, fix missing aliases, and deploy ClamAV to all VPN nodes from a single control point.

### What was done
1. **Global Repo Cleanup:** Purged dozens of redundant/legacy scripts. Centralized aliases into `apply_aliases.sh`.
2. **MOTD Standardization:** 
   - Enforced a strict 90-character width for all server MOTDs.
   - Suppressed SSH spam with `clear` and added `_MOTD_LOADED` guard.
   - Removed `Samba` block from VPN MOTDs (ubiquitous service, unneeded in header).
3. **Alias Restoration:** Restored `banlist` alias (`cscli decisions list`) that was dropped during cleanup.
4. **ClamAV Global Deployment:**
   - Ran `install_clamav_standalone.sh` from Server 222 across all VPN servers.
   - **Fix:** Modified `install_clamav_standalone.sh` to copy and wrap `scan_clamav.sh` instead of writing an inline script. This restores the interactive menu (1: Install, 2: Run, 3: View Log) when the user runs `antivir`.


## Session: 2026-07-31 — backup_to_smb.sh full-day development

**Environment:** CloudStack KVM hypervisor, VNC console (~800×600 or 1024×768),
Ubuntu-based Live system, Windows Server 2016 on `/dev/sda`  
**SMB share:** `//s.gincz.com/soft/ISO`  
**Final version:** `v.2026.07.31i`

---

### Goal

Build a fully interactive, single-script bare-metal backup & restore tool that:
- Runs entirely from a **curl one-liner** on a booted Live/recovery system
- Creates **Clonezilla-compatible disk images** compressed with pigz and stored on SMB
- Supports **restore** and **delete** of existing images from the same menu
- Requires **no local storage** — all I/O goes directly to the network share
- Displays clearly in a **VNC console** (small resolution, no GUI)

---

### Timeline & Problems Solved

#### 1. Initial version — v.2026.07.31

**What was built:**
- Complete pipeline: auto-install deps → set timezone → mount SMB → clean Windows temps
  → Clonezilla `savedisk` → post-backup summary
- RESTORE mode: scan SMB for backup folders, numbered list, `YES` confirmation, `ocs-sr restoredisk`
- Trap-based cleanup on exit, Ctrl+C, error — unmounts all NTFS temp mounts and SMB
- Optional SSH root password change at startup

**Tools used:** `clonezilla`, `partclone`, `pigz`, `ntfs-3g`, `cifs-utils`, `ocs-sr`

---

#### 2. v.2026.07.31b — Windows Temp Cleanup Improvements

**Problem:** Original version removed only `pagefile.sys`. Actual Windows C: partition
was 9.3 GB used — after cleanup it dropped significantly, improving compression ratio.

**Solution:** Added 10-category Windows cleanup:
- `pagefile.sys`, `hiberfil.sys`, `swapfile.sys`
- `Windows\Temp`, `Windows\Prefetch`, `Windows\Logs`, `Windows\Minidump`
- `Windows\SoftwareDistribution\Download`, `PostRebootEventCache.V2`
- `Users\*\AppData\Local\Temp`
- `$Recycle.Bin` on every NTFS partition

Added per-item freed-size counter, total freed summary, SMB space before/after.

---

#### 3. v.2026.07.31c — Two Critical Bug Fixes

**Bug 1 — arithmetic crash in `clean_item()`:**
```
arithmetic syntax error: operand expected
```
Root cause: `FREED=$(clean_item ...)` was capturing both the byte count *and* the
`ok()`/`warn()` human-readable messages printed inside the function.
Fix: redirect all `ok`/`warn` calls inside `clean_item()` to stderr with `>&2`,
so the subshell output contains only the raw number.

**Bug 2 — `$Recycle.Bin` bash variable expansion:**
```bash
# broken — bash expands $R as empty variable:
RECYCLE_PATH="${TMP_MOUNT}/$Recycle.Bin"
# fixed — single-quoted literal:
RECYCLE_PATH="${TMP_MOUNT}"/'$Recycle.Bin'
```

**Also removed:** SSH root password change step — redundant when already connected via SSH.

---

#### 4. v.2026.07.31d — Banner Fix (VNC Display)

**Problem:** Multi-line ASCII-art banner was misaligned in KVM VNC console due to
console font proportions. Characters that form box-drawing art displayed as solid
blocks or uneven widths.

**Solution:** Replaced with plain-text single-line header:
```
BACKUP/SMB  |  Clonezilla+Partclone  |  v.2026.07.31h  |  github.com/GinCz
```

---

#### 5. v.2026.07.31e & v.2026.07.31f — Restore/Delete Flow Redesign

**User request:** Add ability to **delete** backups from SMB share directly from
the script, without needing to manually connect to the share.

**v.2026.07.31e:** Added a pre-selection submenu (`[1] RESTORE / [2] DELETE / [0] Back`).

**v.2026.07.31f:** Moved the submenu to *after* backup selection:
1. Numbered backup list with size and date
2. Select backup number
3. `[1] RESTORE` — full Clonezilla restore to `/dev/sda` with `YES` confirmation
4. `[2] DELETE` — `rm -rf` with size confirmation, freed space reported

**First successful DELETE test:**
- Deleted: `WinServer2016_Backup_20260731_1329` (6.4 GB)
- SMB free after: **138 GB**
- Status: ✅ Clean, no errors

---

#### 6. v.2026.07.31g — New Top-Level Flow

**User request:** Remove the initial `[1] BACKUP / [2] RESTORE` mode selector.
Instead, credentials should be asked *first*, then the backup list appears
immediately after mount, and the user picks an image and gets `[1] Restore / [2] Delete`.
New backup is accessible from the same screen.

**New 4-step flow:**
```
STEP 1/4  Timezone & Console
STEP 2/4  SMB Credentials  ← moved to top
STEP 3/4  Install deps + Mount SMB
STEP 4/4  Backup list → select → [1] Restore / [2] Delete / [0] New Backup
```

---

#### 7. v.2026.07.31h — Compact Output + Aggressive Resolution Fix

**Problem 1 — Console still showing at 800×600:**  
Previous attempts (`fbset`, `printf '\033[8;48;128t'`) were not enough on the
CloudStack KVM VNC console. The terminal window remained visually small.

**Solution:** Applied 7 resolution methods in sequence:
| # | Method | Effect |
|---|--------|--------|
| 1 | `fbset -g 1024 768 1024 768 32` | Framebuffer geometry |
| 2 | `/sys/class/graphics/fb*/virtual_size` | Kernel sysfs fb size |
| 3 | `setterm --resize` | VT kernel resize |
| 4 | `xrandr -s 1024x768` | X11 (if running) |
| 5 | `stty cols 128 rows 48` | TTY columns/rows |
| 6 | `printf '\033[8;48;128t'` | ANSI xterm escape |
| 7 | `mode2` | SVGAlib fallback |

**Problem 2 — Too many blank lines, content doesn't fit on screen:**  
With 800×600 resolution (~25–30 visible rows), the existing blank `echo` lines
between sections caused important information to scroll off screen.

**Solution:** Removed all blank `echo ""` lines. Collapsed multi-line status outputs
to single lines:
```bash
# Before (3 lines):
echo "SMB Share Disk Space"
echo "Total: ..."
echo "Used: ..."

# After (1 line):
ok "SMB mounted.  Total:247G  Used:117G  Free:131G"
```

---

#### 8. v.2026.07.31i — Separator Width & Menu Cleanup

**Problem:** The 90-character `=` separator lines were wrapping in some terminal
widths, causing double-line visual artifacts.

**Fix:** Counted separator to exactly **90 chars** — fits safely in any 90+ column terminal.

**User request:** Replace `[B]` (letter) with `[0]` (number) for new backup;
remove the `Exit` option entirely — Ctrl+C handles abort.

```
# Before:
[B] New backup  ||  [0] Exit

# After:
[0] Create new BACKUP
```

---

### Final Script State (v.2026.07.31i)

**File:** [`scripts/backup_to_smb.sh`](https://github.com/GinCz/Linux_Server_Public/blob/main/scripts/backup_to_smb.sh)

**Run command:**
```bash
export LANG=C LC_ALL=C TERM=xterm-256color
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/backup_to_smb.sh \
  -o /tmp/backup_to_smb.sh && bash /tmp/backup_to_smb.sh
```

**Complete flow:**
```
[Banner: 2-line header with version]
STEP 1/4  Timezone set to Europe/Prague; 7-method resolution enforcement
STEP 2/4  SMB Username + Password prompt
STEP 3/4  apt-get install clonezilla cifs-utils pigz ntfs-3g
          mount //s.gincz.com/soft/ISO → /home/partimag
          Show: SMB Total/Used/Free in one line
STEP 4/4  Scan SMB for Clonezilla backup folders (blkid.list detection)
          If backups exist → numbered list with size and date
          Prompt: [1-N] select backup  ||  [0] new backup
          If backup selected → [1] RESTORE  /  [2] DELETE
            [1] RESTORE: WARNING banner → YES confirm → ocs-sr restoredisk
            [2] DELETE:  name+size confirmation → YES confirm → rm -rf → freed size
          If [0] → NTFS scan → Windows temp cleanup → Clonezilla savedisk
[EXIT TRAP] sync → umount all NTFS mounts → umount SMB → clean exit message
```

**Key technical choices:**
- `ocs-sr savedisk` with `-z1p` (pigz parallel gzip), `-i 4000` (4 GB chunks), `-j2`
- `find -maxdepth 2 -name blkid.list` for reliable Clonezilla folder detection
- `set -euo pipefail` — strict error handling
- `trap cleanup EXIT` — guaranteed unmount on any exit path
- All separator lines exactly 90 chars wide
- Colors: `GREEN`=OK, `YELLOW`=warn/sep, `RED`=error/danger, `CYAN`=step headers

---

### Backup Results — 2026-07-31

| # | Name | Size | Time | Status |
|---|------|------|------|--------|
| 1 | `WinServer2016_Backup_20260731_1329` | 6.4 GB | 15:31:57 | 🗑️ Deleted (test) |
| 2 | `WinServer2016_Backup_20260731_1605` | 6.1 GB | 16:07:36 | ✅ Kept |

- Disk: `/dev/sda` 100G — sda1 (500M), sda2 (39.7G WinServ2016), sda3 (59.8G DATA)
- Windows used: ~9.3 GB → after cleanup significantly less → compressed to **6.1 GB**
- SMB free after session: **138 GB** of 247 GB total
