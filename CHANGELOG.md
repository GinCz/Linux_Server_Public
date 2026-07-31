# CHANGELOG — backup_to_smb.sh

> Repository: [GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)  
> Author: VladiMIR + AI  
> Script: `scripts/backup_to_smb.sh`

---

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
