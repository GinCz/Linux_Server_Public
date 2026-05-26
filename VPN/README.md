# VPN — Server Configuration & Scripts

> VPN infrastructure management for Ubuntu 24 servers.  
> All scripts follow on-demand execution model — no unnecessary background daemons.
> = Rooted by VladiMIR | AI =

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
| VPN-EU-Alex-47 | — | AmneziaWG + AdGuard + Samba |
| VPN-EU-4Ton-237 | 144.124.228.237 | Xray VLESS + Samba |
| VPN-EU-Tatra-9 | — | AmneziaWG + AdGuard + Samba |
| VPN-EU-Pilik-178 | — | AmneziaWG + AdGuard + Samba |
| VPN-EU-Shahin-227 | — | AmneziaWG + AdGuard + Samba |
| VPN-EU-Stolb-24 | — | AmneziaWG + AdGuard + Samba |
| VPN-EU-Ilya-176 | — | AmneziaWG + AdGuard + Samba |
| VPN-EU-So-38 | — | AmneziaWG + AdGuard + Samba |

> **Note (2026-05-26):** Samba deployed on all 8 VPN servers.

---

## 🔄 Daily Reboot Schedule

All 8 VPN servers are configured to reboot automatically every day at **03:00 AM CET/CEST (Europe/Amsterdam)**.

**Applied on 2026-05-26 on all VPN servers via:**

```bash
timedatectl set-timezone Europe/Amsterdam && systemctl restart systemd-timesyncd && (crontab -l 2>/dev/null | grep -v "reboot"; echo "0 3 * * * /sbin/reboot") | crontab -
```

**What this does:**
- Sets timezone to `Europe/Amsterdam` (CET/CEST — UTC+1 winter, UTC+2 summer)
- Restarts time sync (`systemd-timesyncd`)
- Adds cron job: `/sbin/reboot` daily at `0 3 * * *`

**Verify on any VPN server:**
```bash
timedatectl
crontab -l | grep reboot
```

**Remove the reboot job (if needed):**
```bash
(crontab -l 2>/dev/null | grep -v "reboot") | crontab -
```

> ⚠️ During the reboot window (03:00–03:01 CET), VPN connections on that server will drop for ~30–60 seconds while the OS restarts.

---

## 📊 Monthly Traffic (vnstat)

`vnstat` is installed on all VPN servers to track incoming/outgoing traffic from the **1st of each month**.

**Install on a new server:**
```bash
apt install -y vnstat
systemctl enable --now vnstat
```

**SOS script** shows monthly traffic automatically in the `NETWORK` section when vnstat is detected.

**Manual check:**
```bash
vnstat -m          # monthly totals
vnstat --begin $(date +%Y-%m-01)   # from 1st of current month
vnstat -i ens3 -m  # specific interface
```

> ⚠️ vnstat starts counting from the day of installation. After first install, full monthly stats are available from the next 1st of the month.

---

## Directory Structure

```
VPN/
├── .bashrc                    # Unified .bashrc for all VPN servers
├── motd_server.sh             # Universal MOTD (auto-detects AWG/Xray/AdGuard/Samba)
├── scan_clamav_vpn.sh         # ClamAV on-demand antivirus scanner
├── amnezia_stat.sh            # AmneziaWG peer statistics
├── vpn_node_clean_audit.sh    # Security + load audit
├── vpn_hard_shield.sh         # iptables hardening
├── crowdsec_install_vpn.sh    # CrowdSec install for VPN servers
├── xray_clean_install.sh      # Xray VLESS clean install
├── xray_safe_install.sh       # Xray VLESS install (preserves existing config)
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

Auto-detects installed services and shows relevant info on SSH login.

```bash
# Install on any VPN server:
cp VPN/motd_server.sh /etc/profile.d/motd_server.sh
chmod +x /etc/profile.d/motd_server.sh
```

**Displays:**
- Server name, IP, RAM usage, CPU load
- AmneziaWG: online peers / total peers (if Docker container `amnezia-awg` running)
- AdGuard Home: active / stopped
- Xray: active / stopped (if `xray.service` registered)
- Samba: active / connected users (if `smbd.service` registered)
- Quick alias reference menu

---

### `scan_clamav_vpn.sh` — On-Demand Antivirus

ClamAV scanner designed for VPN servers — **no permanent daemon**, minimal RAM footprint.

```bash
# Run manually:
bash /root/Linux_Server_Public/VPN/scan_clamav_vpn.sh

# Or via alias:
antivir
```

**Scan targets:** `/root` `/tmp` `/var/tmp` `/home` `/opt` `/etc`

**Features:**
- Auto-installs ClamAV if not present (first run)
- Updates virus definitions before each scan
- Disables `clamav-freshclam` daemon after install (on-demand only)
- Shows live progress bar during scan
- Sends Telegram report: ✅ clean or ⚠️ threats found
- Runs at lowest I/O priority (`nice -n 19 ionice -c 3`) — does not impact VPN performance

**One-time install:**
```bash
apt install -y clamav
systemctl stop clamav-freshclam
systemctl disable clamav-freshclam
freshclam
```

**Telegram requirements:**
- `TG_TOKEN` and `TG_CHAT_ID` must be exported (via `scripts/common.sh`)

---

### `.bashrc` — Unified Shell Configuration

Applies to all VPN servers. Turquoise PS1 prompt.

```bash
# Deploy:
cp VPN/.bashrc /root/.bashrc && source /root/.bashrc
```

**Available aliases:**

| Alias | Action |
|---|---|
| `sos` / `sos3` / `sos24` / `sos120` | SOS monitoring (24h / 3h / 24h / 120h) |
| `audit` | Security + load audit |
| `infooo` | Full server info |
| `backup` | Backup VPN configs to server 222 |
| `banlog` | CrowdSec ban list (last 20 events) |
| `antivir` | ClamAV on-demand scan + Telegram report |
| `load` | `git pull` + full deploy + `.bashrc` reload |
| `save` | `git push` with auto-stash |
| `aw` | AmneziaWG peer stats |
| `00` | `clear` |
| `ll` | `ls -lh` |
| `la` | `ls -A` |
| `mc` | Midnight Commander |

---

### `crowdsec_install_vpn.sh` — CrowdSec Intrusion Detection

Installs CrowdSec + nftables bouncer on a VPN server.

```bash
bash VPN/crowdsec_install_vpn.sh
```

**Note:** After install, `banlog` alias works fully (`cscli alerts list -l 20`).
If CrowdSec is not installed, `banlog` prints: `CrowdSec not installed`.

---

### `vpn_hard_shield.sh` — iptables Hardening

Applies strict iptables rules — blocks all ports except those explicitly whitelisted.

⚠️ **WARNING: Run only on a VPN server with no production web traffic.**

```bash
bash VPN/vpn_hard_shield.sh
```

---

## Quick Deploy (New VPN Server)

```bash
# 1. Clone repo
git clone https://github.com/GinCz/Linux_Server_Public /root/Linux_Server_Public

# 2. Deploy .bashrc
cp /root/Linux_Server_Public/VPN/.bashrc /root/.bashrc
source /root/.bashrc

# 3. Deploy MOTD
cp /root/Linux_Server_Public/VPN/motd_server.sh /etc/profile.d/motd_server.sh
chmod +x /etc/profile.d/motd_server.sh

# 4. Install CrowdSec
bash /root/Linux_Server_Public/VPN/crowdsec_install_vpn.sh

# 5. Install ClamAV (antivir auto-installs on first run)
apt install -y clamav && systemctl disable clamav-freshclam

# 6. Install Samba
apt install -y samba

# 7. Install vnstat (monthly traffic tracking)
apt install -y vnstat && systemctl enable --now vnstat

# 8. Set timezone + daily reboot at 03:00 CET
timedatectl set-timezone Europe/Amsterdam && systemctl restart systemd-timesyncd && (crontab -l 2>/dev/null | grep -v "reboot"; echo "0 3 * * * /sbin/reboot") | crontab -
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| `banlog: command not found` | Old `.bashrc` not synced | Run `load` or `cp VPN/.bashrc /root/.bashrc && source /root/.bashrc` |
| `antivir: command not found` | Old `.bashrc` not synced | Same as above |
| `banlog` returns `CrowdSec not installed` | CrowdSec not on this server | Run `bash VPN/crowdsec_install_vpn.sh` |
| MOTD shows wrong services | Wrong MOTD file installed | Re-copy `VPN/motd_server.sh` to `/etc/profile.d/` |
| Telegram report not sent | `TG_TOKEN`/`TG_CHAT_ID` missing | Check `scripts/common.sh` is sourced |
| vnstat shows no data | Just installed | Wait until next day; data accumulates over time |

---

## See Also

- [AMNEZIA_SETUP.md](./AMNEZIA_SETUP.md) — Full AmneziaWG setup guide
- [BACKUP.md](./BACKUP.md) — Backup & restore procedures
- [SOS_VPN.md](./SOS_VPN.md) — Emergency recovery guide
- [MOTD_HOWTO.md](./MOTD_HOWTO.md) — MOTD customization guide
- [../scripts/samba_setup.sh](../scripts/samba_setup.sh) — Samba install script
- [../CHANGELOG.md](../CHANGELOG.md) — Full change history
