# 🖥️ VPN Servers — AmneziaWG Nodes

## Protocol
- **Type:** AmneziaWG (obfuscated WireGuard)
- **Docker:** amnezia-awg container
- **Purpose:** Personal VPN, bypass censorship, secure tunnels
- **Color (SSH):** Turquoise `e[38;5;87m`

## Active Nodes

| Hostname | IP | Provider | RAM | Status |
|----------|----|----------|-----|--------|
| VPN-EU-Alex-47 | xxx.xxx.xxx.47 | — | 957MB | ✅ active |
| VPN-EU-4Ton-237 | — | — | — | ✅ active |
| VPN-EU-Tatra-9 | — | — | — | ✅ active |
| VPN-EU-Pilik-178 | — | — | — | ✅ active |

## Backup (updated 2026-03-25)
- **Script:** `VPN/system_backup.sh`
- **Destination:** `/BackUP/VPN/` on server 222 (xxx.xxx.xxx.222)
- **User:** `vlad` (password in Secret_Privat/servers.md)
- **Method:** sshpass + scp
- **Rotation:** keeps last 10 backups per node
- **Archive:** `/etc` + `/root/Linux_Server_Public`
- **Telegram:** notifies on success and failure
- **Alias:** `backup`

## Aliases (VPN)
`aw` `audit` `infooo` `backup` `load` `save` `00` `la`

## MOTD Banner (SSH login)
- Shows: hostname, IP, RAM, CPU cores, uptime (days+hours), WG peers count
- File: `/etc/profile.d/motd_vpn.sh`
- Updated: v2026-03-24

## Install on NEW VPN server
```bash
clear
[ -d /root/Linux_Server_Public ] \
  && cd /root/Linux_Server_Public && git pull \
  || cd /root && git clone https://github.com/GinCz/Linux_Server_Public.git && cd Linux_Server_Public
bash VPN/01_vpn_alliances_v1.0.sh
```

## Changes log
- **2026-03-25:** backup system rebuilt — vlad user, sshpass, /BackUP/VPN/ on 222
- **2026-03-24:** MOTD redesigned — compact single-line header, no SOS aliases, no banlog
- **2026-03-24:** aliases cleaned — removed sos/m/banlog, added audit
- **2026-03-12:** initial VPN setup
