# WORKLOG — Linux_Server_Public

> Full session-by-session work log.
> = Rooted by VladiMIR | AI =

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

### Cleanup Command

```bash
for I in 144.124.228.227 144.124.239.24 91.84.118.178 146.103.110.176; do
  ssh root@$I "crontab -l 2>/dev/null | grep -v 'auto_upgrade' | crontab - && echo OK"
done
```

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
- **Fix:** Added `safe_pct()` using pure `awk` for division:
  ```bash
  safe_pct() {
    local a b
    a="$(safe_int "${1:-0}")"
    b="$(safe_int "${2:-0}")"
    if [ "$b" -gt 0 ]; then
      awk -v a="$a" -v b="$b" 'BEGIN{printf "%.1f", (a/b)*100}'
    else
      printf '0.0'
    fi
  }
  ```
  Integer comparison uses `printf '%.0f'` rounding via awk before `[ ... -ge N ]`.

### Problem 3: HTTP 502/503 same domain counted multiple times

- **Root cause:** Multiple `*access.log` files exist per domain (rotated logs). Each was counted separately, so the same domain appeared 3–5 times in the list.
- **Fix:** Rewrote the section to collect `domain\tcount` pairs in a loop, then pipe through `awk '{sum[$1]+=$2} END{for (d in sum) print d, sum[d]}'` for aggregation before display.

### Problem 4: Monitoring tools appearing in top-CPU / top-RAM lists

- **Root cause:** `ps` itself, plus `awk`, `grep`, `head`, `tail`, `sort` spawned by the script appeared in the process list snapshot.
- **Fix:** Added `awk` filter to exclude these tool names from the output:
  ```bash
  awk 'NR==1 || ($5 !~ /^(ps|awk|grep|head|tail|sort)$/)'
  ```

### Output Limits Added (top-N, sections preserved)

| Section | Limit |
|---|---|
| TOP CPU% | top 10 |
| TOP RAM | top 15 |
| TOP TRAFFIC by log | top 10 |
| TOP IPs | top 10 |
| HTTP STATUS | top 10 |
| WP-LOGIN ATTACKS | top 10 |
| HTTP 502/503 BY DOMAIN | top 10 |
| PHP ERROR RATE | top 10 |
| MARIADB DATABASE SIZES | top 15 |
| DOCKER containers | top 10 |
| SWAP TOP PROCESSES | top 5 |
| DMESG ERRORS | last 10 lines |

---

## 🔧 scripts/setup_aliases_modded_mc.sh — Step [5/7] Added

### Problem: `/etc/bash.bashrc` aliases block broken or missing

- **Root cause:** Ubuntu system updates or manual edits can corrupt or remove the custom aliases block in `/etc/bash.bashrc`. This breaks `00`, `mod`, MC colors, `grep --color` for all users system-wide.
- **Symptoms:** `00: command not found`, `mod: command not found`, MC opens without color theme.

### Fix: New step [5/7] — idempotent block repair

```bash
sed -i '/# === USER ALIASES BLOCK ===/,/# === END USER ALIASES BLOCK ===/d' /etc/bash.bashrc
cat >> /etc/bash.bashrc << 'SYSEOF'
# === USER ALIASES BLOCK ===
alias 00='clear'
alias mod='/usr/local/bin/mod'
...
# === END USER ALIASES BLOCK ===
SYSEOF
```

- Step is **idempotent** — safe to run multiple times, always produces clean result
- Step count bumped: 6 → **7 steps** total
- Version bumped to `v2026.05.25`

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

## 💻 Server 222-DE-NetCup

### 1. `222/.bashrc` — no changes

> **Version before:** v2026-04-12 | **Version after:** v2026-04-12 (unchanged)

Alias `sos1` was already present at time of review. File not modified.

---

### 2. `222/ALIASES.md` — updated

Changes:
- Added `sos1` row to SOS table
- Moved SOS section to top
- Added case-sensitivity warning

---

## 💻 Server 109-RU-FastVDS

### 1. `109/.bashrc` — updated

**Fix:** added `sos1` alias to the SOS block.

**Commit:** [`f6486a2`](https://github.com/GinCz/Linux_Server_Public/commit/f6486a25fcdf35ea7c51a1d20d443627e37c37f0)

---

## 📂 Changed Files

| File | What changed | Commit |
|---|---|---|
| `109/.bashrc` | Added `alias sos1=...`, version bumped to v2026-04-13 | [f6486a2](https://github.com/GinCz/Linux_Server_Public/commit/f6486a25fcdf35ea7c51a1d20d443627e37c37f0) |
| `109/ALIASES.md` | Added `sos1` to SOS table | [f0be4c5](https://github.com/GinCz/Linux_Server_Public/commit/f0be4c5439263b497e1634b32e7a8717735e0085) |
| `222/ALIASES.md` | Added `sos1` to SOS table | [f0be4c5](https://github.com/GinCz/Linux_Server_Public/commit/f0be4c5439263b497e1634b32e7a8717735e0085) |

---

*= Rooted by VladiMIR + AI | v.2026.05.26 | github.com/GinCz/Linux_Server_Public =*
