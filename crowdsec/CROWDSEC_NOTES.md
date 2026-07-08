# CrowdSec — Important Notes
> = Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz =

---

## ⚠️ DO NOT CHANGE sshd.yaml WITHOUT TESTING FIRST

Lesson learned 2026-05-28: changing `journalctl` to `file` source broke SSH parsing
on ALL 10 servers. 3 hours wasted restoring the original config.

---

## Correct sshd.yaml (works on all servers, Ubuntu 24)

```yaml
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

**Why both sources:**
- `journalctl` with `_COMM=sshd` — primary, works on all Ubuntu 24 servers
- `auth.log` file — secondary fallback

---

## How to Read CrowdSec Metrics — What is NORMAL

```
| child-crowdsecurity/sshd-logs     | 160 | -  | 160 |   ← NORMAL if no attacks
| crowdsecurity/sshd-success-logs   |  10 | 10 |  0  |   ← your SSH logins
```

### ✅ sshd-logs Parsed = 0 is NORMAL when:
- No brute-force attacks happened recently
- All hits are successful logins (yours) → go to `sshd-success-logs`
- Your IPs are whitelisted → counted as `ignored by whitelist`

### sshd-logs only parses FAILED attempts:
- `Invalid user`
- `Failed password`
- `Connection closed by invalid user`
- `Disconnected from invalid user`

### sshd-success-logs parses SUCCESSFUL logins:
- `Accepted publickey`
- `Accepted password`

### 🔴 sshd-logs RED in `cscli explain` = NORMAL
When testing with `Accepted publickey` line — sshd-logs will always be red.
This is correct behavior. Test with a FAILED login line to see green.

---

## How to Properly Test Parser

```bash
# Test with a FAILED login line (not successful)
echo "May 28 19:00:00 hostname sshd[1234]: Invalid user admin from 1.2.3.4 port 12345" \
  | cscli explain --type syslog --file - 2>&1
```

Expected: `sshd-logs` 🟢 green

---

## CrowdSec Metrics — All 10 Servers Status (2026-05-28)

| Server | IP | sshd Parsed | Status |
|---|---|---|---|
| 222-DE-NetCup | 152.53.182.222 | 119 | ✅ Active attacks detected |
| 109-RU-FastVDS | 212.109.223.109 | 36 | ✅ Active attacks detected |
| VPN-ALEX_47 | 109.234.38.47 | 10 | ✅ Working |
| VPN-STOLB_24 | 144.124.239.24 | 8 | ✅ Working |
| VPN-SHAHIN_227 | 144.124.228.227 | 2 | ✅ Working |
| VPN-4TON_237 | 144.124.228.237 | 0 | ✅ Normal (no attacks, whitelist active) |
| VPN-TATRA_9 | 144.124.232.9 | 0 | ✅ Normal (no attacks, whitelist active) |
| VPN-PILIK_33 | 195.63.138.33 | 0 | ✅ Normal (no attacks, whitelist active) |
| VPN-ILYA_176 | 146.103.110.176 | 0 | ✅ Normal (no attacks, whitelist active) |
| VPN-SO_38 | 144.124.233.38 | 0 | ✅ Normal (scenarios active: ssh-time-based-bf) |

---

## rsyslog Format (Ubuntu 24 issue)

Some servers use ISO timestamp format by default — CrowdSec parser cannot parse it.

**Fix:** Add to `/etc/rsyslog.conf` line 1:
```
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
```
Then: `systemctl restart rsyslog`

**Servers where this was applied:** VPN-TATRA_9, VPN-4TON_237
