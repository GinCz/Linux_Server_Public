# Linux Server Public

> **Rooted by VladiMIR + AI** | Public scripts for server hardening, Samba file sharing, and IPGuard security.
> All scripts are idempotent — safe to run multiple times on the same server.

---

## Quick Start

### Install Samba (file sharing + security)
```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_setup.sh)
```
Installs Samba, creates users and shares, hardens `smb.conf`, configures UFW,
then **automatically calls IPGuard** at the end — no separate security step needed.

### Install IPGuard only (security without Samba)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/install-ipguard.sh)
```
Full triple-layer protection for any server (web, VPN, mail, etc.), not just Samba.

---

## Repository Structure

```
Linux_Server_Public/
├── scripts/                  — Samba management scripts
│   ├── samba_setup.sh         — Full Samba installer (main script)
│   ├── samba_audit_all.sh     — Audit + auto-fix Samba on ALL servers via SSH
│   └── remove_samba.sh        — Remove Samba completely and close ports
└── blacklist/                — IPGuard security system
    ├── install-ipguard.sh     — IPGuard installer (authoritative, full protection)
    ├── deploy-blacklist.sh    — Apply/update the ipset blacklist (called by cron)
    └── blacklist.txt          — Aggregated IP blacklist from all 10 nodes
```

---

## Script Reference

### `scripts/samba_setup.sh`
**Full Samba installer — run this on a new server.**

```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_setup.sh)
```

What it does, step by step:
1. Installs `samba` and `samba-common-bin` via apt
2. Creates `/storage/soft` and `/storage/soft/user` directories
3. Creates Linux users `vlad` and `usr` (no shell, no home directory)
4. Sets ownership `vlad:vlad` and permissions `2770` (setgid) on both directories
5. Prompts for Samba passwords for `vlad` and `usr` (skippable if already set)
6. Writes `smb.conf` shares `[soft]` and `[user]` — removes old versions first
7. Hardens `[global]`: SMB2+ protocol, NTLMv2-only, no guest access, auth logging level 2
8. Validates config with `testparm` — restores backup if validation fails
9. Opens ports 445 and 139 in UFW with rate-limiting (6 connections / 30 seconds)
10. Downloads and runs `blacklist/install-ipguard.sh` — full IPGuard security

Share structure:
| Windows path | Linux path | vlad | usr |
|---|---|---|---|
| `\\IP\soft` | `/storage/soft` | Read+Write | Read only |
| `\\IP\user` | `/storage/soft/user` | Read+Write | Read+Write |
| `\\IP\soft\user` | `/storage/soft/user` | Read+Write | Read+Write |

> `[user]` is a direct shortcut to the `/user` subfolder inside `/storage/soft`.
> Both `\\IP\user` and `\\IP\soft\user` point to the same directory by design.

---

### `scripts/samba_audit_all.sh`
**Audit and auto-fix Samba on every server via SSH.**

```bash
bash /root/Linux_Server_Public/scripts/samba_audit_all.sh
```

Runs 19 checks on each server:
- Samba installed and running
- Linux users `vlad` and `usr` exist, `usr` is in group `vlad`
- Both users registered in Samba (`pdbedit`)
- Directories exist with correct ownership (`vlad:vlad`) and permissions (`2770`)
- Write tests: `vlad` can write to `/storage/soft`, `usr` is denied
- Write tests: both users can write to `/storage/soft/user`
- `smb.conf` has correct `[soft]` and `[user]` shares with `write list = vlad`
- Fail2Ban `samba` jail is active
- UFW has ports 445 and 139 open

Most issues are fixed automatically. Issues requiring `smbpasswd` are flagged for manual action.

Requirements: SSH key auth (passwordless root login) on all target servers.
Server list: hardcoded `RU-109` and `EU-222`, plus any servers in `/root/.server_alliances.conf`.

---

### `scripts/remove_samba.sh`
**Remove Samba completely and close SMB ports.**

```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/remove_samba.sh)
```

What it does:
- Stops and disables `smbd` and `nmbd`
- Purges `samba` and `samba-common-bin` packages
- Removes UFW rules for ports 445 and 139
- Removes CrowdSec SMB collection and acquis config
- Does NOT delete `/storage/soft` or any user data

---

### `blacklist/install-ipguard.sh`
**IPGuard — the authoritative security installer. Run on any server.**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/install-ipguard.sh)
```

Triple-layer protection:

| Layer | Tool | What it does | iptables chain |
|---|---|---|---|
| 1 | **IPGuard ipset** | Blocks all IPs in shared `vladblacklist` | pos. 1 in INPUT |
| 2 | **CrowdSec** | Pattern-based detection, community CAPI blocklist | CROWDSEC |
| 3 | **Fail2Ban** | SSH brute-force ban after 5 attempts / 5 min | f2b-sshd |

What it installs and configures:
1. `fail2ban` — jails: `sshd` (ban 2h after 5 attempts) + `sshd-ddos` (ban 24h after 20 attempts/min)
2. `crowdsec` + `crowdsec-firewall-bouncer-iptables` — collections: `sshd`, `linux`, `nginx` (if web server)
3. CrowdSec whitelist parser for all 16 trusted VladiMIR IPs
4. `ipset vladblacklist` populated from `blacklist/blacklist.txt` on GitHub
5. `iptables` rule to DROP all IPs in `vladblacklist` at position 1 in INPUT chain
6. Saves rules for persistence: `/etc/iptables/rules.v4` + `/etc/ipset.rules`
7. Cron: pull latest blacklist every 3 hours, restore ipset+iptables on reboot

Auto-detects server type:
- **FastPanel** (web server): adds nginx + wordpress + http-cve collections
- **VPN node**: SSH and linux collections only

---

### `blacklist/deploy-blacklist.sh`
**Apply or refresh the IPGuard blacklist — called by cron every 3 hours.**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh)
```

Downloads the latest `blacklist.txt` from GitHub and atomically swaps the ipset
(`vladblacklist_tmp` → `vladblacklist`). Zero downtime, no gaps in protection.
Also used manually to force an immediate blacklist update.

---

### `blacklist/blacklist.txt`
**Aggregated IP blacklist from all 10 VPN nodes.**

Maintained automatically. Every server that detects an attack adds the attacker IP
to this file. All other servers pull it every 3 hours via cron and block those IPs.
This creates a shared real-time threat intelligence network across all nodes.

---

## Security Architecture

```
Incoming connection
        │
        ▼
[IPGuard ipset]          — DROP if IP is in vladblacklist (shared from 10 nodes)
        │ (not listed)
        ▼
[CrowdSec bouncer]       — DROP if IP is in CrowdSec decision list (community + local)
        │ (not banned)
        ▼
[Fail2Ban iptables]      — DROP if IP triggered too many SSH failures
        │ (not banned)
        ▼
[UFW rate-limit]         — DROP if >6 connections in 30s (SMB only)
        │ (passes)
        ▼
[smb.conf / sshd]        — Application-level auth (SMB2+, NTLMv2, no guest)
```

---

## Samba Share Structure

Identical on all servers:

```
/storage/
└── soft/                    ← share [soft]  — vlad RW, usr RO
    └── user/                ← share [user]  — vlad RW, usr RW
```

**User permissions matrix:**

| Path | vlad | usr | Notes |
|---|---|---|---|
| `/storage/soft` | Read + Write | Read only | `write list = vlad` in smb.conf |
| `/storage/soft/user` | Read + Write | Read + Write | `usr` is in group `vlad` |

**Windows paths:**
- `\\SERVER_IP\soft` → full storage tree
- `\\SERVER_IP\user` → direct shortcut to `/storage/soft/user`
- `\\SERVER_IP\soft\user` → same directory as above

---

## Servers

| Name | IP | Role |
|---|---|---|
| RU-109 | 212.109.223.109 | Russia node — Samba + IPGuard |
| EU-222 | 152.53.182.222 | Germany node — Samba + IPGuard + FastPanel |

---

*= Rooted by VladiMIR + AI | github.com/GinCz =*
