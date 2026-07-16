# Changelog — Linux_Server_Public

> All notable changes to server infrastructure, scripts, and configurations are documented here.
> Format: `[YYYY-MM-DD] | Server | Category | Description`

---

## [2026-06-10] — new_server_install.sh — Full session: SSH banner + MOTD refactor + emoji fix

**Script:** `scripts/new_server_install.sh`  
**Versions touched:** `v2026.06.10b` → `v2026.06.10m` → `v2026.06.10n`  
**Servers affected:** 4Ton-237 (144.124.228.237) and 222-DE-NetCup (152.53.182.222)  
**Time:** ~00:20 – 14:35 CEST

---

### PROBLEM 1 — SSH banner lines «Using username» and «Last login» were not suppressed

#### Symptom
Every SSH connection showed two extra lines before our MOTD:
```
Using username "root".
Last login: Wed Jun 10 00:21:50 2026 from 185.100.197.16
```

#### Root cause
OpenSSH prints by default:
- `Using username` — client-side string from PuTTY/MobaXterm during auth
- `Last login` — controlled by `PrintLastLog yes` in `/etc/ssh/sshd_config`
- PAM module `pam_motd` — printed the system `/etc/motd` on top of ours

These parameters were never disabled in the install script for these servers.

#### Fix (added to STEP 1 of the script)

```bash
# SSH: hide "Last login" banner line
SEEKED_SSHD=/etc/ssh/sshd_config
if [ -f "$SEEKED_SSHD" ]; then
  sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/'  "$SEEKED_SSHD"
  grep -q '^PrintLastLog' "$SEEKED_SSHD" || echo 'PrintLastLog no' >> "$SEEKED_SSHD"
  sed -i 's/^#\?PrintMotd.*/PrintMotd no/'        "$SEEKED_SSHD"
  grep -q '^PrintMotd'     "$SEEKED_SSHD" || echo 'PrintMotd no'     >> "$SEEKED_SSHD"
  systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true
fi
```

- `PrintLastLog no` — removes the `Last login: ...` line
- `PrintMotd no` — disables PAM output of `/etc/motd`
- `systemctl reload ssh` — applies changes without dropping current session

**Apply manually on existing servers:**
```bash
sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
sed -i 's/^#\?PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config
systemctl reload ssh
```

---

### PROBLEM 2 — Type and CrowdSec lines took 2 lines instead of 1

#### Symptom (before)
```
  Type: VPN / XRay / AmneziaWG / AdGuard / Semaphore
  CrowdSec: ● ACTIVE | bans: 4
```
Two separate lines, too much redundant information.

#### Fix (after)
```
  Type: VPN   CrowdSec: ● ACTIVE | bans: 4
```

#### Implementation
Introduced variable `MOTD_TYPE_SHORT` with a short server type name:
- TYPE 1 → `VPN`
- TYPE 2 → `Web-222/CF`
- TYPE 3 → `Web-109`

Both lines merged into a single variable `CS_LINE`:
```bash
CS_LINE="  ${Y}Type:${X} VPN   ${Y}CrowdSec:${X} ${G}● ACTIVE${X} | bans: ${W}${BAN_COUNT}${X}"
```

---

### PROBLEM 3 — Server icon 🖥 was missing in MOTD TYPE 2 and TYPE 3

#### Symptom
After applying the script on server 222 (TYPE 2 — FastPanel + Cloudflare), the MOTD header had no icon before the server name:
```
  222-DE-NetCup  152.53.182.222  RAM:4544/7935MB  CPU:8%
```
Instead of expected:
```
  🌐  222-DE-NetCup  152.53.182.222  RAM:4544/7935MB  CPU:8%
```

#### Root cause
The icon `🖥` (U+1F5A5, Desktop Computer) was only added for TYPE 1 (VPN) but **not** for TYPE 2 and TYPE 3.

Additionally, `🖥` (U+1F5A5) is a **problematic emoji**: it belongs to the «Miscellaneous Symbols» category and in most SSH terminals (PuTTY, MobaXterm, iTerm2) renders as **1.5 characters wide** — overflows the column and breaks line alignment.

#### Fix
Icons replaced with proven **two-byte emoji from the Unicode Emoji block** (render correctly in terminals):

| Server type | Old icon | New icon | Unicode |
|---|---|---|---|
| TYPE 1 — VPN | `🖥` (broken) | `🔑` | U+1F511 (KEY) |
| TYPE 2 — Web 222/CF | missing | `🌐` | U+1F310 (GLOBE WITH MERIDIANS) |
| TYPE 3 — Web 109 | missing | `🌐` | U+1F310 (GLOBE WITH MERIDIANS) |

Inserted via Unicode escape in bash to guarantee correct delivery through heredoc:
```bash
# TYPE 1 VPN:
echo -e "  \U0001F511  ${W}${HN}${X}  ..."

# TYPE 2/3 Web:
echo -e "  \U0001F310  ${W}${HN}${X}  ..."
```

#### Why \U0001F511 instead of a literal character
Inserting `🔑` literally into a bash script via heredoc can cause issues:
- File encoding on the server may not match UTF-8
- Some editors/curl may corrupt multi-byte characters
- `\U0001F511` is a bash built-in escape — works regardless of locale

---

### PROBLEM 4 — Uptime was missing in TYPE 2 and TYPE 3

#### Symptom
The MOTD header on servers 222 and 109 did not include `up ...` — server uptime.

#### Root cause
The `UPTIME` variable was declared only in the TYPE 1 block, but not added to TYPE 2 and TYPE 3.

#### Fix
Added to all three types:
```bash
UPTIME=$(uptime -p | sed 's/up //')
```
And in the header line:
```bash
echo -e "  \U0001F310  ${W}${HN}${X}  ${Y}${IP}${X}  RAM:${W}${RAM_USED}/${RAM_TOTAL}MB${X}  CPU:${W}${CPU}%${X}  up ${W}${UPTIME}${X}"
```

---

### FINAL MOTD STATE

#### TYPE 1 — VPN (server 4Ton-237)
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔑  4Ton-237  144.124.228.237  RAM:444/961MB  CPU:9%  up 5 hours, 57 minutes
  Type: VPN   CrowdSec: ● ACTIVE | bans: 4
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Services:  ● crowdsec  ● fail2ban  ● smbd
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CHEATSHEET:
  amn_st(AmneziaWG)  adg_st(AdGuard)  save(git push)  ...
```

#### TYPE 2 — Web 222 (server 222-DE-NetCup)
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🌐  222-DE-NetCup  152.53.182.222  RAM:4544/7935MB  CPU:8%  up 20 hours, 1 minute
  Xray: 1 enabled / 1 total    CrowdSec Engine: ● ACTIVE  Firewall: ● ACTIVE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SCAN & SECURITY         SERVER                    WORDPRESS
  ...
```

---

### Versions and commits

| Version | Commit | What changed |
|---|---|---|
| `v2026.06.10b` | `24e79bb` | SSH banner fix (PrintLastLog/PrintMotd), Type+CrowdSec into one line |
| `v2026.06.10m` | `3ce154c` | Added 🖥 to TYPE 2/3 (turned out broken symbol) + uptime |
| `v2026.06.10n` | `fc6cf53` | **FINAL**: replaced 🖥 → 🔑 (VPN) and 🌐 (Web), via \U escape |

---

### Files changed

| File | Action |
|---|---|
| `scripts/new_server_install.sh` | SSH banner, Type+CS into 1 line, icons 🔑/🌐, uptime in TYPE 2/3 |
| `CHANGELOG.md` | This entry |

---

### How to apply changes on existing servers

**Full reinstall (recommended):**
```bash
load && bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh)
```

**SSH banner only (no reinstall):**
```bash
sed -i 's/^#\?PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
sed -i 's/^#\?PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config
systemctl reload ssh
```

**MOTD only (no reinstall):**
```bash
load
# Run script, select server type → reconnect via SSH
bash /root/Linux_Server_Public/scripts/new_server_install.sh
```

---

## [2026-06-10 14:19] — sos.sh v2026.06.10h — Verified ✅ + Incident Snapshot

**Server:** 222-DE-NetCup (152.53.182.222)  
**Version:** `v.2026.06.10h`  
**Time:** 14:19:18 CEST

### Verification

Ran `sos 24h` — full output of 31 sections without errors. New section 27 works correctly.

**Section 27. OPEN PORTS — output confirmed:**

```
  TCP LISTEN: (57 unique records, no duplicates from named)
  UDP LISTEN: (25 unique records)
  Key ports:
    21   FTP          open [TCP ]
    22   SSH          open [TCP ]
    53   DNS          open [TCP UDP]
    80   HTTP         open [TCP ]
    443  HTTPS        open [TCP UDP]
    ...  (23 ports total)
    51820 WireGuard   closed
```

### Incidents found during verification

| # | Incident | Section | Priority |
|---|---|---|---|
| 1 | CrowdSec OOM kill repeating — 400MB limit exceeded (was 300M) | 04, 28 | 🔴 HIGH |
| 2 | 91.234.25.247 — 153 WP-login attacks, not banned | 11 | 🔴 HIGH |
| 3 | crypto.gincz.com — 107×502 errors | 12 | 🟡 MEDIUM |
| 4 | kadernik-olga.eu — PHP Fatal: Unknown named parameter | 20 | 🟡 MEDIUM |
| 5 | MariaDB uptime: 13h32m — RECENT RESTART | 18 | 🟡 MEDIUM |
| 6 | Bots scanning /secrets/gcp.json, /secrets/aws.json (8s slow) | 14 | ℹ️ INFO |

### Server State Snapshot 14:19

| Metric | Value |
|---|---|
| Load | 0.56 / 0.53 / 0.85 (14%) |
| RAM | 54% — 4.2Gi / 7.7Gi |
| Swap | 37% — 1.5Gi / 4.0Gi |
| Disk / | 23% — 59G / 247G |
| TCP connections | 202 (estab 25) |
| CrowdSec bans | 46 active |
| ipset vladblacklist | 119 IPs |
| PHP-FPM pools | 10 active |
| Docker | crypto-bot Up 20h |
| HTTP 200 (24h) | 21800 |
| HTTP 404 (24h) | 2725 |
| HTTP 502 (24h) | 142 |

### CrowdSec OOM — details

```
memory: usage 409600kB, limit 409600kB (= 400MB)
swap:   usage 102160kB, limit 102400kB (= 100MB — nearly full)
Killed: pid 85542 (crowdsec) vm:2768708kB, rss:400468kB
Killed: pid 97457 (crowdsec) vm:3012944kB, rss:402504kB
OOM events total: 6
```

Need to raise limit: `MemoryMax=500M`, `MemorySwapMax=200M`.

---

## [2026-06-10] — sos.sh v2026.06.10h — Full Open Ports section + removed `ports` alias

**Script:** `scripts/sos.sh`  
**Server:** 222-DE-NetCup (152.53.182.222)  
**Version:** `v2026.06.10h`

### What was done

#### 1. Rewrote section 27. ALL OPEN PORTS

Old section did a plain `ss -tlnp` with no analysis — everything dumped raw. New version:

| Old problem | Fix |
|---|---|
| Thousands of duplicates (named × 4 interfaces × 4 lines) | `sort -u` by "addr:port + process" |
| No UDP | Separate UDP LISTEN block |
| No grouping | TCP and UDP grouped into sections |
| No summary table | Key ports table with [TCP ] / [TCP UDP] / closed flags |

#### 2. Removed `alias ports` from `shared_aliases_222.sh`

`ports` became fully redundant — all its functionality is built into `sos` as section 27.

### Files Changed

| File | Action |
|---|---|
| `scripts/sos.sh` | Rewrote section 27 OPEN PORTS: deduplication, TCP+UDP, Key ports table |
| `scripts/shared_aliases_222.sh` | Removed `alias ports=...` |
| `WORKLOG.md` | Detailed session worklog |
| `CHANGELOG.md` | This entry |

---

## [2026-06-10] — sos.sh v2026.06.10d — Unified Installer + Audit Script

**Script:** `scripts/sos.sh`
**Version:** `v2026.06.10d`

### Summary

The `install_sos.sh` script was eliminated entirely. All installation logic was merged
directly into `sos.sh`. The script now serves two purposes in a single file:
1. **Installer** — downloads itself, places binary at `/usr/local/bin/sos`, writes aliases
2. **Audit tool** — runs the full server status report for the selected time window

---

### Problem 1 — Two Scripts Were Redundant

Previously the workflow required:
```bash
bash <(curl install_sos.sh)   # step 1 — install
sos                           # step 2 — run audit
```

This was redundant. The user had to maintain two separate scripts in the repository,
keep them in sync, and run two commands for a simple setup. The `install_sos.sh` script
did nothing that `sos.sh` itself could not do.

**Fix:** Deleted `install_sos.sh`. All install logic (`curl` self-download, `chmod +x`,
alias injection into `.bashrc` / `.bash_profile`) moved into `sos.sh` as `do_install()`.

---

### Problem 2 — Missing "Run / Install" First Menu Step

When running `bash <(curl -fsSL .../sos.sh)`, the script was skipping the first
selection menu and jumping directly to the time window selection (1h / 3h / 24h / 120h).

**Final fix:** Compare `realpath "$0"` against `realpath "/usr/local/bin/sos"`.

```bash
SELF_REAL="$(realpath "$0" 2>/dev/null || echo "$0")"
SOS_BIN_REAL="$(realpath "/usr/local/bin/sos" 2>/dev/null || echo "/usr/local/bin/sos")"

if [ "$SELF_REAL" = "$SOS_BIN_REAL" ]; then
  IS_INSTALLED=1   # launched as installed binary → go directly to time window
else
  IS_INSTALLED=0   # launched via curl|bash → show "Run / Install" first
fi
```

---

### Final Behavior

#### Mode A — From GitHub (curl-pipe, first-time setup)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh)
```
Shows: `1) Run` / `2) Install` menu.

#### Mode B — Installed binary

```bash
sos          # asks time window
sos 1h       # runs immediately
sos 24h      # runs immediately
```

Aliases: `sos`, `sos1`, `sos3`, `sos24`, `sos120`

---

### Install Command

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh) && source ~/.bashrc
```

### Files Changed

| File | Action |
|---|---|
| `scripts/sos.sh` | Rewrote entry point, added `do_install()`, `IS_INSTALLED` detection via `realpath` |
| `scripts/install_sos.sh` | **Deleted** |
| `CHANGELOG.md` | This entry |

---

## [2026-05-31] — Go Runtime mmap Crash Fix (FastPanel File Manager / wowflow)

**Server:** 152.53.182.222 (EU-NetCup)  
**Affected service:** `filemanagersystemd@wowflow.service`

### Problem
`@wowflow hard as 300000` in `/etc/security/limits.conf` → 293 MB virtual address limit.
Go runtime reserves hundreds of GB virtual address space via `mmap` at startup.
Kernel enforces `RLIMIT_AS` → Go panics before `main()`.

### Fix
```bash
sed -i '/@wowflow hard as/d' /etc/security/limits.conf
systemctl daemon-reload
systemctl reset-failed filemanagersystemd@wowflow.service
systemctl start filemanagersystemd@wowflow.service
```

**Full postmortem:** `222/FASTPANEL_GO_MMAP_FIX.md`

---

## [2026-05-30] — Multi-Server ClamAV Audit + FastPanel File Manager Fix

### 🛡️ ClamAV — Full Network Audit (9 servers)

| Server IP | ClamAV Before | DB Before | Action | Result |
|---|---|---|---|---|
| 109.234.38.47 | ✅ INSTALLED | ✅ Present | No action needed | ✅ OK |
| 144.124.228.237 | ✅ INSTALLED | ❌ Missing | Sync DB from donor | ✅ Fixed |
| 144.124.232.9 | ✅ INSTALLED | ❌ Missing | Sync DB from donor | ✅ Fixed |
| 144.124.228.227 | ❌ NOT installed | ❌ Missing | Install + sync DB | ✅ Fixed |
| 144.124.239.24 | ✅ INSTALLED | ❌ Missing | Sync DB from donor | ✅ Fixed |
| 195.63.138.33 | ❌ NOT installed | ❌ Missing | Install + sync DB | ✅ Fixed |
| 146.103.110.176 | ❌ NOT installed | ❌ Missing | Install + sync DB | ✅ Fixed |
| 144.124.233.38 | ✅ INSTALLED | ✅ Present | No action needed | ✅ OK |
| 212.109.223.109 | ✅ INSTALLED | ✅ Present | No action needed | ✅ OK |

**Donor server:** `152.53.182.222`

---

## [2026-05-29] — ClamAV Scan Script + Multi-Server Monitoring

- `scan_clamav.sh` established on `212.109.223.109` — weekly Sunday 02:00 cron
- Multi-server monitoring scripts reviewed and updated
- VPN server network audit performed

---

## [2026-03-12] — Cloudflare Configuration Backup

- `109/cloudflare.conf.bak.20260312` — backup before Cloudflare IP range update
- `109/cloudflare_real_ip.conf.bak.20260312` — backup of real IP resolution config
- Nginx reloaded after applying updated Cloudflare IP ranges

---

> _= Rooted by VladiMIR + AI | v.2026.07.11 | github.com/GinCz/Linux_Server_Public =_

## 2026-07-16 — wp_update_all.sh

- Fixed: WordPress core was never actually updated — script only ran `wp core check-update` (info-only). Now runs real `wp core update` + `wp core update-db`.
- Decision: no DB backup taken before core update (removed by explicit request).
- Added: interactive install menu on TTY run — choice between one-off run (1) or full install (2) with alias `wpupdate`, binary copy to `/usr/local/bin/`, and cron job every Sunday 03:00 (`/etc/cron.d/wp_update_all`).
- Fixed: accidental duplicate insertion of the install menu block (double-run of patch script) — deduplicated.
- Verified: crontab was empty on both server 222 (DE-NetCup) and server 109 (RU-FirstVDS) prior to this change — no automatic weekly execution existed before today.
- Pending: cron job installation still needs to be applied on both 222 and 109 (either via interactive menu choice "2", or direct `/etc/cron.d/wp_update_all` creation).
