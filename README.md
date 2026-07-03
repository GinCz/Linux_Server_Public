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
├── blacklist/                — IPGuard security system
│   ├── install-ipguard.sh     — IPGuard installer (authoritative, full protection)
│   ├── deploy-blacklist.sh    — Apply/update the ipset blacklist (called by cron)
│   └── blacklist.txt          — Aggregated IP blacklist from all 10 nodes
├── configs/                  — Reference server configs (MariaDB, etc.)
└── windows/                  — Windows client scripts
    └── SMB_Connect.bat        — Connect all 10 SMB servers at once (see windows/README.md)
```

---

## Samba Share Structure

> **Актуально с v2026.06.15b**

На всех 9 серверах (7 VPN + IONOS + AWS) идентичная структура:

```
/storage/
├── soft/          ← [soft]    — vlad RW, usr RO
└── user/          ← [user]    — vlad RW, usr RW
```

Windows видит **три шары** на каждом сервере:

| Шара          | Linux путь        | vlad        | usr         | Описание                        |
|---------------|-------------------|-------------|-------------|---------------------------------|
| `\storage`    | `/storage`        | browse only | browse only | Корень — показывает soft и user |
| `\storage\soft` → `\soft` | `/storage/soft` | Read+Write  | Read only   | Основное хранилище |
| `\storage\user` → `\user` | `/storage/user` | Read+Write  | Read+Write  | Пользовательский каталог |

**Windows путь для подключения:** `\\SERVER_IP\storage`  
Внутри автоматически видны папки `soft` и `user`.

---

## Servers (все 10 нод)

| Windows имя | IP               | Диск | Провайдер / Роль         |
|-------------|------------------|------|---------------------------|
| AWS_42      | 3.79.14.42       | K:   | AWS Frankfurt             |
| IONOS_38    | 82.223.116.38    | L:   | IONOS (ICMP заблокирован) |
| ILYA_176    | 146.103.110.176  | I:   | VPN нода                  |
| PILIK_178   | 91.84.118.178    | N:   | Резервный сервер          |
| 4TON_237    | 144.124.228.237  | O:   | VPN нода                  |
| SO_38       | 144.124.233.38   | Q:   | VPN нода                  |
| TATRA_9     | 144.124.232.9    | T:   | VPN нода                  |
| SHAHIN_227  | 144.124.228.227  | V:   | VPN нода                  |
| STOLB_24    | 144.124.239.24   | W:   | VPN нода                  |
| ALEX_47     | 109.234.38.47    | Y:   | VPN нода                  |

> **Управляющий сервер:** EU-222 (152.53.182.222) — NetCup Germany, FastPanel + Cloudflare  
> **RU-109** (212.109.223.109) — FastVDS Russia, FastPanel

---

## Whitelist IPs (всегда разрешать: iptables, CrowdSec, Samba)

| Имя           | IP                  | Описание                                      |
|---------------|---------------------|-----------------------------------------------|
| DE_222        | 152.53.182.222      | DE server: FastPanel+CloudFlare+Samba+XRAY+CryptoBot |
| RU_109        | 212.109.223.109     | RU server: FastPanel+Samba+XRAY               |
| ALEX_47       | 109.234.38.47       | VPN: XRAY + Samba                             |
| 4TON_237      | 144.124.228.237     | VPN: XRAY + Samba                             |
| TATRA_9       | 144.124.232.9       | VPN: XRAY + Samba + Monitoring Kuma           |
| SHAHIN_227    | 144.124.228.227     | VPN: AmneziaWG + Samba                        |
| STOLB_24      | 144.124.239.24      | VPN: XRAY + Samba + AdGuard Home              |
| PILIK_33      | 195.63.138.33       | VPN: XRAY + Samba                             |
| ILYA_176      | 146.103.110.176     | VPN: XRAY + Samba                             |
| SO_38         | 144.124.233.38      | VPN: XRAY + Samba                             |
| AWS_42        | 3.79.14.42          | AWS: XRAY                                     |
| IONOS_38      | 82.223.116.38       | IONOS: XRAY                                   |
| HOME          | 185.100.197.XX      | Home IP (dynamic range)                       |
| WORK          | 90.181.133.10       | Work IP                                       |
| **POHODA**    | **87.199.206.79**   | **Windows Server 2019, Pohoda accounting** *(added 2026-07-03)* |

---

## Script Reference

### `scripts/samba_setup.sh`
**Full Samba installer — run this on a new server.**

```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_setup.sh)
```

What it does, step by step:
1. Installs `samba` and `samba-common-bin` via apt
2. Creates `/storage/soft` and `/storage/user` directories
3. Creates Linux users `vlad` and `usr` (no shell, no home directory)
4. Sets ownership `vlad:vlad` and permissions `2770` (setgid) on all directories
5. Prompts for Samba passwords for `vlad` and `usr` (skippable if already set)
6. Writes `smb.conf` with shares `[storage]`, `[soft]`, `[user]`
7. Hardens `[global]`: SMB2+ protocol, NTLMv2-only, no guest access, auth logging level 2
8. Validates config with `testparm` — restores backup if validation fails
9. Opens ports 445 and 139 in UFW with rate-limiting (6 connections / 30 seconds)
10. Downloads and runs `blacklist/install-ipguard.sh` — full IPGuard security

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
- Write tests for both users on both directories
- `smb.conf` shares correct
- Fail2Ban `samba` jail active
- UFW ports 445 and 139 open

Most issues are fixed automatically.

---

### `scripts/remove_samba.sh`
**Remove Samba completely and close SMB ports.**

```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/remove_samba.sh)
```

Does NOT delete `/storage` or any user data.

---

### `blacklist/install-ipguard.sh`
**IPGuard — triple-layer security. Run on any server.**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/install-ipguard.sh)
```

| Layer | Tool | What it does |
|---|---|---|
| 1 | **IPGuard ipset** | Blocks all IPs in shared `vladblacklist` |
| 2 | **CrowdSec** | Pattern-based detection + community blocklist |
| 3 | **Fail2Ban** | SSH brute-force ban after 5 attempts / 5 min |

---

## Security Architecture

```
Incoming connection
        │
        ▼
[IPGuard ipset]          — DROP if IP is in vladblacklist (shared from 10 nodes)
        │
        ▼
[CrowdSec bouncer]       — DROP if IP is in CrowdSec decision list
        │
        ▼
[Fail2Ban iptables]      — DROP if IP triggered too many SSH failures
        │
        ▼
[UFW rate-limit]         — DROP if >6 connections in 30s (SMB only)
        │
        ▼
[smb.conf / sshd]        — Application-level auth (SMB2+, NTLMv2, no guest)
```

---

*= Rooted by VladiMIR + AI | v2026.07.03 | github.com/GinCz =*
