# 🛡️ VladiMIR IP Blacklist — Real Attack IPs

> Automatically collected, publicly available IP blacklist from real DDoS and brute-force attacks detected across the VladiMIR server infrastructure.

**Live blacklist (plain text, one IP per line):**
```
https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/blacklist.txt
```

**Full database (CSV with reason, date, server, duration):**
```
https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/blacklist-full.csv
```

---

## 📋 What Is This?

This blacklist is a real-world, production IP blocklist built from live attack data across a private European server infrastructure running 10+ nodes.

Sources of blocked IPs:
- **CrowdSec** — community-driven intrusion prevention system, detecting brute-force, DDoS, web scanning, and exploit attempts
- **iptables manual bans** — manually added IPs from verified attack incidents
- **Permanent ban list** — persistent entries that survived CrowdSec decision expiry

The list is updated **every 3 hours** automatically on the primary collection server (222-EU-NetCup, NetCup DE, `152.53.182.222`) and immediately propagated to all infrastructure nodes via SSH.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│           222-EU-NetCup (152.53.182.222)                 │
│           Primary server — NetCup DE                     │
│                                                          │
│  CrowdSec decisions                                      │
│       │                                                  │
│       ▼                                                  │
│  collect-blacklist.sh  ──►  blacklist.txt                │
│                         ──►  blacklist-full.csv          │
│                         ──►  git push → GitHub           │
└────────────────────────────┬────────────────────────────┘
                             │  GitHub Raw URL
                             ▼
          ┌──────────────────────────────────────┐
          │   deploy-blacklist.sh (on each node)  │
          │                                       │
          │   curl blacklist.txt                  │
          │       │                               │
          │       ▼                               │
          │   ipset create vladblacklist_tmp       │
          │   ipset add ... (all IPs)             │
          │   ipset swap tmp → vladblacklist      │  ← atomic, no downtime
          │   iptables DROP from vladblacklist    │
          │   save rules + @reboot cron           │
          └──────────────────────────────────────┘
                             │
              applied to all 10 nodes:
              109-RU-FastVDS / EU-Alex-47 / EU-4Ton-237
              EU-Tatra-Kuma-9 / VPN-EU-Shahin-227
              EU-Stolb-AG-24 / VPN-EU-Pilik-178
              VPN-EU-ILYA-176 / EU-SO-38
              (+ 222-EU-NetCup itself)
```

---

## 📁 Files

| File | Description |
|---|---|
| `blacklist.txt` | Plain list of blocked IPs, one per line, comments start with `#` |
| `blacklist-full.csv` | Full database: `ip, reason, source_server, date_added, country, duration` |
| `collect-blacklist.sh` | Run on server 222 — collects CrowdSec decisions and pushes to GitHub |
| `deploy-blacklist.sh` | Run on ANY server — downloads list from GitHub and applies via ipset/iptables |
| `collect-from-vpn.sh` | Helper — collects bans from VPN nodes (future multi-source support) |

---

## ⚙️ How It Works

### Collection (server 222 only)

`collect-blacklist.sh` runs every 3 hours via cron:
```
0 */3 * * * cd /root/Linux_Server_Public && bash blacklist/collect-blacklist.sh >> /var/log/vladblacklist-collect.log 2>&1
```

It:
1. Pulls latest repo state
2. Runs `cscli decisions list -o raw` and auto-detects column positions
3. Strips the `Ip:` prefix present in CrowdSec v1.7 raw output
4. Validates each entry (must start with a digit, no empty lines)
5. Writes clean `blacklist.txt` and full `blacklist-full.csv`
6. Commits and pushes to GitHub

### Deployment (any node)

`deploy-blacklist.sh` can be run on **any Linux server** with one command:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh)
```

It:
1. Downloads `blacklist.txt` from GitHub
2. Builds a **temporary** ipset `vladblacklist_tmp` with all IPs
3. **Atomically swaps** `vladblacklist_tmp` → `vladblacklist` (zero downtime, iptables rule is never broken)
4. Inserts `iptables -I INPUT 1 -m set --match-set vladblacklist src -j DROP`
5. Saves rules to `/etc/iptables/rules.v4` for persistence
6. Saves ipset to `/etc/ipset.rules`
7. Adds `@reboot` cron to restore both after server restart

### Key Technical Detail — Atomic Swap

The deployment uses `ipset swap` instead of destroy+recreate. This means:
- The iptables rule **always points to a valid, populated set**
- During update, no IPs are temporarily unblocked
- Safe to run as frequently as needed without any service interruption

---

## 🚀 Quick Start — Apply This Blacklist to Your Server

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh)
```

**Requirements:** `curl`, `iptables`, `ipset` — the script installs missing tools via `apt` automatically.

**Verify after deployment:**
```bash
ipset list vladblacklist | head -20
iptables -L INPUT -n | grep vladblacklist
```

---

## 🔄 Keeping It Up To Date

To re-apply the latest list (e.g. from cron):
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh)
```

The atomic swap makes this safe to run at any time, even on a live production server.

Add to cron for automatic updates every 3 hours:
```bash
(crontab -l 2>/dev/null; echo "0 */3 * * * bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh) >> /var/log/vladblacklist.log 2>&1") | crontab -
```

---

## 📊 Blacklist Format

### blacklist.txt
```
# ==========================================================
# VladiMIR IP Blacklist — Real Attack IPs
# Source: CrowdSec decisions, server 222 (152.53.182.222)
# Updated: 2026-05-27 21:18:00 | Total: 59 IPs
# Repo: github.com/GinCz/Linux_Server_Public
# ==========================================================
104.155.90.40
117.50.186.57
124.43.145.166
...
```

### blacklist-full.csv
```
ip,reason,source_server,date_added,country,duration
104.155.90.40,custom/wp-login-bf-any,222-DE-NetCup,2026-05-27,unknown,3h
...
```

---

## ⚠️ Disclaimer

These IPs were blocked based on **real attack traffic** observed on production servers. The list reflects active bans at the time of collection and may change with each update. Use at your own discretion — always verify compatibility with your own infrastructure before mass-blocking.

---

## 📜 License

Public domain. Free to use for any purpose.

---

*= Rooted by VladiMIR + AI | v.2026.05.27 | github.com/GinCz =*
