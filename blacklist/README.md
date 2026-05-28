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


==============================================================


## 📋 What Is **IPGuard**?

**IPGuard** is a **real-world production IP blocklist system** — not a curated list, not a theoretical dataset.
Every IP in the blacklist was caught actively attacking one of the 10 servers in this infrastructure.

Attack types detected and blocked:
- SSH brute-force and slow brute-force
- HTTP probing, web scanning, bad user-agent attacks
- WordPress login brute-force
- SMB brute-force
- Port scanning
- Subnet-level attacks (entire `/24` ranges banned when 3+ IPs from the same subnet attack)
- DDoS attempts

Detection engine: **CrowdSec** — open-source, community-driven intrusion prevention system running on every node.

The list currently contains **118+ unique IPs** collected from 8 active nodes. It grows automatically as new attacks are detected.


==============================================================


## 🏗️ Infrastructure

The **IPGuard** system runs on 10 servers spread across Europe and Russia:

| Node | IP | Location | Provider |
|---|---|---|---|
| **222-EU-NetCup** ★ | `xxx.xxx.xxx.222` | Germany | NetCup |
| 109-RU-FastVDS | `xxx.xxx.xxx.109` | Russia | FastVDS |
| EU-Alex-47 | `xxx.xxx.xxx.47` | Europe | — |
| EU-4Ton-237 | `xxx.xxx.xxx.237` | Europe | — |
| EU-Tatra-Kuma-9 | `xxx.xxx.xxx.9` | Europe | — |
| VPN-EU-Shahin-227 | `xxx.xxx.xxx.227` | Europe | — |
| EU-Stolb-AG-24 | `xxx.xxx.xxx.24` | Europe | — |
| VPN-EU-Pilik-178 | `xxx.xxx.xxx.178` | Europe | — |
| VPN-EU-ILYA-176 | `xxx.xxx.xxx.176` | Europe | — |
| EU-SO-38 | `xxx.xxx.xxx.38` | Europe | — |

★ = Master collector node (server 222)


==============================================================


## 🔄 How **IPGuard** Works — Full Data Flow

The system operates in a continuous **3-hour cycle** with three distinct phases.
All phases run automatically via cron. No manual intervention is needed after initial setup.


### 🔹 PHASE 1 — Real-Time Attack Detection on Every Node

**When:** Continuously, 24/7, on all 10 servers simultaneously

**CrowdSec** runs as a background service on every node in the infrastructure.
It reads system logs in real time — `/var/log/auth.log` for SSH, nginx/apache access logs for HTTP traffic, and other sources.

When CrowdSec detects a recognizable attack pattern, it immediately:
1. Records the offending IP address and the attack type (SSH brute-force, HTTP probing, port scan, etc.)
2. Registers a **decision** — a timed ban with a duration (default 3 hours, extended to weeks for repeat offenders)
3. Passes the decision to the **CrowdSec firewall bouncer**, which installs a live `iptables DROP` rule in seconds

The attacker is blocked locally within seconds of the first detected pattern.
This local block is instant and independent — it does not wait for the central collector.

**Subnet-level escalation:** If 3 or more IPs from the same `/24` subnet are detected attacking, the **entire subnet** is banned — not just the individual IPs. This defends against coordinated botnet attacks where the attacker rotates between addresses in the same IP range.


### 🔹 PHASE 2 — Master Collection: Gathering Decisions From All Nodes

**When:** Every 3 hours at `XX:55` — script: `collect-from-vpn.sh` — runs only on **Server 222**

Server 222 (the **IPGuard Hub**, master collector) connects to each of the 9 remote nodes via SSH and harvests their current ban lists.

Detailed steps:

**Step 2.1 — SSH into each remote node**
Server 222 iterates over a list of all 9 remote servers. For each one, it opens an SSH session using pre-configured SSH keys (no password, no interactive prompt).

**Step 2.2 — Upload and execute a remote collector script**
Rather than running raw commands over SSH (which causes quoting and variable expansion problems), `collect-from-vpn.sh` uploads a self-contained bash script to `/tmp/_collect.sh` on the remote node via SSH heredoc, then executes it cleanly. This avoids the classic `awk $3` shell-escaping nightmare.

**Step 2.3 — Receive the remote node's decision list**
The remote script runs `cscli decisions list -o raw` and returns the current active ban list. CrowdSec v1.7 includes an `Ip:` prefix in the output (e.g., `Ip:1.2.3.4`) — the collector strips this prefix automatically via `awk` before processing.

**Step 2.4 — Collect local decisions from Server 222 itself**
After collecting from all remote nodes, Server 222 also queries its own CrowdSec instance locally, so its own bans are included in the merged list.

**Step 2.5 — Merge, deduplicate, validate**
All IP addresses from all 10 nodes are merged into a single list. Duplicates are removed. Invalid entries (non-IP strings, empty lines) are discarded. Subnet ranges (e.g., `45.148.10.0/24`) are preserved as-is.

**Step 2.6 — Write the output files**
- `blacklist.txt` — plain text, one IP or subnet per line, with a header comment block
- `blacklist-full.csv` — full database with columns: `ip, reason, source_server, date_added, source, duration`

**Step 2.7 — Push to GitHub**
Both files are committed and pushed to this repository via `git commit` + `git push`.
From this moment, the updated blacklist is publicly available via GitHub Raw URL worldwide.


### 🔹 PHASE 2b — Local Backup Push (Server 222 Standalone)

**When:** Every 3 hours at `XX:00` — script: `collect-blacklist.sh` — runs only on **Server 222**

This is a lightweight backup step that runs just after Phase 2.
It collects only Server 222's own CrowdSec decisions and pushes them to GitHub independently.
This ensures that even if the remote SSH collection partially fails (a node is offline, unreachable, etc.),
Server 222's own bans are never missed and always reach the blacklist.


### 🔹 PHASE 3 — Deployment: Every Node Pulls and Applies the Blacklist

**When:** Every 3 hours at `XX:30` — script: `deploy-blacklist.sh` — runs on **all 10 nodes independently**

Thirty minutes after the collection cycle completes and the updated blacklist is on GitHub,
every server in the infrastructure independently downloads and applies it.

Detailed steps:

**Step 3.1 — Download the latest blacklist from GitHub**
Each node runs `curl` to fetch the current `blacklist.txt` from the GitHub Raw URL.
No authentication required — the file is public.

**Step 3.2 — Create a temporary ipset**
A new ipset named `vladblacklist_tmp` is created with type `hash:net`.
The `hash:net` type supports both individual IPs and CIDR subnets in the same set.

**Step 3.3 — Populate the temporary ipset**
Every IP and subnet from the downloaded `blacklist.txt` is added to `vladblacklist_tmp`.
The temporary set is fully populated before any swap occurs — the live set is never touched during this phase.

**Step 3.4 — Atomic swap (zero-downtime update)**
This is the most critical step. The command `ipset swap vladblacklist_tmp vladblacklist` is executed.
This operation is **instantaneous and atomic at the kernel level**.
The live `iptables` DROP rule always points to the set named `vladblacklist`.
After the swap, `vladblacklist` contains the new full list — and `vladblacklist_tmp` contains the old list.
The old temporary set is then destroyed.

Result: **Not a single IP is temporarily unblocked during the update.** The transition from old list to new list is seamless.

**Step 3.5 — Ensure the iptables DROP rule is present**
The script checks if an `iptables` rule for `vladblacklist` already exists.
If not (e.g., first run on a fresh server), it adds one: `iptables -I INPUT 1 -m set --match-set vladblacklist src -j DROP`.
This rule is inserted at position 1 (top of the INPUT chain) so it has priority over all other rules.

**Step 3.6 — Save iptables rules for persistence**
`iptables-save > /etc/iptables/rules.v4` — ensures the DROP rule survives a reboot.
The directory `/etc/iptables/` is created automatically if it does not exist.

**Step 3.7 — Save ipset rules for persistence**
`ipset save > /etc/ipset.rules` — stores the full ipset to disk.
On the next reboot, `ipset restore < /etc/ipset.rules` reloads all blocked IPs before networking fully starts.

**Step 3.8 — Register reboot cron entry**
The script adds a `@reboot` cron job that restores both the ipset and the iptables rule automatically on every system restart.
This ensures protection is active from the first second after boot — even before the next scheduled 3-hour cycle runs.


### 🔹 Complete 3-Hour Cycle Summary

| Time | Script | Runs on | Action |
|---|---|---|---|
| `XX:55` | `collect-from-vpn.sh` | Server 222 only | SSH into all 9 nodes, collect bans, merge, push to GitHub |
| `XX:00` | `collect-blacklist.sh` | Server 222 only | Collect Server 222's own local bans, push to GitHub (backup) |
| `XX:30` | `deploy-blacklist.sh` | All 10 nodes | Download latest list from GitHub, apply atomically via ipset swap |


### 🔹 Cron Schedule on Master Server 222 — **IPGuard Hub**

```bash
# IPGuard Step 1: Collect from all 9 remote nodes via SSH, merge, push to GitHub
55 */3 * * * cd /root/Linux_Server_Public && bash blacklist/collect-from-vpn.sh >> /var/log/vladblacklist-vpn.log 2>&1

# IPGuard Step 2: Local collection from server 222 itself (backup / standalone push)
0 */3 * * * cd /root/Linux_Server_Public && bash blacklist/collect-blacklist.sh >> /var/log/vladblacklist-collect.log 2>&1

# IPGuard Step 3: Pull latest blacklist from GitHub and apply to server 222 itself
30 */3 * * * bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh) >> /var/log/vladblacklist.log 2>&1
```


### 🔹 Cron Schedule on All Other 9 Nodes

```bash
# IPGuard: Pull latest blacklist from GitHub and apply atomically every 3 hours
30 */3 * * * bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh) >> /var/log/vladblacklist.log 2>&1
```


==============================================================


## 📁 Files in This Folder

| File | Where to run | Description |
|---|---|---|
| `blacklist.txt` | — | Plain IP list, one per line. Lines starting with `#` are comments |
| `blacklist-full.csv` | — | Full database: `ip, reason, source_server, date_added, source, duration` |
| `collect-from-vpn.sh` | **Server 222 only** | **IPGuard** master collector — SSHes into all 9 nodes, collects their CrowdSec decisions, merges, pushes to GitHub |
| `collect-blacklist.sh` | **Server 222 only** | Local collector — collects CrowdSec decisions from server 222 itself and pushes to GitHub |
| `deploy-blacklist.sh` | **Any server** | **IPGuard** deployer — fetches `blacklist.txt` from GitHub and applies via ipset/iptables with atomic swap |
| `install-crowdsec-vpn.sh` | **Any server** | Installer — installs CrowdSec + firewall bouncer + detection scenarios on any Ubuntu/Debian node |


==============================================================


## ⚪ Whitelist — Trusted IPs Protected by **IPGuard**

All trusted IPs (own servers, VPN clients, home/work) are protected from accidental bans via CrowdSec whitelist:
```
/etc/crowdsec/parsers/s02-enrich/my_whitelist.yaml
```

Source file in repo: [`crowdsec/my_whitelist.yaml`](../crowdsec/my_whitelist.yaml)

Deploy to any new server:
```bash
cp /root/Linux_Server_Public/crowdsec/my_whitelist.yaml \
   /etc/crowdsec/parsers/s02-enrich/my_whitelist.yaml
crowdsec -c /etc/crowdsec/config.yaml -t && systemctl reload crowdsec
```

Active whitelists on each server:
| File | Purpose |
|---|---|
| `my_whitelist.yaml` | Own servers, VPN clients, home/work IPs |
| `letsencrypt-whitelist.yaml` | Let's Encrypt ACME validation servers |


==============================================================


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


==============================================================


## 🛡️ Install CrowdSec on a New Node (**IPGuard** integration)

To run your own attack detection and feed data into **IPGuard**:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/install-crowdsec-vpn.sh)
```

This installs:
- CrowdSec engine (latest stable)
- CrowdSec firewall bouncer for iptables
- Detection collections: `sshd`, `linux` base scenarios
- `nginx` or `apache2` collections if a web server is detected


==============================================================


## 🔧 Technical Details

### Atomic ipset Swap — Zero Downtime Updates

The key technique used in **IPGuard**'s `deploy-blacklist.sh`:

```bash
# WRONG — gap between destroy and recreate leaves server unprotected:
ipset destroy vladblacklist        # iptables rule now points to nothing!
ipset create vladblacklist hash:net
ipset restore < /etc/ipset.rules

# RIGHT — atomic swap, zero gap, zero risk:
ipset create vladblacklist_tmp hash:net
while read ip; do ipset add vladblacklist_tmp "$ip"; done < blacklist.txt
ipset swap vladblacklist_tmp vladblacklist  # instant, atomic
ipset destroy vladblacklist_tmp            # cleanup old set
```

The `iptables` rule always references `vladblacklist` which always contains a valid, populated set.
During the entire update process **not a single IP is temporarily unblocked**.


### CrowdSec v1.7 — `Ip:` Prefix in Raw Output

CrowdSec v1.7 changed the raw CSV format — the IP column now contains `Ip:1.2.3.4` instead of just `1.2.3.4`.
Both **IPGuard** collection scripts handle this transparently:

```awk
# Strip the Ip: prefix before validation
sub(/^[Ii]p:/, "", ip)
if (ip == "" || ip !~ /^[0-9]/) next
```


### Remote Script Injection via SSH Heredoc

`collect-from-vpn.sh` avoids the classic SSH + awk quoting nightmare by uploading a self-contained script to each node:

```bash
# BAD: nested quoting hell
ssh root@node "awk -F',' '{ print \$3 }' file"

# GOOD: upload script as heredoc, run cleanly
REMOTE_SCRIPT=$(cat <<'REMOTE'
#!/bin/bash
cscli decisions list -o raw | awk -F',' '{ print $3 }'
REMOTE
)
ssh root@node "cat > /tmp/_script.sh && bash /tmp/_script.sh" <<< "$REMOTE_SCRIPT"
```


==============================================================


## 🐛 Bugs Fixed During Development

| # | Bug | Root Cause | Fix |
|---|---|---|---|
| 1 | IPs not added, `Skipped: N` in output | CrowdSec v1.7 adds `Ip:` prefix to every IP in raw CSV output | `sub(/^[Ii]p:/,"",ip)` in all awk parsers |
| 2 | `ipset swap` type conflict error | Existing set was `hash:ip`, new set was `hash:net` — types must match to swap | Recreate all sets as `hash:net` from scratch |
| 3 | `/etc/iptables/: No such file or directory` | Directory absent on fresh VPN nodes | Added `mkdir -p /etc/iptables` to `deploy-blacklist.sh` |
| 4 | `$3: unbound variable` on remote nodes | `set -u` in bash + `$3` in awk string passed through SSH — bash expanded `$3` before SSH | Removed `set -u`, moved remote logic to heredoc script |
| 5 | `[[: 0\n0: syntax error in expression` | `grep -c` on empty file returned `"0\n0"` (two lines), `[[ "0\n0" -gt 0 ]]` failed | Added `\| tr -d ' \n'` to strip newlines from all count variables |
| 6 | CrowdSec reload fails after whitelist append | Bare IP list appended to yaml without `whitelist:` wrapper — invalid YAML structure | Restored correct document structure; consolidated to single `my_whitelist.yaml` |


==============================================================


## 📊 Blacklist Format

### blacklist.txt
```
# ==========================================================
# IPGuard — VladiMIR IP Blacklist | Real Attack IPs
# Sources: CrowdSec on all 10 nodes of VladiMIR infrastructure
# Updated: 2026-05-28 | Total: 118+ IPs
# Repo: github.com/GinCz/Linux_Server_Public
# = Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz =
# ==========================================================
1.12.243.31
1.14.149.189
...
```

### blacklist-full.csv
```csv
ip,reason,source_server,date_added,source,duration
1.12.243.31,crowdsecurity/http-probing,109-RU-FastVDS,2026-05-28,crowdsec,3h
27.79.2.71,crowdsecurity/ssh-bf,EU-Alex-47,2026-05-28,crowdsec,3h
45.148.10.0/24,subnet-ban: 3 IPs from same /24 attacked,VPN-EU-Shahin-227,2026-05-28,crowdsec,693h
...
```


==============================================================


## ⚠️ Disclaimer

These IPs were blocked based on **real attack traffic** observed on production servers.
The list reflects active bans at the time of collection — CrowdSec decisions expire (typically 3h to 30 days depending on severity),
so IPs rotate naturally. Use at your own discretion.
Always verify compatibility with your own infrastructure before applying mass IP blocks to production systems.


==============================================================


## 📜 License

Public domain. Free to use for any purpose, no attribution required.


==============================================================

*= Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz =*
