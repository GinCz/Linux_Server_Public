# 🐧 Linux Server Public — IPGuard · XRAY VPN · Samba · CrowdSec · GinBak · Bash Scripting

> **VladiMIR Bulantsev (GinCz)** · [github.com/GinCz](https://github.com/GinCz)  
> Production scripts and configs for Ubuntu 24 LTS Linux servers.  
> All scripts are idempotent — safe to run multiple times.

**IPGuard** · **XRAY VPN** · **CrowdSec** · **Samba** · **Fail2Ban** · **FastPanel** · **Cloudflare WAF** · **nginx** · **MariaDB** · **Clonezilla** · **GinBak** · **bare-metal backup** · **SMB backup** · **disk image** · bash scripting · Linux server administration · Ubuntu 24 LTS · server hardening · DevOps · sysadmin · Windows Server backup · KVM · Partclone · pigz · NTFS · CIFS · ntfs-3g · disk imaging

---

## ⚡ Quick Start

### 💾 GinBak — Bare-Metal Backup & Restore over SMB

```bash
export LANG=C LC_ALL=C TERM=xterm-256color
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/backup_to_smb.sh \
  -o /tmp/backup_to_smb.sh && bash /tmp/backup_to_smb.sh
```

Interactive bare-metal backup and restore for Windows/Linux servers over CIFS/SMB.  
Creates compressed Clonezilla-compatible disk images directly on a network share — no local storage needed.  
Supports **backup**, **restore**, and **remote deletion** of images from a single menu.

### 🛡️ Install IPGuard (triple-layer security)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/install-ipguard.sh)
```

**IPGuard** provides three-layer protection for any Linux server — ipset blacklist + CrowdSec + Fail2Ban.  
Works on any Ubuntu 24 LTS server: web, VPN, Samba, mail, etc.

### 🗂️ Install Samba (file sharing + IPGuard security)

```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_setup.sh)
```

Installs Samba, creates users and shares, hardens `smb.conf`, configures UFW,
then **automatically calls IPGuard** at the end.

---

## 📁 Repository Structure

```
Linux_Server_Public/
├── scripts/
│   ├── backup_to_smb.sh       — GinBak: bare-metal backup/restore over SMB (Clonezilla+Partclone)
│   ├── samba_setup.sh         — Full Samba installer
│   ├── samba_audit_all.sh     — Audit + auto-fix Samba on ALL servers via SSH
│   └── remove_samba.sh        — Remove Samba and close SMB ports
├── blacklist/                — IPGuard security system
│   ├── install-ipguard.sh     — IPGuard installer (ipset + CrowdSec + Fail2Ban)
│   ├── deploy-blacklist.sh    — Apply/update ipset blacklist (called by cron)
│   └── blacklist.txt          — Aggregated IP blacklist from all 10 nodes
├── configs/                  — Reference server configs (MariaDB, CrowdSec, nginx)
├── windows/                  — Windows client scripts
│   └── SMB_Connect.bat        — Connect all 10 Samba servers at once
├── CHANGELOG.md              — Full version history of backup_to_smb.sh / GinBak
└── WORKLOG.md                — Session-by-session development log
```

---

## 💾 GinBak — Bare-Metal Backup & Restore over SMB

**GinBak** (`scripts/backup_to_smb.sh`) is an interactive bare-metal disk imaging tool built on
[Clonezilla](https://clonezilla.org/) + [Partclone](https://partclone.org/) + [pigz](https://zlib.net/pigz/).
It creates compressed, block-level disk images of a Windows or Linux server and writes them
directly to a CIFS/SMB network share — no local temp storage needed.

> **Designed for:** sysadmins who need a reliable, scriptable, single-command bare-metal backup
> tool for KVM/VPS/dedicated servers without a GUI backup solution.

### ✨ Features

- **Single `curl` command** — runs entirely from a Live/recovery system, zero installation
- **Interactive numbered menu** — lists existing backups with size and date
- **Three actions from one screen**: `[1] RESTORE` · `[2] DELETE` · `[0] New BACKUP`
- **Editable SMB path** — default pre-filled, press Enter to keep or type a new one
- **Windows temp cleanup before backup** (10 categories):
  `pagefile.sys` · `hiberfil.sys` · `swapfile.sys` · `Windows\Temp` · `Windows\Prefetch` ·
  `Windows\Logs` · `Windows\Minidump` · `SoftwareDistribution\Download` ·
  `Users\*\AppData\Local\Temp` · `$Recycle.Bin` — maximizes compression ratio
- **Smart Windows partition detection** — mounts each NTFS partition, checks for `\Windows` folder
- **Parallel gzip** via `pigz -z1p` — fast multi-core compression
- **Guaranteed cleanup** via `trap EXIT` — unmounts all NTFS and SMB on any exit path
- **7-method resolution enforcement** — forces 1024×768 on KVM/VNC consoles
- **90-char separator width** — fits any terminal ≥ 90 columns without wrapping
- **`YES` confirmation** before any destructive operation (restore or delete)
- **Auto-install** of all dependencies: `clonezilla`, `cifs-utils`, `pigz`, `ntfs-3g`
- **Timezone auto-set** to `Europe/Prague` at startup (configurable in script header)

### 🚀 How to Run

> **Requirements:** root access, Live USB / recovery system (not the OS being backed up), network connectivity to SMB share.

```bash
export LANG=C LC_ALL=C TERM=xterm-256color
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/backup_to_smb.sh \
  -o /tmp/backup_to_smb.sh && bash /tmp/backup_to_smb.sh
```

### 🔄 Interactive Flow

```
==========================================================================================
  BACKUP/SMB  |  Clonezilla+Partclone  |  v.2026.07.31j  |  github.com/GinCz
  Share: //your-server/share  |  Disk: /dev/sda
==========================================================================================
------------------------------------------------------------------------------------------
  STEP 1/4  Timezone & Console
------------------------------------------------------------------------------------------
  [OK]  TZ: Europe/Prague  CEST +0200  2026-07-31 18:57:48
  [OK]  Console: 128x48 requested (1024x768 equivalent)
------------------------------------------------------------------------------------------
  STEP 2/4  SMB Connection & Credentials
------------------------------------------------------------------------------------------
  Edit the path or press Enter to keep the default:
  SMB Path   : //s.gincz.com/soft/ISO          ← editable, press Enter to keep
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
  Found 1 backup(s):
  === [1]  WinServer2016_Backup_20260731_1605   6.1G   2026-07-31 16:07:36
------------------------------------------------------------------------------------------
  Enter backup number [1-1] to manage  ||  [0] Create new BACKUP
  Your choice: 1

  Selected: WinServer2016_Backup_20260731_1605  (6.1G)
  === [1] RESTORE -- restore to /dev/sda  ||  [2] DELETE -- remove from SMB
  Enter 1 or 2: _
```

### ⚙️ Technical Stack

| Component | Role |
|-----------|------|
| `ocs-sr savedisk` | Clonezilla disk imaging engine |
| `partclone` | Filesystem-aware block-level copy (NTFS / ext4 / FAT) |
| `pigz -z1p` | Parallel gzip compression (all CPU cores) |
| `cifs-utils` | SMB 3.0 network share mount (`vers=3.0`) |
| `ntfs-3g` | NTFS read-write access for Windows temp cleanup |
| `-i 4000` | Split image into 4 GB chunks (FAT32/SMB compatible) |
| `-j2` | 2 parallel I/O threads for imaging |
| `trap EXIT` | Guaranteed unmount on any exit path (Ctrl+C, error, normal) |
| `read -e -i` | Readline editing with pre-filled default SMB path |
| `set -euo pipefail` | Strict error handling — fail fast on any error |

### 📊 Tested Results (2026-07-31)

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

### 📋 Version History

Full details in [CHANGELOG.md](CHANGELOG.md).

| Version | Date | Key change |
|---------|------|------------|
| **v.2026.07.31j** | 2026-07-31 | Editable SMB path with pre-filled default (`read -e -i`); header re-renders after input |
| v.2026.07.31i | 2026-07-31 | Separators exactly 90 chars; `[0]` = New Backup; no Exit option |
| v.2026.07.31h | 2026-07-31 | 7-method 1024×768 enforcement; all blank lines removed; compact single-line output |
| v.2026.07.31g | 2026-07-31 | New top-level flow: credentials → mount → list → select → action |
| v.2026.07.31f | 2026-07-31 | DELETE action added; select backup first, then `[1]` Restore / `[2]` Delete |
| v.2026.07.31e | 2026-07-31 | RESTORE submenu groundwork; DELETE placeholder |
| v.2026.07.31d | 2026-07-31 | Plain-text banner (ASCII-art misaligned in KVM VNC console fonts) |
| v.2026.07.31c | 2026-07-31 | Fixed `arithmetic error` in `clean_item()`; fixed `$Recycle.Bin` bash expansion |
| v.2026.07.31b | 2026-07-31 | 10-category Windows temp cleanup; smart NTFS partition detection; space reports |
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
        │
        ▼
[IPGuard ipset]          — DROP if IP is in vladblacklist
        │
        ▼
[CrowdSec bouncer]       — DROP if IP is in CrowdSec decision list
        │
        ▼
[Fail2Ban iptables]      — DROP if IP triggered too many SSH failures
        │
        ▼
[UFW rate-limit]         — DROP if >6 connections in 30s (SMB)
        │
        ▼
[smb.conf / sshd]        — Application-level auth (SMB2+, NTLMv2, no guest)
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
├── soft/          ← [soft]    — vlad RW, usr RO
└── user/          ← [user]    — vlad RW, usr RW
```

| Share | Path | vlad | usr |
|---|---|---|---|
| `\\storage` | `/storage` | Browse | Browse |
| `\\soft` | `/storage/soft` | Read+Write | Read only |
| `\\user` | `/storage/user` | Read+Write | Read+Write |

**Windows:** `\\\\SERVER_IP\\storage` — folders `soft` and `user` visible inside.

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

**XRAY VPN** server configs are maintained on all nodes — DE-222, RU-109, AWS, and all VPN endpoints.  
**CrowdSec** is integrated with nginx access logs (dual-log format) for automatic HTTP threat detection and banning.  
Whitelist of all trusted IPs (VPN nodes, home, work) is maintained in `222/whitelist.txt`.

---

## 💻 Windows Client — SMB_Connect.bat

See [`windows/README.md`](windows/README.md) for full description.

**Quick summary:** Run as Administrator → connects all 10 Samba drives in parallel (~8 sec) with color-coded status:

```
[  OK  ]  A:  AWS_12       18.195.117.12
[  OK  ]  T:  TATRA_9      144.124.232.9
[ SKIP ]  N:  PILIK_33     195.63.138.33   (server offline)
```

---

## 📜 Script Reference

### `scripts/backup_to_smb.sh` — GinBak Bare-Metal Backup

```bash
export LANG=C LC_ALL=C TERM=xterm-256color
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/backup_to_smb.sh \
  -o /tmp/backup_to_smb.sh && bash /tmp/backup_to_smb.sh
```

Bare-metal backup / restore / delete over SMB. Clonezilla + Partclone + pigz.  
See [full section above](#-ginbak--bare-metal-backup--restore-over-smb) and [CHANGELOG.md](CHANGELOG.md).

### `blacklist/install-ipguard.sh` — IPGuard Security

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/install-ipguard.sh)
```

Triple-layer protection: IPGuard ipset + CrowdSec + Fail2Ban. Run on any Ubuntu 24 LTS server.

### `scripts/samba_setup.sh` — Samba Installer

```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_setup.sh)
```

Full Samba setup with IPGuard integration. Steps: install samba → create users → configure shares → harden smb.conf → open UFW → run IPGuard.

### `scripts/samba_audit_all.sh` — Audit All Servers

```bash
bash /root/Linux_Server_Public/scripts/samba_audit_all.sh
```

19 checks per server via SSH. Auto-fixes most issues.

### `scripts/remove_samba.sh` — Remove Samba

```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/remove_samba.sh)
```

Removes Samba and closes SMB ports. Does NOT delete `/storage` data.

---

## 🔍 About

**Linux server** administration toolkit by **VladiMIR Bulantsev (GinCz)** —
bash scripting, server hardening, bare-metal backup, VPN infrastructure,
and file sharing across a 10-node Ubuntu 24 LTS fleet.

> **Stack:** GinBak · Clonezilla · Partclone · pigz · IPGuard · XRAY VPN · CrowdSec · Fail2Ban · Samba ·
> FastPanel · Cloudflare · nginx · MariaDB · iptables · ipset · UFW · bash · sysadmin · DevOps ·
> Linux administration · Ubuntu LTS · server security · Windows Server · KVM · bare-metal backup ·
> disk image · SMB · CIFS · ntfs-3g · NTFS · Windows client integration · VNC console

🔗 Related: [GinCz/Windows_scripts](https://github.com/GinCz/Windows_scripts) — Windows CMD/BAT/PowerShell utility scripts  
👤 Author profile: [github.com/GinCz](https://github.com/GinCz) — VladiMIR Bulantsev

---

*= Rooted by VladiMIR + AI | v.2026.07.31 | github.com/GinCz =*
