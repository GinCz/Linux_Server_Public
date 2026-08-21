# 3x-ui AWS EC2 Install Script

**Version:** 1.0.0  
**Date:** 2026-06-05  
**Tested on:** Ubuntu 24.04 LTS (AWS EC2, Frankfurt region)  
**3x-ui version:** v3.2.8  

---

## What it does

Full clean installation of [3x-ui](https://github.com/mhsanaei/3x-ui) (Xray VPN panel) on a fresh or existing AWS EC2 Ubuntu server.

- Stops and completely removes any previous x-ui installation
- Resets UFW firewall (preserves SSH port 22)
- Installs 3x-ui v3.2.8 with:
  - SQLite database
  - Random panel port (auto-generated)
  - No SSL / HTTP only mode
  - Listens on all network interfaces
- Automatically opens the generated port in UFW
- Prints the Access URL, port, login and password at the end

---

## Usage

```bash
wget -O 3xui_aws_install.sh https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/VPN/3xui_aws_install.sh
chmod +x 3xui_aws_install.sh
bash 3xui_aws_install.sh
```

Or one-liner:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/VPN/3xui_aws_install.sh)
```

---

## After install

1. Note the **port** printed at the end of the script
2. Go to **AWS Console → EC2 → Security Groups → Edit inbound rules**
3. Add rule: `Custom TCP | Port: <printed port> | Source: 0.0.0.0/0`
4. Open the **Access URL** in browser (use **http**, not https)
5. Log in with credentials printed by the installer

---

## Known Bugs & Limitations (v1.0.0)

### BUG-01 — SSL auto-selection causes ERR_SSL_PROTOCOL_ERROR
**Problem:** The 3x-ui installer defaults to "Let's Encrypt for IP" (option 2) when no input is provided. If port 80 is closed in AWS Security Group, the certificate issuance fails silently. The panel still starts but on HTTPS with an invalid/missing cert, causing `ERR_SSL_PROTOCOL_ERROR` in the browser.  
**Fix in this script:** Forces option `4` (Skip SSL) via heredoc stdin — panel runs on plain HTTP.  
**Workaround if you need SSL:** Open port 80 in AWS Security Group before install and choose option 2 manually.

### BUG-02 — Manual sqlite3 credential edits have no effect
**Problem:** Editing `username`/`password` directly in `/etc/x-ui/x-ui.db` users table does NOT change login credentials. 3x-ui reads credentials from its own internal config layer, not directly from the SQLite users table.  
**Fix:** Always use the login/password printed by the installer in the `Panel Installation Complete` block. To reset credentials after install use `x-ui settings` CLI tool.  
**Affected versions:** v3.2.8 confirmed.

### BUG-03 — Port not auto-opened in AWS Security Group
**Problem:** UFW is a host-level firewall. AWS Security Group is a cloud-level firewall. This script opens the port in UFW automatically, but AWS Security Group rules must be added **manually** in AWS Console.  
**Fix:** Script prints the port and explicit instructions at the end.

### BUG-04 — UFW reset removes all previous rules
**Problem:** The script runs `ufw --force reset` which removes ALL existing UFW rules (except port 22 which is re-added). This is intentional for a clean install but will break any other services using UFW rules.  
**Workaround:** If other ports need to be preserved, add `ufw allow <port>/tcp` lines manually after install.

---

## Tested Environment

| Parameter | Value |
|---|---|
| OS | Ubuntu 24.04 LTS |
| Cloud | AWS EC2 (eu-central-1, Frankfurt) |
| Instance type | t3.micro / t3.small |
| 3x-ui version | v3.2.8 |
| Install date | 2026-06-05 |

---

## Related files

- [`xray_clean_install.sh`](./xray_clean_install.sh) — Xray-only install (without panel)
- [`xray_safe_install.sh`](./xray_safe_install.sh) — Safe Xray reinstall preserving config
- [`README.md`](./README.md) — VPN infrastructure overview
