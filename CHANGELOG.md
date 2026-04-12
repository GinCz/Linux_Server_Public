# 📋 CHANGELOG — Linux_Server_Public

All notable changes to this repository are documented here.  
Format: `YYYY-MM-DD | [server] | description`

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
- No whitelist found for this IP

#### 20:34 CEST — profiles.yaml change attempt #1 (FAILED)
- **Goal:** Change ban from flat `4h` to escalating `duration_expr`
- **Error:** `duration_expr` placed **inside `decisions:` list** — wrong YAML level
- **CrowdSec error:** `field duration_expr not found in type models.Decision`
- **Result:** CrowdSec failed to start — service entered `activating (auto-restart)` loop
- **Repo commit:** `35e0483`

#### 20:36 CEST — profiles.yaml change attempt #2 (FAILED)
- Moved `duration_expr` to top-level of profile block (correct position)
- **New error:** `FATAL invalid hub index: unable to read index file: open /etc/crowdsec/hub/.index.json: no such file or directory`
- **Root cause:** Hub index file was missing — separate pre-existing issue, unrelated to profiles.yaml
- CrowdSec still down
- **Repo commit:** `8c677a9`

#### 20:39 CEST — Netdata optimization applied (independent, successful)
- While CrowdSec was being fixed, Netdata retention was reduced:
  - `history = 1800` (30 min)
  - `update every = 3`
  - `dbengine multihost disk space MB = 256`
- `systemctl restart netdata`
- **Result:** RAM improved: `used 3.8Gi → 3.1Gi / free 984Mi → 1.3Gi`

#### 20:43 CEST — Hub restore + profiles.yaml attempt #3 (FAILED)
- Ran `cscli hub update` — restored `.index.json` ✅
- **New error:** `FATAL crowdsec init: while loading scenarios: bad yaml in /etc/crowdsec/scenarios/custom-wp-login-hardban.yaml: field on_overflow not found in type leakybucket.BucketSpec`
- **Root cause:** Custom scenario `custom-wp-login-hardban.yaml` contained `on_overflow: requeue: "1h"` — this field **does not exist** in CrowdSec v1.7.7
- CrowdSec still down

#### 20:51 CEST — Root cause identified: invalid custom scenario
- File examined: `/etc/crowdsec/scenarios/custom-wp-login-hardban.yaml`
- **Problem field:**
  ```yaml
  on_overflow:
    requeue: "1h"
  ```
- `on_overflow` is **not a valid field** in `leakybucket.BucketSpec` in CrowdSec v1.7.7
- This was an **AI-generated error** when the scenario was originally created
- The `requeue` functionality is also unnecessary — ban duration escalation is already handled by `profiles.yaml`

#### 20:54 CEST — Fix applied: on_overflow removed (SUCCESS)
- Removed the entire `on_overflow:` block from `custom-wp-login-hardban.yaml`
- **Repo commit:** `0d058fc`
- Applied to server: `cp 222/custom-wp-login-hardban.yaml /etc/crowdsec/scenarios/custom-wp-login-hardban.yaml`
- `crowdsec -t -c /etc/crowdsec/config.yaml` → **✅ OK**
- `systemctl start crowdsec` → **✅ active (running)**
- Total downtime: **~18 minutes** (20:36–20:54 CEST)

---

### 🚨 Root causes summary

| # | Error | Cause | Fix |
|---|---|---|---|
| 1 | `duration_expr not found in type models.Decision` | `duration_expr` placed inside `decisions:` list | Move to top-level of profile block |
| 2 | `hub/.index.json: no such file or directory` | Hub index missing (pre-existing, triggered by restart attempt) | `cscli hub update` |
| 3 | `on_overflow not found in type leakybucket.BucketSpec` | Invalid field in custom scenario — AI error during original creation | Remove `on_overflow:` block entirely |

---

### 📚 Lessons learned

1. **`duration_expr` placement:** Must be a **top-level field** in the profile block, NOT nested under `decisions:`
   ```yaml
   # WRONG:
   decisions:
     - type: ban
       duration: 24h
       duration_expr: ...   # ❌ FAILS

   # CORRECT:
   decisions:
     - type: ban
       duration: 24h
   duration_expr: ...       # ✅ top-level
   ```

2. **Always run `cscli hub update` before restarting CrowdSec** if hub-related warnings appeared recently

3. **`on_overflow` does not exist in CrowdSec v1.7.7** — valid leaky bucket fields are:
   `type, name, description, filter, groupby, distinct, capacity, leakspeed, blackhole, labels, overflow_filter`
   Ban duration is controlled by `profiles.yaml` — not by the scenario itself

4. **Test config before applying:** Always run `crowdsec -t -c /etc/crowdsec/config.yaml` before `systemctl start crowdsec`

5. **Custom scenario files must be saved to repo** — `custom-wp-login-hardban.yaml` existed only on server, not in repo. This caused confusion during debugging.

---

### ✅ Final state (20:54 CEST)

| Metric | Before session | After session |
|---|---|---|
| CrowdSec status | active | active ✅ |
| Ban policy | flat 4h | escalating: 24h → 48h → 72h... |
| RAM used | 3.8GB | 3.1GB |
| Swap used | 1.2GB | 1.0GB |
| Netdata retention | 1h / 1s updates | 30min / 3s updates |
| custom-wp-login-hardban.yaml | only on server | saved to repo ✅ |

---

## 2026-04-12 (evening) | 222 | CrowdSec ban escalation + Netdata RAM tuning

### Context
Evening SOS report (20:15 CEST) showed:
- Active WP-login brute-force: `103.186.31.44` (ID/Indonesia) — 2226 hits in 3h on `timan-kuchyne.cz`
- CrowdSec ban duration was flat **4h** → attacker returns after every ban expires
- Netdata using 195MB RAM, no retention limit configured
- Swap usage: 1.2GB — server under memory pressure
- RAM: 3.8GB used / 984MB free

### Investigation — 103.186.31.44
- IP was **already correctly banned** by CrowdSec at 12:46 UTC (168h ban)
- SOS report showed it in TOP-IPs because log aggregation covered period BEFORE the ban
- CrowdSec was working correctly — no manual action needed
- Root cause of seeing it in SOS: `czechtoday.eu`/`timan-kuchyne.cz` not behind Cloudflare proxy (grey cloud) — real IPs visible in logs

### Changes made

#### 🛡️ CrowdSec — escalating ban duration
- **File:** `222/profiles.yaml` (→ `/etc/crowdsec/profiles.yaml`)
- **Change:** flat `duration: 4h` → escalating `duration_expr`
- **Logic:** `Sprintf('%dh', (GetDecisionsCount(Alert.GetValue()) + 1) * 24)`
  - 1st offence → **24h**
  - 2nd offence → **48h**
  - 3rd offence → **72h** (and so on)
- **Why:** 4h ban is too short — persistent attackers return immediately after expiry

#### 📊 Netdata — minimal RAM retention
- **File:** `/etc/netdata/netdata.conf`
- **Changes:** `history = 1800`, `update every = 3`, `dbengine multihost disk space MB = 256`
- **Result:** RAM freed ~700MB after Netdata restart

---

## 2026-04-12 | 222 | CrowdSec hub full restore — parsers + collections

### Context
After `cscli hub update`, all hub-managed parsers and scenarios showed `WARNING: no such file or directory` in `/etc/crowdsec/hub/`. Only 2 local parsers (whitelists) were active. Root cause: hub directory was empty/corrupted — `.index.json` downloaded but actual YAML files missing.

### Fix applied
1. Stopped CrowdSec: `systemctl stop crowdsec`
2. Cleared broken hub cache: `rm -rf /etc/crowdsec/hub/ && mkdir -p /etc/crowdsec/hub/`
3. Re-downloaded index: `cscli hub update`
4. Reinstalled all collections: `linux`, `nginx`, `sshd`, `wordpress`, `base-http-scenarios`, `http-cve`, `whitelist-good-actors`, `mysql`, `mariadb`
5. Started CrowdSec: `systemctl start crowdsec`

### Result
- All parsers active, 31 CVE scenarios active, 48 bans within minutes ✅
- `crowdsec` → `active` ✅

### ⛔ IMPORTANT — SSH port decision
**SSH port 22 must NOT be changed.**
Port 22 stays as-is. CrowdSec handles SSH brute-force protection.

### Script
`222/fix_crowdsec_hub_v2026-04-12.sh`

---

## 2026-04-12 | 222 | PHP memory + OPcache tuning + server config philosophy

### Context
Morning SOS: Load 1.38, RAM 301MB free, Swap 1.3GB, `svetaform.eu` OOM on `/wp-json/oembed/`.

### Changes
- `memory_limit`: 128M → 256M (global `php.ini`)
- OPcache: full config — 256MB, 20000 files, revalidate 60s
- README: Server Configuration Philosophy section added

### Result
- Load: 1.38 → 0.41, RAM free: 301MB → 1.1GB, OOM errors stopped ✅

---

## 2026-04-12 | 109 | wp_update_all.sh language support

- Added WordPress language file updates to `wp_update_all.sh` — `v2026-04-12`

---

## 2026-04-10 | VPN + ALL | Full documentation pass + backup system launch

- SSH keys for VPN nodes configured
- VPN Docker backup to AWS S3 — cron 03:30 daily, KEEP=7
- `VPN/BACKUP.md`, `VPN/README.md`, root `README.md` updated

---

## 2026-04-08 | 222 + 109 | PHP-FPM per-site limits system

- `set_php_fpm_limits_v2026-04-07.sh`: `CPUQuota=320%`, `MemoryMax=6.8G`, `pm.max_children=8`, `pm.max_requests=500`

---

## 2026-04-07 | 222 | PHP-FPM watchdog + Telegram alerts

- `php_fpm_watchdog.sh`: auto-restart pool if CPU > 90% for 15min, Telegram alert
- Cron: `*/5 * * * *`

---

## 2026-04-05 | 222 | CrowdSec + Nginx bouncer fix

- Fixed CrowdSec engine INACTIVE, rebuilt hub, verified Nginx bouncer ✅

---

## 2026-03-16 | ALL | Initial public repository setup

- Created `Linux_Server_Public`, folder structure, coding standards, `save` alias

---

*= Rooted by VladiMIR | AI =*
