# AWS Crypto Bot Server

**Purpose:** Dedicated server for the Crypto Trading Bot project.

| Parameter | Value |
|---|---|
| **Hostname** | aws-crypto-bot |
| **User** | ubuntu (non-root) |
| **OS** | Ubuntu 24 LTS |
| **Repo location** | `/home/ubuntu/server_tools` |
| **Alerts config** | `~/.server_alerts.conf` |
| **Project repo** | [Crypto_BOT](https://github.com/GinCz/Crypto_BOT) (private) |

---

## Key Differences from 222/109 Servers

- User is `ubuntu`, not `root` — use `sudo` for system commands
- Config files go to `~/.server_alerts.conf` instead of `/etc/server_alerts.conf`
- Scripts repo cloned to `/home/ubuntu/server_tools` instead of `/opt/server_tools`
- Aliases defined in `~/.bashrc` instead of shared_aliases.sh

---

## Initial Setup

```bash
# Clone public scripts repo
git clone https://github.com/GinCz/Linux_Server_Public.git ~/server_tools

# Create Telegram config (private — never commit this file!)
cat > ~/.server_alerts.conf << 'EOF'
TG_TOKEN="YOUR_BOT_TOKEN"
TG_CHAT="YOUR_CHAT_ID"
EOF
chmod 600 ~/.server_alerts.conf

# Load config automatically on login
echo 'source ~/.server_alerts.conf' >> ~/.bashrc

# Add aliases
cat >> ~/.bashrc << 'EOF'
alias antivir='bash ~/server_tools/scripts/scan_clamav.sh'
alias antivir-stop='bash ~/server_tools/scripts/scan_clamav.sh --stop'
alias antivir-status='bash ~/server_tools/scripts/scan_clamav.sh --status'
EOF

source ~/.bashrc
```

---

## Installed Tools

| Tool | Status | Notes |
|---|---|---|
| ClamAV | ✅ | `antivir` alias |
| Telegram alerts | ✅ | `~/.server_alerts.conf` |
| Crypto Bot | ✅ | systemd service |

---

## Update Scripts

```bash
cd ~/server_tools && git pull
source ~/.bashrc
```
