# SOS — VPN Node Monitoring Script

> = Rooted by VladiMIR | AI =  
> v2026-04-10

This document describes the **SOS monitoring script** for AmneziaWG VPN nodes.  
The script provides a full real-time snapshot of the server: system resources, VPN peers, Samba, Docker containers, CrowdSec bans, open ports, and critical systemd errors.

---

## 🖥️ VPN Node Fleet

| Alias | IP | Services |
|-------|----|----------|
| ALEX_47 | `109.234.38.47` | AmneziaWG + Samba |
| 4TON_237 | `144.124.228.237` | AmneziaWG + Samba + Prometheus |
| TATRA_9 | `144.124.232.9` | AmneziaWG + Samba + Uptime Kuma |
| SHAHIN_227 | `144.124.228.227` | AmneziaWG + Samba |
| STOLB_24 | `144.124.239.24` | AmneziaWG + Samba + AdGuard Home |
| PILIK_178 | `91.84.118.178` | AmneziaWG + Samba |
| ILYA_176 | `146.103.110.176` | AmneziaWG + Samba |
| SO_38 | `144.124.233.38` | AmneziaWG + Samba |

---

## 📁 File Locations

```
VPN/
├── sos_vpn.sh       ← main monitoring script
├── .bashrc          ← aliases: sos / sos3 / sos24 / sos120
└── SOS_VPN.md       ← this documentation
```

On each VPN node the repository is cloned to:
```
/root/Linux_Server_Public/
```

---

## ⚡ Quick Usage

```bash
sos        # last 24 hours (default)
sos3       # last 3 hours
sos24      # last 24 hours
sos120     # last 5 days (120 hours)
```

Or run the script directly:
```bash
bash /root/Linux_Server_Public/VPN/sos_vpn.sh 24
bash /root/Linux_Server_Public/VPN/sos_vpn.sh 3
bash /root/Linux_Server_Public/VPN/sos_vpn.sh 120
```

---

## 🔗 Aliases in `~/.bashrc`

The following aliases are defined in `VPN/.bashrc` and deployed to every node:

```bash
alias sos='bash /root/Linux_Server_Public/VPN/sos_vpn.sh 24'
alias sos3='bash /root/Linux_Server_Public/VPN/sos_vpn.sh 3'
alias sos24='bash /root/Linux_Server_Public/VPN/sos_vpn.sh 24'
alias sos120='bash /root/Linux_Server_Public/VPN/sos_vpn.sh 120'
```

To apply on a node:
```bash
load          # git pull + deploy + source .bashrc
# or manually:
source /root/.bashrc
```

---

## 📊 Script Sections

| Section | What it shows |
|---------|---------------|
| **⚙️ SYSTEM** | Uptime, RAM used/free, Swap |
| **💿 DISK** | All partitions: size, used, available, mount |
| **🔥 TOP 10 CPU%** | Top processes sorted by CPU usage |
| **🔍 TOP 10 RAM** | Top processes sorted by RAM usage (MB) |
| **🔒 AMNEZIAWG** | Active interface, peer count, RX/TX/handshake per peer |
| **🗂️ SAMBA** | smbd/nmbd status, active connections |
| **🐳 DOCKER** | All containers with status |
| **📡 UPTIME KUMA** | Auto-shown if kuma container detected |
| **📊 PROMETHEUS** | Auto-shown if prometheus container detected |
| **🛡️ ADGUARD HOME** | Auto-shown if adguard container detected |
| **🛡️ CROWDSEC** | Active bans count, top scenarios, last 5 bans |
| **🔧 SERVICES** | Status of: ssh, crowdsec, bouncer, smbd, nmbd, docker |
| **🌐 NETWORK** | Listening ports, active TCP connections |
| **❌ SYSTEMD ERRORS** | Critical errors from journalctl for last N hours |

Sections for **Kuma / Prometheus / AdGuard** appear **automatically** if the corresponding Docker container is running on that node. No manual flags needed.

---

## 📝 Full Script Code — `sos_vpn.sh`

```bash
#!/usr/bin/env bash
clear
# = Rooted by VladiMIR | AI = | v2026-04-10
# SOS monitoring script for AmneziaWG VPN nodes
# Usage: bash sos_vpn.sh [hours]  (default: 24h)

set -euo pipefail

# --- CONFIG ---
HOURS="${1:-24}"
HOSTNAME_SHORT=$(hostname)
MAIN_IP=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
LOAD=$(awk '{print $1,$2,$3}' /proc/loadavg)
CORES=$(nproc)
LOAD_PCT=$(awk -v l="$(awk '{print $1}' /proc/loadavg)" -v c="$CORES" 'BEGIN{printf "%d", (l/c)*100}')
NOW=$(date '+%Y-%m-%d %H:%M:%S')

# Colors
G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'
C='\033[1;36m'; M='\033[1;35m'; X='\033[0m'

section() { echo; echo "==================== $1 ===================="; }

# --- HEADER ---
echo -e "${Y}╔═══════════════════════════════════════════════════════╗${X}"
echo -e "${Y}║  📊 SOS — ${HOURS}h  |  ${NOW}${X}"
echo -e "${Y}║  ${HOSTNAME_SHORT} | ${MAIN_IP} | Load: ${LOAD} (${LOAD_PCT}%/${CORES}c)${X}"
echo -e "${Y}╚═══════════════════════════════════════════════════════╝${X}"

# --- SYSTEM ---
section "⚙️  SYSTEM"
echo "  Uptime: $(uptime -p 2>/dev/null || uptime)"
echo "  RAM:  used $(free -h | awk '/^Mem:/{print $3}') / total $(free -h | awk '/^Mem:/{print $2}') (free $(free -h | awk '/^Mem:/{print $4}'))"
echo "  Swap: used $(free -h | awk '/^Swap:/{print $3}') / total $(free -h | awk '/^Swap:/{print $2}')"

# --- DISK ---
section "💿 DISK"
printf '  %-22s %-6s %-6s %-6s %-5s %s\n' Filesystem Size Used Avail 'Use%' Mounted
df -h --output=source,size,used,avail,pcent,target 2>/dev/null | tail -n +2 | \
  grep -v 'tmpfs\|udev\|loop' | \
  while IFS= read -r line; do printf '  %s\n' "$line"; done

# --- TOP CPU ---
section "🔥 TOP 10 CPU%"
ps aux --sort=-%cpu 2>/dev/null | awk 'NR>1 && NR<=11{printf "  %-7s %-12s %-6s %-6s %s\n",$2,$1,$3,$4,substr($11,1,40)}'

# --- TOP RAM ---
section "🔍 TOP 10 RAM"
ps aux --sort=-%mem 2>/dev/null | awk 'NR>1 && NR<=11{
  mem=$6/1024;
  printf "  %-7s %-12s %-6s %-6s %s\n",$2,$1,$3,sprintf("%.1fMB",mem),substr($11,1,40)
}'

# --- AMNEZIAWG ---
section "🔒 AMNEZIAWG"
AWG_IFACE=$(ip link show 2>/dev/null | awk -F: '/awg/{print $2}' | tr -d ' ' | head -n1)
if [ -n "${AWG_IFACE:-}" ]; then
  echo "  Interface: ${AWG_IFACE}"
  if command -v awg >/dev/null 2>&1; then
    PEERS=$(awg show 2>/dev/null | grep -c '^peer' || echo 0)
    echo "  Peers: ${PEERS}"
    echo
    awg show 2>/dev/null | awk '
      /^peer:/{peer=$2; rx="-"; tx="-"; hs="never"}
      /latest handshake:/{gsub(/.*latest handshake: /,""); hs=$0}
      /transfer:/{rx=$2" "$3; tx=$5" "$6}
      /^$/ && peer!=""{
        printf "  %-20s  RX: %-12s TX: %-12s HS: %s\n", substr(peer,1,20), rx, tx, hs;
        peer=""
      }
    ' | head -n 20
  elif command -v wg >/dev/null 2>&1; then
    PEERS=$(wg show 2>/dev/null | grep -c '^peer' || echo 0)
    echo "  Peers: ${PEERS} (via wg)"
  else
    CONT=$(docker ps --format '{{.Names}}' 2>/dev/null | grep -i amnezia | head -n1)
    [ -n "${CONT:-}" ] && echo "  Container: ${CONT}" && \
      docker exec "$CONT" awg show 2>/dev/null | grep -c '^peer' | xargs -I{} echo "  Peers: {}"
  fi
else
  CONT=$(docker ps --format '{{.Names}}' 2>/dev/null | grep -i amnezia | head -n1)
  if [ -n "${CONT:-}" ]; then
    echo -e "  Container: ${G}${CONT} (running)${X}"
    PEERS=$(docker exec "$CONT" awg show 2>/dev/null | grep -c '^peer' || echo 0)
    echo "  Peers: ${PEERS}"
  else
    echo -e "  ${R}AmneziaWG not running!${X}"
  fi
fi

# --- SAMBA ---
section "🗂️  SAMBA"
if systemctl is-active --quiet smbd 2>/dev/null; then
  echo -e "  smbd:    ${G}active${X}"
  echo -e "  nmbd:    $(systemctl is-active nmbd 2>/dev/null || echo unknown)"
  CONN=$(smbstatus --brief 2>/dev/null | grep -c '^[0-9]' || echo 0)
  echo "  Active connections: ${CONN}"
else
  echo -e "  smbd:    ${R}INACTIVE!${X}"
fi

# --- DOCKER ---
section "🐳 DOCKER"
if command -v docker >/dev/null 2>&1; then
  docker ps --format '  {{printf "%-30s" .Names}} {{.Status}}' 2>/dev/null || echo "  Docker not responding"
else
  echo "  Docker not installed"
fi

# --- UPTIME KUMA (auto-detect) ---
if docker ps --format '{{.Names}}' 2>/dev/null | grep -qi kuma; then
  section "📡 UPTIME KUMA"
  docker ps --format '  {{printf "%-30s" .Names}} {{.Status}}' 2>/dev/null | grep -i kuma
fi

# --- PROMETHEUS (auto-detect) ---
if docker ps --format '{{.Names}}' 2>/dev/null | grep -qi prometheus; then
  section "📊 PROMETHEUS"
  docker ps --format '  {{printf "%-30s" .Names}} {{.Status}}' 2>/dev/null | grep -i prometheus
fi

# --- ADGUARD (auto-detect) ---
if docker ps --format '{{.Names}}' 2>/dev/null | grep -qi adguard; then
  section "🛡️  ADGUARD HOME"
  docker ps --format '  {{printf "%-30s" .Names}} {{.Status}}' 2>/dev/null | grep -i adguard
fi

# --- CROWDSEC ---
section "🛡️  CROWDSEC"
if systemctl is-active --quiet crowdsec 2>/dev/null; then
  BANS=$(cscli decisions list 2>/dev/null | grep -c 'ban' || echo 0)
  echo -e "  crowdsec:         ${G}active${X}"
  echo -e "  bouncer:          $(systemctl is-active crowdsec-firewall-bouncer 2>/dev/null || echo unknown)"
  echo "  Active bans:      ${BANS}"
  echo
  echo "  --- Active scenarios ---"
  cscli scenarios list 2>/dev/null | grep 'enabled' | awk '{printf "  %-42s %s\n", $1, $2}' | head -n 10
  echo
  echo "  --- Last 5 bans ---"
  cscli decisions list --limit 5 2>/dev/null | tail -n +4 | head -n 5 || true
else
  echo -e "  crowdsec:         ${R}INACTIVE!${X}"
fi

# --- SERVICES ---
section "🔧 SERVICES"
for svc in ssh crowdsec crowdsec-firewall-bouncer smbd nmbd docker; do
  STATE=$(systemctl is-active "$svc" 2>/dev/null || echo "not-found")
  if [ "$STATE" = "active" ]; then
    echo -e "  $(printf '%-36s' $svc) ${G}${STATE}${X}"
  elif [ "$STATE" = "not-found" ] || [ "$STATE" = "inactive" ]; then
    echo -e "  $(printf '%-36s' $svc) ${Y}${STATE}${X}"
  else
    echo -e "  $(printf '%-36s' $svc) ${R}${STATE}${X}"
  fi
done

# --- NETWORK ---
section "🌐 NETWORK"
echo "  Listening ports:"
ss -tlnp 2>/dev/null | awk 'NR>1{printf "  %-25s %s\n", $4, $6}' | head -n 15
echo
echo "  Active connections: $(ss -tn 2>/dev/null | grep -c ESTAB || echo 0)"

# --- SYSTEMD ERRORS ---
section "❌ SYSTEMD ERRORS (last ${HOURS}h)"
journalctl -p err --since "${HOURS} hours ago" --no-pager -q 2>/dev/null \
  | grep -v 'audit\|kernel:' \
  | tail -n 20 \
  || echo "  No critical errors found"

# --- FOOTER ---
echo
echo -e "${Y}╔═══════════════════════════════════════════════════════╗${X}"
echo -e "${Y}║  = Rooted by VladiMIR | AI =   v2026-04-10          ║${X}"
echo -e "${Y}╚═══════════════════════════════════════════════════════╝${X}"
```

---

## 🚀 Deploy to All Nodes

### Step 1 — Clone repo (first time only)
```bash
cd /root
git clone https://github.com/GinCz/Linux_Server_Public.git
```

### Step 2 — Deploy `.bashrc` with aliases
```bash
cp /root/Linux_Server_Public/VPN/.bashrc /root/.bashrc
source /root/.bashrc
```

### Step 3 — Test
```bash
sos        # full 24h report
sos3       # last 3 hours only
```

### Update all nodes at once (already deployed)
```bash
load       # alias: git pull + deploy + source .bashrc
```

---

## 🗓️ Changelog

| Date | Change |
|------|--------|
| 2026-04-10 | Initial script created for all 8 VPN nodes |
| 2026-04-10 | Added aliases: `sos` / `sos3` / `sos24` / `sos120` |
| 2026-04-10 | Auto-detection of Kuma / Prometheus / AdGuard sections |
| 2026-04-10 | CrowdSec installed on all 8 nodes |

---

> = Rooted by VladiMIR | AI =  
> GitHub: https://github.com/GinCz/Linux_Server_Public
