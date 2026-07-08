# Samba Setup — Documentation
> = Rooted by VladiMIR + AI | v2026.07.04 | github.com/GinCz =

## Overview

Complete Samba installer for Ubuntu 24 / FASTPANEL servers.  
Idempotent — safe to run multiple times on any server.

## Quick Install

```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_setup.sh)
```

## Share Structure

```
/storage            →  [storage]  browse-only root (shows soft + user)
/storage/soft       →  [soft]     vlad: RW  |  usr: RO
/storage/user       →  [user]     vlad: RW  |  usr: RW
```

### Windows Access

```
\\<IP>\storage   → /storage         (browse root — see soft\ and user\)
\\<IP>\soft      → /storage/soft    (software/executables — usr read-only)
\\<IP>\user      → /storage/user    (shared RW folder for all users)
```

## Users

| User | Linux shell | Samba role | soft\ | user\ |
|------|-------------|------------|-------|-------|
| `vlad` | `/sbin/nologin` | owner/admin | RW | RW |
| `usr`  | `/sbin/nologin` | limited user | RO | RW |
| `zlat` | `/sbin/nologin` | extra user (add manually) | RW | RW |

> **Note:** `zlat` is NOT created by the installer — add manually after install:
> ```bash
> useradd -M -s /sbin/nologin zlat
> usermod -aG vlad zlat
> smbpasswd -a zlat
> # Then add zlat to smb.conf: valid users, write list
> ```

## Folder Permissions

```
drwxr-xr-x  vlad:vlad  0775   /storage
drwxr-sr-x  vlad:vlad  2775   /storage/soft    (setgid — files inherit group vlad)
drwxrwsr-x  vlad:vlad  2775   /storage/user    (setgid — files inherit group vlad)
```

## smb.conf Key Settings

```ini
create mask       = 0775   # Files get rwxrwxr-x — execute bit IS set!
directory mask    = 0775
force create mode = 0775   # Overrides ACL/FASTPANEL restrictions
force directory mode = 0775
server min protocol = SMB2
map to guest = never
ntlm auth = yes
```

> **Critical fix (v2026.07.04):**  
> Previous versions used `create mask = 0664` which blocked execution of `.exe`, `.sh`, `.bat` etc.  
> Changed to `0775` + added `force create mode = 0775` to guarantee execute bits.

## Security Layers

| Layer | Tool | Action |
|-------|------|--------|
| 1 | **Fail2Ban** | Ban IP after 3 failed auth / 1 hour |
| 2 | **CrowdSec** | Community blocklist + CAPI sharing |
| 3 | **IPGuard ipset** | Shared `vladblacklist` across all 10 nodes |
| 4 | **smb.conf** | SMB2+, NTLMv2 only, no guest, auth logging |
| 5 | **UFW rate-limit** | 6 connections/30s on ports 445/139 |

## Whitelist IPs (always preserved)

```
152.53.182.222   DE server 222
212.109.223.109  RU server 109
109.234.38.47    VPN ALEX_47
144.124.228.237  VPN 4TON_237
144.124.232.9    VPN TATRA_9
144.124.228.227  VPN SHAHIN_227
144.124.239.24   VPN STOLB_24
195.63.138.33    VPN PILIK_33
146.103.110.176  VPN ILYA_176
144.124.233.38   VPN SO_38
3.79.14.42       AWS XRAY
82.223.116.38    IONOS XRAY
```

## Changelog

### v2026.07.04
- `create mask` changed `0664 → 0775` — **execute bit fix** (exe/sh files now executable via Samba)
- `force create mode = 0775` added (cannot be overridden by ACL/FASTPANEL)
- `force directory mode = 0775` added
- `/storage` chmod `0770 → 0775` (Windows can now browse root share)
- `/storage/soft` and `/storage/user` chmod `2770 → 2775`
- `acl allow execute always = yes` replaced by `force create mode` (more reliable)
- Migration from old structure: `/storage/soft/user → /storage/user`

### v2026.06.14b
- Added [storage] browse-root share
- Separated [user] from [soft] directory
- Added IPGuard integration at end of setup

### v2026.06.14
- Initial release: [soft] + [user] shares
- Fail2Ban + CrowdSec + UFW rate-limit

## Remote Fix Script

To push correct Samba config from server 222 to ALL other servers at once:

```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_fix_remote.sh)
```

See `samba_fix_remote.sh` in the same directory.

## Related Scripts

| Script | Purpose |
|--------|---------|
| `samba_setup.sh` | Full install/reinstall |
| `samba_fix_remote.sh` | Push fix to all servers via SSH from 222 |
| `samba_audit_all.sh` | Audit Samba on all servers |
| `remove_samba.sh` | Clean uninstall |
