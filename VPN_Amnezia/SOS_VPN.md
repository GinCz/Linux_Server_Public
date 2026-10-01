# SOS — VPN Node Monitoring Script

> Version: **v2026-04-10**  
> Author: `= Rooted by VladiMIR | AI =`  
> Script: [`sos_vpn.sh`](./sos_vpn.sh)

---

## Overview

`sos` is a single-command health snapshot for AmneziaWG VPN nodes.
It collects system, process, traffic, security and service data into one
colour-coded terminal report. Time window is passed as an argument (default `1h`).

---

## Usage

```bash
bash /root/sos_vpn.sh [15m|30m|1h|3h|6h|12h|24h|120h]

# examples
sos          # last 1h  (default)
sos 15m      # last 15 minutes
sos 24h      # last 24 hours
sos 120h     # last 5 days
```

### Install alias on a node

```bash
cat >> /root/.bashrc << 'EOF'
alias sos='bash /root/Linux_Server_Public/VPN/sos_vpn.sh 1h'
alias sos3='bash /root/Linux_Server_Public/VPN/sos_vpn.sh 3h'
alias sos24='bash /root/Linux_Server_Public/VPN/sos_vpn.sh 24h'
alias sos120='bash /root/Linux_Server_Public/VPN/sos_vpn.sh 120h'
EOF
source /root/.bashrc
```

---

## Report Sections

| Section | What it shows |
|---|---|
| **⚙️ SYSTEM** | Uptime, RAM usage, Swap usage |
| **💿 DISK** | All `/dev/*` mounts: size / used / avail / % |
| **🔥 TOP 10 CPU%** | Processes sorted by CPU |
| **🔍 TOP 15 RAM** | Processes sorted by RSS (MB) |
| **🧠 PHP-FPM POOLS** | Workers grouped by pool user + total RAM |
| **🚀 TOP-5 TRAFFIC** | Busiest access.log files by line count |
| **🌍 TOP-10 IPs** | Most frequent remote IPs in access logs |
| **📈 HTTP STATUS** | Response code distribution (colour-coded) |
| **🔐 WP-LOGIN ATTACKS** | IPs hitting `wp-login.php` (red >100, yellow >20) |
| **🔗 NGINX** | Worker count, TCP connections, stub status |
| **💾 MYSQL** | Threads connected / running / slow queries |
| **🐳 DOCKER** | All containers with status (green=Up, red=Exited) |
| **❌ CRITICAL ERRORS** | `fatal / OOM / upstream timeout` in error logs |
| **🛡️ CROWDSEC** | Total active bans + recent alert table |
| **🔧 SERVICES** | Active/inactive state of all known services |

---

## Load Indicator Colours

| Colour | Threshold |
|---|---|
| 🟢 Green | Load% < 60% of cores |
| 🟡 Yellow | Load% 60–89% |
| 🔴 Red | Load% ≥ 90% |

---

## Node Fleet — Real Output 2026-04-10

### VPN-EU-Alex-39 · `89.110.121.39`

| Metric | Value |
|---|---|
| Uptime | 1 week 5 days 15 hours |
| RAM | 655 MB / 957 MB used (free 71 MB) |
| Disk | 5.7G / 9.8G (61%) |
| Load | 0.04 0.07 0.01 → **4%** 🟢 |
| CrowdSec bans | **5** |
| Docker | `amnezia-awg` Up · `elastic_pasteur` Exited |

**Top processes:**
- `wireguard-go` — 1.6% CPU / 229.8 MB RAM
- `crowdsec` — 246.1 MB RAM (largest consumer)

**CrowdSec bans (last 24h):**

| IP | Reason | Country |
|---|---|---|
| 2.57.121.112 | ssh-bf | RO — Unmanaged Ltd |
| 87.251.64.145 | ssh-bf | RU |
| 87.251.64.147 | ssh-slow-bf + ssh-bf | RU |
| 87.251.64.144 | ssh-slow-bf + ssh-bf | RU |
| 80.66.66.70 | ssh-slow-bf + ssh-bf | FI |

> ⚠️ `elastic_pasteur` container is **Exited** — check if it should be running.



---

## Fleet Summary 2026-04-10

| Node | IP | RAM% | Disk% | Bans | Status |
|---|---|---|---|---|---|
| VPN-EU-Alex-39 | 89.110.121.39 | 68% | 61% | 5 | ✅ OK, Exited container |

---

## Known Issues & Notes

### `awk: escape sequence \u` warning
The warning appears in sections "TOP-10 IPs" and "HTTP STATUS" on VPN nodes because there are **no web access logs** (`/var/www/*/data/logs/`). VPN nodes do not host websites — this is expected behaviour, not a bug.

**Fix** (optional — suppress the warning):
```bash
# Replace awk '{print $1}' with:
gawk '{print $1}'
# or suppress stderr:
find ... -exec tail ... 2>/dev/null | awk ... 2>/dev/null
```

### CrowdSec memory usage (~220–250 MB per node)
CrowdSec is the largest RAM consumer on all three nodes. This is normal for the default `crowdsecurity/linux` collection with in-memory state. Consider:
```bash
# Check leaky bucket memory
cscli metrics
# Or limit with systemd MemoryMax
systemctl edit crowdsec --force
# Add: [Service]\nMemoryMax=180M
```

### Disk growth on Tatra-9 (77%)
```bash
# Find largest directories
du -sh /var/log/* /root/* /tmp/* 2>/dev/null | sort -rh | head -20

# Clean old Docker images
docker image prune -a

# Clean journal logs older than 7 days
journalctl --vacuum-time=7d
```

---

## Full Script Code

See [`sos_vpn.sh`](./sos_vpn.sh) in this folder.

```bash
# Quick deploy to a new node:
wget -O /root/sos.sh \
  https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/VPN/sos_vpn.sh
chmod +x /root/sos.sh
echo "alias sos='bash /root/sos.sh 1h'" >> /root/.bashrc
source /root/.bashrc
```

---

## Changelog

| Date | Change |
|---|---|
| 2026-04-10 | Initial version with full 15-section report, time window arg, colour-coded load |
| 2026-04-10 | Added real fleet output analysis for 3 nodes (Alex-47, 4Ton-237, Tatra-9) |
