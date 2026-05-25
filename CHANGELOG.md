# CHANGELOG — Linux_Server_Public

> All notable changes, fixes, and known issues across sessions.
> = Rooted by VladiMIR | AI =

---

## v2026.05.25 — Session: sos.sh rewrite, setup installer fix, /etc/bash.bashrc repair

### ✅ Updated Scripts

| Script | Change |
|---|---|
| `scripts/sos.sh` | Full rewrite. Added `safe_int()`, `safe_float()`, `safe_pct()` functions to prevent `integer expression expected` errors in OOM KILLER and PHP ERROR RATE blocks. Deduplication of HTTP 502/503 by domain via `awk` aggregation. All long sections capped to top-10 / top-15 output. Removed self-contamination of monitoring tools (ps/awk/grep) from top-CPU/RAM lists. |
| `scripts/setup_aliases_modded_mc.sh` | Added step **[5/7]**: repairs `/etc/bash.bashrc` broken aliases block. Removes old `USER ALIASES BLOCK` marker and rewrites it with correct aliases (`00`, `mod`, `cls`, `c`, `ls`, `ll`, `la`, `l`, `grep --color`) and MC color table (`MC_COLOR_TABLE`). Step count bumped from 6 to 7. Version bumped to v2026.05.25. |

### ✅ Bug Fixes

| File | Bug | Fix |
|---|---|---|
| `scripts/sos.sh` | `integer expression expected` in OOM KILLER block | `safe_int()` wrapper strips non-numeric chars, defaults to `0` |
| `scripts/sos.sh` | `integer expression expected` in PHP ERROR RATE block | `safe_pct()` uses awk for float division, safe_int for inputs |
| `scripts/sos.sh` | HTTP 502/503 same domain counted multiple times from different log files | `awk` sum aggregation by domain name before display |
| `scripts/setup_aliases_modded_mc.sh` | `/etc/bash.bashrc` aliases block broken or missing after OS updates | New step [5/7] surgically removes and rewrites the block idempotently |

### ✅ Deployment

- Universal one-liner install (any server, no GitHub access required at runtime):
  ```bash
  bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/setup_aliases_modded_mc.sh) && source ~/.bashrc
  ```
- Script auto-detects server profile by IP: `fast-panel+cloudflare` / `fast-panel` / `vpn`

---

## v2026-05-01 — Session: ClamAV for VPN, universal MOTD, README updates

### ✅ New Scripts

| Script | Purpose |
|---|---|
| `VPN/scan_clamav_vpn.sh` | ClamAV on-demand scanner for VPN servers. Scans `/root /tmp /var/tmp /home /opt /etc`. No daemon — saves ~200MB RAM. Sends Telegram report (clean or threats). Auto-installs ClamAV if missing. |
| `VPN/motd_server.sh` | Universal MOTD for ALL VPN servers. Auto-detects: AmneziaWG peers, AdGuard status, Xray status, Samba status + connected users. |

### ✅ Updated Scripts

| Script | Change |
|---|---|
| `VPN/.bashrc` | Added `antivir` alias → `VPN/scan_clamav_vpn.sh`. Version bumped to v2026-05-01. |
| `VPN/motd_server.sh` | Rewritten as universal (was server-specific). Detects all VPN service types automatically. |

### ✅ Removed

| File | Reason |
|---|---|
| `VPN/bashrc_237.sh` | Replaced by universal `VPN/.bashrc` |
| `VPN/motd_237.sh` | Replaced by universal `VPN/motd_server.sh` |

### ✅ Documentation Updated

- `VPN/README.md` — Added `scan_clamav_vpn.sh`, `motd_server.sh`, updated aliases table
- `CHANGELOG.md` — This entry

### ℹ️ Notes

- `banlog` was already in `VPN/.bashrc` (v2026-04-10). Error `banlog: command not found`
  means server has old `.bashrc` not yet synced. Fix: `load` (git pull + deploy)
- ClamAV install on VPN server: `apt install -y clamav && systemctl disable clamav-freshclam`
- `antivir` auto-installs ClamAV if not present on first run

---

## v2026-04-30 — Session: Aliases cleanup, Samba, Xray, infooo fix

### ✅ Fixed

#### `load` alias — "unstaged changes" error
- **Problem:** `git pull` failed with: `error: cannot pull with rebase: You have unstaged changes`
- **Root cause:** Server had local uncommitted changes (e.g. motd temp files), git refused to pull
- **Fix:** `222/.bashrc` — `load` now runs: `git stash && git pull --rebase && git stash pop`
- **Note:** Must run `load` from inside the repo dir (`~/Linux_Server_Public`), not from `~`

#### `infooo` alias — broken path
- **Problem:** `infooo` called `scripts/infooo.sh` — file did not exist at that path
- **Fix:** Script moved/created at correct path `222/infooo.sh`. Docker section added.

#### `secret` alias — removed
- Private repo alias `git -C ~/Secret_Privat pull` removed from `222/.bashrc`
- Removed from ALIASES.md documentation

### ✅ New Scripts

| Script | Purpose |
|---|---|
| `scripts/new_server_install.sh` | Bootstrap for any new Ubuntu 24 server (git, mc, aliases, etc.) |
| `scripts/samba_setup.sh` | Samba install: users `vlad`+`usr`, shares `/storage/user` + `/storage/soft` |
| `222/wphealth.sh` | WP health check for all sites on server 222 |
| `222/run_all_wp_cron.sh` | Trigger WP-Cron manually on all sites |
| `XRAY/xray_install_109.sh` | x-ui + Xray VLESS Reality installer for server 109 |

### ✅ Documentation Updated

- `XRAY/README.md` — Added **TIMEZONE & TIME SYNC** section (critical for Reality)
  - `timedatectl set-timezone Europe/Prague`
  - NTP must be active — `timedatectl set-ntp true`
- `222/ALIASES.md` — Updated to v2026-04-30, removed broken/dead aliases
- `CHANGELOG.md` — This file created

### ✅ Aliases Added

| Alias | Script |
|---|---|
| `wphealth` | `222/wphealth.sh` |
| `wpcron` | `222/run_all_wp_cron.sh` |

### ⚠️ Known Issues (Not Fixed)

#### `f5vpn` — BROKEN
- **Alias:** `f5vpn` → `VPN/vpn_docker_backup.sh`
- **Problem:** Script does not exist + SSH fails on all 8 VPN servers
- **Status:** Do not use. Needs full rewrite when VPN servers are accessible.

#### `allinfo` — TODO (script missing)
- **Alias:** `allinfo` → `222/all_servers_info.sh`
- **Problem:** Script `222/all_servers_info.sh` does not exist in repo
- **Status:** Alias documented as TODO in ALIASES.md. Create when needed.

---

## v2026-04-28..29 — Session: Repo cleanup, CrowdSec, wp-login hardening

### ✅ Fixed / Clarified

#### CrowdSec 0 bans — NOT a problem
- **Question:** `cscli decisions list` returns empty — is something broken?
- **Answer:** 0 bans = NO active bans right now = system is working correctly
- CrowdSec bans are temporary; after expiry the list empties automatically
- `banlog` / `sos24` will show historical alert events even with 0 current bans

#### Xray binary path — CRITICAL
- After `x-ui` install, Xray binary is at: `/usr/local/x-ui/bin/xray-linux-amd64`
- **NOT** `/usr/local/x-ui/bin/xray` — wrong path = setup fails silently

### ✅ Repo Cleanup
- Deleted ~16 placeholder/stub scripts from `222/` (empty or non-functional)
- Deleted ~17 dead scripts from `scripts/` (outdated, superseded)
- `scripts/shared_aliases.sh` — rock-solid save logic with stash

### ✅ WP-Login Hardening
- Full postmortem documented in `222/POSTMORTEM_wp_login_hardening.md`
- Nginx rate limiting zones: `00-wp-login-limit-zone.conf`, `01-wp-limit-zones.conf`
- CrowdSec custom scenario: `222/custom-wp-login-hardban.yaml`

---

## Server Reference

| Server | IP | Purpose |
|---|---|---|
| 222-DE-NetCup | 152.53.182.222 | Main web server, WP sites, Cloudflare |
| 109-RU-FastVDS | 212.109.223.109 | Russian sites, Xray VPN, no Cloudflare |
| VPN-EU-4Ton-237 | 144.124.228.237 | VPN node: Xray VLESS + Samba file share |
