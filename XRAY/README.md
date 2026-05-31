# Xray (VLESS + Reality) — Full Setup & User Guide
# = Rooted by VladiMIR + AI | v.2026.05.31 | github.com/GinCz =

---

## VERSION HISTORY

| Version | Date | Notes |
|---------|------|-------|
| v2026.05.31 | 2026-05-31 | 3x-ui v1.10.2 / Xray v26.5.9 — new UI tab names, ShortID auto-generated |
| v2026.04.30 | 2026-04-30 | Initial guide |

---

## IMPORTANT: Xray Binary Path

After installing x-ui, Xray binary is at:

```
/usr/local/x-ui/bin/xray-linux-amd64
```

NOT `/usr/local/x-ui/bin/xray` — wrong path = FAIL.

---

## STEP 0: TIMEZONE & TIME SYNC (mandatory before setup)

Xray Reality requires accurate server time.

```bash
timedatectl set-timezone Europe/Prague
apt install -y systemd-timesyncd
systemctl enable --now systemd-timesyncd
timedatectl set-ntp true
timedatectl
```

Expected output:
```
               Local time: Sun 2026-05-31 17:00:00 CEST
           Universal time: Sun 2026-05-31 15:00:00 UTC
                Time zone: Europe/Prague (CEST, +0200)
System clock synchronized: yes
              NTP service: active
```

---

## SETUP GUIDE — 3x-ui v1.10.2 / Xray v26.5.9

### Install 3x-ui

```bash
bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh)
```

During install: set port (e.g. 59417), login and password.

### Recommended Xray Version

In panel Overview → click Xray version badge → select **v26.5.9** (latest stable tested).

---

## STEP 1: Add Inbound

Panel → Inbounds → + Add Inbound

### Tab: Basics

| Field | Value |
|-------|-------|
| Enabled | ON |
| Remark | e.g. EU-ILYA-176 |
| Protocol | vless |
| Address | (leave blank — listens on all IPs) |
| Port | **443** |
| Total Flow | 0 (unlimited) |
| Traffic Reset | Monthly |

> **Port 443 vs 8443:**
> - **443** — standard HTTPS port, best camouflage, looks like normal HTTPS traffic. Recommended for new servers.
> - **8443** — alternative, used on older servers for compatibility. Both work, but 443 is preferred for Reality because it matches the fingerprint camouflage better.

### Tab: Protocol

| Field | Value |
|-------|-------|
| Decryption | none |
| Encryption | none |
| X25519 auth | (not selected) |
| ML-KEM-768 auth | (not selected) |
| Vision testseed | 900, 500, 900, 256 (default — leave as is) |
| Fallbacks | none |

### Tab: Stream

| Field | Value |
|-------|-------|
| Transmission | **RAW** (= TCP in new UI) |
| Proxy Protocol | OFF |
| HTTP Obfuscation | OFF |
| External Proxy | OFF |
| Sockopt | OFF |
| TCP Masks | (none) |

> Note: In v26.5.9 UI, "TCP" is now called **"RAW"** — same thing.

### Tab: Security

| Field | Value |
|-------|-------|
| Security | **Reality** |
| Show | OFF |
| Xver | 0 |
| uTLS (Fingerprint) | **chrome** |
| Target (Dest) | **www.github.com:443** |
| SNI | **www.github.com** |
| Max Time Diff (ms) | 0 |
| Short IDs | **leave the auto-generated one** (one is enough, delete extras) |
| SpiderX | / |
| Public Key | auto-generated — do NOT edit |
| Private Key | auto-generated — do NOT edit |
| mldsa65 Seed | (empty) |
| mldsa65 Verify | (empty) |

> **CRITICAL RULE:** Target = SNI = same domain (www.github.com).
> Mismatch between Target and SNI = Timeout on client.

Click **Get New Cert** only if no keys exist yet.

### Tab: Sniffing

| Field | Value |
|-------|-------|
| Enabled | **OFF** |

---

## STEP 2: Add Client

Inbounds → Edit (pencil icon) → Add Client

| Field | Value |
|-------|-------|
| Email | any name (e.g. VladiMIR_Honor) |
| ID | click Generate (UUID) |
| Flow | **(leave empty)** |
| SubId | auto-generated or set manually |
| Limit IP | 0 (unlimited) |
| Total GB | 0 (unlimited) |
| Expiry Time | 0 or set date |

Save Changes → Xray restarts automatically.

---

## STEP 3: Open Port

```bash
ufw allow 443/tcp
ufw reload
ss -tlnp | grep 443
```

---

## STEP 4: Get Client Config

Inbounds list → click QR icon next to the client → scan with app.

Or copy the vless:// link.

---

## CLIENT APPS

| Platform | App |
|----------|-----|
| Android | Hiddify (recommended), v2rayNG |
| iOS | Shadowrocket, Hiddify |
| Windows | Hiddify, v2rayN |

---

## TROUBLESHOOTING

**Timeout on connect:**
1. Check Target = SNI (same domain!)
2. Check port is open: `ufw status` / `ss -tlnp | grep 443`
3. Check time sync: `timedatectl`
4. Restart: `systemctl restart x-ui`

**x-ui service not found:**
```bash
# 3x-ui uses x-ui.service:
systemctl status x-ui
systemctl restart x-ui
```

**Check Xray logs:**
```bash
journalctl -u xray -n 50 --no-pager
# or in panel: Xray Configs → Logs
```

---

## MUST MATCH (checklist)

- [ ] Target = SNI = `www.github.com`
- [ ] Transmission = RAW (TCP)
- [ ] Security = Reality
- [ ] Fingerprint = chrome
- [ ] Sniffing = OFF
- [ ] Flow = empty
- [ ] Port 443 open in UFW
- [ ] Time synchronized (NTP active)

---

## SECURITY

DO NOT SHARE:
- PrivateKey (stays on server only)
- Panel URL / login / password
- Root SSH access

---

## AUTHOR
Rooted by VladiMIR + AI
v.2026.05.31 | github.com/GinCz
