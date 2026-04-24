# XRAY — Universal 3X-UI Installer
# = Rooted by VladiMIR | AI = v2026-04-24

Universal installer for any fresh Ubuntu 24 VPS with 3X-UI (Xray).
No hardcoded IPs, logins or passwords — all entered interactively.

## Quick install

```bash
bash <(curl -s https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/XRAY/install.sh)
```

## What it does
- Updates system, installs all packages
- Sets hostname + timezone Europe/Prague
- UFW: 22, 80, 443, panel port
- Clones Linux_Server_Public repo
- Deploys .bashrc with ALL aliases from VPN/.bashrc
- Adds x-ui aliases: xuistatus, xuirestart, xuistop, xuibackup, xuiusers, xuiurl, xuiconfig, xuifix
- Installs 3X-UI latest version
- Cleans DB (no duplicate keys!) and sets credentials
- Generates self-signed SSL cert (10 years, by IP)
- Installs MOTD
- Daily backup cron at 03:00 → /root/backups/xray
