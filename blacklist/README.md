# 🛡️ **IPGuard** — Distributed IP Blacklist & Attack Defense System

> **IPGuard** is a distributed, self-updating IP defense system that protects a private 10-node European server infrastructure.
> Every server monitors attacks in real time, shares detected threat IPs with the master node,
> which merges them and publishes a unified blacklist to GitHub — from where all nodes pull and apply it automatically.

**► Live blacklist — plain text, one IP per line:**
```
https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/blacklist.txt
```

**► Full database — CSV with reason, source server, date, duration:**
```
https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/blacklist-full.csv
```

> 🔍 **Keywords for search:** `GitHub IPGuard`, `IPGuard blacklist`, `IPGuard distributed defense`


---


## 📋 What Is **IPGuard**?

**IPGuard** is a **real-world production IP blocklist system** — not a curated list, not a theoretical dataset.
Every IP in the blacklist was caught actively attacking one of the servers in this infrastructure.

Attack types detected and blocked:
- SSH brute-force and slow brute-force
- HTTP probing, web scanning, bad user-agent attacks
- WordPress login brute-force
- SMB brute-force
- Port scanning
- Subnet-level attacks (entire `/24` ranges banned when 3+ IPs from the same subnet attack)
- DDoS attempts

Detection engine: **CrowdSec** — open-source, community-driven intrusion prevention system running on every node.

The list currently contains **155+ unique IPs** collected from active nodes. It grows automatically as new attacks are detected.


---


## 🏗️ Infrastructure

The **IPGuard** system runs on servers spread across Europe and Russia:

| Node | IP | Location | Provider | Status |
|---|---|---|---|---|
| **222-EU-NetCup** ★ | `152.53.182.222` | Germany | NetCup | ✅ Active |
| 109-RU-FastVDS | `212.109.223.109` | Russia | FastVDS | ✅ Active |
| EU-Alex-47 | `109.234.38.47` | Europe | — | ✅ Active |
| EU-4Ton-237 | `144.124.228.237` | Europe | — | ✅ Active |
| EU-Tatra-Kuma-9 | `144.124.232.9` | Europe | — | ✅ Active |
| VPN-EU-Shahin-227 | `144.124.228.227` | Europe | — | ✅ Active |
| EU-Stolb-AG-24 | `144.124.239.24` | Europe | — | ✅ Active |
| VPN-EU-Pilik-178 | `195.63.138.33` | Europe | — | ⚫ Offline |
| VPN-EU-ILYA-176 | `146.103.110.176` | Europe | — | ✅ Active |
| EU-SO-38 | `144.124.233.38` | Europe | — | ✅ Active |

★ = Master collector node (server 222)
⚫ = Node temporarily offline — excluded from collection, not removed from infrastructure


---


## 🔄 How **IPGuard** Works — Full Data Flow

The system operates in a continuous **3-hour cycle** with three distinct phases.
All phases run automatically via cron. No manual intervention is needed after initial setup.


### 🔹 PHASE 1 — Real-Time Attack Detection on Every Node

**When:** Continuously, 24/7, on all active servers simultaneously

**CrowdSec** runs as a background service on every node.
It reads system logs in real time — `/var/log/auth.log` for SSH, nginx/apache access logs for HTTP traffic, and other sources.

When CrowdSec detects a recognizable attack pattern, it immediately:
1. Records the offending IP address and the attack type (SSH brute-force, HTTP probing, port scan, etc.)
2. Registers a **decision** — a timed ban with a duration (default 3 hours, extended to weeks for repeat offenders)
3. Passes the decision to the **CrowdSec firewall bouncer**, which installs a live `iptables DROP` rule in seconds

The attacker is blocked locally within seconds of the first detected pattern.
This local block is instant and independent — it does not wait for the central collector.

**Subnet-level escalation:** If 3 or more IPs from the same `/24` subnet are detected attacking, the **entire subnet** is banned.


### 🔹 PHASE 2 — Master Collection: Gathering Decisions From All Nodes

**When:** Every 3 hours at `XX:00` — script: `collect-from-vpn.sh` — runs only on **Server 222**

Server 222 (the **IPGuard Hub**) connects to each remote node via SSH and harvests their current ban lists.

Detailed steps:

**Step 2.1 — Git pull first**
Before touching any files, the script runs `git pull --rebase` to ensure the local repo is up to date.
This prevents the `! [rejected] ... fetch first` error that previously caused push failures
when other commits (e.g., manual script edits) had been pushed to GitHub between collection cycles.
If `git pull` fails, the script falls back to `git reset --hard origin/main`.

**Step 2.2 — SSH into each remote node**
Server 222 iterates over all 9 remote servers. For each one, it opens an SSH session using pre-configured SSH keys.

**Step 2.3 — Upload and execute a remote collector script**
Rather than running raw commands over SSH (which causes quoting and variable expansion problems),
`collect-from-vpn.sh` uploads a self-contained bash script to `/tmp/_vladbl_collect.sh` on the remote node via SSH heredoc,
then executes it cleanly. This avoids the classic `awk $3` shell-escaping nightmare.

**Step 2.4 — Receive the remote node's decision list**
The remote script runs `cscli decisions list -o raw` and returns the current active ban list.
CrowdSec v1.7 includes an `Ip:` prefix in the output (e.g., `Ip:1.2.3.4`) —
the collector strips this prefix automatically via `awk` before processing.

**Step 2.5 — Collect local decisions from Server 222 itself**
After collecting from all remote nodes, Server 222 also queries its own CrowdSec instance locally.

**Step 2.6 — Merge, deduplicate, validate, filter whitelist**
All IP addresses from all nodes are merged into a single list.
Duplicates are removed.
Invalid entries (non-IP strings, empty lines) are discarded.
**IPv6 addresses are excluded** — `hash:net` ipset is IPv4 only; IPv6 would silently fail on `ipset add`.
**Own infrastructure IPs are stripped** — see Whitelist section below.

**Step 2.7 — Write the output files**
- `blacklist.txt` — plain text, one IP or subnet per line, with a header comment block
- `blacklist-full.csv` — full database with columns: `ip, reason, source_server, date_added, source, duration`

**Step 2.8 — Push to GitHub**
Both files are committed and pushed to this repository.
From this moment, the updated blacklist is publicly available via GitHub Raw URL.


### 🔹 PHASE 3 — Deployment: Every Node Pulls and Applies the Blacklist

**When:** Every 3 hours at `XX:30` — script: `deploy-blacklist.sh` — runs on **all nodes independently**

Thirty minutes after the collection cycle completes and the updated blacklist is on GitHub,
every server independently downloads and applies it.

Detailed steps:

**Step 3.1 — Download** latest `blacklist.txt` from GitHub via `curl`.

**Step 3.2 — Create a temporary ipset** `vladblacklist_tmp` (type `hash:net`, supports IPs and CIDR subnets).

**Step 3.3 — Populate the temporary ipset** fully before touching the live set.

**Step 3.4 — Atomic swap** `ipset swap vladblacklist_tmp vladblacklist` — instantaneous, zero downtime.
The live iptables DROP rule always points to `vladblacklist`.
During the swap, **not a single IP is temporarily unblocked**.

**Step 3.5 — Ensure iptables DROP rule** is present at position 1 of INPUT chain.

**Step 3.6 — Persist** `iptables-save > /etc/iptables/rules.v4` and `ipset save > /etc/ipset.rules`.

**Step 3.7 — Reboot cron** `@reboot` entry restores ipset + iptables rule on every system restart.


### 🔹 Complete 3-Hour Cycle Summary

| Time | Script | Runs on | Action |
|---|---|---|---|
| `XX:00` | `collect-from-vpn.sh` | Server 222 only | Git pull → SSH all nodes → collect bans → filter → push GitHub |
| `XX:30` | `deploy-blacklist.sh` | All nodes | Download latest list from GitHub → apply atomically via ipset swap |


### 🔹 Cron Schedule on Master Server 222

```bash
# IPGuard: Collect from all nodes, merge, filter, push to GitHub
0 */3 * * * cd /root/Linux_Server_Public && bash blacklist/collect-from-vpn.sh >> /var/log/vladblacklist-vpn.log 2>&1

# IPGuard: Pull latest blacklist from GitHub and apply to server 222 itself
30 */3 * * * bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh) >> /var/log/vladblacklist.log 2>&1
```


### 🔹 Cron Schedule on All Other Nodes

```bash
# IPGuard: Pull latest blacklist from GitHub and apply atomically every 3 hours
30 */3 * * * bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh) >> /var/log/vladblacklist.log 2>&1
```


---


## ⚪ Whitelist — Own Infrastructure IPs

### The Problem We Discovered (2026-06-10)

During a routine blacklist audit, we found that **9 of our own server IPs were present in `blacklist.txt`**,
along with the master server 222 itself and several trusted home/work IPs.

**Root cause:** CrowdSec on each node monitors all incoming traffic.
When servers in our infrastructure communicate with each other (SSH connections, monitoring scripts,
VPN traffic), CrowdSec on the receiving end occasionally flags this traffic as suspicious
— especially if a connection is made in rapid succession or from an unusual port.
The resulting ban decision is then collected by the master and written into the shared blacklist.
When the blacklist is deployed back to all nodes, those nodes then **block our own servers from connecting to each other**.

**Impact:** The 8 live nodes all had 171 IPs blocked instead of the correct ~155.
Self-blocking causes SSH timeouts between nodes, broken VPN tunnels, and failed monitoring.

**Fix applied:** `collect-from-vpn.sh` now maintains an explicit `WHITELIST` array containing all own infrastructure IPs.
During the final deduplication step, all whitelist IPs are stripped from the output using `grep -vE`.
This filtering is applied **twice** — once in the awk parser per node, and once in the final sort+dedup pipeline —
so even if a whitelisted IP somehow slips through per-node parsing, it is guaranteed absent from the output files.

### Protected IPs

All own server IPs are protected from appearing in the blacklist:
```
152.53.182.222   # 222-EU-NetCup (master)
212.109.223.109  # 109-RU-FastVDS
109.234.38.47    # EU-Alex-47
144.124.228.237  # EU-4Ton-237
144.124.232.9    # EU-Tatra-Kuma-9
144.124.228.227  # VPN-EU-Shahin-227
144.124.239.24   # EU-Stolb-AG-24
195.63.138.33    # VPN-EU-Pilik-178
146.103.110.176  # VPN-EU-ILYA-176
144.124.233.38   # EU-SO-38
3.79.14.42       # AWS VPN node
185.100.197.16   # trusted home/work
185.14.232.0     # trusted home/work
185.14.233.235   # trusted home/work
90.181.133.10    # trusted work
```

The CrowdSec whitelist at `/etc/crowdsec/parsers/s02-enrich/my_whitelist.yaml` also protects these IPs
at the detection level — but the collector-level filter adds a second layer of defense
for cases where the CrowdSec whitelist has not yet been deployed to a new node.


---


## 📁 Files in This Folder

| File | Where to run | Description |
|---|---|---|
| `blacklist.txt` | — | Plain IP list, one per line. Lines starting with `#` are comments |
| `blacklist-full.csv` | — | Full database: `ip, reason, source_server, date_added, source, duration` |
| `collect-from-vpn.sh` | **Server 222 only** | Master collector — git pull → SSH all nodes → collect → filter whitelist+IPv6 → push GitHub |
| `deploy-blacklist.sh` | **Any server** | Deployer — fetches `blacklist.txt` from GitHub → applies via ipset atomic swap |
| `install-crowdsec-vpn.sh` | **Any server** | Installer — installs CrowdSec + firewall bouncer + detection scenarios |


---


## 🐛 Bugs Fixed — Full Changelog

| # | Date | Bug | Root Cause | Fix |
|---|---|---|---|---|
| 1 | 2026-05 | IPs not added, `Skipped: N` in output | CrowdSec v1.7 adds `Ip:` prefix to every IP in raw CSV output | `sub(/^[Ii]p:/,"",ip)` in all awk parsers |
| 2 | 2026-05 | `ipset swap` type conflict error | Existing set was `hash:ip`, new set was `hash:net` — types must match | Recreate all sets as `hash:net` from scratch |
| 3 | 2026-05 | `/etc/iptables/: No such file or directory` | Directory absent on fresh VPN nodes | Added `mkdir -p /etc/iptables` to `deploy-blacklist.sh` |
| 4 | 2026-05 | `$3: unbound variable` on remote nodes | `set -u` + `$3` in awk string passed through SSH — bash expanded `$3` before SSH | Removed `set -u`, moved remote logic to heredoc script |
| 5 | 2026-05 | `[[: 0\n0: syntax error in expression` | `grep -c` on empty file returned `"0\n0"`, arithmetic comparison failed | Added `\| tr -d ' \n'` to strip newlines from all count variables |
| 6 | 2026-05 | CrowdSec reload fails after whitelist append | Bare IP list appended to yaml without proper wrapper — invalid YAML | Restored correct document structure; consolidated to single `my_whitelist.yaml` |
| 7 | 2026-06-10 | `git push` rejected with `fetch first` error | Another commit (e.g., manual script edit on GitHub) was pushed between collection cycles. The script ran `git add` → `git commit` → `git push` without pulling first, so the local branch was behind remote | Moved `git pull --rebase` to the **first step** of the script, before any file writes. Added fallback `git reset --hard origin/main` if pull fails |
| 8 | 2026-06-10 | 9 own server IPs + master IP appeared in `blacklist.txt` | CrowdSec on nodes occasionally flags inter-server traffic (SSH, monitoring) from other own nodes as attacks. These bans were collected and written to the shared blacklist. When deployed back, nodes blocked each other | Added explicit `WHITELIST` array in `collect-from-vpn.sh`. All own IPs filtered out with `grep -vE` at both awk level and final dedup pipeline |
| 9 | 2026-06-10 | 5 IPv6 addresses in `blacklist.txt` caused `ipset add` failures | `ipset hash:net` is IPv4-only. IPv6 entries (containing `:`) were silently failing on every `deploy-blacklist.sh` run, causing the "176 collected / 171 applied" discrepancy | Added `grep -v ':'` to the final pipeline in `collect-from-vpn.sh` to exclude IPv6 before writing output files |
| 10 | 2026-06-10 | `crontab -e` opened `nano` editor unexpectedly during cron updates | Server 222 had `EDITOR=nano` set in `/etc/environment` (likely set by FastPanel or a package). When `crontab` was invoked from a script without explicit piped input, it opened the editor instead of reading stdin | Removed all `EDITOR`/`VISUAL` entries from `/etc/environment`, `/root/.bashrc`, `/root/.profile`. Added `export EDITOR=true` to `/root/.bashrc` so `crontab` never opens an editor interactively |
| 11 | 2026-06-10 | Cron on 222 ran `deploy` (XX:30) before `collect` (XX:55) completed | Cron schedule had `collect` at `:55` and `deploy` at `:30` of the same 3-hour window — deploy ran first and applied a 3-hour-old blacklist | Fixed cron schedule: `collect` at `XX:00`, `deploy` at `XX:30`, ensuring deploy always runs 30 minutes after a fresh collection |


---


## 🚀 Quick Start — Apply **IPGuard** Blacklist to Your Server

One command — works on any Ubuntu/Debian server:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh)
```

The **IPGuard** deploy script will:
- Install `ipset` and `iptables-persistent` if missing (via `apt`)
- Download the latest `blacklist.txt` from GitHub
- Create ipset `vladblacklist` and atomically populate it
- Add `iptables` DROP rule for all blacklisted IPs/subnets
- Save rules for persistence across reboots
- Add `@reboot` cron entry to restore everything after restart

**Verify after deployment:**
```bash
ipset list vladblacklist | head -20
iptables -L INPUT -n | grep vladblacklist
```

**Add automatic updates every 3 hours:**
```bash
(crontab -l 2>/dev/null; echo "30 */3 * * * bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh) >> /var/log/vladblacklist.log 2>&1") | crontab -
```


---


## 🔧 Technical Details

### Atomic ipset Swap — Zero Downtime Updates

```bash
# WRONG — gap between destroy and recreate leaves server unprotected:
ipset destroy vladblacklist        # iptables rule now points to nothing!
ipset create vladblacklist hash:net
ipset restore < /etc/ipset.rules

# RIGHT — atomic swap, zero gap:
ipset create vladblacklist_tmp hash:net
while read ip; do ipset add vladblacklist_tmp "$ip"; done < blacklist.txt
ipset swap vladblacklist_tmp vladblacklist  # instant, atomic
ipset destroy vladblacklist_tmp
```

### CrowdSec v1.7 — `Ip:` Prefix in Raw Output

CrowdSec v1.7 changed the raw CSV format — the IP column now contains `Ip:1.2.3.4` instead of `1.2.3.4`.
Both collection scripts handle this transparently via `sub(/^[Ii]p:/, "", ip)` in awk.

### Remote Script Injection via SSH Heredoc

```bash
# BAD: nested quoting hell
ssh root@node "awk -F',' '{ print \$3 }' file"

# GOOD: upload script as heredoc, execute cleanly
REMOTE_SCRIPT=$(cat <<'REMOTE'
#!/bin/bash
cscli decisions list -o raw | awk -F',' '{ print $3 }'
REMOTE
)
ssh root@node "cat > /tmp/_script.sh && bash /tmp/_script.sh" <<< "$REMOTE_SCRIPT"
```


---


## ⚠️ Disclaimer

These IPs were blocked based on **real attack traffic** observed on production servers.
CrowdSec decisions expire (typically 3h to 30 days depending on severity), so IPs rotate naturally.
Use at your own discretion. Always verify compatibility with your own infrastructure before applying.


---

## 📜 License

Public domain. Free to use for any purpose, no attribution required.


---

*= Rooted by VladiMIR + AI | v.2026.06.10d | github.com/GinCz =*
