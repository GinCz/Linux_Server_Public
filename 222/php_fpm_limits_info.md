# PHP-FPM Resource Limits — CPU + RAM
**Script:** `/root/scripts/set_php_fpm_limits_v2026-04-07.sh`  
**Works on:** Both servers — 222-DE-NetCup and 109-RU-FastVDS  
**Version:** v2026-04-07.2  

---

## Problem History (07.04.2026)

### What happened
Site `diamond-odtah.cz` occupied ~90% CPU on server 222. IP `85.203.23.4` sent 471 requests,
other bots joined. The old `set_php_limits.sh` script limited only `pm.max_children` (RAM),
but had **no CPU limit** at all. One pool with 70% allowed processes could grab all 4 CPU cores.

### Root cause
Old script `set_php_limits.sh` (still kept for history):
- ✅ Limited RAM via `pm.max_children` (70% rule)
- ❌ No `CPUQuota` in systemd
- ❌ No `MemoryMax` in systemd
- ❌ No `pm.max_requests` (workers never restarted → memory leaks)

---

## New Solution: Two-Layer CPU+RAM Protection

### Layer 1 — PHP-FPM pool settings (per-pool)
| Parameter | Value | Reason |
|---|---|---|
| `pm` | `dynamic` | Workers start/stop based on load |
| `pm.max_children` | 8 (hard cap) | 70% of (8GB - 1.5GB reserve) ÷ 60MB/proc, capped at 8 |
| `pm.start_servers` | 2 | 25% of max_children |
| `pm.min_spare_servers` | 1 | 20% of max_children |
| `pm.max_spare_servers` | 4 | 50% of max_children |
| `pm.max_requests` | 500 | Worker auto-restart prevents memory leaks |

### Layer 2 — systemd cgroups (global PHP-FPM service)
File: `/etc/systemd/system/<php-service>.d/cpu-memory-limit.conf`

| Parameter | Value | Reason |
|---|---|---|
| `CPUQuota` | 320% | 4 cores × 80% — always 1 core free for Nginx/MySQL/OS |
| `MemoryMax` | 6435M (222) / 6339M (109) | Hard RAM limit — kernel kills PHP workers first |
| `MemoryHigh` | 85% of MemoryMax | Soft limit — throttle before hitting hard cap |
| `OOMScoreAdjust` | 300 | PHP workers are OOM-killed before Nginx/MySQL |

---

## FastPanel Service Name Bug (fixed in v2)

FastPanel names PHP-FPM services WITHOUT a dot:  
`php83-fpm.service`, `php84-fpm.service`, `php56-fpm.service`

Standard Ubuntu names: `php8.3-fpm.service`

The script extracted `83` from the service name, then tried to run `php-fpm83 -t` — which doesn't exist.
**Fix:** convert `83` → `8.3` via bash substring: `"${RAW_VER:0:1}.${RAW_VER:1}"`

---

## Cloudflare WAF Rules (server 222 — all domains)

Added 07.04.2026 in Cloudflare Security → WAF → Custom Rules:

**Rule 20 — Block XMLRPC** (Action: Block)
```
(http.request.uri.path eq "/xmlrpc.php") or (http.request.uri.path eq "//xmlrpc.php")
```

**Rule 30 — Challenge WP-Admin + Login** (Action: Managed Challenge)
```
(http.request.uri.path eq "/wp-login.php" or http.request.uri.path eq "//wp-login.php")
or (
  (starts_with(http.request.uri.path, "/wp-admin/") or starts_with(http.request.uri.path, "//wp-admin/"))
  and not (http.request.uri.path eq "/wp-admin/admin-ajax.php" or http.request.uri.path eq "//wp-admin/admin-ajax.php")
)
```
Note: `admin-ajax.php` is excluded — it's used by WooCommerce and WordPress frontend AJAX calls.

---

## Usage

```bash
# On either server — script auto-detects hardware
wget -O /root/set_php_fpm_limits_v2026-04-07.sh \
  https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/222/set_php_fpm_limits_v2026-04-07.sh
chmod +x /root/set_php_fpm_limits_v2026-04-07.sh
bash /root/set_php_fpm_limits_v2026-04-07.sh
```

## Server results

**222-DE-NetCup** (7935 MB RAM, 4 cores, php84-fpm.service):
- 3 pools updated: gadanie-tel.eu, svetaform.eu, wowflow.cz
- CPUQuota=320%, MemoryMax=6435M
- diamond-odtah.cz was the attacker — protected by Cloudflare WAF rules

**109-RU-FastVDS** (7839 MB RAM, 4 cores, php56-fpm.service... suspicious — check if php8.x is installed):
- 6 pools updated: ne-son.ru, shapkioptom.ru, stanok-ural.ru, study-italy.eu, tatra-ural.ru, ugfp.ru
- CPUQuota=320%, MemoryMax=6339M

---
_= Rooted by VladiMIR | AI =_
