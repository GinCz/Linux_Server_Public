# 🗄️ VPN_Amnezia — Archive: AmneziaWG & VPN Legacy Configurations

> **Archive Note:** Historical configuration archive for AmneziaWG setups. Production servers have been fully migrated to standardized **Xray Core** and **AdGuard Home**.
> = Rooted by VladiMIR + AI | v.2026.08.21 | github.com/GinCz =

---

## 🔖 Quick Navigation

| Topic | File |
|-------|------|
| **3x-ui + XRAY REALITY — key locations, Hiddify setup, Russia/EU routing** | [📖 3XUI_XRAY_README.md](./3XUI_XRAY_README.md) |
| AmneziaWG — full setup guide | [AMNEZIA_SETUP.md](./AMNEZIA_SETUP.md) |
| Backup & Restore | [BACKUP.md](./BACKUP.md) |
| SOS / Emergency Recovery | [SOS_VPN.md](./SOS_VPN.md) |
| MOTD setup | [MOTD_HOWTO.md](./MOTD_HOWTO.md) |
| Server 237 — specific notes | [VPN_237_README.md](./VPN_237_README.md) |

---

## Overview

This directory contains scripts and configuration files for managing VPN servers running:
- **AmneziaWG** (obfuscated WireGuard) via Docker
- **Xray VLESS Reality** (anti-DPI VPN for RU/CIS access)
- **AdGuard Home** (DNS-level ad blocking)
- **Samba** (internal file sharing — installed on **all** VPN servers)
- **CrowdSec** (intrusion detection & IP banning)
- **ClamAV** (on-demand antivirus)
- **vnstat** (monthly traffic statistics from the 1st of each month)

---

## Server List

| Hostname | IP | Stack |
|---|---|---|
| VPN-EU-Alex-47 | 212.34.148.51 | Xray VLESS REALITY + 3x-ui + Samba |
| VPN-EU-4Ton-237 | 144.124.228.237 | Xray VLESS + Samba |
| VPN-EU-Tatra-9 | 144.124.232.9 | AmneziaWG + AdGuard + Samba |
| VPN-EU-Pilik-178 | 195.63.138.33 | AmneziaWG + AdGuard + Samba |
| VPN-EU-Shahin-227 | 144.124.228.227 | AmneziaWG + AdGuard + Samba |
| VPN-EU-Stolb-24 | 144.124.239.24 | AmneziaWG + AdGuard + Samba |
| VPN-EU-Ilya-176 | 146.103.110.176 | AmneziaWG + AdGuard + Samba |
| VPN-EU-So-38 | 144.124.233.38 | AmneziaWG + AdGuard + Samba |
| VPN-IONOS-38 | 82.223.116.38 | Xray VLESS REALITY + 3x-ui |

> Panel logins/passwords — stored in private repository `Secret_Privat`.

---

## 🔑 3x-ui — REALITY Key Locations (Quick Cheatsheet)

| What | Path |
|------|------|
| **Database (x-ui.db)** | `/etc/x-ui/x-ui.db` |
| **XRAY config** | `/usr/local/x-ui/bin/config.json` |
| **REALITY keys** | Stored **in x-ui.db**, managed via panel → Edit Inbound → Security → Reality |
| XRAY binary | `/usr/local/x-ui/bin/xray-linux-amd64` |
| Logs | `journalctl -u x-ui -n 50` |

> ⚠️ `config.json` contains **only `privateKey`**. `publicKey` is not stored in the file — it is derived from the private key.  
> Get publicKey: `/usr/local/x-ui/bin/xray-linux-amd64 x25519 -i YOUR_PRIVATE_KEY`

> 📖 **Full documentation:** [3XUI_XRAY_README.md](./3XUI_XRAY_README.md)

---

## 🔄 Daily Reboot Schedule

All VPN servers reboot automatically every day at **03:00 AM CET/CEST (Europe/Amsterdam)**.

```bash
timedatectl set-timezone Europe/Amsterdam && systemctl restart systemd-timesyncd && (crontab -l 2>/dev/null | grep -v "reboot"; echo "0 3 * * * /sbin/reboot") | crontab -
```

**Verify:**
```bash
timedatectl
crontab -l | grep reboot
```

**Remove:**
```bash
(crontab -l 2>/dev/null | grep -v "reboot") | crontab -
```

---

## 📊 Monthly Traffic (vnstat)

```bash
vnstat -m                               # monthly totals
vnstat --begin $(date +%Y-%m-01)        # from 1st of current month
vnstat -i ens3 -m                       # specific interface
```

> ⚠️ vnstat starts counting from the day of installation.

---

## Directory Structure

```
VPN/
├── 3XUI_XRAY_README.md        # XRAY REALITY + 3x-ui + Hiddify — keys, setup, Russia/EU routing
├── .bashrc                    # Unified .bashrc for all VPN servers
├── motd_server.sh             # Universal MOTD (auto-detects AWG/Xray/AdGuard/Samba)
├── scan_clamav_vpn.sh         # ClamAV on-demand antivirus scanner
├── amnezia_stat.sh            # AmneziaWG peer statistics
├── vpn_node_clean_audit.sh    # Security + load audit
├── crowdsec_install_vpn.sh    # CrowdSec install for VPN servers
├── crowdsec/                  # CrowdSec scenarios and configs
├── AMNEZIA_SETUP.md           # AmneziaWG full setup guide
├── BACKUP.md                  # Backup procedures
├── MOTD_HOWTO.md              # MOTD setup guide
├── SOS_VPN.md                 # Emergency recovery guide
└── VPN_237_README.md          # Server 237 specific notes
```

---

## Key Scripts

### `motd_server.sh` — Universal MOTD

```bash
# Install on any VPN server:
cp VPN/motd_server.sh /etc/profile.d/motd_server.sh
chmod +x /etc/profile.d/motd_server.sh
```

### `scan_clamav_vpn.sh` — On-Demand Antivirus

```bash
bash /root/Linux_Server_Public/VPN/scan_clamav_vpn.sh
# or: antivir
```

**One-time install:**
```bash
apt install -y clamav
systemctl stop clamav-freshclam && systemctl disable clamav-freshclam
freshclam
```

### `.bashrc` — Unified Shell Configuration

```bash
cp VPN/.bashrc /root/.bashrc && source /root/.bashrc
```

| Alias | Action |
|---|---|
| `sos` / `sos24` | SOS monitoring (1h / 24h) |
| `antivir` | ClamAV on-demand scan |
| `load` | git pull + deploy + .bashrc reload |
| `save` | git push with auto-stash |
| `banlist` | CrowdSec + fail2ban ban list |
| `ports` | Open ports |
| `infooo` | Full server info |
| `aw` | AmneziaWG peer stats |
| `xray_st` / `smb_st` / `adg_st` | Service status |
| `00` | clear |
| `ll` / `la` / `mc` | ls / hidden / Midnight Commander |

---

## Quick Deploy (New VPN Server)

```bash
# 1. Clone repo
git clone https://github.com/GinCz/Linux_Server_Public /root/Linux_Server_Public

# 2. Deploy .bashrc
cp /root/Linux_Server_Public/VPN/.bashrc /root/.bashrc && source /root/.bashrc

# 3. Deploy MOTD
cp /root/Linux_Server_Public/VPN/motd_server.sh /etc/profile.d/motd_server.sh
chmod +x /etc/profile.d/motd_server.sh

# 4. CrowdSec
bash /root/Linux_Server_Public/VPN/crowdsec_install_vpn.sh

# 5. ClamAV
apt install -y clamav && systemctl disable --now clamav-freshclam

# 6. Samba
apt install -y samba

# 7. vnstat
apt install -y vnstat && systemctl enable --now vnstat

# 8. Timezone + daily reboot 03:00 CET
timedatectl set-timezone Europe/Amsterdam && systemctl restart systemd-timesyncd && (crontab -l 2>/dev/null | grep -v "reboot"; echo "0 3 * * * /sbin/reboot") | crontab -
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| `banlog: command not found` | Old .bashrc | `cp VPN/.bashrc /root/.bashrc && source /root/.bashrc` |
| `antivir` silent / not working | ClamAV not installed | `apt install -y clamav && systemctl disable clamav-freshclam` |
| `sos` returns `404: command not found` | sos.sh was not found on GitHub, HTML 404 page was saved instead | `cp /root/Linux_Server_Public/scripts/sos-fastpanel.sh /usr/local/bin/sos && chmod +x /usr/local/bin/sos` |
| MOTD shows wrong services | Wrong MOTD file | Re-copy `VPN/motd_server.sh` to `/etc/profile.d/` |
| Telegram report not sent | TG_TOKEN/TG_CHAT_ID missing | Check `scripts/common.sh` is sourced |
| vnstat shows no data | Just installed | Wait 24h |
| Xray keys change on every restart | Keys not fixed in x-ui.db | Edit Inbound → Security → Reality → fill in keys → Save |
| Telegram calls don’t work through VPN | UDP not tunneled | Hiddify: TUN mode + Resolve Destination ON |
| VPN connected, Telegram blocked | Region not set to `ru` | Settings → Routing → Region: Russia |
| Local network (router/Samba) unreachable while VPN is on | Bypass LAN disabled | Hiddify: Settings → Routing → Bypass LAN: ON |

---

## See Also

- [3XUI_XRAY_README.md](./3XUI_XRAY_README.md) — 3x-ui + XRAY REALITY + Hiddify full documentation
- [AMNEZIA_SETUP.md](./AMNEZIA_SETUP.md) — Full AmneziaWG setup guide
- [BACKUP.md](./BACKUP.md) — Backup & restore procedures
- [SOS_VPN.md](./SOS_VPN.md) — Emergency recovery guide
- [MOTD_HOWTO.md](./MOTD_HOWTO.md) — MOTD customization guide
- [../scripts/samba_setup.sh](../scripts/samba_setup.sh) — Samba install script
- [../CHANGELOG.md](../CHANGELOG.md) — Full change history
