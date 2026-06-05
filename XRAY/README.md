# XRAY Clean Installer

> **Version:** v2026-06-05d  
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
4. Apply credentials via `x-ui` CLI (correct bcrypt hashing)
5. Configure UFW firewall (SSH + panel port)
6. Print **URL / LOGIN / PASSWORD** at the end

### Expected output

```
==========================================
  XRAY INSTALLED SUCCESSFULLY!
  Rooted by VladiMIR | AI
==========================================

  SERVER IP:   3.79.14.42
  PANEL URL:   http://3.79.14.42:15539/1l9prc7y
  LOGIN:       adminXXXXXX
  PASSWORD:    XXXXXXXXXXXXXXXX

  !! Save these credentials NOW !!
  x-ui status: active
==========================================
```

---

## Requirements

- Ubuntu 22.04 or 24.04 (clean or existing server)
- Root access
- Port 22 must remain open (SSH)
- AWS: open the panel port in Security Group after installation

---

## AWS Security Group

After install, open the generated port in AWS Console:  
`EC2 → Security Groups → Inbound Rules → Add Rule → Custom TCP → port from output`

---

## Adding Inbounds (VLESS/Reality)

Add inbounds via the web panel:  
**Panel → Inbounds → Add Inbound**

Recommended config:
- Protocol: `vless`
- Port: `443`
- Security: `reality`
- Dest (SNI): `www.github.com:443`
- Fingerprint: `chrome`

---

## Bug History & Fixes

### v2026-06-05d — Current (working)

**Fix: Switched from `alireza0/x-ui` to `MHSanaei/3x-ui`**
- `alireza0` GitHub profile was flagged/banned by GitHub in early 2026
- Install script returned HTTP 404, causing `line 1: 404:: command not found` error
- **Fix:** Switched to `MHSanaei/3x-ui` (active fork, v3.2.7+)
- Install answers: `1` = SQLite, `4` = Skip SSL (no port 80 required)

**Fix: Password stored as bcrypt hash — cannot be read from DB**
- SQLite `users` table stores password as `$2a$10$...` bcrypt hash
- Reading it back is useless — original plain-text password is gone
- **Fix:** Generate credentials BEFORE install, apply AFTER via `x-ui setting -username -password -port -webBasePath` CLI command which handles bcrypt hashing internally
- Fallback: direct SQLite UPDATE if CLI fails

**Fix: Wrong DB path**
- `alireza0/x-ui` stored DB at `/usr/local/x-ui/db/x-ui.db`
- `MHSanaei/3x-ui` stores DB at `/etc/x-ui/x-ui.db`
- **Fix:** Updated DB path to `/etc/x-ui/x-ui.db`

**Fix: SSL setup blocking on AWS (no port 80)**
- MHSanaei installer prompts for SSL setup and tries Let's Encrypt
- AWS Security Groups block port 80 by default → ACME challenge times out (~60s hang)
- **Fix:** Pass `4` (Skip SSL) as automated answer to installer

### v2026-06-05c

**Fix: Correct DB path for MHSanaei fork**
- First migration attempt used wrong path from alireza0 era
- Updated candidate paths with priority on `/etc/x-ui/x-ui.db`

### v2026-06-05b

**Fix: Credentials not displayed after install**
- Old script used `x-ui settings` command to read credentials
- `alireza0/x-ui` — `x-ui settings` returned empty output after install
- Even when output existed, `grep -oP` regex did not match new format
- **Fix:** Read credentials directly from SQLite DB after install
- **Fix:** Generate credentials before install, use as fallback if DB read fails

### v2026-04-25 (original)

- Initial version using `alireza0/x-ui`
- Used `x-ui settings | grep -oP` to read credentials — unreliable
- No fallback if credentials were empty
- Result: URL/LOGIN/PASSWORD printed as empty strings

---

## Files

| File | Description |
|---|---|
| `xray_clean_installer.sh` | **Main installer** — full wipe + reinstall |
| `xray_installer.sh` | Installer without wipe (preserves existing services) |
| `xray_safe_installer.sh` | Safe installer — does not touch firewall |
| `config.example.json` | Example VLESS+Reality inbound config |
| `MIGRATION_LOG_2026-05-31.md` | Server migration log |
