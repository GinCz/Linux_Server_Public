# VPN Node vpn-4ton-237 — Setup Summary

> **Version:** v2026-04-17 | *Rooted by VladiMIR | AI*

## Server Specs

| Parameter | Value |
|---|---|
| **IP** | 144.124.228.237 |
| **Hostname** | vpn-4ton-237 |
| **OS** | Ubuntu 24 LTS |
| **Provider** | 4ton.com |
| **Hardware** | 4 vCore AMD EPYC / 8 GB RAM / 80 GB NVMe |

---

## What Was Done

### 1. Base packages installed

```
git mc curl wget htop jq ufw docker (via Amnezia app)
```

### 2. AmneziaWG2 installed via Amnezia Windows app

- Protocol: **AmneziaWG** (NOT standard WireGuard)
- Docker container name: `amnezia-awg2` (NOT `amnezia-awg` like on old servers)
- Port: `44735/udp`
- Config path inside container: `/opt/amnezia/awg/clientsTable`

### 3. UFW firewall configured

```
22/tcp    — SSH
44735/udp — AmneziaWG2
```

### 4. Aliases deployed via `.bashrc`

```
awg  awg2  dps  dlogs  drestart  infooo  audit  backup  sos  ports  fw  load  save  mem  disk  myip
```

### 5. amnezia_stat.sh

Colored stats script with **Total** column + **TOTAL** row.

---

## Problems Encountered

| Problem | Cause | Fix |
|---|---|---|
| `amnezia_stat.shclear` — alias broken | `clear` glued to filename in `.bashrc` | `sed -i` fix |
| `python3 not found` in container | Alpine Linux inside container, no python3 | Moved parser to host Ubuntu |
| Script hung on heredoc | Nested heredoc `PYEOF` inside `cat << EOF` conflicted | Rewrote using `python3 << 'PYEOF'` on host |
| 3 peers with no IP, never connect | Created via **WireGuard** protocol instead of **AmneziaWG** | Deleted via Amnezia app, recreated correctly |
| TOTAL row showed `0.00 GiB` | `parse_bytes()` didn't handle KiB/MiB correctly in awk | Fixed `toGiB()` function in awk |
| Total column wrapped to next line | Column width too narrow (13 chars) | Increased to 14 chars |

---

## Key Difference: AWG2 vs Old Servers

| | Old servers (Shain-227 etc.) | vpn-4ton-237 |
|---|---|---|
| Container | `amnezia-awg` | `amnezia-awg2` |
| Protocol | AmneziaWG v1 | AmneziaWG v2 |
| Stats script | `docker exec amnezia-awg` | `docker exec amnezia-awg2` |
| clientsTable | same JSON format | same JSON format |

---

> ⚠️ **CRITICAL:** When adding new clients in Amnezia app — always select **AmneziaWG** protocol.
> WireGuard protocol creates broken peers with no IP that **never connect**.
