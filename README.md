# Linux Server Public — Scripts & Configs
GitHub: https://github.com/GinCz/Linux_Server_Public
Author: Ing. VladiМIR Bulantsev
Last updated: v2026-03-24

---

## Git Clone — always use SSH, never HTTPS

```bash
# CORRECT (no password prompt):
git clone git@github.com:GinCz/Linux_Server_Public.git

# WRONG (asks password every time):
# git clone https://github.com/GinCz/Linux_Server_Public.git
```

---

## MAIN RULE
Every script used on a specific server MUST be present in that server's own folder.
Each server folder is self-contained and fully independent.
Scripts MAY be duplicated across folders — this is intentional.

---

## COLOR SCHEME (SSH terminal)
- 222 EU Germany  : YELLOW       `PS1 033[01;33m`
- 109 RU Russia   : LIGHT PINK   `PS1 e[38;5;217m`
- VPN             : TURQUOISE    `PS1 e[38;5;87m`

---

## REPOSITORY STRUCTURE

```
Linux_Server_Public/
|-- 222/         <- EU Server Germany NetCup  xxx.xxx.xxx.222
|-- 109/         <- RU Server Russia FastVDS  xxx.xxx.xxx.109
|-- VPN/         <- VPN Servers AmneziaWG + WireGuard
|-- scripts/     <- Universal scripts (shared across all servers)
|-- README.md
```

---

## Aliases Quick Reference

### Shared (all servers) — from scripts/shared_aliases.sh

| Alias | = same as | Description |
|-------|-----------|-------------|
| `load` | | `git pull --rebase` + `source .bashrc` — update from GitHub |
| `save` | | `git add . && commit && push` — save to GitHub |
| `aw` | `vpnstat` | AmneziaWG / WireGuard client statistics table |
| `vpnstat` | `aw` | same as `aw` |
| `m` | `mc` | Midnight Commander file manager |
| `00` | `clear` | Clear screen |
| `banlog` | | CrowdSec: last 20 alerts |
| `la` | | `ls -A` (show hidden files) |
| `l` | | `ls -CF` (compact list) |

### Server-specific (222 and 109)

| Alias | Description |
|-------|-------------|
| `sos` | Server audit 1h |
| `sos3` | Server audit 3h |
| `sos24` | Server audit 24h |
| `sos120` | Server audit 120h (5 days) |
| `i` | Server info (infooo.sh) |
| `d` | Domain status check |
| `fight` | Block bots |
| `wpcron` | Run WordPress cron for all sites |
| `cronwp` | Same as `wpcron` |
| `watchdog` | PHP-FPM watchdog |
| `backup` | System backup |
| `antivir` | ClamAV scan |
| `mailclean` | Clean mail queue + root mailbox |

### VPN servers — from VPN/.bashrc

| Alias | Description |
|-------|-------------|
| `aw` | AmneziaWG stats (= `vpnstat`) |
| `vpnstat` | Same as `aw` |
| `sos` / `sos3` / `sos24` | VPN server audit |
| `i` | VPN server info |
| `backup` | VPN system backup |
| `load` | git pull + apply |
| `save` | git push |
| `m` | Midnight Commander |
| `00` | Clear screen |

---

## Install aliases on any NEW VPN server

```bash
clear
[ -d /root/Linux_Server_Public ] \
  && cd /root/Linux_Server_Public && git pull \
  || cd /root && git clone https://github.com/GinCz/Linux_Server_Public.git && cd Linux_Server_Public
bash VPN/01_vpn_alliances_v1.0.sh
```

---

## Fix aliases on 222 or 109 (after load)

```bash
source /root/Linux_Server_Public/scripts/shared_aliases.sh && aw
```

---

## 222/ — EU Server Germany (NetCup) xxx.xxx.xxx.222
**Specs:** 4 vCore AMD EPYC-Genoa / 8GB DDR5 ECC / 256GB NVMe / Ubuntu 24 / FastPanel / 8.60 EUR/mo
**Sites:** European WordPress sites WITH Cloudflare protection

---

## 109/ — RU Server Russia (FastVDS) xxx.xxx.xxx.109
**Specs:** 4 vCore AMD EPYC 7763 / 8GB RAM / 80GB NVMe / Ubuntu 24 LTS / FastPanel / 13 EUR/mo
**Sites:** Russian WordPress sites WITHOUT Cloudflare (direct IP)

---

## VPN/ — VPN Servers (AmneziaWG + WireGuard)
**Purpose:** Personal VPN, bypass censorship, secure tunnels
**Protocol:** AmneziaWG (obfuscated WireGuard)
**Nodes:** VPN-EU-4Ton-237, VPN-EU-Tatra-9, VPN-EU-Pilik-178

| File | Description |
|------|-------------|
| `01_vpn_alliances_v1.0.sh` | **INSTALLER** — Run on any new VPN server to clone repo + install .bashrc + apply all aliases |
| `.bashrc` | VPN server bash config: turquoise PS1, all aliases, shared_aliases source |
| `amnezia_stat.sh` | Old version (use `scripts/amnezia_stat.sh` instead) |
| `vpn_server_audit.sh` | VPN server audit (sos/sos3/sos24/sos120) |
| `infooo.sh` | VPN server info |
| `system_backup.sh` | VPN system backup |
| `setup.sh` | Initial VPN node setup |
| `vpn-info.md` | VPN documentation: nodes, commands, how to add new node |

---

## scripts/ — Universal scripts (shared across all servers)

| Script | Description |
|--------|-------------|
| `amnezia_stat.sh` | **AmneziaWG stats** — beautiful table of all WG clients with traffic (GB). Called by `aw` and `vpnstat` aliases. Works on 222, 109, all VPN servers. |
| `shared_aliases.sh` | **Universal aliases** — sourced by .bashrc on every server. Contains: load, save, aw, vpnstat, m, 00, banlog, ls, grep, la, l |
| `telegram_alert.sh` | Send Telegram message from any server |
| `crowdsec_xmlrpc_shield` | Install CrowdSec + WordPress protection + xmlrpc block |

---

Last updated: v2026-03-24
