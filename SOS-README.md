# ⚡ SOS — Server Operational Status

> A self-contained Bash diagnostic tool for Linux servers.
> One command. Full picture. No dependencies.

**SOS** is a single-file Bash script that prints a structured, color-coded status
report of a Linux server — CPU load, RAM, disk, network, top processes, blacklist
system, services, and role-specific sections (WEB / VPN / DOCKER).
It installs in 10 seconds and works on any Ubuntu/Debian server with no external
dependencies beyond standard coreutils.

---

## 🖥 Proposed Names (for discussion)

The tool needs a proper project name — something short, memorable, and not already
taken as a bash utility. Ten candidates:

| # | Name | Meaning / Rationale |
|---|------|---------------------|
| 1 | **ServerWatch** | Direct, two words, no collision |
| 2 | **NodePulse** | "Pulse" implies live vitals; works for VPN nodes too |
| 3 | **StatusFlash** | Fast snapshot — flash = instant picture |
| 4 | **SysScope** | System scope / overview — clean and professional |
| 5 | **ServerLens** | One lens, full view |
| 6 | **QuickStatus** | Exactly what it does |
| 7 | **NetraCheck** | Netra = eye in Sanskrit; a nod to multi-server awareness |
| 8 | **GlanceOps** | One glance, all ops info |
| 9 | **PulseBoard** | Dashboard-like output, terminal native |
| 10 | **ViewNode** | View any node instantly |

> Current working name used in code: **SOS** (Server Operational Status).
> The command alias remains `sos` regardless of final name.

---

## ⚙️ Quick Install (one command)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/install-sos.sh)
```

This single command:
1. Writes the complete `sos` script to `/usr/local/bin/sos`
2. Sets `chmod +x`
3. Runs a syntax check (`bash -n`)
4. Registers all aliases in `/root/.bashrc`

After install, run `source ~/.bashrc` or open a new SSH session.

---

## 📋 Usage

```bash
sos           # default — last 24 hours (recommended)
sos 1h        # last 1 hour
sos 3h        # last 3 hours
sos 24h       # last 24 hours (same as default)
sos 120h      # last 5 days
sos 30m       # any custom window (minutes supported)
```

### Pre-registered Aliases

After installation the following aliases are available in `/root/.bashrc`:

| Alias | Equivalent | Window |
|-------|-----------|--------|
| `sos` | `sos 24h` | Last 24 hours **(default)** |
| `sos1` | `sos 1h` | Last 1 hour |
| `sos3` | `sos 3h` | Last 3 hours |
| `sos24` | `sos 24h` | Last 24 hours |
| `sos120` | `sos 120h` | Last 5 days |

The time window controls how far back log-based sections look (access logs,
error logs, slow requests). System metrics (RAM, CPU, disk) are always current.

---

## 🔍 What SOS Reports

### Always (all server types)

| Section | Description |
|---------|-------------|
| **Header** | Hostname, IP, timestamp, CPU load vs cores, uptime, auto-detected role |
| **RAM** | Used / total with visual bar (green / yellow / red by threshold) |
| **Swap** | Usage bar, or "not configured" |
| **Disk** | All `/dev/*` partitions — size, used, available, visual bar, mount |
| **Top 10 CPU%** | Processes sorted by CPU consumption |
| **Top 15 RAM** | Processes sorted by RSS, shown in MB |
| **OOM Killer** | Events since last boot + syslog count |
| **Network** | Connection summary, per-interface RX/TX since boot |
| **vnstat** | Monthly traffic per interface (if vnstat installed) |
| **Blacklist System** | ipset `vladblacklist` count, iptables DROP rule status, last deploy log, cron |
| **CrowdSec** | Active bans + recent alerts |
| **Docker** | All containers with status and image |
| **Services** | Systemd status for nginx, mariadb, php-fpm, crowdsec, fail2ban, xray, wg, etc. |
| **Disk I/O** | 1-second read/write sample in MB/s |
| **Swap Top-5** | Processes using the most swap |
| **dmesg Errors** | Last 10 error/fail/panic/warn lines |
| **CrowdSec Metrics** | Parser hit stats |

### WEB role (nginx + `/var/www` detected)

| Section | Description |
|---------|-------------|
| **PHP-FPM Pools** | Process count and total RAM per pool |
| **Top-10 Traffic** | Most active access logs by request count in the time window |
| **Top-10 IPs** | Highest-traffic client IPs in the time window |
| **HTTP Status** | Request counts grouped by status code (2xx green, 4xx yellow, 5xx red) |
| **WP-Login Attacks** | Per-IP brute force attempt counts |
| **HTTP 502/503 by Domain** | Error counts per domain |
| **PHP-FPM Slow Log** | Slow request counts per pool |
| **Nginx Slow Requests >3s** | Requests exceeding 3 seconds with URL and client IP |
| **PHP Error Rate** | PHP Fatal/Warning/Notice counts vs total requests per domain |
| **Font Filename Errors** | Flatsome / local font "filename too long" detection |
| **Nginx** | Worker count, TCP connections, stub_status if available |
| **MySQL / MariaDB** | Connected threads, running queries, slow queries, uptime |
| **MariaDB Database Sizes** | Per-database size in MB, color-coded by threshold |
| **Critical Errors** | Fatal / OOM / upstream timeout lines from error logs |
| **Fail2ban / UFW** | Per-jail ban counts, UFW rules |

### VPN role (wg / awg / xray detected)

| Section | Description |
|---------|-------------|
| **VPN Status** | WireGuard / AmneziaWG interface details, Xray service state |
| **VPN Peers** | Total peer count per WG command |
| **VPN Traffic** | Per-interface RX/TX for wg/awg/tun interfaces |
| **Fail2ban / UFW** | Same as WEB role |

---

## 🎨 Color System

| Color | Meaning |
|-------|---------|
| 🟢 Green | OK, normal, below 60% usage |
| 🟡 Yellow | Warning, 60–89% usage or non-critical issues |
| 🔴 Red | Critical, 90%+ usage or service down / OOM / ban active |
| 🔵 Cyan | Labels / section headers |
| ⚪ White | Role badge, version footer |

Visual usage bars use `[****......]` format — 10 characters, filled proportionally.

---

## 🤖 Auto Role Detection

The server role is detected automatically at runtime, no configuration needed:

| Detected condition | Role assigned |
|-------------------|---------------|
| `nginx` installed AND `/var/www` exists | `WEB` |
| `xray` installed | `VPN/XRAY` |
| `wg` installed | `VPN/WG` |
| `awg` installed | `VPN/AWG` |
| `docker` installed (fallback) | `DOCKER/NODE` |
| None of the above | `GENERIC` |

---

## 📦 Files

| File | Purpose |
|------|---------|
| `install-sos.sh` | **Self-contained installer** — contains the full sos script embedded as heredoc. Run this on any new server. |
| `scripts/install_sos.sh` | Lightweight installer that pulls `sos.sh` from the repo (requires git clone first). |
| `scripts/sos-fastpanel.sh` | Extended version with FastPanel-specific sections. |

---

## 🔧 Manual Install (without curl)

```bash
# Clone the repository
git clone https://github.com/GinCz/Linux_Server_Public.git /opt/linux-server
cd /opt/linux-server

# Run the installer
bash scripts/install_sos.sh
source ~/.bashrc
```

Or use the self-contained version (no clone needed):

```bash
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/install-sos.sh -o install-sos.sh
bash install-sos.sh
source ~/.bashrc
```

---

## 📊 Requirements

- **OS**: Ubuntu 22.04 / 24.04 or Debian 11/12 (tested)
- **Shell**: Bash 4.x+
- **Permissions**: root (required for `iptables`, `ipset`, `dmesg`, process inspection)
- **Required tools**: `awk`, `grep`, `sed`, `ps`, `df`, `free`, `ss`, `ip` — all present in standard Ubuntu/Debian
- **Optional tools** (used if installed): `vnstat`, `ipset`, `iptables`, `cscli` (CrowdSec), `fail2ban-client`, `ufw`, `docker`, `mysql`, `nginx`, `xray`, `wg`, `awg`

---

## 🔒 Security Notes

- The script reads system state only — it writes nothing to disk and changes no configuration.
- All `iptables` and `ipset` calls are read-only (`-L`, `list`).
- MariaDB access uses the local root socket (`mysql -N -e ...`) — no password required if configured via `~/.my.cnf` or socket auth.

---

## 📌 Similar Tools on GitHub

The following open-source tools cover overlapping ground but differ in scope:

| Tool | Language | Closest overlap |
|------|----------|-----------------|
| [htop](https://github.com/htop-dev/htop) | C | Interactive process viewer, no log analysis |
| [glances](https://github.com/nicolargo/glances) | Python | Real-time system monitor, requires Python + deps |
| [bottom (btm)](https://github.com/ClementTsang/bottom) | Rust | TUI monitor, no web/VPN role logic |
| [netdata](https://github.com/netdata/netdata) | C/Go | Full monitoring stack, persistent agent, not a quick CLI snapshot |
| [sysstat / sar](https://github.com/sysstat/sysstat) | C | Historical data collection, separate viewer required |

**SOS differs** in that it is a single Bash file, requires zero installation of
interpreters or agents, produces a complete role-aware snapshot in under 3 seconds,
and covers application-layer metrics (nginx logs, PHP-FPM, MariaDB, CrowdSec,
ipset blacklist) alongside standard system metrics — all in one terminal output.

---

## 🗒 Changelog

See [CHANGELOG.md](CHANGELOG.md) for full version history.

---

```
= Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz =
```
