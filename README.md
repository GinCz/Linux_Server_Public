# 🐧 Linux Server Public — IPGuard · XRAY VPN · Samba · CrowdSec · Bash Scripting

> **VladiMIR Bulantsev (GinCz)** · [github.com/GinCz](https://github.com/GinCz)  
> Production scripts and configs for Ubuntu 24 LTS Linux servers.  
> All scripts are idempotent — safe to run multiple times.

**IPGuard** · **XRAY VPN** · **CrowdSec** · **Samba** · **Fail2Ban** · **FastPanel** · **Cloudflare WAF** · **nginx** · **MariaDB** · bash scripting · Linux server administration · Ubuntu 24 LTS · server hardening · DevOps · sysadmin

---

## ⚡ Quick Start

### Install IPGuard (triple-layer security)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/install-ipguard.sh)
```
**IPGuard** provides three-layer protection for any Linux server — ipset blacklist + CrowdSec + Fail2Ban.
Works on any Ubuntu 24 LTS server: web, VPN, Samba, mail, etc.

### Install Samba (file sharing + IPGuard security)
```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_setup.sh)
```
Installs Samba, creates users and shares, hardens `smb.conf`, configures UFW,
then **automatically calls IPGuard** at the end.

---

## 📁 Repository Structure

```
Linux_Server_Public/
├── blacklist/                — IPGuard security system
│   ├── install-ipguard.sh     — IPGuard installer (ipset + CrowdSec + Fail2Ban)
│   ├── deploy-blacklist.sh    — Apply/update ipset blacklist (called by cron)
│   └── blacklist.txt          — Aggregated IP blacklist from all 10 nodes
├── scripts/                  — Samba management scripts
│   ├── samba_setup.sh         — Full Samba installer
│   ├── samba_audit_all.sh     — Audit + auto-fix Samba on ALL servers via SSH
│   └── remove_samba.sh        — Remove Samba and close SMB ports
├── configs/                  — Reference server configs (MariaDB, CrowdSec, nginx)
└── windows/                  — Windows client scripts
    └── SMB_Connect.bat        — Connect all 10 Samba servers at once
```

---

## 🛡️ IPGuard — Triple-Layer Linux Server Security

**IPGuard** is the main security tool in this repo. It protects any Linux server with three layers:

| Layer | Tool | What it does |
|---|---|---|
| 1 | **IPGuard ipset** | Drops all IPs in shared `vladblacklist` (aggregated from 10 nodes) |
| 2 | **CrowdSec** | Pattern-based threat detection + community blocklist |
| 3 | **Fail2Ban** | SSH brute-force ban after 5 attempts / 5 min |

```bash
# Install IPGuard on any Ubuntu 24 LTS server
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
Configs include: WAF rules for WordPress protection, Bot Fight Mode, JS Challenge for suspicious IPs, nginx dual-log for CrowdSec compatibility with Cloudflare real-IP headers.

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
...
```

---

## 📜 Script Reference

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

## 🔐 Whitelist IPs (always allow: iptables, CrowdSec, Samba)

```
152.53.182.222   (DE server 222): FastPanel + nginx + Cloudflare + Samba + XRAY VPN + IPGuard
212.109.223.109  (RU server 109): FastPanel + Samba + XRAY VPN + IPGuard
109.234.38.47    (VPN ALEX_47):   XRAY VPN + Samba
144.124.228.237  (VPN 4TON_237):  XRAY VPN + Samba
144.124.232.9    (VPN TATRA_9):   XRAY VPN + Samba + Monitoring Kuma
144.124.228.227  (VPN SHAHIN_227): XRAY VPN + Samba
144.124.239.24   (VPN STOLB_24):  XRAY VPN + Samba + AdGuard Home
195.63.138.33    (VPN PILIK_33):  XRAY VPN + Samba
146.103.110.176  (VPN ILYA_176):  XRAY VPN + Samba
144.124.233.38   (VPN SO_38):     XRAY VPN + Samba
18.195.117.12    (AWS_12):        XRAY VPN + Samba
82.223.116.38    (IONOS):         XRAY VPN
```

---

## 🔍 About

**Linux server** administration toolkit by **VladiMIR Bulantsev (GinCz)** — bash scripting, server hardening, VPN infrastructure, and file sharing across a 10-node Ubuntu 24 LTS fleet.

> **Stack:** IPGuard · XRAY VPN · CrowdSec · Fail2Ban · Samba · FastPanel · Cloudflare · nginx · MariaDB · iptables · ipset · UFW · bash · sysadmin · DevOps · Linux administration · Ubuntu LTS · server security · Windows client integration

🔗 Related: [GinCz/Windows_scripts](https://github.com/GinCz/Windows_scripts) — Windows CMD/BAT/PowerShell utility scripts  
👤 Author profile: [github.com/GinCz](https://github.com/GinCz) — VladiMIR Bulantsev

---

*= Rooted by VladiMIR + AI | v.2026.07.12 | github.com/GinCz =*
