# VPN Node — AmneziaWG v2 Setup Guide

> **Version:** v2026-04-18 | *Rooted by VladiMIR | AI*  
> **Reference server:** vpn-4ton-237 (144.124.228.237)

---

## Server Specs (reference)

| Parameter | Value |
|---|---|
| **IP** | 144.124.228.237 |
| **Hostname** | vpn-4ton-237 |
| **OS** | Ubuntu 24 LTS |
| **Provider** | 4ton.com |
| **Hardware** | 4 vCore AMD EPYC / 8 GB RAM / 80 GB NVMe |

---

## Step 1 — Fresh Ubuntu 24 base packages

```bash
apt update && apt upgrade -y
apt install -y git mc curl wget htop jq ufw
```

> Docker is installed automatically by the Amnezia Windows app. Do NOT install Docker manually before running Amnezia app.

---

## Step 2 — Install AmneziaWG v2 via Amnezia Windows App

1. Open **Amnezia VPN** Windows app
2. Click **Add server** → enter server IP + root password
3. App installs Docker + AmneziaWG automatically
4. When asked for protocol — select **AmneziaWG** (NOT WireGuard, NOT OpenVPN)
5. App creates Docker container named **`amnezia-awg2`**

### ⚠️ CRITICAL: Protocol selection

| Protocol | Container name | Result |
|---|---|---|
| **AmneziaWG** ✅ | `amnezia-awg2` | Works correctly, peers get IP |
| WireGuard ❌ | `amnezia-awg` | Peers created with NO IP, never connect |
| OpenVPN ❌ | different | Wrong protocol entirely |

**Always choose AmneziaWG when adding new clients too!**  
If a client was created via WireGuard — delete it in Amnezia app and recreate with AmneziaWG.

---

## Step 3 — Verify container is running

```bash
docker ps | grep amnezia
```

Expected output:
```
4f7369addbab   amnezia-awg2   "dumb-init /opt/amne…"   Up 3 hours   0.0.0.0:44735->44735/udp   amnezia-awg2
```

- Container name: **`amnezia-awg2`** (v2)
- Port: **`44735/udp`**
- Image name: `amnezia-awg2`

### Key paths inside container

| Path | Description |
|---|---|
| `/opt/amnezia/awg/clientsTable` | JSON with client names, IPs (cached, NOT real-time) |
| `/opt/amnezia/awg/wg0.conf` | WireGuard config |

### ⚠️ clientsTable is a CACHE

`clientsTable` stores handshake time and traffic as a snapshot updated only when Amnezia app is open.  
**Do NOT use clientsTable for real-time stats** — use `awg show` instead.

```bash
# Real-time stats (always accurate)
docker exec amnezia-awg2 awg show

# Client names only (from cache)
docker exec amnezia-awg2 cat /opt/amnezia/awg/clientsTable | jq '[.[] | {name: .userData.clientName, ip: .userData.allowedIps}]'
```

### awg show traffic direction

| awg show field | Meaning for client |
|---|---|
| `received` | Server received from client = **Outbound** (client uploaded) |
| `sent` | Server sent to client = **Inbound** (client downloaded) |

---

## Step 4 — UFW Firewall

```bash
ufw allow 22/tcp
ufw allow 44735/udp
ufw enable
ufw status
```

Expected:
```
22/tcp    ALLOW
44735/udp ALLOW
```

---

## Step 5 — Aliases in ~/.bashrc

```bash
cat >> ~/.bashrc << 'EOF'

# === AmneziaWG2 aliases ===
alias awg='docker exec amnezia-awg2 awg show'
alias awg2='docker exec amnezia-awg2 awg show'
alias dps='docker ps'
alias dlogs='docker logs amnezia-awg2 --tail=50'
alias drestart='docker restart amnezia-awg2'
alias infooo='echo "Hostname: $(hostname)" && echo "IP: $(curl -s ifconfig.me)" && docker ps | grep amnezia'
alias audit='last -20'
alias backup='cp ~/amnezia_stat.sh ~/amnezia_stat.sh.bak'
alias sos='systemctl status docker'
alias ports='ss -tulnp'
alias fw='ufw status numbered'
alias load='uptime'
alias save='history -w'
alias mem='free -h'
alias disk='df -h /'
alias myip='curl -s ifconfig.me && echo'
EOF
source ~/.bashrc
```

> ⚠️ Make sure alias names do NOT get merged with other words. After adding, run `source ~/.bashrc` and test each alias.

---

## Step 6 — Deploy amnezia_stat.sh

```bash
curl -o ~/amnezia_stat.sh https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/VPN_237/amnezia_stat.sh
chmod +x ~/amnezia_stat.sh
bash ~/amnezia_stat.sh
```

The script uses **`awg show`** for real-time data + **`clientsTable`** for client names only.

---

## Useful commands

```bash
# Show all peers with real-time stats
docker exec amnezia-awg2 awg show

# List clients with names and IPs
docker exec amnezia-awg2 cat /opt/amnezia/awg/clientsTable | jq '.[] | {name: .userData.clientName, ip: .userData.allowedIps, hs: .userData.latestHandshake}'

# Restart container
docker restart amnezia-awg2

# Container logs
docker logs amnezia-awg2 --tail=100

# Check listening port
ss -tulnp | grep 44735
```

---

## Problems Encountered & Fixes

| Problem | Cause | Fix |
|---|---|---|
| Alias name merged with next word (e.g. `amnezia_stat.shclear`) | `clear` glued to filename in `.bashrc` | `sed -i` to fix |
| `python3 not found` inside container | Alpine Linux inside Docker, no python3 | Run Python on host Ubuntu, not inside container |
| Script hung on heredoc | Nested `PYEOF` inside `cat << EOF` conflicted | Rewrite using `python3 << 'PYEOF'` on host |
| 3 peers with no IP, never connect | Created via WireGuard protocol instead of AmneziaWG | Delete in Amnezia app, recreate with AmneziaWG |
| TOTAL row showed `0.00 GiB` | Values in KiB, hard-coded GiB output rounded to 0 | Use auto-scale `fmt()` / `fmtT()` functions in awk |
| Stats show wrong handshake time | `clientsTable` is a cache, not real-time | Read from `awg show` instead |
| Stats column overflow past HR line | Column widths too wide | Reduce column widths to fit 95-char HR |

---

## AWG v2 vs Old Servers comparison

| | Old servers (Shain-227 etc.) | New servers (vpn-4ton-237) |
|---|---|---|
| Container name | `amnezia-awg` | `amnezia-awg2` |
| Protocol | AmneziaWG v1 | AmneziaWG v2 |
| Port | varies | `44735/udp` |
| Stats source | `clientsTable` (cached) | `awg show` (real-time) |
| clientsTable format | JSON | JSON (same) |
| Docker image | `amnezia-awg` | `amnezia-awg2` |

---

## Files in this folder

| File | Description |
|---|---|
| `README.md` | This setup guide |
| `amnezia_stat.sh` | Colored real-time stats script (v2026-04-18d) |
