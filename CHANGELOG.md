# CHANGELOG — Linux_Server_Public

> All notable changes, fixes, and known issues across sessions.
> = Rooted by VladiMIR | AI =

---

## v2026.05.26 — Session: SOS update on all VPN nodes, multipathd disable, CrowdSec SSH parser fix

### ✅ SOS Script Updated & Deployed (all 8 VPN nodes)

- Updated `scripts/sos.sh` — new version `v.2026.05.26d`
- New installer: `install-sos.sh` — deploys `sos` to `/usr/local/bin/sos` + sets up aliases in `~/.bashrc`
- Aliases installed: `sos`, `sos1`, `sos3`, `sos24`, `sos120`
- Deployed to all 8 VPN nodes via one command from server 222:

```bash
ssh root@<NODE> "bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/install-sos.sh) && source ~/.bashrc"
```

**Nodes updated:**
- EU-Alex-47 (109.234.38.47) ✅
- EU-4Ton-237 (144.124.228.237) ✅
- EU-Tatra-Kuma-9 (144.124.232.9) ✅
- VPN-EU-Shahin-227 (144.124.228.227) ✅
- EU-Stolb-AG-24 (144.124.239.24) ✅
- VPN-EU-Pilik-178 (91.84.118.178) ✅
- VPN-EU-ILYA-176 (146.103.110.176) ✅
- EU-SO-38 (144.124.233.38) ✅

---

### ✅ multipathd Disabled (all 8 VPN nodes)

`multipathd` is a multipath disk daemon — completely unnecessary on VPN nodes (single-disk VPS).
It consumed RAM and generated noise in system logs.

**Actions:**
- `systemctl disable --now multipathd`
- `systemctl stop multipathd.socket`
- `systemctl disable multipathd.socket`

Applied to all 8 VPN nodes + EU-Tatra-Kuma-9 directly.

---

### ✅ CrowdSec Hub Updated (all 8 VPN nodes)

```bash
cscli hub update && cscli hub upgrade
systemctl restart crowdsec
```

- Hub index updated on all nodes
- Custom local items (parsers, scenarios) preserved — not overwritten
- CrowdSec v1.7.7 running on all nodes (v1.7.8 available but not yet upgraded)

---

### ✅ Xray Symlink Fixed (all 8 VPN nodes)

```bash
ln -sf /usr/local/bin/xray /usr/bin/xray
```

Ensures `xray` is accessible system-wide via `/usr/bin/xray`.

---

### ✅ .bashrc Cleaned (all 8 VPN nodes)

```bash
sed -i '/shared_aliases.sh/d' /root/.bashrc
```

Removed stale `shared_aliases.sh` source line that caused "No such file or directory" warning on every SSH login.

---

### ✅ CrowdSec SSH Parser Fix — Ubuntu 24 (all 8 VPN nodes)

**Problem diagnosed on EU-Tatra-Kuma-9:**

CrowdSec parser `crowdsecurity/sshd-logs` showed `272 hits / 272 unparsed` — all SSH events were unrecognized.

**Root cause:**

Ubuntu 24 writes SSH log lines to `/var/log/syslog` in **ISO 8601 format**:
```
2026-05-26T18:12:06.578123+02:00 EU-Tatra-Kuma-9 sshd[2941]: Failed password...
```

The `crowdsecurity/sshd-logs` parser expects the **classic syslog format**:
```
May 26 18:12:06 EU-Tatra-Kuma-9 sshd[2941]: Failed password...
```

Result: 100% of SSH events unparsed → CrowdSec could not detect SSH brute force attacks.

**Fix:**

1. **`/etc/crowdsec/acquis.d/sshd.yaml`** — Changed source from `_SYSTEMD_UNIT=ssh.service` to `SYSLOG_IDENTIFIER=sshd`:
   ```yaml
   source: journalctl
   journalctl_filter:
     - SYSLOG_IDENTIFIER=sshd
   labels:
     type: syslog
   ```
   `SYSLOG_IDENTIFIER=sshd` captures ALL sshd events (including `Invalid user`, `Failed password`) in classic format that the parser understands. `_SYSTEMD_UNIT=ssh.service` missed many lines.

2. **`/etc/crowdsec/acquis.d/setup.linux.yaml`** — Removed `/var/log/syslog` from file sources (it contains SSH lines in ISO format that cause unparsed noise):
   ```yaml
   filenames:
     - /var/log/messages
     - /var/log/kern.log
   labels:
     type: syslog
   source: file
   ```

3. **Removed duplicate** `/etc/crowdsec/acquis.d/setup.sshd.yaml` on all nodes where it existed.

**Result after fix (EU-Tatra-Kuma-9):**
```
| crowdsecurity/sshd-logs  | 8 | 5 parsed | 3 unparsed |
```
SSH brute force detection active. 2 IPs auto-banned immediately after fix.

**Fix script:** `VPN/crowdsec/fix_sshd_parser.sh`
Deploy on any VPN node:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/VPN/crowdsec/fix_sshd_parser.sh)
```

**Applied to all 8 VPN nodes** from server 222 in one loop. ✅

### ✅ New Files Added to Repo

| File | Purpose |
|---|---|
| `VPN/crowdsec/fix_sshd_parser.sh` | Fix CrowdSec SSH parser on Ubuntu 24 VPN nodes |
| `VPN/crowdsec/acquis.d/sshd.yaml` | Correct journalctl SSH acquisition config |
| `VPN/crowdsec/acquis.d/setup.linux.yaml` | Linux syslog config without /var/log/syslog |

---

## v2026.05.26 — Session: Nightly maintenance, cron cleanup, VPN aliases, shared_aliases.sh

### ✅ New Scripts / Files

| File | Purpose |
|---|---|
| `install-night-maintenance.sh` | Universal installer for nightly maintenance on all VPN servers. Installs `night-maintenance` (02:00 apt update+upgrade+reboot with Telegram alerts on error) and `night-audit` (@reboot health check + Telegram report). Deployed via `curl` from GitHub raw URL. |
| `scripts/shared_aliases.sh` | Shared aliases for ALL VPN nodes. Loaded via `source` in `~/.bashrc` line 79. Covers: sos/sos3/sos24, ports, banlist/banblock/banunblock, fight, antivir, backup, xray_st/smb_st/adg_st/awg_st, save/load, nightlog, 00/ll/mc. |

### ✅ Installed on VPN Servers

Two scripts installed system-wide on all 8 VPN nodes:

| Script | Path | Cron |
|---|---|---|
| `night-maintenance` | `/usr/local/bin/night-maintenance` | `0 2 * * *` |
| `night-audit` | `/usr/local/bin/night-audit` | `@reboot` |

**Servers updated:**
- EU-Alex-47 (109.234.38.47)
- EU-4Ton-237 (144.124.228.237)
- EU-Tatra-Kuma-9 (144.124.232.9)
- VPN-EU-Shain-227 (144.124.228.227)
- EU-Stolb-AG-24 (144.124.239.24)
- VPN-EU-Pilik-178 (91.84.118.178)
- VPN-EU-ILYA-176 (146.103.110.176)
- EU-SO-38 (144.124.233.38)

### ✅ Cron Cleanup

- Removed duplicate `auto_upgrade.sh` cron entry (Sunday 03:30) from: shahin227, stolb24, pilik178, ilya176
- Old `0 3 * * *` reboot-only cron replaced by unified `night-maintenance` on all VPN nodes
- Servers 222 and 109 intentionally excluded — they run live websites, no nightly reboot

### ✅ Bug Fixes

| Server | Bug | Fix |
|---|---|---|
| pilik178, ilya176 | `/root/.bashrc` line 79: `shared_aliases.sh: No such file or directory` | Created `scripts/shared_aliases.sh` and pushed to repo; both servers synced via `git pull` |
| pilik178, ilya176 | `Linux_Server_Public` repo was outdated (missing recent commits) | `git -C /root/Linux_Server_Public pull` synced both servers |

### ✅ Nightly Maintenance Flow (all VPN nodes)

```
02:00  apt-get update -qq
       apt-get upgrade -y -qq  → log: /var/log/auto-upgrade.log
       On error → Telegram alert ❌
       /sbin/reboot
@reboot +30s
       /usr/local/bin/audit (if exists)
       Telegram report: hostname, uptime, RAM, disk, load, failed services ✅
```

### ✅ Deploy Command (any new VPN server)

```bash
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/install-night-maintenance.sh | bash
```

### ✅ Timezone + Cron Setup (one-liner for new VPN servers)

```bash
timedatectl set-timezone Europe/Prague && \
systemctl restart systemd-timesyncd && \
(crontab -l 2>/dev/null | grep -v 'reboot\|apt.*update\|apt.*upgrade'; \
echo "0 2 * * * /usr/local/bin/night-maintenance >> /var/log/auto-upgrade.log 2>&1"; \
echo "@reboot /usr/local/bin/night-audit >> /var/log/auto-upgrade.log 2>&1") | crontab - && \
crontab -l && date
```

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
| EU-Alex-47 | 109.234.38.47 | VPN node: Xray |
| EU-4Ton-237 | 144.124.228.237 | VPN node: Xray VLESS + Samba |
| EU-Tatra-Kuma-9 | 144.124.232.9 | VPN node: Xray |
| VPN-EU-Shain-227 | 144.124.228.227 | VPN node: Xray + security scripts |
| EU-Stolb-AG-24 | 144.124.239.24 | VPN node: Xray + security scripts |
| VPN-EU-Pilik-178 | 91.84.118.178 | VPN node: Xray + security scripts |
| VPN-EU-ILYA-176 | 146.103.110.176 | VPN node: Xray + security scripts |
| EU-SO-38 | 144.124.233.38 | VPN node: Xray |
