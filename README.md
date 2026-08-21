# 🐧 Linux Server Public — WinSambaBackup · IPGuard · XRAY VPN · Samba · CrowdSec · Bash Scripting

> **VladiMIR Bulantsev (GinCz)** · [github.com/GinCz](https://github.com/GinCz)  
> Production scripts and configs for Ubuntu 24 LTS Linux servers.  
> All scripts are idempotent — safe to run multiple times.

**WinSambaBackup** · **IPGuard** · **XRAY VPN** · **CrowdSec** · **Samba** · **Fail2Ban** · **FastPanel** · **Cloudflare WAF** · **nginx** · **MariaDB** · **Clonezilla** · **bare-metal backup** · **SMB backup** · **Windows Server backup** · **Samba backup script** · **disk image** · bash scripting · Linux server administration · Ubuntu 24 LTS · server hardening · DevOps · sysadmin · KVM backup · Partclone · pigz · NTFS · CIFS · ntfs-3g · disk imaging · backup restore delete · GinCz

---

## ⚡ Quick Start

### 💾 WinSambaBackup — Windows Bare-Metal Backup & Restore over Samba/SMB

```bash
export LANG=C LC_ALL=C TERM=xterm-256color
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/backup_to_smb.sh \
  -o /tmp/backup_to_smb.sh && bash /tmp/backup_to_smb.sh
```

**WinSambaBackup** — interactive bare-metal backup and restore for Windows/Linux servers over Samba/CIFS/SMB.  
Creates compressed Clonezilla-compatible disk images directly on a network share — no local storage needed.  
Supports **backup**, **restore**, and **remote deletion** of images from a single interactive menu.

### 🖥️ Master Server Installer & Provisioning Wizard (`new_server_install.sh`)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh)
```

**Universal 5-Step Server Provisioning Wizard** for new and existing Ubuntu 22.04/24.04 nodes:
- **Interactive Wizard:** Prompts for server hostname, server role (VPN / Web 222 / Web 109), MOTD palette (8 colors), PS1 font color, and installation mode (FULL vs UPDATE).
- **3 Dynamic MOTD Banners:** Role-tailored telemetry banners displaying live RAM, Swap, CPU, Load, and service statuses (Xray, AdGuard Home, CrowdSec, fail2ban, Nginx, FastPanel).
- **Midnight Commander F2 Menu:** Native shortcuts for `sos` server audit, antivirus scan, Xray journals, AdGuard status, disk cleanup, and WordPress maintenance.
- **Automated Tool Deployment:** Installs latest `sos` (v2026.08.08a), `infooo`, `wp_update_all`, `run_all_wp_cron`, `server_cleanup`, `block_bots`, `domains`, and `system_backup` (for Web nodes).
- *See full documentation:* [scripts/README.md ↗](scripts/README.md).

### 🛡️ Install IPGuard (triple-layer security)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/install-ipguard.sh)
```

**IPGuard** provides three-layer protection for any Linux server — ipset blacklist + CrowdSec + Fail2Ban.

### 🗂️ Install Samba (file sharing + IPGuard security)

```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_setup.sh)
```

---

## 📁 Repository Structure

```
Linux_Server_Public/
├── scripts/
│   ├── backup_to_smb.sh       — WinSambaBackup: bare-metal backup/restore over Samba/SMB
│   ├── samba_setup.sh         — Full Samba installer
│   ├── samba_audit_all.sh     — Audit + auto-fix Samba on ALL servers via SSH
│   └── remove_samba.sh        — Remove Samba and close SMB ports
├── blacklist/                — IPGuard security system
│   ├── install-ipguard.sh     — IPGuard installer (ipset + CrowdSec + Fail2Ban)
│   ├── deploy-blacklist.sh    — Apply/update ipset blacklist
│   └── blacklist.txt          — Aggregated IP blacklist from all 10 nodes
├── configs/                  — Reference server configs (MariaDB, CrowdSec, nginx)
├── VPN_Amnezia/              — Archive: AmneziaWG legacy configurations & guides
├── windows/                  — Windows client scripts
│   └── SMB_Connect.bat        — Connect all 10 Samba servers at once
├── CHANGELOG.md              — Full version history of WinSambaBackup
└── WORKLOG.md                — Session-by-session development log
```

---

## 💾 WinSambaBackup — Windows Bare-Metal Backup & Restore over Samba/SMB

**WinSambaBackup** (`scripts/backup_to_smb.sh`) is an interactive bare-metal disk imaging tool
built on [Clonezilla](https://clonezilla.org/) + [Partclone](https://partclone.org/) + [pigz](https://zlib.net/pigz/).
It creates compressed, block-level disk images of a Windows or Linux server and writes them
directly to a Samba/CIFS/SMB network share — no local temp storage required.

> **WinSambaBackup** is designed for sysadmins who need a reliable, scriptable, single-command
> bare-metal backup tool for KVM/VPS/dedicated Windows servers without a GUI backup solution.
> Works on any server accessible via Samba/SMB/CIFS share.

### ✨ Features

- **Single `curl` command** — WinSambaBackup runs entirely from a Live/recovery system, zero install
- **Interactive numbered menu** — lists all WinSambaBackup images with size and date
- **Three actions from one screen**: `[1] RESTORE` · `[2] DELETE` · `[0] New BACKUP`
- **Editable Samba/SMB path** — default pre-filled, press Enter to keep or type a new path
- **Windows temp cleanup before backup** (10 categories):
  `pagefile.sys` · `hiberfil.sys` · `swapfile.sys` · `Windows\Temp` · `Windows\Prefetch` ·
  `Windows\Logs` · `Windows\Minidump` · `SoftwareDistribution\Download` ·
  `Users\*\AppData\Local\Temp` · `$Recycle.Bin` — maximizes compression ratio
- **Smart Windows partition detection** — mounts each NTFS partition, checks for `\Windows` folder
- **Parallel gzip** via `pigz -z1p` — fast multi-core compression
- **Guaranteed cleanup** via `trap EXIT` — unmounts all NTFS and Samba/SMB on any exit path
- **7-method resolution enforcement** — forces 1024×768 on KVM/VNC consoles
- **`YES` confirmation** before any destructive operation (restore or delete)
- **Auto-install** of all dependencies: `clonezilla`, `cifs-utils`, `pigz`, `ntfs-3g`
- **Timezone auto-set** to `Europe/Prague` at startup (configurable at top of script)

### 🚀 How to Run WinSambaBackup

> **Requirements:** root, Live USB / recovery system (not the OS being backed up), network access to Samba/SMB share.

```bash
export LANG=C LC_ALL=C TERM=xterm-256color
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/backup_to_smb.sh \
  -o /tmp/backup_to_smb.sh && bash /tmp/backup_to_smb.sh
```

### 🔄 WinSambaBackup Interactive Flow

```
==========================================================================================
  WinSambaBackup  |  Clonezilla+Partclone  |  v.2026.07.31j  |  github.com/GinCz
  Share: //your-server/share  |  Disk: /dev/sda
==========================================================================================
------------------------------------------------------------------------------------------
  STEP 1/4  Timezone & Console
------------------------------------------------------------------------------------------
  [OK]  TZ: Europe/Prague  CEST +0200  2026-07-31 18:57:48
  [OK]  Console: 128x48 requested (1024x768 equivalent)
------------------------------------------------------------------------------------------
  STEP 2/4  SMB Connection & Credentials  [WinSambaBackup]
------------------------------------------------------------------------------------------
  Edit the path or press Enter to keep the default:
  SMB Path   : //s.gincz.com/soft/ISO          <- editable, press Enter to keep
  SMB Username: vlad
  SMB Password: ****
  [OK]  Path: //s.gincz.com/soft/ISO  |  User: vlad
------------------------------------------------------------------------------------------
  STEP 3/4  Install Dependencies & Mount SMB Share
------------------------------------------------------------------------------------------
  [OK]  All dependencies installed.
  [OK]  SMB mounted.  Total:247G  Used:117G  Free:131G
------------------------------------------------------------------------------------------
  STEP 4/4  Select Backup & Action
------------------------------------------------------------------------------------------
  Found 1 WinSambaBackup image(s):
  === [1]  WinServer2016_Backup_20260731_1605   6.1G   2026-07-31 16:07:36
------------------------------------------------------------------------------------------
  Enter backup number [1-1] to manage  ||  [0] Create new BACKUP
  Your choice: 1

  Selected: WinServer2016_Backup_20260731_1605  (6.1G)
  === [1] RESTORE -- restore to /dev/sda  ||  [2] DELETE -- remove from SMB
  Enter 1 or 2: _
```

### ⚙️ WinSambaBackup Technical Stack

| Component | Role |
|-----------|------|
| `ocs-sr savedisk` | Clonezilla disk imaging engine |
| `partclone` | Filesystem-aware block-level copy (NTFS / ext4 / FAT) |
| `pigz -z1p` | Parallel gzip compression (all CPU cores) |
| `cifs-utils` | Samba/SMB/CIFS 3.0 network share mount (`vers=3.0`) |
| `ntfs-3g` | NTFS read-write access for Windows temp cleanup |
| `-i 4000` | Split image into 4 GB chunks (FAT32/SMB compatible) |
| `-j2` | 2 parallel I/O threads for imaging |
| `trap EXIT` | Guaranteed unmount on any exit path (Ctrl+C, error, normal) |
| `read -e -i` | Readline editing with pre-filled default Samba path |
| `set -euo pipefail` | Strict error handling — fail fast on any error |

### 📊 WinSambaBackup Tested Results (2026-07-31)

| Parameter | Value |
|-----------|-------|
| Machine | CloudStack KVM Hypervisor |
| Disk | `/dev/sda` — 100 GB |
| Partitions | sda1 (500M NTFS System_Reserved), sda2 (39.7G NTFS WinServer2016), sda3 (59.8G NTFS DATA) |
| Windows used | ~9.3 GB before cleanup |
| Backup size | **6.1 GB** compressed (−35% of used data) |
| Duration | **~3 min** (Partclone @ 8–16 GB/min) |
| SMB target | `\\s.gincz.com\soft\ISO` |
| SMB free after | 137 GB of 247 GB |
| Status | ✅ All 3 partitions saved and restorable |

### 📋 WinSambaBackup Version History

Full details in [CHANGELOG.md](CHANGELOG.md).

| Version | Date | Key change |
|---------|------|------------|
| **v.2026.07.31j** | 2026-07-31 | Rebranded to **WinSambaBackup**; editable Samba path with pre-filled default |
| v.2026.07.31i | 2026-07-31 | Separators 90 chars; `[0]` = New Backup; no Exit option |
| v.2026.07.31h | 2026-07-31 | 7-method 1024×768 enforcement; compact single-line output |
| v.2026.07.31g | 2026-07-31 | New top-level flow: credentials → mount → list → select → action |
| v.2026.07.31f | 2026-07-31 | DELETE action added; select backup first, then `[1]` Restore / `[2]` Delete |
| v.2026.07.31e | 2026-07-31 | RESTORE submenu groundwork |
| v.2026.07.31d | 2026-07-31 | Plain-text banner (ASCII-art misaligned in KVM VNC) |
| v.2026.07.31c | 2026-07-31 | Fixed arithmetic crash in `clean_item()`; fixed `$Recycle.Bin` bash expansion |
| v.2026.07.31b | 2026-07-31 | 10-category Windows temp cleanup; smart NTFS detection; space reports |
| v.2026.07.31 | 2026-07-31 | Initial version: backup, restore, trap cleanup, dep auto-install |

---

## 🛡️ IPGuard — Triple-Layer Linux Server Security

**IPGuard** is the main security tool in this repo. It protects any Linux server with three layers:

| Layer | Tool | What it does |
|---|---|---|
| 1 | **IPGuard ipset** | Drops all IPs in shared `vladblacklist` (aggregated from 10 nodes) |
| 2 | **CrowdSec** | Pattern-based threat detection + community blocklist |
| 3 | **Fail2Ban** | SSH brute-force ban after 5 attempts / 5 min |

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/install-ipguard.sh)
```

### Security Architecture

```
Incoming connection
        |
        v
[IPGuard ipset]          -- DROP if IP is in vladblacklist
        |
        v
[CrowdSec bouncer]       -- DROP if IP is in CrowdSec decision list
        |
        v
[Fail2Ban iptables]      -- DROP if IP triggered too many SSH failures
        |
        v
[UFW rate-limit]         -- DROP if >6 connections in 30s (SMB)
        |
        v
[smb.conf / sshd]        -- Application-level auth (SMB2+, NTLMv2, no guest)
```

---

## ☁️ Cloudflare + nginx Integration

All production sites behind **Cloudflare** WAF and CDN, served via **nginx**.  
Configs include: WAF rules for WordPress protection, Bot Fight Mode, JS Challenge for suspicious IPs,
nginx dual-log for CrowdSec compatibility with Cloudflare real-IP headers.

- `222/Cloudflare_WAF_WordPress.txt` — Cloudflare WAF rules for WordPress
- `222/00-wp-protection-zones.conf` — nginx rate-limiting zones (Cloudflare + direct)
- CrowdSec nginx parser compatible with Cloudflare proxied traffic

---

## 🗂️ Samba File Sharing — 10-Node Network

All 10 servers share an identical **Samba** structure:

```
/storage/
├── soft/          <- [soft]    -- vlad RW, usr RO
└── user/          <- [user]    -- vlad RW, usr RW
```

| Share | Path | vlad | usr |
|---|---|---|---|
| `\\storage` | `/storage` | Browse | Browse |
| `\\soft` | `/storage/soft` | Read+Write | Read only |
| `\\user` | `/storage/user` | Read+Write | Read+Write |

---

## 🖥️ Linux Servers (Ubuntu 24 LTS)

| Name | IP | Provider / Role |
|---|---|---|
| DE-222 | 152.53.182.222 | NetCup Germany — FastPanel + nginx + MariaDB + Cloudflare + XRAY VPN + IPGuard |
| RU-109 | 212.109.223.109 | FastVDS Russia — FastPanel + Samba + XRAY VPN + IPGuard |
| AWS-12 | 18.195.117.12 | AWS Frankfurt — XRAY VPN + Samba + IPGuard |
| IONOS | 82.223.116.38 | IONOS — XRAY VPN + IPGuard |
| + 8 VPN nodes | 144.124.x.x / others | Samba + XRAY VPN + IPGuard (Ubuntu 24 LTS) |

---

## 🔐 XRAY VPN + CrowdSec

**XRAY VPN** server configs are maintained on all nodes.  
**CrowdSec** is integrated with nginx access logs for automatic HTTP threat detection.  
Whitelist of all trusted IPs is maintained in `222/whitelist.txt`.

---

## 💻 Windows Client — SMB_Connect.bat

See [`windows/README.md`](windows/README.md) for full description.

```
[  OK  ]  A:  AWS_12       18.195.117.12
[  OK  ]  T:  TATRA_9      144.124.232.9
[ SKIP ]  N:  PILIK_33     195.63.138.33   (server offline)
```

---

## 📜 Script Reference

### `scripts/backup_to_smb.sh` — WinSambaBackup

```bash
export LANG=C LC_ALL=C TERM=xterm-256color
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/backup_to_smb.sh \
  -o /tmp/backup_to_smb.sh && bash /tmp/backup_to_smb.sh
```

**WinSambaBackup** — bare-metal backup / restore / delete over Samba/SMB.  
Clonezilla + Partclone + pigz. See [full section above](#-winsamambabackup--windows-bare-metal-backup--restore-over-sambasmb) and [CHANGELOG.md](CHANGELOG.md).

### `blacklist/install-ipguard.sh` — IPGuard Security

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/install-ipguard.sh)
```

### `scripts/samba_setup.sh` — Samba Installer

```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_setup.sh)
```

### `scripts/samba_audit_all.sh` — Audit All Servers

```bash
bash /root/Linux_Server_Public/scripts/samba_audit_all.sh
```

### `scripts/remove_samba.sh` — Remove Samba

```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/remove_samba.sh)
```

---

## 🔍 About

**Linux server** administration toolkit by **VladiMIR Bulantsev (GinCz)** —
bash scripting, server hardening, bare-metal backup (WinSambaBackup), VPN infrastructure,
and file sharing across a 10-node Ubuntu 24 LTS fleet.

> **Stack:** WinSambaBackup · Clonezilla · Partclone · pigz · IPGuard · XRAY VPN · CrowdSec ·
> Fail2Ban · Samba · FastPanel · Cloudflare · nginx · MariaDB · iptables · ipset · UFW ·
> bash · sysadmin · DevOps · Linux administration · Ubuntu LTS · server security ·
> Windows Server backup · KVM · bare-metal backup · disk image · SMB · CIFS ·
> Samba backup · ntfs-3g · NTFS · Windows client integration · VNC console · GinCz

🔗 Related: [GinCz/Windows_scripts](https://github.com/GinCz/Windows_scripts) — Windows CMD/BAT/PowerShell utility scripts  
👤 Author: [github.com/GinCz](https://github.com/GinCz) — VladiMIR Bulantsev

---

*= Rooted by VladiMIR + AI | WinSambaBackup v.2026.07.31j | github.com/GinCz =*
