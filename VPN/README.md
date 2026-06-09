# VPN — Server Configuration & Scripts

> VPN infrastructure management for Ubuntu 24 servers.  
> All scripts follow on-demand execution model — no unnecessary background daemons.  
> = Rooted by VladiMIR + AI | v.2026.06.09 | github.com/GinCz =

---

## 🔖 Быстрый навигатор по документации

| Тема | Файл |
|------|------|
| **3x-ui + XRAY REALITY — где лежат ключи, настройка Hiddify, Hiddify для России** | [📖 3XUI_XRAY_README.md](./3XUI_XRAY_README.md) |
| AmneziaWG — полная настройка | [AMNEZIA_SETUP.md](./AMNEZIA_SETUP.md) |
| Backup & Restore | [BACKUP.md](./BACKUP.md) |
| SOS / Emergency Recovery | [SOS_VPN.md](./SOS_VPN.md) |
| MOTD настройка | [MOTD_HOWTO.md](./MOTD_HOWTO.md) |
| Сервер 237 — специфика | [VPN_237_README.md](./VPN_237_README.md) |

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
| VPN-EU-Alex-47 | 109.234.38.47 | Xray VLESS REALITY + 3x-ui + Samba |
| VPN-EU-4Ton-237 | 144.124.228.237 | Xray VLESS + Samba |
| VPN-EU-Tatra-9 | 144.124.232.9 | AmneziaWG + AdGuard + Samba |
| VPN-EU-Pilik-178 | 91.84.118.178 | AmneziaWG + AdGuard + Samba |
| VPN-EU-Shahin-227 | 144.124.228.227 | AmneziaWG + AdGuard + Samba |
| VPN-EU-Stolb-24 | 144.124.239.24 | AmneziaWG + AdGuard + Samba |
| VPN-EU-Ilya-176 | 146.103.110.176 | AmneziaWG + AdGuard + Samba |
| VPN-EU-So-38 | 144.124.233.38 | AmneziaWG + AdGuard + Samba |
| VPN-IONOS-38 | 82.223.116.38 | Xray VLESS REALITY + 3x-ui |

> Логины/пароли панелей 3x-ui — в приватном репозитории `Secret_Privat`.

---

## 🔑 3x-ui — где лежат ключи REALITY (краткая шпаргалка)

| Что | Путь |
|-----|-------|
| **База данных (x-ui.db)** | `/etc/x-ui/x-ui.db` |
| **Конфиг XRAY** | `/usr/local/x-ui/bin/config.json` |
| **Ключи REALITY** | Хранятся **в x-ui.db**, через панель → Edit Inbound → Security → Reality |
| Бинарник XRAY | `/usr/local/x-ui/bin/xray-linux-amd64` |
| Логи | `journalctl -u x-ui -n 50` |

> ⚠️ `config.json` содержит **только `privateKey`**. `publicKey` — вычисляется из него, в файле не хранится.  
> Получить publicKey: `/usr/local/x-ui/bin/xray-linux-amd64 x25519 -i YOUR_PRIVATE_KEY`

> 📖 **Подробная документация:** [3XUI_XRAY_README.md](./3XUI_XRAY_README.md)

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
vnstat -m                                       # monthly totals
vnstat --begin $(date +%Y-%m-01)                # from 1st of current month
vnstat -i ens3 -m                               # specific interface
```

> ⚠️ vnstat начинает считать со дня установки.

---

## Directory Structure

```
VPN/
├── 3XUI_XRAY_README.md        # ⭐ 3x-ui + XRAY REALITY + Hiddify — ключи, настройка, Hiddify, Россия
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
| `antivir` not working | ClamAV not installed | `apt install -y clamav && systemctl disable clamav-freshclam` |
| `sos` returns `404: command not found` | sos.sh не скачался, записалась HTML-страница 404 | `cp /root/Linux_Server_Public/scripts/sos-fastpanel.sh /usr/local/bin/sos && chmod +x /usr/local/bin/sos` |
| MOTD shows wrong services | Wrong MOTD file | Re-copy `VPN/motd_server.sh` to `/etc/profile.d/` |
| Telegram report not sent | TG_TOKEN/TG_CHAT_ID missing | Check `scripts/common.sh` |
| vnstat shows no data | Just installed | Wait 24h |
| Xray ключи меняются при рестарте | Ключи не зафиксированы в x-ui.db | Edit Inbound → Security → Reality → заполнить ключи → Save |
| Звонки Telegram не работают через VPN | UDP не перехватывается | Hiddify: TUN режим + Определять адрес назначения ON |
| VPN работает, Telegram заблокирован | Регион в Hiddify не `ru` | Настройки → Маршрутизация → Регион: Russia |

---

## See Also

- [3XUI_XRAY_README.md](./3XUI_XRAY_README.md) — ⭐ 3x-ui + XRAY REALITY + Hiddify полная документация
- [AMNEZIA_SETUP.md](./AMNEZIA_SETUP.md) — Full AmneziaWG setup guide
- [BACKUP.md](./BACKUP.md) — Backup & restore procedures
- [SOS_VPN.md](./SOS_VPN.md) — Emergency recovery guide
- [MOTD_HOWTO.md](./MOTD_HOWTO.md) — MOTD customization guide
- [../scripts/samba_setup.sh](../scripts/samba_setup.sh) — Samba install script
- [../CHANGELOG.md](../CHANGELOG.md) — Full change history
