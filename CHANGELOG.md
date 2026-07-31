# CHANGELOG — backup_to_smb.sh (GinBak)

> Repository: [GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)  
> Author: VladiMIR + AI  
> Script: `scripts/backup_to_smb.sh`

---

## v.2026.07.31j  *(2026-07-31)*
- **Editable SMB path in Step 2** with pre-filled default value:
  - Uses `read -e -i "${SMB_HOST_DEFAULT}"` — readline editing, cursor at end of default
  - Press **Enter** to keep `//s.gincz.com/soft/ISO` unchanged
  - Use **← Backspace** or **Ctrl+U** to edit/clear and type any other path
  - After confirmation, header re-renders with the selected path
- `SMB_HOST_DEFAULT` constant + `SMB_HOST` runtime variable separated for clarity
- Completion message now uses `${SMB_HOST}` (shows actual path used, not hardcoded)
- Makes script **universally usable** by anyone with any SMB/CIFS share

## v.2026.07.31i  *(2026-07-31)*
- **Separator width** trimmed to exactly **90 characters** (`=` and `-`) to fit
  narrower KVM/VNC console windows without line-wrapping
- **`[B]` New Backup option replaced by `[0]`** — unified numeric input throughout
  the selection menu; `Exit` option removed entirely (user presses Ctrl+C to quit)
- All menu prompts now use numeric-only input for consistency

## v.2026.07.31h  *(2026-07-31)*
- **Aggressive 1024×768 resolution** enforcement via 7 independent methods:
  1. `fbset -g 1024 768 1024 768 32` — direct framebuffer geometry
  2. `/sys/class/graphics/fb*/virtual_size` — kernel sysfs framebuffer size
  3. `setterm --resize` — VT terminal resize
  4. `xrandr -s 1024x768` — X11 (if `$DISPLAY` is set)
  5. `stty cols 128 rows 48` — tell kernel tty the terminal is 128×48 chars
  6. `printf '\033[8;48;128t'` — ANSI xterm resize escape
  7. `mode2` — SVGAlib fallback
- **Removed all blank `echo` lines** between sections; output is fully compact
- **Single-line status messages**: SMB disk info, cleanup totals, pre-flight check
  all collapsed to one line each
- Header condensed to 2 lines; step banners condensed to 1 line

## v.2026.07.31g  *(2026-07-31)*
- **Completely new user flow** (breaking change vs. v.f):
  1. Banner
  2. SMB Credentials (username + password) — **moved to top, Step 2**
  3. Install dependencies + mount SMB share
  4. Immediately show backup list on the same screen after mount
  5. User selects backup number → sees `[1] RESTORE` / `[2] DELETE`
  6. New backup via `[0]` from the same list screen
- Removed the initial BACKUP / RESTORE mode selector entirely
- Steps renumbered 1–4

## v.2026.07.31f  *(2026-07-31)*
- **RESTORE path restructured**: user first sees the full backup list and selects
  a backup by number, *then* chooses `[1] RESTORE` or `[2] DELETE`
- **DELETE action added** to RESTORE submenu:
  - Lists the backup with size
  - Requires `YES` confirmation before `rm -rf`
  - Reports freed space and new SMB free total after deletion
- Selection flow: numbered list → select number → `[1] RESTORE / [2] DELETE`

## v.2026.07.31e  *(2026-07-31)*
- Added RESTORE submenu shown **before** backup selection:
  `[1] RESTORE` / `[2] DELETE` / `[0] Back`
- Groundwork for DELETE feature (not yet functional in this version)

## v.2026.07.31d  *(2026-07-31)*
- Replaced broken multi-line ASCII-art logo with a compact, reliable text banner
  (ASCII-art was rendering incorrectly due to terminal font proportions in KVM/VNC consoles)
- Removed one blank line between header sections for a more compact display
- Minor polish: consistent spacing in step headers

## v.2026.07.31c  *(2026-07-31)*
- **Removed SSH root password step** (Step 2 of previous versions)
  — not needed when script is launched via SSH which is already established
- **Fixed critical crash** in `clean_item()`: `ok`/`warn` messages now redirect to
  stderr (`>&2`) so that `FREED=$(clean_item ...)` captures only the numeric byte
  count, preventing `arithmetic syntax error: operand expected`
- **Fixed `$Recycle.Bin` bash expansion bug**: path now built with single-quoted
  literal `'$Recycle.Bin'` to prevent bash treating `$R` as a variable
- Steps renumbered 0–5 (was 0–6 after SSH step removal)

## v.2026.07.31b  *(2026-07-31)*
- **Smart Windows partition detection**: script now mounts each NTFS partition
  and checks for presence of `\Windows` folder instead of blindly cleaning all
- **Full Windows temp cleanup** (10 categories) with per-item freed-size reporting:
  `pagefile.sys`, `hiberfil.sys`, `swapfile.sys`, `Windows\Temp`,
  `Windows\Prefetch`, `Windows\Logs`, `Windows\Minidump`,
  `Windows\SoftwareDistribution\Download`,
  `Users\*\AppData\Local\Temp`, `$Recycle.Bin` on all NTFS
- **Total freed bytes** counter with human-readable summary
- **SMB free space** shown immediately after successful mount
- **Windows partition space report** (Total / Used / Free) before and after cleanup
- **Pre-flight check**: SMB free vs full disk size comparison before imaging
- **Backup size** on share shown in completion message

## v.2026.07.31  *(2026-07-31)*  — initial version
- Interactive BACKUP / RESTORE mode selector
- Timezone set to `Europe/Prague` at startup
- Console resolution set to `1024x768` at startup
- Auto-install of dependencies: `clonezilla`, `cifs-utils`, `pigz`, `ntfs-3g`
- SMB 3.0 mount with clean remount if stale
- BACKUP: `ocs-sr savedisk` with parallel gzip `-z1p`, 4 GB chunks `-i 4000`, `-j2`
- RESTORE: scan SMB share for Clonezilla folders, numbered list with size/date,
  `YES` confirmation before destructive restore
- Trap-based cleanup: unmounts all NTFS temp mounts and SMB on exit/error/Ctrl+C
- Optional SSH root password change at startup *(removed in v.2026.07.31c)*
- Basic pagefile.sys removal from NTFS partitions before backup

---

## First successful backup — 2026-07-31

| Parameter        | Value |
|-----------------|-------|
| Machine         | CloudStack KVM Hypervisor |
| Disk            | `/dev/sda` — 100G |
| Partitions      | sda1 (500M NTFS System_Reserved), sda2 (39.7G NTFS WinServ_2016), sda3 (59.8G NTFS DATA_60) |
| Windows on      | `sda2` — 42.7 GB total, **9.3 GB used** |
| Backup name     | `WinServer2016_Backup_20260731_1605` |
| Backup size     | **6.1 GB** (compressed) |
| SMB target      | `\\s.gincz.com\soft\ISO` |
| SMB free before | 133G of 247G |
| Duration        | ~3 min (294s total, Partclone @ 8–16 GB/min) |
| Status          | ✅ All partitions restorable (verified by Clonezilla check) |

## First successful DELETE — 2026-07-31

| Parameter        | Value |
|-----------------|-------|
| Backup deleted  | `WinServer2016_Backup_20260731_1329` |
| Size freed      | **~6.4 GB** |
| SMB free after  | **138G** |
| Status          | ✅ Clean removal, SMB free space confirmed |
