# WORKLOG — Linux Server Infrastructure
> Rooted by VladiMIR + AI | github.com/GinCz/Linux_Server_Public

---

## Session 2026-07-08 — Flatsome license patch + WC autoload cleanup (server 222)

### Context
On server **152.53.182.222 (DE-NetCup)** all sites running the Flatsome theme were periodically pinging `api.uxthemes.com` and `wupdates.com` for license verification. The goal — fully disable the license check inside the theme on all 43 sites. Additionally, WC autoload garbage was found and cleaned on doska-* sites.

---

### Incident — mu-plugin caused mass HTTP 500 on all sites

#### What happened
First attempt — installing mu-plugin `disable-wc-stubs.php` via bash script with `while read` (hung due to stdin capture). After fixing to `for` loop — script ran, but mu-plugin caused **HTTP 500 on all 43 sites**.

**Cause:** mu-plugin loads **before** themes and plugins. The `class WooCommerce {}` stub conflicted with the real WooCommerce class on sites where WC is installed. On doska-* sites mu-plugin failed with ~10 minute delay for the same reason.

**Affected sites (first wave 20:37):**
- car-bus-autoservice.cz, hulk-jobs.cz, kk-med.eu, car-bus-service.cz, detailing-alex.eu

**Affected sites (second wave 20:47 — all doska-*):**
- doska-it.ru, doska-cz.ru, doska-de.ru, doska-fr.ru, doska-esp.ru, doska-hun.ru, doska-ua.ru, doska-gr.ru, doska-isl.ru, doska-pl.ru, doska-mld.ru

#### Recovery
```bash
# Remove mu-plugin from all sites
find /var/www -name "disable-wc-stubs.php" -path "*/mu-plugins/*" -delete
```
All sites came back immediately without PHP-FPM restart.

#### Lesson
**mu-plugin is the wrong place to patch the theme license.** The correct approach — patch the file inside the theme itself.

---

### Correct solution — patch class inside the theme

#### Target file
```
flatsome/inc/classes/class-flatsome-wupdates-registration.php
```

This file contains `Flatsome_WUpdates_Registration` class — it makes all HTTP requests to `api.uxthemes.com`, checks the license, and hooks the cron `flatsome_scheduled_registration`.

#### Stub (saved in theme archive)
Class replaced with a stub of the same signature:
- `is_registered()` → always `true`
- `is_verified()` → always `true`
- `get_code()` → returns fake UUID `00000000-0000-0000-0000-000000000000`
- `register()` → returns `['status' => 'ok']` without HTTP request
- `get_latest_version()` → `false` (auto-updates disabled)
- `migrate_registration()` → empty function
- `__construct()` → does not hook cron

#### Deploy to server 222
```bash
# Script wrote the stub to /tmp/patch.php and copied to all sites
find /var/www -name "class-flatsome-wupdates-registration.php" -path "*/themes/flatsome/*"
# cp /tmp/patch.php "$f" for each found file
```

**Result:** 43 sites patched successfully.

| Domain | User | WC |
|---|---|---|
| alejandrofashion.cz | alejandrofashion | ❌ |
| detailing-alex.eu | alex_detailing | ❌ |
| autoservis-rychlik.cz | andrey-autoservis | ❌ |
| car-bus-autoservice.cz | andrey-autoservis | ❌ |
| autoservis-praha.eu | arslan | ❌ |
| praha-autoservis.eu | bayerhoff | ❌ |
| diamond-odtah.cz | diamond-drivers | ❌ |
| czechtoday.eu | dmitry-vary | ❌ |
| doska-cz.ru … doska-ua.ru (11 sites) | doski | ❌ |
| gadanie-tel.eu | gadanie-tel | ✅ |
| lybawa.com | gadanie-tel | ✅ |
| eco-seo.cz | gincz | ❌ |
| ekaterinburg-sro.eu | gincz | ❌ |
| ru-tv.eu | gincz | ✅ |
| hulk-jobs.cz | hulk | ❌ |
| abl-metal.com | igor_kap | ❌ |
| megan-consult.cz | igor_kap | ❌ |
| kk-med.eu | karina | ❌ |
| timan-kuchyne.cz | nata_popkova | ✅ |
| kadernik-olga.eu | olga_pisareva | ❌ |
| east-vector.cz | serg_et | ❌ |
| eurasia-translog.cz | serg_et | ❌ |
| rail-east.uk | serg_et | ❌ |
| car-chip.eu | serg_pimonov | ❌ |
| vymena-motoroveho-oleje.cz | serg_pimonov | ❌ |
| stopservis-vestec.cz | serg_reno | ❌ |
| svetaform.eu | spa | ✅ |
| balance-b2b.eu | sveta_tuk | ❌ |
| bio-zahrada.eu | tan-adrian | ✅ |
| stm-services-group.cz | tatiana_podzolkova | ❌ |
| tstwist.cz | tstwist | ❌ |
| kadernictvi-salon.eu | viktoria | ❌ |
| wowflow.cz | wowflow | ✅ |

---

### WC autoload garbage on doska-* sites

#### Problem
All 11 doska-*.ru sites had WC options with `autoload=yes` in the DB even though WooCommerce is not installed. This meant WC-related code was loaded on every WordPress request for nothing.

**Culprit:** plugin `miniorange-login-openid` v7.8.0 — created options:
- `mo_openid_woocommerce_before_login_form` — autoload=yes
- `mo_openid_woocommerce_center_login_form` — autoload=yes

Additionally found garbage options from old WooCommerce installation:
- `wc_plugin_version` — autoload=yes
- `wc_options` — autoload=yes

#### Fix
```bash
# Switch all WC autoload options to autoload=no on all doska-*
for site in /var/www/doski/data/www/doska-*.ru; do
    wp --path="$site" db query \
      "UPDATE wp_options SET autoload='no'
       WHERE (option_name LIKE 'wc_%' OR option_name LIKE '%woocommerce%' OR option_name LIKE '%mo_openid_woo%')
       AND autoload='yes';" --allow-root
done

# Flush object cache
for site in /var/www/doski/data/www/doska-*.ru; do
    wp --path="$site" cache flush --allow-root
done
```

**Result:** All 11 doska-* sites have no WC autoload options with `yes` left. Object cache flushed.

#### Check on remaining sites without WC
All 25 sites without WooCommerce (non doska-*) checked — no WC autoload garbage found on any of them.

**Conclusion:** Flatsome theme correctly uses `is_woocommerce_activated()` (checks `class_exists('woocommerce')`) — all WC-related code in the theme is automatically skipped if WC is not installed. No additional patches needed to disable WC functions in the theme.

---

### Final state of server 222 after session

| Task | Status |
|---|---|
| Flatsome license blocked — 43 sites | ✅ |
| mu-plugins disable-wc-stubs.php removed (except doska-*) | ✅ |
| WC autoload garbage cleaned on doska-* (11 sites) | ✅ |
| Object cache flushed on doska-* | ✅ |
| All sites alive after all changes | ✅ |

### TODO
- [ ] Update archive `flatsome-3.18.1__Lic_VladiMIR.zip` on Windows — replace `class-flatsome-wupdates-registration.php` with the stub (so new installs are ready without license from the start)
- [ ] Remove mu-plugins from doska-* after reinstalling theme from updated archive
- [ ] Check miniorange-login-openid on other servers (109) — may have the same WC autoload options issue

---

## Session 2026-06-25 — x-ui 3.4.0 bug: Reality config.json missing settings block (server 47)

### Context
Users of server **109.234.38.47 (VPN ALEX_47)** stopped connecting via old VLESS Reality links on port 443. Port 8443 (test inbound) was manually removed via x-ui panel during the session.

---

### Symptoms
- Timeout on client connection (v2rayN, NekoBox)
- All users showed "offline" in x-ui panel
- `ss -tlnp` showed Xray **listening** on port 443 — service is alive
- `tcpdump` showed TCP SYN from client **arrives** and server responds SYN-ACK
- Xray log (`journalctl -u x-ui`) — **empty**, not a single line about client connection
- `openssl s_client -connect 109.234.38.47:443 -servername www.github.com` → `CONNECTED`, `CN = github.com` — TLS response exists

---

### Diagnostics — what was checked

#### 1. config.json vs x-ui.db
```python
# x-ui.db (SQLite) — data is CORRECT:
port=443  publicKey=eW3mJ2CRGSp3_nQ_RijPnMTfMTWgq_IUY4YnJ70yMXw  fingerprint=chrome

# /usr/local/x-ui/bin/config.json — settings block MISSING:
"realitySettings": {
    "privateKey": "OMY7kYfTJ4I_SJFsD9K3iC17_ccUaILN1IlMlhha4lo",
    "serverNames": ["www.github.com"],
    "shortIds": ["02"],
    ...
    # MISSING block "settings": { "publicKey": ..., "fingerprint": ... }
}
```

**Conclusion:** x-ui version **26.6.22 (Xray 26.6.22 / x-ui 3.4.0)** when writing config.json **intentionally omits** the `settings` block inside `realitySettings`. By the new logic x-ui should generate `publicKey` from `privateKey` in memory at startup. But in practice this does not happen — Xray starts **without publicKey**, and Reality handshake is impossible.

#### 2. Firewall — not guilty
```
iptables INPUT policy DROP
Rule 2: ACCEPT tcp dpt:8443
Rule 5: ACCEPT tcp dpt:443  ← exists, packets pass
```
CrowdSec — no bans for client IPs. ufw — 443/tcp ALLOW.

#### 3. Xray log
```
journalctl -u x-ui:
  INFO  - XRAY: infra/conf/serial: Reading config: bin/config.json
  WARNING - XRAY: core: Xray 26.6.22 started
  INFO  - xray core supports the online-stats API
```
After startup — **complete silence** even on client connection attempts. Xray accepts TCP connection (SYN-ACK) but rejects Reality handshake at TLS level before logging anything.

#### 4. Xray working path
```
/proc/<pid>/cwd → /usr/local/x-ui
cmdline: bin/xray-linux-amd64 -c bin/config.json
```
Correct file, reads properly.

#### 5. tcpdump — client IP
Client connects from **95.139.45.86** (VladiMIR mobile/home IP).
```
95.139.45.86 → 109.234.38.47:443  [SYN]     ✅ arrives
109.234.38.47 → 95.139.45.86      [SYN-ACK] ✅ server responds
95.139.45.86 → 109.234.38.47      [ACK]     ✅ TCP established
109.234.38.47 → 95.139.45.86      [FIN]     ❌ server immediately closes
```
Reality handshake rejected immediately — publicKey not set, verification impossible.

---

### Fix attempts

#### Attempt 1 — patch x-ui.db
Inserted `publicKey` and `fingerprint` directly into SQLite DB via python3:
```python
conn.execute('UPDATE inbounds SET stream_settings=? WHERE id=?', (json.dumps(ss), ib_id))
```
**Result:** DB updated, but after `systemctl restart x-ui` — config.json is regenerated **without** the settings block. x-ui 3.4.0 fundamentally does not write it.

#### Attempt 2 — direct patch of config.json
```python
rl['settings'] = {
    "publicKey":    "eW3mJ2CRGSp3_nQ_RijPnMTfMTWgq_IUY4YnJ70yMXw",
    "fingerprint":  "chrome",
    "serverName":   "",
    "spiderX":      "/",
    "mldsa65Verify": ""
}
```
File saved, verification showed `[OK]`. Xray killed and restarted via `kill`.
**Result:** x-ui after a few minutes/restarts **overwrites** config.json again without the settings block. Patch does not stick.

#### Attempt 3 — restart only Xray without x-ui
`kill $(pgrep -f xray-linux-amd64)` — x-ui automatically brings Xray back up, but reads config.json from its template (again without settings).

---

### Current state of server 47 (at session end)
- Xray running, port 443 listening
- 54 active ESTAB connections — **old users holding sessions**
- New connections — **not working** (Reality handshake fails)
- Port 8443 (test inbound) — **removed** via x-ui panel
- Backups: `/etc/x-ui/x-ui.db.bak2`, `/usr/local/x-ui/bin/config.json.bak_final`

### Inbound 443 parameters (for recovery)
```
privateKey : OMY7kYfTJ4I_SJFsD9K3iC17_ccUaILN1IlMlhha4lo
publicKey  : eW3mJ2CRGSp3_nQ_RijPnMTfMTWgq_IUY4YnJ70yMXw
fingerprint: chrome
shortIds   : ["02"]
serverNames: ["www.github.com"]
target     : www.github.com:443
spiderX    : /
```

### Correct client link (VladiMIR)
```
vless://fe07c169-8304-4007-a2f3-b828943efc88@109.234.38.47:443?encryption=none&fp=chrome&pbk=eW3mJ2CRGSp3_nQ_RijPnMTfMTWgq_IUY4YnJ70yMXw&security=reality&sid=02&sni=www.github.com&spx=%2F&type=tcp#VladiMIR
```

---

### Root cause
**x-ui 3.4.0 (Xray 26.6.22)** — critical bug: when generating `config.json` from DB, does not write the `realitySettings.settings` block containing `publicKey` and `fingerprint`. By design these parameters should be computed from `privateKey` at startup, but the implementation is broken — Xray starts without them and cannot authenticate clients.

**Version where it broke:** presumably when updating x-ui to version 3.4.0. Everything worked before the update.

---

### Useful commands for Reality diagnostics (found during session)

#### Check what is actually in config.json vs DB
```bash
# DB (source of truth):
python3 -c "
import sqlite3, json, tempfile, os
data = open('/etc/x-ui/x-ui.db','rb').read()
t = tempfile.NamedTemporaryFile(delete=False, suffix='.db')
t.write(data); t.close()
conn = sqlite3.connect(t.name)
for r in conn.execute('SELECT port, stream_settings FROM inbounds WHERE protocol=\"vless\"').fetchall():
    ss = json.loads(r[1]) if r[1] else {}
    rl = ss.get('realitySettings', {})
    sett = rl.get('settings', {})
    print(f'port={r[0]}  publicKey={sett.get(\"publicKey\",\"MISSING\")}  fp={sett.get(\"fingerprint\",\"MISSING\")}')
os.unlink(t.name)
"

# config.json (what Xray actually reads):
python3 -c "
import json
with open('/usr/local/x-ui/bin/config.json') as f:
    cfg = json.load(f)
for ib in cfg.get('inbounds',[]):
    if ib.get('protocol')=='vless':
        ss=ib.get('streamSettings',{})
        rl=ss.get('realitySettings',{})
        sett=rl.get('settings',{})
        print(f'port={ib[\"port\"]}  publicKey={sett.get(\"publicKey\",\"MISSING\")}  fp={sett.get(\"fingerprint\",\"MISSING\")}')
"
```

#### Capture Reality handshake moment via tcpdump
```bash
# Watch all incoming connections from specific client:
tcpdump -i ens3 -n "host <CLIENT_IP> and port 443"

# SYN-only for fast new connection diagnostics:
tcpdump -i ens3 -n "port 443 and tcp[tcpflags] & tcp-syn != 0"

# Sign of Reality problem: SYN → SYN-ACK → ACK → FIN (server closes without data)
# Sign of normal operation: SYN → SYN-ACK → ACK → DATA → DATA (tunnel open)
```

#### Check Xray log (writes via journald, not to file)
```bash
journalctl -u x-ui --no-pager --since '5 minutes ago'
# Enable debug:
# In config.json: "log": {"loglevel": "debug"}
# then kill $(pgrep -f xray-linux-amd64) — x-ui will auto-restart with new config
```

#### Diagnose from server 222 to all VPN servers
```bash
# Check publicKey on all servers at once:
PASS="OKMokm-09"
for HOST in 109.234.38.47 144.124.228.237 144.124.232.9 144.124.239.24 146.103.110.176 144.124.233.38 82.223.116.38; do
  echo -n "$HOST: "
  sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$HOST \
    'python3 -c "
import json
with open("/usr/local/x-ui/bin/config.json") as f: cfg=json.load(f)
for ib in cfg.get("inbounds",[]):
    if ib.get("protocol")=="vless":
        ss=ib.get("streamSettings",{})
        rl=ss.get("realitySettings",{})
        pk=rl.get("settings",{}).get("publicKey","MISSING")
        print(f"port={ib[chr(39)]}  pk={pk[:20] if pk!= chr(77)+chr(73)+chr(83)+chr(83)+chr(73)+chr(78)+chr(71) else chr(77)+chr(73)+chr(83)+chr(83)+chr(73)+chr(78)+chr(71)}")
"' 2>&1
done
```

---

### TODO — to be done next session

- [ ] **MAIN:** Find solution for x-ui 3.4.0 — how to make it write `settings` block to config.json. Options:
  - Roll back x-ui to the last version where the bug was not present (need to find it)
  - Write a systemd hook/ExecStartPre that patches config.json **after** x-ui generates it but **before** Xray starts
  - Use `inotifywait` to watch config.json changes and auto-patch
  - Replace x-ui with 3x-ui or another fork without this bug
- [ ] Check the same issue on **other VPN servers** (237, 9, 24, 176, 38, IONOS) — they may have the same x-ui version and same bug, old sessions just still holding
- [ ] After fix — send updated links to server 47 users (spx changed from `/e8R1jEWH8Z7CaRR` to `/`)
- [ ] Delete test backups: `/etc/x-ui/x-ui.db.bak2`, `config.json.bak_final`, `config.json.bak_debug`

---

## Session 2026-06-15 — night_update.sh full refactor + deploy to 10 servers

### Context
Checking the state of all 10 infrastructure servers revealed a serious conflict: on most servers two independent update mechanisms were running in parallel — the old cron with a hard `apt + /sbin/reboot` every night, and the new `night_update.sh` via systemd timer. This led to double updates, unpredictable reboots, and empty logs.

### Infrastructure (10 servers)

| IP | Name | Type | Provider |
|---|---|---|---|
| 152.53.182.222 | 222-DE-NetCup | Web sites (DE) | NetCup |
| 212.109.223.109 | 109-RU | Web sites (RU) | VDS |
| 109.234.38.47 | VPN-1 | VPN | NetCup |
| 144.124.228.237 | VPN-2 | VPN | NetCup |
| 144.124.232.9 | VPN-3 | VPN | NetCup |
| 144.124.228.227 | VPN-4 | VPN | NetCup |
| 144.124.239.24 | VPN-5 | VPN | NetCup |
| 146.103.110.176 | VPN-6 | VPN | NetCup |
| 144.124.233.38 | VPN-7 | VPN | NetCup |
| 3.79.14.42 | VPN-Amazon | VPN | Amazon AWS |
| 82.223.116.38 | VPN-IONOS | VPN | IONOS |

---

### Problems found

#### 1. Double updater — cron + systemd timer conflict
**Symptom:** Every night on most servers two updates ran:
- Old cron (`0 2 * * *` or `0 3 * * *`): dumb apt-get + immediate `/sbin/reboot`
- Systemd `night-update.timer`: ran smart `night_update.sh` at 03:30

**Consequences:**
- Server rebooted at 02:00 from cron, then at 03:30 timer ran second apt upgrade already after reboot
- Log `/var/log/night_update.log` was empty — cron wrote to `/var/log/auto-upgrade.log`
- On servers 222 and 109 (with sites!) there was automatic daily reboot at 02:00 — this disrupted site operation

#### 2. Garbage Telegram alerts from --audit
**Symptom:** After each reboot, Telegram notifications about "problems" with services arrived:
```
❌ Failed units: certbot.service exim4-base.service fwupd-refresh.service logrotate.service motd-news.service openipmi.service
```
**Cause:** Script `--audit` checked all failed services without filtering. Listed services are system noise, they periodically fail with exit-code on scheduled runs and that is completely normal:
- `certbot` — returns non-zero exit if no certs to renew
- `exim4-base` — housekeeping task
- `fwupd-refresh` — firmware metadata update (VPS has no firmware)
- `motd-news` — loading daily news
- `logrotate` — log rotation (sometimes fails on empty logs)
- `openipmi` — IPMI driver that **will never exist** on VPS/virtual machines

#### 3. Different variants of old cron
Servers had different versions of the old update-cron:
- Variant A: `0 2 * * *` with `--force-confold`
- Variant B: `0 3 * * *` with `DEBIAN_FRONTEND=noninteractive` but without `--force-confdef`
- Variant C (servers .237, .227, Amazon): wrong flag order — redirect `>>` placed before some commands, causing part of errors not to be logged

#### 4. server_monitor.sh was checking non-existent php8.1-fpm
**Symptom:** On server 222 `server_monitor.sh` was monitoring `php8.1-fpm` which does not exist (8.3 and 8.4 are present). Every N minutes the script could send false alerts.

---

> _= Rooted by VladiMIR + AI | v.2026.07.11 | github.com/GinCz =_
