# WORKLOG — Linux_Server_Public

> Full session-by-session work log.
> = Rooted by VladiMIR | AI =

---

# 📅 Session: 2026-05-28 (Evening)

> Evening 28 May 2026
> Affected: **ALL 10 servers** — CrowdSec global fix deployed from 222

---

## 📋 Session Summary

1. Created `scripts/fix_crowdsec_global.sh` v2026.05.28 — universal CrowdSec + Samba fix
2. Deployed script to all 10 servers in one SSH loop from server 222
3. Fixed 4 identical misconfigurations present on all servers (see details below)
4. Disabled `fwupd` on servers where it was running (wasting ~26MB RAM on VPS)
5. Added `scripts/README.md` and `crowdsec/README.md` with full documentation
6. Updated `WORKLOG.md` and `CHANGELOG.md`

---

## 🔧 Fix 1 — sshd.yaml: duplicate journalctl + wrong type

### Problem
On 8 of 10 servers, `sshd.yaml` contained **two sources**:
- `journalctl` (SYSLOG_IDENTIFIER=sshd)
- file `/var/log/auth.log` with **wrong** `type: ssh` instead of `type: syslog`

Result: CrowdSec tried to parse SSH logs twice, with the wrong parser → high Unparsed rate.

### Fix
Replaced with single clean source:
```yaml
filenames:
  - /var/log/auth.log
  - /var/log/auth.log.1
labels:
  type: syslog
source: file
```

### Special cases
- **222-DE-NetCup**: `sshd.yaml` was completely **missing** — created from scratch
- **VPN-ALEX-47**: `setup.smb.yaml` was reading Samba via `journalctl` instead of file — corrected

---

## 🔧 Fix 2 — setup.smb.yaml: wide glob → single log.smbd

### Problem
Auto-generated `setup.smb.yaml` used glob patterns:
```yaml
filenames:
  - /var/log/samba/*.log
  - /var/log/samba/log.*
```
This caused CrowdSec to tail **hundreds** of per-IP files.

### Fix
```yaml
filenames:
  - /var/log/samba/log.smbd
```

---

## 🔧 Fix 3 — smb.conf: log level = 1 + unified log file

### Problem
`log level = 2` wrote a separate `log.<IP>` for every Samba client connection.

### Fix
`log level = 1`, all logs go to `/var/log/samba/log.smbd`.

---

## 🔧 Fix 4 — Samba per-IP log cleanup

| Server | Files deleted |
|---|---|
| 222-DE-NetCup | 2407 |
| 109-RU-FastVDS | 329 |
| VPN-ALEX-47 | 571 |
| VPN-SO-38 | 547 |
| VPN-STOLB-24 | 277 |
| VPN-TATRA-9 | 19 |
| VPN-4TON-237 | 19 |
| VPN-SHAHIN-227 | 0 (already clean) |
| VPN-PILIK-178 | 0 (already clean) |
| VPN-ILYA-176 | 0 (already clean) |

---

## 📂 Changed / Created Files

| File | Action | Notes |
|---|---|---|
| `scripts/fix_crowdsec_global.sh` | Created/Updated | v2026.05.28 — deployed to all 10 servers |
| `scripts/README.md` | Created | Full scripts documentation |
| `crowdsec/README.md` | Created | CrowdSec docs + known issues + fix summary |
| `WORKLOG.md` | Updated | This file |
| `CHANGELOG.md` | Updated | Added v2026.05.28 entry |

---

---

# 📅 Session: 2026-05-28 (Afternoon)

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
