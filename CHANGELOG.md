# CHANGELOG — Linux_Server_Public

> All notable changes to server infrastructure, scripts, and configurations.
> Format: `[vYYYY.MM.DD] — Summary`
> = Rooted by VladiMIR + AI | github.com/GinCz =

---

## [v2026.05.28-evening] — CrowdSec Global Fix: All 10 Servers

### Added
- `scripts/fix_crowdsec_global.sh` v2026.05.28 — universal 5-step CrowdSec + Samba fix
- `scripts/README.md` — full documentation for all scripts, deployment pattern, server fleet table
- `crowdsec/README.md` — CrowdSec docs, whitelist table, known issues, fix summary, useful commands

### Fixed (all 10 servers)
- `sshd.yaml` — removed journalctl duplicate, fixed `type: ssh` → `type: syslog`
- `setup.smb.yaml` — replaced `log.*` glob with single `log.smbd`
- `smb.conf` — set `log level = 1`, unified log file path
- Deleted stale per-IP Samba log files (`log.<IP>`) — **4,169 files** removed across fleet
- `fwupd` — stopped and masked on 6 servers (was wasting ~26MB RAM each)

### Special cases
- **222-DE-NetCup**: `sshd.yaml` was completely missing — created
- **VPN-ALEX-47**: `setup.smb.yaml` used journalctl source for Samba — replaced with file source

### Changed
- `WORKLOG.md` — added full evening session log
- `CHANGELOG.md` — this entry

---

## [v2026.05.28] — CrowdSec Whitelist Fix + sos.sh 24h default

### Added
- `crowdsec/my_whitelist.yaml` — consolidated trusted IP whitelist
- `scripts/install_sos.sh` — universal sos installer for new servers

### Fixed
- CrowdSec whitelist YAML was corrupted (bare IP list without proper document structure)
- Consolidated 3 duplicate whitelist files into 1

### Changed
- `scripts/sos.sh` — default time window changed from `1h` to `24h`

---

## [v2026.05.27] — CrowdSec WARNING Fix + Hub Rebuild

### Fixed
- `letsencrypt-whitelist.yaml` — wrong `name:` field causing conflict
- 60+ WARNING messages on every `cscli` command — stale hub symlinks cleaned
- Reinstalled all collections with `--force`

### Added
- `222/crowdsec/letsencrypt-whitelist.yaml`

---

## [v2026.05.26] — Nightly Maintenance Unified Across All VPN Nodes

### Added
- `install-night-maintenance.sh` — universal VPN nightly maintenance installer
- `scripts/shared_aliases.sh` — VPN node aliases, fixes `.bashrc` line 79 error

### Fixed
- Duplicate `auto_upgrade.sh` cron entries removed from 4 VPN servers
- Outdated local repo on PILIK-178 and ILYA-176 — `git pull` applied

---

## [v2026.05.25] — sos.sh Safety Rewrite + setup_aliases Fix

### Fixed
- `sos.sh` — all `integer expression expected` runtime errors eliminated
- `sos.sh` — HTTP 502/503 domain deduplication logic corrected
- `sos.sh` — tool self-contamination in log parsing fixed

### Changed
- `sos.sh` — top-N output limits added to all long sections
- `setup_aliases_modded_mc.sh` — new step [5/7]: auto-repair of `/etc/bash.bashrc`

---

## [v2026.04.13] — sos1 Alias Added to Server 109

### Fixed
- `sos1` alias was missing on server 109 — added to `.bashrc`

### Changed
- `ALIASES.md` updated on both servers 222 and 109

---

*= Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz/Linux_Server_Public =*
