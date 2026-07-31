# 🖥️ Windows-VPS — Windows Client & VPS Management Scripts

> **WinSambaBackup** · **ISO Uploader** · **SMB Connect** · Windows VPS tools by [GinCz](https://github.com/GinCz)  
> Author: VladiMIR Bulantsev (GinCz) + AI · [github.com/GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)

**Keywords:** WinSambaBackup · Windows VPS backup · ISO upload SMB · Samba connect Windows · Windows Server backup script · bare-metal backup Windows · Clonezilla Windows · SMB drive connect bat · ISO downloader Linux · Windows backup restore · CIFS mount Windows · KVM Windows backup · disk image restore · GinCz scripts · Linux server tools

---

## 📦 Scripts in this folder

| File | Purpose |
|------|---------|
| [`SMB_Connect.bat`](SMB_Connect.bat) | Connect all Samba/SMB shares as Windows drives in parallel |
| [`backup_to_smb.sh`](../scripts/backup_to_smb.sh) | **WinSambaBackup** — bare-metal backup & restore over SMB |
| [`upload_iso_to_smb.sh`](upload_iso_to_smb.sh) | Download & upload ISO files directly to Samba/SMB share |

---

## 💾 WinSambaBackup — Bare-Metal Backup & Restore over Samba/SMB

**WinSambaBackup** (`scripts/backup_to_smb.sh`) creates compressed block-level disk images
of a Windows or Linux VPS/server and stores them on a Samba/CIFS/SMB network share.
No local storage needed — runs from any Live/recovery system via a single `curl` command.

> **Use case:** You need to back up a Windows Server 2016/2019/2022 VPS running on KVM.
> Boot into recovery/Live, run WinSambaBackup, and the full disk image lands on your Samba share
> in ~3 minutes. Restore with one command. Delete old backups from the same menu.

### ✨ Features

- **Single `curl` command** — no installation, runs from Live/recovery system
- **Interactive menu**: `[0]` New Backup · `[1]` Restore · `[2]` Delete image
- **Editable Samba path** — default pre-filled, press Enter to keep or type any SMB path
- **Windows temp cleanup before backup** (10 categories) — `pagefile.sys`, `hiberfil.sys`,
  `swapfile.sys`, `Windows\Temp`, `Prefetch`, `Logs`, `Minidump`,
  `SoftwareDistribution\Download`, `Users\*\AppData\Local\Temp`, `$Recycle.Bin`
- **Smart NTFS detection** — finds Windows partition automatically
- **Parallel compression** via `pigz -z1p` (all CPU cores)
- **4 GB chunk splitting** — FAT32/SMB compatible, reassembled automatically on restore
- **Guaranteed cleanup** via `trap EXIT` — unmounts everything on Ctrl+C or error
- **`YES` confirmation** before any destructive action (restore or delete)
- **Auto-installs** all dependencies: `clonezilla`, `cifs-utils`, `pigz`, `ntfs-3g`

### 🚀 Run WinSambaBackup

> **Requires:** root, Live USB / recovery system (not the OS being backed up), SMB share access.

```bash
export LANG=C LC_ALL=C TERM=xterm-256color
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/backup_to_smb.sh \
  -o /tmp/backup_to_smb.sh && bash /tmp/backup_to_smb.sh
```

### 🔄 WinSambaBackup Flow

```
[STEP 1]  Set timezone & console resolution (1024×768 for KVM/VNC)
[STEP 2]  Enter Samba/SMB path (editable, default pre-filled), username, password
[STEP 3]  Auto-install dependencies + mount Samba share
[STEP 4]  Show existing WinSambaBackup images with size & date
          → [0]  Create new BACKUP
          → [1]  RESTORE selected image to /dev/sda
          → [2]  DELETE selected image from Samba share
```

### 📊 Tested Results (2026-07-31, KVM)

| Parameter | Value |
|-----------|-------|
| OS | Windows Server 2016 |
| Disk | `/dev/sda` — 100 GB |
| Used before backup | ~9.3 GB (after Windows temp cleanup) |
| **Backup size** | **6.1 GB** compressed |
| **Duration** | **~3 min** (Partclone @ 8–16 GB/min) |
| SMB target | `\\s.gincz.com\soft\ISO` |
| Status | ✅ All 3 partitions saved and restorable |

### ⚙️ Tech Stack

| Component | Role |
|-----------|------|
| `ocs-sr savedisk` | Clonezilla disk imaging engine |
| `partclone` | Filesystem-aware block-level copy (NTFS/ext4/FAT) |
| `pigz -z1p` | Parallel gzip — multi-core compression |
| `cifs-utils` | Samba/SMB/CIFS 3.0 mount |
| `ntfs-3g` | NTFS read-write for Windows temp cleanup |
| `read -e -i` | Readline editing with pre-filled default SMB path |
| `trap EXIT` | Guaranteed unmount on any exit (Ctrl+C / error / normal) |

📋 Full version history → [CHANGELOG.md](../CHANGELOG.md)

---

## 📀 ISO Uploader — Download & Upload ISO to Samba/SMB Share

**`upload_iso_to_smb.sh`** downloads ISO files (Windows, Ubuntu, Debian, custom) from any URL
and saves them directly to a Samba/SMB network share — no local storage needed.
Useful for keeping bootable ISO images on your Samba server for PXE boot, KVM, or VirtualBox.

> **Use case:** You want to store Windows Server 2022 ISO on your Samba share at
> `\\s.gincz.com\soft\ISO` without downloading to your local PC first.
> Run the script from any Linux server/VPS with access to the SMB share.

### ✨ ISO Uploader Features

- **Direct upload to Samba** — streams ISO via `wget -O` directly to mounted SMB share
- **Interactive menu** — choose from preset ISO list or enter a custom URL
- **Progress bar** — shows download speed and ETA in real time
- **MD5/SHA256 checksum verify** — validates ISO integrity after download (optional)
- **Samba path editable** — default pre-filled, press Enter to keep or change
- **Auto-install** of dependencies: `cifs-utils`, `wget`
- **Cleanup trap** — unmounts Samba share on Ctrl+C or error

### 🚀 Run ISO Uploader

```bash
export LANG=C LC_ALL=C TERM=xterm-256color
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Windows-VPS/upload_iso_to_smb.sh \
  -o /tmp/upload_iso_to_smb.sh && bash /tmp/upload_iso_to_smb.sh
```

### 🔄 ISO Uploader Flow

```
[STEP 1]  Enter Samba/SMB path, username, password
[STEP 2]  Mount Samba share — show free space
[STEP 3]  Choose ISO:
          [1]  Windows Server 2022 Evaluation
          [2]  Windows Server 2019 Evaluation
          [3]  Ubuntu 24.04 LTS Server
          [4]  Debian 12 Netinstall
          [0]  Enter custom URL
[STEP 4]  Download ISO → stream directly to Samba share
[STEP 5]  Verify checksum (optional) → report file size & SMB free space
```

---

## 🔗 SMB_Connect.bat — Connect All Samba Drives on Windows

**`SMB_Connect.bat`** connects multiple Samba/SMB network shares as Windows drives
in parallel, with color-coded status output and automatic drive label assignment via registry.

### ✨ SMB_Connect Features

- **Parallel launch** — all servers connect simultaneously via `start /b`
- **Password at launch** — not stored in the script, cleared from memory after use
- **Color output** — green `[OK]`, yellow `[SKIP]`, red `[FAIL]`, `[TIMEOUT]`
- **Drive labels** — set via `reg add` in Windows Explorer
- **Reliable result detection** — folder-based (`C:\smbtmp\ok\`, `fail\`, `skip\`)

### Status Codes

| Status | Meaning |
|--------|---------|
| `[  OK  ]` | Drive connected successfully |
| `[ SKIP ]` | Server unreachable (ping failed) |
| `[ FAIL ]` | Ping OK, but SMB connection rejected |
| `[TIMEOUT]` | Failed to connect within 8 seconds |

### 📅 SMB_Connect Changelog

| Version | Changes |
|---------|---------|
| v2026.06.15b | Connect to `\storage`; `soft\` and `user\` visible inside |
| v2026.06.14h | Password entered at launch, not stored in script |
| v2026.06.14g | Folder-based result detection; IONOS without ping |
| v2026.06.14e | First working version with parallel launch |

---

## 🔍 About

All scripts in this folder are part of the **Linux Server Public** toolkit by **VladiMIR Bulantsev (GinCz)**.
Production-tested on a 10-node Ubuntu 24 LTS fleet with Samba, KVM, XRAY VPN, and CrowdSec.

> **Tags:** `WinSambaBackup` `windows-backup-smb` `samba-backup-script` `iso-upload-smb`
> `clonezilla-windows` `bare-metal-backup` `kvm-backup` `windows-server-backup` `partclone`
> `cifs-mount` `ntfs-3g` `pigz` `disk-image-restore` `smb-bat` `windows-vps` `GinCz`

🔗 Main repo README: [Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)  
👤 Author: [github.com/GinCz](https://github.com/GinCz) — VladiMIR Bulantsev

---

*= Rooted by VladiMIR + AI | Windows-VPS | github.com/GinCz =*
