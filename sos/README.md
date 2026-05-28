# 🖥️ SOS — Server Operational Status

> **One command. Full picture. Any time window.**
> `sos` is a self-contained Bash diagnostic tool that gives you an instant
> full-health snapshot of any Linux server — web, VPN, Docker, or generic.

==============================================================
## 📋 TABLE OF CONTENTS
==============================================================

- [What is SOS?](#what-is-sos)
- [Quick Install](#quick-install)
- [Usage & Time Windows](#usage--time-windows)
- [How SOS Works — Step by Step](#how-sos-works--step-by-step)
- [Output Sections by Role](#output-sections-by-role)
- [Color System](#color-system)
- [Server Role Auto-Detection](#server-role-auto-detection)
- [Blacklist System Block](#blacklist-system-block)
- [Safety & Reliability](#safety--reliability)
- [File Structure](#file-structure)

==============================================================
## 💡 WHAT IS SOS?
==============================================================

`sos` (**S**erver **O**perational **S**tatus) is a single Bash script that collects,
formats and displays a complete health report of your Linux server directly in the
terminal — no dependencies, no agents, no web UI required.

It was designed for server administrators who manage multiple machines and need
an instant overview without logging into monitoring dashboards.

**Key principles:**
- 🔒 Zero external dependencies — pure Bash + standard Linux tools
- ⚡ Fast — completes in 1–3 seconds (plus 1 second disk I/O sample)
- 🎯 Role-aware — automatically detects WEB / VPN / Docker / Generic server
- 🪟 Time-window aware — all log analysis respects the selected period
- 🛡️ Safe — all values sanitized, no `eval`, no unquoted variables

==============================================================
## 🚀 QUICK INSTALL
==============================================================

### One-line install (recommended)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/install-sos.sh)
```

Then reload aliases:

```bash
source ~/.bashrc
```

### What the installer does

**Step 1 — Writes the full `sos` script to `/usr/local/bin/sos`**
The installer embeds the entire diagnostic script (as a heredoc) directly into
`/usr/local/bin/sos`. No git clone needed — the binary is self-contained.

**Step 2 — Sets executable permissions**
```bash
chmod +x /usr/local/bin/sos
```

**Step 3 — Syntax check**
```bash
bash -n /usr/local/bin/sos
```
If the syntax check fails, the installer aborts immediately and reports an error.
Nothing broken is ever installed.

**Step 4 — Registers aliases in `/root/.bashrc`**
Existing `sos` aliases are removed first (idempotent), then new ones are appended:
```bash
alias sos='/usr/local/bin/sos 24h'
alias sos1='/usr/local/bin/sos 1h'
alias sos3='/usr/local/bin/sos 3h'
alias sos24='/usr/local/bin/sos 24h'
alias sos120='/usr/local/bin/sos 120h'
```

==============================================================
## ⏱️ USAGE & TIME WINDOWS
==============================================================

```bash
sos           # default — last 24 hours
sos1          # last 1 hour
sos3          # last 3 hours
sos24         # last 24 hours
sos120        # last 5 days (120 hours)
sos 2h        # any custom window — e.g. 2 hours
sos 30m       # or 30 minutes
```

The time window controls how far back log analysis looks.
All sections that scan log files (traffic, errors, attacks, slow requests)
use this window via `find ... -mmin -N` where `N` is the window in minutes.

| Alias   | Window    | Minutes | Best for                              |
|---------|-----------|---------|---------------------------------------|
| `sos1`  | 1 hour    | 60      | Incident investigation, live attack   |
| `sos3`  | 3 hours   | 180     | Recent issue triage                   |
| `sos`   | **24 hours** | **1440** | **Daily check — default**          |
| `sos24` | 24 hours  | 1440    | Same as `sos`                         |
| `sos120`| 5 days    | 7200    | Weekly trend, post-incident analysis  |

==============================================================
## 🔄 HOW SOS WORKS — STEP BY STEP
==============================================================

### Step 1 — Screen clear & initialization

The script starts with `clear` to produce a clean terminal output.
Then it parses the time window argument (`$1`, default `24h`) and converts it
to minutes stored in `$M`. This value is used in every `find -mmin` call later.

```
sos 3h  →  TW="3h"  →  M=180
sos     →  TW="24h" →  M=1440
```

==============================================================

### Step 2 — Color & helper function setup

ANSI escape codes are defined as short variables:

```
G = Bold Green    (OK, success, healthy values)
C = Bold Cyan     (labels, field names)
Y = Bold Yellow   (warnings, section headers, separators)
R = Bold Red      (errors, high usage, attacks)
W = Bold White    (important neutral info)
X = Reset         (always appended after colored text)
```

Three safety helpers are defined before any data collection:

- `safe_int()` — strips all non-digits from a value, returns `0` on empty input.
  Prevents arithmetic errors when a command returns empty or unexpected output.

- `safe_float()` — validates that a value matches `^[0-9]+([.][0-9]+)?$`,
  returns `0` on invalid input. Used for CPU load averages.

- `safe_pct()` — divides part by total using `awk`, returns `0.0` if total is zero.
  Used for PHP error rate calculation.

- `draw_bar()` — renders a 10-character ASCII usage bar with color thresholds:
  green below 60%, yellow 60–89%, red 90%+. Used for RAM, Swap, and Disk.

==============================================================

### Step 3 — System baseline collection

The following values are collected once and reused throughout the report:

```
NOW      — current date and time
HOST     — hostname
IP       — first global IPv4 address (from ip -4 addr)
CORES    — CPU core count (from nproc, min 1)
LOAD     — load average 1m/5m/15m (from /proc/loadavg)
LOAD1    — 1-minute load average as float
LOAD_PCT — load as percentage of available cores (via awk)
```

Load color threshold: green below 60% of cores, yellow 60–89%, red 90%+.

==============================================================

### Step 4 — Server role auto-detection

SOS inspects installed binaries to determine what role the server plays.
Detection runs in order — first match wins:

```
nginx + /var/www present  →  WEB
xray installed            →  VPN/XRAY
wg installed              →  VPN/WG
awg installed             →  VPN/AWG
docker installed          →  DOCKER/NODE
(none of the above)       →  GENERIC
```

The detected role controls which sections are shown later.
All sections (RAM, Disk, Services, Docker, Blacklist) are shown for every role.
Role-specific blocks (web logs, VPN peers, PHP pools) are conditionally included.

==============================================================

### Step 5 — Header banner

A full-width separator line is printed in yellow (`=` × 100).
Two lines of key info are shown:

```
Line 1:  SOS <window>  |  <date and time>
Line 2:  <hostname>  <IP>  |  Load: X.XX (NN%/Nc)  [ROLE]
```

This is followed by the system uptime.

==============================================================

### Step 6 — Memory overview (RAM + Swap)

RAM values are read from `free -k` (kilobytes for calculation) and
`free -h` (human-readable for display). The `draw_bar` function renders
a visual usage indicator.

```
RAM:  [*****.....]  54%   4.3G used / 7.8G total (free 3.5G)
Swap: [*.........]  10%   800M used / 8.0G total
```

If swap is not configured (`SWAP_TOTAL == 0`), a warning is shown instead.

==============================================================

### Step 7 — Disk usage

All `/dev/*` block devices are enumerated via `df -k --output=...`.
For each device, a usage bar is drawn with the same color thresholds as RAM.

```
Filesystem           Size   Used  Avail  Usage   Mount
/dev/sda1           236G    41G   183G  [****......] 17%  /
/dev/sdb1           100G    88G    12G  [*********.]  88%  /data
```

==============================================================

### Step 8 — Top CPU and RAM processes

Two tables are displayed using `ps` output:

- **Top 10 by CPU%** — sorted by `-%cpu`, filtered to exclude monitoring
  processes (`ps`, `awk`, `grep`, `head`, `tail`, `sort`) to avoid
  self-reference noise

- **Top 15 by RSS** — sorted by `-rss`, memory shown in MB
  (calculated as `rss/1024`)

==============================================================

### Step 9 — OOM Killer detection

`dmesg` is scanned for OOM events since last boot.
Keywords: `oom-kill`, `Out of memory`, `Killed process`.

If OOM events are found, they are shown in red with the last 5 entries.
`/var/log/syslog` is also scanned separately for persistent OOM records.

==============================================================

### Step 10 — Network overview

Two sub-sections are shown:

**Connections** — output of `ss -s` filtered for `Total`, `TCP:`, `UDP:` lines.
Shows total socket count, TCP established, time-wait etc.

**Interface traffic** — `ip -s link` parsed with `awk` to extract RX/TX bytes
per interface. Values are automatically converted to MB or GB.
Only `eth`, `ens`, `enp`, `wg`, `awg`, `tun`, `vmbr` interfaces are shown.

**Monthly traffic** — if `vnstat` is installed, monthly RX/TX statistics
are shown per interface using the current `YYYY-MM` month key.

==============================================================

### Step 11 — Blacklist system status

This section is always shown regardless of server role.
It reports the state of the `vladblacklist` ipset-based IP blocking system:

**Sub-step 11a — ipset count**
Runs `ipset list vladblacklist` and parses `Number of entries`.
States: `loaded — N IPs/subnets` (green) / `exists but empty` (yellow) /
`not loaded` (red) / `ipset not installed` (yellow).

**Sub-step 11b — iptables DROP rule**
Checks `iptables -L INPUT -n` for a rule referencing `vladblacklist`.
Shows rule number if active, or `MISSING — not protected!` in red.

**Sub-step 11c — Last deploy log**
Reads the last line of `/var/log/vladblacklist.log`.
Lines containing `error`, `fail`, or `warn` are shown in red; others in green.

**Sub-step 11d — Cron auto-update**
Checks `crontab -l` for `deploy-blacklist.sh` to confirm scheduled updates.

**Sub-step 11e — CrowdSec active bans**
Runs `cscli decisions list` and counts active bans.
Also shows the 3 most recent alerts from the last 24 hours.

==============================================================

### Step 12 — Role-specific sections (WEB)

Activated when `ROLE = WEB` (nginx + /var/www detected).

**PHP-FPM Pools** — counts worker processes and total RAM per pool user.

**Top-10 Traffic** — finds all `*access.log` files modified within the time
window using `find -mmin -M`, counts lines per log file, sorts descending.

**Top-10 IPs** — reads tails of all access logs, extracts field `$1` (client IP),
counts with `uniq -c`, sorts by request count.

**HTTP Status Codes** — extracts field `$9` (HTTP status), counts occurrences.
Color-coded: 2xx green, 3xx cyan, 4xx yellow, 5xx red.

**WP-Login Attacks** — grep for `wp-login.php` across all access logs and
nginx logs. IPs with >100 hits shown in red, >20 in yellow.

**HTTP 502/503 by Domain** — scans each domain's access log separately,
counts upstream errors, sorts by domain.

**PHP-FPM Slow Log** — searches common slow log paths with glob patterns,
counts entries per pool.

**Nginx Slow Requests (>3s)** — parses response time from the last field of
each log line, collects requests with response time ≥ 3 seconds.
Top 10 slowest shown; ≥10s in red, others in yellow.

**PHP Error Rate** — cross-references access log request counts with error log
PHP fatal/warning counts. Calculates error percentage per domain.
Domains with ≥5% error rate shown in red, ≥1% in yellow.

**Font Filename Errors** — checks for `File name too long` + `fonts` in
frontend error logs. A Flatsome/local-font deployment issue detector.

**Nginx status** — worker count, TCP established, active connections via
`http://127.0.0.1/nginx_status` (requires stub_status module).

**MySQL / MariaDB** — connected threads, running threads, slow query count,
server uptime. If MariaDB restarted within 24 hours, a red warning is shown.

**Database Sizes** — lists all user databases with size in MB, color-coded
by size threshold (green / yellow ≥100MB / red ≥500MB).

**Critical Errors** — grep across all error logs for fatal upstream/memory
errors in the selected time window.

**CrowdSec** — ban count and recent alerts.

**Fail2ban / UFW** — per-jail current and total ban counts, UFW rule list.

==============================================================

### Step 13 — Role-specific sections (VPN)

Activated when `ROLE` starts with `VPN`.

**VPN Status** — runs `wg show all` and/or `awg show all`, shows interfaces,
peers, endpoints, and transfer stats. For Xray, checks `systemctl is-active`
and counts established TCP connections.

**VPN Peers** — total peer count per WireGuard/AmneziaWG interface.

**VPN Traffic** — `ip -s link` filtered for `wg`, `awg`, `tun` interfaces.

**Fail2ban / UFW** — same as WEB role.

==============================================================

### Step 14 — Docker container status

Always shown. Lists up to 10 containers with name, status, and image.
Running containers shown in green, stopped/failed in red.

==============================================================

### Step 15 — Systemd service health

A fixed list of known services is checked with `systemctl is-active`:

```
nginx  mariadb  mysql  php8.1-fpm  php8.2-fpm  php8.3-fpm  php8.4-fpm
crowdsec  crowdsec-firewall-bouncer  fail2ban  exim4  postfix
docker  ssh  xray  wg-quick@wg0  amnezia-wg  smbd  nmbd  vnstat
```

Only services that exist on the system (via `systemctl list-units`) are shown.
Active = green, any other state = red.

==============================================================

### Step 16 — Disk I/O live sample

Reads `/proc/diskstats` read/write sector counters twice with a 1-second
`sleep` between reads. Calculates throughput in MB/s:

```
((sectors_after - sectors_before) × 512) ÷ 1048576 = MB/s
```

Detects the first `vd`, `sd`, or `nvme` non-partition device automatically.

==============================================================

### Step 17 — Swap usage by process

Reads `/proc/*/status` for all processes, extracts `VmSwap` values.
Top 5 swap consumers sorted descending. Color-coded:
cyan below 50MB, yellow 50–199MB, red ≥200MB.

==============================================================

### Step 18 — Dmesg error tail

Last 10 lines from `dmesg -T` matching `error|fail|oom|kill|panic|warn`.

==============================================================

### Step 19 — CrowdSec metrics

If `cscli` is installed, runs `cscli metrics` and extracts the Parsers section.
Shows top 8 parser lines for a quick overview of detection activity.

==============================================================

### Step 20 — Footer

```
====...====
= Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz =
====...====
```

==============================================================
## 📊 OUTPUT SECTIONS BY ROLE
==============================================================

| Section                    | GENERIC | WEB | VPN | DOCKER |
|----------------------------|:-------:|:---:|:---:|:------:|
| Header + uptime            | ✅      | ✅  | ✅  | ✅     |
| RAM + Swap                 | ✅      | ✅  | ✅  | ✅     |
| Disk usage                 | ✅      | ✅  | ✅  | ✅     |
| Top CPU / RAM processes    | ✅      | ✅  | ✅  | ✅     |
| OOM Killer                 | ✅      | ✅  | ✅  | ✅     |
| Network + vnstat           | ✅      | ✅  | ✅  | ✅     |
| Blacklist system           | ✅      | ✅  | ✅  | ✅     |
| PHP-FPM pools              | ❌      | ✅  | ❌  | ❌     |
| Traffic / IP / HTTP stats  | ❌      | ✅  | ❌  | ❌     |
| WP-Login attack detector   | ❌      | ✅  | ❌  | ❌     |
| 502/503 by domain          | ❌      | ✅  | ❌  | ❌     |
| PHP slow log               | ❌      | ✅  | ❌  | ❌     |
| Nginx slow requests >3s    | ❌      | ✅  | ❌  | ❌     |
| PHP error rate             | ❌      | ✅  | ❌  | ❌     |
| Font filename errors       | ❌      | ✅  | ❌  | ❌     |
| Nginx status               | ❌      | ✅  | ❌  | ❌     |
| MariaDB / database sizes   | ❌      | ✅  | ❌  | ❌     |
| VPN peer stats             | ❌      | ❌  | ✅  | ❌     |
| VPN traffic interfaces     | ❌      | ❌  | ✅  | ❌     |
| Docker containers          | ✅      | ✅  | ✅  | ✅     |
| Systemd services           | ✅      | ✅  | ✅  | ✅     |
| Disk I/O sample            | ✅      | ✅  | ✅  | ✅     |
| Swap by process            | ✅      | ✅  | ✅  | ✅     |
| Dmesg errors               | ✅      | ✅  | ✅  | ✅     |
| CrowdSec metrics           | ✅      | ✅  | ✅  | ✅     |
| Fail2ban / UFW             | ❌      | ✅  | ✅  | ❌     |

==============================================================
## 🎨 COLOR SYSTEM
==============================================================

SOS uses a consistent 4-color system across all sections:

| Color        | Meaning                               | Examples                        |
|--------------|---------------------------------------|---------------------------------|
| 🟢 Green     | Healthy, OK, within normal range      | Services active, low load       |
| 🟡 Yellow    | Warning, elevated, needs attention    | Load 60–89%, swap warnings      |
| 🔴 Red       | Critical, high, requires action       | Load >90%, OOM, attacks, errors |
| 🔵 Cyan      | Labels and field names                | "RAM:", "Uptime:", "CrowdSec:"  |
| ⚪ White     | Important neutral info                | SOS header, server role         |

Usage bars follow the same thresholds:

```
[****......]  40%   →  Green   (0–59%)
[*******...]  70%   →  Yellow  (60–89%)
[**********] 100%   →  Red     (90–100%)
```

==============================================================
## 🏗️ SERVER ROLE AUTO-DETECTION
==============================================================

Detection is performed once at startup using the `have()` helper,
which wraps `command -v` for safe binary existence checks.

```bash
ROLE="GENERIC"
have nginx && [ -d /var/www ] && ROLE="WEB"
have xray  && ROLE="VPN/XRAY"
have wg    && ROLE="VPN/WG"
have awg   && ROLE="VPN/AWG"
[ "$ROLE" = "GENERIC" ] && have docker && ROLE="DOCKER/NODE"
```

Detection priority (first match wins):

```
1. WEB         nginx binary present + /var/www directory exists
2. VPN/XRAY    xray binary present
3. VPN/WG      wg (WireGuard) binary present
4. VPN/AWG     awg (AmneziaWG) binary present
5. DOCKER/NODE docker binary present (and role still GENERIC)
6. GENERIC     fallback — shows all universal sections
```

==============================================================
## 🛡️ BLACKLIST SYSTEM BLOCK
==============================================================

This block integrates with the **vladblacklist** IPGuard system
(see `blacklist/README.md` for full documentation).

SOS reports 5 blacklist health indicators on every server:

```
ipset vladblacklist:    loaded — 14823 IPs/subnets
iptables DROP rule:     ACTIVE (INPUT rule #1)
Last deploy:            2026-05-28 03:15:01 — OK, 14823 IPs loaded
Auto-update:            cron active
CrowdSec active bans:   3 IPs
```

This allows you to verify in one glance that the blacklist is loaded,
the firewall rule is active, the last sync was successful, and the
automatic update is scheduled.

==============================================================
## 🔧 SAFETY & RELIABILITY
==============================================================

SOS is designed to **never crash** even on partially configured systems:

- Every numeric value passes through `safe_int()` or `safe_float()`
  before arithmetic operations — empty output from any command
  is treated as `0` rather than causing a syntax error

- The `have()` function checks binary existence before every tool call —
  missing tools (ipset, docker, cscli, vnstat, fail2ban, mysql) are
  gracefully reported as "not installed" rather than causing errors

- All `find` commands use `2>/dev/null` to suppress permission errors
  on directories the script cannot read

- Temporary files (e.g., slow request analysis) are created with `mktemp`
  and always cleaned up with `rm -f` in the same block

- `head -1` is applied before `tr` / `grep` pipeline parsing to prevent
  multiline command output from breaking string processing

- The installer runs `bash -n /usr/local/bin/sos` as a syntax check
  before finishing — a broken install is impossible

==============================================================
## 📁 FILE STRUCTURE
==============================================================

```
Linux_Server_Public/
├── install-sos.sh          ← One-line installer (embeds full sos script)
├── scripts/
│   └── install_sos.sh      ← Alternative installer with alias setup
└── sos/
    └── README.md           ← This file
```

The `sos` binary lives at `/usr/local/bin/sos` after installation.
It is a standalone file — no repo clone required on the target server.

==============================================================

```
= Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz =
```
