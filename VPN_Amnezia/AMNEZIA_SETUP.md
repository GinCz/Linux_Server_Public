# AmneziaWG VPN Server — Setup & Management Guide

> = Rooted by VladiMIR | AI =
> v2026-04-07

---

## What it is and why

- **VPN Software:** [AmneziaWG](https://github.com/amnezia-vpn/amneziawg-go) — obfuscated WireGuard
- **Runs in:** Docker container `amnezia-awg`
- **Why not plain WireGuard:** In Russia, plain WireGuard is blocked by DPI (Deep Packet Inspection) due to the distinctive handshake packet signature. AmneziaWG prepends random junk packets with randomized parameters before the handshake — traffic becomes indistinguishable from random UDP
- **Protocol:** UDP
- **Subnet:** `10.8.1.0/24`
- **Interface inside container:** `wg0`
- **Interface on host:** `amn0`

---

## Servers

| Server | IP | Provider | Port | Purpose |
|---|---|---|---|---|
| VPN-EU-Tatra-9 | 144.124.232.9 | NetCup (Germany) | 42430 | Europe, with Cloudflare |
| VPN-RU | 212.109.223.109 | FastVDS (Russia) | — | Russia, without Cloudflare |

---

## Installation on fresh Ubuntu 24

### 1. System preparation

```bash
apt update && apt upgrade -y
apt install -y docker.io docker-compose curl
systemctl enable docker --now
```

### 2. Installing AmneziaWG

Installed via the official **Amnezia Client** (recommended) or manually via Docker.

**Method 1 — via Amnezia Client (recommended):**
1. Download [Amnezia Client](https://amnezia.org) on your computer (Windows/Mac/Linux)
2. Open the client → `Add server` → enter IP, SSH port, root login/password
3. The client will automatically install Docker, pull the image, create the container, and configure the tunnel
4. After installation — add users directly from the client

**Method 2 — manually via Docker:**
```bash
docker run -d \
  --name amnezia-awg \
  --cap-add NET_ADMIN \
  --cap-add SYS_MODULE \
  -p 42430:42430/udp \
  -v /opt/amnezia/awg:/opt/amnezia/awg \
  --restart unless-stopped \
  ghcr.io/amnezia-vpn/amnezia-awg:latest
```

### 3. ⚠️ IMPORTANT: which port to use

When installing via Amnezia Client or manually — **always specify a non-standard port**.

| Port | Problem |
|---|---|
| 51820 | Standard WireGuard port — blocked in Russia by port number |
| 1194 | Standard OpenVPN — also blocked |
| **42430** | Non-standard — not blocked |

> Our servers use port **42430**. Use this port when setting up new VPN servers.

### 4. Obfuscation parameters (junk)

These parameters are set automatically when installing via Amnezia Client.
They are stored in `/opt/amnezia/awg/wg0.conf` under the `[Interface]` section:

```
Jc = 3        # number of junk packets before handshake
Jmin = 10     # minimum junk packet size (bytes)
Jmax = 50     # maximum junk packet size (bytes)
S1 = 115      # first initiation packet offset
S2 = 96       # response packet offset
H1-H4 = ...   # magic headers — random numbers, generated at install time
```

---

## Configuration files on the server

All stored on the host in `/opt/amnezia/awg/` (mounted into the container):

```
/opt/amnezia/awg/
├── wg0.conf        # WireGuard interface config (interface + all peers)
├── clientsTable    # JSON: client names + their public keys
└── start.sh        # container startup script
```

### View server config

```bash
cat /opt/amnezia/awg/wg0.conf
```

Example output:
```
[Interface]
PrivateKey = SBiNPxi5KhtzzI6OgP+FZQMg9Ey8jSyCXA5lpk7kzWA=
Address = 10.8.1.0/24
ListenPort = 42430
Jc = 3
Jmin = 10
Jmax = 50
S1 = 115
S2 = 96
H1 = 1759142089
H2 = 1948227888
H3 = 11875121
H4 = 754506434

[Peer]
PublicKey = xd/y9Lxnq7vHSlgZwUMSbAM8pfRZ5ZQ2xIa43q5VykM=
PresharedKey = yb7iprzwxp1FXWrY0ATVwiI0mdOVT+sDiV9qJEMlgg0=
AllowedIPs = 10.8.1.4/32

[Peer]
...
```

> ℹ️ On the server `[Peer]` has no `Endpoint` field — this is normal. The server does not know the client IP in advance; clients connect from any IP.

### View client table (names)

```bash
cat /opt/amnezia/awg/clientsTable
```

JSON file — contains each client's public key, name (`clientName`) and IP (`allowedIps`).

---

## Container management

```bash
# Check that the container is running
docker ps | grep amnezia

# Restart container
docker restart amnezia-awg

# Enter the container
docker exec -it amnezia-awg sh
```

> ⚠️ The `wg` and `awg` commands are available ONLY inside the container, not on the host.
> `wg` is not installed on the host — this is normal, wireguard-tools is not needed.

### Inside the container

```bash
# Enter
docker exec -it amnezia-awg sh

# Status of all peers (key diagnostic command)
wg show

# Detailed dump with handshake timestamp and traffic
wg show wg0 dump
```

**Example `wg show` output:**
```
interface: wg0
  public key: aN/9OA10G0HqPBY1/5ktTIcXIZP+XGJQ8SbU7pqrxDk=
  listening port: 42430
  jc: 3  jmin: 10  jmax: 50  s1: 115  s2: 96

peer: uoW4QeKgb8LYExGRSsbHBJxjKx1iEM6c63vWoRlcBn0=
  endpoint: 5.189.4.217:28208
  allowed ips: 10.8.1.15/32
  latest handshake: 1 second ago
  transfer: 1.15 MiB received, 129.03 MiB sent

peer: xd/y9Lxnq7vHSlgZwUMSbAM8pfRZ5ZQ2xIa43q5VykM=
  allowed ips: 10.8.1.4/32
  (no handshake — client has never connected)
```

**How to read the output:**
- `endpoint` — current client IP:port (appears only if the client has connected)
- `latest handshake: Xs ago` — client is active
- `latest handshake: (none)` or missing — client has never connected or connected very long ago
- If handshake was < 3 minutes ago — client is online

**`wg show wg0 dump` format (used in scripts):**
```
pubkey  preshared  endpoint  allowed_ips  last_handshake_unix  rx_bytes  tx_bytes  keepalive
```
- `last_handshake_unix` = 0 means "never connected"

---

## Adding a new user

### Via Amnezia Client (recommended)

1. Open **Amnezia Client** on your computer
2. Select the server (VPN-EU-Tatra-9)
3. `Settings` → `Users` section → `Add user` button
4. Enter a name in the format `Name_Device` (e.g. `Pavel_iPhone`, `Elena_PC`)
5. Click `Create` — the client automatically:
   - Generates a key pair
   - Adds the peer to `wg0.conf` on the server
   - Records the name in `clientsTable`
   - Assigns the next free IP from the `10.8.1.x` subnet
6. Download the QR code → scan it with the Amnezia app on the phone
7. Or download the `.conf` file → import it into Amnezia on PC

### IP assignments (current state)

| IP | User | Status |
|---|---|---|
| 10.8.1.4 | Admin [Windows 10 22H2] | never connected |
| 10.8.1.5 | Pavel_iPhone | never connected |
| 10.8.1.6 | Pavel_PC | never connected |
| 10.8.1.7 | Andr_iPhone | ✅ active |
| 10.8.1.9 | Serg_iPhone | ✅ active |
| 10.8.1.10 | Konstantine_iPhone | ✅ active |
| 10.8.1.11 | ilya_iPhone | ✅ active |
| 10.8.1.12 | Olga_Kre_iPhone | never connected |
| 10.8.1.13 | Irina_Ilya_Samsung | never connected |
| 10.8.1.14 | Olesya_Valery_iPhone | never connected |
| 10.8.1.15 | Elena_Andr_iPhone | ✅ active |
| 10.8.1.16 | Elis_Star_iPhone | ✅ active |
| 10.8.1.17 | Lev_Star_iPhone | never connected |
| 10.8.1.18 | Evgenia_iPhone | ✅ active |
| 10.8.1.19 | Admin [Android 10] | never connected |
| 10.8.1.20 | Valer_iPhone | never connected |
| 10.8.1.21 | (reserved) | — |

> Next free IP for a new user: **10.8.1.22**

---

## Scripts

All scripts are located in `/root/` on the server and in this repository under `VPN/`.

### Update scripts from GitHub

```bash
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/VPN/amnezia_stat.sh \
  -o /root/amnezia_stat.sh
```

---

### `amnezia_stat.sh` — Traffic statistics

Main monitoring script. Shows:
- **Section 1:** table of all peers with traffic (inbound/outbound/total in GB), sorted by descending traffic
- **Section 2:** only peers that had a handshake in the last 15 minutes (actually active right now)

**Run:**
```bash
bash /root/amnezia_stat.sh
```

**Example output:**
```
=== AmneziaWG Stats v2026-04-07b ===

┌─────────────────────┬──────────────────────────────────────────┬──────────────┬──────────────┬──────────────┐
│ IP Address          │ User Name                                │ Inbound(GB)  │ Outbound(GB) │ Total(GB)    │
├─────────────────────┼──────────────────────────────────────────┼──────────────┼──────────────┼──────────────┤
│ 10.8.1.7            │ Andr_iPhone                              │ 0.05         │ 1.09         │ 1.13         │
│ 10.8.1.15           │ Elena_Andr_iPhone                        │ 0.01         │ 0.80         │ 0.81         │
│ 10.8.1.10           │ Konstantine_iPhone                       │ 0.01         │ 0.70         │ 0.72         │
│ ...                 │ ...                                      │ ...          │ ...          │ ...          │
├─────────────────────┼──────────────────────────────────────────┼──────────────┼──────────────┼──────────────┤
│ TOTAL               │ All Clients Combined                     │ 0.07         │ 2.65         │ 2.73         │
└─────────────────────┴──────────────────────────────────────────┴──────────────┴──────────────┴──────────────┘

=== Active peers (last 15 minutes) ===

  10.8.1.9             Serg_iPhone              1m 7s ago     rx:2.9 MB     tx:4.4 MB
  10.8.1.7             Andr_iPhone              2m 3s ago     rx:47.5 MB    tx:1112.9 MB
  10.8.1.15            Elena_Andr_iPhone        1m 49s ago    rx:5.3 MB     tx:820.9 MB
  10.8.1.11            ilya_iPhone              1m 12s ago    rx:0.3 MB     tx:0.8 MB
  10.8.1.18            Evgenia_iPhone           5m 9s ago     rx:0.1 MB     tx:0.2 MB
```

**How the script works internally:**

1. Reads `/opt/amnezia/awg/clientsTable` — JSON with client names
2. Determines the command: `awg show awg0 dump` or `wg show wg0 dump` (depending on image version)
3. Parses the dump — columns: `pubkey | preshared | endpoint | allowed_ips | last_handshake_unix | rx | tx | keepalive`
4. For each peer looks up the name and IP in clientsTable by public key
5. Section 1: converts bytes to GB, sorts descending
6. Section 2: compares `last_handshake_unix` with `$(date +%s)` — if difference ≤ 900 seconds (15 min) — peer is active

**Full script code** — see file [`amnezia_stat.sh`](./amnezia_stat.sh)

---

### Quick one-liner (without file)

If you need to quickly check stats without downloading the file — copy and paste into terminal:

```bash
clear; echo "= Rooted by VladiMIR | AI = v2026-04-07"; C="\033[1;36m"; Y="\033[1;33m"; R="\033[0m"; printf "${C}┌─────────────────────┬──────────────────────────────────────────┬──────────────┬──────────────┬──────────────┐${R}\n"; printf "${C}│ ${Y}%-19s ${C}│ ${Y}%-40s ${C}│ ${Y}%-12s ${C}│ ${Y}%-12s ${C}│ ${Y}%-12s ${C}│${R}\n" "IP Address" "User Name" "Inbound(GB)" "Outbound(GB)" "Total(GB)"; printf "${C}├─────────────────────┼──────────────────────────────────────────┼──────────────┼──────────────┼──────────────┤${R}\n"; J=$(docker exec amnezia-awg cat /opt/amnezia/awg/clientsTable 2>/dev/null); if docker exec amnezia-awg awg show awg0 dump >/dev/null 2>&1; then D="awg show awg0 dump"; else D="wg show wg0 dump"; fi; docker exec amnezia-awg $D | tail -n +2 | awk '{print $1, $6, $7}' | while read k r t; do b=$(echo "$J" | grep -B5 -A5 "$k"); n=$(echo "$b" | grep '"clientName"' | sed 's/.*"clientName": "//;s/".*//' | head -1); ip=$(echo "$b" | grep '"allowedIps"' | sed 's/.*"allowedIps": "//;s/".*//;s|/32||' | head -1); [ -z "$n" ] || [ "$n" == "null" ] && n="Unknown"; [ -z "$ip" ] && ip="N/A"; rg=$(awk -v r="$r" 'BEGIN {printf "%.2f", r/1073741824}'); tg=$(awk -v t="$t" 'BEGIN {printf "%.2f", t/1073741824}'); tt=$(awk -v r="$r" -v t="$t" 'BEGIN {printf "%.2f", (r+t)/1073741824}'); echo "$tt|$ip|$n|$rg|$tg"; done | sort -t'|' -k1 -rn | awk -F'|' -v c="$C" -v y="$Y" -v r="$R" '{si+=$4; so+=$5; st+=$1; printf "%s│ %s%-19s %s│ %s%-40s %s│ %s%-12s %s│ %s%-12s %s│ %s%-12s %s│%s\n", c, r, $2, c, r, $3, c, r, $4, c, r, $5, c, r, $1, c, r} END {printf "%s├─────────────────────┼──────────────────────────────────────────┼──────────────┼──────────────┼──────────────┤%s\n", c, r; printf "%s│ %s%-19s %s│ %s%-40s %s│ %s%-12.2f %s│ %s%-12.2f %s│ %s%-12.2f %s│%s\n", c, y, "TOTAL", c, y, "All Clients Combined", c, y, si, c, y, so, c, y, st, c, r; printf "%s└─────────────────────┴──────────────────────────────────────────┴──────────────┴──────────────┴──────────────┘%s\n", c, r}'
```

---

## Diagnostics

### Client not connecting

```bash
# Step 1: enter the container
docker exec -it amnezia-awg sh

# Step 2: check peer status
wg show
# Find the peer by IP (allowed ips: 10.8.1.X/32)
# If there is no "latest handshake" or it is very old — client is not connecting

# Step 3: exit container
exit

# Step 4: check that port is open in UFW
ufw status | grep 42430

# Step 5: check that port is listening
ss -ulnp | grep 42430

# Step 6: tcpdump — check if packets from client are arriving (warning: verbose output)
tcpdump -i any udp port 42430 -n -c 50
```

**Common reasons why a client does not connect:**

| Symptom | Cause | Fix |
|---|---|---|
| No handshake, packets visible in tcpdump | Wrong key or client config | Regenerate config via Amnezia Client |
| No packets in tcpdump | Client not running or wrong server IP/port | Check endpoint in client config |
| 100% packet loss on ping | Peer behind NAT or blocking ICMP | Normal, UDP tunnel works regardless of ping |
| `wg` not found on host | wireguard-tools not installed on host | Use `docker exec -it amnezia-awg sh` |
| `awg` not found in container | Image version uses `wg` instead of `awg` | Use `wg show` inside container |
| `Error: logging driver does not support reading` | docker logs driver does not support this | Normal, diagnose via `wg show` |

### Firewall

```bash
# Open VPN port
ufw allow 42430/udp
ufw reload

# Verify
ufw status numbered | grep 42430
```

---

## Backup of configs

```bash
# Copy the entire amnezia folder
cp -r /opt/amnezia/awg/ /root/backup_amnezia_$(date +%Y%m%d)/

# Or via system_backup.sh
bash /root/system_backup.sh
```

Critical files to back up:
- `/opt/amnezia/awg/wg0.conf` — all keys and peers
- `/opt/amnezia/awg/clientsTable` — client names
