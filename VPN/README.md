# 🛡 VPN — AmneziaWG Infrastructure

> **= Rooted by VladiMIR | AI =**  
> Server: **222-DE-NetCup** · `152.53.182.xxx` · Ubuntu 24 / FASTPANEL  
> Last updated: **2026-04-10**

---

## 📁 Files in this folder

| File | Description |
|---|---|
| [`vpn_docker_backup.sh`](vpn_docker_backup.sh) | 🔑 **Main backup script** — backs up all 8 VPN nodes via SSH |
| [`BACKUP.md`](BACKUP.md) | 📖 Full backup documentation, cron setup, results |
| [`01_vpn_alliances_v1.0.sh`](01_vpn_alliances_v1.0.sh) | Bulk deploy script for all VPN nodes |
| [`deploy_vpn_node.sh`](deploy_vpn_node.sh) | Deploy single VPN node |
| [`deploy_bashrc.sh`](deploy_bashrc.sh) | Deploy `.bashrc` to all nodes |
| [`amnezia_stat.sh`](amnezia_stat.sh) | Show AmneziaWG peer statistics |
| [`vpn_node_clean_audit.sh`](vpn_node_clean_audit.sh) | Clean & audit VPN node |
| [`vpn_server_audit.sh`](vpn_server_audit.sh) | Full server audit |
| [`vpn_hard_shield.sh`](vpn_hard_shield.sh) | Harden VPN node firewall |
| [`quick_status.sh`](quick_status.sh) | Quick status of all nodes |
| [`infooo.sh`](infooo.sh) | Extended node info |
| [`motd_server.sh`](motd_server.sh) | MOTD banner for VPN nodes |
| [`system_backup.sh`](system_backup.sh) | System-level backup (old, per-node) |
| [`fix_node.sh`](fix_node.sh) | Emergency fix for broken node |
| [`setup.sh`](setup.sh) | Initial node setup |
| [`samba_setup.sh`](samba_setup.sh) | Samba share setup |
| [`save.sh`](save.sh) | Save config shortcut |
| [`AMNEZIA_INSTALL.md`](AMNEZIA_INSTALL.md) | AmneziaWG installation guide |
| [`AMNEZIA_SETUP.md`](AMNEZIA_SETUP.md) | AmneziaWG full setup guide |
| [`MOTD_HOWTO.md`](MOTD_HOWTO.md) | MOTD configuration guide |
| [`server-info.md`](server-info.md) | VPN server hardware info |
| [`vpn-info.md`](vpn-info.md) | VPN network info |
| [`.bashrc`](.bashrc) | Bash config deployed to VPN nodes |
| [`mc.menu`](mc.menu) | Midnight Commander menu for VPN |

---

## 🌐 VPN Node Fleet (8 nodes)

| # | Name | Last octet | Container | Extras |
|---|---|---|---|---|
| 1 | ALEX_47 | `.47` | amnezia-awg | Samba |
| 2 | 4TON_237 | `.237` | amnezia-awg | Samba, Prometheus |
| 3 | TATRA_9 | `.9` | amnezia-awg | Samba, Kuma |
| 4 | SHAHIN_227 | `.227` | amnezia-awg | Samba |
| 5 | STOLB_24 | `.24` | amnezia-awg | Samba, AdGuard Home |
| 6 | PILIK_178 | `.178` | amnezia-awg | Samba |
| 7 | ILYA_176 | `.176` | amnezia-awg | Samba |
| 8 | SO_38 | `.38` | amnezia-awg | Samba |

> ⚠️ Full IPs stored only in the **private repository**.

---

## ⚡ Quick Start

```bash
# Run backup manually
bash /root/vpn_docker_backup.sh

# Alias on server 222
f5vpn

# Check cron schedule
crontab -l | grep vpn
```

→ See [BACKUP.md](BACKUP.md) for full documentation.
