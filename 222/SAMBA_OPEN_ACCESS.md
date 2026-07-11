# Samba Open Access — Server 222

```
= Rooted by VladiMIR + AI | v.2026.07.11 | github.com/GinCz =
```

## Summary

On **2026-07-11**, Samba SMB ports were opened for **all IP addresses** on server 222 (152.53.182.222).

Previously, access was restricted to a whitelist of specific IPs (primarily VPN nodes and 87.199.206.79).  
This caused connectivity issues when connecting from dynamic or unknown IPs (work, client sites, mobile ISPs).

Access is secured by **Samba user authentication only** — no guest access, `map to guest = never`.

---

## Problem

- Client connecting from IP `185.63.97.6` (and other dynamic IPs) could not reach shares.
- `Test-NetConnection` to ports 139 and 445 failed despite successful ICMP ping.
- Investigation confirmed: no bans in iptables / UFW / Fail2ban / CrowdSec on the server side.
- Root cause A: iptables only had `ACCEPT` rules for specific IPs — all others were dropped.
- Root cause B: Some ISPs (especially consumer broadband) block **outbound port 445** globally to prevent SMB malware spreading. This is an ISP-level transport block that cannot be bypassed on the client side.

---

## Solution Applied

### 1. iptables — opened for all IPs

**Before (2026-07-11):**
```
ACCEPT  tcp  87.199.206.79  dpt:139
ACCEPT  tcp  87.199.206.79  dpt:445
ACCEPT  udp  87.199.206.79  dpt:137
ACCEPT  udp  87.199.206.79  dpt:138
```

**After (2026-07-11):**
```
ACCEPT  tcp  0.0.0.0/0  dpt:445
ACCEPT  tcp  0.0.0.0/0  dpt:139
ACCEPT  udp  0.0.0.0/0  dpt:138
ACCEPT  udp  0.0.0.0/0  dpt:137
```

Rules saved persistently via `netfilter-persistent save`.

### 2. smb.conf — removed hosts allow / hosts deny

No `hosts allow` or `hosts deny` directives were found in `/etc/samba/smb.conf` at the time of change.  
The `[global]` section was confirmed clean — open to all IPs by default.

**smb.conf [global] effective config:**
```ini
[global]
   log level = 2
   max log size = 1000
   log file = /var/log/samba/log.%m
   invalid users = root bin daemon nobody
   max smbd processes = 100
   ntlm auth = yes
   server min protocol = SMB2
   workgroup = WORKGROUP
   security = user
   map to guest = never
   dns proxy = no
```

### 3. CrowdSec — existing bans cleared

All active CrowdSec IP bans were cleared once to unblock any previously banned Samba clients.  
CrowdSec continues to monitor HTTP/SSH traffic and will re-ban attackers automatically.

> **Note:** CrowdSec does NOT have an SMB scenario active — it only monitors nginx and SSH logs.  
> Samba brute-force protection relies on Samba's built-in lockout and Fail2ban (if samba jail is configured).

---

## Samba Shares

| Share | Path | vlad | usr | Notes |
|-------|------|------|-----|-------|
| `storage` | `/storage` | RO | RO | Root — shows soft and user folders |
| `soft` | `/storage/soft` | RW | RO | Software storage |
| `user` | `/storage/user` | RW | RW | User storage |

**Users:** `vlad` (read-write on all), `usr` (read-only on soft, read-write on user)  
**Guest access:** disabled (`map to guest = never`)  
**Min protocol:** SMB2 (SMB1 disabled for security)

---

## Connection (Windows)

```
\\152.53.182.222\storage
\\152.53.182.222\soft
\\152.53.182.222\user
```

Or using hostname if DNS resolves:
```
\\s.gincz.com\storage
```

> **If your ISP blocks port 445:** Use SSH tunnel workaround — see `WORKLOG.md` entry 2026-07-11.

---

## Security Notes

- Samba is protected by username + password authentication only.
- `root`, `bin`, `daemon`, `nobody` are explicitly blocked via `invalid users`.
- SMB1 is disabled — minimum protocol is SMB2.
- No guest/anonymous access possible.
- The same open-access policy should be applied to **server 109 (212.109.223.109)** — see `109/` folder.

---

## Rollback

To restore IP-restricted access (if needed):

```bash
# Remove open rules
iptables -D INPUT -p tcp --dport 445 -j ACCEPT
iptables -D INPUT -p tcp --dport 139 -j ACCEPT
iptables -D INPUT -p udp --dport 137 -j ACCEPT
iptables -D INPUT -p udp --dport 138 -j ACCEPT

# Add back whitelist-only rules
iptables -A INPUT -s YOUR_IP -p tcp --dport 445 -j ACCEPT
iptables -A INPUT -s YOUR_IP -p tcp --dport 139 -j ACCEPT
netfilter-persistent save
```

---

Last updated: **2026-07-11 22:00 CEST**

```
= Rooted by VladiMIR + AI | v.2026.07.11 | github.com/GinCz =
```
