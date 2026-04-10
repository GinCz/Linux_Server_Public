# 🔐 VPN/ — AmneziaWG VPN Infrastructure

> All scripts, configs, and documentation for the AmneziaWG VPN node network.  
> Nodes run Docker-based AmneziaWG (AWG). Managed from server 222-DE-NetCup.

---

## 🗺️ VPN Node Overview

| Node name | IP Mask | Services | Status |
|---|---|---|---|
| ALEX_47 | `xxx.xxx.xx.47` | AmneziaWG + Samba | ✅ Active |
| 4TON_237 | `xxx.xxx.xxx.237` | AmneziaWG + Samba + Prometheus | ✅ Active |
| TATRA_9 | `xxx.xxx.xxx.9` | AmneziaWG + Samba + Kuma Monitoring | ✅ Active |
| SHAHIN_227 | `xxx.xxx.xxx.227` | AmneziaWG + Samba | ✅ Active |
| STOLB_24 | `xxx.xxx.xxx.24` | AmneziaWG + Samba + AdGuard Home | ✅ Active |
| PILIK_178 | `xx.xx.xxx.178` | AmneziaWG + Samba | ✅ Active |
| ILYA_176 | `xxx.xxx.xxx.176` | AmneziaWG + Samba | ✅ Active |
| SO_38 | `xxx.xxx.xxx.38` | AmneziaWG + Samba | ✅ Active |

> Real IPs and SSH credentials are stored in the **private** `Secret_Privat` repository only.

---

## 📂 Files in This Folder

### 🔧 Shell Scripts

| File | Description |
|---|---|
| `vpn_docker_backup.sh` | **Main backup script** — backs up all AWG Docker volumes via SSH. Runs Wed+Sat at 03:30 via cron. Keeps last 7 archives per node. |
| `amnezia_stat.sh` | Shows connected VPN clients, traffic stats, and peer status for all nodes. |
| `deploy_vpn_node.sh` | Full automated setup of a new VPN node (Docker, AWG, firewall, aliases). |
| `deploy_bashrc.sh` | Deploys `.bashrc` with all aliases to a remote VPN node via SSH. |
| `fix_node.sh` | Quick fix script for common VPN node issues (Docker restart, AWG reconnect). |
| `setup.sh` | Initial server setup (UFW firewall, fail2ban, locale, timezone). |
| `system_backup.sh` | System-level backup (OS configs, cron, keys) — complement to Docker backup. |
| `vpn_server_audit.sh` | Security audit of VPN node: open ports, running services, auth.log analysis. |
| `vpn_node_clean_audit.sh` | Cleanup + audit combo: removes old logs, checks disk, verifies services. |
| `vpn_hard_shield.sh` | Hardens VPN node firewall: blocks all ports except SSH and AWG. |
| `01_vpn_alliances_v1.0.sh` | Manages peer alliances between VPN nodes (routing between nodes). |
| `infooo.sh` | Displays full server info: CPU, RAM, disk, uptime, Docker containers. |
| `quick_status.sh` | Fast one-screen status: services, Docker, disk, load average. |
| `save.sh` | Saves local changes to the GitHub repo (`git add -A && git commit && git push`). |
| `samba_setup.sh` | Optional Samba share setup for VPN node file access. |
| `motd_server.sh` | MOTD banner displayed at SSH login — shows server name, alias cheatsheet. |

### ⚙️ Config Files

| File | Description |
|---|---|
| `.bashrc` | Root user aliases for VPN nodes: `aw`, `awstat`, `mc`, `save`, `gs`, etc. |
| `mc.menu` | Midnight Commander user menu with quick actions for VPN management. |

### 📖 Documentation

| File | Description |
|---|---|
| `README.md` | **This file** — index of the VPN folder. |
| `BACKUP.md` | Full backup system documentation: how `vpn_docker_backup.sh` works, cron setup, restore procedure, real run results from 2026-04-10. |
| `AMNEZIA_INSTALL.md` | Step-by-step AmneziaWG installation guide (Docker method). |
| `AMNEZIA_SETUP.md` | Full AWG configuration guide: peers, keys, client export, split tunneling. |
| `MOTD_HOWTO.md` | How to edit the MOTD banner on VPN nodes. |
| `server-info.md` | VPN node server specifications, provider info, monthly costs. |
| `vpn-info.md` | AWG VPN protocol details, port configuration, client setup instructions. |

---

## 💾 Backup System — Quick Reference

The automated backup system uses `vpn_docker_backup.sh` to protect all AWG Docker data.

### What gets backed up:
- AWG Docker volumes (peer configs, keys, WireGuard state)
- Docker container image snapshot (`docker commit` + `docker save`)
- Server configs (UFW rules, cron, SSH keys) via `system_backup.sh`

### Backup destination:
- **Local storage** on server 222: `/BACKUP/vpn/<node-name>/`
- Daily **Wed + Sat at 03:30** via root cron on server 222
- Last **7 backups** kept per node (older auto-deleted)

### Current results (2026-04-10 first run):
- 8/8 nodes ✔ — 0 errors
- Total: **227M** in **53 seconds**
- Each archive: **~13 MB**

### Cron setup (server 222):
```bash
# Check:
crontab -l | grep backup

# Add if missing:
crontab -l | grep -v 'vpn_docker_backup' | \
  { cat; echo "30 3 * * 3,6  bash /root/vpn_docker_backup.sh >> /var/log/vpn_backup.log 2>&1"; } \
  | crontab - && echo "✔ Done"
```

### Run manually:
```bash
bash /root/vpn_docker_backup.sh
# or via alias:
f5vpn
```

### View log:
```bash
tail -50 /var/log/vpn_backup.log
```

### Check archives:
```bash
for d in /BACKUP/vpn/*/; do echo "$(ls $d*.tar.gz 2>/dev/null | wc -l) — $d"; done
```

> 📖 Full restore procedure: see [BACKUP.md](BACKUP.md)

---

## 🚀 Quick Start — New VPN Node

```bash
# 1. SSH into new node:
ssh root@NEW_NODE_IP

# 2. Clone repo:
git clone https://github.com/GinCz/Linux_Server_Public.git /root/Linux_Server_Public

# 3. Run initial setup:
bash /root/Linux_Server_Public/VPN/setup.sh

# 4. Deploy aliases:
bash /root/Linux_Server_Public/VPN/deploy_bashrc.sh
source /root/.bashrc

# 5. Deploy MOTD:
cp /root/Linux_Server_Public/VPN/motd_server.sh /etc/profile.d/motd_server.sh
chmod +x /etc/profile.d/motd_server.sh

# 6. Install AmneziaWG (Docker):
# → Follow: VPN/AMNEZIA_INSTALL.md

# 7. Add SSH key from server 222:
# On server 222: ssh-copy-id -i /root/.ssh/id_ed25519 root@NEW_NODE_IP
# Verify: ssh -i /root/.ssh/id_ed25519 -o BatchMode=yes root@NEW_NODE_IP "echo OK"

# 8. Add new node to vpn_docker_backup.sh SERVERS array
```

---

## 🔗 Related Documentation

- 📋 [Full Backup Guide](BACKUP.md)
- 📋 [AmneziaWG Installation](AMNEZIA_INSTALL.md)
- 📋 [AmneziaWG Configuration](AMNEZIA_SETUP.md)
- 📋 [MOTD How-To](MOTD_HOWTO.md)
- 📋 [Root README](../README.md)
- 📋 [CHANGELOG](../CHANGELOG.md)

---

*= Rooted by VladiMIR | AI =*
