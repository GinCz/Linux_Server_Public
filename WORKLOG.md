# WORKLOG — Linux_Server_Public

> Full session-by-session work log.
> = Rooted by VladiMIR | AI =

---

# 📅 Session: 2026-05-28

> Afternoon 28 May 2026
> Affected: **222-DE-NetCup** (152.53.182.222) — Semaphore cleanup, CrowdSec whitelist, sos.sh default

---

## 📋 Session Summary

1. Investigated 502 errors in `sem.gincz.com-ssl` logs — root cause: stale browser tab, not a real incident
2. Cleaned `sem.gincz.com` and `server.gincz.com` logs (truncated to 0, removed `.bak`)
3. Confirmed `sem.gincz.com` has no active nginx config — service properly removed
4. Fixed broken CrowdSec whitelist — file was accidentally overwritten with bare IP list (invalid YAML)
5. Consolidated 3 duplicate whitelist files into 1 clean `my_whitelist.yaml`
6. Updated `sos.sh` — changed default time window from `1h` to `24h`
7. Added `scripts/install_sos.sh` — universal installer for new servers
8. Saved `crowdsec/my_whitelist.yaml` to repository

---

## 🔧 Fix 1 — sem.gincz.com 502 errors investigation

### Symptom

Logs `sem.gincz.com-ssl.access.log` (16K) and `sem.gincz.com-ssl.error.log` (11K) appeared after Semaphore was removed.

### Investigation

```bash
# Check nginx configs
find /etc/nginx/ -name "*sem*"       # → empty
nginx -T 2>/dev/null | grep -A5 "sem.gincz"  # → empty
cscli parsers list | grep whitelist
```

### Root Cause

- `sem.gincz.com` nginx config was **not active** — no symlink in `fastpanel2-sites/`
- 502 errors came from **home IP `185.100.197.16`** — stale browser tab with open WebSocket (`/api/ws`)
- Semaphore service already removed — so nginx served 502 to the dangling WebSocket connection
- After browser closed, errors stopped. No incident.

### Fix

Logs truncated to 0. No nginx changes needed.

---

## 🔧 Fix 2 — CrowdSec whitelist YAML broken

### Problem

Script accidentally appended IPs at top of `whitelists.yaml` without proper YAML structure:
```yaml
- "185.100.197.16"  # Home IP VladiMIR
- "185.14.233.235"  # Home IP VladiMIR 2
- "185.14.232.0"    # Home IP VladiMIR 3
```

This is valid YAML sequence but CrowdSec expects a `whitelist:` document — caused `unmarshal error` on reload:
```
FATAL failed to sync /etc/crowdsec: failed to parse whitelists.yaml:
  yaml: unmarshal errors: line 1: cannot unmarshal !!seq into cwhub.localItemName
```

CrowdSec was still **running** (old process PID kept serving), but reload failed.

### Fix

Restored correct YAML structure, then consolidated all 3 duplicate whitelist files:

| Before | After |
|---|---|
| `whitelists.yaml` — broken (our new file) | ❌ Deleted |
| `vladimir-whitelists.yaml` — duplicate | ❌ Deleted |
| `letsencrypt-whitelist.yaml` — Let's Encrypt IPs | ✅ Kept (separate purpose) |
| `my_whitelist.yaml` — full trusted IP list | ✅ Kept + updated |

After fix:
```
crowdsecurity/letsencrypt-whitelist  🏠  enabled,local
my_whitelist                         🏠  enabled,local
```

Test confirmed:
```
Error: 185.100.197.16 is allowlisted by item 185.100.197.16 from trusted-ips
→ Whitelist working — cannot ban whitelisted IP ✅
```

---

## 🔧 Fix 3 — sos.sh default time window changed to 24h

### Change

`scripts/sos.sh`: changed default from `1h` to `24h`
- Before: `TW="${1:-1h}"` / `M=60`
- After: `TW="${1:-24h}"` / `M=1440`

Now `sos` (without arguments) shows last 24 hours.

Available aliases:
| Command | Period |
|---|---|
| `sos` | **24h** (default) |
| `sos1` | 1h |
| `sos3` | 3h |
| `sos24` | 24h |
| `sos120` | 120h |
| `sos 30m` | any custom period |

---

## 📂 Changed / Created Files

| File | Action | Notes |
|---|---|---|
| `crowdsec/my_whitelist.yaml` | Created | Consolidated trusted IP whitelist v2026-05-28 |
| `scripts/install_sos.sh` | Created | Universal sos installer for new servers |
| `WORKLOG.md` | Updated | This file |

---

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

### Root Cause

CrowdSec v1.7+ changed internal hub storage structure. Old symlinks pointed to paths that were relocated during hub migration.

### Fix Applied

```bash
find /etc/crowdsec -type l | while read link; do
    [ ! -e "$link" ] && rm "$link"
done

cscli collections install \
  crowdsecurity/linux crowdsecurity/sshd crowdsecurity/nginx \
  crowdsecurity/apache2 crowdsecurity/wordpress crowdsecurity/http-cve \
  crowdsecurity/base-http-scenarios crowdsecurity/whitelist-good-actors \
  --force

systemctl restart crowdsec
```

### Result

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

*= Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz/Linux_Server_Public =*
