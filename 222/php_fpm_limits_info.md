# PHP-FPM Resource Limits — CPU + RAM
**Script:** `set_php_fpm_limits_v2026-04-07.sh` (keep in `/root/` on both servers)  
**Works on:** 222-DE-NetCup AND 109-RU-FastVDS  
**Current version:** v2026-04-07.3  

---

## Incident: 07.04.2026 — diamond-odtah.cz, 90% CPU

### What happened
Site `diamond-odtah.cz` on server 222 showed ~90% CPU usage.
- Top attacker IP: `85.203.23.4` — 471 requests in last 1000 log lines
- Bursts up to 150 req/min
- Bots hitting WordPress entry points: `/wp-login.php`, `/wp-admin/`, `/xmlrpc.php`

### Root cause
Old script `set_php_limits.sh` limited only `pm.max_children` (RAM protection),
but had **no CPU limit** at all. One pool could grab all 4 CPU cores.

Also missing:
- No `CPUQuota` in systemd
- No `MemoryMax` in systemd  
- No `pm.max_requests` → workers ran forever → memory leaks accumulated

---

## Solution: Two-Layer CPU + RAM Protection

### Layer 1 — PHP-FPM pool config (per pool, in `/etc/php/8.x/fpm/pool.d/*.conf`)

| Parameter | Value | Reason |
|---|---|---|
| `pm` | `dynamic` | Workers scale between min_spare and max_children |
| `pm.max_children` | **8** (hard cap) | 70% of (8GB − 1.5GB reserve) ÷ 60MB/proc, capped at 8 |
| `pm.start_servers` | 2 | 25% of max_children |
| `pm.min_spare_servers` | 1 | 20% of max_children |
| `pm.max_spare_servers` | 4 | 50% of max_children |
| `pm.max_requests` | **500** | Worker auto-restart prevents memory leaks |

### Layer 2 — systemd cgroups (global per PHP-FPM service)

File: `/etc/systemd/system/php8.3-fpm.service.d/cpu-memory-limit.conf`

| Parameter | Value (222) | Value (109) | Reason |
|---|---|---|---|
| `CPUQuota` | 320% | 320% | 4 cores × 80% — always 1 core free for Nginx/MySQL/OS |
| `MemoryMax` | 6435M | 6339M | Hard RAM — kernel kills PHP workers first |
| `MemoryHigh` | 5469M | 5388M | Soft limit — throttle at 85% before hard cap |
| `OOMScoreAdjust` | 300 | 300 | PHP workers OOM-killed before Nginx/MySQL |

---

## Version History & Bugs Fixed

### v1 (initial)
- ✅ RAM limits via `pm.max_children` (70% rule)
- ❌ No CPUQuota, no MemoryMax in systemd
- ❌ No pm.max_requests

### v2 (07.04.2026)
- ✅ Added CPUQuota + MemoryMax + MemoryHigh + OOMScoreAdjust via systemd override
- ✅ Fixed pm.max_requests = 500
- **BUG**: FastPanel lists `php84-fpm.service` / `php56-fpm.service` in systemctl,
  but these are phantom names. Script wrote override to wrong dir
  (`php84-fpm.service.d/` instead of `php8.3-fpm.service.d/`). Limits showed `infinity`.
- **BUG**: Used `systemctl reload` — reload does NOT apply cgroup changes.
  Only `restart` re-reads the override and activates CPUQuota/MemoryMax.
- **BUG**: BLUE color `\033[0;34m` invisible on black terminal.

### v3 (07.04.2026 — current)
- ✅ Service detection: searches for `php[digit].[digit]-fpm.service` (with dot)
  — the canonical Ubuntu format, ignoring FastPanel phantom names
- ✅ Fallback: if dot-format not found, verify each candidate with `systemctl cat`
- ✅ Uses `systemctl restart` (not reload) to apply cgroup limits
- ✅ Verifies CPUQuota was applied by checking `CPUQuotaPerSecUSec != infinity`
- ✅ Color fixed: MAGENTA `\033[1;35m` instead of BLUE

---

## FastPanel Service Name Issue (root cause)

FastPanel on both servers shows phantom service names in `systemctl list-units`:
- 222: `php84-fpm.service` listed, but real file is `/lib/systemd/system/php8.3-fpm.service`
- 109: `php56-fpm.service` listed, but real file is `/lib/systemd/system/php8.3-fpm.service`

The phantom names do NOT have real `.service` files on disk.
`systemctl restart php84-fpm.service` → `Unit php84-fpm.service not found.`
`systemctl restart php8.3-fpm.service` → ✅ works

**Rule:** Always use `php[MAJOR].[MINOR]-fpm.service` format (with dot between major and minor).

---

## Verified Results

### 222-DE-NetCup (7935 MB RAM, 4 cores)
```
CPUQuotaPerSecUSec=3.200000s    ← 320% confirmed
MemoryHigh=5734662144           ← 5469M confirmed  
MemoryMax=6747586560            ← 6435M confirmed
```
Pools updated: gadanie-tel.eu, svetaform.eu, wowflow.cz (3/3)

### 109-RU-FastVDS (7839 MB RAM, 4 cores)
```
CPUQuotaPerSecUSec=3s           ← 320% confirmed
MemoryHigh=5649727488           ← 5388M confirmed
MemoryMax=6442450944            ← 6339M confirmed
```
Pools updated: ne-son.ru, shapkioptom.ru, stanok-ural.ru, study-italy.eu, tatra-ural.ru, ugfp.ru (6/6)

---

## Cloudflare WAF Rules (server 222 — all domains)

Added 07.04.2026 — see `cloudflare_waf_rules.md` for full details.

**Rule 20 — Block XMLRPC** (Action: Block)
```
(http.request.uri.path eq "/xmlrpc.php") or (http.request.uri.path eq "//xmlrpc.php")
```

**Rule 30 — Challenge WP-Admin + Login** (Action: Managed Challenge)  
Excludes `admin-ajax.php` — needed for WooCommerce and WordPress frontend AJAX.

---

## Usage

```bash
# Download and run on either server — auto-detects hardware
wget -O /root/set_php_fpm_limits_v2026-04-07.sh \
  https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/222/set_php_fpm_limits_v2026-04-07.sh
chmod +x /root/set_php_fpm_limits_v2026-04-07.sh
bash /root/set_php_fpm_limits_v2026-04-07.sh

# After running — verify limits applied:
systemctl show php8.3-fpm.service | grep -E 'CPUQuota|MemoryMax|MemoryHigh'
```

---
_= Rooted by VladiMIR | AI =_
