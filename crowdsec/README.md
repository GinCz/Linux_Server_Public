# crowdsec/

> CrowdSec configuration files, whitelists, and acquisition rules for all 10 servers.
> CrowdSec is the primary intrusion detection and ban system across the entire fleet.
>
> = Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz =

---

## What is CrowdSec?

[CrowdSec](https://crowdsec.net/) is an open-source, collaborative IPS (Intrusion Prevention System).
It parses logs, detects attack patterns, and triggers bans via bouncers (iptables, firewall).

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
| 91.84.118.178 | VPN-PILIK-178 |
| 146.103.110.176 | VPN-ILYA-176 |
| 144.124.233.38 | VPN-SO-38 |
| 185.100.197.16 | Home IP (primary) |
| 185.14.233.235 | Home IP (secondary) |
| 185.14.232.0 | Home IP (tertiary) |
| 90.181.133.10 | Work IP |

---

## Known Issues Fixed (2026-05-28)

All 10 servers had the same 4 misconfigurations. Fixed via `scripts/fix_crowdsec_global.sh`:

### 1. `sshd.yaml` — duplicate source + wrong type

**Problem:** CrowdSec was acquiring SSH logs from both `journalctl` AND `auth.log` simultaneously,
with incorrect `type: ssh` instead of `type: syslog`. Parser could not parse events → high Unparsed rate.

**Fix:**
```yaml
# /etc/crowdsec/acquis.d/sshd.yaml
filenames:
  - /var/log/auth.log
  - /var/log/auth.log.1
labels:
  type: syslog
source: file
```

### 2. `setup.smb.yaml` — wide glob

**Problem:** Auto-generated file used `log.*` and `*.log` globs, causing CrowdSec to tail
hundreds of per-IP Samba log files (`log.192.168.1.1`, etc.) instead of just `log.smbd`.

**Fix:**
```yaml
# /etc/crowdsec/acquis.d/setup.smb.yaml
filenames:
  - /var/log/samba/log.smbd
labels:
  type: smb
source: file
```

### 3. `smb.conf` — log level = 2

**Problem:** `log level = 2` caused Samba to write a separate `log.<IP>` file for every connecting client.

**Fix:** `log level = 1` — writes only to `log.smbd`.

### 4. Per-IP log files polluting disk

**Problem:** Hundreds of `log.<IP>` files accumulating in `/var/log/samba/`.

**Removed totals across all servers:**

| Server | Files deleted | Space freed |
|---|---|---|
| 222-DE-NetCup | 2407 | ~0 (already rotated) |
| 109-RU-FastVDS | 329 | 5MB |
| VPN-ALEX-47 | 571 | 2MB |
| VPN-4TON-237 | 19 | — |
| VPN-TATRA-9 | 19 | 0.1MB |
| VPN-STOLB-24 | 277 | 0.1MB |
| VPN-SO-38 | 547 | 0.7MB |
| VPN-SHAHIN-227 | 0 | already fixed |
| VPN-PILIK-178 | 0 | already fixed |
| VPN-ILYA-176 | 0 | already fixed |

---

## Useful Commands

```bash
# Check active bans
cscli decisions list

# Test if IP is whitelisted
cscli decisions add --ip 185.100.197.16 --type ban --duration 1m --dry-run

# Check parser metrics
cscli metrics

# Reload CrowdSec config
systemctl reload crowdsec

# Check bouncer status
cscli bouncers list
```

---

*= Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz =*
