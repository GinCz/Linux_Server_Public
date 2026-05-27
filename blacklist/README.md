# 🚫 Blacklist — IP Attack Database

> Public IP blacklist collected from real attacks on VladiMIR's server infrastructure.
> Automatically updated from CrowdSec decisions on server 222 (152.53.182.222).
> = Rooted by VladiMIR + AI | v.2026.05.27 | github.com/GinCz =

---

## 📋 What Is This?

This is a **real-world IP blacklist** collected from:
- CrowdSec decisions on **server 222** (main web server, Cloudflare + Ubuntu 24)
- CrowdSec decisions on **server 109** (Russian sites server)
- Manual bans via `banblock` alias (wp-login brute force, DDoS, probing)
- Aggregated from all **8 VPN nodes** (planned automation)

All IPs in this list have **actively attacked** one or more servers in this infrastructure.

---

## 📂 Files

| File | Description |
|---|---|
| `blacklist.txt` | Raw IP list — one IP per line. Machine-readable. No comments. |
| `blacklist-full.csv` | Full database — IP, reason, source server, date added, country |
| `collect-blacklist.sh` | Script: collects IPs from CrowdSec on server 222, exports to this repo |
| `deploy-blacklist.sh` | Script: downloads blacklist from GitHub and applies to any server |
| `README.md` | This file |

---

## 🔄 Update Frequency

Currently: **manual** (run `collect-blacklist.sh` from server 222 when needed).

Planned: **automatic** — cron job on server 222, runs every night at 03:00,
exports current CrowdSec decisions + permanent bans, pushes to GitHub via API.

---

## 🚀 Quick Apply (any server)

```bash
# Download and apply blacklist to iptables (one-line)
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh)
```

Or just block all IPs from the raw list:
```bash
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/blacklist.txt | \
  while read ip; do
    [[ "$ip" =~ ^#|^$ ]] && continue
    iptables -I INPUT -s "$ip" -j DROP 2>/dev/null
  done
```

---

## 🔧 Integration Options

### CrowdSec (recommended)
Add as a custom blocklist in CrowdSec:
```bash
cscli decisions import -i <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/blacklist.txt) \
  --type ban --duration 720h
```

### iptables / ipset
```bash
# Create ipset and populate
ipset create vladblacklist hash:ip
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/blacklist.txt | \
  grep -v '^#' | grep -v '^$' | \
  while read ip; do ipset add vladblacklist "$ip" 2>/dev/null; done

# Block the set
iptables -I INPUT -m set --match-set vladblacklist src -j DROP
```

### Nginx (deny by IP)
```bash
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/blacklist.txt | \
  grep -v '^#' | grep -v '^$' | \
  awk '{print "deny " $1 ";"}' > /etc/nginx/conf.d/ip-blacklist.conf
nginx -t && systemctl reload nginx
```

---

## ⚠️ Disclaimer

This list is provided **as-is** for informational and security purposes.
False positives are possible (shared hosting, Tor exit nodes, VPN providers).
Always review before applying in production.

License: MIT — free to use, share, modify.

---

## 🖥️ Server Reference

| Server | IP | Role |
|---|---|
| 222-DE-NetCup | 152.53.182.222 | Main source — web server, CrowdSec |
| 109-RU-FastVDS | 212.109.223.109 | Secondary source — Russian sites |
| VPN nodes (×8) | various | Planned future sources |

*= Rooted by VladiMIR + AI | v.2026.05.27 | github.com/GinCz/Linux_Server_Public =*
