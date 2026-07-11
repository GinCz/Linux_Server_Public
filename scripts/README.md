# 📁 Scripts — Linux Server Public

> = Rooted by VladiMIR + AI | v.2026.07.11 | github.com/GinCz =

---

## 🖥️ new_server_install.sh

Main installation script for a new Ubuntu 24 server.

### What it does (in order):

1. Sets hostname, timezone, locale
2. apt update + upgrade
3. Installs required packages
4. Creates swap (if absent)
5. Clones the git repository
6. Installs scripts: `sos`, `infooo`, `antivir`
7. Configures fail2ban
8. Writes `.bashrc` with aliases
9. Configures UFW
10. Installs CrowdSec
11. Configures MOTD
12. (Optional) Installs Samba

### Server types supported:

| Type | Description |
|---|---|
| TYPE 1 | VPN node — XRay + AmneziaWG + AdGuard + Semaphore |
| TYPE 2 | Web server 222 — FastPanel + Cloudflare + Samba |
| TYPE 3 | Web server 109 — FastPanel + Samba |

### Launch:
```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh)
```

---

## 📊 sos.sh — Server Audit

Full server status report. Covers 30+ sections: processes, RAM, disk, logs, CrowdSec bans, nginx errors, WordPress issues, open ports, etc.

### Usage:
```bash
sos       # last 1 hour
sos 3h    # last 3 hours
sos 24h   # last 24 hours
sos 120h  # last 5 days
```

### Install:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh) && source ~/.bashrc
```

---

## 🛡️ Samba Access Matrix

| Share | vlad | usr |
|---|---|---|
| `\\server\storage\soft` | RW | RO |
| `\\server\storage\user` | RW | RW |

- **vlad** — main admin account (full access)
- **usr** — client account (read-only for `soft`, read-write for `user`)

---

## 📄 Other scripts

| Script | Description |
|---|---|
| `install_vpn.sh` | Full VPN node install — XRay + AmneziaWG + AdGuard. Run on fresh server only |
| `infooo.sh` | Quick server info: IP, RAM, disk, load, services |
| `scan_clamav.sh` (antivir) | ClamAV virus scan |
| `motd_vpn.sh` | MOTD for VPN server (TYPE 1) |
| `night_update.sh` | Scheduled nightly updates via systemd timer |
| `shared_aliases_222.sh` | Additional aliases for server 222 |
| `new_server_install.sh` | Main installer (see above) |

---

*= Rooted by VladiMIR + AI | v.2026.07.11 | github.com/GinCz =*
