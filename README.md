# Linux Server Public — Scripts & Configs
GitHub: https://github.com/GinCz/Linux_Server_Public
Author: Ing. VladiМIR Bulantsev
Last updated: v2026-03-25

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

## BACKUP SYSTEM (updated 2026-03-25)

All servers back up via user `vlad` (password in Secret_Privat repo).
No root SSH required — sshpass used with vlad credentials.

| Server | Local copy | Remote copy | Folder on 222 |
|--------|-----------|-------------|---------------|
| 222-EU | `/BackUP/222/` (on self) | `/BackUP/222/` on 109 | — |
| 109-RU | `/BackUP/109/` (on self) | `/BackUP/109/` on 222 | ✅ |
| VPN-*  | — | `/BackUP/VPN/` on 222 | ✅ |
| AWS    | — | `/BackUP/AWS/` on 222 | ✅ (future) |

- Rotation: **10 last backups** per server, older deleted automatically
- Telegram notification on success and failure
- Run via alias: `backup` on any server
- Archive includes: `/etc` + `/root` + `/usr/local/fastpanel2`
- Excludes: `.git` sessions cache www-data

### Setup user vlad on storage server (one time):
```bash
useradd -m -s /bin/bash vlad
echo "vlad:sa4434" | chpasswd
mkdir -p /BackUP/{222,109,VPN,AWS}
chown -R vlad:vlad /BackUP
chmod 755 /BackUP
mkdir -p /home/vlad/.ssh
chmod 700 /home/vlad/.ssh
chown -R vlad:vlad /home/vlad/.ssh
```

### Test connection from any server to 222:
```bash
sshpass -p "sa4434" ssh -o StrictHostKeyChecking=no vlad@xxx.xxx.xxx.222 "echo OK && ls /BackUP/"
```

---

## Aliases Quick Reference

### Shared (all servers) — from scripts/shared_aliases.sh

| Alias | Description |
|-------|-------------|
| `load` | `git pull --rebase` + `source .bashrc` — update from GitHub |
| `save` | `git add . && commit && push` — save to GitHub |
| `aw` | AmneziaWG / WireGuard client statistics table |
| `00` | Clear screen |
| `la` | `ls -A` (show hidden files) |
| `l` | `ls -CF` (compact list) |

### Server 222 & 109 specific

| Alias | Description |
|-------|-------------|
| `sos` / `sos3` / `sos24` / `sos120` | Server audit 1h / 3h / 24h / 5 days |
| `infooo` | Full server info + benchmark |
| `fight` | Block bots |
| `wpcron` | Run WordPress cron for all sites |
| `backup` | System backup (local + remote) |
| `antivir` | ClamAV scan |
| `mailclean` | Clean mail queue |
| `banlog` | CrowdSec: last 20 alerts |
| `audit` | Security audit |
| `domains` | Domain status check |
| `cleanup` | Disk cleanup |
| `wphealth` | WordPress health check |

### VPN servers — from VPN/.bashrc

| Alias | Description |
|-------|-------------|
| `aw` | AmneziaWG stats |
| `audit` | VPN load + attack monitor |
| `infooo` | VPN server info |
| `backup` | VPN system backup → 222 |
| `load` | git pull + apply |
| `save` | git push |
| `00` | Clear screen |
| `la` | list files |

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

## 222/ — EU Server Germany (NetCup) xxx.xxx.xxx.222
**Specs:** 4 vCore AMD EPYC-Genoa / 8GB DDR5 ECC / 256GB NVMe / Ubuntu 24 / FastPanel / 8.60 EUR/mo  
**Sites:** European WordPress sites WITH Cloudflare protection  
**Backup:** local `/BackUP/222/` + copy to 109  
**Scripts:** `system_backup.sh` `infooo.sh` `.bashrc` `server-info.md`

---

## 109/ — RU Server Russia (FastVDS) xxx.xxx.xxx.109
**Specs:** 4 vCore AMD EPYC 7763 / 8GB RAM / 80GB NVMe / Ubuntu 24 LTS / FastPanel / 13 EUR/mo  
**Sites:** Russian WordPress sites WITHOUT Cloudflare (direct IP)  
**Backup:** local `/BackUP/109/` + copy to 222  
**Scripts:** `system_backup.sh` `infooo.sh` `.bashrc` `server-info.md`

---

## VPN/ — VPN Servers (AmneziaWG + WireGuard)
**Purpose:** Personal VPN, bypass censorship, secure tunnels  
**Protocol:** AmneziaWG (obfuscated WireGuard)  
**Nodes:** VPN-EU-Alex-47, VPN-EU-4Ton-237, VPN-EU-Tatra-9, VPN-EU-Pilik-178  
**Backup:** `/BackUP/VPN/` on server 222 via user vlad  

| File | Description |
|------|-------------|
| `01_vpn_alliances_v1.0.sh` | **INSTALLER** — Run on any new VPN server |
| `.bashrc` | VPN server bash config: turquoise PS1, all aliases |
| `amnezia_stat.sh` | WG client stats |
| `vpn_node_clean_audit.sh` | VPN audit: load, network, disk, processes |
| `infooo.sh` | VPN server info |
| `system_backup.sh` | VPN backup → 222 via vlad |
| `setup.sh` | Initial VPN node setup |
| `vpn-info.md` | VPN documentation |

---

## scripts/ — Universal scripts (shared across all servers)

| Script | Description |
|--------|-------------|
| `amnezia_stat.sh` | AmneziaWG stats table — called by `aw` alias |
| `shared_aliases.sh` | Universal aliases sourced by .bashrc on every server |
| `telegram_alert.sh` | Send Telegram message from any server |

---

## = Rooted by VladiMIR | AI =
Last updated: v2026-03-25
