# 🪣 Windows Scripts

## SMB_Connect.bat

**Version:** `v2026.06.15b`
**Author:** Rooted by VladiMIR + AI | [github.com/GinCz](https://github.com/GinCz)
**Run as:** Administrator

### Description

Parallel connection of 10 SMB file shares with color-coded status output and automatic drive label assignment in Windows Explorer via the registry.

Each drive connects to the `\storage` share, which contains two subdirectories:
- `soft\` — vlad RW, usr RO
- `user\` — vlad RW, usr RW

### ✨ Features

- **Parallel launch** — all 10 servers connect simultaneously via `start /b`
- **`\storage` share** — browse-only root; access controlled through `soft` and `user` subdirectories
- **Folder-based result** — `C:\smbtmp\ok\`, `fail\`, `skip\` — more reliable than string comparison
- **Drive labels** — `reg add` in the main process, correct quoting without escaping
- **IONOS_38** — no ping check (ICMP blocked by IPGuard, SMB works directly)
- **PILIK_33** — included in the script; shows `[ SKIP ]` when server is offline
- **Password entered at launch** — not stored in the script, cleared from memory after use
- **Color output** — ANSI colors: green OK, yellow SKIP, red FAIL/TIMEOUT

### 🖥️ Servers

| Drive | Name | IP | Notes |
|---|---|---|---|
| K: | AWS_12 | 18.195.117.12 | AWS Frankfurt |
| L: | IONOS_38 | 82.223.116.38 | No ping (ICMP blocked) |
| I: | ILYA_176 | 146.103.110.176 | |
| N: | PILIK_33 | 195.63.138.33 | Backup server |
| O: | 4TON_237 | 144.124.228.237 | |
| Q: | SO_38 | 144.124.233.38 | |
| T: | TATRA_9 | 144.124.232.9 | |
| V: | SHAHIN_227 | 144.124.228.227 | |
| W: | STOLB_24 | 144.124.239.24 | |
| Y: | ALEX_47 | 109.234.38.47 | |

### Share structure (on each server)

```
\\SERVER_IP\storage\
    ├── soft\          ← vlad RW, usr RO
    └── user\          ← vlad RW, usr RW
```

### Status codes

| Status | Meaning |
|---|---|
| `[  OK  ]` | Drive connected successfully |
| `[ SKIP ]` | Server unreachable (ping failed) |
| `[ FAIL ]` | Ping OK, but SMB rejected the connection |
| `[TIMEOUT]` | Failed to connect within 8 seconds |

### 📅 Changelog

| Version | Changes |
|---|---|
| v2026.06.15b | Connect to `\storage` instead of `\soft`; `soft\` and `user\` visible inside; all `reg add` updated to `#storage` |
| v2026.06.14h | Password entered at launch, not stored in the script |
| v2026.06.14g | Folder-based result (ok/fail/skip), `reg add` in main process, IONOS without ping |
| v2026.06.14f | `reg add` inside `cmd /c` with escaping (broken), `for/f` string comparison (broken) |
| v2026.06.14e | First working version with parallel launch |

---

*= Rooted by VladiMIR + AI | v2026.07.11 | github.com/GinCz =*
