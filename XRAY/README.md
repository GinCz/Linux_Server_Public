# XRAY Clean Installer

> **Version:** v2026-06-05g  
> **Author:** VladiMIR | AI  
> **Panel:** [MHSanaei/3x-ui](https://github.com/MHSanaei/3x-ui) v3.x

## Quick Start

```bash
curl -Ls https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/XRAY/xray_clean_installer.sh | bash
```

The installer will:
1. Wipe all old Xray / x-ui installations
2. Install fresh 3x-ui (MHSanaei fork)
3. Auto-generate credentials (username, password, port, path)
4. Write credentials directly into SQLite DB (DELETE + INSERT)
5. Configure UFW: `22`, `443/tcp+udp`, `8443`, panel port
6. Print **URL / LOGIN / PASSWORD** + AWS step-by-step reminder

### Expected output

```
==========================================
  XRAY INSTALLED SUCCESSFULLY!
  Rooted by VladiMIR | AI
==========================================

  SERVER IP:   3.79.14.42
  PANEL URL:   http://3.79.14.42:26303/jgvuz6lu
  LOGIN:       adminXXXXXX
  PASSWORD:    XXXXXXXXXXXXXXXX

  !! Save these credentials NOW !!

  UFW ports open: 22, 443/tcp+udp, 8443, 26303
  x-ui status:    active
==========================================

  !! AWS SECURITY GROUP — MANUAL STEP REQUIRED !!

  UFW is open on the server, but AWS Security Group
  is an external firewall — it CANNOT be changed
  from inside the server. You must open the port
  manually in the AWS Console:

  Port to open:   26303 (TCP)
  Source:         0.0.0.0/0

  Direct link to EC2 Security Groups:
  https://console.aws.amazon.com/ec2/home#SecurityGroups

  Steps:
  1. Open the link above
  2. Select your Security Group → Edit inbound rules
  3. Add Rule → Custom TCP → Port 26303 → Source 0.0.0.0/0
  4. Save rules
  5. Open: http://3.79.14.42:26303/jgvuz6lu
==========================================
```

---

## Requirements

- Ubuntu 22.04 or 24.04 (clean or existing server)
- Root access
- Port 22 must remain open (SSH)
- **AWS only:** open the panel port in Security Group after installation (see reminder in output)

---

## AWS Security Group — Why Manual?

AWS Security Groups are an **external firewall** managed by AWS itself — completely separate from UFW running inside the server. There is no AWS CLI command that can be run from inside the EC2 instance without IAM credentials configured. The installer opens all ports in UFW automatically, but the Security Group step will always require the AWS Console.

Direct link: [EC2 Security Groups](https://console.aws.amazon.com/ec2/home#SecurityGroups)

---

## Adding Inbounds (VLESS/Reality)

Add inbounds via the web panel:  
**Panel → Inbounds → Add Inbound**

Recommended base config:
- Protocol: `vless`
- Port: `443`
- Security: `reality`
- SpiderX: `/` ← must be exactly `/`, not a random string

---

## Bug History & Fixes

### v2026-06-05g — Current

**Fix: AWS Security Group reminder in output**
- Installer detects AWS via instance metadata endpoint (`169.254.169.254`)
- If AWS detected: prints step-by-step instructions + direct Console link
- If other provider: prints generic cloud firewall note

### v2026-06-05f

**Fix: `INSERT OR REPLACE` created duplicate rows in settings table**
- `INSERT OR REPLACE INTO settings` was adding a **new row** instead of updating the existing one
- Because `key` is not a true `PRIMARY KEY` in the 3x-ui settings table, SQLite treats each insert as a new record
- x-ui reads the **first** matching row — so the old value (random port from installer) always won — the new port was silently ignored
- **Fix:** `DELETE FROM settings WHERE key='...'` followed by `INSERT INTO settings` — guarantees exactly one row per key
- Added DB verification output: prints saved port/path before starting x-ui

**Fix: UFW missing 443/udp and 8443**
- Previous versions only opened `443/tcp` — VLESS Reality also needs `443/udp`
- Added `ufw allow 443/tcp`, `ufw allow 443/udp`, `ufw allow 8443/tcp`

### v2026-06-05d

**Fix: Switched from `alireza0/x-ui` to `MHSanaei/3x-ui`**
- `alireza0` GitHub profile was deleted, returning HTTP 404
- **Fix:** Switched to `MHSanaei/3x-ui` (active fork, v3.2.7+)
- Install answers: `1` = SQLite, `4` = Skip SSL (no port 80 required)

**Fix: Password stored as bcrypt hash**
- SQLite stores password as `$2a$10$...` — cannot be read back
- **Fix:** Generate credentials before install, write after via CLI / SQLite

**Fix: Wrong DB path**
- `alireza0` used `/usr/local/x-ui/db/x-ui.db`
- `MHSanaei/3x-ui` uses `/etc/x-ui/x-ui.db`

**Fix: SSL setup hanging on AWS**
- AWS blocks port 80 by default → Let's Encrypt ACME challenge times out
- **Fix:** Pass `4` (Skip SSL) as automated answer

### v2026-06-05b

**Fix: Credentials not displayed after install**
- `x-ui settings` returned empty output after install
- `grep -oP` regex did not match new format
- **Fix:** Read credentials directly from SQLite DB

### v2026-04-25 (original)

- Initial version using `alireza0/x-ui`
- Used `x-ui settings | grep -oP` — unreliable, printed empty strings

---

## Files

| File | Description |
|---|---|
| `xray_clean_installer.sh` | **Main installer** — full wipe + reinstall |
| `xray_installer.sh` | Installer without wipe (preserves existing services) |
| `xray_safe_installer.sh` | Safe installer — does not touch firewall |
| `config.example.json` | Example VLESS+Reality inbound config |
| `MIGRATION_LOG_2026-05-31.md` | Server migration log (alireza0 → MHSanaei) |
