# 3x-ui + XRAY REALITY — Full Documentation
> = Rooted by VladiMIR + AI | v.2026.06.09 | github.com/GinCz =

---

## 🗂️ File Locations (Quick Reference)

| What | Path on Server | Notes |
|------|---------------|-------|
| 3x-ui binary | `/usr/local/x-ui/x-ui` | Main process |
| XRAY binary | `/usr/local/x-ui/bin/xray-linux-amd64` | Launched by x-ui internally |
| **XRAY config** | `/usr/local/x-ui/bin/config.json` | Generated from DB on startup |
| **3x-ui database** | `/etc/x-ui/x-ui.db` | SQLite — stores ALL inbounds, clients, keys |
| Systemd service | `/etc/systemd/system/x-ui.service` | |
| x-ui logs | `journalctl -u x-ui -n 50` | |
| XRAY access log | `/var/log/xray/access.log` (if enabled) | Disabled by default |

### ⚠️ IMPORTANT: REALITY keys are stored in the DB, NOT in config.json

`config.json` contains only `privateKey`. `publicKey` is **not stored** in the file — it is derived from the private key at runtime.
The keys (`publicKey` + `privateKey`) are saved through the 3x-ui panel:
**Inbounds → Edit → Security → Reality → Public Key / Private Key fields → Save**

Once saved via the panel, keys are fixed in `/etc/x-ui/x-ui.db` and **do not change on restart**.

---

## 🔑 Getting publicKey from privateKey

```bash
# Derive publicKey from an existing privateKey
PRIVKEY="YOUR_PRIVATE_KEY"
/usr/local/x-ui/bin/xray-linux-amd64 x25519 -i "$PRIVKEY"
```

Output:
```
PrivateKey: <same as input>
Password (PublicKey): <this is the publicKey to use in client links>
```

### Generate a new key pair

```bash
/usr/local/x-ui/bin/xray-linux-amd64 x25519
```

After generating — always save via panel (Edit Inbound → Save) to persist keys in the DB.

---

## 🏗️ VLESS+REALITY Link Structure

```
vless://UUID@IP:PORT?encryption=none&fp=FINGERPRINT&pbk=PUBLIC_KEY&security=reality&sid=SHORT_ID&sni=SNI&spx=%2F&type=tcp#CLIENT_NAME
```

| Parameter | Value | Where to get it |
|-----------|-------|-----------------|
| `UUID` | Client ID | 3x-ui panel → Clients → UUID |
| `IP:PORT` | Server IP:443 | Server IP |
| `fp` | `chrome` | Inbound → Security → uTLS |
| `pbk` | Public Key | Inbound → Security → Reality → Public Key |
| `sid` | Short ID | Inbound → Security → Reality → Short IDs |
| `sni` | `www.github.com` | Inbound → Security → Reality → SNI |
| `spx` | `%2F` (slash) | Inbound → Security → Reality → SpiderX |

**⚠️ spx must match the panel value exactly!** If panel shows `/` — link must have `%2F`.
Always **copy the link from the panel QR code**, do not edit manually.

---

## 🛠️ Diagnostics — Checklist When Connection Fails

```bash
# 1. Check x-ui is running
systemctl status x-ui

# 2. Check xray is listening on port 443
ss -tlnp | grep ':443'

# 3. Check UFW firewall
ufw status

# 4. Check CrowdSec bans (client IP might be banned)
cscli decisions list

# 5. Check active connections on 443
ss -tnp | grep ':443'

# 6. Check x-ui logs (last restarts)
journalctl -u x-ui -n 30

# 7. Check dest in XRAY config
grep -A3 "dest" /usr/local/x-ui/bin/config.json | head -5
```

### Common Failure Causes

| Symptom | Cause | Fix |
|---------|-------|-----|
| Client does not connect, server OK | Wrong `publicKey` in link | Recreate link from panel QR |
| Connects but nothing works | `spx` in link ≠ `spx` in panel | Make both match |
| Worked before, stopped after restart | Keys not saved in DB | Go to Edit Inbound → fill Public/Private Key → Save |
| Keys change on every restart | Keys not fixed in x-ui.db | Edit Inbound → fill in keys → Save |
| Works from EU, not from Russia | DPI/RKN blocking | See Russia section below |
| VPN connected, Telegram messages work but calls fail | UDP not tunneled | TUN mode + Enable Resolve Destination ON |

---

## 📋 Recommended Inbound Settings

### Tab: Basics
- Protocol: `vless`
- Port: `443`

### Tab: Stream
- Network: `tcp`

### Tab: Security → Reality

| Field | Value |
|-------|-------|
| uTLS / Fingerprint | `chrome` |
| Target (dest) | `www.github.com:443` |
| SNI | `www.github.com` |
| Short IDs | `02` (or any hex string) |
| SpiderX | `/` |
| Public Key | (must be saved here!) |
| Private Key | (must be saved here!) |

### Tab: Sniffing
- Enable: ✅ ON
- destOverride: `http`, `tls`, `quic`
- Required for correct proxying of Telegram and other apps

### New client fields (v3.2.0+)
- **Hysteria Auth** and **Password** — appeared in v3.2.0
- Only needed for Hysteria2 inbounds
- For VLESS+REALITY — leave empty

---

## 📱 Hiddify Client Setup — Step by Step

### Installation and Profile Import
1. Download Hiddify from the official site / GitHub releases
2. Open app → **Profiles** → **+** → paste VLESS link or scan QR code from 3x-ui panel

### Settings → Routing

| Parameter | Value | Why |
|-----------|-------|-----|
| **Region** | **Russia (ru)** ⚠️ | Activates RKN bypass rules — without this Telegram, Instagram, YouTube remain blocked |
| Block ads | ON | DNS-level ad blocking |
| Bypass LAN | **ON** | Allows access to local network (router, Samba, printer) while VPN is active |
| **Resolve destination address** | **ON** | Required for correct UDP routing (Telegram calls) |
| Route IPv6 | OFF | Prevents leaks |

### Settings → Inbound (Service Mode)

| Parameter | Value | Why |
|-----------|-------|-----|
| **Service mode** | **TUN** (not "System Proxy") | Only TUN tunnels UDP — without it Telegram calls do not work |
| **Strict routing** | **ON** | All traffic through VPN; when VPN is off — internet is fully cut (leak protection) |
| TUN implementation | `gvisor` | Best stability |

### Settings → DNS

| Parameter | Value |
|-----------|-------|
| Remote DNS | `tcp://8.8.8.8` |
| Direct resolver | `1.1.1.1` |
| Split DNS | OFF |

### Settings → TLS Tricks

| Parameter | Value | When to enable |
|-----------|-------|----------------|
| Enable fragmentation | OFF (default) | Enable if REALITY fails to connect from specific networks |
| Fragment packets | `TLS Hello` | |
| Fragment size | `10-30` | |

### Settings → General

| Parameter | Value |
|-----------|-------|
| Use xray-core | OFF | Hiddify uses sing-box by default — better performance |
| Connection test URL | `http://captive.apple.com/hotspot-detect.html` |

### After changing settings
Always **fully restart Hiddify** (close → reopen), not just disconnect/connect.

---

## 🇷🇺 Russia — What Works, What Doesn’t

### What RKN/TSPU blocks
- UDP traffic to foreign servers (unstable)
- Specific IP addresses of Telegram, Instagram, YouTube (periodically)
- VPN protocols with obvious signatures (OpenVPN, standard WireGuard)

### Why REALITY works in Russia
REALITY disguises itself as normal TLS traffic to a legitimate site (in our case `www.github.com`). DPI sees a connection to GitHub and lets it through.

### TCP vs UDP Through VPN From Russia

| Traffic type | Protocol | Via System Proxy | Via TUN mode |
|-------------|----------|------------------|--------------|
| Telegram messages | TCP | ✅ works | ✅ works |
| Telegram calls | UDP | ❌ not tunneled | ✅ works |
| Video calls | UDP | ❌ | ✅ |
| Browser (HTTP/HTTPS) | TCP | ✅ | ✅ |
| Torrents | UDP+TCP | ❌ / partial | ✅ |

### Telegram messages work but calls don’t
1. Verify **TUN mode is enabled** (not System Proxy)
2. **Resolve destination address** → ON
3. **Strict routing** → ON
4. Full restart of Hiddify
5. If still broken → enable **TLS Fragmentation** (TLS Tricks → ON)

### Telegram requires "Use system proxy" setting
This is normal behavior. In System Proxy mode Hiddify sets a local HTTP/SOCKS5 proxy (`127.0.0.1:2080`). Some versions of Telegram Desktop ignore the TUN tunnel and only respect the system proxy. Setting: Telegram → Settings → Advanced → Connection type → Use system proxy settings.

### Russian sites (Yandex, VK, Mail.ru) work without VPN
With region **Russia (ru)**, Hiddify automatically routes RU-domain traffic **directly** (bypassing VPN). Russian streaming services, banks, and government portals get your real EU IP and work fine — they are not blocked for EU visitors.

### Accessing Russian banks from Europe (Gosuslugi, VTB, Alfa-Bank)
- These sites are **not blocked** — they are accessible from Europe directly
- With region Russia, Hiddify routes them **directly** (no VPN), which is correct
- If a specific bank blocks foreign IPs — add its domain manually:
  - Settings → Routing → Proxy Domains → add `vtb.ru`, `alfabank.ru`, etc.
  - These will then route through the VPN server (Russian IP)

### Which region to use from Czech Republic / Europe

| Goal | Region | Result |
|------|--------|--------|
| Bypass RKN blocks (Telegram, Instagram, YouTube) | **Russia (ru)** | Blocked sites → VPN, others → direct |
| Access Russian banks that block foreign IPs | **Russia (ru)** + add domain to Proxy Domains | Bank traffic → VPN |
| All traffic through VPN (no split) | Any region + disable split tunneling | Everything via VPN |

**Recommendation: always use Russia (ru)** when connecting from Europe to access Russian and blocked services.

### Nothing works from a specific network
The provider may block port 443 to foreign IPs. Test:
- Try with mobile internet (not home ISP)
- If mobile works — problem is in home router/ISP
- Home router fix: set DNS to `8.8.8.8` / `8.8.4.4`, disable parental controls and DPI in router settings

---

## 🔄 Updating 3x-ui

```bash
# Update 3x-ui
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)

# After update: verify keys are still in place
systemctl status x-ui
grep "privateKey" /usr/local/x-ui/bin/config.json
```

**⚠️ After update** — open panel, verify that keys in Edit Inbound → Security → Reality have not been reset.

---

## 🖥️ Our VPN Servers

| Server | IP | Panel URL | Inbound |
|--------|----|----------|---------|
| EU-Alex-47 | 109.234.38.47 | `:24178/Alex_47` | vless:443 REALITY |
| VPN-IONOS-38 | 82.223.116.38 | — | vless:443 REALITY |
| DE-222 | 152.53.182.222 | — | — |
| RU-109 | 212.109.223.109 | — | — |

Panel logins/passwords — stored in private repository `Secret_Privat`.
