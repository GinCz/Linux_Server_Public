# 📂 scripts/ — Samba Management Scripts

> = Rooted by VladiMIR + AI | v2026.07.11 | github.com/GinCz =

---

## 📦 samba_setup.sh

**Current version:** `v2026.06.15c`
**Run as:** root
**Idempotent:** yes — safe to run multiple times on the same server

```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_setup.sh)
```

### What the script does (steps)

1. **Install Samba** — `samba` + `samba-common-bin` + `python3` via apt (if not already installed)
2. **Directories** — creates `/storage`, `/storage/soft`, `/storage/user`
3. **Migration** — automatically moves files from `/storage/soft/user` → `/storage/user` (if the old structure still exists)
4. **Users** — creates `vlad` and `usr` (no shell, no home); `usr` is added to group `vlad`
5. **Directory permissions** — `vlad:vlad` owner, `2770` (setgid) on `soft` and `user`, `0770` on `/storage`
6. **Samba passwords** — prompts for `vlad` and `usr` (press Enter to skip if already set)
7. **smb.conf** — written in full with `[storage]` + `[soft]` + `[user]`; validated via `testparm`; backup restored on error
8. **UFW** — opens ports 445 and 139 with rate-limit of 6 connections per 30 seconds
9. **IPGuard** — runs `blacklist/install-ipguard.sh` — full triple-layer protection

### Share structure

```
/storage/
├── soft/          ← [soft]     vlad RW, usr RO
└── user/          ← [user]     vlad RW, usr RW
         ^-- [storage] — browse-only root (shows soft\ and user\ in Windows)
```

### 🔒 Permissions matrix

| Path | Linux path | vlad | usr | Notes |
|---|---|---|---|---|
| `\\IP\storage` | `/storage` | browse only | browse only | Root — soft\ and user\ visible |
| `\\IP\soft` | `/storage/soft` | Read+Write | Read only | Files/software |
| `\\IP\user` | `/storage/user` | Read+Write | Read+Write | Shared folder |

### Linux-level permissions

| Directory | owner | group | chmod | Reason |
|---|---|---|---|---|
| `/storage` | vlad:vlad | vlad | 0770 | Root — no direct file creation |
| `/storage/soft` | vlad:vlad | vlad | 2770 | setgid: new files inherit group |
| `/storage/user` | vlad:vlad | vlad | 2770 | setgid: usr can write (is in group vlad) |

> `usr` is a member of group `vlad` — this grants write access to `/storage/user` at the Linux level.
> Access to `/storage/soft` is restricted to read-only for `usr` via `write list = vlad` in smb.conf.

### smb.conf (key `[global]` parameters)

| Parameter | Value | Purpose |
|---|---|---|
| `server min protocol` | SMB2 | Disables SMB1 (CVE-2017-0144, EternalBlue) |
| `ntlm auth` | yes | Required for Windows compatibility |
| `map to guest` | never | No anonymous/guest access |
| `max smbd processes` | 100 | Protection against connection flooding |
| `log level` | 2 | Required by Fail2Ban for auth failure detection |
| `invalid users` | root bin... | Blocks system users |

### 📅 Changelog

| Version | Date | Changes |
|---|---|---|
| v2026.06.15c | 2026-06-15 | New structure: `[storage]`+`[soft]`+`[user]`; `/storage/soft` and `/storage/user` separate; auto-migration; full smb.conf rewrite |
| v2026.06.14b | 2026-06-14 | Old structure: `[soft]`+`[user]`; `/storage/soft/user` inside soft |

---

## 🔍 samba_audit_all.sh

**Audit and auto-fix Samba on all servers via SSH.**

```bash
bash /root/Linux_Server_Public/scripts/samba_audit_all.sh
```

Runs 19 checks per server. Most issues are fixed automatically.

---

## 🗑️ remove_samba.sh

**Completely remove Samba and close SMB ports.**

```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/remove_samba.sh)
```

`/storage` and all user data are NOT deleted.

---

*= Rooted by VladiMIR + AI | v2026.07.11 | github.com/GinCz =*
