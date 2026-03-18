# 🖥️ Linux Server Management Scripts

**Author:** Ing. VladiMIR Bulantsev | 2026  
**Environment:** Ubuntu 24 LTS + FastPanel + CrowdSec + AmneziaVPN  
**Servers:** DE-NetCup (152.53.182.222) · RU-FastVDS (212.109.223.109) · VPN nodes  

---

## 🚀 Quick Start — New Server

```bash
curl -sSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/setup.sh | bash
```

This single command:
- Clones the repo to `/opt/server_tools`
- Makes all scripts executable
- Adds aliases permanently to `/root/.bashrc`
- Creates global `/usr/local/bin/load` and `/usr/local/bin/save` commands
- Detects server type automatically (222 / 109 / VPN)

---

## ⚡ Global Commands (Aliases)

| Command | Description |
|---|---|
| `save` | **Nuclear save** — `git add . && commit && push --force` to GitHub |
| `load` | **Nuclear load** — `fetch + reset --hard + clean -fd` from GitHub |
| `infooo` | Server health: CPU, RAM, Disk, uptime, top processes |
| `sos` | Full server audit (FastPanel) or node audit (VPN) |
| `sos1/3/24/120` | Audit for last 1/3/24/120 hours |
| `fight` | Block bots via CrowdSec + .htaccess rules |
| `domains` | Live domain checker — HTTP status for all Nginx vhosts |
| `backup` | System backup to local storage |
| `antivir` | CrowdSec decisions list |
| `banlog` | Last 20 CrowdSec alerts |
| `303` | Log 303 redirects analysis |
| `mailclean` | Clean Postfix mail queue |
| `audit` | Full security audit |
| `aws-test` | AWS region latency test |
| `chname` | Change server hostname |
| `aw` | AmneziaVPN stats |

---

## 📁 Repository Structure

```
/
├── setup.sh              # One-command bootstrap for any new server
├── shared_aliases.sh     # All aliases definition (sourced by .bashrc)
├── CRITICAL_RULES.md     # Rules: never commit secrets!
├── scripts/
│   ├── load.sh           # Nuclear load from GitHub
│   ├── save.sh           # Nuclear save to GitHub
│   ├── infooo.sh         # Server health monitor
│   ├── server_audit.sh   # FastPanel server audit
│   ├── node_audit.sh     # VPN node audit
│   ├── block_bots.sh     # Bot blocking
│   ├── deploy_htaccess.sh# .htaccess deployer
│   ├── domain_monitor.sh # Domain + SSL monitor
│   ├── disk_monitor.sh   # Disk usage monitor
│   ├── scan_clamav.sh    # ClamAV antivirus scanner
│   ├── system_backup.sh  # System backup
│   ├── mail_queue.sh     # Mail queue manager
│   ├── migration_tool.sh # Site migration tool
│   └── setup.sh / setup_eu_222.sh / setup_ru_109.sh
├── 222/                  # DE server specific configs
├── 109/                  # RU server specific configs
└── VPN/                  # VPN nodes configs
```

---

## 🔒 Security Rules

- **Never commit** real passwords, tokens, or API keys
- Secrets go to `/opt/server_tools/config.local` (in `.gitignore`)
- TG tokens use env variables: `TG_TOKEN` and `TG_CHAT_ID`
- See [CRITICAL_RULES.md](CRITICAL_RULES.md) for full rules

---

*Maintained with nuclear precision.* ⚛️
