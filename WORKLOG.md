# WORKLOG — Linux_Server_Public

> Full session-by-session work log.
> = Rooted by VladiMIR | AI =

---

# 🗓️ Session: 2026-05-24 / 2026-05-25

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
# Removes old block (if exists) and rewrites cleanly
sed -i '/# === USER ALIASES BLOCK ===/,/# === END USER ALIASES BLOCK ===/d' /etc/bash.bashrc

cat >> /etc/bash.bashrc << 'SYSEOF'
# === USER ALIASES BLOCK ===
alias 00='clear'
alias mod='/usr/local/bin/mod'
alias cls='clear'
alias c='clear'
alias ls='ls --color=auto'
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
export MC_COLOR_TABLE='...'
# === END USER ALIASES BLOCK ===
SYSEOF
```

- Step is **idempotent** — safe to run multiple times, always produces clean result
- Step count bumped: 6 → **7 steps** total
- Version bumped to `v2026.05.25`

### Universal deploy command (any server)

```bash
bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/setup_aliases_modded_mc.sh) && source ~/.bashrc
```

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

# 🗓️ Session: 2026-04-12 / 2026-04-13

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

**Full sos alias set on 222:**
```bash
alias sos='bash /root/Linux_Server_Public/222/sos.sh 1h'
alias sos1='bash /root/Linux_Server_Public/222/sos.sh 1h'
alias sos3='bash /root/Linux_Server_Public/222/sos.sh 3h'
alias sos24='bash /root/Linux_Server_Public/222/sos.sh 24h'
alias sos120='bash /root/Linux_Server_Public/222/sos.sh 120h'
```

---

### 2. `222/ALIASES.md` — updated

> **Version before:** without `sos1` | **Version after:** v2026-04-13

Changes:
- Added `sos1` row to SOS table
- Moved SOS section to top (right after "How to restore")
- Added case-sensitivity warning:

```
✅ Correct: sos  sos1  sos3  sos24  sos120
❌ Wrong:   SOS 1  SOS1  — bash aliases are case-sensitive!
```

---

## 💻 Server 109-RU-FastVDS

### 1. `109/.bashrc` — updated

> **Version before:** v2026-04-10 | **Version after:** v2026-04-13

**Problem:** alias `sos1` was missing. Typing `sos1` executed old or undefined code.

**Fix:** added `sos1` alias to the SOS block next to `sos`.

**Full sos alias set on 109:**
```bash
alias sos='bash /root/Linux_Server_Public/109/sos.sh 1h'
alias sos1='bash /root/Linux_Server_Public/109/sos.sh 1h'
alias sos3='bash /root/Linux_Server_Public/109/sos.sh 3h'
alias sos24='bash /root/Linux_Server_Public/109/sos.sh 24h'
alias sos120='bash /root/Linux_Server_Public/109/sos.sh 120h'
```

**Commit:** [`Add alias sos1 to 109/.bashrc v2026-04-13`](https://github.com/GinCz/Linux_Server_Public/commit/f6486a25fcdf35ea7c51a1d20d443627e37c37f0)

---

### 2. `109/ALIASES.md` — updated

> **Version before:** without `sos1` | **Version after:** v2026-04-13

Changes identical to 222/ALIASES.md:
- Added `sos1` to SOS table
- Moved SOS section to top
- Added case-sensitivity warning

**Commit:** [`Add sos1 alias to ALIASES.md on both 222 and 109 v2026-04-13`](https://github.com/GinCz/Linux_Server_Public/commit/f0be4c5439263b497e1634b32e7a8717735e0085)

---

## ⚠️ SOS Aliases Rule

Bash aliases are case-sensitive. Always use lowercase:

| Command | Script | Period | Both servers |
|---|---|---|---|
| `sos` | `sos.sh 1h` | 1 hour | ✅ 222 and 109 |
| `sos1` | `sos.sh 1h` | 1 hour | ✅ 222 and 109 |
| `sos3` | `sos.sh 3h` | 3 hours | ✅ 222 and 109 |
| `sos24` | `sos.sh 24h` | 24 hours | ✅ 222 and 109 |
| `sos120` | `sos.sh 120h` | 120 hours | ✅ 222 and 109 |
| ~~`SOS`~~ | — | — | ❌ does not exist |
| ~~`SOS1`~~ | — | — | ❌ does not exist |

---

## 📂 Changed Files

| File | What changed | Commit |
|---|---|---|
| `109/.bashrc` | Added `alias sos1=...`, version bumped to v2026-04-13 | [f6486a2](https://github.com/GinCz/Linux_Server_Public/commit/f6486a25fcdf35ea7c51a1d20d443627e37c37f0) |
| `109/ALIASES.md` | Added `sos1` to SOS table, section moved to top | [f0be4c5](https://github.com/GinCz/Linux_Server_Public/commit/f0be4c5439263b497e1634b32e7a8717735e0085) |
| `222/ALIASES.md` | Added `sos1` to SOS table, section moved to top | [f0be4c5](https://github.com/GinCz/Linux_Server_Public/commit/f0be4c5439263b497e1634b32e7a8717735e0085) |
| `222/.bashrc` | Not modified — `sos1` was already present | — |

---

*= Rooted by VladiMIR + AI | v.2026.05.25 | github.com/GinCz/Linux_Server_Public =*
