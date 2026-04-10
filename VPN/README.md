# 🔐 VPN/ — AmneziaWG VPN Infrastructure

> All scripts, configs, and documentation for the AmneziaWG VPN node network.  
> Nodes run Docker-based AmneziaWG (AWG). Managed from server 222-DE-NetCup.

---

## 🗺️ VPN Node Overview

| Node | IP Mask | Location | Status | Provider |
|---|---|---|---|---|
| Node 47 | 10.8.0.x | Main hub | ✅ Active | — |
| Node 2 | 10.8.1.x | — | ✅ Active | — |
| Node 3 | 10.8.2.x | — | ✅ Active | — |
| Node 4 | 10.8.3.x | — | ✅ Active | — |
| Node 5 | 10.8.4.x | — | ✅ Active | — |
| Node 6 | 10.8.5.x | — | ✅ Active | — |
| Node 7 | 10.8.6.x | — | ✅ Active | — |
| Node 8 | 10.8.7.x | — | ✅ Active | — |

> Node IPs and credentials are stored in the **private** `Secret_Privat` repository only.

---

## 📂 Files in This Folder

### 🔧 Shell Scripts

| File | Description |
|---|---|
| `vpn_docker_backup.sh` | **Main backup script** — backs up all AWG Docker volumes to AWS S3. Runs daily at 03:30. Keeps last 7 archives. |
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
| `BACKUP.md` | Full backup system documentation: how `vpn_docker_backup.sh` works, cron setup, restore procedure, real run example from 2026-04-10. |
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
- Docker Compose files
- Server configs (UFW rules, cron, SSH keys)

### Backup destination:
- **AWS S3** bucket (credentials in private repo)
- Daily at **03:30** via root cron
- Last **7 backups** kept per node (older auto-deleted)

### Cron setup:
```bash
# Check current cron:
crontab -l | grep backup

# Add if missing:
crontab -e
# Add line:
30 3 * * * /bin/bash /root/Linux_Server_Public/VPN/vpn_docker_backup.sh >> /var/log/vpn_backup.log 2>&1
```

### Run manually:
```bash
bash /root/Linux_Server_Public/VPN/vpn_docker_backup.sh
```

### View backup log:
```bash
tail -50 /var/log/vpn_backup.log
```

### Restore from S3:
```bash
# List available backups:
aws s3 ls s3://YOUR-BUCKET/vpn-backups/

# Download specific backup:
aws s3 cp s3://YOUR-BUCKET/vpn-backups/vpn_backup_2026-04-10_03-30.tar.gz /root/restore/

# Extract and restore:
tar -xzf /root/restore/vpn_backup_*.tar.gz -C /root/restore/
# Then restore Docker volumes manually from extracted data
```

> 📖 Full restore procedure: see `BACKUP.md`

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

# 7. Setup backup:
# → Follow: VPN/BACKUP.md
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
