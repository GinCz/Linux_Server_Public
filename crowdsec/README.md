# CrowdSec — Linux Server IPS Configuration (VladiMIR Bulantsev / GinCz)

> CrowdSec configuration files, whitelists, and acquisition rules for all 10 servers.  
> CrowdSec is the primary intrusion detection and ban system across the entire fleet.  
> **Keywords:** CrowdSec · Linux server · Ubuntu · sysadmin · IPGuard · Fail2Ban · bash scripting · VPN server · XRAY VPN · Ubuntu server · security hardening
>
> = Rooted by VladiMIR Bulantsev (GinCz) | v.2026.07.11 | github.com/GinCz =

---

## 🔴 MANDATORY RULES — Read Before ANY Change

> These rules were written after 3 hours of unnecessary work on 2026-05-28.
> Do not skip them.

1. **Test first with `cscli explain`** before changing any parser or acquisition config
2. **Deploy to ONE server first**, verify metrics after 5 minutes, then deploy to all
3. **Never change `sshd.yaml`** without checking that `Parsed > 0` after restart
4. **`Parsed = 0` is NORMAL** when there are no active attacks — do NOT fix what is not broken
5. **`sshd-logs` RED in `cscli explain`** is NORMAL when testing with `Accepted publickey` line

### How to test before deploying:
```bash
# 1. Test parser with a FAILED login line
echo "May 28 19:00:00 hostname sshd[1234]: Invalid user admin from 1.2.3.4 port 12345" \
  | cscli explain --type syslog --file - 2>&1

# 2. Check metrics 5 minutes after any change
cscli metrics | grep sshd-logs

# 3. Deploy to one server first
ssh root@152.53.182.222 "bash <(curl -fsSL <script_url>)"
# Wait 5 min, verify, THEN run on all servers
```

---

## What is CrowdSec?

[CrowdSec](https://crowdsec.net/) is an open-source, collaborative IPS (Intrusion Prevention System).
It parses logs, detects attack patterns, and triggers bans via bouncers (iptables, firewall).

---

## Correct sshd.yaml (Ubuntu 24, all servers)

```yaml
# /etc/crowdsec/acquis.d/sshd.yaml
# journalctl = primary (Ubuntu 24 compatible)
# auth.log   = secondary fallback
---
source: journalctl
journalctl_filter:
  - "_SYSTEMD_UNIT=ssh.service"
  - "_COMM=sshd"
labels:
  type: syslog
---
filenames:
  - /var/log/auth.log
  - /var/log/auth.log.1
labels:
  type: syslog
source: file
```

> **Why `_COMM=sshd`?** On some servers `_SYSTEMD_UNIT=ssh.service` returns no data.
> `_COMM=sshd` works universally across all Ubuntu 24 servers in the fleet.

---

## Files

### `my_whitelist.yaml`
**Version:** v2026.05.28
**Deploy to:** `/etc/crowdsec/parsers/s02-enrich/my_whitelist.yaml` on every server

Trusted IP whitelist — all server IPs, home IPs, and work IP are whitelisted in CrowdSec, iptables, and Samba.

| IP | Description |
|---|---|
| 152.53.182.222 | DE-222-NetCup — main server |
| 212.109.223.109 | RU-109-FastVDS |
| 109.234.38.47 | VPN-ALEX-47 |
| 144.124.228.237 | VPN-4TON-237 |
| 144.124.232.9 | VPN-TATRA-9 |
| 144.124.228.227 | VPN-SHAHIN-227 |
| 144.124.239.24 | VPN-STOLB-24 |
| 195.63.138.33 | VPN-PILIK-178 |
| 146.103.110.176 | VPN-ILYA-176 |
| 144.124.233.38 | VPN-SO-38 |
| 185.100.197.16 | Home IP (primary) |
| 185.14.233.235 | Home IP (secondary) |
| 185.14.232.0 | Home IP (tertiary) |
| 90.181.133.10 | Work IP |

---

## How to Read CrowdSec Metrics — What is Normal

```
| child-crowdsecurity/sshd-logs     | 160 | -  | 160 |  ← NORMAL if no active attacks
| crowdsecurity/sshd-success-logs   |  10 | 10 |  0  |  ← your SSH logins (whitelisted)
```

- `sshd-logs` only parses **failed** login attempts (`Invalid user`, `Failed password`)
- `sshd-success-logs` parses **successful** logins (`Accepted publickey`)
- If no attacks are happening — `Parsed = 0` or very low is **completely normal**
- High `Unparsed` = systemd/pam lines that sshd-logs ignores by design

---

## Known Issues Fixed (2026-05-28)

All 10 servers had the same 4 misconfigurations. Fixed via `scripts/fix_crowdsec_global.sh`:

### 1. `sshd.yaml` — wrong source type
**Problem:** Using only `file` source broke SSH parsing on Ubuntu 24 (100% Unparsed).
**Fix:** Restored `journalctl` as primary source with `_COMM=sshd` filter.

### 2. `setup.smb.yaml` — wide glob
**Problem:** `log.*` glob caused CrowdSec to tail hundreds of per-IP Samba log files.
**Fix:** Single file `log.smbd` only.

### 3. `smb.conf` — log level = 2
**Problem:** Created a separate `log.<IP>` file per connecting client.
**Fix:** `log level = 1`

### 4. Per-IP log files polluting disk
**Removed totals across all servers:**

| Server | Files deleted |
|---|---|
| 222-DE-NetCup | 2407 |
| 109-RU-FastVDS | 329 |
| VPN-ALEX-47 | 571 |
| VPN-4TON-237 | 19 |
| VPN-TATRA-9 | 19 |
| VPN-STOLB-24 | 277 |
| VPN-SO-38 | 547 |

---

## Useful Commands

```bash
# Check active bans
cscli decisions list

# Test parser with a failed SSH login
echo "May 28 19:00:00 hostname sshd[1234]: Invalid user admin from 1.2.3.4 port 12345" \
  | cscli explain --type syslog --file - 2>&1

# Check parser metrics
cscli metrics | grep sshd

# Check bouncer status
cscli bouncers list

# Reload CrowdSec config
systemctl reload crowdsec
```

---

## 🔍 About This Project

This **CrowdSec** configuration is part of the [Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public) toolkit maintained by **VladiMIR Bulantsev (GinCz)**.

Full security stack on each **Linux server** (Ubuntu 24 LTS):

> **CrowdSec** · **Fail2Ban** · **IPGuard** · **XRAY VPN** · VPN server · **Samba** · **FastPanel** · Cloudflare · iptables · ipset · bash scripting · Ubuntu · Ubuntu server · Linux server · Windows server · sysadmin · DevOps · Czech Republic · PowerShell

🔗 Full documentation: [GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)  
👤 Author: [github.com/GinCz](https://github.com/GinCz) — VladiMIR Bulantsev

---

*= Rooted by VladiMIR Bulantsev + AI | v.2026.07.11 | github.com/GinCz =*
