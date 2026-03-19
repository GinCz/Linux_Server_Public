# AWS EC2 — Crypto Bot Server Setup

> **Version:** v2026-03-19  
> **OS:** Ubuntu 24 LTS  
> **User:** `ubuntu` (sudo required for system operations)  
> **Purpose:** Dedicated server for running the Crypto Trading Bot

---

## 📋 Table of Contents

1. [Server Overview](#server-overview)
2. [First Connection](#first-connection)
3. [Installing server_tools](#installing-server_tools)
4. [Setting up 303 (tmux clipboard tool)](#setting-up-303)
5. [ClamAV Antivirus](#clamav-antivirus)
6. [Crypto Bot Setup](#crypto-bot-setup)
7. [Known Issues & Solutions](#known-issues--solutions)
8. [Useful Commands](#useful-commands)

---

## Server Overview

| Parameter       | Value                          |
|----------------|--------------------------------|
| Provider        | Amazon AWS EC2                 |
| OS              | Ubuntu 24 LTS                  |
| Default user    | `ubuntu`                       |
| Sudo            | passwordless (`ubuntu ALL=NOPASSWD:ALL`) |
| App directory   | `/home/ubuntu/aws-setup/`      |
| Tools directory | `/opt/server_tools/`           |
| Bot URL         | https://crypto.YOUR-DOMAIN.com |
| Service manager | systemd                        |

> ⚠️ **Unlike servers 222/109 (FastPanel, root access), AWS uses user `ubuntu` with sudo.**  
> All scripts in `scripts/aws/` are adapted for this environment.

---

## First Connection

```bash
# Connect via SSH with your .pem key
ssh -i your-key.pem ubuntu@YOUR-AWS-IP

# Or if key is already in agent
ssh ubuntu@YOUR-AWS-IP
```

---

## Installing server_tools

The `/opt/server_tools` directory may not be a git repository on AWS (it could be
a manually copied folder). Run this to set it up properly:

```bash
# If /opt/server_tools exists but is NOT a git repo:
sudo rm -rf /opt/server_tools
sudo git clone https://github.com/GinCz/Linux_Server_Public.git /opt/server_tools
sudo chmod -R 755 /opt/server_tools

# Load aliases for current session
source /opt/server_tools/scripts/shared_aliases_aws.sh
```

To make aliases load automatically on every SSH login:

```bash
echo 'source /opt/server_tools/scripts/shared_aliases_aws.sh' >> ~/.bashrc
```

---

## Setting up 303

`303` is a tool that captures the full terminal scrollback buffer and copies it
to your clipboard via OSC 52 — so you can paste the entire session into a browser
or chat with one `Ctrl+V`.

### How it works

- `303` requires `tmux` to capture scrollback
- On first run **without tmux**, `303` installs everything automatically
- On every subsequent SSH login, tmux starts automatically

### Installation (first time)

```bash
# Run 303 - it will self-install tmux and configure auto-start
sudo bash /opt/server_tools/scripts/log_303.sh

# Output:
# [1/3] Installing tmux... OK
# [2/3] Writing ~/.tmux.conf... OK
# [3/3] Configuring tmux auto-start... OK
# → Reconnect SSH, then type: 303
```

### After reconnecting SSH

```bash
# tmux starts automatically. Now 303 works:
303
# → Captures scrollback, press Ctrl+V to paste
```

### Tmux quick keys

| Key           | Action                        |
|--------------|-------------------------------|
| `Ctrl+B, D`  | Detach (session keeps running)|
| `Ctrl+B, [`  | Scroll mode (Q to exit)       |
| `tmux ls`    | List sessions                 |
| `tmux a`     | Re-attach to last session     |

### Troubleshooting 303

| Error | Cause | Fix |
|-------|-------|-----|
| `❌ 303 requires tmux` | tmux not running | Run `sudo bash /opt/server_tools/scripts/log_303.sh` then reconnect SSH |
| `Error: Can't open display` | Old version of 303 using xclip | Update: `cd /opt/server_tools && sudo git pull` |
| `Permission denied` on /opt | ubuntu user has no write access | Use `sudo` for all operations in `/opt/` |
| `fatal: not a git repository` | /opt/server_tools was copied, not cloned | Re-clone: see [Installing server_tools](#installing-server_tools) |
| `✓ Copied 0 lines` | xclip method, not OSC 52 | Update scripts, reconnect SSH, try again |

---

## ClamAV Antivirus

### Problem encountered

On AWS Ubuntu, `freshclam` is not in `$PATH` when called from a script,
and `systemctl` requires `sudo`. The default `scan_clamav.sh` was written
for root access (servers 222/109) and fails on AWS.

### AWS-specific scan script

Use `scripts/aws/scan_clamav_aws.sh` instead:

```bash
bash /opt/server_tools/scripts/aws/scan_clamav_aws.sh
```

Differences from the standard version:
- Uses `sudo freshclam` instead of stopping/starting systemd service
- Scans `/home/ubuntu/aws-setup/` (bot directory) specifically
- Does not require root — works with `sudo`
- No display/X11 dependency

### Install ClamAV (if not installed)

```bash
sudo apt-get update && sudo apt-get install -y clamav clamav-daemon
sudo systemctl stop clamav-freshclam
sudo freshclam
sudo systemctl start clamav-freshclam
```

---

## Crypto Bot Setup

The bot lives in `/home/ubuntu/aws-setup/`. See the
[Crypto_BOT repository](https://github.com/GinCz/Crypto_BOT) for full documentation.

### Quick deploy

```bash
cd ~/aws-setup
bash scripts/deploy.sh
```

### Check status

```bash
pgrep -a python3
tail -f ~/aws-setup/app.log
tail -f ~/aws-setup/scanner.log
```

### Service management

```bash
# If running as systemd service:
sudo systemctl status crypto-bot
sudo systemctl restart crypto-bot
sudo journalctl -u crypto-bot -f
```

---

## Known Issues & Solutions

### `rm: cannot remove 'server_tools': Permission denied`
**Cause:** `ubuntu` user doesn't own `/opt/server_tools`  
**Fix:** `sudo rm -rf /opt/server_tools`

### `git pull` fails with "local changes would be overwritten"
**Cause:** Files were edited locally without committing  
**Fix:** `git fetch origin && git reset --hard origin/main`

### `freshclam: command not found`
**Cause:** ClamAV installed but not in PATH for non-root  
**Fix:** Use full path: `sudo /usr/bin/freshclam` or use `scan_clamav_aws.sh`

### `polkit authentication failed` when stopping services
**Cause:** `ubuntu` user needs passwordless sudo configured, or use sudo explicitly  
**Fix:** `sudo systemctl stop clamav-freshclam`

### `fatal: not a git repository`
**Cause:** `/opt/server_tools` was created by copying files, not `git clone`  
**Fix:** Remove and re-clone (see [Installing server_tools](#installing-server_tools))

---

## Useful Commands

```bash
# Update server_tools from GitHub
cd /opt/server_tools && sudo git pull

# Load aliases for current session
source /opt/server_tools/scripts/shared_aliases_aws.sh

# Check running bot processes
pgrep -a python3

# View bot logs live
tail -f ~/aws-setup/app.log
tail -f ~/aws-setup/scanner.log
tail -f ~/aws-setup/trade_engine.log

# Restart all bot processes
cd ~/aws-setup && bash scripts/deploy.sh

# Full server info
bash /opt/server_tools/scripts/infooo.sh

# Antivirus scan (AWS version)
bash /opt/server_tools/scripts/aws/scan_clamav_aws.sh
```
