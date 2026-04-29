# CHANGELOG — Linux_Server_Public

> All notable changes, fixes, and known issues across sessions.
> = Rooted by VladiMIR | AI =

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
