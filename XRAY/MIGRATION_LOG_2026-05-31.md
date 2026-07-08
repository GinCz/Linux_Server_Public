# Xray VPN Migration Log — 2026-05-31
# = Rooted by VladiMIR + AI | v.2026.05.31 | github.com/GinCz =

Complete documentation of the migration from **alireza0/x-ui** to **MHSanaei/3x-ui**
across all VPN servers on 2026-05-31. Includes all problems encountered, root causes,
and fixes applied.

---

## Background

All VPN servers were running **alireza0/x-ui** (old unmaintained fork of x-ui).
The repository `https://github.com/alireza0/x-ui` returned **404 (deleted)**,
making updates and new installs impossible.

Decision: migrate all servers to **MHSanaei/3x-ui** — the actively maintained fork,
now at v3.2.0 with significant UI and feature changes.

---

## Servers Migrated

| Server | IP | Old version | New version | Status |
|--------|----|-------------|-------------|--------|
| EU-ILYA-176 | 146.103.110.176 | — (new server) | 3x-ui v1.10.2 / Xray 26.5.9 | ✅ |
| EU-4TON-237 | 144.124.228.237 | alireza0/x-ui | 3x-ui v1.10.2 / Xray 26.5.9 | ✅ |
| RU-SO-109 | 212.109.223.109 | alireza0/x-ui | 3x-ui v3.2.0 / Xray 26.5.9 | ✅ |
| EU-SO-38 | 144.124.233.38 | alireza0/x-ui | 3x-ui v3.2.0 / Xray 26.5.9 | ✅ |
| EU-ALEX-47 | 109.234.38.47 | alireza0/x-ui | 3x-ui v3.2.0 | 🔄 |
| EU-TATRA-9 | 144.124.232.9 | alireza0/x-ui | 3x-ui v3.2.0 | 🔄 |
| EU-SHAHIN-227 | 144.124.228.227 | alireza0/x-ui | 3x-ui v3.2.0 | 🔄 |
| EU-STOLB-24 | 144.124.239.24 | alireza0/x-ui | 3x-ui v3.2.0 | 🔄 |
| EU-PILIK-178 | 195.63.138.33 | alireza0/x-ui | 3x-ui v3.2.0 | 🔄 |

---

## Migration Procedure

### Step 1: Backup existing database

The x-ui database contains all inbounds and clients.
Always backup before touching anything:

```bash
mkdir -p /root/backup_xui
cp /etc/x-ui/x-ui.db /root/backup_xui/x-ui.db.$(date +%Y%m%d_%H%M%S)
```

Good news: **3x-ui installer automatically migrates the existing database**
(`Migration done!` message appears during install). Old inbounds and clients
are preserved — users stay connected without reconfiguration.

### Step 2: Set hostname (important for panel visibility)

The server name shown in the 3x-ui panel Overview comes from the system hostname.
Set it before installing so it appears correctly from the start:

```bash
hostnamectl set-hostname EU-ILYA-176
echo "EU-ILYA-176" > /etc/hostname
```

Hostname naming convention:
```
222-EU-NetCup     (152.53.182.222)
RU-SO-109         (212.109.223.109)
EU-ALEX-47        (109.234.38.47)
EU-4TON-237       (144.124.228.237)
EU-TATRA-9        (144.124.232.9)
EU-SHAHIN-227     (144.124.228.227)
EU-STOLB-24       (144.124.239.24)
EU-PILIK-178      (195.63.138.33)
EU-ILYA-176       (146.103.110.176)
EU-SO-38          (144.124.233.38)
```

### Step 3: Stop old x-ui and install 3x-ui

```bash
# Stop and remove old service (not the database)
systemctl stop x-ui 2>/dev/null
systemctl disable x-ui 2>/dev/null
rm -f /usr/local/x-ui/x-ui
rm -f /etc/systemd/system/x-ui.service
systemctl daemon-reload

# Install 3x-ui
bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh)
```

During install prompts:
- **SSL setup**: choose **4 (Skip SSL)** — panel is behind UFW/SSH, no public domain
- **Bind to 127.0.0.1?**: choose **N** — needs to be reachable from admin IPs
- **Port / Username / Password**: set or keep existing

### Step 4: Open UFW ports

**CRITICAL — installer does NOT open ports automatically!**
Without this step, clients cannot connect even though Xray is running.

```bash
ufw allow 443/tcp
ufw allow 443/udp
ufw allow 8443/tcp
ufw allow <panel_port>/tcp
ufw reload
```

Verify:
```bash
ufw status | grep -E "443|8443"
ss -tlnp | grep 443
```

### Step 5: Upgrade Xray to v26.5.9

In panel: **Overview → click Xray version badge → select v26.5.9**

Do not use the latest untested version. v26.5.9 is confirmed working.

---

## Problems Encountered & Fixes

---

### PROBLEM 1: alireza0/x-ui repository deleted (404)

**Symptom:** Cannot install or update x-ui. GitHub returns 404.

**Root cause:** The `alireza0/x-ui` repository was deleted by its author.

**Fix:** Migrate to `MHSanaei/3x-ui` — the actively maintained fork:
```bash
bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh)
```

---

### PROBLEM 2: x-ui.service could not be found

**Symptom:**
```
Unit x-ui.service could not be found.
```

**Root cause:** Old alireza0/x-ui was either never installed as a service,
or was installed with a different service name on this particular server.

**Fix:** Not an error — just means old service was not running.
Proceed with 3x-ui install normally.

---

### PROBLEM 3: Client Timeout — Target ≠ SNI mismatch

**Symptom:** Hiddify shows "Connection Timeout" immediately after connecting.

**Root cause:** In the Inbound Security settings, **Target (Dest)** was set to
`www.nvidia.com:443` but **SNI** was `www.github.com`. These MUST match.

**Reality protocol requirement:** Target and SNI must point to the same domain.
Xray uses the target domain to forward handshake traffic, and SNI to identify
which certificate to present. If they differ, the handshake fails.

**Fix:**
- Security → Reality → **Target**: change to `www.github.com:443`
- **SNI**: `www.github.com`
- Both must be identical.

**Working vless link example:**
```
vless://UUID@IP:443?type=tcp&encryption=none&security=reality
  &pbk=PUBLIC_KEY&fp=chrome&sni=www.github.com&sid=02&spx=%2F
  #ServerName-UserName
```

---

### PROBLEM 4: Client Timeout — UFW blocking port 443

**Symptom:** Xray is running, port 443 is listening (`ss -tlnp | grep 443` shows it),
but clients still get timeout. `ufw status` shows 443 is NOT in the rules.

**Root cause:** The 3x-ui installer does NOT add UFW rules automatically.
Xray listens on the port, but the firewall silently drops all incoming packets.

**Diagnosis:**
```bash
ufw status | grep 443
# If nothing shown — port is BLOCKED
```

**Fix:**
```bash
ufw allow 443/tcp
ufw allow 443/udp
ufw allow 8443/tcp
ufw reload
```

**This is the most common "silent" failure after fresh 3x-ui install.**
Always verify UFW after installation.

---

### PROBLEM 5: SpiderX random path in vless:// link

**Symptom:** New client vless link contains `spx=%2FrandomString` instead of `spx=%2F`.
Client connects but gets timeout.

**Root cause:** New 3x-ui versions auto-generate a random SpiderX path when
creating an inbound. The SpiderX path must match between server and client.

**Comparison:**
```
# Old (working):  spx=%2F           → SpiderX = /
# New (broken):   spx=%2FmegmnXq3   → SpiderX = /megmnXq3 (random)
```

**Fix:** In panel Security tab → **SpiderX** field → manually set to `/`
Then save and rescan QR code.

**Prevention:** Always check SpiderX = `/` when creating new inbound.

---

### PROBLEM 6: Hiddify shows 404 when adding profile via QR code

**Symptom:**
```
Не удалось добавить профиль
status code 404
```

**Root cause:** The QR code contained a **Subscription URL** (`http://ip:port/sub/...`)
instead of a direct `vless://` link. Hiddify tried to fetch the subscription
from the server, but the endpoint returned 404 (subscription service not configured
or wrong path).

**Fix:** Do not scan the subscription QR code. Instead:
1. In Inbounds list → click the three-dot menu (⋮) next to the client
2. Choose **"Copy Config"** or **"Show Config"**
3. Copy the `vless://` link directly
4. In Hiddify → add manually by pasting the vless:// link

OR: Use the individual client QR (not the inbound subscription QR).

---

### PROBLEM 7: Profile name in Hiddify changed vs old x-ui

**Old behavior (alireza0/x-ui):**
Profile in Hiddify showed: `VladiMIR_Honor @ EU-4TON-237`
(email + remark = username + server)

**New behavior (3x-ui v1.10.2+):**
Profile shows only: `EU-4TON-237`
(only the Inbound Remark is used as profile name)

**Root cause:** Change in how vless:// link is constructed.
The `#` fragment (profile name) now uses only the Inbound remark,
not `email@remark`.

**Workaround:** Include username in the Inbound Remark:
```
Remark: EU-ILYA-176 | VladiMIR
```
Or accept the new behavior — server name is enough to identify the connection.

---

### PROBLEM 8: New 3x-ui UI — renamed fields confuse setup

**Changes in 3x-ui v1.10.2+ vs old x-ui:**

| Old x-ui field | New 3x-ui field | Notes |
|----------------|-----------------|-------|
| TCP | RAW | Same protocol, renamed |
| Dest | Target | Same field, renamed |
| ShortID (manual `02`) | Short IDs (auto-generated) | Leave auto-generated value |
| — | Vision testseed (900,500,900,256) | New field, leave default |
| — | mldsa65 Seed / Verify | New fields, leave empty |
| UDP Masks not shown | UDP Masks field visible | Leave empty |

---

### PROBLEM 9: Panel shows wrong server name (v622618...)

**Symptom:** Panel Overview shows generic VDS hostname like `v622618.hosted-by-vdsina.com`
instead of a meaningful name like `EU-ILYA-176`.

**Root cause:** Hostname was not set after OS install.

**Fix:**
```bash
hostnamectl set-hostname EU-ILYA-176
echo "EU-ILYA-176" > /etc/hostname
systemctl restart x-ui
```

After restart, panel Overview → Server shows the correct name.

---

## Post-Install Checklist

Run after every fresh 3x-ui installation:

```bash
# 1. Verify hostname
hostname

# 2. Verify time sync
timedatectl | grep -E "Time zone|synchronized"

# 3. Verify x-ui running
systemctl status x-ui --no-pager | grep Active

# 4. Verify Xray running and listening
ss -tlnp | grep 443

# 5. Verify UFW allows 443
ufw status | grep 443

# 6. Check Xray logs for errors
journalctl -u x-ui -n 20 --no-pager | grep -iE "error|fail"
```

Full post-install setup:
```bash
# Open all required ports
ufw allow 443/tcp
ufw allow 443/udp
ufw allow 8443/tcp
ufw allow <panel_port>/tcp
ufw reload

# Upgrade Xray: panel → Overview → click version → v26.5.9
```

---

## Working vless:// Link Structure

Reference link that is confirmed working (from server EU-4TON-237):
```
vless://22540983-9df4-4336-958c-1a8b72203daa@144.124.228.237:443
  ?type=tcp
  &encryption=none
  &security=reality
  &pbk=Ix7LYuCk5TPpOXCgRkrba6lbO1YweoImlsEVfFmll04
  &fp=chrome
  &sni=www.github.com
  &sid=02
  &spx=%2F
  #EU_4Ton-237-VladiMIR_Honor
```

Key parameters:
- `type=tcp` — RAW/TCP transport
- `security=reality` — Reality protocol
- `pbk` — server Public Key (from panel)
- `fp=chrome` — fingerprint
- `sni=www.github.com` — must match Target
- `sid` — ShortID (must exist in server Short IDs list)
- `spx=%2F` — SpiderX must be `/` (encoded as `%2F`)

---

## Mass Migration Script (run from DE-222)

```bash
# Run from: DE-222 (152.53.182.222)
# Migrates: ALEX_47, TATRA_9, SHAHIN_227, STOLB_24, PILIK_33, SO_38

VPN_SERVERS=(
  "109.234.38.47:EU-ALEX-47"
  "144.124.232.9:EU-TATRA-9"
  "144.124.228.227:EU-SHAHIN-227"
  "144.124.239.24:EU-STOLB-24"
  "195.63.138.33:EU-PILIK-178"
  "144.124.233.38:EU-SO-38"
)

for ENTRY in "${VPN_SERVERS[@]}"; do
  IP="${ENTRY%%:*}"
  NAME="${ENTRY##*:}"
  echo ">>> $NAME ($IP)"
  ssh -o StrictHostKeyChecking=no root@$IP bash << ENDSSH
    mkdir -p /root/backup_xui
    cp /etc/x-ui/x-ui.db /root/backup_xui/x-ui.db.\$(date +%Y%m%d_%H%M%S) 2>/dev/null
    hostnamectl set-hostname $NAME
    echo "$NAME" > /etc/hostname
    timedatectl set-timezone Europe/Prague
    systemctl stop x-ui 2>/dev/null
    systemctl disable x-ui 2>/dev/null
    rm -f /usr/local/x-ui/x-ui /etc/systemd/system/x-ui.service
    systemctl daemon-reload
    echo "4" | bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh)
    ufw allow 443/tcp && ufw allow 443/udp && ufw allow 8443/tcp && ufw reload
    systemctl is-active x-ui && echo "OK: x-ui running" || echo "FAIL: x-ui not running"
ENDSSH
done
```

---

## Notes

- Old users on migrated servers: **no reconnection needed** — database migrated automatically
- New installs: always open UFW ports manually after install
- Always verify SpiderX = `/` in every new inbound
- Target and SNI must always be the same domain
- Xray version v26.5.9 confirmed stable — do not auto-update to untested versions

---

## Author
Rooted by VladiMIR + AI
v.2026.05.31 | github.com/GinCz
