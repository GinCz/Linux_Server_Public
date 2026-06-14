# SESSION LOG — STOLB-24 | 2026-06-14

> = Rooted by VladiMIR + AI | v.2026.06.14 | github.com/GinCz

---

## Goal

Investigate and permanently fix periodic DNS failures on STOLB-24 (144.124.239.24).
AdGuard Home was failing to resolve DNS 2-3 times per month, causing full outage for all DNS clients.

---

## Root Causes Found

### Root Cause 1: `netfilter-persistent` failed on every reboot

**Symptom:**
```
netfilter-persistent[692]: iptables-restore: Set doesn't exist
Error occurred at line: 50
netfilter-persistent.service: Failed with result 'exit-code'
```

**Why it happened:**

The file `/etc/iptables/rules.v4` was saved by `deploy-blacklist.sh` (via `netfilter-persistent save` or `iptables-save`) while ALL runtime chains were active — including:
- `--match-set vladblacklist src` (ipset created by deploy-blacklist.sh, only exists after cron runs)
- `--match-set crowdsec-blacklists-0/1 src` (ipsets created by CrowdSec, only exist after CrowdSec starts)
- UFW chains: `ufw-before-logging-input`, `ufw-before-input`, etc. (only exist after UFW starts)

At reboot, `netfilter-persistent` runs early in boot sequence. At that moment:
- CrowdSec has not started yet → its ipsets do not exist → `iptables-restore` fails at first `--match-set crowdsec` reference
- UFW has not started yet → its chains do not exist → `iptables-restore` fails at first `ufw-before-*` reference
- `vladblacklist` ipset only restored from `/etc/ipset.rules` via `@reboot` cron, which runs later

Result: `netfilter-persistent` exits with error → **none of our DNS bypass rules load at boot** → DNS port 53 is blocked by INPUT DROP policy until someone manually fixes iptables.

**How we found it:**
After reboot, `iptables -L INPUT -n --line-numbers` showed `CROWDSEC_CHAIN` at position 1 with no DNS bypass rules above it.

**Fix:**
Rewrite `rules.v4` and `rules.v6` to contain ONLY minimal bypass rules — no UFW chains, no CrowdSec chains, no ipset references. Each service adds its own rules when it starts:

```
# /etc/iptables/rules.v4 — CORRECT minimal content:
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -p udp --dport 53  -j ACCEPT  # DNS bypass
-A INPUT -p tcp --dport 53  -j ACCEPT  # DNS bypass
-A INPUT -p tcp --dport 853 -j ACCEPT  # DoT bypass
-A INPUT -p udp --dport 853 -j ACCEPT  # DoT bypass
-A INPUT -p tcp --dport 443 -j ACCEPT  # DoH bypass
-A INPUT -p tcp --dport 8443 -j ACCEPT # XRAY VPN bypass
-A INPUT -p tcp --dport 8080 -j ACCEPT # AdGuard Web UI
-A INPUT -i lo -j ACCEPT
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p tcp --dport 22 -j ACCEPT
COMMIT
```

---

### Root Cause 2: `deploy-blacklist.sh` inserted vladblacklist DROP at position 1

**Symptom:**
After cron ran `deploy-blacklist.sh`, the INPUT chain looked like:
```
1  DROP  all  match-set vladblacklist src   ← FIRST! Blocks everything including DNS
2  ACCEPT udp dpt:53
3  ...
```

Any IP in the vladblacklist had its DNS queries dropped BEFORE reaching the ACCEPT rule for port 53.

**Why it happened:**
The original script used:
```bash
iptables -I INPUT 1 -m set --match-set vladblacklist src -j DROP
```
`-I INPUT 1` always inserts at position 1, pushing all other rules down.

**Additional problem in the same script:**
The script also called `netfilter-persistent save` after inserting the vladblacklist rule. This saved the FULL runtime state of iptables (including UFW chains, CrowdSec chains, vladblacklist ipset reference) into `rules.v4`. Next reboot → `netfilter-persistent` failed again (see Root Cause 1).

**Fix:**
`deploy-blacklist.sh` updated ([commit 39b6e85](https://github.com/GinCz/Linux_Server_Public/commit/39b6e853f65dbc37d9a33c66b2cfe1b9a3078a9c)):
- `get_insert_position()` function finds the last DNS/VPN bypass rule position and inserts vladblacklist DROP AFTER it
- Removed `netfilter-persistent save` and `iptables-save > rules.v4` entirely
- Only `ipset save > /etc/ipset.rules` is kept for persistence
- Added DNS position verification with warning if order is wrong

```bash
# NEW logic in deploy-blacklist.sh:
get_insert_position() {
  local last_bypass_pos=0
  while IFS= read -r line; do
    pos=$(echo "$line" | awk '{print $1}')
    if echo "$line" | grep -qE "dpt:(53|853|443|8443|8080)"; then
      [ "$pos" -gt "$last_bypass_pos" ] && last_bypass_pos=$pos
    fi
  done < <(iptables -L INPUT -n --line-numbers)
  echo $((last_bypass_pos + 1))
}

INSERT_POS=$(get_insert_position)
iptables -I INPUT "$INSERT_POS" -m set --match-set "$IPSET_NAME" src -j DROP
```

---

### Root Cause 3: DNS bypass rules were AFTER CrowdSec at boot

**Symptom:**
After reboot (even when `netfilter-persistent` succeeded), CrowdSec's bouncer ran and prepended `CROWDSEC_CHAIN` at position 1. Our DNS bypass rules ended up BELOW CrowdSec.

**Why it happened:**
CrowdSec firewall bouncer uses `iptables -I INPUT 1` to insert its chain. If it starts AFTER `netfilter-persistent` has loaded the bypass rules, it pushes them all down by one position. So `CROWDSEC_CHAIN` ends up at pos 1, DNS bypass at pos 2+.

This means: if a client's IP is in CrowdSec's blacklist → their DNS queries are dropped by `CROWDSEC_CHAIN` before reaching `ACCEPT dpt:53`.

**Fix applied:**
1. Two-layer protection: `dns-bypass-ensure.sh` script created at `/root/scripts/dns-bypass-ensure.sh`
2. Added to crontab: `@reboot sleep 45` (runs after all services) + `*/10 * * * *` (periodic check)
3. Script detects if DNS rules are below CrowdSec and re-inserts them at position 1 if needed

```bash
# dns-bypass-ensure.sh verifies:
DNS_POS=$(iptables -L INPUT -n --line-numbers | grep "dpt:53" | head -1 | awk '{print $1}')
CS_POS=$(iptables -L INPUT -n --line-numbers | grep "CROWDSEC_CHAIN" | head -1 | awk '{print $1}')
[ "$DNS_POS" -lt "$CS_POS" ] && echo "OK" || echo "WARNING — reinsert needed"
```

---

### Root Cause 4: Only one AdGuard upstream — single point of failure

**Symptom:**
Logs showed repeated:
```
exchange failed upstream=https://dns10.quad9.net:443/dns-query err="unexpected EOF"
```
With only one upstream configured, any Quad9 outage = total DNS outage for all clients.

**Fix:**
Added 5 upstream servers in `parallel` mode via `sed` in `/opt/AdGuardHome/AdGuardHome.yaml`:
```yaml
upstream_dns:
  - https://dns10.quad9.net/dns-query
  - https://cloudflare-dns.com/dns-query
  - https://dns.google/dns-query
  - tls://1.1.1.1
  - tls://8.8.8.8
fallback_dns:
  - 1.1.1.1
  - 8.8.8.8
upstream_mode: parallel
```

**Note:** Python `yaml.safe_load` + `yaml.dump` approach corrupted the file (duplicate keys, wrong indentation). Use `sed` for targeted in-place replacements in AdGuardHome.yaml.

---

### Root Cause 5: `@reboot` crontab missing `ip6tables-restore`

**Was:**
```
@reboot sleep 5 && ipset restore < /etc/ipset.rules; iptables-restore < /etc/iptables/rules.v4
```

**Fixed to:**
```
@reboot sleep 15 && ipset restore < /etc/ipset.rules 2>/dev/null; iptables-restore < /etc/iptables/rules.v4 2>/dev/null; ip6tables-restore < /etc/iptables/rules.v6 2>/dev/null
```
Increased sleep from 5s to 15s, added `ip6tables-restore`, suppressed errors with `2>/dev/null`.

---

## Why Previous Attempts Failed

### Attempt 1: Add UFW chains back to rules.v4
Failed because UFW chains (`ufw-before-logging-input` etc.) are created dynamically by UFW on startup — they cannot be pre-defined in `rules.v4`. `iptables-restore` refuses to load rules referencing non-existent chains.

### Attempt 2: Use Python yaml.safe_load to edit AdGuardHome.yaml
Failed because PyYAML `yaml.dump` does not preserve key order and creates duplicate keys when the yaml has nested structures with same key names at different indent levels. AdGuardHome.yaml has both root-level and nested `upstream_mode` keys. Result: AdGuard refused to start with the corrupted config.

### Attempt 3: Drop-in `after-crowdsec.conf` for service ordering
Added `After=crowdsec.service` to netfilter-persistent. This helped with startup ORDER but did not solve the rules.v4 content problem — even starting after CrowdSec, `iptables-restore` still fails if rules.v4 references UFW chains that UFW hasn't created yet.

---

## Final State After Session

```
netfilter-persistent:         active (exited) — Finished  [no more crashes!]
AdGuardHome:                  active
crowdsec:                     active
crowdsec-firewall-bouncer:    active
ufw:                          active
x-ui:                         active
fail2ban:                     active

iptables INPUT chain order (post-boot):
1   ACCEPT udp dpt:53   DNS bypass      ← FIRST
2   ACCEPT tcp dpt:53   DNS bypass
3   ACCEPT tcp dpt:853  DoT bypass
4   ACCEPT udp dpt:853  DoT bypass
5   ACCEPT tcp dpt:443  AdGuard DoH
6   ACCEPT tcp dpt:8443 XRAY VPN
7   ACCEPT tcp dpt:8080 AdGuard Web UI
8   CROWDSEC_CHAIN                      ← CrowdSec after DNS
9   ACCEPT lo
10  ACCEPT RELATED,ESTABLISHED
11  ACCEPT tcp dpt:22
..  vladblacklist DROP                  ← added by cron, always after DNS bypass

DNS resolution tests: google.com, cloudflare.com, ya.ru — all OK
AdGuard upstream: 5 servers in parallel mode — no single point of failure
```

---

## Files Modified

| File | Change |
|---|---|
| `/etc/iptables/rules.v4` | Rewritten — only bypass rules, no UFW/CrowdSec/ipset chains |
| `/etc/iptables/rules.v6` | Rewritten — same approach for IPv6 |
| `/opt/AdGuardHome/AdGuardHome.yaml` | 5 upstream DNS servers, parallel mode, fallback DNS |
| `/root/scripts/dns-bypass-ensure.sh` | NEW — ensures DNS bypass stays before CrowdSec |
| `crontab` | Added `@reboot sleep 45 dns-bypass-ensure.sh` + `*/10 * * * *` |
| `crontab` | Fixed `@reboot` — added `ip6tables-restore`, sleep 5→15 |
| `blacklist/deploy-blacklist.sh` | Fixed INSERT position + removed `netfilter-persistent save` |
| `/etc/systemd/system/netfilter-persistent.service.d/after-crowdsec.conf` | NEW drop-in: `After=crowdsec.service` |

---

## The Golden Rule for This Server Stack

> **`rules.v4` and `rules.v6` must ONLY contain simple bypass rules.**
> **Never save UFW chains, CrowdSec chains, or ipset references into these files.**
> **Never run `netfilter-persistent save` or `iptables-save > rules.v4` while UFW/CrowdSec are active.**
> **Each service (UFW, CrowdSec, fail2ban, deploy-blacklist.sh) adds its own rules when it starts.**
> **DNS ports 53/853/443 must always be FIRST in INPUT chain — before any blacklist or firewall chain.**

---

## Checklist for Other Servers (109, 222, VPN nodes)

If any server runs AdGuard Home + CrowdSec + UFW + deploy-blacklist.sh, verify:

```bash
# 1. Check rules.v4 has NO ipset/UFW/CrowdSec references
grep -cE "match-set|ufw-|CROWDSEC" /etc/iptables/rules.v4 && echo "PROBLEM" || echo "OK"

# 2. Check DNS bypass is BEFORE CrowdSec
DNS=$(iptables -L INPUT -n --line-numbers | grep "dpt:53" | head -1 | awk '{print $1}')
CS=$(iptables -L INPUT -n --line-numbers | grep "CROWDSEC_CHAIN" | head -1 | awk '{print $1}')
[ "$DNS" -lt "$CS" ] && echo "DNS before CrowdSec: OK" || echo "WARNING"

# 3. Check AdGuard has multiple upstreams
grep -c "upstream_dns" /opt/AdGuardHome/AdGuardHome.yaml

# 4. Check netfilter-persistent is healthy
systemctl status netfilter-persistent | grep -E "Active:|Finished|failed"

# 5. Check deploy-blacklist.sh version (must be v.2026.06.14 or newer)
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh | grep "^# = Rooted"
```

---

## Key Insight: Boot Startup Order on This Server

```
Boot sequence (approximate):
 1. kernel
 2. network-online.target
 3. netfilter-persistent  → loads rules.v4 (bypass rules only)
 4. ufw                   → adds ufw-* chains + port rules + whitelist IPs
 5. fail2ban              → adds f2b-sshd chain
 6. crowdsec              → starts agent
 7. crowdsec-firewall-bouncer → adds CROWDSEC_CHAIN at INPUT pos 1 (pushes bypass down!)
 8. AdGuardHome           → starts DNS server
 9. x-ui                  → starts XRAY
10. @reboot cron (sleep 15) → restores ipset, iptables, ip6tables
11. @reboot cron (sleep 45) → dns-bypass-ensure.sh re-pins DNS bypass to top
12. */10 cron             → dns-bypass-ensure.sh checks every 10 min
13. */3h cron             → deploy-blacklist.sh updates vladblacklist (inserts AFTER bypass)
```

CrowdSec bouncer at step 7 inserts `CROWDSEC_CHAIN` at position 1 every time it starts.
This is why `dns-bypass-ensure.sh` is needed — it runs at step 11 and re-moves DNS bypass above CrowdSec.
