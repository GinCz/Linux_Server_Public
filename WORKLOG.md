# WORKLOG — Linux_Server_Public

> Full session-by-session work log.
> = Rooted by VladiMIR | AI =

---

# 📅 Session: 2026-05-27

> Evening 27 May 2026
> Affected: **222-DE-NetCup** (152.53.182.222) — CrowdSec

---

## 📋 Session Summary

1. Fixed `letsencrypt-whitelist.yaml` — wrong `name:` field caused conflict with other whitelists
2. Diagnosed root cause of 60+ WARNING messages on every `cscli` command
3. Confirmed CrowdSec v1.7.8 — already latest version, no upgrade needed
4. Cleaned stale hub symlinks and reinstalled all collections with `--force`
5. All WARNING eliminated — parsers now show clean versions ✅

---

## 🔧 Fix 1 — letsencrypt-whitelist.yaml: wrong name field

### Problem

`/etc/crowdsec/parsers/s02-enrich/letsencrypt-whitelist.yaml` had:
```yaml
name: crowdsecurity/whitelists
```
Should be:
```yaml
name: crowdsecurity/letsencrypt-whitelist
```

This caused `cscli parsers list` to show name conflict / ambiguity with other whitelists.

### Fix

Edited file directly on server 222. Correct content saved to repo at:
`222/crowdsec/letsencrypt-whitelist.yaml`

---

## 🔧 Fix 2 — CrowdSec WARNING Ignoring File (60+ warnings)

### Symptom

Every `cscli` call produced 60+ lines like:
```
WARNING Ignoring file /etc/crowdsec/parsers/s01-parse/sshd-logs.yaml:
  lstat /etc/crowdsec/hub/parsers/s01-parse/crowdsecurity/sshd-logs.yaml: no such file or directory
```

### Investigation Steps

1. Ran `cscli version` → v1.7.8 — already latest
2. Ran `curl ... | apt-get install --only-upgrade crowdsec` → "already newest version"
3. Checked hub index → "Nothing to do, the hub index is up to date"
4. Checked `/etc/crowdsec/parsers/` structure → symlinks pointing to hub paths that no longer exist
5. `find /etc/crowdsec -type l ! -e` — BSD `find` on Ubuntu doesn't support `! -e` → returned 0 (false negative)

### Root Cause

CrowdSec v1.7+ changed internal hub storage structure. Old symlinks in `/etc/crowdsec/parsers/`, `/etc/crowdsec/scenarios/`, `/etc/crowdsec/collections/` etc. pointed to `/etc/crowdsec/hub/<type>/crowdsecurity/<file>.yaml` paths that were relocated during hub migration. The symlinks existed as filesystem objects but hub no longer had files at those locations.

### Fix Applied

```bash
# Delete stale symlinks (manual — BSD find ! -e not working on Ubuntu)
find /etc/crowdsec -type l | while read link; do
    [ ! -e "$link" ] && rm "$link"
done

# Reinstall all collections with --force to recreate correct symlinks
cscli collections install \
  crowdsecurity/linux \
  crowdsecurity/sshd \
  crowdsecurity/nginx \
  crowdsecurity/apache2 \
  crowdsecurity/wordpress \
  crowdsecurity/http-cve \
  crowdsecurity/base-http-scenarios \
  crowdsecurity/whitelist-good-actors \
  --force

systemctl restart crowdsec
```

### Downloaded During Fix

- Parsers: `syslog-logs`, `geoip-enrich` (+ GeoLite2-City.mmdb, GeoLite2-ASN.mmdb), `dateparse-enrich`, `sshd-logs`, `sshd-success-logs`, `nginx-logs`, `http-logs`, `apache2-logs`, `public-dns-allowlist`
- Postoverflows: `seo-bots-whitelist`, `cdn-whitelist` (Cloudflare IPs), `rdns`, `google-special-crawlers-whitelist`
- Scenarios: all CVE scenarios (2017–2024), `ssh-bf`, `ssh-slow-bf`, `ssh-time-based-bf`, `nginx-req-limit-exceeded`, `http-sqli-probing`, `http-xss-probing`, `http-technology-probing`, etc.
- Contexts: `bf_base`, `http_base`
- Collections: `linux`, `sshd`, `nginx`, `apache2`, `wordpress`, `http-cve`, `base-http-scenarios`, `whitelist-good-actors`

### Result

```
crowdsecurity/apache2-logs      ✔️  enabled  1.5
crowdsecurity/dateparse-enrich  ✔️  enabled  0.2
crowdsecurity/geoip-enrich      ✔️  enabled  0.5
crowdsecurity/http-logs         ✔️  enabled  1.3
crowdsecurity/nginx-logs        ✔️  enabled  2.0
crowdsecurity/public-dns-allowlist ✔️ enabled 0.1
crowdsecurity/sshd-logs         ✔️  enabled  3.1
crowdsecurity/sshd-success-logs ✔️  enabled  0.1
crowdsecurity/syslog-logs       ✔️  enabled  1.0
crowdsecurity/letsencrypt-whitelist 🏠 enabled,local
my_whitelist                    🏠  enabled,local
vladimir/whitelists             🏠  enabled,local
```

Zero WARNING messages. ✅

---

## 📂 Changed / Created Files

| File | Action | Notes |
|---|---|---|
| `222/crowdsec/letsencrypt-whitelist.yaml` | Created | Whitelist config for Let's Encrypt ACME IPs |
| `CHANGELOG.md` | Updated | Added session v2026.05.27 |
| `WORKLOG.md` | Updated | This file |

---

---

# 📅 Session: 2026-05-25 / 2026-05-26

> Evening 25 May → afternoon 26 May 2026
> Affected: **ALL VPN nodes** (8 servers), **scripts/shared_aliases.sh**, **install-night-maintenance.sh**

---

## 📋 Session Summary

1. Audited cron jobs on all 10 servers from main server 222 via SSH loop
2. Unified nightly maintenance: apt update + upgrade + reboot + post-reboot Telegram report
3. Removed duplicate `auto_upgrade.sh` cron entries from 4 VPN servers
4. Created `scripts/shared_aliases.sh` for VPN nodes (fixes `.bashrc` line 79 error on pilik178 + ilya176)
5. Fixed outdated repo on pilik178 and ilya176 via `git pull`
6. Created `install-night-maintenance.sh` — universal installer deployable via `curl` from GitHub
7. Deployed to all 8 VPN servers in one SSH loop from server 222

---

## 🔍 Cron Audit — All Servers

### Method

Ran cron inspection from server 222 across all servers:

```bash
for E in "222-DE-NetCup:152.53.182.222" "109-RU-FastVDS:212.109.223.109" ...; do
  ssh root@$I "crontab -l 2>/dev/null | grep -vE '^#|^$'"
done
```

### Results

| Server | Status | Issue |
|---|---|---|
| EU-Alex-47 | ✅ clean | — |
| EU-4Ton-237 | ✅ clean | — |
| EU-Tatra-Kuma-9 | ✅ clean | — |
| VPN-EU-Shain-227 | ⚠️ duplicate | `auto_upgrade.sh` at Sunday 03:30 — removed |
| EU-Stolb-AG-24 | ⚠️ duplicate | `auto_upgrade.sh` at Sunday 03:30 — removed |
| VPN-EU-Pilik-178 | ⚠️ duplicate | `auto_upgrade.sh` at Sunday 03:30 — removed |
| VPN-EU-ILYA-176 | ⚠️ duplicate | `auto_upgrade.sh` at Sunday 03:30 — removed |
| EU-SO-38 | ✅ clean | — |
| 222-DE-NetCup | ℹ️ web server | No reboot cron — intentional |
| 109-RU-FastVDS | ℹ️ web server | No reboot cron — intentional |

---

## 🔧 install-night-maintenance.sh — Creation & Deployment

### Problem with Heredoc

First attempt used nested heredoc (`INSTALLER` containing `EOF`) — bash broke because inner `EOF` token
closed the outer heredoc prematurely. Workaround: replaced inner heredocs with `printf '%s\n'` per line.

Final solution: pushed to GitHub, deployed via:
```bash
ssh root@$I "curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/install-night-maintenance.sh | bash"
```

### What the Installer Does

**Writes `/usr/local/bin/night-maintenance`:**
```
02:00  apt-get update -qq         → error → Telegram ❌ + exit
       apt-get upgrade -y -qq     → error → Telegram ❌ + exit
       Telegram: "🔄 SERVER rebooting..."
       sleep 3 && /sbin/reboot
```

**Writes `/usr/local/bin/night-audit`:**
```
@reboot  sleep 30
         run /usr/local/bin/audit (if exists)
         collect: uptime, RAM, disk, load avg, failed systemd units
         Telegram: "✅ SERVER rebooted\n⏱ uptime\n🧠 RAM\n💾 Disk\n⚡ Load\n🔧 Services"
```

**Updates crontab:**
```
0 2 * * *   /usr/local/bin/night-maintenance >> /var/log/auto-upgrade.log 2>&1
@reboot     /usr/local/bin/night-audit >> /var/log/auto-upgrade.log 2>&1
```

Removes old entries: `apt.*update`, `apt.*upgrade`, `/sbin/reboot`, `auto_upgrade.sh`, `0 2 * * * /usr/local/bin/audit`

### Deployment Loop (from server 222)

```bash
for I in 109.234.38.47 144.124.228.237 144.124.232.9 144.124.228.227 \
         144.124.239.24 91.84.118.178 146.103.110.176 144.124.233.38; do
  echo "=== $I ==="
  ssh -o ConnectTimeout=5 root@$I \
    "curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/install-night-maintenance.sh | bash"
done
```

**Result:** All 8 VPN servers responded `✅ Installed on <hostname>`

---

## 🔧 scripts/shared_aliases.sh — Created for VPN Nodes

### Problem

Servers pilik178 and ilya176 had in `~/.bashrc` line 79:
```bash
source /root/Linux_Server_Public/scripts/shared_aliases.sh
```
But file `scripts/shared_aliases.sh` did not exist in repo — only `shared_aliases_109.sh` and `shared_aliases_222.sh`.

This caused on every SSH login:
```
/root/.bashrc: line 79: /root/Linux_Server_Public/scripts/shared_aliases.sh: No such file or directory
```

### Root Cause

VPN servers were set up with a `.bashrc` referencing a generic `shared_aliases.sh` that was never created.
The `_109` and `_222` variants exist only for web servers.

### Fix

Created `scripts/shared_aliases.sh` tailored for VPN nodes, covering all aliases visible in
`VPN/motd_server.sh` menu (sos, ports, banlist, fight, antivir, backup, xray_st, smb_st, adg_st, awg_st,
save, load, 00, ll, mc, nightlog).

Pushed to GitHub → both servers synced via:
```bash
for I in 91.84.118.178 146.103.110.176; do
  ssh root@$I "git -C /root/Linux_Server_Public pull && echo OK"
done
```

Verified on next SSH login — no errors on both servers.

---

## 📊 Timezone Setup

All VPN servers confirmed timezone + NTP setup with:
```bash
timedatectl set-timezone Europe/Prague
systemctl restart systemd-timesyncd
```

Note: original command used `Europe/Amsterdam` — corrected to `Europe/Prague` (server owner location: Czech Republic).

---

## 📂 Changed / Created Files

| File | Action | Notes |
|---|---|---|
| `install-night-maintenance.sh` | Created | Universal VPN nightly maintenance installer |
| `scripts/shared_aliases.sh` | Created | VPN node aliases, fixes `.bashrc` line 79 error |
| `CHANGELOG.md` | Updated | Added session v2026.05.26 |
| `WORKLOG.md` | Updated | This file |

---

---

# 📅 Session: 2026-05-24 / 2026-05-25

> Evening 24 May → night 25 May 2026
> Affected: **scripts/sos.sh**, **scripts/setup_aliases_modded_mc.sh**

---

## 📋 Session Summary

1. `sos.sh` — full safety rewrite: eliminated all `integer expression expected` runtime errors
2. `sos.sh` — fixed HTTP 502/503 domain deduplication logic
3. `sos.sh` — added top-N output limits to all long sections (no content removed)
4. `setup_aliases_modded_mc.sh` — added step [5/7]: auto-repair of `/etc/bash.bashrc` aliases block
5. Version bumped to `v2026.05.25` in both scripts

---

## 🔧 scripts/sos.sh — Full Rewrite

### Problem 1: `integer expression expected` — OOM KILLER block

- **Root cause:** `dmesg | grep -c` or `wc -l` could return empty string or string with whitespace/newline. Bash `[ "$VAR" -gt 0 ]` fails with `integer expression expected` if value is not a clean integer.
- **Fix:** Added `safe_int()` function:
  ```bash
  safe_int() {
    local v="${1:-}"
    v="$(printf '%s' "$v" | tr -cd '0-9')"
    printf '%s\n' "${v:-0}"
  }
  ```
  All counters passed through `safe_int` before any integer comparison.

### Problem 2: `integer expression expected` — PHP ERROR RATE block

- **Root cause:** Percentage calculation used bash arithmetic on floats from `awk`, which can produce `0.0` — not valid for `[ ... -ge 5 ]`.
- **Fix:** Added `safe_pct()` using pure `awk` for division.

### Problem 3: HTTP 502/503 same domain counted multiple times

- **Root cause:** Multiple `*access.log` files exist per domain (rotated logs). Each was counted separately.
- **Fix:** `awk '{sum[$1]+=$2} END{for (d in sum) print d, sum[d]}'` aggregation before display.

### Problem 4: Monitoring tools appearing in top-CPU / top-RAM lists

- **Root cause:** `ps`, `awk`, `grep` etc. spawned by the script appeared in the process list snapshot.
- **Fix:** `awk 'NR==1 || ($5 !~ /^(ps|awk|grep|head|tail|sort)$/)'` filter.

---

## 📂 Changed Files

| File | What changed | Version |
|---|---|---|
| `scripts/sos.sh` | safe_int/safe_float/safe_pct added; 502/503 dedup fixed; tool self-contamination fix; top-N limits | v2026.05.25 |
| `scripts/setup_aliases_modded_mc.sh` | New step [5/7]: /etc/bash.bashrc repair; step count 6→7 | v2026.05.25 |
| `CHANGELOG.md` | Added session v2026.05.25 | — |
| `WORKLOG.md` | Added this session | — |

---

---

# 📅 Session: 2026-04-12 / 2026-04-13

> Evening 12 April → night 13 April 2026
> Affected: **222** (152.53.182.222) and **109** (212.109.223.109)

---

## 📋 Session Summary

1. `sos.sh` updated with color output and time-window parameters (`1h`, `3h`, `24h`, `120h`)
2. Server **222** — alias `sos1` was already present, no changes needed
3. Server **109** — alias `sos1` was missing, added to `.bashrc`
4. `ALIASES.md` updated on both servers

---

## 📂 Changed Files

| File | What changed | Commit |
|---|---|---|
| `109/.bashrc` | Added `alias sos1=...`, version bumped to v2026-04-13 | [f6486a2](https://github.com/GinCz/Linux_Server_Public/commit/f6486a25fcdf35ea7c51a1d20d443627e37c37f0) |
| `109/ALIASES.md` | Added `sos1` to SOS table | [f0be4c5](https://github.com/GinCz/Linux_Server_Public/commit/f0be4c5439263b497e1634b32e7a8717735e0085) |
| `222/ALIASES.md` | Added `sos1` to SOS table | [f0be4c5](https://github.com/GinCz/Linux_Server_Public/commit/f0be4c5439263b497e1634b32e7a8717735e0085) |

---

*= Rooted by VladiMIR + AI | v.2026.05.27 | github.com/GinCz/Linux_Server_Public =*
