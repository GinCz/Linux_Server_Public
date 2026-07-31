# 🗂️ Windows-VPS Scripts

> **VladiMIR Bulantsev (GinCz)** · [github.com/GinCz](https://github.com/GinCz)  
> Windows-side and server-side utility scripts for VPS/KVM server administration.

---

## 📂 Contents

| File | Type | Description |
|------|------|-------------|
| `SMB_Connect.bat` | Windows BAT | Connect all Samba network drives in parallel from Windows |
| `download_iso.sh` | Bash | Download ISO / large files directly to a Samba/SMB share |
| `backup_to_smb.sh` | Bash | **WinSambaBackup** — bare-metal backup & restore over SMB |

> `backup_to_smb.sh` lives in `../scripts/` but is described here as it’s part of the Windows VPS workflow.

---

## 💾 WinSambaBackup — `../scripts/backup_to_smb.sh`

**WinSambaBackup** creates compressed bare-metal disk images of Windows/Linux servers
and saves them directly to a Samba/SMB/CIFS network share — no local storage needed.
Built on Clonezilla + Partclone + pigz.

### Quick start

```bash
export LANG=C LC_ALL=C TERM=xterm-256color
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/backup_to_smb.sh \
  -o /tmp/backup_to_smb.sh && bash /tmp/backup_to_smb.sh
```

> Run from a **Live USB / recovery system** (not the OS being backed up). Requires root.

### What it does

1. **Mounts** your Samba/SMB share (editable path, credentials at runtime)
2. **Cleans** Windows temp files before imaging (10 categories, frees 1–10 GB)
3. **Shows** list of existing WinSambaBackup images with size and date
4. **Choose action** from one menu:
   - `[0]` — Create new **BACKUP** (Clonezilla savedisk, pigz compressed, 4 GB chunks)
   - `[1]` — **RESTORE** selected image to disk (requires `YES` confirmation)
   - `[2]` — **DELETE** selected image from SMB (requires `YES` confirmation)
5. **Unmounts** everything cleanly on exit (trap EXIT)

### Features

- Single `curl` command — no installation
- Parallel gzip via `pigz -z1p` (all CPU cores)
- Smart Windows partition detection (checks for `\Windows` folder)
- 7-method KVM/VNC console resolution enforcement (1024×768)
- `set -euo pipefail` — strict error handling
- Auto-installs: `clonezilla`, `cifs-utils`, `pigz`, `ntfs-3g`

### Tested result

| Parameter | Value |
|-----------|-------|
| Disk | `/dev/sda` — 100 GB |
| Windows used | ~9.3 GB (after cleanup) |
| Backup size | **6.1 GB** compressed |
| Duration | **~3 min** (Partclone @ 8–16 GB/min) |
| Status | ✅ All 3 partitions restorable |

---

## 📥 ISO Downloader — `download_iso.sh`

Downloads any ISO or large file directly to a Samba/SMB/CIFS network share.
No local disk needed — the file streams straight from the internet to your SMB share.

### Quick start

```bash
export LANG=C LC_ALL=C TERM=xterm-256color
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Windows-VPS/download_iso.sh \
  -o /tmp/download_iso.sh && bash /tmp/download_iso.sh
```

> Run from any Linux server or Live system with network access to your Samba share. Requires root.

### What it does

1. **Mounts** your Samba/SMB share (editable path, credentials at runtime)
2. **Shows** free space on the share
3. **Asks** for a direct download URL (ISO, ZIP, IMG, any file)
4. **Suggests** filename from URL — editable before download starts
5. **Downloads** with `wget -c` (resume support) or `curl -C -` as fallback
6. **Reports** final file size and remaining SMB free space
7. **Unmounts** SMB on exit (trap EXIT)

### Features

- Resume support (`wget -c` / `curl -C -`) — safe to Ctrl+C and retry
- Progress bar in terminal
- Pre-flight free space check before download
- Editable filename — rename on the fly before saving
- Works with any direct URL: Microsoft, Ubuntu, Debian, custom mirrors
- Auto-installs `wget`, `curl`, `cifs-utils` if missing

### Example use cases

```
URL: https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso
URL: https://software-download.microsoft.com/sg/Win11_23H2_English_x64.iso
URL: https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.9.0-amd64-netinst.iso
```

---

## 🔗 SMB Connect — `SMB_Connect.bat`

Windows BAT script. Connects multiple Samba network drives in parallel from a Windows machine.

### Quick start

```
Right-click SMB_Connect.bat -> Run as Administrator
```

### What it does

1. Asks for SMB password at launch (never stored in the script)
2. Saves credentials to Windows Credential Manager (`cmdkey`)
3. Connects all configured Samba shares **in parallel** (`start /b`)
4. Waits 8 seconds, then shows color-coded results
5. Sets drive labels in Windows Explorer via registry (`reg add`)

### Features

- **Parallel connection** — all servers connect simultaneously (~8 sec total)
- **Color output** — green OK · yellow SKIP · red FAIL · red TIMEOUT
- **Ping pre-check** — skips unreachable servers instantly
- **ICMP-blocked server support** — connects directly without ping if needed
- **Drive labels** — custom names visible in Windows Explorer
- **Password not stored** — entered at launch, cleared from memory after use

### Status codes

| Status | Meaning |
|--------|------- |
| `[  OK  ]` | Drive connected successfully |
| `[ SKIP ]` | Server unreachable (ping failed) |
| `[ FAIL ]` | Ping OK, but SMB connection rejected |
| `[TIMEOUT]` | No response within 8 seconds |

### Changelog

| Version | Changes |
|---------|--------|
| v2026.07.11 | Connect to `\storage` root; `soft\` and `user\` visible inside |
| v2026.06.15b | `reg add` for drive labels; all paths updated to `#storage` |
| v2026.06.14h | Password entered at launch, not stored in script |
| v2026.06.14g | Folder-based result detection (ok/fail/skip); IONOS without ping |
| v2026.06.14e | First working version with parallel launch |

---

*= Rooted by VladiMIR + AI | v2026.07.31 | github.com/GinCz =*
