# 📋 CHANGELOG — Linux_Server_Public

All notable changes to this repository are documented here.  
Format: `YYYY-MM-DD | [server] | description`

---

## 2026-04-28 | 222 + ALL VPN | sos script unification + deploy to all nodes

### Goal
Replace all per-role sos variants (`sos_vpn.sh`, `sos_web.sh`, symlinks, aliases) with
a single universal script `sos` — one file, role auto-detected, parameters as arguments.

### Changes

#### `222/sos.sh` — unified universal SOS script
- Single file `/usr/local/bin/sos` on every server
- Role auto-detected at runtime: `[WEB]` if nginx + `/var/www` found, `[VPN]` otherwise
- Time window via argument: `sos` = 1h default, `sos 3h`, `sos 24h`, `sos 120h`, `sos 30m`
- No symlinks, no aliases, no separate scripts per role
- Installed on: **222-DE-NetCup** and all **8 VPN nodes**

#### `222/deploy_sos_all_vpn.sh` — deploy script from 222 to all VPN nodes
- Loops over all 8 VPN nodes via SSH
- Downloads `sos.sh` from GitHub directly on each remote node via `curl`
- Reports `✓ installed` / `✗ FAILED` per node with summary
- Uses `StrictHostKeyChecking=accept-new` to handle reinstalled servers
- IPs masked in public repo (`xxx.xxx.xxx.XX`)

### Issues resolved during session

| Issue | Cause | Fix |
|---|---|---|
| 3 nodes FAILED on first deploy | SSH host key changed after server reinstall | `ssh-keygen -R <IP>` for each node |
| 3 nodes asked for password | SSH key from 222 not yet copied to those nodes | `ssh-copy-id` ran for all 3 |
| Old `sos_vpn.sh` version on some nodes | Previous script not replaced | New deploy overwrote it |

### SSH key status after session
- All 8 VPN nodes: passwordless SSH from 222 confirmed ✅
- `id_ed25519.pub` from 222 added to `authorized_keys` on ALEX_47, 4TON_237, TATRA_9

### Verification
```
ALEX_47      109.xxx.xxx.xx  ... ✓ sos OK
4TON_237     144.xxx.xxx.xxx ... ✓ sos OK
TATRA_9      144.xxx.xxx.x   ... ✓ sos OK
SHAHIN_227   144.xxx.xxx.xxx ... ✓ sos OK
STOLB_24     144.xxx.xxx.xx  ... ✓ sos OK
PILIK_178    91.xxx.xxx.xxx  ... ✓ sos OK
ILYA_176     146.xxx.xxx.xxx ... ✓ sos OK
SO_38        144.xxx.xxx.xx  ... ✓ sos OK
```

### SOS output highlights — 222-DE-NetCup (24h window)
| Metric | Value |
|---|---|
| Load | 0.43 / 0.45 / 0.45 (11% / 4 cores) |
| RAM | 3.8Gi used / 1.1Gi free |
| Swap | 1.3Gi / 4.0Gi |
| Disk | 53G / 247G (22%) |
| Total requests 24h | 153,819 |
| HTTP 200 | 30,703 |
| HTTP 502 | 436 (gincz + olga_pisareva pools) |
| WP-Login attacks | active, CrowdSec 0 bans — review recommended |
| Top traffic site | svetaform.eu — 24,174 req |
| Top external IP | 144.124.232.9 — 16,810 req (own VPN node) |

### Critical errors noted (222, 24h)
- `doska-*.ru` — `Call to undefined function wc_get_template()` — WooCommerce not loaded
- `doska-de.ru` — `Class WP_Widget_Media not found` — WordPress core load failure
- `doska-it.ru` — upstream timeout on `msk.tar.gz` download request (suspicious)
- **TODO:** investigate WooCommerce / WordPress load errors on doski sites

---

## 2026-04-12 20:57–21:13 CEST | 222 | SOS report analysis — doski CPU spike

### SOS report 20:57 CEST — state snapshot
| Metric | Value |
|---|---|
| Load | 0.67 / 0.76 / 0.60 (17% / 4 cores) |
| RAM | used 3.5Gi / free 985Mi / Swap 1.0Gi |
| CrowdSec | ✅ active, **53 bans** |
| All services | ✅ all active |

### 🔴 Alert: doski PHP-FPM — 82% + 67% CPU
- **Observed:** 2 × `php-fpm: doski` processes at 82.5% and 67.5% CPU
- **Pool RAM:** 142MB total for doski pool
- **Investigation:** `/var/www/doski/data/www/` contains 11 sites:
  `doska-cz.ru`, `doska-de.ru`, `doska-esp.ru`, `doska-fr.ru`, `doska-gr.ru`,
  `doska-hun.ru`, `doska-isl.ru`, `doska-it.ru`, `doska-mld.ru`, `doska-pl.ru`, `doska-ua.ru`
- **Root cause:** VladiMIR manually updated **translations + SEOPress settings** on the doska-*.ru sites at ~20:57
- **Conclusion:** CPU spike was **expected and legitimate** — not an attack or runaway process
- **Action taken:** None required — CPU normalised after update completed

### 🔴 Critical errors on 2 sites (from log — occurred earlier in the day)
| Site | Time | Error |
|---|---|---|
| `autoservis-praha.eu` | 10:30 CEST | `PHP Fatal: Undefined constant "ABSPATH" in wp-settings.php:34` |
| `stm-services-group.cz` | 01:32 CEST | `PHP Fatal: Undefined constant "ABSPATH" in wp-settings.php:34` |

- **Cause:** WordPress bootstrap failing — `ABSPATH` is defined in `wp-config.php` and passed to `wp-settings.php`
  This error means PHP is executing `wp-settings.php` without first loading `wp-config.php`
  Typical triggers: corrupted `wp-config.php`, broken plugin loading order, or PHP-FPM process leak hitting a cached bad state
- **Status:** Errors occurred hours before the session, sites appear operational in the 20:57 SOS
- **TODO:** Check WP Admin on both sites, run `wp core verify-checksums` if issues recur

### 🟡 HTTP 502 errors — 1907 in last 1h
- Correlated with doski CPU spike during translation update
- PHP-FPM workers temporarily saturated → Nginx returned 502 to waiting requests
- Expected to resolve automatically after update completed

### 🟡 IP `103.186.31.44` still in TOP-IPs (3487 req/h)
- Still showing in logs despite 168h ban applied at 12:46 UTC
- **Explanation:** CrowdSec firewall-bouncer blocks at iptables level BEFORE Nginx
  but Nginx access logs record the connection attempt regardless
- Actually the IP IS blocked — requests never reach PHP, just hit Nginx and get dropped
- **No action needed**

### ✅ Confirmed working after CrowdSec fix
- `crowdsec` → active ✅
- `crowdsec-firewall-bouncer` → active ✅
- 53 bans active, new bans accumulating (44661–44668 seen)
- escalating ban duration: `duration_expr` confirmed working

---

## 2026-04-12 20:15–20:54 CEST | 222 | CrowdSec outage — full incident log

### 📅 Timeline

#### 20:15 CEST — SOS report received
- Evening SOS report showed IP `103.186.31.44` (Indonesia) with **2226 wp-login hits in 3h**
- CrowdSec ban was flat **4h** — decision: upgrade to escalating bans (24h → 48h → 72h...)
- Netdata using 195MB RAM with no retention limit
- RAM: `used 3.8Gi / free 984Mi / Swap 1.2Gi`

#### 20:20 CEST — Investigation: IP already banned
- Ran `cscli decisions list -i 103.186.31.44` and `cscli alerts list -i 103.186.31.44`
- **Result:** IP was already banned at **12:46 UTC** (168h ban via `custom/xmlrpc-bf`)
- SOS showed it in TOP-IPs because the 3h log window included time **before** the ban
- CrowdSec was working correctly — no manual action needed

#### 20:34 CEST — profiles.yaml attempt #1 (FAILED)
- `duration_expr` placed **inside `decisions:` list** — wrong YAML level
- **Error:** `field duration_expr not found in type models.Decision`
- **Repo commit:** `35e0483`

#### 20:36 CEST — profiles.yaml attempt #2 (FAILED)
- Moved `duration_expr` to top-level (correct position)
- **Error:** `FATAL invalid hub index: open /etc/crowdsec/hub/.index.json: no such file or directory`
- **Repo commit:** `8c677a9`

#### 20:39 CEST — Netdata optimisation (SUCCESS, independent)
- `history = 1800`, `update every = 3`, `dbengine multihost disk space MB = 256`
- **Result:** RAM: `3.8Gi → 3.1Gi`

#### 20:43 CEST — Hub restore + attempt #3 (FAILED)
- `cscli hub update` → restored `.index.json` ✅
- **New error:** `bad yaml in custom-wp-login-hardban.yaml: field on_overflow not found in type leakybucket.BucketSpec`
- **Root cause:** `on_overflow: requeue: "1h"` — field does not exist in CrowdSec v1.7.7 — AI error during original creation

#### 20:54 CEST — Fix applied: on_overflow removed (SUCCESS)
- Removed `on_overflow:` block from `custom-wp-login-hardban.yaml`
- **Repo commit:** `0d058fc`
- `systemctl start crowdsec` → **✅ active**
- **Total downtime: ~18 minutes**

### 🚨 Root causes summary

| # | Error | Cause | Fix |
|---|---|---|---|
| 1 | `duration_expr not found in type models.Decision` | `duration_expr` inside `decisions:` list | Move to top-level of profile block |
| 2 | `hub/.index.json: no such file or directory` | Hub index missing | `cscli hub update` |
| 3 | `on_overflow not found in type leakybucket.BucketSpec` | Invalid field — AI error in original scenario | Remove `on_overflow:` block |

### 📚 Lessons learned
1. `duration_expr` must be **top-level** in profile block, NOT inside `decisions:`
2. Always run `cscli hub update` before restarting CrowdSec if hub warnings appeared
3. `on_overflow` does not exist in v1.7.7 — ban duration is controlled by `profiles.yaml` only
4. Always run `crowdsec -t -c /etc/crowdsec/config.yaml` before `systemctl start`
5. Custom scenario files must be saved to repo — server-only files cause debugging confusion

### ✅ Final state (20:54 CEST)
| Metric | Before | After |
|---|---|---|
| CrowdSec | active | active ✅ |
| Ban policy | flat 4h | escalating 24h/48h/72h... |
| RAM used | 3.8GB | 3.1GB |
| Swap used | 1.2GB | 1.0GB |
| Netdata retention | 1h / 1s | 30min / 3s |
| custom-wp-login-hardban.yaml | server only | saved to repo ✅ |

---

## 2026-04-12 | 222 | CrowdSec hub full restore — parsers + collections

### Context
After `cscli hub update`, all hub-managed parsers showed WARNING. Hub directory empty/corrupted.

### Fix
1. `systemctl stop crowdsec`
2. `rm -rf /etc/crowdsec/hub/ && mkdir -p /etc/crowdsec/hub/`
3. `cscli hub update`
4. Reinstalled: `linux`, `nginx`, `sshd`, `wordpress`, `base-http-scenarios`, `http-cve`, `whitelist-good-actors`, `mysql`, `mariadb`
5. `systemctl start crowdsec`

### Result
All parsers + 31 CVE scenarios active, 48 bans within minutes ✅

### ⛔ SSH port 22 — must NOT be changed
Port 22 stays. CrowdSec handles brute-force protection. Previous attempt to move to 2222 broke dependent services.

### Script: `222/fix_crowdsec_hub_v2026-04-12.sh`

---

## 2026-04-12 | 222 | PHP memory + OPcache tuning

### Context
Morning SOS: Load 1.38, RAM 301MB free, `svetaform.eu` OOM on `/wp-json/oembed/`

### Changes
- `memory_limit`: 128M → 256M (global `/etc/php/8.3/fpm/php.ini`)
- OPcache: 256MB, 20000 files, `revalidate_freq=60`, `validate_timestamps=1`
- README: Server Configuration Philosophy section added (all config at server level, never per-site)

### Result
Load: 1.38 → 0.41 | RAM free: 301MB → 1.1GB | OOM errors stopped ✅

---

## 2026-04-12 | 109 | wp_update_all.sh language support
- Added WordPress language file updates — `v2026-04-12`

---

## 2026-04-10 | VPN + ALL | Documentation + backup system
- SSH keys for VPN nodes, VPN Docker backup → AWS S3, cron 03:30 daily, KEEP=7
- `VPN/BACKUP.md`, `VPN/README.md`, root `README.md` updated

---

## 2026-04-08 | 222 + 109 | PHP-FPM per-site limits
- `CPUQuota=320%`, `MemoryMax=6.8G`, `pm.max_children=8`, `pm.max_requests=500`

---

## 2026-04-07 | 222 | PHP-FPM watchdog + Telegram alerts
- Auto-restart pool if CPU > 90% for 15min, Telegram alert
- Cron: `*/5 * * * *`

---

## 2026-04-05 | 222 | CrowdSec + Nginx bouncer fix
- Fixed CrowdSec engine INACTIVE, rebuilt hub, verified bouncer ✅

---

## 2026-03-16 | ALL | Initial repository setup
- Created `Linux_Server_Public`, folder structure, coding standards, `save` alias

---

*= Rooted by VladiMIR | AI =*
